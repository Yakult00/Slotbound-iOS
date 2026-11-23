// SlotboundTrainer v2 — GGGLHHH/slotbound-trainer 功能移植（iOS dylib，越狱注入）
//
// 架构：
//   - 钩 love 静态符号表里的 lua_pushnumber（LC_SYMTAB 解析 + Dobby），
//     在游戏主线程上把后端 Lua（trainer_lua.h 里的 sb_trainer_v2.lua）
//     用 luaL_loadbuffer + lua_pcall 注进游戏 Lua 状态；后端自己包住
//     love.update，每帧跑 tick。注入前是原版游戏，注入后才有辅助面板。
//   - 面板是原生 UIKit 悬浮骰子按钮 + 三页分页面板（资源 / 老虎机 / 单位），
//     和后端用文件桥通信：面板写 cheats_ui.lua，后端每 0.5s 轮询应用；
//     后端每 1s 写回 cheats_status.lua，每 5s 写 cheats_catalog.txt。
//   - 不改游戏文件，不依赖 JIT。
//
// 功能（GGGLHHH/slotbound-trainer）：
//   资源：金币 / 旋转次数（spinsLeft）/ 水晶，显示、改值、加、锁定。
//   老虎机：大奖模式，9 格同一兵种（W/A/S/M/H/D/J/random）。
//   单位：星级、吸收 LV、基础属性（生命/攻击/攻速/射程）、
//         主动技能冷却（最短 0.1 秒）、被动技能触发条件
//         （charges / chance / internalCooldown），
//         词条（32）、觉醒（12 候选）、刻印（33，等级 1-5，槽数可改）、物品（63）。
//   注意：棱彩概率没有做（GGGLHHH 也没做：波次、基地血量、棱彩概率）。
//
// Build: xcrun -sdk iphoneos clang++ -arch arm64 -dynamiclib -fobjc-arc \
//        -framework Foundation -framework UIKit -framework CoreGraphics -lc++ \
//        SlotboundTrainer.mm dobby/libdobby.a
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <mach-o/dyld.h>
#import <mach-o/nlist.h>
#import <dlfcn.h>
#import <pthread.h>
#import <sys/mman.h>
#import <errno.h>
#import <string.h>
#import <libkern/OSCacheControl.h>
#import <stdlib.h>
#import <unistd.h>
#import <stdio.h>
#include "dobby.h"
#include "trainer_lua.h"

// 面板版本号：CI 编译时用 -DSB_PANEL_VERSION="..." 注入（dylib 独立版本，
// 不跟 game.love 版本走）；本地手工编译不传该 flag 时用这里的兜底值。
#ifndef SB_PANEL_VERSION
#define SB_PANEL_VERSION "panel-dev"
#endif

#pragma mark - Lua types
typedef void lua_State;
typedef void (*lua_pushnumber_t)(lua_State*, double);
typedef int (*luaL_loadbuffer_t)(lua_State*, const char*, size_t, const char*);
typedef int (*lua_pcall_t)(lua_State*, int, int, int);
typedef int (*lua_gettop_t)(lua_State*);
typedef void (*lua_settop_t)(lua_State*, int);
typedef const char* (*lua_tolstring_t)(lua_State*, int, size_t*);
typedef int (*lua_type_t)(lua_State*, int);
typedef int (*lua_toboolean_t)(lua_State*, int);
#define LUA_MULTRET (-1)

static lua_pushnumber_t g_origPushNumber = NULL;
static luaL_loadbuffer_t g_luaL_loadbuffer = NULL;
static lua_pcall_t g_lua_pcall = NULL;
static lua_gettop_t g_lua_gettop = NULL;
static lua_settop_t g_lua_settop = NULL;
static lua_tolstring_t g_lua_tolstring = NULL;
static lua_type_t g_lua_type = NULL;
static lua_toboolean_t g_lua_toboolean = NULL;
static _Atomic int g_inHook = 0;
static _Thread_local int t_running = 0;
static BOOL g_backendInjected = NO;
static BOOL g_hookReady = NO;

// ---- 待执行的 Lua（UI 线程写，主线程 hook 里执行；v2 面板走文件桥，队列备用）----
static NSMutableArray<NSString*> *g_luaQueue = nil;
static NSLock *g_queueLock = nil;
static void enqueue_lua(NSString *code) {
    [g_queueLock lock];
    [g_luaQueue addObject:code];
    [g_queueLock unlock];
}

// ---- 静态符号表解析（love 二进制保留完整 LC_SYMTAB）----
// 注意：symoff/stroff 是文件偏移，必须经 __LINKEDIT 的 fileoff→vmaddr 换算成内存地址，
// 不能直接 slide + symoff（那会读到错误位置，符号永远解析不到，hook 装不上）。
// ---- 符号解析：不假设 image 0 就是 love ----
// 之前直接对 _dyld_get_image_header(0) 走 load command，结果全部符号返回 NULL：
// 要么 image 0 不是主程序，要么那一刻拿不到 header。这里改成遍历所有 image，
// 按路径匹配 love 再解析；最后再退回 image 0。
static void* resolve_sym_in_header(const struct mach_header_64 *hdr, const char *name) {
    if (!hdr) return NULL;
    intptr_t slide = 0;
    uint32_t imgCount = _dyld_image_count();
    for (uint32_t i = 0; i < imgCount; i++) {
        if ((const void *)_dyld_get_image_header(i) == (const void *)hdr) { slide = _dyld_get_image_vmaddr_slide(i); break; }
    }
    struct load_command *lc = (struct load_command*)((char*)hdr + sizeof(struct mach_header_64));
    struct symtab_command *symtab = NULL;
    struct segment_command_64 *linkedit = NULL;
    for (uint32_t i = 0; i < hdr->ncmds; i++) {
        if (lc->cmd == LC_SYMTAB) symtab = (struct symtab_command*)lc;
        else if (lc->cmd == LC_SEGMENT_64) {
            struct segment_command_64 *seg = (struct segment_command_64*)lc;
            if (strncmp(seg->segname, "__LINKEDIT", 16) == 0) linkedit = seg;
        }
        lc = (struct load_command*)((char*)lc + lc->cmdsize);
        if (lc->cmdsize == 0) break;
    }
    if (!symtab || !linkedit) return NULL;
    struct nlist_64 *syms = (struct nlist_64*)(slide + (intptr_t)linkedit->vmaddr + (symtab->symoff - linkedit->fileoff));
    char *strs = (char*)(slide + (intptr_t)linkedit->vmaddr + (symtab->stroff - linkedit->fileoff));
    for (uint32_t i = 0; i < symtab->nsyms; i++) {
        uint32_t off = syms[i].n_un.n_strx;
        if (off == 0 || off >= symtab->strsize) continue;
        if (strcmp(strs + off, name) == 0) return (void*)(syms[i].n_value + slide);
    }
    return NULL;
}

static void* resolve_sym(const char *name) {
    void *r = NULL;
    uint32_t n = _dyld_image_count();
    for (uint32_t i = 0; i < n && !r; i++) {
        const char *nm = _dyld_get_image_name(i);
        if (!nm) continue;
        if (strstr(nm, "SlotBound.app/love") || (strstr(nm, "/love") && !strstr(nm, ".dylib"))) {
            r = resolve_sym_in_header((const struct mach_header_64*)_dyld_get_image_header(i), name);
        }
    }
    if (!r) r = resolve_sym_in_header((const struct mach_header_64*)_dyld_get_image_header(0), name);
    return r;
}

static void run_queued_lua(lua_State *L) {
    NSArray<NSString*> *batch = nil;
    [g_queueLock lock];
    if (g_luaQueue.count > 0) { batch = [g_luaQueue copy]; [g_luaQueue removeAllObjects]; }
    [g_queueLock unlock];
    if (!batch) return;
    for (NSString *code in batch) {
        const char *c = code.UTF8String;
        int top = g_lua_gettop(L);
        int st = g_luaL_loadbuffer(L, c, strlen(c), "=trainer");
        if (st == 0) st = g_lua_pcall(L, 0, LUA_MULTRET, 0);
        if (st != 0) {
            size_t len = 0;
            const char *msg = g_lua_tolstring(L, -1, &len);
            NSLog(@"[SBTrainer] lua err: %s", msg ? msg : "?");
        }
        g_lua_settop(L, top);
    }
}

// 小探测：跑一段返回 boolean 的 Lua（不留栈），用来判断游戏是否已就绪。
static int lua_probe(lua_State *L, const char *code) {
    int top = g_lua_gettop(L);
    int st = g_luaL_loadbuffer(L, code, strlen(code), "=probe");
    if (st == 0) st = g_lua_pcall(L, 0, 1, 0);
    int r = 0;
    if (st == 0) r = g_lua_toboolean(L, -1);
    g_lua_settop(L, top);
    return r;
}

// 把后端（trainer_lua.h 里的 sb_trainer_v2.lua）注进游戏 Lua 状态，只注一次。
// 等游戏 main.lua 跑完、love.update 定义好再注，否则后端包不到 update。
static void inject_backend(lua_State *L) {
    if (g_backendInjected) return;
    if (!lua_probe(L, "return type(love) == 'table' and type(love.update) == 'function'")) return;
    int top = g_lua_gettop(L);
    int st = g_luaL_loadbuffer(L, (const char*)kTrainerLua, kTrainerLuaLen, "=sb_trainer");
    if (st == 0) st = g_lua_pcall(L, 0, LUA_MULTRET, 0);
    if (st != 0) {
        size_t len = 0;
        const char *msg = g_lua_tolstring(L, -1, &len);
        NSLog(@"[SBTrainer] backend inject err: %s", msg ? msg : "?");
        g_lua_settop(L, top);
        return; // 下次 hook 再试
    }
    g_lua_settop(L, top);
    g_backendInjected = YES;
    NSLog(@"[SBTrainer] backend injected");
}

static void hook_pushnumber(lua_State *L, double n) {
    if (g_origPushNumber) g_origPushNumber(L, n);
    if (t_running) return;
    if (![NSThread isMainThread]) return;
    if (g_inHook) return;
    g_inHook = 1;
    t_running = 1;
    inject_backend(L);
    run_queued_lua(L);
    t_running = 0;
    g_inHook = 0;
}

#pragma mark - Panel: file bridge + 3-tab UI
// ---- 悬浮按钮图标（圆形橙色骰子，base64 PNG）----
static NSString *kIconBase64 = @"iVBORw0KGgoAAAANSUhEUgAAAIQAAACECAYAAABRRIOnAAAFRUlEQVR4nO2dy7WdMAxFRVamqSBlpo5XZipIAWREFpcA/ulzZJ89zXpB2PvKAgsQIYQQQghpZ4sOwJN93/fev922bYmxmvIkRya+ldlEmeJkPAUokV2QtMEjSfBERjlSBZxBgieyyJEiyMwiXEEXAzo4bRH+fP3s/tsfv34rRoIrBmRQGiKMTH4tGpKgiQEVzIgIHgKUGBEERQyIIET6ZECQ4IkeORCkCA+gVQRkCZ5olSNSjFAhWmTIKMKVFjGipAg56GoiXEEWw12IWhlmFOFKrRieUnzzOpAIZbhSe56um3UeB6EIZVCyhXmGoAx1oGQLU9tqgl9dhDtqsoVVpjDLEJShn5pxscoUJkJQhnGipFAXgjLoESGF6jpUCo4i9FOqK7RqCrf7EJRhDK/xUxPiLTtQBh3exlFr6VARYqYWt8xozMOwEKwbfCmN56gUpjUEZbDBclyHhGDdEIdVPdEtBGWIx0IK1+1vgk+XEMwOOGhniea7W9EyaD8w40H0uLTcxfyuEo0DGUU4OGLPkD2bMkREdsgswhMRY1WbJVSKSsrQhtV5acxDtRDet6dnleHA+/xq5284Q1hkh9llOLA4z9H5qBKCm1dzUDOPVYXG038UnR3ujh+RXUbj8BzHUnFZvOxEzA5vA3j8m4cYKHG0sO/7/iZFdw0RlR1qj2t9za8ZB1ItkWovo/UkraRAicOCVyEQlwsyztu8dmWICON7j6kdK0ocVsdMtWQQex6F4HIxN0/z25whMhVIpH2+uGSQD9II0Xutrn2NjxKHFbdCsH5Yg7t5bsoQ0fVD66/M6leJEkctLfOWZsk4qB1c60lAiUObND2VZ956FD0nACUOTVIKcYAy6ChxaJBuySC2/JchPJthEJgp3b/x5+vn7Xld+yNSLxkjZGxu8WDJJQOlyQaR5YSYublFg+WEIO8sJUSm5pYolhKClKEQ5AMKQT6gEOSDpYSYvblFg6WEIGWWEyJbc4s3ywkhMm9ziwbLbm7N2Nyiwe1j4VFb4CtPRNTYXl8NsOSSQZ5JvWSgpHuUODRIKQRKcwtKHJqkWzJQmltQ4tCmSYho21GaW1DiqKVl3m6FsP7gOMHgbp7TLBkozS0ocViRRgjiQ7MQ0XUEaaN1vh6FYB0xN0/zyyWDfNAlRMSygdLcghKH1TFfheCyMScm77qOAKW5BSUOC7qFiHphN0pzi2Yc0Z+ZOFPc3Nq2bUN7CRlKcwtKHC2UyoChD6iIYNmdEe/xKwlRtWSwuJyDmnkcLiqRPv6RDcTsWi2Ed5aYXQrv83P9kCvyh0kRQf7wbZqPwc9QaEaNz5Qfg8/aoyiSK9N11QVRWYLco5UdRDpriLeDZPwFZ0ZTBpFkexnEnm4hmCXi0c4OIoMZglLEYSGDiPGSQSlssBzXYSFKNlIKXUrjOXpHWSVDcPMLA415UFsyWE/YY1U3nHG77KQUY3iNn3qqr+mu4t3MempE0Fyy1TNETXDMFnV4yyBitGRQinEiZBAxrCEoRT9RMogY1BBXaju2WVfU/0AsL/PNrzJqg189WyDIIOKQIc4wW/wPiggHrtvfzBafoMkg4pwhDlqeBJsxW7QI770tELoHsZoYyCL8O27EQc+0PjeaUYzWJTByszBciIOeB4qR5eipgxB2jcMDODPylDmCHCPFMIIMImBCHGi8fsBDEJUnpUBEOIAK5or2eylGJNG+FEYT4QAyqCtoLywZAVWEA+jgrmQWA12EgxRB3pFBjiwSnEkX8B1IcmSU4Ezq4J/wFCS7AFemOpkSI6LMNvGEEELIIH8BbTrFaMh7bJAAAAAASUVORK5CYII=";

// ---- 全局状态 ----
static NSString *g_saveDir = nil;

// 一次性操作 pending（写完 cheats_ui.lua 即清空）
static long long g_coinSet = 0;
static long long g_coinAdd = 0;
static long long g_spinsSet = 0;
static long long g_spinsAdd = 0;
static long long g_jungsuSet = 0;
static long long g_originiteSet = 0;
static long long g_originiteAdd = 0;
static NSString *g_runLua = nil;
static NSString *g_cmd = nil;     // 命名命令
static NSString *g_arg = nil;     // 命令参数（Lua 字面量）
static NSString *g_arg2 = nil;

// 持续状态
static BOOL g_lockCoins = NO;
static long long g_lockTarget = 0;
static BOOL g_lockSpins = NO;
static long long g_lockSpinsTarget = 0;
static BOOL g_lockJungsu = NO;
static long long g_lockJungsuTarget = 0;
static BOOL g_lockOriginite = NO;
static long long g_lockOriginiteTarget = 0;
static NSString *g_jackpot = nil;

// 实时状态（游戏写回）
static long long g_lastCoins = 0;
static long long g_lastSpins = 0;
static long long g_lastJungsu = 0;
static long long g_lastOriginite = 0;
// 老虎机页：核心添加（滚轮选一个 → 添加；或一键全加）
static UIPickerView *g_corePicker = nil;
static NSMutableArray *g_cores = nil;      // @{id, name, rarity}
static UILabel *g_coreLabel = nil;
static long long g_coreAdd = 0;
static long long g_coreAddAll = 0;
static long long g_lastCoreN = 0;
static long long g_lastCoreTotal = 0;
static NSString *g_unitSym = nil;
static NSString *g_unitGrade = nil;
static long long g_unitRank = 0;
static long long g_unitAbsorb = 0;
static long long g_imprintSlots = 0;

// 技能状态（游戏写回 cheats_status.lua 的 skill 行）
//   主动："active|名字|基础秒|总倍率|游戏原倍率|是否自定义"
//   被动："passive|名字|key:原值:现值;..."
static NSString *g_skillKind = nil;   // @"active" / @"passive" / @"none"
static NSString *g_skillName = nil;
static double g_skillBase = 0;
static double g_skillMul = 1;
static double g_skillCustom = 0;
static NSMutableDictionary *g_skillParams = nil; // key -> @{@"base": NSNumber, @"cur": NSNumber}

