//
//  YandexMusicAppDelegate.m
//  YandexMusic
//
//  Created by Michail Pishchagin on 9/1/11.
//  Copyright 2011 mblshaworks. All rights reserved.
//

#import "YandexMusicAppDelegate.h"
#import "YMTabButtonPanelView.h"
#import "YMTabWebView.h"

@implementation YandexMusicApp



- (void)sendEvent:(NSEvent *)theEvent
{
  // If event tap is not installed, handle events that reach the app instead
  BOOL shouldHandleMediaKeyEventLocally = ![SPMediaKeyTap usesGlobalMediaKeyTap];

  if(shouldHandleMediaKeyEventLocally && [theEvent type] == NSSystemDefined
                    && [theEvent subtype] == SPSystemDefinedEventMediaKeys) {
    [(id)[self delegate] mediaKeyTap:nil receivedMediaKeyEvent:theEvent];
  }
  [super sendEvent:theEvent];
}
@end

@interface YandexMusicAppDelegate ()<YMTabButtonPanelViewDelegate, YMTabWebViewDelegate>
@property (weak) IBOutlet YMTabButtonPanelView *tabPanel;
@property (weak) IBOutlet NSView *tabContainer;
@property (strong, nonatomic) YMTabWebView* activeTabView;
@property (strong, nonatomic) YMTabWebView* playingTabView;
@property (strong, nonatomic) NSMutableArray* tabViews;

@end

@implementation YandexMusicAppDelegate

@synthesize window;
@synthesize statusMenu;
@synthesize playMenuItem;
@synthesize trackInfoMenuItem;

+(void)initialize;
{
  if([self class] != [YandexMusicAppDelegate class]) return;

  // Register defaults for the whitelist of apps that want to use media keys
  [[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
    [SPMediaKeyTap defaultMediaKeyUserBundleIdentifiers], kMediaKeyUsingBundleIdentifiersDefaultsKey,
    nil]];
}

- (BOOL)windowShouldClose:(id)sender
{
  if ([window isEqualTo:sender]) {
    // ugly hack to avoid disappearing sound on Mac OS 10.8.4
    [window orderOut:self];
    return NO;
  } else {
    return YES;
  }
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    self.tabViews = [NSMutableArray array];
    self.tabPanel.delegate = self;
  keyTap = [[SPMediaKeyTap alloc] initWithDelegate:self];
  if([SPMediaKeyTap usesGlobalMediaKeyTap])
    [keyTap startWatchingMediaKeys];
  else
    NSLog(@"Media key monitoring disabled");

  statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
  [statusItem setMenu:[self statusMenu]];
  [statusItem setImage:[NSImage imageNamed:@"menu_logo_16.png"]];
  [statusItem setHighlightMode:YES];

    [self openTabWithURL:[NSURL URLWithString:@"http://music.yandex.ru" ]];

}



- (void) openTabWithURL:(NSURL*) url{
    YMTabWebView* newTabView = [[YMTabWebView alloc] initWithFrame:self.tabContainer.bounds];
    newTabView.autoresizingMask = NSViewWidthSizable|NSViewHeightSizable;
    newTabView.delegate = self;
    [newTabView setUrl:url];
    [newTabView setHidden:YES];

    [self.tabViews addObject:newTabView];
    if(self.tabViews.count == 1){
        [self setActiveTabIndex:0];
    }
    [self.tabPanel refresh];
    [self.tabContainer addSubview:newTabView positioned:NSWindowBelow relativeTo:nil];
}

- (void) setActiveTabIndex:(NSUInteger) index{
    
    [self.activeTabView setHidden:YES];
    self.activeTabView = self.tabViews[index];
    self.activeTabView.frame = self.tabContainer.bounds;
    [self.activeTabView setHidden:NO];
    
}

- (void) closeTabWithIndex:(NSUInteger) index{
    BOOL isClosingActiveTab = self.activeTabView == self.tabViews[index];
    [self.tabViews removeObjectAtIndex:index];
    if(isClosingActiveTab){
        if(index > 0){
            [self setActiveTabIndex:index -1];
        }else{
            NSAssert(self.tabViews.count > 0, @"You can't close last tab");
            [self setActiveTabIndex:index];
        }
    }
    [self.tabPanel refresh];
}

