//
//  YMTabButtonView.m
//  YandexMusic
//
//  Created by Dmitry Povolotsky on 4/11/14.
//  Copyright (c) 2014 mblshaworks. All rights reserved.
//

#import "YMTabButtonView.h"

@interface YMTabButtonView ()

@property (nonatomic, strong) NSTextField* titleLabel;
@property (nonatomic, strong) NSButton* closeButton;
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
        
        NSButton* closeButton = [[NSButton alloc] initWithFrame:NSMakeRect(NSWidth(frame) - 40,
                                                                          0,
                                                                          40, NSHeight(frame))];
        closeButton.autoresizingMask = NSViewMinXMargin|NSViewHeightSizable;
        closeButton.title = @"X";
        closeButton.target = self;
        closeButton.action = @selector(closeButtonPressed);
        [self addSubview:closeButton];
        self.closeButton = closeButton;

        
    }
    return self;
}

#pragma mark Actions

- (void) closeButtonPressed{
    [self.delegate tabButtonClosePressed:self];
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
