//
//  YandexMusicAppDelegate.m
//  YandexMusic
//
//  Created by Michail Pishchagin on 9/1/11.
//  Copyright 2011 mblshaworks. All rights reserved.
//

#import "YandexMusicAppDelegate.h"
#import <IOKit/hidsystem/ev_keymap.h>

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
  [self listenForKeyEvents];
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

CGEventRef
myCGEventCallback(CGEventTapProxy proxy, CGEventType type,
                  CGEventRef event, void *refcon)
{
  // Paranoid sanity check.
  if ((type != kCGEventKeyDown) && (type != kCGEventKeyUp) && (type !=
                                                               NX_SYSDEFINED))
    return event;

  NSEvent *e = [NSEvent eventWithCGEvent:event];

  // We're getting a special event
  if( ([e type] == NSSystemDefined && [e subtype] == 8) ) {
		int keyCode = (([e data1] & 0xFFFF0000) >> 16);
		int keyFlags = ([e data1] & 0x0000FFFF);
		int keyState = (((keyFlags & 0xFF00) >> 8)) == 0xA;
//		int keyRepeat = (keyFlags & 0x1);
//    NSLog(@"%x; %x, %x, %x", keyCode, keyFlags, keyState, keyRepeat);
    YandexMusicAppDelegate* self = (__bridge YandexMusicAppDelegate*)refcon;

    if (keyState) {
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
      }
    }

    return NULL;
  } else if([e type] == NSKeyDown || [e type] == NSKeyUp) {
    // do whatever you do with regular events
    // return NULL to kill the event
  }

  return event;
}

- (void)listenForKeyEvents
{
  CFMachPortRef      eventTap, eventTapTest;
  CGEventMask        eventMask;
  CFRunLoopSourceRef runLoopSource;

  eventMask = ((1 << kCGEventKeyDown) | (1 << kCGEventKeyUp));

  // try creating an event tap just for keypresses. if it fails, we need Universal Access.
  eventTapTest = CGEventTapCreate(kCGSessionEventTap,
                                  kCGHeadInsertEventTap, 0,
                                  eventMask, myCGEventCallback, NULL);
  if (!eventTapTest) {
    NSLog(@"no tap");
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"Quit"];
    [alert setMessageText:@"Could not create an event tap."];
    [alert setInformativeText:@"Please enable \"access for assistive devices\" in the Universal Access pane of System Preferences."];
    [alert setAlertStyle:NSCriticalAlertStyle];
    [alert runModal];
    [NSApp terminate:self];
    return;
  }
  // disable the test tap
  // causes a crash otherwise (infinite loop with the replacement events, probably)
  CGEventTapEnable(eventTapTest, false);

  // Create an event tap. We are interested in key presses and system defined keys.
  eventTap = CGEventTapCreate(kCGSessionEventTap,
                              kCGHeadInsertEventTap, 0,
                              CGEventMaskBit(NX_SYSDEFINED) | eventMask, myCGEventCallback,
                              (__bridge void*)self);

  // Create a run loop source.
  runLoopSource = CFMachPortCreateRunLoopSource(
                                                kCFAllocatorDefault, eventTap, 0);

  // Add to the current run loop.
  CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource,
                     kCFRunLoopCommonModes);

  // Enable the event tap.
  CGEventTapEnable(eventTap, true);
}

@end