static NSInteger g_seq = 0;

// 目录数据（读 cheats_catalog.txt）
static NSMutableArray *g_options = nil;    // @{id, name}
static NSMutableArray *g_imprints = nil;   // @{id, name, maxLevel}
static NSMutableArray *g_items = nil;      // @{id, name, maxLevel}
static NSMutableArray *g_awakenings = nil; // @{id, name, maxLevel=5}
static UIPickerView *g_picker = nil;
static UIPickerView *g_shopPicker = nil;
static NSInteger g_pickerKind = 0;         // 0=词条 1=刻印 2=物品 3=觉醒

// UI
static UIWindow *g_win = nil;
static UIButton *g_floatBtn = nil;
static UIView *g_panel = nil;
static BOOL g_open = NO;
static CGPoint g_btnPos = {0, 0};
static double g_totalDrag = 0;

static UILabel *g_hookLabel = nil;
static UILabel *g_coinLabel = nil;
// 自定义数值输入框（资源 / 吸收等级 / 商店等级）
static UITextField *g_coinField = nil;
static UITextField *g_spinsField = nil;
static UITextField *g_jungsuField = nil;
static UITextField *g_originiteField = nil;
static UITextField *g_absorbField = nil;
static UITextField *g_shopLvField = nil;
static UIView *g_pageShop = nil;
static UILabel *g_shopInfoLabel = nil;
// 四个页面各自一个滚动视图（原来共用一个，短页面也要跟着长页面滚）
static UIScrollView *g_scrollRes = nil;
static UIScrollView *g_scrollSlot = nil;
static UIScrollView *g_scrollUnit = nil;
static UIScrollView *g_scrollShop = nil;
static UILabel *g_spinsLabel = nil;
static UILabel *g_jungsuLabel = nil;
static UILabel *g_originiteLabel = nil;
static UILabel *g_unitLabel = nil;
static UISwitch *g_lockSwitch = nil;
static UISwitch *g_spinsLockSwitch = nil;
static UISwitch *g_jungsuLockSwitch = nil;
static UISwitch *g_originiteLockSwitch = nil;
static UISwitch *g_jackpotSwitch = nil;

// ---- 新三页（抽奖 / 开关 / 存档）----
static UIScrollView *g_scrollDraw = nil, *g_scrollSw = nil, *g_scrollSave = nil;
static UIView *g_pageDraw = nil, *g_pageSw = nil, *g_pageSave = nil;
static UIView *g_symRow = nil, *g_gradeRow = nil, *g_jokerRow = nil;
static UILabel *g_spinsWaveLabel = nil;
static NSInteger g_symLock = 0, g_gradeLock = 0, g_luckTier = 0, g_spinsWave = 0;
static BOOL g_jesterHero = NO;
static long long g_jokerBits = 0;
#define kSwCount 14
static BOOL g_swOn[kSwCount] = { NO };
static NSString *swKey(int i) {
    static NSString *k[kSwCount] = {
        @"coins_lock", @"free_spin", @"force_win", @"hero_always", @"basehp_lock",
        @"spins_lock", @"reroll_lock", @"freespin_lock", @"jungsu_lock", @"start_bonus",
        @"unit_cap", @"item_cap", @"shop_free", @"speed_mul"
    };
    return (i >= 0 && i < kSwCount) ? k[i] : @"";
}
static NSString *swLabel(int i) {
    static NSString *k[kSwCount] = {
        @"无限金币", @"免费抽奖", @"必中大奖", @"每次必出英雄", @"基地无敌",
        @"抽奖次数锁定", @"核心重掷不限", @"无限免费抽", @"精粹锁定", @"开局超级加成",
        @"单位容量 99", @"物品容量 99", @"商店刷新不限", @"战斗加速 ×2"
    };
    return (i >= 0 && i < kSwCount) ? k[i] : @"";
}
static UILabel *g_skillLabel = nil;
static UIView *g_cdRow = nil;
static NSMutableArray *g_paramRows = nil;   // 3 个被动参数行 UIView
static NSMutableArray *g_paramLabels = nil; // 3 个被动参数行 UILabel
static UILabel *g_slotsLabel = nil;
static UIButton *g_replaceBtn = nil;
static UIButton *g_deleteBtn = nil;

static UIView *g_pageRes = nil;
static UIView *g_pageSlot = nil;
static UIView *g_pageUnit = nil;

static const CGFloat kBtnSize = 44;

// ---- save 目录定位 ----
// 游戏存档在 Library/Application Support/slotbound_full（LÖVE iOS 的 save 目录，
// 不是 Documents）。先按这个找，再在 Library 下递归找，最后才试 Documents。
static NSString *find_save_dir(void) {
    if (g_saveDir) return g_saveDir;
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *libDirs = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *libDir = libDirs.firstObject;
    NSString *cand = [libDir stringByAppendingPathComponent:@"Application Support/slotbound_full"];
    if ([fm fileExistsAtPath:[cand stringByAppendingPathComponent:@"save_fallback.dat"]]) {
        g_saveDir = cand;
        return g_saveDir;
    }
    NSDirectoryEnumerator *en = [fm enumeratorAtPath:libDir];
    NSString *rel = nil;
    int depth = 0;
    while ((rel = [en nextObject])) {
        if ([rel.lastPathComponent isEqualToString:@"save_fallback.dat"]) {
            g_saveDir = [[libDir stringByAppendingPathComponent:rel] stringByDeletingLastPathComponent];
            return g_saveDir;
        }
        if (++depth > 2000) break;
    }
    NSArray *docs = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docDir = docs.firstObject;
    NSString *cand2 = [docDir stringByAppendingPathComponent:@"slotbound_full"];
    if ([fm fileExistsAtPath:[cand2 stringByAppendingPathComponent:@"save_fallback.dat"]]) {
        g_saveDir = cand2;
        return g_saveDir;
    }
    g_saveDir = cand;
    return g_saveDir;
}

// ---- 文件写入 / 读取 ----
static void write_cheats(void) {
    NSString *dir = find_save_dir();
    if (!dir) return;
    g_seq++;
    NSMutableString *s = [NSMutableString string];
    [s appendFormat:@"return {\n  seq = %ld,\n", (long)g_seq];
    [s appendFormat:@"  coins_set = %@,\n", g_coinSet > 0 ? [NSString stringWithFormat:@"%lld", g_coinSet] : @"nil"];
    [s appendFormat:@"  coins_add = %lld,\n", g_coinAdd];
    [s appendFormat:@"  lock_coins = %@,\n", g_lockCoins ? [NSString stringWithFormat:@"%lld", g_lockTarget] : @"false"];
    [s appendFormat:@"  spins_set = %@,\n", g_spinsSet > 0 ? [NSString stringWithFormat:@"%lld", g_spinsSet] : @"nil"];
    [s appendFormat:@"  spins_add = %lld,\n", g_spinsAdd];
    [s appendFormat:@"  lock_spins = %@,\n", g_lockSpins ? [NSString stringWithFormat:@"%lld", g_lockSpinsTarget] : @"false"];
    [s appendFormat:@"  jungsu_set = %@,\n", g_jungsuSet > 0 ? [NSString stringWithFormat:@"%lld", g_jungsuSet] : @"nil"];
    [s appendFormat:@"  lock_jungsu = %@,\n", g_lockJungsu ? [NSString stringWithFormat:@"%lld", g_lockJungsuTarget] : @"false"];
    [s appendFormat:@"  originite_set = %@,\n", g_originiteSet > 0 ? [NSString stringWithFormat:@"%lld", g_originiteSet] : @"nil"];
    [s appendFormat:@"  originite_add = %lld,\n", g_originiteAdd];
    [s appendFormat:@"  lock_originite = %@,\n", g_lockOriginite ? [NSString stringWithFormat:@"%lld", g_lockOriginiteTarget] : @"false"];
    [s appendFormat:@"  core_add = %lld,\n", g_coreAdd];
    [s appendFormat:@"  core_add_all = %lld,\n", g_coreAddAll];
    [s appendFormat:@"  jackpot = %@,\n", g_jackpot ? [NSString stringWithFormat:@"\"%@\"", g_jackpot] : @"false"];
    [s appendFormat:@"  run_lua = %@,\n", g_runLua ? [NSString stringWithFormat:@"\"%@\"", g_runLua] : @"nil"];
    [s appendFormat:@"  cmd = %@,\n", g_cmd ? [NSString stringWithFormat:@"\"%@\"", g_cmd] : @"nil"];
    [s appendFormat:@"  arg = %@,\n", g_arg ?: @"nil"];
    [s appendFormat:@"  arg2 = %@,\n", g_arg2 ?: @"nil"];
    // ---- 抽奖（并入老虎机页；符号锁定与「必中大奖」重复，恒关）----
    [s appendFormat:@"  sym_lock = 0,\n"];
    [s appendFormat:@"  grade_lock = %ld,\n", (long)g_gradeLock];
    [s appendFormat:@"  luck_tier = %ld,\n", (long)g_luckTier];
    [s appendFormat:@"  spins_wave = %ld,\n", (long)g_spinsWave];
    [s appendFormat:@"  joker_bits = %lld,\n", g_jokerBits];
    [s appendFormat:@"  jester_hero = %d,\n", g_jesterHero ? 1 : 0];
    // ---- 开关（13 项，分散到各页；金币/次数/精粹锁定沿用资源页原有开关）----
    for (int i = 0; i < kSwCount; i++) {
        long long v = g_swOn[i] ? 1 : 0;
        if (i == 0 || i == 5 || i == 8) v = 0;         // coins/spins/jungsu 锁定由资源页原开关接管
        if (i == 9)  v = g_swOn[i] ? 1 : 0;           // start_bonus 开关即可
        if (i == 10) v = g_swOn[i] ? 99 : 0;          // unit_cap
        if (i == 11) v = g_swOn[i] ? 99 : 0;          // item_cap
        if (i == 13) v = g_swOn[i] ? 2 : 0;           // speed_mul
        [s appendFormat:@"  %@ = %lld,\n", swKey(i), v];
    }
    [s appendFormat:@"  coins_value = 9999999,\n  basehp_value = 999,\n  spins_value = 99,\n"];
    [s appendString:@"}\n"];
    [s writeToFile:[dir stringByAppendingPathComponent:@"cheats_ui.lua"]
        atomically:YES encoding:NSUTF8StringEncoding error:nil];
    g_coinSet = 0;
    g_coinAdd = 0;
    g_spinsSet = 0;
    g_spinsAdd = 0;
    g_jungsuSet = 0;
    g_originiteSet = 0;
    g_originiteAdd = 0;
    g_coreAdd = 0;
    g_coreAddAll = 0;
    g_runLua = nil;
    g_cmd = nil;
    g_arg = nil;
    g_arg2 = nil;
}

// ---- 轻量反馈：触感 + 底部提示条（让"点了有没有生效"看得见）----
static UILabel *g_toast = nil;

static void tap_haptic(void) {
    if (@available(iOS 10.0, *)) {
        static UIImpactFeedbackGenerator *gen = nil;
        if (!gen) gen = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
        [gen impactOccurred];
    }
}

static void show_toast(NSString *msg) {
    if (!g_panel) return;
    UIColor *gold = [UIColor colorWithRed:1.00 green:0.78 blue:0.25 alpha:1.0];
    UIColor *ink = [UIColor colorWithRed:0.10 green:0.07 blue:0.02 alpha:1.0];
    if (!g_toast) {
        g_toast = [[UILabel alloc] initWithFrame:CGRectMake(16, g_panel.bounds.size.height - 52,
                                                           g_panel.bounds.size.width - 32, 36)];
        g_toast.textAlignment = NSTextAlignmentCenter;
        g_toast.font = [UIFont boldSystemFontOfSize:14];
        g_toast.textColor = ink;
        g_toast.backgroundColor = gold;
        g_toast.layer.cornerRadius = 10;
        g_toast.clipsToBounds = YES;
        g_toast.alpha = 0;
        g_toast.userInteractionEnabled = NO;
        [g_panel addSubview:g_toast];
    }
    g_toast.text = msg;
    [g_panel bringSubviewToFront:g_toast];
    [g_toast.layer removeAllAnimations];
    [UIView animateWithDuration:0.12 animations:^{ g_toast.alpha = 1; } completion:^(BOOL f) {
        [UIView animateWithDuration:0.4 delay:1.0 options:UIViewAnimationOptionBeginFromCurrentState
                         animations:^{ g_toast.alpha = 0; } completion:nil];
    }];
}

static void send_command(NSString *cmd, NSString *arg, NSString *arg2) {
    g_cmd = cmd;
    g_arg = arg;    // Lua 字面量：数字 "22"，字符串 "\"atk\""
    g_arg2 = arg2;
    write_cheats();
    tap_haptic();
    show_toast(@"✓ 已执行");
}

