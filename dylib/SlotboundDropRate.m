// SlotboundDropRate v3.2 dylib (UI-only)
// Native iOS overlay (UIWindow + UIKit) for the drop-rate controls.
// The UI is a real iOS window on top of the game (Satella-style), so it
// always shows and never depends on the game's rendering.
//
// How the drop rates actually change (see GGGLHHH/slotbound-trainer for
// the same "external overlay + Lua bridge" architecture):
//   - The game's Lua is STATICALLY linked into the love binary, so a
//     dylib cannot hook lua_pcall / luaL_dostring (fishhook + dlsym find
//     nothing). v3's in-dylib Lua injection therefore never ran.
//   - So this dylib does NOT touch Lua at all. It only writes the slider
//     values to "drop_rates_ui.lua" in the game's save dir.
//   - The game's own shim (main.lua, IPA v1.3.0) polls that file in
//     love.update (~0.5s) and applies the grade/class values live.
//     The shim IS the Lua bridge; the dylib is only the overlay.
// Build: Xcode, iOS arm64, UIKit. See .github/workflows/dylib.yml.

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

// ---- Dice icon (circular orange button, white 5-pip die), base64 PNG ----
static NSString *kIconBase64 = @"iVBORw0KGgoAAAANSUhEUgAAAIQAAACECAYAAABRRIOnAAAFRUlEQVR4nO2dy7WdMAxFRVamqSBlpo5XZipIAWREFpcA/ulzZJ89zXpB2PvKAgsQIYQQQghpZ4sOwJN93/fev922bYmxmvIkRya+ldlEmeJkPAUokV2QtMEjSfBERjlSBZxBgieyyJEiyMwiXEEXAzo4bRH+fP3s/tsfv34rRoIrBmRQGiKMTH4tGpKgiQEVzIgIHgKUGBEERQyIIET6ZECQ4IkeORCkCA+gVQRkCZ5olSNSjFAhWmTIKMKVFjGipAg56GoiXEEWw12IWhlmFOFKrRieUnzzOpAIZbhSe56um3UeB6EIZVCyhXmGoAx1oGQLU9tqgl9dhDtqsoVVpjDLEJShn5pxscoUJkJQhnGipFAXgjLoESGF6jpUCo4i9FOqK7RqCrf7EJRhDK/xUxPiLTtQBh3exlFr6VARYqYWt8xozMOwEKwbfCmN56gUpjUEZbDBclyHhGDdEIdVPdEtBGWIx0IK1+1vgk+XEMwOOGhniea7W9EyaD8w40H0uLTcxfyuEo0DGUU4OGLPkD2bMkREdsgswhMRY1WbJVSKSsrQhtV5acxDtRDet6dnleHA+/xq5284Q1hkh9llOLA4z9H5qBKCm1dzUDOPVYXG038UnR3ujh+RXUbj8BzHUnFZvOxEzA5vA3j8m4cYKHG0sO/7/iZFdw0RlR1qj2t9za8ZB1ItkWovo/UkraRAicOCVyEQlwsyztu8dmWICON7j6kdK0ocVsdMtWQQex6F4HIxN0/z25whMhVIpH2+uGSQD9II0Xutrn2NjxKHFbdCsH5Yg7t5bsoQ0fVD66/M6leJEkctLfOWZsk4qB1c60lAiUObND2VZ956FD0nACUOTVIKcYAy6ChxaJBuySC2/JchPJthEJgp3b/x5+vn7Xld+yNSLxkjZGxu8WDJJQOlyQaR5YSYublFg+WEIO8sJUSm5pYolhKClKEQ5AMKQT6gEOSDpYSYvblFg6WEIGWWEyJbc4s3ywkhMm9ziwbLbm7N2Nyiwe1j4VFb4CtPRNTYXl8NsOSSQZ5JvWSgpHuUODRIKQRKcwtKHJqkWzJQmltQ4tCmSYho21GaW1DiqKVl3m6FsP7gOMHgbp7TLBkozS0ocViRRgjiQ7MQ0XUEaaN1vh6FYB0xN0/zyyWDfNAlRMSygdLcghKH1TFfheCyMScm77qOAKW5BSUOC7qFiHphN0pzi2Yc0Z+ZOFPc3Nq2bUN7CRlKcwtKHC2UyoChD6iIYNmdEe/xKwlRtWSwuJyDmnkcLiqRPv6RDcTsWi2Ed5aYXQrv83P9kCvyh0kRQf7wbZqPwc9QaEaNz5Qfg8/aoyiSK9N11QVRWYLco5UdRDpriLeDZPwFZ0ZTBpFkexnEnm4hmCXi0c4OIoMZglLEYSGDiPGSQSlssBzXYSFKNlIKXUrjOXpHWSVDcPMLA415UFsyWE/YY1U3nHG77KQUY3iNn3qqr+mu4t3MempE0Fyy1TNETXDMFnV4yyBitGRQinEiZBAxrCEoRT9RMogY1BBXaju2WVfU/0AsL/PNrzJqg189WyDIIOKQIc4wW/wPiggHrtvfzBafoMkg4pwhDlqeBJsxW7QI770tELoHsZoYyCL8O27EQc+0PjeaUYzWJTByszBciIOeB4qR5eipgxB2jcMDODPylDmCHCPFMIIMImBCHGi8fsBDEJUnpUBEOIAK5or2eylGJNG+FEYT4QAyqCtoLywZAVWEA+jgrmQWA12EgxRB3pFBjiwSnEkX8B1IcmSU4Ezq4J/wFCS7AFemOpkSI6LMNvGEEELIIH8BbTrFaMh7bJAAAAAASUVORK5CYII=";

