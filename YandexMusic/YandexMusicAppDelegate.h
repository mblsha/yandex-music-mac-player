//
//  YandexMusicAppDelegate.h
//  YandexMusic
//
//  Created by Michail Pishchagin on 9/1/11.
//  Copyright 2011 MAZsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface YandexMusicAppDelegate : NSObject <NSApplicationDelegate> {
	NSWindow *_window;
}

@property (strong) IBOutlet NSWindow *window;

@end
