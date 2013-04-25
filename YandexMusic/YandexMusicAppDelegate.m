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

	if(shouldHandleMediaKeyEventLocally
			&& [theEvent type] == NSSystemDefined
			&& [theEvent subtype] == SPSystemDefinedEventMediaKeys) {
		[(id)[self delegate] mediaKeyTap:nil receivedMediaKeyEvent:theEvent];
	}
	[super sendEvent:theEvent];
}
@end

@implementation YandexMusicAppDelegate

@synthesize window = _window;
@synthesize webView = _webView;
@synthesize statusMenu = _statusMenu;

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
  if ([state isEqualTo:@"waiting"]) {
    [self eval:@"$Mu.trigger(\"player_start\")"];
    [self notifyCurrentTrackInfo];
  } else if (![state isEqualTo:@"playing"]) {
    [self eval:@"Mu.Player.resume()"];
    [self notifyCurrentTrackInfo];
  } else
    [self eval:@"Mu.Player.pause()"];
}

- (void)musicFastForward {
  [self eval:@"Mu.Songbird.playNext()"];
  [self notifyCurrentTrackInfo];
}

- (void)musicRewind {
  [self eval:@"Mu.Songbird.playPrev()"];
  [self notifyCurrentTrackInfo];
}


- (void)notifyCurrentTrackInfo {
  NSUserNotificationCenter *nc =
      [NSUserNotificationCenter defaultUserNotificationCenter];
  if (nil == nc)
    return;

  NSString *playing = [self eval:@"Mu.Player.isPlaying()"];
  if ([playing isEqual:@"false"]) {
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

- (IBAction)showBrowser:(id)sender {
	[_window makeKeyAndOrderFront:self];
	[NSApp activateIgnoringOtherApps:YES];
}

- (IBAction)quit:(id)sender {
	[NSApp terminate:self];
}

-(void)mediaKeyTap:(SPMediaKeyTap*)keyTap receivedMediaKeyEvent:(NSEvent*)event;
{
	NSAssert([event type] == NSSystemDefined && [event subtype] == SPSystemDefinedEventMediaKeys, @"Unexpected NSEvent in mediaKeyTap:receivedMediaKeyEvent:");
	// here be dragons...
	int keyCode = (([event data1] & 0xFFFF0000) >> 16);
	int keyFlags = ([event data1] & 0x0000FFFF);
	BOOL keyIsPressed = (((keyFlags & 0xFF00) >> 8)) == 0xA;
	int keyRepeat = (keyFlags & 0x1);

	if (keyIsPressed) {
		NSString *debugString = [NSString stringWithFormat:@"%@", keyRepeat?@", repeated.":@"."];
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