static void read_status(void) {
    NSString *dir = find_save_dir();
    if (!dir) return;
    NSString *content = [NSString stringWithContentsOfFile:[dir stringByAppendingPathComponent:@"cheats_status.lua"]
                                                  encoding:NSUTF8StringEncoding error:nil];
    if (!content) return;
    for (NSString *line in [content componentsSeparatedByString:@"\n"]) {
        NSString *t = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        NSArray *kv = [t componentsSeparatedByString:@"="];
        if (kv.count < 2) continue;
        NSString *key = [kv[0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        NSString *val = [kv[1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        val = [val stringByReplacingOccurrencesOfString:@"," withString:@""];
        if ([key isEqualToString:@"coins"]) {
            g_lastCoins = (long long)[val doubleValue];
        } else if ([key isEqualToString:@"spins"]) {
            g_lastSpins = (long long)[val doubleValue];
        } else if ([key isEqualToString:@"jungsu"]) {
            g_lastJungsu = (long long)[val doubleValue];
        } else if ([key isEqualToString:@"originite"]) {
            g_lastOriginite = (long long)[val doubleValue];
        } else if ([key isEqualToString:@"cores"]) {
            g_lastCoreN = (long long)[val doubleValue];
        } else if ([key isEqualToString:@"coresTotal"]) {
            g_lastCoreTotal = (long long)[val doubleValue];
        } else if ([key isEqualToString:@"unit"]) {
            g_unitSym = [val stringByReplacingOccurrencesOfString:@"\"" withString:@""];
        } else if ([key isEqualToString:@"unit_grade"]) {
            g_unitGrade = [val stringByReplacingOccurrencesOfString:@"\"" withString:@""];
        } else if ([key isEqualToString:@"unit_rank"]) {
            g_unitRank = (long long)[val doubleValue];
        } else if ([key isEqualToString:@"unit_absorb"]) {
            g_unitAbsorb = (long long)[val doubleValue];
        } else if ([key isEqualToString:@"imprint_slots"]) {
            g_imprintSlots = (long long)[val doubleValue];
        } else if ([key isEqualToString:@"skill"]) {
            NSString *sv = [val stringByReplacingOccurrencesOfString:@"\"" withString:@""];
            NSArray *parts = [sv componentsSeparatedByString:@"|"];
            if (parts.count >= 1) g_skillKind = parts[0];
            if ([g_skillKind isEqualToString:@"active"] && parts.count >= 6) {
                g_skillName = parts[1];
                g_skillBase = [parts[2] doubleValue];
                g_skillMul = [parts[3] doubleValue];
                g_skillCustom = [parts[5] isEqualToString:@"1"];
                if (!g_skillParams) g_skillParams = [NSMutableDictionary dictionary];
                [g_skillParams removeAllObjects];
            } else if ([g_skillKind isEqualToString:@"passive"] && parts.count >= 3) {
                g_skillName = parts[1];
                if (!g_skillParams) g_skillParams = [NSMutableDictionary dictionary];
                [g_skillParams removeAllObjects];
                if ([(NSString *)parts[2] length] > 0) {
                    for (NSString *item in [parts[2] componentsSeparatedByString:@";"]) {
                        NSArray *p = [item componentsSeparatedByString:@":"];
                        if (p.count >= 3) {
                            g_skillParams[p[0]] = @{@"base": @([p[1] doubleValue]), @"cur": @([p[2] doubleValue])};
                        }
                    }
                }
            } else {
                g_skillName = nil;
                if (!g_skillParams) g_skillParams = [NSMutableDictionary dictionary];
                [g_skillParams removeAllObjects];
            }
        }
    }
    if (g_coinLabel) g_coinLabel.text = [NSString stringWithFormat:@"金币：%lld", g_lastCoins];
    if (g_spinsLabel) g_spinsLabel.text = [NSString stringWithFormat:@"旋转次数：%lld", g_lastSpins];
    if (g_jungsuLabel) g_jungsuLabel.text = [NSString stringWithFormat:@"水晶：%lld", g_lastJungsu];
    if (g_originiteLabel) g_originiteLabel.text = [NSString stringWithFormat:@"升级宝石：%lld", g_lastOriginite];
    if (g_coreLabel) {
        g_coreLabel.text = (g_lastCoreTotal > 0)
            ? [NSString stringWithFormat:@"已拥有核心：%lld / %lld", g_lastCoreN, g_lastCoreTotal]
            : @"已拥有核心：--";
    }
    if (g_unitLabel) {
        if (g_unitSym && ![g_unitSym isEqualToString:@"none"]) {
            g_unitLabel.text = [NSString stringWithFormat:@"选中单位：%@（%@） 星%lld 吸收%lld",
                                g_unitSym, g_unitGrade ?: @"?", g_unitRank, g_unitAbsorb];
        } else {
            g_unitLabel.text = @"选中单位：无（先在游戏里点一个单位）";
        }
    }
    if (g_slotsLabel) {
        g_slotsLabel.text = [NSString stringWithFormat:@"刻印槽数：%lld", g_imprintSlots];
    }
    if (g_skillLabel) {
        if ([g_skillKind isEqualToString:@"active"]) {
            double cur = g_skillBase * g_skillMul;
            g_skillLabel.text = [NSString stringWithFormat:@"主动技能：%@（基础 %g 秒，现 %g 秒%@）",
                                 g_skillName ?: @"?", g_skillBase, cur,
                                 g_skillCustom ? @"，已自定义" : @""];
        } else if ([g_skillKind isEqualToString:@"passive"]) {
            g_skillLabel.text = [NSString stringWithFormat:@"被动技能：%@", g_skillName ?: @"?"];
        } else {
            g_skillLabel.text = @"技能：--";
        }
    }
    if (g_cdRow) g_cdRow.hidden = ![g_skillKind isEqualToString:@"active"];
    if (g_paramRows) {
        NSArray *keys = @[@"charges", @"chance", @"internalCooldown"];
        NSArray *labels = @[@"普攻次数", @"触发概率", @"内置冷却"];
        for (NSInteger i = 0; i < 3; i++) {
            UIView *row = g_paramRows[i];
            UILabel *lab = g_paramLabels[i];
            NSDictionary *p = g_skillParams[keys[i]];
            BOOL show = [g_skillKind isEqualToString:@"passive"] && p != nil;
            row.hidden = !show;
            if (show) {
                lab.text = [NSString stringWithFormat:@"%@ %@: 原 %g → 现 %g",
                            labels[i], keys[i],
                            [p[@"base"] doubleValue], [p[@"cur"] doubleValue]];
            }
        }
    }
}

static void read_catalog(void) {
    NSString *dir = find_save_dir();
    if (!dir) return;
    NSString *content = [NSString stringWithContentsOfFile:[dir stringByAppendingPathComponent:@"cheats_catalog.txt"]
                                                  encoding:NSUTF8StringEncoding error:nil];
    if (!content) return;
    if (!g_options) g_options = [NSMutableArray array];
    if (!g_imprints) g_imprints = [NSMutableArray array];
    if (!g_items) g_items = [NSMutableArray array];
    if (!g_awakenings) g_awakenings = [NSMutableArray array];
    if (!g_cores) g_cores = [NSMutableArray array];
    [g_options removeAllObjects];
    [g_imprints removeAllObjects];
    [g_items removeAllObjects];
    [g_awakenings removeAllObjects];
    [g_cores removeAllObjects];
    NSMutableArray *cur = nil;
    for (NSString *line in [content componentsSeparatedByString:@"\n"]) {
        NSString *t = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (t.length == 0) continue;
        if ([t hasPrefix:@"["]) {
            if ([t isEqualToString:@"[options]"]) cur = g_options;
            else if ([t isEqualToString:@"[imprints]"]) cur = g_imprints;
            else if ([t isEqualToString:@"[items]"]) cur = g_items;
            else if ([t isEqualToString:@"[awakenings]"]) cur = g_awakenings;
            else if ([t isEqualToString:@"[cores]"]) cur = g_cores;
            else cur = nil;
            continue;
        }
        if (!cur) continue;
        NSArray *parts = [t componentsSeparatedByString:@"\t"];
        if (parts.count >= 2) {
            if (cur == g_cores) {   // 核心：id \t 名字 \t 稀有度 \t 是否已拥有
                NSMutableDictionary *d = [NSMutableDictionary dictionary];
                d[@"id"] = parts[0];
                d[@"name"] = parts[1];
                d[@"rarity"] = parts.count >= 3 ? parts[2] : @"";
                d[@"owned"] = @(parts.count >= 4 ? [parts[3] intValue] : 0);
                [cur addObject:d];
                continue;
            }
            NSMutableDictionary *d = [NSMutableDictionary dictionary];
            d[@"id"] = parts[0];
            d[@"name"] = parts[1];
            if (parts.count >= 3) d[@"maxLevel"] = @([parts[2] intValue]);
            [cur addObject:d];
        }
    }
    if (g_picker) [g_picker reloadAllComponents];
    if (g_shopPicker) [g_shopPicker reloadAllComponents];
    if (g_corePicker) {
        [g_corePicker reloadAllComponents];
        // 当前选中的已拥有 → 自动跳到第一个未拥有的，避免反复点同一个
        NSInteger cnt = (NSInteger)g_cores.count;
        NSInteger cur = [g_corePicker selectedRowInComponent:0];
        if (cnt > 0 && (cur < 0 || cur >= cnt || [g_cores[cur][@"owned"] intValue])) {
            for (NSInteger i = 0; i < cnt; i++) {
                if (![g_cores[i][@"owned"] intValue]) {
                    [g_corePicker selectRow:i inComponent:0 animated:NO];
                    break;
                }
            }
        }
    }
}

// ---- 触控穿透视图 ----
@interface PassthroughView : UIView
@end
@implementation PassthroughView
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hit = [super hitTest:point withEvent:event];
    return (hit == self) ? nil : hit;
}
@end

// ---- 主控制器 ----
@interface CheatsOverlay : NSObject <UIPickerViewDataSource, UIPickerViewDelegate>
+ (instancetype)shared;
+ (void)setup;
+ (void)floatTapped:(id)s;
+ (void)panButton:(UIPanGestureRecognizer *)gr;
+ (void)closeTapped;
+ (void)tabChanged:(UISegmentedControl *)sc;
+ (void)coinAdd:(UIButton *)b;
+ (void)coinSet:(UIButton *)b;
+ (void)coinSetText:(id)s;
+ (void)spinsSetText:(id)s;
+ (void)jungsuSetText:(id)s;
+ (void)absorbSetText:(id)s;
+ (void)panelTapped:(UITapGestureRecognizer *)g;
+ (void)btnDown:(UIButton *)b;
+ (void)itemsAll:(id)s;
+ (void)itemsClear:(id)s;
+ (void)shopAddOne:(id)s;
+ (void)spinsAdd:(UIButton *)b;
+ (void)spinsSet:(UIButton *)b;
+ (void)jungsuAdd:(UIButton *)b;
+ (void)jungsuSet:(UIButton *)b;
+ (void)originiteAdd:(UIButton *)b;
+ (void)originiteSet:(UIButton *)b;
+ (void)originiteSetText:(id)s;
+ (void)originiteLockChanged:(UISwitch *)sw;
+ (void)lockChanged:(UISwitch *)sw;
+ (void)spinsLockChanged:(UISwitch *)sw;
+ (void)jungsuLockChanged:(UISwitch *)sw;
+ (void)jackpotChanged:(UISwitch *)sw;
+ (void)addCoreTapped:(UIButton *)b;
+ (void)addAllCoresTapped:(UIButton *)b;
+ (void)unlockAllStages:(UIButton *)b;
+ (void)symTapped:(UIButton *)b;
+ (void)absorbAction:(UIButton *)b;
+ (void)rankAction:(UIButton *)b;
+ (void)statAction:(UIButton *)b;
+ (void)cdSet:(UIButton *)b;
+ (void)skillParamDelta:(UIButton *)b;
+ (void)skillParamReset:(UIButton *)b;
+ (void)slotsSet:(UIButton *)b;
+ (void)pickerKindChanged:(UISegmentedControl *)sc;
+ (NSMutableArray *)pickerArray;
+ (void)addSelected:(UIButton *)b;
+ (void)replaceFirst:(UIButton *)b;
+ (void)deleteFirst:(UIButton *)b;
// 抽奖 / 开关 / 存档
+ (void)symLockTapped:(UIButton *)b;
+ (void)gradeLockTapped:(UIButton *)b;
+ (void)luckChanged:(UISegmentedControl *)sc;
+ (void)spinsWaveDelta:(UIButton *)b;
+ (void)jokerTapped:(UIButton *)b;
+ (void)jesterChanged:(UISwitch *)sw;
+ (void)swChanged:(UISwitch *)sw;
+ (void)saveNow:(id)s;
+ (void)saveBackup:(id)s;
+ (void)saveRestore:(id)s;
+ (void)saveDefaults:(id)s;
+ (void)resetAllTapped:(id)s;
+ (void)doResetAll;
+ (void)clearCoresTapped:(id)s;
+ (void)linkTapped:(id)s;
@end

// ---- 配色：对齐游戏本体（深紫黑底 + 金色强调）----
static UIColor *accent(void) { return [UIColor colorWithRed:1.00 green:0.78 blue:0.25 alpha:1.0]; }        // 金
// 核心稀有度字母 → 中文（C/U/R/L）
static NSString *zh_rarity(NSString *r) {
    if ([r isEqualToString:@"C"]) return @"普通";
    if ([r isEqualToString:@"U"]) return @"精良";
    if ([r isEqualToString:@"R"]) return @"稀有";
    if ([r isEqualToString:@"L"]) return @"传说";
    return (r.length ? r : @"?");
}
static UIColor *panelBg(void) { return [UIColor colorWithRed:0.09 green:0.07 blue:0.14 alpha:0.98]; }       // 深紫黑
static UIColor *panelBg2(void) { return [UIColor colorWithRed:0.04 green:0.03 blue:0.07 alpha:0.98]; }      // 更深的收口
static UIColor *cardBg(void) { return [UIColor colorWithWhite:1.0 alpha:0.06]; }                            // 卡片底
static UIColor *txtPrimary(void) { return [UIColor colorWithWhite:1.0 alpha:0.96]; }                         // 主文字
static UIColor *txtDim(void) { return [UIColor colorWithWhite:1.0 alpha:0.55]; }                             // 次要文字
static UIColor *inkOnGold(void) { return [UIColor colorWithRed:0.10 green:0.07 blue:0.02 alpha:1.0]; }       // 金底上的字
static UIColor *dangerRed(void) { return [UIColor colorWithRed:0.90 green:0.30 blue:0.32 alpha:1.0]; }

static void styleSecondary(UIButton *b) {
    b.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.10];
    [b setTitleColor:txtPrimary() forState:UIControlStateNormal];
    b.titleLabel.font = [UIFont boldSystemFontOfSize:15];
    b.layer.cornerRadius = 10;
}
static void stylePrimary(UIButton *b) {
    b.backgroundColor = accent();
    [b setTitleColor:inkOnGold() forState:UIControlStateNormal];
    b.titleLabel.font = [UIFont boldSystemFontOfSize:15];
    b.layer.cornerRadius = 10;
}
static void restyleRow(UIView *row, int base, NSInteger sel) {
    if (!row) return;
    for (UIView *v in row.subviews) {
        if (![v isKindOfClass:[UIButton class]]) continue;
        BOOL on = ((NSInteger)v.tag - base) == sel;
        v.backgroundColor = on ? accent() : [UIColor colorWithWhite:0.22 alpha:1];
        [(UIButton *)v setTitleColor:on ? inkOnGold() : txtPrimary() forState:UIControlStateNormal];
    }
}

static void styleDanger(UIButton *b) {
    b.backgroundColor = dangerRed();
    [b setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    b.titleLabel.font = [UIFont boldSystemFontOfSize:15];
    b.layer.cornerRadius = 10;
}

// 分段控件：默认样式是"浅灰底+黑字"，放在黑面板上等于看不见
static void styleSegment(UISegmentedControl *sc) {
    if (@available(iOS 13.0, *)) sc.selectedSegmentTintColor = accent();
    sc.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.07];
    [sc setTitleTextAttributes:@{ NSForegroundColorAttributeName: txtPrimary(),
                                  NSFontAttributeName: [UIFont boldSystemFontOfSize:14] }
                      forState:UIControlStateNormal];
    [sc setTitleTextAttributes:@{ NSForegroundColorAttributeName: inkOnGold(),
                                  NSFontAttributeName: [UIFont boldSystemFontOfSize:14] }
                      forState:UIControlStateSelected];
}

static UIButton *makeButton(NSString *title, SEL action) {
    UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem];
    [b setTitle:title forState:UIControlStateNormal];
    styleSecondary(b);
    [b addTarget:[CheatsOverlay class] action:action forControlEvents:UIControlEventTouchUpInside];
    [b addTarget:[CheatsOverlay class] action:@selector(btnDown:) forControlEvents:UIControlEventTouchDown];
    return b;
}

// 顶部小标题（金色小号，配一条细金线）
static __attribute__((unused)) CGFloat addSectionTitle(UIView *v, CGFloat x, CGFloat y, CGFloat w, NSString *text) {
    UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(x, y, w, 18)];
    l.text = text;
    l.font = [UIFont boldSystemFontOfSize:13];
    l.textColor = accent();
    [v addSubview:l];
    UIView *line = [[UIView alloc] initWithFrame:CGRectMake(x, y + 20, w, 1)];
    line.backgroundColor = [accent() colorWithAlphaComponent:0.28];
    [v addSubview:line];
    return y + 28;
}

// 数字输入框（自定义数值用）
static UITextField *makeNumField(CGFloat x, CGFloat y, CGFloat w, NSString *placeholder) {
    UITextField *f = [[UITextField alloc] initWithFrame:CGRectMake(x, y, w, 36)];
    f.backgroundColor = cardBg();
    f.textColor = txtPrimary();
    f.tintColor = accent();
    f.layer.cornerRadius = 10;
    f.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.14].CGColor;
    f.layer.borderWidth = 1;
    f.keyboardType = UIKeyboardTypeNumberPad;
    f.clearButtonMode = UITextFieldViewModeWhileEditing;
    f.font = [UIFont boldSystemFontOfSize:16];
    f.textAlignment = NSTextAlignmentCenter;
    f.attributedPlaceholder = [[NSAttributedString alloc]
        initWithString:placeholder
            attributes:@{NSForegroundColorAttributeName: [UIColor colorWithWhite:1 alpha:0.42]}];
    // 左边留白，字不贴边
    UIView *pad = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 36)];
    f.leftView = pad;
    f.leftViewMode = UITextFieldViewModeAlways;
    // 数字键盘没有回车键，必须自带一个「完成」，否则键盘收不回去
    UIToolbar *tb = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    tb.barStyle = UIBarStyleBlack;
    UIBarButtonItem *flex = [[UIBarButtonItem alloc]
        initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *done = [[UIBarButtonItem alloc]
        initWithTitle:@"完成" style:UIBarButtonItemStyleDone target:f action:@selector(resignFirstResponder)];
    tb.items = @[ flex, done ];
    [tb sizeToFit];
    f.inputAccessoryView = tb;
    return f;
}