// ---- Config file ----
static NSString *g_saveDir = nil;   // directory holding save_fallback.dat
static NSMutableDictionary *g_grade = nil; // key -> NSNumber (0-100)
static NSMutableDictionary *g_class = nil; // key -> NSNumber (0-5)

// Locate the save dir by finding save_fallback.dat under Documents.
static NSString *find_save_dir(void) {
    if (g_saveDir) return g_saveDir;
    NSArray *docs = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docDir = docs.firstObject;
    if (!docDir) return nil;
    NSFileManager *fm = [NSFileManager defaultManager];
    // Most likely: Documents/slotbound_full/
    NSString *cand = [docDir stringByAppendingPathComponent:@"slotbound_full"];
    if ([fm fileExistsAtPath:[cand stringByAppendingPathComponent:@"save_fallback.dat"]]) {
        g_saveDir = cand;
        return g_saveDir;
    }
    // Fallback: search Documents (2 levels) for save_fallback.dat.
    NSDirectoryEnumerator *en = [fm enumeratorAtPath:docDir];
    NSString *rel = nil;
    int depth = 0;
    while ((rel = [en nextObject])) {
        if ([rel.lastPathComponent isEqualToString:@"save_fallback.dat"]) {
            g_saveDir = [[docDir stringByAppendingPathComponent:rel] stringByDeletingLastPathComponent];
            return g_saveDir;
        }
        if (++depth > 500) break;
    }
    // Last resort: assume Documents/slotbound_full even if the save isn't there yet.
    g_saveDir = cand;
    return g_saveDir;
}

