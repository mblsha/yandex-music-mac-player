//
//  YandexMusicAppDelegate.h
//  YandexMusic
//
//  Created by Michail Pishchagin on 9/1/11.
//  Copyright 2011 mblshaworks. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@interface YandexMusicAppDelegate : NSObject <NSApplicationDelegate>
{
	NSWindow *_window;
	WebView *_webView;
	NSMenu *_statusMenu;

	NSStatusItem *_statusItem;
}

@property (strong) IBOutlet NSWindow *window;
@property (strong) IBOutlet WebView *webView;
@property (strong) IBOutlet NSMenu *statusMenu;

- (void)musicPlayPause;
- (void)musicFastForward;
- (void)musicRewind;

- (IBAction)showBrowser:(id)sender;
- (IBAction)quit:(id)sender;

@end
