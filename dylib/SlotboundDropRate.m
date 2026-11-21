// SlotboundDropRate v3 dylib
// Native iOS overlay (UIWindow + UIKit) for the drop-rate controls.
// The UI is a real iOS window on top of the game (like the Satella
// reference the user provided), so it does NOT depend on LÖVE's draw
// pipeline or the game's coordinate transform -- it always shows.
// The game logic (grade probabilities + class weights) is still done
// by injected Lua, reached through the captured lua_State.
// Build: Xcode, iOS arm64, UIKit. See .github/workflows/dylib.yml.

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#include <stdio.h>
#include <string.h>
#include <stdbool.h>
#include <dlfcn.h>
#include "fishhook.h"

typedef struct lua_State lua_State;
typedef int (*lua_pcall_fn)(lua_State *L, int nargs, int nresults, int errfunc);
typedef int (*luaL_loadstring_fn)(lua_State *L, const char *s);
typedef int (*luaL_dostring_fn)(lua_State *L, const char *str);

static lua_pcall_fn orig_lua_pcall = NULL;
static luaL_loadstring_fn real_luaL_loadstring = NULL;
static luaL_dostring_fn real_luaL_dostring = NULL;
static lua_State *g_L = NULL;
static bool injected = false;
static bool injecting = false;

// ---- Injected Lua (game logic only; no LÖVE UI drawing) ----
static const char kInjectLua[] =
#include "grade_logic_embed.h"
;

// Run a Lua snippet on the captured state. Returns true on success.
static bool run_lua(const char *code) {
    if (!g_L || !code) return false;
    if (!real_luaL_dostring) {
        real_luaL_dostring = (luaL_dostring_fn)dlsym(RTLD_DEFAULT, "luaL_dostring");
    }
    if (!real_luaL_loadstring) {
        real_luaL_loadstring = (luaL_loadstring_fn)dlsym(RTLD_DEFAULT, "luaL_loadstring");
    }
    if (real_luaL_dostring) {
        return real_luaL_dostring(g_L, code) == 0;
    }
    if (real_luaL_loadstring && orig_lua_pcall) {
        if (real_luaL_loadstring(g_L, code) == 0) {
            return orig_lua_pcall(g_L, 0, 0, 0) == 0;
        }
    }
    return false;
}

static void run_injection(lua_State *L) {
    if (!L) return;
    g_L = L;
    if (!real_luaL_dostring) {
        real_luaL_dostring = (luaL_dostring_fn)dlsym(RTLD_DEFAULT, "luaL_dostring");
    }
    if (!real_luaL_loadstring) {
        real_luaL_loadstring = (luaL_loadstring_fn)dlsym(RTLD_DEFAULT, "luaL_loadstring");
    }
    if (real_luaL_dostring) {
        real_luaL_dostring(L, kInjectLua);
    } else if (real_luaL_loadstring && orig_lua_pcall) {
        if (real_luaL_loadstring(L, kInjectLua) == 0) {
            orig_lua_pcall(L, 0, 0, 0);
        }
    }
}

static int hooked_lua_pcall(lua_State *L, int nargs, int nresults, int errfunc) {
    if (!injected && !injecting && L != NULL) {
        injecting = true;
        run_injection(L);
        injected = true;
        injecting = false;
    }
    return orig_lua_pcall(L, nargs, nresults, errfunc);
}

// ---- Native UIKit overlay ----
static UIWindow *g_overlayWindow = nil;
static UIButton *g_floatButton = nil;
static UIView *g_panel = nil;
static BOOL g_panelOpen = NO;

// Grade and class definitions (must match grade_logic.lua).
static NSArray<NSDictionary *> *gradeDefs(void) {
    return @[
        @{@"key": @"normal",    @"label": @"普通"},
        @{@"key": @"advanced",  @"label": @"高级"},
        @{@"key": @"rare",      @"label": @"稀有"},
        @{@"key": @"legendary", @"label": @"传说"},
        @{@"key": @"prism",     @"label": @"棱镜"},
    ];
}
static NSArray<NSDictionary *> *classDefs(void) {
    return @[
        @{@"key": @"A", @"label": @"弓手"},
        @{@"key": @"D", @"label": @"决斗者"},
        @{@"key": @"H", @"label": @"骑兵"},
        @{@"key": @"M", @"label": @"法师"},
        @{@"key": @"S", @"label": @"枪兵"},
        @{@"key": @"W", @"label": @"战士"},
    ];
}

// A view that only intercepts touches on its subviews (button/panel).
// Touches elsewhere pass through to the game window below.
@interface PassthroughView : UIView
@end
@implementation PassthroughView
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hit = [super hitTest:point withEvent:event];
    if (hit == self) return nil;
    return hit;
}
@end

