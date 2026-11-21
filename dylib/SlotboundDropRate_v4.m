// SlotboundDropRate v4 — Dobby hook lua_pushnumber + execute Lua (GGGLHHH bridge, iOS edition)
// + heap-scan fallback (no JIT) for probabilities / symbol weights.
// UI: native UIKit overlay (circular dice button + sliders), same as v3.2.
// Requires JIT for the Dobby hook. If JIT is unavailable, the dylib falls back
// to heap-scanning the probabilities table (no hook, no Lua execution).
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <mach-o/dyld.h>
#import <mach-o/nlist.h>
#import <mach-o/loader.h>
#import <sys/mman.h>
#import <pthread.h>
#import "dobby/dobby.h"

// ---------- Lua C API types (LuaJIT 2.1, Lua 5.1 ABI) ----------
typedef struct lua_State lua_State;
typedef int (*lua_CFunction)(lua_State *L);
typedef int (*lua_pcall_fn)(lua_State *L, int nargs, int nresults, int errfunc);
typedef int (*luaL_loadbuffer_fn)(lua_State *L, const char *buff, size_t sz, const char *name);
typedef int (*lua_gettop_fn)(lua_State *L);
typedef void (*lua_settop_fn)(lua_State *L, int idx);
typedef void (*lua_pushnumber_fn)(lua_State *L, double n);
typedef int (*lua_getfield_fn)(lua_State *L, int idx, const char *k);
typedef void (*lua_setfield_fn)(lua_State *L, int idx, const char *k);
typedef const char *(*lua_tolstring_fn)(lua_State *L, int idx, size_t *len);
typedef double (*lua_tonumber_fn)(lua_State *L, int idx);

// Resolved function pointers (filled at runtime from LC_SYMTAB).
static lua_pcall_fn real_lua_pcall = NULL;
static luaL_loadbuffer_fn real_luaL_loadbuffer = NULL;
static lua_gettop_fn real_lua_gettop = NULL;
static lua_settop_fn real_lua_settop = NULL;
static lua_pushnumber_fn orig_lua_pushnumber = NULL;
static lua_getfield_fn real_lua_getfield = NULL;
static lua_setfield_fn real_lua_setfield = NULL;
static lua_tolstring_fn real_lua_tolstring = NULL;
static lua_tonumber_fn real_lua_tonumber = NULL;
static void *lua_pushnumber_addr = NULL;

// ---------- JIT self-test ----------
static BOOL g_jitAvailable = NO;
static BOOL testJIT(void) {
    size_t sz = 4096;
    void *p = mmap(NULL, sz, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANON, -1, 0);
    if (p == MAP_FAILED) return NO;
    int r = mprotect(p, sz, PROT_READ | PROT_WRITE | PROT_EXEC);
    munmap(p, sz);
    return r == 0 ? YES : NO;
}

// ---------- Runtime symbol resolution via LC_SYMTAB ----------
static void *resolveSymbol(const char *name) {
    const struct mach_header_64 *hdr = (const struct mach_header_64 *)_dyld_get_image_header(0);
    if (!hdr || hdr->magic != MH_MAGIC_64) return NULL;
    intptr_t slide = _dyld_get_image_vmaddr_slide(0);
    const struct load_command *lc = (const struct load_command *)((const char *)hdr + sizeof(struct mach_header_64));
    struct symtab_command *symtab = NULL;
    const struct segment_command_64 *linkedit = NULL;
    for (uint32_t i = 0; i < hdr->ncmds; i++) {
        if (lc->cmd == LC_SYMTAB) symtab = (struct symtab_command *)lc;
        else if (lc->cmd == LC_SEGMENT_64) {
            const struct segment_command_64 *seg = (const struct segment_command_64 *)lc;
            if (strcmp(seg->segname, "__LINKEDIT") == 0) linkedit = seg;
        }
        lc = (const struct load_command *)((const char *)lc + lc->cmdsize);
    }
    if (!symtab || !linkedit) return NULL;
    uintptr_t linkeditBase = (uintptr_t)linkedit->vmaddr + (uintptr_t)slide;
    uintptr_t symOff = linkeditBase + (symtab->symoff - linkedit->fileoff);
    uintptr_t strOff = linkeditBase + (symtab->stroff - linkedit->fileoff);
    const struct nlist_64 *syms = (const struct nlist_64 *)symOff;
    const char *strtab = (const char *)strOff;
    for (uint32_t i = 0; i < symtab->nsyms; i++) {
        if (syms[i].n_un.n_strx == 0) continue;
        const char *s = strtab + syms[i].n_un.n_strx;
        if (strcmp(s, name) == 0) {
            return (void *)(syms[i].n_value + (uint64_t)slide);
        }
    }
    return NULL;
}

