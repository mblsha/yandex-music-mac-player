//
//  YandexMusicAppDelegate.h
//  YandexMusic
//
//  Created by Michail Pishchagin on 9/1/11.
//  Copyright 2011 mblshaworks. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "../SPMediaKeyTap/SPMediaKeyTap.h"

@interface YandexMusicApp : NSApplication
@end

@interface YandexMusicAppDelegate : NSObject <NSApplicationDelegate, NSUserNotificationCenterDelegate, NSWindowDelegate>
{
  NSWindow *window;
  NSMenu *statusMenu;
  NSStatusItem *statusItem;
  NSMenuItem *playMenuItem;
  NSMenuItem *trackInfoMenuItem;
  SPMediaKeyTap *keyTap;
}

@property (strong) IBOutlet NSWindow *window;
@property (strong) IBOutlet NSMenu *statusMenu;
@property (strong) IBOutlet NSMenuItem *playMenuItem;
@property (strong) IBOutlet NSMenuItem *trackInfoMenuItem;

- (IBAction)playPauseMusic:(id)sender;
- (IBAction)fastForwardMusic:(id)sender;
- (IBAction)rewindMusic:(id)sender;
- (IBAction)showBrowser:(id)sender;
- (IBAction)quit:(id)sender;

// Window close hook
- (BOOL)windowShouldClose:(id)sender;

@end