// 资源页：金币 / 旋转次数 / 水晶，各自显示、加、设、锁定。
static UIView *build_page_res(CGFloat w) {
    UIView *v = [[UIView alloc] initWithFrame:CGRectMake(0, 0, w, 520)];
    v.backgroundColor = [UIColor clearColor];
    CGFloat x = 14, y = 8, cw = w - 28;
    CGFloat bw = (cw - 3 * 8) / 4;

    // ---- 金币 ----
    g_coinLabel = [[UILabel alloc] initWithFrame:CGRectMake(x, y, cw, 34)];
    g_coinLabel.font = [UIFont boldSystemFontOfSize:24];
    g_coinLabel.textColor = accent();
    g_coinLabel.text = @"金币：--";
    [v addSubview:g_coinLabel];
    y += 44;

    NSArray *adds = @[@"+100", @"+1000", @"+1万", @"+10万"];
    NSArray *addVals = @[@100, @1000, @10000, @100000];
    for (NSInteger i = 0; i < 4; i++) {
        UIButton *b = makeButton(adds[i], @selector(coinAdd:));
        b.tag = [addVals[i] longLongValue];
        b.frame = CGRectMake(x + i * (bw + 8), y, bw, 40);
        [v addSubview:b];
    }
    y += 50;

    NSArray *sets = @[@"设1万", @"设10万", @"设100万"];
    NSArray *setVals = @[@10000, @100000, @1000000];
    for (NSInteger i = 0; i < 3; i++) {
        UIButton *b = makeButton(sets[i], @selector(coinSet:));
        b.tag = [setVals[i] longLongValue];
        b.frame = CGRectMake(x + i * (bw + 8), y, bw, 40);
        [v addSubview:b];
    }
    y += 50;

    UILabel *lockLab = [[UILabel alloc] initWithFrame:CGRectMake(x, y, 210, 30)];
    lockLab.text = @"锁定金币（锁到当前值）";
    lockLab.font = [UIFont systemFontOfSize:15];
    lockLab.textColor = [UIColor whiteColor];
    [v addSubview:lockLab];
    g_lockSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(w - 14 - 51, y, 51, 31)];
    g_lockSwitch.on = g_lockCoins;
    g_lockSwitch.onTintColor = accent();
    [g_lockSwitch addTarget:[CheatsOverlay class] action:@selector(lockChanged:) forControlEvents:UIControlEventValueChanged];
    [v addSubview:g_lockSwitch];
    y += 46;

    UIView *sep = [[UIView alloc] initWithFrame:CGRectMake(x, y, cw, 1)];
    sep.backgroundColor = [accent() colorWithAlphaComponent:0.22];
    [v addSubview:sep];
    y += 12;

    // ---- 旋转次数 ----
    g_spinsLabel = [[UILabel alloc] initWithFrame:CGRectMake(x, y, cw, 34)];
    g_spinsLabel.font = [UIFont boldSystemFontOfSize:24];
    g_spinsLabel.textColor = [UIColor colorWithRed:0.6 green:0.9 blue:0.4 alpha:1];
    g_spinsLabel.text = @"旋转次数：--";
    [v addSubview:g_spinsLabel];
    y += 44;

    NSArray *sadds = @[@"+1", @"+5", @"+10", @"设999"];
    NSArray *saddVals = @[@1, @5, @10, @999];
    for (NSInteger i = 0; i < 4; i++) {
        UIButton *b = (i < 3) ? makeButton(sadds[i], @selector(spinsAdd:)) : makeButton(sadds[i], @selector(spinsSet:));
        b.tag = [saddVals[i] longLongValue];
        b.frame = CGRectMake(x + i * (bw + 8), y, bw, 40);
        [v addSubview:b];
    }
    y += 50;

    UILabel *spinsLockLab = [[UILabel alloc] initWithFrame:CGRectMake(x, y, 210, 30)];
    spinsLockLab.text = @"锁定旋转（锁到当前值）";
    spinsLockLab.font = [UIFont systemFontOfSize:15];
    spinsLockLab.textColor = [UIColor whiteColor];
    [v addSubview:spinsLockLab];
    g_spinsLockSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(w - 14 - 51, y, 51, 31)];
    g_spinsLockSwitch.on = g_lockSpins;
    g_spinsLockSwitch.onTintColor = accent();
    [g_spinsLockSwitch addTarget:[CheatsOverlay class] action:@selector(spinsLockChanged:) forControlEvents:UIControlEventValueChanged];
    [v addSubview:g_spinsLockSwitch];
    y += 46;

    UIView *sep2 = [[UIView alloc] initWithFrame:CGRectMake(x, y, cw, 1)];
    sep2.backgroundColor = [accent() colorWithAlphaComponent:0.22];
    [v addSubview:sep2];
    y += 12;

    // ---- 水晶 ----
    g_jungsuLabel = [[UILabel alloc] initWithFrame:CGRectMake(x, y, cw, 34)];
    g_jungsuLabel.font = [UIFont boldSystemFontOfSize:24];
    g_jungsuLabel.textColor = [UIColor colorWithRed:0.4 green:0.8 blue:1 alpha:1];
    g_jungsuLabel.text = @"水晶：--";
    [v addSubview:g_jungsuLabel];
    y += 44;

    NSArray *jadds = @[@"+100", @"+1000", @"设9999", @"设99999"];
    NSArray *jaddVals = @[@100, @1000, @9999, @99999];
    for (NSInteger i = 0; i < 4; i++) {
        UIButton *b = (i < 2) ? makeButton(jadds[i], @selector(jungsuAdd:)) : makeButton(jadds[i], @selector(jungsuSet:));
        b.tag = [jaddVals[i] longLongValue];
        b.frame = CGRectMake(x + i * (bw + 8), y, bw, 40);
        [v addSubview:b];
    }
    y += 50;

    UILabel *jungsuLockLab = [[UILabel alloc] initWithFrame:CGRectMake(x, y, 210, 30)];
    jungsuLockLab.text = @"锁定水晶（锁到当前值）";
    jungsuLockLab.font = [UIFont systemFontOfSize:15];
    jungsuLockLab.textColor = [UIColor whiteColor];
    [v addSubview:jungsuLockLab];
    g_jungsuLockSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(w - 14 - 51, y, 51, 31)];
    g_jungsuLockSwitch.on = g_lockJungsu;
    g_jungsuLockSwitch.onTintColor = accent();
    [g_jungsuLockSwitch addTarget:[CheatsOverlay class] action:@selector(jungsuLockChanged:) forControlEvents:UIControlEventValueChanged];
    [v addSubview:g_jungsuLockSwitch];
    y += 46;

    // ---- 升级宝石（originite）----
    UIView *sepO = [[UIView alloc] initWithFrame:CGRectMake(x, y, cw, 1)];
    sepO.backgroundColor = [accent() colorWithAlphaComponent:0.22];
    [v addSubview:sepO];
    y += 12;

    g_originiteLabel = [[UILabel alloc] initWithFrame:CGRectMake(x, y, cw, 34)];
    g_originiteLabel.font = [UIFont boldSystemFontOfSize:24];
    g_originiteLabel.textColor = [UIColor colorWithRed:0.85 green:0.45 blue:1 alpha:1];
    g_originiteLabel.text = @"升级宝石：--";
    [v addSubview:g_originiteLabel];
    y += 44;

    NSArray *oadds = @[@"+100", @"+1000", @"设9999", @"设99999"];
    NSArray *oaddVals = @[@100, @1000, @9999, @99999];
    for (NSInteger i = 0; i < 4; i++) {
        UIButton *b = (i < 2) ? makeButton(oadds[i], @selector(originiteAdd:)) : makeButton(oadds[i], @selector(originiteSet:));
        b.tag = [oaddVals[i] longLongValue];
        b.frame = CGRectMake(x + i * (bw + 8), y, bw, 40);
        [v addSubview:b];
    }
    y += 50;

    UILabel *originiteLockLab = [[UILabel alloc] initWithFrame:CGRectMake(x, y, 210, 30)];
    originiteLockLab.text = @"锁定宝石（锁到当前值）";
    originiteLockLab.font = [UIFont systemFontOfSize:15];
    originiteLockLab.textColor = [UIColor whiteColor];
    [v addSubview:originiteLockLab];
    g_originiteLockSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(w - 14 - 51, y, 51, 31)];
    g_originiteLockSwitch.on = g_lockOriginite;
    g_originiteLockSwitch.onTintColor = accent();
    [g_originiteLockSwitch addTarget:[CheatsOverlay class] action:@selector(originiteLockChanged:) forControlEvents:UIControlEventValueChanged];
    [v addSubview:g_originiteLockSwitch];
    y += 46;

    // ---- 自定义数值：输入多少就设多少 ----
    UIView *sepC = [[UIView alloc] initWithFrame:CGRectMake(x, y, cw, 1)];
    sepC.backgroundColor = [accent() colorWithAlphaComponent:0.22];
    [v addSubview:sepC];
    y += 10;
    UILabel *custLab = [[UILabel alloc] initWithFrame:CGRectMake(x, y, cw, 20)];
    custLab.text = @"自定义数值（输入后点「设定」）";
    custLab.font = [UIFont boldSystemFontOfSize:14];
    custLab.textColor = [UIColor whiteColor];
    [v addSubview:custLab];
    y += 26;

    NSArray *ph = @[ @"金币", @"旋转次数", @"水晶", @"升级宝石" ];
    NSArray *sel = @[ @"coinSetText:", @"spinsSetText:", @"jungsuSetText:", @"originiteSetText:" ];
    NSMutableArray *fields = [NSMutableArray arrayWithCapacity:4];
    for (NSInteger i = 0; i < 4; i++) {
        UITextField *f = makeNumField(x, y, cw - bw - 8, ph[i]);
        [v addSubview:f];
        [fields addObject:f];
        UIButton *b = makeButton(@"设定", NSSelectorFromString(sel[i]));
        b.frame = CGRectMake(x + cw - bw, y, bw, 34);
        [v addSubview:b];
        y += 42;
    }
    g_coinField = fields[0];
    g_spinsField = fields[1];
    g_jungsuField = fields[2];
    g_originiteField = fields[3];

    // ---- 关卡 / 无尽：一键全开（写存档，重进选关界面生效）----
    UIView *sepS = [[UIView alloc] initWithFrame:CGRectMake(x, y + 6, cw, 1)];
    sepS.backgroundColor = [accent() colorWithAlphaComponent:0.22];
    [v addSubview:sepS];
    y += 18;

    UIButton *stageBtn = makeButton(@"一键解锁全部关卡（含无尽）", @selector(unlockAllStages:));
    stageBtn.frame = CGRectMake(x, y, cw, 46);
    stageBtn.backgroundColor = accent();
    [v addSubview:stageBtn];
    y += 54;

    UILabel *stageHint = [[UILabel alloc] initWithFrame:CGRectMake(x, y, cw, 34)];
    stageHint.text = @"写满 6 关 × 3 难度通关记录；退出重进游戏后选关界面全开";
    stageHint.font = [UIFont systemFontOfSize:12];
    stageHint.numberOfLines = 2;
    stageHint.textColor = [UIColor colorWithWhite:0.72 alpha:1];
    [v addSubview:stageHint];
    y += 40;

    v.frame = CGRectMake(0, 0, w, y);
    return v;
}

static NSArray *symDefs(void) {
    return @[
        @{@"key": @"W", @"label": @"战士"},
        @{@"key": @"A", @"label": @"弓手"},
        @{@"key": @"S", @"label": @"枪兵"},
        @{@"key": @"M", @"label": @"法师"},
        @{@"key": @"H", @"label": @"骑兵"},
        @{@"key": @"D", @"label": @"决斗者"},
        @{@"key": @"J", @"label": @"小丑"},
        @{@"key": @"random", @"label": @"随机"},
    ];
}

static UIView *build_page_slot(CGFloat w) {
    UIView *v = [[UIView alloc] initWithFrame:CGRectMake(0, 0, w, 300)];
    v.backgroundColor = [UIColor clearColor];
    CGFloat x = 14, y = 8, cw = w - 28;

    UILabel *lab = [[UILabel alloc] initWithFrame:CGRectMake(x, y, 220, 30)];
    lab.text = @"老虎机大奖（9 格同一兵种）";
    lab.font = [UIFont systemFontOfSize:15];
    lab.textColor = [UIColor whiteColor];
    [v addSubview:lab];
    g_jackpotSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(w - 14 - 51, y, 51, 31)];
    g_jackpotSwitch.on = (g_jackpot != nil);
    g_jackpotSwitch.onTintColor = accent();
    [g_jackpotSwitch addTarget:[CheatsOverlay class] action:@selector(jackpotChanged:) forControlEvents:UIControlEventValueChanged];
    [v addSubview:g_jackpotSwitch];
    y += 46;

    NSArray *defs = symDefs();
    CGFloat bw = (cw - 3 * 8) / 4;
    for (NSInteger i = 0; i < (NSInteger)defs.count; i++) {
        NSInteger col = i % 4, row = i / 4;
        UIButton *b = makeButton(defs[i][@"label"], @selector(symTapped:));
        b.tag = i;
        b.frame = CGRectMake(x + col * (bw + 8), y + row * 50, bw, 42);
        BOOL selected = g_jackpot && [g_jackpot isEqualToString:defs[i][@"key"]];
        b.backgroundColor = selected ? accent() : [UIColor colorWithWhite:0.22 alpha:1];
        [v addSubview:b];
    }
    y += 2 * 50 + 12;

    UILabel *hint = [[UILabel alloc] initWithFrame:CGRectMake(x, y, cw, 60)];
    hint.text = @"开启后每次拉杆 9 格全是指定兵种；\n「随机」每次随机一个兵种。";
    hint.numberOfLines = 0;
    hint.font = [UIFont systemFontOfSize:13];
    hint.textColor = [UIColor colorWithWhite:0.7 alpha:1];
    [v addSubview:hint];
    y += 66;

    // ---- 核心添加（和单位页的「物品/刻印」一样：滚轮选 → 添加）----
    UIView *coreDiv = [[UIView alloc] initWithFrame:CGRectMake(x, y, cw, 1)];
    coreDiv.backgroundColor = [UIColor colorWithWhite:0.32 alpha:1];
    [v addSubview:coreDiv];
    y += 10;

    g_coreLabel = [[UILabel alloc] initWithFrame:CGRectMake(x, y, cw, 26)];
    g_coreLabel.text = @"已拥有核心：--";
    g_coreLabel.font = [UIFont boldSystemFontOfSize:15];
    g_coreLabel.textColor = accent();
    [v addSubview:g_coreLabel];
    y += 30;

    g_corePicker = [[UIPickerView alloc] initWithFrame:CGRectMake(x, y, cw, 110)];
    g_corePicker.dataSource = [CheatsOverlay shared];
    g_corePicker.delegate = [CheatsOverlay shared];
    [v addSubview:g_corePicker];
    y += 116;

    CGFloat chalf = (cw - 8) / 2;
    UIButton *coreAddBtn = makeButton(@"添加选中核心", @selector(addCoreTapped:));
    coreAddBtn.frame = CGRectMake(x, y, chalf, 44);
    [v addSubview:coreAddBtn];
    UIButton *coreAllBtn = makeButton(@"一键全部添加", @selector(addAllCoresTapped:));
    coreAllBtn.frame = CGRectMake(x + chalf + 8, y, chalf, 44);
    coreAllBtn.backgroundColor = accent();
    [v addSubview:coreAllBtn];
    y += 52;

    UIButton *coreClearBtn = makeButton(@"一键清除所有核心", @selector(clearCoresTapped:));
    coreClearBtn.frame = CGRectMake(x, y, cw, 44);
    coreClearBtn.backgroundColor = [UIColor colorWithRed:0.62 green:0.20 blue:0.20 alpha:1.0];
    [v addSubview:coreClearBtn];
    y += 54;

    v.frame = CGRectMake(0, 0, w, y);
    return v;
}

// 单位页：星级 / 吸收 / 属性 / 技能（主动冷却、被动触发条件）/ 刻印槽数 /
// 词条·刻印·物品·觉醒滚轮。
static NSArray *skillParamDefs(void) {
    return @[
        @{@"key": @"charges",         @"label": @"普攻次数", @"step": @1},
        @{@"key": @"chance",          @"label": @"触发概率", @"step": @0.05},
        @{@"key": @"internalCooldown", @"label": @"内置冷却", @"step": @0.5},
    ];
}