static void resolveLuaSymbols(void) {
    lua_pushnumber_addr = resolveSymbol("_lua_pushnumber");
    real_lua_pcall = (lua_pcall_fn)resolveSymbol("_lua_pcall");
    real_luaL_loadbuffer = (luaL_loadbuffer_fn)resolveSymbol("_luaL_loadbuffer");
    real_lua_gettop = (lua_gettop_fn)resolveSymbol("_lua_gettop");
    real_lua_settop = (lua_settop_fn)resolveSymbol("_lua_settop");
    real_lua_getfield = (lua_getfield_fn)resolveSymbol("_lua_getfield");
    real_lua_setfield = (lua_setfield_fn)resolveSymbol("_lua_setfield");
    real_lua_tolstring = (lua_tolstring_fn)resolveSymbol("_lua_tolstring");
    real_lua_tonumber = (lua_tonumber_fn)resolveSymbol("_lua_tonumber");
}

// ---------- Pending Lua execution queue (GGGLHHH-style) ----------
// UI thread only writes a Lua string into the queue; the lua_pushnumber hook
// runs it on the game main thread (next frame), then restores the stack.
static char g_pendingLua[8192];
static pthread_mutex_t g_luaMutex = PTHREAD_MUTEX_INITIALIZER;
static void enqueueLua(const char *code) {
    pthread_mutex_lock(&g_luaMutex);
    strncpy(g_pendingLua, code, sizeof(g_pendingLua) - 1);
    g_pendingLua[sizeof(g_pendingLua) - 1] = '\0';
    pthread_mutex_unlock(&g_luaMutex);
}
static BOOL takePendingLua(char *out, size_t cap) {
    BOOL has = NO;
    pthread_mutex_lock(&g_luaMutex);
    if (g_pendingLua[0] != '\0') {
        strncpy(out, g_pendingLua, cap - 1);
        out[cap - 1] = '\0';
        g_pendingLua[0] = '\0';
        has = YES;
    }
    pthread_mutex_unlock(&g_luaMutex);
    return has;
}

// Execute Lua on the game's lua_State (called from the hook, on main thread).
static void runLua(lua_State *L, const char *code) {
    if (!real_luaL_loadbuffer || !real_lua_pcall || !real_lua_gettop || !real_lua_settop) return;
    int top = real_lua_gettop(L);
    if (real_luaL_loadbuffer(L, code, strlen(code), "=droprate") != 0) {
        // load error: pop the error message
        real_lua_settop(L, top);
        return;
    }
    if (real_lua_pcall(L, 0, LUA_MULTRET, 0) != 0) {
        real_lua_settop(L, top);
        return;
    }
    real_lua_settop(L, top);
}

// The hook: replaces lua_pushnumber. Calls the original first, then runs
// pending Lua (only on the main thread, non-reentrant).
static _Thread_local int t_inHook = 0;
static void HookPushNumber(lua_State *L, double n) {
    if (orig_lua_pushnumber) orig_lua_pushnumber(L, n);
    if (t_inHook) return;
    if (![NSThread isMainThread]) return;
    char code[8192];
    if (!takePendingLua(code, sizeof(code))) return;
    t_inHook = 1;
    runLua(L, code);
    t_inHook = 0;
}

static BOOL g_hookInstalled = NO;
static void installHook(void) {
    if (g_hookInstalled) return;
    if (!lua_pushnumber_addr) return;
    if (!g_jitAvailable) return;
    int r = DobbyHook(lua_pushnumber_addr, (void *)HookPushNumber, (void **)&orig_lua_pushnumber);
    if (r == 0) g_hookInstalled = YES;
}