static void apply_grade_to_lua(NSString *key, double pct) {
    char buf[256];
    snprintf(buf, sizeof(buf), "SetDropGrade('%s', %g)", [key UTF8String], pct);
    run_lua(buf);
}
static void apply_class_to_lua(NSString *key, double mult) {
    char buf[256];
    snprintf(buf, sizeof(buf), "SetDropClass('%s', %g)", [key UTF8String], mult);
    run_lua(buf);
}

// Update a row's value label after a slider moves.
static void refresh_value_labels(UIView *panel) {
    // Grade value labels show the normalized percent; class labels show x.
    // We recompute the grade percent from the sliders.
    double total = 0;
    NSMutableArray<UISlider *> *gs = [NSMutableArray array];
    NSMutableArray<UISlider *> *cs = [NSMutableArray array];
    for (UIView *v in panel.subviews) {
        if ([v isKindOfClass:[UISlider class]]) {
            UISlider *s = (UISlider *)v;
            if (s.tag < 100) [gs addObject:s];
            else [cs addObject:s];
        }
    }
    for (UISlider *s in gs) total += s.value;
    for (UIView *v in panel.subviews) {
        if ([v isKindOfClass:[UILabel class]]) {
            UILabel *lab = (UILabel *)v;
            NSInteger tag = lab.tag;
            if (tag >= 1000 && tag < 2000) {
                NSInteger idx = tag - 1000;
                if (idx < (NSInteger)gs.count) {
                    double pct = total > 0 ? (gs[idx].value / total * 100.0) : 0;
                    lab.text = [NSString stringWithFormat:@"%.0f%%", pct];
                }
            } else if (tag >= 2000) {
                NSInteger idx = tag - 2000;
                if (idx < (NSInteger)cs.count) {
                    lab.text = [NSString stringWithFormat:@"%.1fx", cs[idx].value];
                }
            }
        }
    }
}

static void grade_slider_changed(UISlider *sender) {
    NSArray *defs = gradeDefs();
    NSInteger idx = sender.tag;
    if (idx < 0 || idx >= (NSInteger)defs.count) return;
    NSString *key = defs[idx][@"key"];
    apply_grade_to_lua(key, sender.value);
    if (sender.superview) refresh_value_labels(sender.superview);
}

static void class_slider_changed(UISlider *sender) {
    NSArray *defs = classDefs();
    NSInteger idx = sender.tag - 100;
    if (idx < 0 || idx >= (NSInteger)defs.count) return;
    NSString *key = defs[idx][@"key"];
    apply_class_to_lua(key, sender.value);
    if (sender.superview) refresh_value_labels(sender.superview);
}

static void close_panel(void) {
    g_panelOpen = NO;
    if (g_panel) g_panel.hidden = YES;
}

static void toggle_panel(void) {
    g_panelOpen = !g_panelOpen;
    if (g_panel) g_panel.hidden = !g_panelOpen;
}

static void reset_tapped(void) {
    run_lua("ResetDropRates()");
    // Reset sliders to defaults and refresh labels.
    if (!g_panel) return;
    for (UIView *v in g_panel.subviews) {
        if ([v isKindOfClass:[UISlider class]]) {
            UISlider *s = (UISlider *)v;
            if (s.tag < 100) {
                s.value = (s.tag == 0) ? 100 : 0;
            } else {
                s.value = 1;
            }
        }
    }
    refresh_value_labels(g_panel);
}

