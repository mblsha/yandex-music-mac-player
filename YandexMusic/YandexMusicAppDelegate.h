//
//  YandexMusicAppDelegate.h
//  YandexMusic
//
//  Created by Michail Pishchagin on 9/1/11.
//  Copyright 2011 mblshaworks. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import "../SPMediaKeyTap/SPMediaKeyTap.h"

@interface YandexMusicApp : NSApplication
@end

@interface YandexMusicAppDelegate : NSObject <NSApplicationDelegate, NSUserNotificationCenterDelegate>
{
  NSWindow *window;
  WebView *webView;
  NSMenu *statusMenu;
  NSStatusItem *statusItem;
  NSMenuItem *playMenuItem;
  NSMenuItem *trackInfoMenuItem;
  SPMediaKeyTap *keyTap;
}

@property (strong) IBOutlet NSWindow *window;
@property (strong) IBOutlet WebView *webView;
@property (strong) IBOutlet NSMenu *statusMenu;
@property (strong) IBOutlet NSMenuItem *playMenuItem;
@property (strong) IBOutlet NSMenuItem *trackInfoMenuItem;

- (void)musicPlayPause;
- (void)musicFastForward;
- (void)musicRewind;

- (IBAction)playPauseMusic:(id)sender;
- (IBAction)fastForwardMusic:(id)sender;
- (IBAction)rewindMusic:(id)sender;
- (IBAction)showBrowser:(id)sender;
- (IBAction)quit:(id)sender;

// Frame Load Delegate method
- (void)webView:(WebView *)webView didClearWindowObject:(WebScriptObject *)windowScriptObject
       forFrame:(WebFrame *)frame;

// configure what is available to use from JavaScript
+ (BOOL)isSelectorExcludedFromWebScript:(SEL)selector;
+ (NSString *) webScriptNameForSelector:(SEL)sel;

// methods to share with JavaScript
- (void) jsLog:(NSString*)theMessage;
- (void) jsNotify:(int)isPlaying;

@end