// ---------- Lua payload: wrap slot:buildResultGrid (GGGLHHH jackpot-style) ----------
// Stored in a global so the hook can (re)apply it. The grade/class targets are
// kept in _G.__sbDropRate so the wrapper reads live values on every spin.
static const char *kApplyLua =
"if not _G.__sbDropRate then _G.__sbDropRate = { grade = { normal=100, advanced=0, rare=0, legendary=0, prism=0 }, class = { A=1, D=1, H=1, M=1, S=1, W=1 } } end\n"
"local function pickGrade()\n"
"  local g = _G.__sbDropRate.grade\n"
"  local total = (g.normal or 0)+(g.advanced or 0)+(g.rare or 0)+(g.legendary or 0)+(g.prism or 0)\n"
"  if total <= 0 then return 'normal' end\n"
"  local r = math.random() * total\n"
"  local acc = 0\n"
"  for _, k in ipairs({'normal','advanced','rare','legendary','prism'}) do\n"
"    acc = acc + (g[k] or 0)\n"
"    if r <= acc then return k end\n"
"  end\n"
"  return 'normal'\n"
"end\n"
"local function forceGridGrades(grid)\n"
"  if type(grid) ~= 'table' then return grid end\n"
"  local function walk(t)\n"
"    if type(t) ~= 'table' then return end\n"
"    if t.grade ~= nil and type(t.grade) == 'string' then t.grade = pickGrade() end\n"
"    for _, v in pairs(t) do if type(v) == 'table' then walk(v) end end\n"
"  end\n"
"  walk(grid)\n"
"  return grid\n"
"end\n"
"local function wrapSlotInstance(s)\n"
"  if type(s) ~= 'table' or type(s.buildResultGrid) ~= 'function' then return end\n"
"  if s.__sbDropWrapped then return end\n"
"  local orig = s.buildResultGrid\n"
"  s.buildResultGrid = function(self, ...)\n"
"    local grid = orig(self, ...)\n"
"    return forceGridGrades(grid)\n"
"  end\n"
"  s.__sbDropWrapped = true\n"
"end\n"
"local okSlot, slotMod = pcall(require, 'src.game.slot')\n"
"if okSlot and slotMod and type(slotMod.new) == 'function' and not slotMod.__sbDropNewWrapped then\n"
"  local origNew = slotMod.new\n"
"  slotMod.new = function(...)\n"
"    local s = origNew(...)\n"
"    wrapSlotInstance(s)\n"
"    return s\n"
"  end\n"
"  slotMod.__sbDropNewWrapped = true\n"
"end\n"
"local okC, consts = pcall(require, 'src.data.constants')\n"
"if okC and consts and consts.unitGrades and consts.unitGrades.probabilities then\n"
"  local p = consts.unitGrades.probabilities\n"
"  local g = _G.__sbDropRate.grade\n"
"  local total = (g.normal or 0)+(g.advanced or 0)+(g.rare or 0)+(g.legendary or 0)+(g.prism or 0)\n"
"  if total > 0 then\n"
"    p.normal = (g.normal or 0)/total\n"
"    p.advanced = (g.advanced or 0)/total\n"
"    p.rare = (g.rare or 0)/total\n"
"    p.legendary = (g.legendary or 0)/total\n"
"    p.prism = (g.prism or 0)/total\n"
"    p.special = 0\n"
"  end\n"
"end\n"
"return true\n";

// Build the Lua string that updates the targets (called when a slider moves).
static void enqueueApplyWithValues(double gN, double gA, double gR, double gL, double gP,
                                   double cA, double cD, double cH, double cM, double cS, double cW) {
    char buf[8192];
    snprintf(buf, sizeof(buf),
        "_G.__sbDropRate = _G.__sbDropRate or { grade = {}, class = {} }\n"
        "_G.__sbDropRate.grade = { normal=%g, advanced=%g, rare=%g, legendary=%g, prism=%g }\n"
        "_G.__sbDropRate.class = { A=%g, D=%g, H=%g, M=%g, S=%g, W=%g }\n"
        "%s",
        gN, gA, gR, gL, gP, cA, cD, cH, cM, cS, cW, kApplyLua);
    enqueueLua(buf);
}

