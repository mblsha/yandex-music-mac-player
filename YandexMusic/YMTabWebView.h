//
//  YMTabWebView.h
//  YandexMusic
//
//  Created by Dmitry Povolotsky on 4/15/14.
//  Copyright (c) 2014 mblshaworks. All rights reserved.
//
@class YMTabWebView;

@protocol YMTabWebViewDelegate <NSObject>

- (void) tabWebView:(YMTabWebView*) tabWebView changedTitle:(NSString *)title;
- (void) tabWebViewStopPlaying;
- (void) tabWebView:(YMTabWebView*) tabWebView startPlayingTrack:(NSString*)track artist:(NSString*) artist;
- (void) tabWebViewWantsToOpenNewTabWithURL:(NSURL*) url;

@end

@interface YMTabWebView : NSView

@property (nonatomic, weak) NSObject<YMTabWebViewDelegate>* delegate;
@property (nonatomic, strong) NSString* title;

- (void) setUrl:(NSURL*) url;
- (void) refresh;

- (BOOL) isPlaying;
- (void) play;
- (void) pause;
- (void) rewind;
- (void) fastForward;

@end
