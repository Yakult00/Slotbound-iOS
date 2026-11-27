#!/usr/bin/env python3
"""把原生存档面板（UIDocumentPicker）注入 LÖVE 的 src/common/ios.mm。

思路：love.system.openURL 在 iOS 上最终调到 love::ios::openURL，
URL 不出应用、不用注册 scheme。因此在这里拦 slotbound://export 与
slotbound://import，直接用 UIKit 弹系统文件面板，不需要 dylib 注入。

用法： python3 tools/native_save_dialog.py <love-11.5-ios-source 目录>
"""

import io
import os
import sys

OBJC_BLOCK = r"""
// ===== SlotBound: 原生存档面板（不依赖注入插件） =====
// 说明：只在本文件内实现，不改 Info.plist、不注册 URL scheme；
// 由 love::ios::openURL 就地拦截 slotbound://，URL 从未离开进程。
static UIViewController *sb_presenter_vc(void)
{
	UIViewController *vc = nil;
	for (UIWindow *w in [[UIApplication sharedApplication] windows])
	{
		if (!w.rootViewController)
			continue;
		NSString *cn = NSStringFromClass([w.rootViewController class]);
		if ([cn rangeOfString:@"SDL"].location != NSNotFound)
		{
			vc = w.rootViewController;
			break;
		}
		if (!vc)
			vc = w.rootViewController;
	}
	if (!vc)
		vc = [[[UIApplication sharedApplication] keyWindow] rootViewController];
	while (vc && vc.presentedViewController)
		vc = vc.presentedViewController;
	return vc;
}

static NSString *sb_docs_file(NSString *name)
{
	NSString *docs = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
	return [docs stringByAppendingPathComponent:name];
}

// 导出文件名从 URL 查询串里取：slotbound://export?f=SlotBound-20261128-003000.sbsave
static NSString *sb_query_name(NSString *s)
{
	NSRange r = [s rangeOfString:@"?f="];
	if (r.location == NSNotFound)
		return nil;
	NSString *raw = [s substringFromIndex:NSMaxRange(r)];
	NSString *dec = [raw stringByRemovingPercentEncoding];
	if (dec)
		raw = dec;
	raw = [raw lastPathComponent];
	if (raw.length == 0 || [raw hasPrefix:@"."])
		return nil;
	if (![[raw lowercaseString] hasSuffix:@".sbsave"])
		raw = [raw stringByAppendingPathExtension:@"sbsave"];
	return raw;
}

// 结果通过一个文本文件回传给 Lua（Lua 侧每帧轮询一次）
static void sb_state(NSString *text)
{
	[text writeToFile:sb_docs_file(@"sb_dialog_state.txt")
		   atomically:YES
		     encoding:NSUTF8StringEncoding
			error:NULL];
}

@interface SBSBDialog : NSObject <UIDocumentPickerDelegate>
@property (nonatomic, copy) NSString *mode;
@end

static SBSBDialog *g_sbDialog = nil;

@implementation SBSBDialog
- (void)documentPicker:(UIDocumentPickerViewController *)c didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls
{
	NSURL *u = urls.firstObject;
	if (!u)
	{
		sb_state(@"import fail");
		g_sbDialog = nil;
		return;
	}
	if ([self.mode isEqualToString:@"export"])
	{
		sb_state(@"export ok");
		g_sbDialog = nil;
		return;
	}
	BOOL scoped = [u startAccessingSecurityScopedResource];
	NSData *data = [NSData dataWithContentsOfURL:u];
	if (scoped)
		[u stopAccessingSecurityScopedResource];
	if (!data || data.length == 0)
	{
		sb_state(@"import fail");
	}
	else if (![data writeToFile:sb_docs_file(@"sb_import_incoming.sbsave") atomically:YES])
	{
		sb_state(@"import fail");
	}
	else
	{
		sb_state(@"import ok");
	}
	g_sbDialog = nil;
}

- (void)documentPickerWasCancelled:(UIDocumentPickerViewController *)c
{
	sb_state([self.mode isEqualToString:@"export"] ? @"export cancel" : @"import cancel");
	g_sbDialog = nil;
}
@end

static bool sb_present_export(NSString *name)
{
	NSString *path = sb_docs_file(@"sb_export.sbsave");
	if (![[NSFileManager defaultManager] fileExistsAtPath:path])
	{
		sb_state(@"export missing");
		return false;
	}
	NSString *shown = path;
	if (name.length > 0)
	{
		NSString *dest = sb_docs_file(name);
		[[NSFileManager defaultManager] removeItemAtPath:dest error:NULL];
		if ([[NSFileManager defaultManager] copyItemAtPath:path toPath:dest error:NULL])
			shown = dest;
	}
	UIViewController *top = sb_presenter_vc();
	if (!top)
		return false;
	if (@available(iOS 14.0, *))
	{
		SBSBDialog *d = [[SBSBDialog alloc] init];
		d.mode = @"export";
		g_sbDialog = d;
		UIDocumentPickerViewController *pk =
			[[UIDocumentPickerViewController alloc] initForExportingURLs:@[[NSURL fileURLWithPath:shown]] asCopy:YES];
		pk.delegate = d;
		[top presentViewController:pk animated:YES completion:nil];
		return true;
	}
	sb_state(@"export fail");
	return false;
}

static bool sb_present_import(void)
{
	UIViewController *top = sb_presenter_vc();
	if (!top)
		return false;
	SBSBDialog *d = [[SBSBDialog alloc] init];
	d.mode = @"import";
	g_sbDialog = d;
	// 用老的 initWithDocumentTypes:inMode: 避免额外链接 UniformTypeIdentifiers
	UIDocumentPickerViewController *pk =
		[[UIDocumentPickerViewController alloc] initWithDocumentTypes:@[@"public.data"] inMode:UIDocumentPickerModeImport];
	pk.delegate = d;
	[top presentViewController:pk animated:YES completion:nil];
	return true;
}

static bool sb_handle_url(const char *url)
{
	if (!url)
		return false;
	NSString *s = [NSString stringWithUTF8String:url];
	if (!s || ![s hasPrefix:@"slotbound://"])
		return false;
	if ([s hasPrefix:@"slotbound://export"])
		return sb_present_export(sb_query_name(s));
	if ([s hasPrefix:@"slotbound://import"])
		return sb_present_import();
	return false;
}

"""

OPENURL_NEEDLE = "bool openURL(const std::string &url)\n{\n"
OPENURL_INJECT = (
    OPENURL_NEEDLE
    + "\t// SlotBound: 原生存档面板走这里，URL 不出进程\n"
    + "\tif (sb_handle_url(url.c_str()))\n"
    + "\t\treturn true;\n\n"
)
NS_NEEDLE = "namespace love\n{"
NS_INJECT = OBJC_BLOCK + "namespace love\n{"


def main():
    root = sys.argv[1] if len(sys.argv) > 1 else "."
    p = os.path.join(root, "src", "common", "ios.mm")
    s = io.open(p, encoding="utf-8").read()

    if "sb_handle_url" in s:
        print("already patched:", p)
        return 0

    assert s.count(NS_NEEDLE) == 1, "namespace love anchor not unique"
    s = s.replace(NS_NEEDLE, NS_INJECT, 1)

    assert s.count(OPENURL_NEEDLE) == 1, "openURL anchor not unique"
    s = s.replace(OPENURL_NEEDLE, OPENURL_INJECT, 1)

    io.open(p, "w", encoding="utf-8", newline="\n").write(s)
    print("patched:", p)
    print("sb_handle_url x", s.count("sb_handle_url"))
    return 0


if __name__ == "__main__":
    sys.exit(main())