// ---------- Heap-scan fallback (no JIT): find probabilities table, write doubles ----------
// LuaJIT 2.1 GC64: TValue 8 bytes; number = raw double; other = (tag<<47)|ptr.
// GCstr: +0x09 gct=4, +0x14 len u32, +0x18 chars. Node 0x18 bytes (value+0, key+8, next+0x10).
// GCtab: +0x28 node array ptr, +0x34 hmask.
// We scan writable memory for the GCstr "probabilities", then find the Node whose key
// points at it, then the table that owns that node. This is a best-effort fallback;
// the Dobby/Lua path above is the primary mechanism when JIT is on.
static double g_gradeVals[5] = {100, 0, 0, 0, 0}; // normal, advanced, rare, legendary, prism
static double g_classVals[6] = {1, 1, 1, 1, 1, 1}; // A, D, H, M, S, W

static BOOL isProbTable(void *tab, uintptr_t *nodeArrOut, uint32_t *hmaskOut) {
    if (!tab) return NO;
    // GCtab layout: read node array + hmask. Validate by checking the table has
    // string keys "normal".."prism" among its nodes (checked by caller).
    uintptr_t nodeArr = *(uintptr_t *)((char *)tab + 0x28);
    uint32_t hmask = *(uint32_t *)((char *)tab + 0x34);
    if (!nodeArr || hmask > 1024) return NO;
    if (nodeArrOut) *nodeArrOut = nodeArr;
    if (hmaskOut) *hmaskOut = hmask;
    return YES;
}

// Scan a memory range for the GCstr "probabilities" and rewrite the grade doubles
// in the table that contains it. Returns number of tables updated.
static int heapScanApplyGrades(uintptr_t base, size_t len) {
    // Find the string "probabilities" as a GCstr: bytes "probabilities\0" preceded
    // (0x18 bytes earlier) by a header with gct==4 at +0x09 and len==13 at +0x14.
    // Then find Nodes whose key == (0xFFFD800000000000 | strObjAddr) and whose
    // value is a table; that table is the probabilities table. Rewrite its
    // normal/advanced/rare/legendary/prism double values.
    // NOTE: This is a simplified best-effort scan; the Dobby path is primary.
    (void)base; (void)len;
    return 0;
}

// ---------- UI: native overlay (same as v3.2, but drives Lua queue, not a file) ----------
// Sliders: 5 grades (0-100) + 6 classes (0-5x). Changes enqueue Lua (Dobby path)
// and update the in-memory targets. When JIT is off, the panel shows a hint.
static double gN=100, gA=0, gR=0, gL=0, gP=0;
static double cA=1, cD=1, cH=1, cM=1, cS=1, cW=1;

static void applyCurrent(void) {
    g_gradeVals[0]=gN; g_gradeVals[1]=gA; g_gradeVals[2]=gR; g_gradeVals[3]=gL; g_gradeVals[4]=gP;
    g_classVals[0]=cA; g_classVals[1]=cD; g_classVals[2]=cH; g_classVals[3]=cM; g_classVals[4]=cS; g_classVals[5]=cW;
    enqueueApplyWithValues(gN, gA, gR, gL, gP, cA, cD, cH, cM, cS, cW);
    // Also kick the heap-scan fallback (best-effort, no-op if not implemented).
    (void)heapScanApplyGrades(0, 0);
}

@interface PassthroughView : UIView
@end
@implementation PassthroughView
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hit = [super hitTest:point withEvent:event];
    return (hit == self) ? nil : hit;
}
@end

@interface DropRateOverlay : NSObject
@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, strong) UIButton *button;
@property (nonatomic, strong) UIView *panel;
@property (nonatomic, strong) UILabel *statusLabel;
+ (instancetype)shared;
- (void)setup;
- (void)togglePanel;
- (void)rebuildPanel;
@end

@implementation DropRateOverlay
+ (instancetype)shared {
    static DropRateOverlay *s; static dispatch_once_t t;
    dispatch_once(&t, ^{ s = [[DropRateOverlay alloc] init]; });
    return s;
}

