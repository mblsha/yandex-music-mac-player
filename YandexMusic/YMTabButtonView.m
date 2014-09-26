//
//  YMTabButtonView.m
//  YandexMusic
//
//  Created by Dmitry Povolotsky on 4/11/14.
//  Copyright (c) 2014 mblshaworks. All rights reserved.
//

#import "YMTabButtonView.h"

static const CGFloat BUTTON_WIDTH = 40;

@interface YMTabButtonView ()

@property (nonatomic, strong) NSTextField* titleLabel;
@property (nonatomic, strong) NSButton* closeButton;
@property (nonatomic, strong) NSButton* refreshButton;
@end

@implementation YMTabButtonView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        NSTextField* titleLabel = [[NSTextField alloc] initWithFrame:self.bounds];
        titleLabel.autoresizingMask = NSViewWidthSizable|NSViewHeightSizable;
        [titleLabel setSelectable:NO];
        [titleLabel setEditable:NO];
        [titleLabel setDrawsBackground:YES];
        [titleLabel setAlignment:NSCenterTextAlignment];
        [titleLabel setBordered:NO];
        [titleLabel.cell setUsesSingleLineMode:YES];
        [self addSubview:titleLabel];
        self.titleLabel = titleLabel;
        
        NSButton* closeButton = [[NSButton alloc] initWithFrame:NSMakeRect(NSWidth(frame) - BUTTON_WIDTH,
                                                                          0,
                                                                          BUTTON_WIDTH, NSHeight(frame))];
        closeButton.autoresizingMask = NSViewMinXMargin|NSViewHeightSizable;
        closeButton.title = @"X";
        closeButton.target = self;
        closeButton.action = @selector(closeButtonPressed);
        [self addSubview:closeButton];
        self.closeButton = closeButton;

        NSButton* refreshButton = [[NSButton alloc] initWithFrame:NSMakeRect(NSWidth(frame) - BUTTON_WIDTH*2,
                                                                           0,
                                                                           BUTTON_WIDTH, NSHeight(frame))];
        refreshButton.autoresizingMask = NSViewMinXMargin|NSViewHeightSizable;
        refreshButton.title = @"\u27f2";
        refreshButton.target = self;
        refreshButton.action = @selector(refreshButtonPressed);
        [self addSubview:refreshButton];
        self.refreshButton = refreshButton;
       
    }
    return self;
}

#pragma mark Actions

- (void) closeButtonPressed{
    [self.delegate tabButtonClosePressed:self];
}

- (void) refreshButtonPressed{
    [self.delegate tabButtonRefreshPressed:self];
}

- (void) mouseUp:(NSEvent *)theEvent{
    [self.delegate tabButtonPressed:self];
}

#pragma mark Properties

- (NSString*) title{
    return self.titleLabel.stringValue;
}

- (void) setTitle:(NSString *)title{
    [self.titleLabel setStringValue:title];
}

- (NSInteger) tag{
    return _tagValue;
}

@end
