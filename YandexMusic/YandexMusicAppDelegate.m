//
//  YandexMusicAppDelegate.m
//  YandexMusic
//
//  Created by Michail Pishchagin on 9/1/11.
//  Copyright 2011 mblshaworks. All rights reserved.
//

#import "YandexMusicAppDelegate.h"

@implementation YandexMusicAppDelegate

@synthesize window = _window;
@synthesize webView = _webView;
@synthesize statusMenu = _statusMenu;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	_statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
	[_statusItem setMenu:[self statusMenu]];
	[_statusItem setImage:[NSImage imageNamed:@"menu_logo_16.png"]];
	[_statusItem setHighlightMode:YES];

	[_webView setMainFrameURL:@"http://music.yandex.ru"];
}

- (NSString*)eval:(NSString*)javaScript {
	return [_webView stringByEvaluatingJavaScriptFromString:javaScript];
}

- (void)musicPlayPause {
	NSString *state = [self eval:@"Mu.Player.state"];
	if ([state isEqualTo:@"waiting"])
		[self eval:@"$Mu.trigger(\"player_start\")"];
	else if (![state isEqualTo:@"playing"])
		[self eval:@"Mu.Player.resume()"];
	else
		[self eval:@"Mu.Player.pause()"];
}

- (void)musicFastForward {
	[self eval:@"Mu.Songbird.playNext()"];
}

- (void)musicRewind {
	[self eval:@"Mu.Songbird.playPrev()"];
}

- (IBAction)showBrowser:(id)sender {
	[_window makeKeyAndOrderFront:self];
	[NSApp activateIgnoringOtherApps:YES];
}

- (IBAction)quit:(id)sender {
	[NSApp terminate:self];
}

@end