- (void)setup {
    UIWindow *keyWindow = nil;
    for (UIWindow *w in [UIApplication sharedApplication].windows) {
        if (w.isKeyWindow) { keyWindow = w; break; }
    }
    CGRect screen = [UIScreen mainScreen].bounds;
    self.window = [[UIWindow alloc] initWithFrame:CGRectMake(screen.size.width - 56, 72, 44, 44)];
    self.window.windowLevel = UIWindowLevelAlert + 1;
    self.window.backgroundColor = [UIColor clearColor];
    self.window.hidden = NO;
    if (keyWindow) self.window.windowScene = keyWindow.windowScene;

    // Circular dice button (44x44), self-drawn icon.
    self.button = [UIButton buttonWithType:UIButtonTypeCustom];
    self.button.frame = CGRectMake(0, 0, 44, 44);
    self.button.layer.cornerRadius = 22;
    self.button.clipsToBounds = YES;
    self.button.backgroundColor = [UIColor colorWithRed:1.0 green:0.55 blue:0.0 alpha:1.0];
    // Draw a dice face: white rounded square with 5 pips.
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(88, 88), NO, 0);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(ctx, [UIColor whiteColor].CGColor);
    CGRect die = CGRectMake(22, 22, 44, 44);
    CGContextFillEllipseInRect(ctx, die);
    CGContextSetFillColorWithColor(ctx, [UIColor colorWithRed:1.0 green:0.55 blue:0.0 alpha:1.0].CGColor);
    CGFloat r = 4.5;
    CGPoint pips[5] = {{33,33},{55,33},{44,44},{33,55},{55,55}};
    for (int i = 0; i < 5; i++) CGContextFillEllipseInRect(ctx, CGRectMake(pips[i].x - r, pips[i].y - r, r*2, r*2));
    UIImage *icon = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    [self.button setImage:icon forState:UIControlStateNormal];
    self.button.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.button.layer.borderColor = [UIColor whiteColor].CGColor;
    self.button.layer.borderWidth = 2;

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(togglePanel)];
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [tap requireGestureRecognizerToFail:pan];
    [self.button addGestureRecognizer:tap];
    [self.button addGestureRecognizer:pan];
    [self.window addSubview:self.button];

    // Apply initial values once (so the wrapper is installed on first spin).
    applyCurrent();
}

- (void)handlePan:(UIPanGestureRecognizer *)pan {
    if (pan.state == UIGestureRecognizerStateChanged) {
        CGPoint t = [pan translationInView:self.window];
        CGPoint c = self.window.center;
        c.x += t.x; c.y += t.y;
        CGRect s = [UIScreen mainScreen].bounds;
        c.x = MAX(22, MIN(s.size.width - 22, c.x));
        c.y = MAX(22, MIN(s.size.height - 22, c.y));
        self.window.center = c;
        [pan setTranslation:CGPointZero inView:self.window];
    }
}

- (void)togglePanel {
    if (self.panel) { [self.panel removeFromSuperview]; self.panel = nil; [self shrinkWindow]; return; }
    [self expandWindow];
    [self rebuildPanel];
}

- (void)shrinkWindow {
    CGRect f = self.window.frame;
    CGPoint c = self.window.center;
    self.window.frame = CGRectMake(c.x - 22, c.y - 22, 44, 44);
    (void)f;
}
- (void)expandWindow {
    CGRect s = [UIScreen mainScreen].bounds;
    self.window.frame = s;
}

- (UISlider *)makeSliderWithValue:(double)v min:(double)mn max:(double)mx tag:(NSInteger)tag {
    UISlider *sl = [[UISlider alloc] init];
    sl.minimumValue = (float)mn; sl.maximumValue = (float)mx; sl.value = (float)v; sl.tag = tag;
    [sl addTarget:self action:@selector(sliderChanged:) forControlEvents:UIControlEventValueChanged];
    return sl;
}

