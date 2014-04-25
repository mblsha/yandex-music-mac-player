//
//  YMTabButtonView.h
//  YandexMusic
//
//  Created by Dmitry Povolotsky on 4/11/14.
//  Copyright (c) 2014 mblshaworks. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class YMTabButtonView;

@protocol YMTabButtonViewDelegate <NSObject>

- (void) tabButtonPressed:(YMTabButtonView*) button;
- (void) tabButtonClosePressed:(YMTabButtonView*) button;

@end

@interface YMTabButtonView : NSView


@property (nonatomic, weak) NSObject<YMTabButtonViewDelegate>* delegate;
@property (nonatomic, weak) NSString* title;
@property (nonatomic, assign) NSInteger tagValue;

@end
