//
//  TransparentWebViewAppDelegate.h
//  TransparentWebView
//
//  Created by Dirk van Oosterbosch on 22-12-10.
//  Copyright 2010 IR labs. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebView.h>
#import <WebKit/WebFrame.h>

@class PreferenceController;

extern NSString *const TWVLocationUrlKey;
extern NSString *const TWVBorderlessWindowKey;
extern NSString *const TWVMainTransparantWindowFrameKey;

#if (MAC_OS_X_VERSION_MAX_ALLOWED <= MAC_OS_X_VERSION_10_5)
@interface TransparentWebViewAppDelegate : NSObject {
#else
@interface TransparentWebViewAppDelegate : NSObject <NSApplicationDelegate, NSWindowDelegate, NSTextFieldDelegate> {
#endif
  NSWindow *window;
	WebView *theWebView;
	
	NSMenuItem *borderlessWindowMenuItem;
	
	NSWindow *locationSheet;
	NSString *urlString;
	
	PreferenceController *preferenceController;
	NSTimer *automaticReloadTimer;
}

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet WebView *theWebView;
@property (nonatomic, strong) NSWindow *borderedWindow;
@property (nonatomic, strong) NSWindow *borderlessWindow;
  
@property (assign) IBOutlet NSMenuItem *borderlessWindowMenuItem;
@property (assign) IBOutlet NSMenuItem *floatingWindowMenuItem;
  
@property (assign) IBOutlet NSMenuItem *increaseOpacityMenuItem;
@property (assign) IBOutlet NSMenuItem *decreaseOpacityMenuItem;

@property (assign) IBOutlet NSMenuItem *backMenuItem;
@property (assign) IBOutlet NSMenuItem *forwardMenuItem;
  
@property (assign) IBOutlet NSSegmentedControl *backForwardGroup;
  
@property (assign) IBOutlet NSTextField *locationTextField;
  
@property (assign) IBOutlet NSWindow *locationSheet;
@property (nonatomic, retain) NSString *urlString;
	
@property (assign) IBOutlet NSButtonCell *floatingToolbarButton;
  
@property (nonatomic, retain) PreferenceController *preferenceController;

  //- (IBAction)reloadPage:(id)sender;
  
- (IBAction)decreaseOpacity:(id)sender;
- (IBAction)increaseOpacity:(id)sender;
  
- (IBAction)toogleFloating:(id)sender;

- (IBAction)showLocationSheet:(id)sender;
- (IBAction)endLocationSheet:(id)sender;
- (IBAction)cancelLocationSheet:(id)sender;

- (IBAction)toggleBorderlessWindow:(id)sender;
- (IBAction)showPreferencePanel:(id)sender;
	
- (void)resetAutomaticReloadTimer;	
- (void)loadUrlString:(NSString *)anUrlString IntoWebView:(WebView *)aWebView;

- (void)setBorderlessWindowMenuItemState:(BOOL)booleanState;

- (void)replaceWindowWithBorderlessWindow:(BOOL)borderlessFlag;
  
- (void)webView:(WebView *)sender didStartProvisionalLoadForFrame:(WebFrame *)frame;
- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame;

@end
