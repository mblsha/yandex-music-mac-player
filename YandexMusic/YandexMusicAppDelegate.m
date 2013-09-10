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

@synthesize handlerInstalled;
@synthesize window;
@synthesize webView;
@synthesize statusMenu;
@synthesize playMenuItem;
@synthesize trackInfoMenuItem;

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

  handlerInstalled = @"NO";

  // set our app as a Frame Load Delegate (in order to implement didClearWindowObject below)
  [webView setFrameLoadDelegate:self];
}

- (NSString*)eval:(NSString*)javaScript {
  return [webView stringByEvaluatingJavaScriptFromString:javaScript];
}

- (void)webView:(WebView *)sender didClearWindowObject:(WebScriptObject *)windowScriptObject
       forFrame:(WebFrame *)frame {

    // install `window.yamusicapp` object into JavaScript
    [windowScriptObject setValue:self forKey:@"yamusicapp"];

    // inject JavaScript handler to track playing/non-playing state
    [self eval:@"(function() { "
                   "if(yamusicapp.handlerInstalled !== \"NO\") { yamusicapp.log(\"handler already there\"); return; } "
                   "yamusicapp.log(\"installing handler\"); "
                   "Mu.events.bind(\"pl:onPlayTrack pl:onPause pl:onResume pl:onStop\", function(f) { "
                     "var isPlaying = (f.type === \"pl:onResume\" || f.type === \"pl:onPlayTrack\"); "
                     "yamusicapp.notify(isPlaying); "
                   "}); "
                   "yamusicapp.handlerInstalled = \"YES\"; "
                "})();"];
}

// allow `notify()` and `log()` methods on (JavaScript) `yamusicapp` object
+ (BOOL)isSelectorExcludedFromWebScript:(SEL)selector {
    if (selector == @selector(jsNotify:) || selector == @selector(jsLog:)) {
        return NO;
    }
    return YES;
}

// allow `handlerInstalled` property on `yamusicapp` object
+ (BOOL)isKeyExcludedFromWebScript:(const char *)property {
    if (strcmp(property, "handlerInstalled") == 0) {
        return NO;
    }
    return YES;
}

// setup ObjC <=> JavaScript names translation
+ (NSString *) webScriptNameForSelector:(SEL)sel {
    if (sel == @selector(jsLog:)) {
        return @"log";
    } else if (sel == @selector(jsNotify:)) {
        return @"notify";
    } else {
        return nil;
    }
}

- (void) jsNotify:(int)isPlaying {
    [self updateStatusIcon:isPlaying];

    if(!isPlaying) {
        NSLog(@"NOTIFY: not playing");
        return;
    }

    NSString *title = [self eval:@"Mu.Player.currentEntry.getTrack().title"];
    NSString *artist = [self eval:@"Mu.Player.currentEntry.getTrack().artist"];
    [self notifyCurrentTrackInfo:title trackArtist:artist];

    NSString *trackInfo = [title stringByAppendingString:@" – "];
    trackInfo = [trackInfo stringByAppendingString:artist];
    [trackInfoMenuItem setTitle:trackInfo];
}

- (void) jsLog:(NSString*)theMessage {
    NSLog(@"jsLog: %@", theMessage);
}

- (void)musicPlayPause {
  NSString *state = [self eval:@"Mu.Player.state"];
  if ([state isEqualTo:@"waiting"]) {
    [self eval:@"Mu.events.trigger(\"player_start\")"];
  } else if (![state isEqualTo:@"playing"]) {
    [self eval:@"Mu.Player.resume()"];
  } else
    [self eval:@"Mu.Player.pause()"];
}

- (void)musicFastForward {
  [self eval:@"Mu.Songbird.playNext()"];
}

- (void)musicRewind {
  [self eval:@"Mu.Songbird.playPrev()"];
}

// show track info in notification center
- (void)notifyCurrentTrackInfo:(NSString*)title trackArtist:(NSString*)artist {
  NSUserNotificationCenter *nc =
    [NSUserNotificationCenter defaultUserNotificationCenter];
  if (nil == nc)
    return;

  NSUserNotification *notification = [[NSUserNotification alloc] init];
  [notification setTitle:artist];
  [notification setInformativeText:title];
  [notification setHasActionButton:NO];

  [nc deliverNotification:notification];
}

- (void)updateStatusIcon:(bool)isPlaying {
  if (isPlaying) {
    [statusItem setImage:[NSImage imageNamed:@"menu_logo_16_playing"]];
    [playMenuItem setTitle:@"Pause      ❙❙"];
  } else {
    [statusItem setImage:[NSImage imageNamed:@"menu_logo_16"]];
    [playMenuItem setTitle:@"Play        ▶"];
  }
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
  int keyRepeat = (keyFlags & 0x1);

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