static void write_config(void) {
    NSString *dir = find_save_dir();
    if (!dir) return;
    NSMutableString *s = [NSMutableString stringWithString:@"return {\n  grade = {\n"];
    NSArray *gk = @[@"normal", @"advanced", @"rare", @"legendary", @"prism"];
    for (NSString *k in gk) {
        [s appendFormat:@"    %@ = %@,\n", k, g_grade[k] ?: @0];
    }
    [s appendString:@"  },\n  class = {\n"];
    NSArray *ck = @[@"A", @"D", @"H", @"M", @"S", @"W"];
    for (NSString *k in ck) {
        [s appendFormat:@"    %@ = %@,\n", k, g_class[k] ?: @1];
    }
    [s appendString:@"  },\n}\n"];
    NSString *path = [dir stringByAppendingPathComponent:@"drop_rates_ui.lua"];
    [s writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

static void read_config(void) {
    NSString *dir = find_save_dir();
    if (!dir) return;
    NSString *path = [dir stringByAppendingPathComponent:@"drop_rates_ui.lua"];
    NSString *content = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    if (!content) return;
    // Parse the simple "key = number" lines; robust enough for our own format.
    for (NSString *line in [content componentsSeparatedByString:@"\n"]) {
        NSString *t = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        NSArray *parts = [t componentsSeparatedByString:@"="];
        if (parts.count != 2) continue;
        NSString *key = [parts[0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        NSString *val = [[parts[1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] stringByReplacingOccurrencesOfString:@"," withString:@""];
        double v = [val doubleValue];
        if ([@[@"normal", @"advanced", @"rare", @"legendary", @"prism"] containsObject:key]) {
            g_grade[key] = @(MAX(0, MIN(100, v)));
        } else if ([@[@"A", @"D", @"H", @"M", @"S", @"W"] containsObject:key]) {
            g_class[key] = @(MAX(0, MIN(5, v)));
        }
    }
}

// ---- Native UIKit overlay ----
static UIWindow *g_overlayWindow = nil;
static UIButton *g_floatButton = nil;
static UIView *g_panel = nil;
static BOOL g_panelOpen = NO;
static const CGFloat kBtnSize = 44; // small circular button
static CGPoint g_btnPos = {0, 0};
static double g_totalDrag = 0;

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
@interface PassthroughView : UIView
@end
@implementation PassthroughView
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hit = [super hitTest:point withEvent:event];
    if (hit == self) return nil;
    return hit;
}
@end

static void layout_button(void) {
    if (!g_floatButton) return;
    if (g_panelOpen) {
        g_floatButton.frame = CGRectMake(g_btnPos.x, g_btnPos.y, kBtnSize, kBtnSize);
    } else {
        g_floatButton.frame = CGRectMake(0, 0, kBtnSize, kBtnSize);
    }
}
static void sync_window_frame(void) {
    if (!g_overlayWindow || !g_floatButton) return;
    CGRect bounds = [UIScreen mainScreen].bounds;
    if (g_panelOpen) {
        g_overlayWindow.frame = bounds;
    } else {
        g_overlayWindow.frame = CGRectMake(g_btnPos.x, g_btnPos.y, kBtnSize, kBtnSize);
    }
    layout_button();
}
static void close_panel(void) {
    g_panelOpen = NO;
    if (g_panel) g_panel.hidden = YES;
    sync_window_frame();
}
static void toggle_panel(void) {
    g_panelOpen = !g_panelOpen;
    if (g_panel) g_panel.hidden = !g_panelOpen;
    sync_window_frame();
}

static void refresh_value_labels(UIView *panel) {
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
    g_grade[defs[idx][@"key"]] = @(sender.value);
    write_config();
    if (sender.superview) refresh_value_labels(sender.superview);
}
static void class_slider_changed(UISlider *sender) {
    NSArray *defs = classDefs();
    NSInteger idx = sender.tag - 100;
    if (idx < 0 || idx >= (NSInteger)defs.count) return;
    g_class[defs[idx][@"key"]] = @(sender.value);
    write_config();
    if (sender.superview) refresh_value_labels(sender.superview);
}
static void reset_tapped(void) {
    g_grade = [@{@"normal": @100, @"advanced": @0, @"rare": @0, @"legendary": @0, @"prism": @0} mutableCopy];
    g_class = [@{@"A": @1, @"D": @1, @"H": @1, @"M": @1, @"S": @1, @"W": @1} mutableCopy];
    write_config();
    if (!g_panel) return;
    for (UIView *v in g_panel.subviews) {
        if ([v isKindOfClass:[UISlider class]]) {
            UISlider *s = (UISlider *)v;
            if (s.tag < 100) s.value = (s.tag == 0) ? 100 : 0;
            else s.value = 1;
        }
    }
    refresh_value_labels(g_panel);
}

static UIView *build_panel(CGRect screenBounds) {
    CGFloat pw = MIN(660, screenBounds.size.width - 24);
    CGFloat rows = 6;
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
    closeBtn.tag = 9001;
    [panel addSubview:closeBtn];

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
        sl.value = [g_grade[gdefs[i][@"key"]] floatValue];
        sl.tag = i;
        sl.minimumTrackTintColor = [UIColor colorWithRed:1 green:0.8 blue:0.3 alpha:1];
        [panel addSubview:sl];
        UILabel *val = [[UILabel alloc] initWithFrame:CGRectMake(16 + colW - 52, y + 8, 48, 22)];
        val.font = [UIFont systemFontOfSize:14];
        val.textColor = [UIColor colorWithRed:1 green:0.8 blue:0.3 alpha:1];
        val.textAlignment = NSTextAlignmentRight;
        val.tag = 1000 + i;
        [panel addSubview:val];
    }
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
        sl.value = [g_class[cdefs[i][@"key"]] floatValue];
        sl.tag = 100 + i;
        sl.minimumTrackTintColor = [UIColor colorWithRed:0.4 green:0.8 blue:1 alpha:1];
        [panel addSubview:sl];
        UILabel *val = [[UILabel alloc] initWithFrame:CGRectMake(cx + colW - 52, y + 8, 48, 22)];
        val.font = [UIFont systemFontOfSize:14];
        val.textColor = [UIColor colorWithRed:0.4 green:0.8 blue:1 alpha:1];
        val.textAlignment = NSTextAlignmentRight;
        val.tag = 2000 + i;
        [panel addSubview:val];
    }

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

    refresh_value_labels(panel);
    return panel;
}

@interface DropRateOverlay : NSObject
+ (void)setup;
+ (void)gradeChanged:(UISlider *)sender;
+ (void)classChanged:(UISlider *)sender;
+ (void)closeTapped:(id)sender;
+ (void)resetTapped:(id)sender;
+ (void)floatTapped:(id)sender;
+ (void)panButton:(UIPanGestureRecognizer *)gr;
@end

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

@implementation DropRateOverlay
+ (void)gradeChanged:(UISlider *)sender { grade_slider_changed(sender); }
+ (void)classChanged:(UISlider *)sender { class_slider_changed(sender); }
+ (void)closeTapped:(id)sender { close_panel(); }
+ (void)resetTapped:(id)sender { reset_tapped(); }
+ (void)floatTapped:(id)sender { toggle_panel(); }

// Drag the button. Uses incremental translation (reset each step) so the
// button tracks the finger 1:1 with no jitter/feedback.
+ (void)panButton:(UIPanGestureRecognizer *)gr {
    if (!g_overlayWindow || g_panelOpen) return;
    if (gr.state == UIGestureRecognizerStateBegan) {
        g_totalDrag = 0;
    } else if (gr.state == UIGestureRecognizerStateChanged) {
        CGPoint t = [gr translationInView:g_overlayWindow];
        g_totalDrag += fabs(t.x) + fabs(t.y);
        CGRect bounds = [UIScreen mainScreen].bounds;
        CGRect f = g_overlayWindow.frame;
        CGFloat nx = f.origin.x + t.x;
        CGFloat ny = f.origin.y + t.y;
        nx = MAX(0, MIN(bounds.size.width - f.size.width, nx));
        ny = MAX(0, MIN(bounds.size.height - f.size.height, ny));
        f.origin = CGPointMake(nx, ny);
        g_overlayWindow.frame = f;
        g_btnPos = f.origin;
        [gr setTranslation:CGPointZero inView:g_overlayWindow];
    }
}

+ (void)setup {
    if (g_overlayWindow) return;
    g_grade = [@{@"normal": @100, @"advanced": @0, @"rare": @0, @"legendary": @0, @"prism": @0} mutableCopy];
    g_class = [@{@"A": @1, @"D": @1, @"H": @1, @"M": @1, @"S": @1, @"W": @1} mutableCopy];
    read_config();
    dispatch_async(dispatch_get_main_queue(), ^{
        CGRect bounds = [UIScreen mainScreen].bounds;
        g_btnPos = CGPointMake(bounds.size.width - kBtnSize - 12, 72);
        g_overlayWindow = [[UIWindow alloc] initWithFrame:CGRectMake(g_btnPos.x, g_btnPos.y, kBtnSize, kBtnSize)];
        g_overlayWindow.windowLevel = UIWindowLevelAlert + 1;
        g_overlayWindow.backgroundColor = [UIColor clearColor];
        g_overlayWindow.hidden = NO;

        UIViewController *vc = [[UIViewController alloc] init];
        PassthroughView *root = [[PassthroughView alloc] initWithFrame:g_overlayWindow.bounds];
        root.backgroundColor = [UIColor clearColor];
        root.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        vc.view = root;
        g_overlayWindow.rootViewController = vc;

        // Small circular button with the dice icon.
        g_floatButton = [UIButton buttonWithType:UIButtonTypeCustom];
        g_floatButton.frame = CGRectMake(0, 0, kBtnSize, kBtnSize);
        g_floatButton.layer.cornerRadius = kBtnSize / 2;
        g_floatButton.clipsToBounds = YES;
        NSData *iconData = [[NSData alloc] initWithBase64EncodedString:kIconBase64 options:0];
        if (iconData) {
            UIImage *icon = [UIImage imageWithData:iconData];
            if (icon) [g_floatButton setImage:icon forState:UIControlStateNormal];
        }
        // Tap opens the panel; pan drags the button. The tap only fires
        // when the pan fails, so a tap is never mistaken for a drag.
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:[DropRateOverlay class] action:@selector(floatTapped:)];
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:[DropRateOverlay class] action:@selector(panButton:)];
        [tap requireGestureRecognizerToFail:pan];
        [g_floatButton addGestureRecognizer:tap];
        [g_floatButton addGestureRecognizer:pan];
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
    [DropRateOverlay setup];
}
