//
//  MediaKeysApplication.m
//  YandexMusic
//
//  Created by Michail Pishchagin on 9/1/11.
//  Copyright 2011 mblshaworks. All rights reserved.
//

#import "MediaKeysApplication.h"

#import <IOKit/hidsystem/ev_keymap.h>

#import "YandexMusicAppDelegate.h"

@implementation MediaKeysApplication

- (void)mediaKeyEvent:(int)key state:(BOOL)state repeat:(BOOL)repeat
{
	if (state != 0)
		return;

	YandexMusicAppDelegate *musicDelegate = [self delegate];
	switch (key) {
		case NX_KEYTYPE_PLAY:
			[musicDelegate musicPlayPause];
			break;
			
		case NX_KEYTYPE_FAST:
			[musicDelegate musicFastForward];
			break;
			
		case NX_KEYTYPE_REWIND:
			[musicDelegate musicRewind];
			break;
	}
}

- (void)sendEvent: (NSEvent*)event
{
	if (([event type] == NSSystemDefined) && ([event subtype] == 8)) {
		int keyCode = (([event data1] & 0xFFFF0000) >> 16);
		int keyFlags = ([event data1] & 0x0000FFFF);
		int keyState = (((keyFlags & 0xFF00) >> 8)) == 0xA;
		int keyRepeat = (keyFlags & 0x1);
		
		[self mediaKeyEvent:keyCode state:keyState repeat:keyRepeat];
	}
	
	[super sendEvent:event];
}

@end
