//
//  YandexMusicAppDelegate.m
//  YandexMusic
//
//  Created by Michail Pishchagin on 9/1/11.
//  Copyright 2011 mblshaworks. All rights reserved.
//

#import "YandexMusicAppDelegate.h"

@implementation YandexMusicApp
- (void)sendEvent:(NSEvent *)theEvent
{
  // If event tap is not installed, handle events that reach the app instead
  BOOL shouldHandleMediaKeyEventLocally = ![SPMediaKeyTap usesGlobalMediaKeyTap];

  if(shouldHandleMediaKeyEventLocally && [theEvent type] == NSSystemDefined
                    && [theEvent subtype] == SPSystemDefinedEventMediaKeys) {
    [(id)[self delegate] mediaKeyTap:nil receivedMediaKeyEvent:theEvent];
  }
  [super sendEvent:theEvent];
}
@end

@implementation YandexMusicAppDelegate

@synthesize window;
@synthesize webView;
@synthesize statusMenu;

bool windowResized = false;

+(void)initialize;
{
  if([self class] != [YandexMusicAppDelegate class]) return;

  // Register defaults for the whitelist of apps that want to use media keys
  [[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
    [SPMediaKeyTap defaultMediaKeyUserBundleIdentifiers], kMediaKeyUsingBundleIdentifiersDefaultsKey,
    nil]];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
  keyTap = [[SPMediaKeyTap alloc] initWithDelegate:self];
  if([SPMediaKeyTap usesGlobalMediaKeyTap])
    [keyTap startWatchingMediaKeys];
  else
    NSLog(@"Media key monitoring disabled");

  statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
  [statusItem setMenu:[self statusMenu]];
  [statusItem setImage:[NSImage imageNamed:@"menu_logo_16.png"]];
  [statusItem setHighlightMode:YES];

  [webView setMainFrameURL:@"http://music.yandex.ru"];
}

- (NSString*)eval:(NSString*)javaScript {
  return [webView stringByEvaluatingJavaScriptFromString:javaScript];
}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame {
  if (!windowResized) {
    NSInteger targetWidth = [[self eval:@"document.body.scrollWidth"] integerValue];
    
    [webView setFrameSize:NSMakeSize(targetWidth, webView.frame.size.height)];
    [window setFrame:NSMakeRect(window.frame.origin.x, window.frame.origin.y,
                                targetWidth, window.frame.size.height) display:true];
    
    windowResized = true;
  }
}

- (bool)isPlaying {
  NSString *playing = [self eval:@"Mu.Player.isPlaying()"];
  return [playing isEqual:@"true"];
}

- (void)updateStatus {
  // update status menu icon
  if ([self isPlaying]) {
    [statusItem setImage:[NSImage imageNamed:@"menu_logo_16_playing"]];
  } else {
    [statusItem setImage:[NSImage imageNamed:@"menu_logo_16"]];
  }
  
  // TODO: enable/disable menuitems in accordance with state of the Mu.Player
  // TODO: add informational menuitem with track info
}

- (void)musicPlayPause {
  NSString *state = [self eval:@"Mu.Player.state"];
  if ([state isEqualTo:@"waiting"]) {
    [self eval:@"$('.b-jambox__play').click();"];
    [self notifyCurrentTrackInfo];
  } else if (![state isEqualTo:@"playing"]) {
    [self eval:@"Mu.Player.resume()"];
    [self notifyCurrentTrackInfo];
  } else {
    [self eval:@"Mu.Player.pause()"];
  }
  
  [self updateStatus];
}

- (void)musicFastForward {
  [self eval:@"Mu.Songbird.playNext()"];
  [self notifyCurrentTrackInfo];
  [self updateStatus];
}

- (void)musicRewind {
  [self eval:@"Mu.Songbird.playPrev()"];
  [self notifyCurrentTrackInfo];
  [self updateStatus];
}


- (void)notifyCurrentTrackInfo {
  NSUserNotificationCenter *nc =
    [NSUserNotificationCenter defaultUserNotificationCenter];
  if (nil == nc)
    return;

  if ([self isPlaying]) {
    return;
  }

  NSString *title = [self eval:@"Mu.Player.currentEntry.getTrack().title"];
  NSString *artist = [self eval:@"Mu.Player.currentEntry.getTrack().artist"];

  NSUserNotification *notification = [[NSUserNotification alloc] init];
  [notification setTitle:artist];
  [notification setInformativeText:title];
  [notification setHasActionButton:NO];

  [nc deliverNotification:notification];
}

- (void)userNotificationCenter:(NSUserNotificationCenter *)center
       didActivateNotification:(NSUserNotification *)notification {
  NSRunAlertPanel([notification title],
                  [notification informativeText], nil, nil, nil);
}

- (void)userNotificationCenter:(NSUserNotificationCenter *)center
        didDeliverNotification:(NSUserNotification *)notification {
  [center removeDeliveredNotification:notification];
  [self showBrowser:nil];
}

- (IBAction)playPauseMusic:(id)sender {
  [self musicPlayPause];
}

- (IBAction)fastForwardMusic:(id)sender {
  [self musicFastForward];
}

- (IBAction)rewindMusic:(id)sender {
  [self musicRewind];
}

- (IBAction)showBrowser:(id)sender {
  [window makeKeyAndOrderFront:self];
  [NSApp activateIgnoringOtherApps:YES];
}

- (IBAction)quit:(id)sender {
  [NSApp terminate:self];
}

-(void)mediaKeyTap:(SPMediaKeyTap*)keyTap receivedMediaKeyEvent:(NSEvent*)event;
{
  NSAssert([event type] == NSSystemDefined && [event subtype] == SPSystemDefinedEventMediaKeys, @"Unexpected NSEvent in mediaKeyTap:receivedMediaKeyEvent:");

  int keyCode = (([event data1] & 0xFFFF0000) >> 16);
  int keyFlags = ([event data1] & 0x0000FFFF);
  BOOL keyIsPressed = (((keyFlags & 0xFF00) >> 8)) == 0xA;

  if (keyIsPressed) {
    switch (keyCode) {
      case NX_KEYTYPE_PLAY:
        [self musicPlayPause];
        break;
      case NX_KEYTYPE_FAST:
        [self musicFastForward];
        break;
      case NX_KEYTYPE_REWIND:
        [self musicRewind];
        break;
      default:
        break;
    }
  }
}

@end
