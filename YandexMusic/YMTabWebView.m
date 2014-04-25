//
//  YMTabWebView.m
//  YandexMusic
//
//  Created by Dmitry Povolotsky on 4/15/14.
//  Copyright (c) 2014 mblshaworks. All rights reserved.
//

#import "YMTabWebView.h"
#import <WebKit/WebKit.h>

@interface YMTabWebView()
@property (nonatomic, strong) WebView* webView;
@property (strong, nonatomic) NSURL* selectedUrl;

@end

@implementation YMTabWebView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        WebView* newWebView = [[WebView alloc] initWithFrame:self.bounds];
        newWebView.autoresizingMask = NSViewHeightSizable| NSViewWidthSizable;
        [[newWebView preferences] setDefaultFontSize:16];
        
        
        // set our app as a Frame Load Delegate (in order to implement didClearWindowObject below)
        [newWebView setFrameLoadDelegate:self];
        
        // set our app as a WebUIDelegate and WebPolicyDelegate (for createWebViewWithRequest,
        // decidePolicyForNewWindowAction, decidePolicyForNavigationAction below)
        [newWebView setUIDelegate:self];
        [newWebView setPolicyDelegate:self];
        [self addSubview:newWebView];
        self.webView = newWebView;
        
    }
    return self;
}

- (void) setUrl:(NSURL*) url{
    self.webView.mainFrameURL = url.absoluteString;
}

- (BOOL) isPlaying{
    NSString *state = [self eval:@"Mu.Player.state"];
    return [state isEqualTo:@"playing"];
}

- (void) play{
    NSString *state = [self eval:@"Mu.Player.state"];
    if ([state isEqualTo:@"waiting"]) {
        [self eval:@"Mu.events.trigger(\"player_start\")"];
    } else if (![state isEqualTo:@"playing"]) {
        [self eval:@"Mu.Player.resume()"];
    }

}
- (void) pause{
    [self eval:@"Mu.Player.pause()"];
}
- (void) rewind{
    [self eval:@"Mu.Songbird.playPrev()"];
}
- (void) fastForward{
    [self eval:@"Mu.Songbird.playNext()"];
}


- (NSString*) title{
    return self.webView.mainFrameTitle;
}

- (NSString*)eval:(NSString*)javaScript {
    return [self.webView stringByEvaluatingJavaScriptFromString:javaScript];
}

- (void)webView:(WebView *)sender didReceiveTitle:(NSString *)title forFrame:(WebFrame *)frame{
    [self.delegate tabWebView:self changedTitle:title];
}

// Handle popup links (<href target="_blank"> and JavaScript window.open)
// taken from http://stackoverflow.com/a/16868088/17708

- (WebView *)webView:(WebView *)sender createWebViewWithRequest:(NSURLRequest *)request
{
    // HACK: This is all a hack to get around a bug/misfeature in Tiger's WebKit
    // (should be fixed in Leopard [1]). On Javascript window.open, Tiger sends a null
    // request here, then sends a loadRequest: to the new WebView, which will
    // include a decidePolicyForNavigation (which is where we'll open our
    // external window). In Leopard, we should be getting the request here from
    // the start, and we should just be able to create a new window.
    
    // [1]: @shamrin: it wasn't fixed - request is null in Lion. Hack is still needed.
    
    WebView *newWebView = [[WebView alloc] init];
    [newWebView setUIDelegate:self];
    [newWebView setPolicyDelegate:self];
    
    return newWebView;
}

- (void)webView:(WebView *)sender decidePolicyForNewWindowAction:(NSDictionary *)actionInformation request:(NSURLRequest *)request newFrameName:(NSString *)frameName decisionListener:(id<WebPolicyDecisionListener>)listener {
    [[NSWorkspace sharedWorkspace] openURL:[actionInformation objectForKey:WebActionOriginalURLKey]];
    [listener ignore];
}

- (void)webView:(WebView *)sender decidePolicyForNavigationAction:(NSDictionary *)actionInformation request:(NSURLRequest *)request frame:(WebFrame *)frame decisionListener:(id<WebPolicyDecisionListener>)listener {
    if( self.webView == sender ) {
        [listener use];
    }
    else {
        [[NSWorkspace sharedWorkspace] openURL:[actionInformation objectForKey:WebActionOriginalURLKey]];
        [listener ignore];
    }
}

// end handle popup links

- (void)webView:(WebView *)sender didClearWindowObject:(WebScriptObject *)windowScriptObject
       forFrame:(WebFrame *)frame {
    
    // install `window.yamusicapp` object into JavaScript
    [windowScriptObject setValue:self forKey:@"yamusicapp"];
    
    // inject JavaScript handler to track playing/non-playing state
    [self eval:@"(function() { "
     "if(window.MAC_APP_HANDLER_INSTALLED) { yamusicapp.log(\"handler already there\"); return; } "
     "yamusicapp.log(\"installing handler\"); "
     "yamusicapp.notify(false); "
     "Mu.events.bind(\"pl:onPlayTrack pl:onPause pl:onResume pl:onStop\", function(f) { "
     "var isPlaying = (f.type === \"pl:onResume\" || f.type === \"pl:onPlayTrack\"); "
     "yamusicapp.notify(isPlaying); "
     "}); "
     "window.MAC_APP_HANDLER_INSTALLED = true; "
     "})();"];
}

// allow `notify()` and `log()` methods on (JavaScript) `yamusicapp` object
+ (BOOL)isSelectorExcludedFromWebScript:(SEL)selector {
    if (selector == @selector(jsNotify:) || selector == @selector(jsLog:)) {
        return NO;
    }
    return YES;
}

// setup ObjC <=> JavaScript names translation
+ (NSString *) webScriptNameForSelector:(SEL)sel {
    if (sel == @selector(jsLog:)) {
        return @"log";
    } else if (sel == @selector(jsNotify:)) {
        return @"notify";
    } else {
        return nil;
    }
}

- (NSArray*) webView:(WebView *)webView contextMenuItemsForElement:(NSDictionary *)element defaultMenuItems:(NSArray *)defaultMenuItems{
    NSMutableArray* result = [NSMutableArray array];
    NSURL* linkUrl = element[WebElementLinkURLKey];
    if(linkUrl) {
        self.selectedUrl = linkUrl;
        NSMenuItem* menuItem = [[NSMenuItem alloc] initWithTitle:@"Open in New Tab" action:@selector(openInNewTabAction:) keyEquivalent:@""];
        [result addObject:menuItem];
    }
    return result;
}

- (void) jsNotify:(int)isPlaying {
    if(!isPlaying) {
        [self.delegate tabWebViewStopPlaying];
        NSLog(@"NOTIFY: not playing");
        return;
    }
    
    NSString *title = [self eval:@"Mu.Player.currentEntry.getTrack().title"];
    NSString *artist = [self eval:@"Mu.Player.currentEntry.getTrack().artist"];
    [self.delegate tabWebView:self startPlayingTrack:title artist:artist];
    
}

- (void) jsLog:(NSString*)theMessage {
    NSLog(@"jsLog: %@", theMessage);
}


-(void)openInNewTabAction:(id) something {
    [self.delegate tabWebViewWantsToOpenNewTabWithURL:self.selectedUrl];
}


@end