static UIView *build_page_unit(CGFloat w) {
    UIView *v = [[UIView alloc] initWithFrame:CGRectMake(0, 0, w, 720)];
    v.backgroundColor = [UIColor clearColor];
    CGFloat x = 14, y = 8, cw = w - 28;
    CGFloat bw = (cw - 3 * 8) / 4;

    g_unitLabel = [[UILabel alloc] initWithFrame:CGRectMake(x, y, cw, 24)];
    g_unitLabel.font = [UIFont boldSystemFontOfSize:15];
    g_unitLabel.textColor = accent();
    g_unitLabel.text = @"选中单位：无（先在游戏里点一个单位）";
    [v addSubview:g_unitLabel];
    y += 30;

    UILabel *l1 = [[UILabel alloc] initWithFrame:CGRectMake(x, y, 120, 30)];
    l1.text = @"吸收 LV";
    l1.font = [UIFont systemFontOfSize:14]; l1.textColor = [UIColor whiteColor];
    [v addSubview:l1];
    NSArray *absT = @[@"+1", @"+10", @"设100"];
    NSArray *absV = @[@1, @10, @100];
    for (NSInteger i = 0; i < 3; i++) {
        UIButton *b = makeButton(absT[i], @selector(absorbAction:));
        b.tag = [absV[i] longLongValue];
        b.frame = CGRectMake(x + (i + 1) * (bw + 8), y, bw, 34);
        [v addSubview:b];
    }
    y += 42;

    g_absorbField = makeNumField(x, y, cw - bw - 8, @"自定义吸收 LV（1-100）");
    [v addSubview:g_absorbField];
    UIButton *abSet = makeButton(@"设定", @selector(absorbSetText:));
    abSet.frame = CGRectMake(x + cw - bw, y, bw, 34);
    [v addSubview:abSet];
    y += 44;

    UILabel *l2 = [[UILabel alloc] initWithFrame:CGRectMake(x, y, 120, 30)];
    l2.text = @"星级";
    l2.font = [UIFont systemFontOfSize:14]; l2.textColor = [UIColor whiteColor];
    [v addSubview:l2];
    NSArray *rkT = @[@"升2星", @"升3星"];
    NSArray *rkV = @[@2, @3];
    for (NSInteger i = 0; i < 2; i++) {
        UIButton *b = makeButton(rkT[i], @selector(rankAction:));
        b.tag = [rkV[i] longLongValue];
        b.frame = CGRectMake(x + (i + 1) * (bw + 8), y, bw, 34);
        [v addSubview:b];
    }
    y += 42;

    UILabel *l3 = [[UILabel alloc] initWithFrame:CGRectMake(x, y, 120, 30)];
    l3.text = @"属性";
    l3.font = [UIFont systemFontOfSize:14]; l3.textColor = [UIColor whiteColor];
    [v addSubview:l3];
    NSArray *stT = @[@"生命×2", @"攻击×2", @"攻速×2", @"射程×2"];
    for (NSInteger i = 0; i < 4; i++) {
        UIButton *b = makeButton(stT[i], @selector(statAction:));
        b.tag = i;
        b.frame = CGRectMake(x + i * (bw + 8), y, bw, 34);
        [v addSubview:b];
    }
    y += 44;

    UIView *sep = [[UIView alloc] initWithFrame:CGRectMake(x, y, cw, 1)];
    sep.backgroundColor = [accent() colorWithAlphaComponent:0.22];
    [v addSubview:sep];
    y += 10;

    // ---- 技能（主动冷却 / 被动触发条件）----
    g_skillLabel = [[UILabel alloc] initWithFrame:CGRectMake(x, y, cw, 20)];
    g_skillLabel.font = [UIFont boldSystemFontOfSize:14];
    g_skillLabel.textColor = [UIColor whiteColor];
    g_skillLabel.text = @"技能：--";
    [v addSubview:g_skillLabel];
    y += 24;

    // 主动技能冷却行（只有主动技能的单位才显示）
    g_cdRow = [[UIView alloc] initWithFrame:CGRectMake(0, y, w, 34)];
    g_cdRow.backgroundColor = [UIColor clearColor];
    {
        UILabel *cdLab = [[UILabel alloc] initWithFrame:CGRectMake(x, 2, 52, 30)];
        cdLab.text = @"冷却";
        cdLab.font = [UIFont systemFontOfSize:14]; cdLab.textColor = [UIColor whiteColor];
        [g_cdRow addSubview:cdLab];
        NSArray *cdT = @[@"0.1秒", @"0.5秒", @"1秒", @"2秒", @"恢复"];
        NSArray *cdV = @[@1, @5, @10, @20, @-10];
        CGFloat cbw = (cw - 52 - 8 - 4 * 8) / 5;
        for (NSInteger i = 0; i < 5; i++) {
            UIButton *b = makeButton(cdT[i], @selector(cdSet:));
            b.tag = [cdV[i] longLongValue];
            b.frame = CGRectMake(x + 52 + 8 + i * (cbw + 8), 0, cbw, 34);
            [g_cdRow addSubview:b];
        }
    }
    g_cdRow.hidden = YES;
    [v addSubview:g_cdRow];
    y += 38;

    // 被动技能参数行（只有被动技能且参数存在时才显示）
    g_paramRows = [NSMutableArray array];
    g_paramLabels = [NSMutableArray array];
    NSArray *pdefs = skillParamDefs();
    for (NSInteger i = 0; i < 3; i++) {
        UIView *row = [[UIView alloc] initWithFrame:CGRectMake(0, y, w, 34)];
        row.backgroundColor = [UIColor clearColor];
        UILabel *lab = [[UILabel alloc] initWithFrame:CGRectMake(x, 6, 190, 22)];
        lab.font = [UIFont systemFontOfSize:14];
        lab.textColor = [UIColor whiteColor];
        lab.text = [NSString stringWithFormat:@"%@：--", pdefs[i][@"label"]];
        [row addSubview:lab];
        UIButton *minus = makeButton(@"−", @selector(skillParamDelta:));
        minus.tag = i * 2;
        minus.frame = CGRectMake(w - 14 - 3 * 56 - 2 * 8, 0, 56, 34);
        [row addSubview:minus];
        UIButton *plus = makeButton(@"+", @selector(skillParamDelta:));
        plus.tag = i * 2 + 1;
        plus.frame = CGRectMake(w - 14 - 2 * 56 - 8, 0, 56, 34);
        [row addSubview:plus];
        UIButton *reset = makeButton(@"恢复", @selector(skillParamReset:));
        reset.tag = i;
        reset.frame = CGRectMake(w - 14 - 56, 0, 56, 34);
        [row addSubview:reset];
        row.hidden = YES;
        [v addSubview:row];
        [g_paramRows addObject:row];
        [g_paramLabels addObject:lab];
        y += 38;
    }

    UIView *sep2 = [[UIView alloc] initWithFrame:CGRectMake(x, y, cw, 1)];
    sep2.backgroundColor = [accent() colorWithAlphaComponent:0.22];
    [v addSubview:sep2];
    y += 10;

    // ---- 刻印槽数 ----
    g_slotsLabel = [[UILabel alloc] initWithFrame:CGRectMake(x, y, 150, 30)];
    g_slotsLabel.font = [UIFont systemFontOfSize:14];
    g_slotsLabel.textColor = [UIColor whiteColor];
    g_slotsLabel.text = @"刻印槽数：--";
    [v addSubview:g_slotsLabel];
    NSArray *slotT = @[@"槽3", @"槽5"];
    NSArray *slotV = @[@3, @5];
    for (NSInteger i = 0; i < 2; i++) {
        UIButton *b = makeButton(slotT[i], @selector(slotsSet:));
        b.tag = [slotV[i] longLongValue];
        b.frame = CGRectMake(x + (i + 2) * (bw + 8), y, bw, 34);
        [v addSubview:b];
    }
    y += 42;

    UIView *sep3 = [[UIView alloc] initWithFrame:CGRectMake(x, y, cw, 1)];
    sep3.backgroundColor = [accent() colorWithAlphaComponent:0.22];
    [v addSubview:sep3];
    y += 10;

    UILabel *l4 = [[UILabel alloc] initWithFrame:CGRectMake(x, y, cw, 20)];
    l4.text = @"词条 / 刻印 / 物品 / 觉醒（滚轮选择，点「添加」加到选中单位）";
    l4.font = [UIFont boldSystemFontOfSize:14];
    l4.textColor = [UIColor whiteColor];
    [v addSubview:l4];
    y += 24;

    UISegmentedControl *kind = [[UISegmentedControl alloc] initWithItems:@[@"词条", @"刻印", @"物品", @"觉醒"]];
    kind.frame = CGRectMake(x, y, cw, 32);
    kind.selectedSegmentIndex = g_pickerKind;
    styleSegment(kind);
    [kind addTarget:[CheatsOverlay class] action:@selector(pickerKindChanged:) forControlEvents:UIControlEventValueChanged];
    [v addSubview:kind];
    y += 36;

    g_picker = [[UIPickerView alloc] initWithFrame:CGRectMake(x, y, cw, 120)];
    g_picker.dataSource = [CheatsOverlay shared];
    g_picker.delegate = [CheatsOverlay shared];
    [v addSubview:g_picker];
    y += 126;

    UIButton *add = makeButton(@"添加（加到满级）", @selector(addSelected:));
    add.frame = CGRectMake(x, y, cw, 40);
    stylePrimary(add);
    [v addSubview:add];
    y += 48;

    g_replaceBtn = makeButton(@"替换第1个", @selector(replaceFirst:));
    g_replaceBtn.frame = CGRectMake(x, y, cw / 2 - 4, 36);
    [v addSubview:g_replaceBtn];
    g_deleteBtn = makeButton(@"删除第1个", @selector(deleteFirst:));
    g_deleteBtn.frame = CGRectMake(x + cw / 2 + 4, y, cw / 2 - 4, 36);
    [v addSubview:g_deleteBtn];
    y += 44;

    v.frame = CGRectMake(0, 0, w, y);
    return v;
}

// 商店页：物品（背包）批量操作 + 自定义等级
static UIView *build_page_shop(CGFloat w) {
    UIView *v = [[UIView alloc] initWithFrame:CGRectMake(0, 0, w, 400)];
    v.backgroundColor = [UIColor clearColor];
    CGFloat x = 14, y = 8, cw = w - 28;
    CGFloat bw = (cw - 3 * 8) / 4;

    g_shopInfoLabel = [[UILabel alloc] initWithFrame:CGRectMake(x, y, cw, 24)];
    g_shopInfoLabel.font = [UIFont boldSystemFontOfSize:15];
    g_shopInfoLabel.textColor = accent();
    g_shopInfoLabel.text = @"商店 / 背包物品";
    [v addSubview:g_shopInfoLabel];
    y += 32;

    UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(x, y, cw, 20)];
    l.text = @"等级（1-3，稀有物品只有 1 级）";
    l.font = [UIFont systemFontOfSize:13];
    l.textColor = [UIColor whiteColor];
    [v addSubview:l];
    y += 24;

    g_shopLvField = makeNumField(x, y, cw - bw - 8, @"等级");
    [v addSubview:g_shopLvField];
    y += 44;

    UILabel *pl = [[UILabel alloc] initWithFrame:CGRectMake(x, y, cw, 20)];
    pl.text = @"选择物品（滚轮，只加这一个）";
    pl.font = [UIFont systemFontOfSize:13];
    pl.textColor = [UIColor whiteColor];
    [v addSubview:pl];
    y += 24;

    // 物品滚轮：数据来自 cheats_catalog.txt 的 [items] 段
    if (!g_shopPicker) {
        g_shopPicker = [[UIPickerView alloc] initWithFrame:CGRectMake(x, y, cw, 132)];
        g_shopPicker.dataSource = [CheatsOverlay shared];
        g_shopPicker.delegate = [CheatsOverlay shared];
    } else {
        g_shopPicker.frame = CGRectMake(x, y, cw, 132);
    }
    [v addSubview:g_shopPicker];
    y += 138;

    UIButton *one = makeButton(@"加入选中物品（按上面等级）", @selector(shopAddOne:));
    one.frame = CGRectMake(x, y, cw, 40);
    stylePrimary(one);
    [v addSubview:one];
    y += 48;

    UIButton *all = makeButton(@"全部加入背包（按上面的等级）", @selector(itemsAll:));
    all.frame = CGRectMake(x, y, cw, 40);
    stylePrimary(all);
    [v addSubview:all];
    y += 48;

    UIButton *clr = makeButton(@"清空背包", @selector(itemsClear:));
    clr.frame = CGRectMake(x, y, cw, 40);
    styleDanger(clr);
    [v addSubview:clr];
    y += 48;

    UILabel *tip = [[UILabel alloc] initWithFrame:CGRectMake(x, y, cw, 44)];
    tip.text = @"滚轮里选中一个物品 → 「加入选中物品」只加它；「全部加入背包」按等级刷全套。";
    tip.numberOfLines = 0;
    tip.font = [UIFont systemFontOfSize:12];
    tip.textColor = [UIColor colorWithWhite:1 alpha:0.6];
    [v addSubview:tip];
    y += 50;

    v.frame = CGRectMake(0, 0, w, y);
    return v;
}

// ---- 抽奖页：符号锁定 / 品质锁定 / 概率模式 / 每波次数 / 小丑核心 / 小丑英雄 ----
static UIView *build_page_draw(CGFloat w) {
    UIView *v = [[UIView alloc] initWithFrame:CGRectMake(0, 0, w, 620)];
    v.backgroundColor = [UIColor clearColor];
    CGFloat x = 14, y = 8, cw = w - 28;

    // 符号锁定整段删除：与老虎机页「必中大奖」重复
    y = addSectionTitle(v, x, y, cw, @"品质锁定");
    g_gradeRow = [[UIView alloc] initWithFrame:CGRectMake(x, y, cw, 100)];
    [v addSubview:g_gradeRow];
    NSArray *gradeNames = @[ @"关", @"普通", @"高级", @"稀有", @"传说", @"棱彩" ];
    CGFloat bw3 = (cw - 2 * 8) / 3;
    for (NSInteger i = 0; i < (NSInteger)gradeNames.count; i++) {
        UIButton *b = makeButton(gradeNames[i], @selector(gradeLockTapped:));
        b.tag = 200 + i;
        b.frame = CGRectMake((i % 3) * (bw3 + 8), (i / 3) * 50, bw3, 42);
        BOOL on = (i == g_gradeLock);
        b.backgroundColor = on ? accent() : [UIColor colorWithWhite:0.22 alpha:1];
        [b setTitleColor:on ? inkOnGold() : txtPrimary() forState:UIControlStateNormal];
        [g_gradeRow addSubview:b];
    }
    y += 108;

    y = addSectionTitle(v, x, y, cw, @"概率模式（关掉品质锁定后生效）");
    UISegmentedControl *seg = [[UISegmentedControl alloc] initWithItems:@[ @"原版", @"好运", @"逆天", @"均衡" ]];
    seg.frame = CGRectMake(x, y, cw, 34);
    seg.selectedSegmentIndex = g_luckTier;
    styleSegment(seg);
    [seg addTarget:[CheatsOverlay class] action:@selector(luckChanged:) forControlEvents:UIControlEventValueChanged];
    [v addSubview:seg];
    y += 44;

    y = addSectionTitle(v, x, y, cw, @"每波抽奖次数");
    g_spinsWaveLabel = [[UILabel alloc] initWithFrame:CGRectMake(x, y, cw - 140, 40)];
    g_spinsWaveLabel.font = [UIFont boldSystemFontOfSize:17];
    g_spinsWaveLabel.textColor = accent();
    g_spinsWaveLabel.text = g_spinsWave > 0 ? [NSString stringWithFormat:@"当前：%ld 次/波", (long)g_spinsWave] : @"当前：默认";
    [v addSubview:g_spinsWaveLabel];
    UIButton *minus = makeButton(@"－5", @selector(spinsWaveDelta:));
    minus.tag = -5;
    minus.frame = CGRectMake(x + cw - 132, y, 60, 40);
    [v addSubview:minus];
    UIButton *plus = makeButton(@"＋5", @selector(spinsWaveDelta:));
    plus.tag = 5;
    plus.frame = CGRectMake(x + cw - 64, y, 64, 40);
    plus.backgroundColor = accent();
    [v addSubview:plus];
    y += 50;

    y = addSectionTitle(v, x, y, cw, @"小丑核心");
    g_jokerRow = [[UIView alloc] initWithFrame:CGRectMake(x, y, cw, 100)];
    [v addSubview:g_jokerRow];
    NSArray *jokerNames = @[ @"小丑种子", @"百搭小丑", @"黑签", @"丑的微笑" ];
    for (NSInteger i = 0; i < 4; i++) {
        UIButton *b = makeButton(jokerNames[i], @selector(jokerTapped:));
        b.tag = 300 + i;
        b.frame = CGRectMake((i % 2) * ((cw - 8) / 2 + 8), (i / 2) * 50, (cw - 8) / 2, 42);
        BOOL on = ((g_jokerBits >> i) & 1) != 0;
        b.backgroundColor = on ? accent() : [UIColor colorWithWhite:0.22 alpha:1];
        [b setTitleColor:on ? inkOnGold() : txtPrimary() forState:UIControlStateNormal];
        [g_jokerRow addSubview:b];
    }
    y += 108;

    UILabel *jl = [[UILabel alloc] initWithFrame:CGRectMake(x, y, 220, 31)];
    jl.text = @"直接把战场单位变成小丑";
    jl.font = [UIFont systemFontOfSize:15];
    jl.textColor = txtPrimary();
    [v addSubview:jl];
    UISwitch *js = [[UISwitch alloc] initWithFrame:CGRectMake(x + cw - 51, y, 51, 31)];
    js.on = g_jesterHero;
    js.onTintColor = accent();
    [js addTarget:[CheatsOverlay class] action:@selector(jesterChanged:) forControlEvents:UIControlEventValueChanged];
    [v addSubview:js];
    y += 44;

    UILabel *hint = [[UILabel alloc] initWithFrame:CGRectMake(x, y, cw, 40)];
    hint.text = @"品质锁定时概率模式不生效；关掉立即还原。";
    hint.numberOfLines = 0;
    hint.font = [UIFont systemFontOfSize:12];
    hint.textColor = txtDim();
    [v addSubview:hint];
    y += 46;

    v.frame = CGRectMake(0, 0, w, y);
    return v;
}