- (YMTabWebView*) responderTab{
    return self.playingTabView ? self.playingTabView :self.activeTabView;
}




- (void)switchPlayPause {
    YMTabWebView* responderTab = [self responderTab];
    if([responderTab isPlaying]){
        [responderTab pause];
    }else{
        [responderTab play];
    }
}


// show track info in notification center
- (void)notifyCurrentTrackInfo:(NSString*)title trackArtist:(NSString*)artist {
  NSUserNotificationCenter *nc =
    [NSUserNotificationCenter defaultUserNotificationCenter];
  if (nil == nc)
    return;

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

- (IBAction)playPauseMusic:(id)sender {
    [self switchPlayPause];
}

- (IBAction)fastForwardMusic:(id)sender {
    [[self responderTab] fastForward];
}

- (IBAction)rewindMusic:(id)sender {
    [[self responderTab] rewind];
}

- (IBAction)showBrowser:(id)sender {
  [window makeKeyAndOrderFront:self];
  [NSApp activateIgnoringOtherApps:YES];
}

- (IBAction)quit:(id)sender {
  [NSApp terminate:self];
}

-(void)mediaKeyTap:(SPMediaKeyTap*)keyTap receivedMediaKeyEvent:(NSEvent*)event;
{
    NSAssert([event type] == NSSystemDefined && [event subtype] == SPSystemDefinedEventMediaKeys, @"Unexpected NSEvent in mediaKeyTap:receivedMediaKeyEvent:");
    
    int keyCode = (([event data1] & 0xFFFF0000) >> 16);
    int keyFlags = ([event data1] & 0x0000FFFF);
    BOOL keyIsPressed = (((keyFlags & 0xFF00) >> 8)) == 0xA;
    
    if (keyIsPressed) {
        switch (keyCode) {
            case NX_KEYTYPE_PLAY:
                [self switchPlayPause];
                break;
            case NX_KEYTYPE_FAST:
                [[self responderTab] fastForward];
                break;
            case NX_KEYTYPE_REWIND:
                [[self responderTab] rewind];
                break;
            default:
                break;
        }
    }
}
#pragma mark YMTabWebView

- (void)tabWebViewStopPlaying{
    [statusItem setImage:[NSImage imageNamed:@"menu_logo_16"]];
    [playMenuItem setTitle:@"Play        ▶"];
    
}

- (void) tabWebView:(YMTabWebView*) tabWebView startPlayingTrack:(NSString*)track artist:(NSString*) artist{
    [statusItem setImage:[NSImage imageNamed:@"menu_logo_16_playing"]];
    [playMenuItem setTitle:@"Pause      ❙❙"];
    [self notifyCurrentTrackInfo:track trackArtist:artist];
    
    NSString *trackInfo = [track stringByAppendingString:@" – "];
    trackInfo = [trackInfo stringByAppendingString:artist];
    [trackInfoMenuItem setTitle:trackInfo];
    self.playingTabView = tabWebView;
}

-(void)tabWebViewWantsToOpenNewTabWithURL:(NSURL *)url{
    [self openTabWithURL:url];
}

- (void) tabWebView:(YMTabWebView*) tabWebView changedTitle:(NSString *)title{
    [self.tabPanel refreshTabWithIndex:[self.tabViews indexOfObject:tabWebView]];
}

#pragma mark YMTabButtonPanelViewDelegate

- (NSUInteger) tabButtonPanelNumberOfButtons{
    return self.tabViews.count;
}

- (NSString*) tabButtonPanelTitleOfButtonWithIndex:(NSUInteger)index{
    return ((YMTabWebView*)self.tabViews[index]).title;
}

- (void) tabButtonPanelButtonSelected:(NSUInteger)index{
    [self setActiveTabIndex:index];
}

- (void) tabButtonPanelRequestedCloseTab:(NSUInteger)index{
    [self closeTabWithIndex:index];
}

@end