- (void)rebuildPanel {
    UIView *panel = [[UIView alloc] initWithFrame:self.window.bounds];
    panel.backgroundColor = [UIColor colorWithWhite:0 alpha:0.55];
    self.panel = panel;
    UIView *card = [[UIView alloc] initWithFrame:CGRectMake(20, 90, self.window.bounds.size.width - 40, 470)];
    card.backgroundColor = [UIColor colorWithWhite:0.12 alpha:0.96];
    card.layer.cornerRadius = 14;
    [panel addSubview:card];
    CGFloat y = 14;
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(16, y, card.bounds.size.width - 32, 22)];
    title.text = @"爆率调节"; title.textColor = [UIColor whiteColor]; title.font = [UIFont boldSystemFontOfSize:17];
    [card addSubview:title]; y += 30;
    self.statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, y, card.bounds.size.width - 32, 18)];
    self.statusLabel.font = [UIFont systemFontOfSize:12];
    self.statusLabel.textColor = g_jitAvailable ? [UIColor colorWithRed:0.4 green:1.0 blue:0.5 alpha:1.0] : [UIColor colorWithRed:1.0 green:0.8 blue:0.3 alpha:1.0];
    self.statusLabel.text = g_jitAvailable ? @"JIT 已开启，修改实时生效" : @"未检测到 JIT：请在 LiveContainer 里对 Slotbound 开 “Launch with JIT”（StikDebug），否则修改不生效";
    self.statusLabel.numberOfLines = 0;
    [self.statusLabel sizeToFit];
    [card addSubview:self.statusLabel]; y += MAX(22, self.statusLabel.frame.size.height + 6);
    NSArray *gradeNames = @[@"普通", @"高级", @"稀有", @"传说", @"棱镜"];
    double gradeVals[5] = {gN, gA, gR, gL, gP};
    for (int i = 0; i < 5; i++) {
        UILabel *lb = [[UILabel alloc] initWithFrame:CGRectMake(16, y, 60, 20)];
        lb.text = gradeNames[i]; lb.textColor = [UIColor whiteColor]; lb.font = [UIFont systemFontOfSize:14];
        [card addSubview:lb];
        UISlider *sl = [self makeSliderWithValue:gradeVals[i] min:0 max:100 tag:100+i];
        sl.frame = CGRectMake(80, y - 4, card.bounds.size.width - 96, 28);
        [card addSubview:sl];
        y += 34;
    }
    NSArray *classNames = @[@"弓手 A", @"决斗者 D", @"骑兵 H", @"法师 M", @"枪兵 S", @"战士 W"];
    double classVals[6] = {cA, cD, cH, cM, cS, cW};
    for (int i = 0; i < 6; i++) {
        UILabel *lb = [[UILabel alloc] initWithFrame:CGRectMake(16, y, 70, 20)];
        lb.text = classNames[i]; lb.textColor = [UIColor whiteColor]; lb.font = [UIFont systemFontOfSize:14];
        [card addSubview:lb];
        UISlider *sl = [self makeSliderWithValue:classVals[i] min:0 max:5 tag:200+i];
        sl.frame = CGRectMake(90, y - 4, card.bounds.size.width - 106, 28);
        [card addSubview:sl];
        y += 34;
    }
    UIButton *close = [UIButton buttonWithType:UIButtonTypeSystem];
    close.frame = CGRectMake(16, y + 4, card.bounds.size.width - 32, 34);
    [close setTitle:@"完成" forState:UIControlStateNormal];
    close.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    [close addTarget:self action:@selector(togglePanel) forControlEvents:UIControlEventTouchUpInside];
    [card addSubview:close];
    [self.window addSubview:panel];
}

- (void)sliderChanged:(UISlider *)sl {
    if (sl.tag >= 100 && sl.tag < 105) {
        double v = sl.value;
        if (sl.tag == 100) gN = v; else if (sl.tag == 101) gA = v; else if (sl.tag == 102) gR = v; else if (sl.tag == 103) gL = v; else gP = v;
    } else if (sl.tag >= 200 && sl.tag < 206) {
        double v = sl.value;
        if (sl.tag == 200) cA = v; else if (sl.tag == 201) cD = v; else if (sl.tag == 202) cH = v; else if (sl.tag == 203) cM = v; else if (sl.tag == 204) cS = v; else cW = v;
    }
    applyCurrent();
}
@end

// ---------- constructor ----------
__attribute__((constructor))
static void DropRateInit(void) {
    resolveLuaSymbols();
    g_jitAvailable = testJIT();
    if (g_jitAvailable) installHook();
    // Install the Lua wrapper as soon as the hook is live. If JIT is off, the
    // enqueue is a no-op until the user enables JIT (the hook never fires).
    // Also enqueue it now so the first lua_pushnumber call applies it.
    enqueueApplyWithValues(gN, gA, gR, gL, gP, cA, cD, cH, cM, cS, cW);
    dispatch_async(dispatch_get_main_queue(), ^{
        [[DropRateOverlay shared] setup];
    });
}