// ---- 开关页：14 项 ----
static UIView *build_page_sw(CGFloat w) {
    UIView *v = [[UIView alloc] initWithFrame:CGRectMake(0, 0, w, 560)];
    v.backgroundColor = [UIColor clearColor];
    CGFloat x = 14, y = 8, cw = w - 28;

    y = addSectionTitle(v, x, y, cw, @"一键开关（改动实时生效）");
    for (int i = 0; i < kSwCount; i++) {
        UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(x, y + 6, cw - 70, 26)];
        l.text = swLabel(i);
        l.font = [UIFont systemFontOfSize:15];
        l.textColor = txtPrimary();
        [v addSubview:l];
        UISwitch *s = [[UISwitch alloc] initWithFrame:CGRectMake(x + cw - 51, y + 4, 51, 31)];
        s.on = g_swOn[i];
        s.tag = i;
        s.onTintColor = accent();
        [s addTarget:[CheatsOverlay class] action:@selector(swChanged:) forControlEvents:UIControlEventValueChanged];
        [v addSubview:s];
        y += 44;
    }
    UILabel *hint = [[UILabel alloc] initWithFrame:CGRectMake(x, y + 4, cw, 60)];
    hint.text = @"金币/血量/次数类是每帧补写；容量与商店类包游戏取值函数，关掉即还原。";
    hint.numberOfLines = 0;
    hint.font = [UIFont systemFontOfSize:12];
    hint.textColor = txtDim();
    [v addSubview:hint];
    y += 70;

    v.frame = CGRectMake(0, 0, w, y);
    return v;
}

// ---- 存档页 ----
static UIButton *wideButton(NSString *title, SEL action, CGFloat x, CGFloat y, CGFloat w, BOOL primary) {
    UIButton *b = makeButton(title, action);
    b.frame = CGRectMake(x, y, w, 46);
    if (primary) {
        b.backgroundColor = accent();
        [b setTitleColor:inkOnGold() forState:UIControlStateNormal];
    }
    return b;
}

static UIView *build_page_save(CGFloat w) {
    UIView *v = [[UIView alloc] initWithFrame:CGRectMake(0, 0, w, 320)];
    v.backgroundColor = [UIColor clearColor];
    CGFloat x = 14, y = 8, cw = w - 28;

    y = addSectionTitle(v, x, y, cw, @"存档");
    [v addSubview:wideButton(@"立即存档", @selector(saveNow:), x, y, cw, YES)];
    y += 56;
    [v addSubview:wideButton(@"备份当前存档", @selector(saveBackup:), x, y, cw, NO)];
    y += 56;
    [v addSubview:wideButton(@"从备份还原", @selector(saveRestore:), x, y, cw, NO)];
    y += 56;

    UILabel *hint = [[UILabel alloc] initWithFrame:CGRectMake(x, y, cw, 60)];
    hint.text = @"备份写在 save.dat.sb_bak / save_fallback.dat.sb_bak；\n还原后需要重进一局才看到变化。";
    hint.numberOfLines = 0;
    hint.font = [UIFont systemFontOfSize:12];
    hint.textColor = txtDim();
    [v addSubview:hint];
    y += 66;

    y = addSectionTitle(v, x, y, cw, @"重置");
    UIButton *rst = wideButton(@"恢复默认设置（关掉全部修改）", @selector(saveDefaults:), x, y, cw, NO);
    styleDanger(rst);
    [v addSubview:rst];
    y += 60;

    v.frame = CGRectMake(0, 0, w, y);
    return v;
}

// ---- 三页面板 ----
static UISegmentedControl *g_tab = nil;

static void show_page(NSInteger idx) {
    // 0 全局 / 1 老虎机(含抽奖) / 2 单位 / 3 商店 / 4 存档
    g_pageRes.hidden = (idx != 0);
    g_pageSlot.hidden = (idx != 1);
    g_pageUnit.hidden = (idx != 2);
    if (g_pageShop) g_pageShop.hidden = (idx != 3);
    if (g_pageSave) g_pageSave.hidden = (idx != 4);
    if (g_scrollRes) g_scrollRes.hidden = (idx != 0);
    if (g_scrollSlot) g_scrollSlot.hidden = (idx != 1);
    if (g_scrollUnit) g_scrollUnit.hidden = (idx != 2);
    if (g_scrollShop) g_scrollShop.hidden = (idx != 3);
    if (g_scrollSave) g_scrollSave.hidden = (idx != 4);
}

static void refresh_hook_status(void) {
    if (!g_hookLabel) return;
    dispatch_async(dispatch_get_main_queue(), ^{
#ifdef SB_NO_HOOK
        g_hookLabel.text = @"纯 Lua 后端 · 无需 JIT（靠游戏内 trainer_backend.lua）";
        g_hookLabel.textColor = [UIColor colorWithRed:0.2 green:0.7 blue:0.3 alpha:1];
#else
        g_hookLabel.text = g_hookReady ? @"已注入 · 修改实时生效" : @"等待注入…（进一局后生效）";
        g_hookLabel.textColor = g_hookReady ? [UIColor colorWithRed:0.2 green:0.7 blue:0.3 alpha:1] : [UIColor secondaryLabelColor];
#endif
    });
}

// 把若干开关追加到已有页面底部（idxList 是 swKey/swLabel 的下标）
static CGFloat append_switches(UIView *v, CGFloat w, NSArray *idxList, CGFloat y, NSString *title) {
    CGFloat x = 14, cw = w - 28;
    y = addSectionTitle(v, x, y, cw, title);
    for (NSNumber *n in idxList) {
        int i = [n intValue];
        UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(x, y + 6, cw - 70, 26)];
        l.text = swLabel(i);
        l.font = [UIFont systemFontOfSize:15];
        l.textColor = txtPrimary();
        [v addSubview:l];
        UISwitch *s = [[UISwitch alloc] initWithFrame:CGRectMake(x + cw - 51, y + 4, 51, 31)];
        s.on = g_swOn[i];
        s.tag = i;
        s.onTintColor = accent();
        [s addTarget:[CheatsOverlay class] action:@selector(swChanged:) forControlEvents:UIControlEventValueChanged];
        [v addSubview:s];
        y += 44;
    }
    y += 10;
    v.frame = CGRectMake(0, 0, w, y);
    return y;
}

static void sync_window_frame(void) {
    if (!g_win || !g_floatBtn) return;
    CGRect bounds = [UIScreen mainScreen].bounds;
    if (g_open) {
        g_win.frame = bounds;
        g_floatBtn.frame = CGRectMake(g_btnPos.x, g_btnPos.y, kBtnSize, kBtnSize);
    } else {
        g_win.frame = CGRectMake(g_btnPos.x, g_btnPos.y, kBtnSize, kBtnSize);
        g_floatBtn.frame = CGRectMake(0, 0, kBtnSize, kBtnSize);
    }
}
static void close_panel(void) {
    g_open = NO;
    if (g_panel) g_panel.hidden = YES;
    sync_window_frame();
}
static void toggle_panel(void) {
    g_open = !g_open;
    if (g_open) {
        // 后端 catalog 现在按需写，打开面板要一份最新的
        g_cmd = @"catalog";
        g_arg = nil;
        g_arg2 = nil;
        write_cheats();
    }
    if (g_panel) g_panel.hidden = !g_open;
    sync_window_frame();
}

static UIView *build_panel(CGRect bounds) {
    // 不再铺满屏宽：最宽 820，居中
    CGFloat w = MIN(bounds.size.width - 24, 820);
    CGFloat ph = MIN(bounds.size.height - 56, 780);
    UIView *panel = [[UIView alloc] initWithFrame:CGRectMake(0, 0, w, ph)];
    panel.backgroundColor = [UIColor clearColor];
    panel.layer.cornerRadius = 18;
    panel.layer.borderColor = [accent() colorWithAlphaComponent:0.55].CGColor;
    panel.layer.borderWidth = 1.5;
    panel.layer.shadowColor = [UIColor blackColor].CGColor;
    panel.layer.shadowOpacity = 0.55;
    panel.layer.shadowRadius = 18;
    panel.layer.shadowOffset = CGSizeMake(0, 10);
    {
        CAGradientLayer *grad = [CAGradientLayer layer];
        grad.frame = panel.bounds;
        grad.colors = @[ (__bridge id)panelBg().CGColor, (__bridge id)panelBg2().CGColor ];
        grad.startPoint = CGPointMake(0, 0);
        grad.endPoint = CGPointMake(0, 1);
        grad.cornerRadius = 18;
        [panel.layer insertSublayer:grad atIndex:0];
    }

    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(18, 10, w - 80, 26)];
    title.text = @"SLOTBOUND 修改器";
    title.font = [UIFont boldSystemFontOfSize:19];
    title.textColor = accent();
    [panel addSubview:title];

    UILabel *ver = [[UILabel alloc] initWithFrame:CGRectMake(18, 36, w - 80, 14)];
    ver.text = [NSString stringWithFormat:@"%s · 金色按钮是主操作", SB_PANEL_VERSION];
    ver.font = [UIFont systemFontOfSize:11];
    ver.textColor = txtDim();
    [panel addSubview:ver];

    UIButton *close = makeButton(@"✕", @selector(closeTapped));
    close.frame = CGRectMake(w - 52, 12, 34, 34);
    close.layer.cornerRadius = 17;
    close.backgroundColor = [UIColor colorWithWhite:1 alpha:0.12];
    [panel addSubview:close];

    g_hookLabel = [[UILabel alloc] initWithFrame:CGRectMake(18, 54, w - 36, 14)];
    g_hookLabel.font = [UIFont systemFontOfSize:11];
    g_hookLabel.textColor = txtDim();
    [panel addSubview:g_hookLabel];
    refresh_hook_status();

    g_tab = [[UISegmentedControl alloc] initWithItems:@[ @"全局", @"老虎机", @"单位", @"商店", @"存档" ]];
    g_tab.frame = CGRectMake(16, 74, w - 32, 34);
    g_tab.selectedSegmentIndex = 0;
    styleSegment(g_tab);
    [g_tab addTarget:[CheatsOverlay class] action:@selector(tabChanged:) forControlEvents:UIControlEventValueChanged];
    [panel addSubview:g_tab];

    // 页签下面一条金线，和内容分开
    UIView *headLine = [[UIView alloc] initWithFrame:CGRectMake(0, 116, w, 1)];
    headLine.backgroundColor = [accent() colorWithAlphaComponent:0.22];
    [panel addSubview:headLine];

    // 点空白处收键盘（点在输入框上不收，否则刚点就失焦）
    UITapGestureRecognizer *tapBg = [[UITapGestureRecognizer alloc]
        initWithTarget:[CheatsOverlay class] action:@selector(panelTapped:)];
    tapBg.cancelsTouchesInView = NO;
    [panel addGestureRecognizer:tapBg];

    // 四个页面各自一个 UIScrollView：各自独立滚动、独立回弹
    CGRect srect = CGRectMake(0, 118, w, ph - 118 - 26);
    UIScrollView *(^mkscroll)(void) = ^UIScrollView *{
        UIScrollView *s = [[UIScrollView alloc] initWithFrame:srect];
        s.backgroundColor = [UIColor clearColor];
        s.alwaysBounceVertical = YES;
        s.showsVerticalScrollIndicator = YES;
        s.indicatorStyle = UIScrollViewIndicatorStyleWhite;
        s.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag; // 拖动就收键盘
        [panel addSubview:s];
        return s;
    };
    g_scrollRes = mkscroll();
    g_scrollSlot = mkscroll();
    g_scrollUnit = mkscroll();
    g_scrollShop = mkscroll();
    g_scrollSave = mkscroll();

    // 每页单独 try：某一页写崩了也不至于整个 app 起不来
    // 归并：开关按功能散到各页，抽奖区并入老虎机页
    @try {
        g_pageRes = build_page_res(w - 28);
        // 页面顶部插一个「一键恢复原版」：整体下移 62pt，按钮独占首行
        CGFloat pw = w - 28, shift = 62;
        for (UIView *sv in g_pageRes.subviews) {
            CGRect f = sv.frame; f.origin.y += shift; sv.frame = f;
        }
        g_pageRes.frame = CGRectMake(0, 0, pw, g_pageRes.frame.size.height + shift);
        UIButton *rst = wideButton(@"一键恢复所有改动（回到原版）", @selector(resetAllTapped:), 14, 8, pw - 28, NO);
        [g_pageRes addSubview:rst];
        append_switches(g_pageRes, pw,
                        @[ @(9) /*开局超级加成*/, @(4) /*基地无敌*/ ],
                        g_pageRes.frame.size.height + 6, @"开关");
    }
    @catch (NSException *e) { NSLog(@"[SBTrainer] page RES: %@", e.reason); g_pageRes = [[UIView alloc] initWithFrame:CGRectZero]; }
    @try {
        g_pageSlot = build_page_slot(w - 28);
        CGFloat y = append_switches(g_pageSlot, w - 28,
                        @[ @(1) /*免费抽奖*/, @(2) /*必中大奖*/, @(3) /*必出英雄*/,
                           @(7) /*无限免费抽*/, @(6) /*核心重掷不限*/, @(13) /*战斗加速×2*/ ],
                        g_pageSlot.frame.size.height + 6, @"开关");
        UIView *draw = build_page_draw(w - 28);
        draw.frame = CGRectMake(0, y + 4, w - 28, draw.frame.size.height);
        [g_pageSlot addSubview:draw];
        g_pageSlot.frame = CGRectMake(0, 0, w - 28, y + 4 + draw.frame.size.height + 16);
    }
    @catch (NSException *e) { NSLog(@"[SBTrainer] page SLOT: %@", e.reason); g_pageSlot = [[UIView alloc] initWithFrame:CGRectZero]; }
    @try {
        g_pageUnit = build_page_unit(w - 28);
        append_switches(g_pageUnit, w - 28, @[ @(10) /*单位容量 99*/ ],
                        g_pageUnit.frame.size.height + 6, @"开关");
    }
    @catch (NSException *e) { NSLog(@"[SBTrainer] page UNIT: %@", e.reason); g_pageUnit = [[UIView alloc] initWithFrame:CGRectZero]; }
    @try {
        g_pageShop = build_page_shop(w - 28);
        append_switches(g_pageShop, w - 28,
                        @[ @(11) /*物品容量 99*/, @(12) /*商店刷新不限*/ ],
                        g_pageShop.frame.size.height + 6, @"开关");
    }
    @catch (NSException *e) { NSLog(@"[SBTrainer] page SHOP: %@", e.reason); g_pageShop = [[UIView alloc] initWithFrame:CGRectZero]; }
    @try { g_pageSave = build_page_save(w - 28); }
    @catch (NSException *e) { NSLog(@"[SBTrainer] page SAVE: %@", e.reason); g_pageSave = [[UIView alloc] initWithFrame:CGRectZero]; }
    [g_scrollRes addSubview:g_pageRes];
    [g_scrollSlot addSubview:g_pageSlot];
    [g_scrollUnit addSubview:g_pageUnit];
    [g_scrollShop addSubview:g_pageShop];
    [g_scrollSave addSubview:g_pageSave];
    g_scrollRes.contentSize = g_pageRes.frame.size;
    g_scrollSlot.contentSize = g_pageSlot.frame.size;
    g_scrollUnit.contentSize = g_pageUnit.frame.size;
    g_scrollShop.contentSize = g_pageShop.frame.size;
    g_scrollSave.contentSize = g_pageSave.frame.size;

    // 左下角：项目主页（点一下开浏览器）
    UIButton *link = [UIButton buttonWithType:UIButtonTypeSystem];
    link.frame = CGRectMake(14, ph - 24, w - 28, 22);
    link.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [link setTitle:@"项目主页 · github.com/Yakult00/Slotbound-iOS" forState:UIControlStateNormal];
    [link setTitleColor:[accent() colorWithAlphaComponent:0.85] forState:UIControlStateNormal];
    link.titleLabel.font = [UIFont systemFontOfSize:11];
    [link addTarget:[CheatsOverlay class] action:@selector(linkTapped:) forControlEvents:UIControlEventTouchUpInside];
    [panel addSubview:link];

    show_page(0);
    return panel;
}

// ---- CheatsOverlay 实现 ----
@implementation CheatsOverlay

+ (instancetype)shared {
    static CheatsOverlay *s;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ s = [[CheatsOverlay alloc] init]; });
    return s;
}

+ (void)closeTapped { close_panel(); }
+ (void)floatTapped:(id)s { toggle_panel(); }
+ (void)tabChanged:(UISegmentedControl *)sc { show_page(sc.selectedSegmentIndex); }