static UIView *build_panel(CGRect screenBounds) {
    CGFloat pw = MIN(660, screenBounds.size.width - 24);
    CGFloat rows = 6; // max(grades 5, classes 6)
    CGFloat ph = 44 + rows * 44 + 56;
    if (ph > screenBounds.size.height - 16) ph = screenBounds.size.height - 16;
    CGFloat px = (screenBounds.size.width - pw) / 2;
    CGFloat py = (screenBounds.size.height - ph) / 2;
    UIView *panel = [[UIView alloc] initWithFrame:CGRectMake(px, py, pw, ph)];
    panel.backgroundColor = [UIColor colorWithRed:0.08 green:0.08 blue:0.11 alpha:0.97];
    panel.layer.cornerRadius = 16;
    panel.layer.borderColor = [UIColor colorWithRed:1 green:0.8 blue:0.3 alpha:1].CGColor;
    panel.layer.borderWidth = 2;

    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(16, 8, pw - 90, 28)];
    title.text = @"爆率设置";
    title.font = [UIFont boldSystemFontOfSize:20];
    title.textColor = [UIColor colorWithRed:1 green:0.8 blue:0.3 alpha:1];
    [panel addSubview:title];

    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    closeBtn.frame = CGRectMake(pw - 58, 6, 44, 32);
    [closeBtn setTitle:@"✕" forState:UIControlStateNormal];
    closeBtn.titleLabel.font = [UIFont boldSystemFontOfSize:22];
    [closeBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [closeBtn addTarget:[NSNull null] action:NULL forControlEvents:UIControlEventTouchUpInside];
    // Use a block-free target via the panel itself: store the button and
    // wire it through the shared handler below (see setup_overlay).
    closeBtn.tag = 9001;
    [panel addSubview:closeBtn];

    // Column headers
    CGFloat colW = (pw - 32 - 16) / 2;
    UILabel *h1 = [[UILabel alloc] initWithFrame:CGRectMake(16, 40, colW, 20)];
    h1.text = @"等级爆率";
    h1.font = [UIFont boldSystemFontOfSize:15];
    h1.textColor = [UIColor whiteColor];
    [panel addSubview:h1];
    UILabel *h2 = [[UILabel alloc] initWithFrame:CGRectMake(16 + colW + 16, 40, colW, 20)];
    h2.text = @"职业倍数";
    h2.font = [UIFont boldSystemFontOfSize:15];
    h2.textColor = [UIColor whiteColor];
    [panel addSubview:h2];

    // Grade rows (left column)
    NSArray *gdefs = gradeDefs();
    for (NSInteger i = 0; i < (NSInteger)gdefs.count; i++) {
        CGFloat y = 64 + i * 44;
        UILabel *lab = [[UILabel alloc] initWithFrame:CGRectMake(16, y + 8, 62, 22)];
        lab.text = gdefs[i][@"label"];
        lab.font = [UIFont systemFontOfSize:16];
        lab.textColor = [UIColor whiteColor];
        [panel addSubview:lab];
        UISlider *sl = [[UISlider alloc] initWithFrame:CGRectMake(82, y + 6, colW - 62 - 56, 28)];
        sl.minimumValue = 0;
        sl.maximumValue = 100;
        sl.value = (i == 0) ? 100 : 0;
        sl.tag = i;
        sl.minimumTrackTintColor = [UIColor colorWithRed:1 green:0.8 blue:0.3 alpha:1];
        [sl addTarget:[NSNull null] action:NULL forControlEvents:UIControlEventValueChanged];
        // Wire via the overlay controller (see setup_overlay) using tags.
        sl.accessibilityIdentifier = @"grade";
        [panel addSubview:sl];
        UILabel *val = [[UILabel alloc] initWithFrame:CGRectMake(16 + colW - 52, y + 8, 48, 22)];
        val.text = (i == 0) ? @"100%" : @"0%";
        val.font = [UIFont systemFontOfSize:14];
        val.textColor = [UIColor colorWithRed:1 green:0.8 blue:0.3 alpha:1];
        val.textAlignment = NSTextAlignmentRight;
        val.tag = 1000 + i;
        [panel addSubview:val];
    }
    // Class rows (right column)
    NSArray *cdefs = classDefs();
    for (NSInteger i = 0; i < (NSInteger)cdefs.count; i++) {
        CGFloat y = 64 + i * 44;
        CGFloat cx = 16 + colW + 16;
        UILabel *lab = [[UILabel alloc] initWithFrame:CGRectMake(cx, y + 8, 62, 22)];
        lab.text = cdefs[i][@"label"];
        lab.font = [UIFont systemFontOfSize:16];
        lab.textColor = [UIColor whiteColor];
        [panel addSubview:lab];
        UISlider *sl = [[UISlider alloc] initWithFrame:CGRectMake(cx + 66, y + 6, colW - 62 - 56, 28)];
        sl.minimumValue = 0;
        sl.maximumValue = 5;
        sl.value = 1;
        sl.tag = 100 + i;
        sl.minimumTrackTintColor = [UIColor colorWithRed:0.4 green:0.8 blue:1 alpha:1];
        sl.accessibilityIdentifier = @"class";
        [panel addSubview:sl];
        UILabel *val = [[UILabel alloc] initWithFrame:CGRectMake(cx + colW - 52, y + 8, 48, 22)];
        val.text = @"1.0x";
        val.font = [UIFont systemFontOfSize:14];
        val.textColor = [UIColor colorWithRed:0.4 green:0.8 blue:1 alpha:1];
        val.textAlignment = NSTextAlignmentRight;
        val.tag = 2000 + i;
        [panel addSubview:val];
    }

    // Reset button
    UIButton *resetBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    resetBtn.frame = CGRectMake(16, ph - 48, 120, 36);
    [resetBtn setTitle:@"重置" forState:UIControlStateNormal];
    resetBtn.titleLabel.font = [UIFont boldSystemFontOfSize:17];
    [resetBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    resetBtn.backgroundColor = [UIColor colorWithRed:0.3 green:0.3 blue:0.35 alpha:1];
    resetBtn.layer.cornerRadius = 8;
    resetBtn.tag = 9002;
    [panel addSubview:resetBtn];

    UILabel *hint = [[UILabel alloc] initWithFrame:CGRectMake(148, ph - 48, pw - 164, 36)];
    hint.text = @"改完即时生效，下一次抽卡按新概率";
    hint.font = [UIFont systemFontOfSize:13];
    hint.textColor = [UIColor colorWithWhite:0.7 alpha:1];
    [panel addSubview:hint];

    return panel;
}

// Forward declaration: wire_panel references DropRateOverlay (defined below).
@class DropRateOverlay;

// Wire targets after the panel is built (keeps the builder simple).
static void wire_panel(UIView *panel) {
    for (UIView *v in panel.subviews) {
        if ([v isKindOfClass:[UISlider class]]) {
            UISlider *sl = (UISlider *)v;
            if (sl.tag < 100) {
                [sl addTarget:[DropRateOverlay class] action:@selector(gradeChanged:) forControlEvents:UIControlEventValueChanged];
            } else {
                [sl addTarget:[DropRateOverlay class] action:@selector(classChanged:) forControlEvents:UIControlEventValueChanged];
            }
        } else if ([v isKindOfClass:[UIButton class]]) {
            UIButton *b = (UIButton *)v;
            if (b.tag == 9001) {
                [b addTarget:[DropRateOverlay class] action:@selector(closeTapped:) forControlEvents:UIControlEventTouchUpInside];
            } else if (b.tag == 9002) {
                [b addTarget:[DropRateOverlay class] action:@selector(resetTapped:) forControlEvents:UIControlEventTouchUpInside];
            }
        }
    }
}

@interface DropRateOverlay : NSObject
+ (void)setup;
+ (void)gradeChanged:(UISlider *)sender;
+ (void)classChanged:(UISlider *)sender;
+ (void)closeTapped:(id)sender;
+ (void)resetTapped:(id)sender;
+ (void)floatTapped:(id)sender;
@end

@implementation DropRateOverlay
+ (void)gradeChanged:(UISlider *)sender { grade_slider_changed(sender); }
+ (void)classChanged:(UISlider *)sender { class_slider_changed(sender); }
+ (void)closeTapped:(id)sender { close_panel(); }
+ (void)resetTapped:(id)sender { reset_tapped(); }
+ (void)floatTapped:(id)sender { toggle_panel(); }

+ (void)setup {
    if (g_overlayWindow) return;
    dispatch_async(dispatch_get_main_queue(), ^{
        CGRect bounds = [UIScreen mainScreen].bounds;
        g_overlayWindow = [[UIWindow alloc] initWithFrame:bounds];
        g_overlayWindow.windowLevel = UIWindowLevelAlert + 1;
        g_overlayWindow.backgroundColor = [UIColor clearColor];
        g_overlayWindow.hidden = NO;

        UIViewController *vc = [[UIViewController alloc] init];
        PassthroughView *root = [[PassthroughView alloc] initWithFrame:bounds];
        root.backgroundColor = [UIColor clearColor];
        vc.view = root;
        g_overlayWindow.rootViewController = vc;

        // Big floating button: top-right, below the game's L/R toggle.
        CGFloat bs = 100;
        CGFloat bx = bounds.size.width - bs - 12;
        CGFloat by = 72;
        g_floatButton = [UIButton buttonWithType:UIButtonTypeCustom];
        g_floatButton.frame = CGRectMake(bx, by, bs, bs);
        g_floatButton.backgroundColor = [UIColor colorWithRed:0.95 green:0.55 blue:0.10 alpha:0.95];
        g_floatButton.layer.cornerRadius = 20;
        g_floatButton.layer.borderColor = [UIColor whiteColor].CGColor;
        g_floatButton.layer.borderWidth = 4;
        [g_floatButton setTitle:@"爆率" forState:UIControlStateNormal];
        g_floatButton.titleLabel.font = [UIFont boldSystemFontOfSize:28];
        [g_floatButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [g_floatButton addTarget:[DropRateOverlay class] action:@selector(floatTapped:) forControlEvents:UIControlEventTouchUpInside];
        [root addSubview:g_floatButton];

        g_panel = build_panel(bounds);
        g_panel.hidden = YES;
        wire_panel(g_panel);
        [root addSubview:g_panel];
    });
}
@end

__attribute__((constructor))
static void slotbound_droprate_init(void) {
    struct rebinding rb;
    rb.name = "lua_pcall";
    rb.replacement = (void *)hooked_lua_pcall;
    rb.replaced = (void **)&orig_lua_pcall;
    rebind_symbols(&rb, 1);
    [DropRateOverlay setup];
}
