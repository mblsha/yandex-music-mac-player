//
//  YMTabButtonPanelView.h
//  YandexMusic
//
//  Created by Dmitry Povolotsky on 4/11/14.
//  Copyright (c) 2014 mblshaworks. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@protocol YMTabButtonPanelViewDelegate <NSObject>

- (NSUInteger) tabButtonPanelNumberOfButtons;
- (NSString*) tabButtonPanelTitleOfButtonWithIndex:(NSUInteger) index;

- (void) tabButtonPanelButtonSelected:(NSUInteger) index;
- (void) tabButtonPanelRequestedCloseTab:(NSUInteger) index;
- (void) tabButtonPanelRequestedRefreshTab:(NSUInteger) index;

@end

@interface YMTabButtonPanelView : NSView

@property (nonatomic, assign) NSObject<YMTabButtonPanelViewDelegate>* delegate;

- (void)refresh;
- (void)refreshTabWithIndex:(NSUInteger) index;

@end
