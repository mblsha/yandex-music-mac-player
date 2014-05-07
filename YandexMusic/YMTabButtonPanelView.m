//
//  YMTabButtonPanelView.m
//  YandexMusic
//
//  Created by Dmitry Povolotsky on 4/11/14.
//  Copyright (c) 2014 mblshaworks. All rights reserved.
//

#import "YMTabButtonPanelView.h"
#import "YMTabButtonView.h"

@interface YMTabButtonPanelView ()<YMTabButtonViewDelegate>
@property (nonatomic, strong) NSMutableArray* buttons;
@end

@implementation YMTabButtonPanelView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.buttons = [NSMutableArray array];
        self.translatesAutoresizingMaskIntoConstraints = YES;
    }
    return self;
}



- (void) resizeSubviewsWithOldSize:(NSSize)oldSize{
    [super resizeSubviewsWithOldSize:oldSize];
    NSRect bounds = self.bounds;
    CGFloat width = NSWidth(bounds)/self.buttons.count;
    CGFloat height = NSHeight(bounds);
    CGFloat offsetX = 0;
    for(NSView* button in self.buttons){
        button.frame = NSMakeRect(offsetX, 0, width, height);
        offsetX += width;
    }

}


-(void) refresh{
    [self removeAllButtons];
    [self createButtons];
    [self setNeedsLayout:YES];
    [self layout];
    
}

- (void)refreshTabWithIndex:(NSUInteger) index{
    YMTabButtonView* button = (YMTabButtonView*)self.buttons[index];
    [button setTitle:[self.delegate tabButtonPanelTitleOfButtonWithIndex:index]];
}


- (void) removeAllButtons{
    for(NSView* button in self.buttons){
        [button removeFromSuperview];
    }
    [self.buttons removeAllObjects];
}

- (void) createButtons{
    NSUInteger count = [self.delegate tabButtonPanelNumberOfButtons];
    for(NSUInteger i = 0; i < count; i++){
        YMTabButtonView* button = [[YMTabButtonView alloc] initWithFrame:NSZeroRect];
        button.delegate = self;
        //TODO:
        button.tagValue = i;
        [button setTitle:[self.delegate tabButtonPanelTitleOfButtonWithIndex:i]];
        [self.buttons addObject:button];
        [self addSubview:button];
    }
}

#pragma mark YMTabButtonViewDelegate

- (void) tabButtonPressed:(YMTabButtonView *)button{
    [self.delegate tabButtonPanelButtonSelected:button.tag];
}

- (void) tabButtonClosePressed:(YMTabButtonView *)button{
    [self.delegate tabButtonPanelRequestedCloseTab:button.tag];
}


@end
