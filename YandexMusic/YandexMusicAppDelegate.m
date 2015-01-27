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

- (BOOL)windowShouldClose:(id)sender
{
  if ([window isEqualTo:sender]) {
    // ugly hack to avoid disappearing sound on Mac OS 10.8.4
    [window orderOut:self];
    return NO;
  } else {
    return YES;
  }
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
  [[webView preferences] setDefaultFontSize:16];

  // set our app as a Frame Load Delegate (in order to implement didClearWindowObject below)
  [webView setFrameLoadDelegate:self];

  // set our app as a WebUIDelegate and WebPolicyDelegate (for createWebViewWithRequest,
  // decidePolicyForNewWindowAction, decidePolicyForNavigationAction below)
  [webView setUIDelegate:self];
  [webView setPolicyDelegate:self];
}

- (NSString*)eval:(NSString*)javaScript {
  return [webView stringByEvaluatingJavaScriptFromString:javaScript];
}


// Handle popup links (<href target="_blank"> and JavaScript window.open)
// taken from http://stackoverflow.com/a/16868088/17708

- (WebView *)webView:(WebView *)sender createWebViewWithRequest:(NSURLRequest *)request
{
  // HACK: This is all a hack to get around a bug/misfeature in Tiger's WebKit
  // (should be fixed in Leopard [1]). On Javascript window.open, Tiger sends a null
  // request here, then sends a loadRequest: to the new WebView, which will
  // include a decidePolicyForNavigation (which is where we'll open our
  // external window). In Leopard, we should be getting the request here from
  // the start, and we should just be able to create a new window.

  // [1]: @shamrin: it wasn't fixed - request is null in Lion. Hack is still needed.

  WebView *newWebView = [[WebView alloc] init];
  [newWebView setUIDelegate:self];
  [newWebView setPolicyDelegate:self];

  return newWebView;
}

- (void)webView:(WebView *)sender decidePolicyForNewWindowAction:(NSDictionary *)actionInformation request:(NSURLRequest *)request newFrameName:(NSString *)frameName decisionListener:(id<WebPolicyDecisionListener>)listener {
  [[NSWorkspace sharedWorkspace] openURL:[actionInformation objectForKey:WebActionOriginalURLKey]];
  [listener ignore];
}

- (void)webView:(WebView *)sender decidePolicyForNavigationAction:(NSDictionary *)actionInformation request:(NSURLRequest *)request frame:(WebFrame *)frame decisionListener:(id<WebPolicyDecisionListener>)listener {
  if( [sender isEqual:webView] ) {
    [listener use];
  }
  else {
    [[NSWorkspace sharedWorkspace] openURL:[actionInformation objectForKey:WebActionOriginalURLKey]];
    [listener ignore];
  }
}

// end handle popup links

- (void)webView:(WebView *)sender didClearWindowObject:(WebScriptObject *)windowScriptObject
       forFrame:(WebFrame *)frame {

    // install `window.yamusicapp` object into JavaScript
    [windowScriptObject setValue:self forKey:@"yamusicapp"];

    // inject JavaScript handler to track playing/non-playing state
    [self eval:@"(function() { "
                   "if(window.MAC_APP_HANDLER_INSTALLED) { yamusicapp.log(\"handler already there\"); return; } "
                   "yamusicapp.log(\"installing handler\"); "
                   "yamusicapp.notify(false); "
                   "Mu.events.bind(\"pl:onPlayTrack pl:onPause pl:onResume pl:onStop\", function(f) { "
                     "var isPlaying = (f.type === \"pl:onResume\" || f.type === \"pl:onPlayTrack\"); "
                     "yamusicapp.notify(isPlaying); "
                   "}); "
                   "window.MAC_APP_HANDLER_INSTALLED = true; "
                "})();"];
}

// allow `notify()` and `log()` methods on (JavaScript) `yamusicapp` object
+ (BOOL)isSelectorExcludedFromWebScript:(SEL)selector {
    if (selector == @selector(jsNotify:) || selector == @selector(jsLog:)) {
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
  [self eval:@"jQuery('.player-controls__btn.player-controls__btn_play').click()"];
}

- (void)musicFastForward {
  [self eval:@"jQuery('.player-controls__btn.player-controls__btn_next').click()"];
}

- (void)musicRewind {
  [self eval:@"jQuery('.player-controls__btn.player-controls__btn_prev').click()"];
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