+ (void)panButton:(UIPanGestureRecognizer *)gr {
    if (!g_win || g_open) return;
    if (gr.state == UIGestureRecognizerStateBegan) {
        g_totalDrag = 0;
    } else if (gr.state == UIGestureRecognizerStateChanged) {
        CGPoint t = [gr translationInView:g_win];
        g_totalDrag += fabs(t.x) + fabs(t.y);
        CGRect bounds = [UIScreen mainScreen].bounds;
        CGRect f = g_win.frame;
        CGFloat nx = f.origin.x + t.x;
        CGFloat ny = f.origin.y + t.y;
        nx = MAX(0, MIN(bounds.size.width - f.size.width, nx));
        ny = MAX(0, MIN(bounds.size.height - f.size.height, ny));
        f.origin = CGPointMake(nx, ny);
        g_win.frame = f;
        g_btnPos = f.origin;
        [gr setTranslation:CGPointZero inView:g_win];
    }
}

+ (void)coinAdd:(UIButton *)b { g_coinAdd = b.tag; write_cheats(); }
+ (void)coinSet:(UIButton *)b { g_coinSet = b.tag; write_cheats(); }

// ---- 自定义数值（读输入框）----
+ (void)coinSetText:(id)s {
    long long v = (long long)[[g_coinField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] longLongValue];
    if (v <= 0) return;
    g_coinSet = v;
    write_cheats();
}
+ (void)spinsSetText:(id)s {
    long long v = (long long)[g_spinsField.text longLongValue];
    if (v <= 0) return;
    g_spinsSet = v;
    write_cheats();
}
+ (void)jungsuSetText:(id)s {
    long long v = (long long)[g_jungsuField.text longLongValue];
    if (v <= 0) return;
    g_jungsuSet = v;
    write_cheats();
}
+ (void)absorbSetText:(id)s {
    long long v = (long long)[g_absorbField.text longLongValue];
    if (v <= 0) return;
    send_command(@"set_absorb_lv", [NSString stringWithFormat:@"%lld", v], nil);
}
+ (void)itemsAll:(id)s {
    long long lv = (long long)[g_shopLvField.text longLongValue];
    if (lv <= 0) lv = 1;
    send_command(@"items_all", [NSString stringWithFormat:@"%lld", lv], nil);
}
+ (void)itemsClear:(id)s { send_command(@"items_clear", nil, nil); }

// 商店页：只加滚轮里选中的那一个物品
+ (void)shopAddOne:(id)s {
    if (!g_items || g_items.count == 0) { show_toast(@"⚠ 物品表未就绪，重开面板试试"); return; }
    NSInteger row = g_shopPicker ? [g_shopPicker selectedRowInComponent:0] : 0;
    if (row < 0 || row >= (NSInteger)g_items.count) return;
    NSDictionary *d = g_items[row];
    NSString *idStr = d[@"id"];
    long long lv = (long long)[g_shopLvField.text longLongValue];
    if (lv <= 0) lv = 1;
    long long maxL = [d[@"maxLevel"] longLongValue];
    if (maxL < 1) maxL = 1;
    if (lv > maxL) lv = maxL;
    send_command(@"add_item", [NSString stringWithFormat:@"\"%@\"", idStr], [NSString stringWithFormat:@"%lld", lv]);
    show_toast([NSString stringWithFormat:@"✓ 已加入 %@ Lv%lld", idStr, lv]);
}

+ (void)btnDown:(UIButton *)b { tap_haptic(); }

// 点面板空白处收键盘（点输入框本身不处理，否则一点就失焦）
+ (void)panelTapped:(UITapGestureRecognizer *)g {
    if (!g_panel) return;
    CGPoint p = [g locationInView:g_panel];
    UIView *hit = [g_panel hitTest:p withEvent:nil];
    if ([hit isKindOfClass:[UITextField class]] || [hit isKindOfClass:[UITextView class]]) return;
    [g_panel endEditing:YES];
}
+ (void)spinsAdd:(UIButton *)b { g_spinsAdd = b.tag; write_cheats(); }
+ (void)spinsSet:(UIButton *)b { g_spinsSet = b.tag; write_cheats(); }
+ (void)jungsuSet:(UIButton *)b { g_jungsuSet = b.tag; write_cheats(); }

+ (void)originiteAdd:(UIButton *)b { g_originiteAdd = b.tag; write_cheats(); tap_haptic(); }
+ (void)originiteSet:(UIButton *)b { g_originiteSet = b.tag; write_cheats(); tap_haptic(); }
+ (void)originiteSetText:(id)s {
    long long v = (long long)[g_originiteField.text longLongValue];
    if (v <= 0) return;
    g_originiteSet = v;
    write_cheats();
}
+ (void)originiteLockChanged:(UISwitch *)sw {
    g_lockOriginite = sw.isOn;
    g_lockOriginiteTarget = g_lastOriginite;
    write_cheats();
}

// 老虎机页：把滚轮选中的核心加进当前 run（= 老虎机抽到它）
+ (void)addCoreTapped:(UIButton *)b {
    if (!g_cores || g_cores.count == 0) return;
    NSInteger row = g_corePicker ? [g_corePicker selectedRowInComponent:0] : 0;
    if (row < 0 || row >= (NSInteger)g_cores.count) return;
    NSString *cid = g_cores[row][@"id"];
    long long v = (long long)[cid integerValue];
    if (v <= 0) return;
    g_coreAdd = v;
    write_cheats();
}

+ (void)addAllCoresTapped:(UIButton *)b {
    g_coreAddAll = 1;
    write_cheats();
}

// 关卡 / 无尽：把 6 关 × 3 难度全部写成已通关（存档层），退出重进后选关界面全开
+ (void)unlockAllStages:(UIButton *)b {
    g_runLua =
        @"local S=require('src.save'); local t=S.load(); "
         "t.unlockedStages=t.unlockedStages or {}; "
         "t.unlockedDifficulties=t.unlockedDifficulties or {}; "
         "t.clearedDifficulties=t.clearedDifficulties or {}; "
         "for i=1,6 do t.unlockedStages[i]=true; "
         "local u=t.unlockedDifficulties[i] or {}; local c=t.clearedDifficulties[i] or {}; "
         "for d=1,3 do u[d]=true; c[d]=true end; "
         "t.unlockedDifficulties[i]=u; t.clearedDifficulties[i]=c end; "
         "t.newStages={}; "
         "local ok=pcall(S.save,t); "
         "if not ok then love.filesystem.write(S._lastSavePath,S.serialize(t)) end";
    write_cheats();
}

+ (void)jungsuAdd:(UIButton *)b {
    long long add = b.tag;
    g_runLua = [NSString stringWithFormat:
        @"jungsu = (jungsu or 0) + %lld; "
        @"local u = _G.ui; if u and type(u.jungsuBalanceTarget)=='number' then u.jungsuBalanceTarget = jungsu end",
        add];
    write_cheats();
}

+ (void)lockChanged:(UISwitch *)sw {
    g_lockCoins = sw.isOn;
    g_lockTarget = g_lastCoins;
    write_cheats();
}

+ (void)spinsLockChanged:(UISwitch *)sw {
    g_lockSpins = sw.isOn;
    g_lockSpinsTarget = g_lastSpins;
    write_cheats();
}

+ (void)jungsuLockChanged:(UISwitch *)sw {
    g_lockJungsu = sw.isOn;
    g_lockJungsuTarget = g_lastJungsu;
    write_cheats();
}

+ (void)jackpotChanged:(UISwitch *)sw {
    if (sw.isOn) { if (!g_jackpot) g_jackpot = @"W"; }
    else {
        g_jackpot = nil;
        // 关掉大奖时把符号按钮的高亮也清掉
        for (UIView *sv in g_pageSlot.subviews) {
            if ([sv isKindOfClass:[UIButton class]]) {
                sv.backgroundColor = [UIColor colorWithWhite:0.22 alpha:1];
            }
        }
    }
    write_cheats();
}

+ (void)symTapped:(UIButton *)b {
    NSArray *defs = symDefs();
    if (b.tag < 0 || b.tag >= (NSInteger)defs.count) return;
    g_jackpot = defs[b.tag][@"key"];
    if (g_jackpotSwitch) g_jackpotSwitch.on = YES; // 选了符号 = 开大奖
    for (UIView *sv in b.superview.subviews) {
        if ([sv isKindOfClass:[UIButton class]]) {
            UIButton *btn = (UIButton *)sv;
            btn.backgroundColor = (btn == b) ? accent() : [UIColor colorWithWhite:0.22 alpha:1];
        }
    }
    write_cheats();
}

+ (void)absorbAction:(UIButton *)b {
    // 全部走后端：后端知道怎么找"当前选中单位"，比在面板里拼 Lua 靠谱
    if (b.tag >= 100) {
        send_command(@"set_absorb_lv", [NSString stringWithFormat:@"%ld", (long)b.tag], nil);
    } else {
        send_command(@"absorb_add", [NSString stringWithFormat:@"%ld", (long)b.tag], nil);
    }
}

+ (void)rankAction:(UIButton *)b {
    send_command(@"raise_rank", [NSString stringWithFormat:@"%ld", (long)b.tag], nil);
}

+ (void)statAction:(UIButton *)b {
    NSArray *keys = @[@"hp", @"atk", @"aspd", @"distance"];
    if (b.tag < 0 || b.tag >= (NSInteger)keys.count) return;
    send_command(@"mul_stat", [NSString stringWithFormat:@"\"%@\"", keys[b.tag]], @"2");
}

// 主动技能冷却：tag = 秒数×10（1=0.1s, 5=0.5s, 10=1s, 20=2s），-10 = 恢复原版。
+ (void)cdSet:(UIButton *)b {
    double sec = b.tag / 10.0;
    send_command(@"set_skill_cd", [NSString stringWithFormat:@"%g", sec], nil);
}

// 被动技能参数微调：tag = idx*2（−）/ idx*2+1（+）。
+ (void)skillParamDelta:(UIButton *)b {
    NSArray *defs = skillParamDefs();
    NSInteger idx = b.tag / 2;
    BOOL plus = (b.tag % 2) == 1;
    if (idx < 0 || idx >= (NSInteger)defs.count) return;
    NSString *key = defs[idx][@"key"];
    double cur = [g_skillParams[key][@"cur"] doubleValue];
    double step = [defs[idx][@"step"] doubleValue];
    double nv = cur + (plus ? step : -step);
    if ([key isEqualToString:@"charges"]) nv = MAX(1, round(nv));
    else nv = MAX(0, nv);
    send_command(@"set_passive", [NSString stringWithFormat:@"\"%@\"", key], [NSString stringWithFormat:@"%g", nv]);
}

// 被动技能参数恢复原版。
+ (void)skillParamReset:(UIButton *)b {
    NSArray *defs = skillParamDefs();
    if (b.tag < 0 || b.tag >= (NSInteger)defs.count) return;
    send_command(@"set_passive", [NSString stringWithFormat:@"\"%@\"", defs[b.tag][@"key"]], nil);
}

+ (void)slotsSet:(UIButton *)b {
    send_command(@"set_imprint_slots", [NSString stringWithFormat:@"%ld", (long)b.tag], nil);
}

+ (void)pickerKindChanged:(UISegmentedControl *)sc {
    g_pickerKind = sc.selectedSegmentIndex;
    if (g_picker) [g_picker reloadAllComponents];
    if (g_shopPicker) [g_shopPicker reloadAllComponents];
    // 物品那档「删除」删的是滚轮选中的那件，其他档删第 1 个
    if (g_replaceBtn) [g_replaceBtn setTitle:(g_pickerKind == 2 ? @"替换该物品" : @"替换第1个") forState:UIControlStateNormal];
    if (g_deleteBtn) [g_deleteBtn setTitle:(g_pickerKind == 2 ? @"删除该物品" : @"删除第1个") forState:UIControlStateNormal];
}

+ (NSMutableArray *)pickerArray {
    if (g_pickerKind == 0) return g_options;
    if (g_pickerKind == 1) return g_imprints;
    if (g_pickerKind == 2) return g_items;
    return g_awakenings;
}

+ (void)addSelected:(UIButton *)b {
    NSMutableArray *cur = [self pickerArray];
    if (!cur || cur.count == 0) return;
    NSInteger row = g_picker ? [g_picker selectedRowInComponent:0] : 0;
    if (row < 0 || row >= (NSInteger)cur.count) return;
    NSDictionary *d = cur[row];
    NSString *idStr = d[@"id"];
    NSInteger maxL = [d[@"maxLevel"] integerValue];
    if (maxL < 1) maxL = 1;
    if (g_pickerKind == 0) {
        send_command(@"add_option", [NSString stringWithFormat:@"\"%@\"", idStr], nil);
    } else if (g_pickerKind == 1) {
        send_command(@"add_imprint", [NSString stringWithFormat:@"\"%@\"", idStr], [NSString stringWithFormat:@"%ld", (long)maxL]);
    } else if (g_pickerKind == 2) {
        send_command(@"add_item", [NSString stringWithFormat:@"\"%@\"", idStr], [NSString stringWithFormat:@"%ld", (long)maxL]);
    } else {
        send_command(@"add_awakening", [NSString stringWithFormat:@"\"%@\"", idStr], nil);
    }
}

+ (void)replaceFirst:(UIButton *)b {
    NSMutableArray *cur = [self pickerArray];
    if (!cur || cur.count == 0) return;
    NSInteger row = g_picker ? [g_picker selectedRowInComponent:0] : 0;
    if (row < 0 || row >= (NSInteger)cur.count) return;
    NSDictionary *d = cur[row];
    NSString *idStr = d[@"id"];
    NSInteger maxL = [d[@"maxLevel"] integerValue];
    if (maxL < 1) maxL = 1;
    if (g_pickerKind == 0) {
        send_command(@"replace_option", [NSString stringWithFormat:@"\"%@\"", idStr], @"1");
    } else if (g_pickerKind == 1) {
        send_command(@"replace_imprint", [NSString stringWithFormat:@"\"%@\"", idStr], @"1");
    } else if (g_pickerKind == 2) {
        send_command(@"replace_item", [NSString stringWithFormat:@"\"%@\"", idStr], [NSString stringWithFormat:@"%ld", (long)maxL]);
    } else {
        send_command(@"replace_awakening", [NSString stringWithFormat:@"\"%@\"", idStr], @"1");
    }
}

+ (void)deleteFirst:(UIButton *)b {
    NSMutableArray *cur = [self pickerArray];
    if (!cur || cur.count == 0) return;
    NSInteger row = g_picker ? [g_picker selectedRowInComponent:0] : 0;
    if (row < 0 || row >= (NSInteger)cur.count) return;
    NSDictionary *d = cur[row];
    NSString *idStr = d[@"id"];
    if (g_pickerKind == 0) {
        send_command(@"remove_option", @"1", nil);
    } else if (g_pickerKind == 1) {
        send_command(@"remove_imprint", @"1", nil);
    } else if (g_pickerKind == 2) {
        send_command(@"remove_item", [NSString stringWithFormat:@"\"%@\"", idStr], nil);
    } else {
        send_command(@"remove_awakening", @"1", nil);
    }
}

// ---- 抽奖 / 开关 / 存档 交互 ----
+ (void)symLockTapped:(UIButton *)b {
    g_symLock = (NSInteger)b.tag - 100;
    restyleRow(g_symRow, 100, g_symLock);
    write_cheats();
    tap_haptic();
}

+ (void)gradeLockTapped:(UIButton *)b {
    g_gradeLock = (NSInteger)b.tag - 200;
    restyleRow(g_gradeRow, 200, g_gradeLock);
    write_cheats();
    tap_haptic();
}

+ (void)luckChanged:(UISegmentedControl *)sc {
    g_luckTier = sc.selectedSegmentIndex;
    if (g_luckTier < 0) g_luckTier = 0;
    write_cheats();
    tap_haptic();
}

+ (void)spinsWaveDelta:(UIButton *)b {
    NSInteger v = g_spinsWave + (NSInteger)b.tag;
    if (v < 0) v = 0;
    if (v > 99) v = 99;
    g_spinsWave = v;
    g_spinsWaveLabel.text = v > 0 ? [NSString stringWithFormat:@"当前：%ld 次/波", (long)v] : @"当前：默认";
    write_cheats();
    tap_haptic();
}

+ (void)jokerTapped:(UIButton *)b {
    NSInteger i = (NSInteger)b.tag - 300;
    if (i < 0 || i > 3) return;
    g_jokerBits ^= (1LL << i);
    restyleRow(g_jokerRow, 300, -1);
    for (UIView *v in g_jokerRow.subviews) {
        if (![v isKindOfClass:[UIButton class]]) continue;
        NSInteger k = (NSInteger)v.tag - 300;
        BOOL on = ((g_jokerBits >> k) & 1) != 0;
        v.backgroundColor = on ? accent() : [UIColor colorWithWhite:0.22 alpha:1];
        [(UIButton *)v setTitleColor:on ? inkOnGold() : txtPrimary() forState:UIControlStateNormal];
    }
    write_cheats();
    tap_haptic();
}

+ (void)jesterChanged:(UISwitch *)sw {
    g_jesterHero = sw.isOn;
    write_cheats();
    tap_haptic();
}

+ (void)swChanged:(UISwitch *)sw {
    NSInteger i = (NSInteger)sw.tag;
    if (i < 0 || i >= kSwCount) return;
    g_swOn[i] = sw.isOn;
    write_cheats();
    tap_haptic();
}

+ (void)saveNow:(id)s { send_command(@"save_now", nil, nil); }
+ (void)saveBackup:(id)s { send_command(@"save_backup", nil, nil); }
+ (void)saveRestore:(id)s { send_command(@"save_restore", nil, nil); }

+ (void)saveDefaults:(id)s { [CheatsOverlay doResetAll]; }

// 一键恢复原版：关掉全部开关/锁定/抽奖改动，并清掉一次性命令
+ (void)doResetAll {
    for (int i = 0; i < kSwCount; i++) g_swOn[i] = NO;
    g_symLock = g_gradeLock = g_luckTier = g_spinsWave = 0;
    g_jokerBits = 0;
    g_jesterHero = NO;
    g_lockCoins = g_lockSpins = g_lockJungsu = g_lockOriginite = NO;
    g_lockTarget = g_lockSpinsTarget = g_lockJungsuTarget = g_lockOriginiteTarget = 0;
    g_originiteSet = 0;
    g_originiteAdd = 0;
    g_cmd = nil; g_arg = nil; g_arg2 = nil;

    // UI 同步：所有页面上的开关回关，锁定开关回关
    NSArray *pages = @[ g_pageRes ?: (id)[NSNull null], g_pageSlot ?: (id)[NSNull null],
                        g_pageUnit ?: (id)[NSNull null], g_pageShop ?: (id)[NSNull null],
                        g_pageSave ?: (id)[NSNull null] ];
    for (id p in pages) {
        if (![p isKindOfClass:[UIView class]]) continue;
        for (UIView *sv in [(UIView *)p subviews]) {
            if ([sv isKindOfClass:[UISwitch class]]) ((UISwitch *)sv).on = NO;
        }
    }
    g_lockSwitch.on = g_spinsLockSwitch.on = NO;
    g_jungsuLockSwitch.on = g_originiteLockSwitch.on = NO;

    send_command(@"reset_all", nil, nil);
    show_toast(@"✓ 已恢复原版，重开面板后生效");
}

+ (void)resetAllTapped:(id)s {
    UIAlertController *ac = [UIAlertController alertControllerWithTitle:@"恢复原版游戏"
                                                              message:@"会关掉全部开关、锁定和抽奖改动，确定？"
                                                       preferredStyle:UIAlertControllerStyleAlert];
    [ac addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [ac addAction:[UIAlertAction actionWithTitle:@"恢复原版" style:UIAlertActionStyleDestructive
                                        handler:^(UIAlertAction *a) { [CheatsOverlay doResetAll]; }]];
    UIViewController *vc = g_win ? g_win.rootViewController : nil;
    if (!vc) return;
    UIViewController *top = vc;
    while (top.presentedViewController) top = top.presentedViewController;
    [top presentViewController:ac animated:YES completion:nil];
}

+ (void)clearCoresTapped:(id)s {
    UIAlertController *ac = [UIAlertController alertControllerWithTitle:@"清除所有核心"
                                                              message:@"会移除当前已激活的全部核心（不清背包里的核心图鉴），确定？"
                                                       preferredStyle:UIAlertControllerStyleAlert];
    [ac addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [ac addAction:[UIAlertAction actionWithTitle:@"全部清除" style:UIAlertActionStyleDestructive
                                        handler:^(UIAlertAction *a) {
                                            send_command(@"cores_clear", nil, nil);
                                            // 命令槽只有一个：catalog 必须延后发，否则会顶掉 cores_clear
                                            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                                send_command(@"catalog", nil, nil);
                                            });
                                            show_toast(@"✓ 已清除所有核心");
                                        }]];
    UIViewController *vc = g_win ? g_win.rootViewController : nil;
    if (!vc) return;
    UIViewController *top = vc;
    while (top.presentedViewController) top = top.presentedViewController;
    [top presentViewController:ac animated:YES completion:nil];
}

+ (void)linkTapped:(id)s {
    NSURL *u = [NSURL URLWithString:@"https://github.com/Yakult00/Slotbound-iOS"];
    UIApplication *app = [UIApplication sharedApplication];
    if ([app respondsToSelector:@selector(openURL:options:completionHandler:)]) {
        [app openURL:u options:@{} completionHandler:nil];
    } else {
        [app openURL:u];
    }
}

// ---- UIPickerView 数据源 / 代理 ----
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pv { return 1; }
- (NSInteger)pickerView:(UIPickerView *)pv numberOfRowsInComponent:(NSInteger)component {
    if (pv == g_corePicker) return g_cores ? (NSInteger)g_cores.count : 0;
    if (pv == g_shopPicker) return g_items ? (NSInteger)g_items.count : 0;
    NSMutableArray *cur = [CheatsOverlay pickerArray];
    return cur ? (NSInteger)cur.count : 0;
}
- (void)pickerView:(UIPickerView *)pv didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    [pv reloadComponent:component];
}

- (NSAttributedString *)pickerView:(UIPickerView *)pv attributedTitleForRow:(NSInteger)row forComponent:(NSInteger)component {
    NSString *s = [self pickerView:pv titleForRow:row forComponent:component];
    UIColor *c = ([pv selectedRowInComponent:component] == row) ? accent() : txtPrimary();
    return [[NSAttributedString alloc] initWithString:(s ?: @"")
                                           attributes:@{ NSForegroundColorAttributeName: c,
                                                         NSFontAttributeName: [UIFont boldSystemFontOfSize:15] }];
}

- (NSString *)pickerView:(UIPickerView *)pv titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    if (pv == g_corePicker) {
        if (!g_cores || row < 0 || row >= (NSInteger)g_cores.count) return @"";
        NSDictionary *c = g_cores[row];
        NSString *suffix = [c[@"owned"] intValue] ? @"（已拥有）" : @"";
        return [NSString stringWithFormat:@"%@ %@ · %@%@", c[@"id"], c[@"name"], zh_rarity(c[@"rarity"]), suffix];
    }
    if (pv == g_shopPicker) {
        if (!g_items || row < 0 || row >= (NSInteger)g_items.count) return @"";
        NSDictionary *d = g_items[row];
        return [NSString stringWithFormat:@"%@ %@（满级%@）", d[@"id"], d[@"name"], d[@"maxLevel"] ?: @"1"];
    }
    NSMutableArray *cur = [CheatsOverlay pickerArray];
    if (!cur || row < 0 || row >= (NSInteger)cur.count) return @"";
    NSDictionary *d = cur[row];
    if (g_pickerKind == 0) return [NSString stringWithFormat:@"%@ %@", d[@"id"], d[@"name"]];
    return [NSString stringWithFormat:@"%@ %@（满级%@）", d[@"id"], d[@"name"], d[@"maxLevel"] ?: @"1"];
}

+ (void)setup {
    if (g_win) return;
    g_skillParams = [NSMutableDictionary dictionary];

    dispatch_async(dispatch_get_main_queue(), ^{
        CGRect bounds = [UIScreen mainScreen].bounds;
        g_btnPos = CGPointMake(bounds.size.width - kBtnSize - 12, 96);
        g_win = [[UIWindow alloc] initWithFrame:CGRectMake(g_btnPos.x, g_btnPos.y, kBtnSize, kBtnSize)];
        g_win.windowLevel = UIWindowLevelAlert + 1;
        if (@available(iOS 13.0, *)) g_win.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
        g_win.backgroundColor = [UIColor clearColor];
        g_win.hidden = NO;

        UIViewController *vc = [[UIViewController alloc] init];
        PassthroughView *root = [[PassthroughView alloc] initWithFrame:g_win.bounds];
        root.backgroundColor = [UIColor clearColor];
        root.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        vc.view = root;
        g_win.rootViewController = vc;

        g_floatBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        g_floatBtn.frame = CGRectMake(0, 0, kBtnSize, kBtnSize);
        g_floatBtn.layer.cornerRadius = kBtnSize / 2;
        g_floatBtn.clipsToBounds = YES;
        g_floatBtn.layer.borderColor = accent().CGColor;
        g_floatBtn.layer.borderWidth = 2.5;
        g_floatBtn.backgroundColor = [UIColor colorWithRed:0.09 green:0.07 blue:0.14 alpha:0.92];
        g_floatBtn.layer.shadowColor = [UIColor blackColor].CGColor;
        g_floatBtn.layer.shadowOpacity = 0.5;
        g_floatBtn.layer.shadowRadius = 8;
        g_floatBtn.layer.shadowOffset = CGSizeMake(0, 3);
        NSData *iconData = [[NSData alloc] initWithBase64EncodedString:kIconBase64 options:0];
        if (iconData) {
            UIImage *icon = [UIImage imageWithData:iconData];
            if (icon) [g_floatBtn setImage:icon forState:UIControlStateNormal];
        }
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:[CheatsOverlay class] action:@selector(floatTapped:)];
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:[CheatsOverlay class] action:@selector(panButton:)];
        [tap requireGestureRecognizerToFail:pan];
        [g_floatBtn addGestureRecognizer:tap];
        [g_floatBtn addGestureRecognizer:pan];
        [root addSubview:g_floatBtn];

        g_panel = build_panel(bounds);
        g_panel.hidden = YES;
        {
            CGSize ps = g_panel.frame.size;
            g_panel.frame = CGRectMake((bounds.size.width - ps.width) / 2,
                                       (bounds.size.height - ps.height) / 2,
                                       ps.width, ps.height);
        }
        [root addSubview:g_panel];

        // 面板关着的时候完全不读文件；开着时 1Hz 读状态，并每 2 秒 touch
        // cheats_alive.txt —— 游戏后端据此决定 1Hz 还是 0.125Hz 写状态文件。
        [NSTimer scheduledTimerWithTimeInterval:1.0 repeats:YES block:^(NSTimer *t) {
            if (!g_open) return;
            read_status();
            read_catalog();
            static double lastAlive = 0;
            double now = [NSDate timeIntervalSinceReferenceDate];
            if (now - lastAlive >= 2.0) {
                lastAlive = now;
                NSString *dir = find_save_dir();
                if (dir) {
                    NSString *p2 = [dir stringByAppendingPathComponent:@"cheats_alive.txt"];
                    [[NSString stringWithFormat:@"%.0f\n", now]
                        writeToFile:p2 atomically:YES encoding:NSUTF8StringEncoding error:nil];
                }
            }
        }];
        read_status();
        read_catalog();
        refresh_hook_status();
    });
}

@end

static void setup_ui(void) {
    g_luaQueue = [NSMutableArray array];
    g_queueLock = [[NSLock alloc] init];
    [CheatsOverlay setup];
}

// 延迟初始化线程：等 3 秒让进程完全加载、dyld 完成，再做所有工作。
// （constructor 时期 _dyld_get_image_header(0) 拿不到符号表，全部返回 NULL；
//  延迟到游戏跑起来之后再解析，符号表一定在。）
static void *delayed_init_thread(void *arg) {
    (void)arg;
    sleep(3);
    // 调试：把符号解析与 hook 结果写到存档目录。纯 C 取 HOME（数据容器根目录）。
    const char *home = getenv("HOME");
    char dbgPath[1024];
    if (home) {
        snprintf(dbgPath, sizeof(dbgPath), "%s/Library/Application Support/slotbound_full/sbtrainer_debug.txt", home);
    } else {
        snprintf(dbgPath, sizeof(dbgPath), "/tmp/sbtrainer_debug.txt");
    }
    FILE *dbg = fopen(dbgPath, "w");
#define STEP(fmt, ...) do { if (dbg) { fprintf(dbg, fmt "\n", ##__VA_ARGS__); fflush(dbg); } } while (0)
    STEP("step0 start pid=%d", getpid());
    if (dbg) {
        uint32_t nImg = _dyld_image_count();
        STEP("step1 images=%u", nImg);
        for (uint32_t i = 0; i < nImg && i < 40; i++) {
            const char *nm = _dyld_get_image_name(i);
            STEP("  [%u] %s hdr=%p slide=%ld", i, nm ? nm : "?",
                 (void *)_dyld_get_image_header(i),
                 (long)_dyld_get_image_vmaddr_slide(i));
        }
        STEP("step2 image list done");
    }
#if 0   // 纯 Lua 后端：后端在 game.love 里，面板只做文件桥。DobbyHook 会改写
        // lua_pushnumber 所在 __TEXT 页（mprotect 被拒 errno=13，Dobby 仍返回 0），
        // 之后游戏一调 pushnumber 就 SIGBUS，日志停在 step4 —— 故整段不编译。
    // 解析 Lua 符号并钩 lua_pushnumber
    g_luaL_loadbuffer = (luaL_loadbuffer_t)resolve_sym("_luaL_loadbuffer");
    g_lua_pcall = (lua_pcall_t)resolve_sym("_lua_pcall");
    g_lua_gettop = (lua_gettop_t)resolve_sym("_lua_gettop");
    g_lua_settop = (lua_settop_t)resolve_sym("_lua_settop");
    g_lua_tolstring = (lua_tolstring_t)resolve_sym("_lua_tolstring");
    g_lua_type = (lua_type_t)resolve_sym("_lua_type");
    g_lua_toboolean = (lua_toboolean_t)resolve_sym("_lua_toboolean");
    void *pushnumber = resolve_sym("_lua_pushnumber");
    STEP("step3 push=%p lb=%p pcall=%p", pushnumber, g_luaL_loadbuffer, g_lua_pcall);
    if (pushnumber && g_luaL_loadbuffer && g_lua_pcall && g_lua_gettop && g_lua_settop && g_lua_toboolean) {
        // ① 比对 prologue，确认地址正确
        static const uint8_t kPushPrologue[16] = {
            0x08,0x14,0x40,0xf9, 0x00,0x01,0x00,0xfd,
            0x08,0x14,0x40,0xf9, 0x00,0x01,0x40,0xfd };
        int prologue_match = (memcmp(pushnumber, kPushPrologue, 16) == 0);
        // ② 试写 __TEXT：mprotect 告诉我们进程到底有没有写权限
        uintptr_t pg = (uintptr_t)pushnumber & ~(uintptr_t)0x3FFF;
        errno = 0;
        int mr = mprotect((void*)pg, 0x4000, PROT_READ|PROT_WRITE|PROT_EXEC);
        int merrno = errno;
        // ③ arm64e：Dobby 内部自己处理写保护（pthread_jit_write_protect_np 在 iOS 上不可用）
        int r = DobbyHook(pushnumber, (void*)hook_pushnumber, (void**)&g_origPushNumber);
        sys_icache_invalidate(pushnumber, 32);
        g_hookReady = (r == 0);
        STEP("step4 prologue=%d mprotect=%d errno=%d hook r=%d ready=%d orig=%p",
             prologue_match, mr, merrno, r, g_hookReady, g_origPushNumber);
        NSLog(@"[SBTrainer] hook lua_pushnumber: %d (ready=%d)", r, g_hookReady);
    } else {
        if (dbg) { fprintf(dbg, "symbol resolve FAILED\n"); }
        NSLog(@"[SBTrainer] symbol resolve failed: push=%p loadbuffer=%p", pushnumber, g_luaL_loadbuffer);
    }
#endif
    g_hookReady = YES;   // 纯 Lua 后端：后端在 game.love 里，面板只做文件桥
    if (dbg) { fflush(dbg); }
    // 建面板（主队列，UIKit 已就绪）。dbg 保持打开直到这里也写完，
    // 否则崩在 setup_ui 里就什么线索都没有（文件只剩 0 字节）。
    dispatch_async(dispatch_get_main_queue(), ^{
        if (dbg) { fprintf(dbg, "step5 setup_ui begin\n"); fflush(dbg); }
        @try {
            setup_ui();
            if (dbg) { fprintf(dbg, "step6 setup_ui done\n"); fflush(dbg); }
        } @catch (NSException *e) {
            if (dbg) {
                fprintf(dbg, "EXC %s: %s\n", e.name.UTF8String, (e.reason ?: @"?").UTF8String);
                fflush(dbg);
            }
        }
        refresh_hook_status();
        if (dbg) { fprintf(dbg, "step7 all done\n"); fclose(dbg); }
    });
    return NULL;
}

__attribute__((constructor))
static void trainer_init(void) {
    // constructor 里只起延迟线程，不做任何实际工作。
    // dyld 时期 _dyld_get_image_header 拿不到符号表、Foundation/UIKit 未就绪，
    // 所有事都等 3 秒后在线程里做。
    pthread_t th;
    pthread_create(&th, NULL, delayed_init_thread, NULL);
    pthread_detach(th);
}
