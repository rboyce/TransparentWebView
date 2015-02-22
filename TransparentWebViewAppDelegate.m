//
//  TransparentWebViewAppDelegate.m
//  TransparentWebView
//
//  Created by Dirk van Oosterbosch on 22-12-10.
//  Copyright 2010 IR labs. All rights reserved.
//

#import "TransparentWebViewAppDelegate.h"
#import "WebViewWindow.h"
#import "PreferenceController.h"

NSString *const TWVLocationUrlKey = @"WebViewLocationUrl";
NSString *const TWVBorderlessWindowKey = @"OpenBorderlessWindow";
NSString *const TWVMainTransparantWindowFrameKey = @"MainTransparentWindow";
NSString *const TWVWindowFloatingKey = @"WindowFloating";

double const kOpacityInterval = 0.1;

const CGFloat kToolbarHeight = 40.0;

@implementation TransparentWebViewAppDelegate {
  CGFloat _toolbarHeight;
}

@synthesize window, theWebView;
@synthesize borderlessWindowMenuItem;
@synthesize locationSheet, urlString;
@synthesize preferenceController;


+ (void)initialize {
  // Register the Defaults in the Preferences
  NSMutableDictionary *defaultValues = [NSMutableDictionary dictionary];
  
  [defaultValues setObject:@"http://localhost/" forKey:TWVLocationUrlKey];
  [defaultValues setObject:[NSNumber numberWithBool:NO] forKey:TWVBorderlessWindowKey];
  
  [defaultValues setObject:[NSNumber numberWithBool:NO] forKey:TWVShouldAutomaticReloadKey];
  [defaultValues setObject:[NSNumber numberWithBool:YES] forKey:TWVWindowFloatingKey];
  [defaultValues setObject:[NSNumber numberWithInt:15] forKey:TWVAutomaticReloadIntervalKey];
  
  [defaultValues setObject:[NSNumber numberWithBool:YES] forKey:@"WebKitDeveloperExtras"];
  
  [[NSUserDefaults standardUserDefaults] registerDefaults:defaultValues];
}

- (id) init {
	[super init];
	
	// Set the url from the Preferences file
  self.urlString = [[NSUserDefaults standardUserDefaults] objectForKey:TWVLocationUrlKey];
	
	// Register for Preference Changes
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(handleAutomaticReloadChange:)
												 name:TWVAutomaticReloadChangedNotification
											   object:nil];
	
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(handleOpacityChange:)
                                               name:TWVOpacityChangedNotification
                                             object:nil];
  
	return self;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// Insert code here to initialize your application
	NSLog(@"TransparentWebView app got launched ...");
  
  [window setDelegate:self];
  
  // Set the window type and the content frame
  self.borderedWindow = window;
  
  [self replaceWindowWithBorderlessWindow:[self _borderlessState]];
  [self setBorderlessWindowMenuItemState:[self _borderlessState]];
  
  [self loadUrlString:self.urlString IntoWebView:self.theWebView];
  
  [self _setWebViewOpacity:[self _opacity]];
  
  [self _setFloatingState:[self _isWindowFloating]];
	
	// Make us the delegate of the Main Window
  
	// Start a timer if the Transparent Web View is set to reload with a given interval
	[self resetAutomaticReloadTimer];
}

#pragma mark -
#pragma mark Location Sheet

- (IBAction)showLocationSheet:(id)sender {
	//
	[NSApp beginSheet:locationSheet
	   modalForWindow:window
      modalDelegate:nil
	   didEndSelector:NULL
        contextInfo:NULL];
}


- (IBAction)endLocationSheet:(id)sender {
	
	// Return to normal event handling and hide the sheet
	[NSApp endSheet:locationSheet];
	[locationSheet orderOut:sender];
	
	// Save the location url in the Preferences
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject:self.urlString forKey:TWVLocationUrlKey];
	
	NSLog(@"Load the url: %@", urlString);
	[self loadUrlString:self.urlString IntoWebView:self.theWebView];
}

- (IBAction)cancelLocationSheet:(id)sender {
	// Return to normal event handling and hide the sheet
	[NSApp endSheet:locationSheet];
	[locationSheet orderOut:sender];
}

/*
 * The method to load any url string into a web view of choice
 */
- (void)loadUrlString:(NSString *)anUrlString IntoWebView:(WebView *)aWebView {
	
	// Make an URL from the String, and then a Request from the URL
	NSURL *url = [NSURL URLWithString:anUrlString];
	NSURLRequest *urlReq = [NSURLRequest requestWithURL:url];
	
	// Get the webFrame and load the request
	WebFrame* webFrame = [aWebView mainFrame];
	[webFrame loadRequest: urlReq];
}


#pragma mark -
#pragma mark Preferences Panel

- (IBAction)showPreferencePanel:(id)sender {
	// Lazy loading
	if (self.preferenceController == nil) {
		PreferenceController *prefController = [[PreferenceController alloc] init];
		self.preferenceController = prefController;
		[prefController release];
	}
	NSLog(@"showing %@", preferenceController);
	[preferenceController showWindow:self];
}


- (void)handleAutomaticReloadChange:(NSNotification *)notification {
	//NSLog(@"Received Notification %@", notification);
	[self resetAutomaticReloadTimer];
}


- (void)resetAutomaticReloadTimer {
	// Invalidate the previousTimer
	if (automaticReloadTimer != nil) {
		[automaticReloadTimer invalidate];
		[automaticReloadTimer release];
		automaticReloadTimer = nil;
	}
	
	// Do we need a timer?
	if ( [[NSUserDefaults standardUserDefaults] boolForKey:TWVShouldAutomaticReloadKey] ) {
		// Create a new timer
		int reloadInterval = [[[NSUserDefaults standardUserDefaults] objectForKey:TWVAutomaticReloadIntervalKey] intValue];
		automaticReloadTimer = [[NSTimer scheduledTimerWithTimeInterval:reloadInterval
																 target:self
															   selector:@selector(reloadWebView:)
															   userInfo:nil
																repeats:YES] retain];
	}
}


- (void)reloadWebView:(NSTimer *)timer {
	// Reload the web view
	NSLog(@"Reload the web view");
	[self.theWebView reload:self];
}


#pragma mark -
#pragma mark Borderless Window

- (BOOL)_borderlessState {
  return [[NSUserDefaults standardUserDefaults] boolForKey:TWVBorderlessWindowKey];
}

- (IBAction)toggleBorderlessWindow:(id)sender {
	// Toggle the borderless Window state:
  BOOL borderless = ![self _borderlessState];
	
	// Set the MenuItemState
	[self setBorderlessWindowMenuItemState:borderless];
	
	// Save the borderless Window state in the Preferences
	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:borderless]
                                            forKey:TWVBorderlessWindowKey];
	
	[self replaceWindowWithBorderlessWindow:borderless];
}


/*
 * Methods sets the UI properties according to the state of the Borderless Window
 */
- (void)setBorderlessWindowMenuItemState:(BOOL)booleanState {
	
	if (booleanState) {
		// YES BorderlessWindow
		NSLog(@"Set borderless!");
		[borderlessWindowMenuItem setTitle:@"Show Title Bar"];
	} else {
		// NO BorderlessWindow
		NSLog(@"Set NOT borderless!");
		[borderlessWindowMenuItem setTitle:@"Hide Title Bar"];
	}
}
	
- (void)replaceWindowWithBorderlessWindow:(BOOL)borderlessFlag {

	// Save the previous frame (to file and to string)
	[self.window saveFrameUsingName:TWVMainTransparantWindowFrameKey];
	NSString *savedFrameString = [self.window stringWithSavedFrame];
	
	// Get a pointer to the old window
	NSWindow *oldWindow = self.window;
	
  if (self.borderlessWindow == nil) {
    self.borderlessWindow = [[WebViewWindow alloc] initWithContentRect:oldWindow.frame
                                                         styleMask:NSBorderlessWindowMask
                                                           backing:NSBackingStoreBuffered
                                                             defer:NO];
  }
  self.window = borderlessFlag ? self.borderlessWindow : self.borderedWindow;
  
  [oldWindow orderOut:nil];
  
  self.window.contentView = oldWindow.contentView;
  self.window.frameAutosaveName = TWVMainTransparantWindowFrameKey;
  [self.window setFrameFromString:savedFrameString];
  
  CGRect newFrame = oldWindow.frame;
  if (borderlessFlag) {
//    newFrame.origin.y -= 2*kToolbarHeight;
    newFrame.size.height -= kToolbarHeight;
  } else {
//    newFrame.origin.y += 2*kToolbarHeight;
    newFrame.size.height += kToolbarHeight;
  }
  [self.window setFrame:newFrame display:YES];
  
  self.window.delegate = self;
  
  // Call the same window as awakeFromNib would have
  [(WebViewWindow *)window setDrawsBackgroundSettings];
  
  [self.window makeKeyAndOrderFront:self.window];
}

#pragma mark - Floating window

- (BOOL)_isWindowFloating {
  return [[NSUserDefaults standardUserDefaults] boolForKey:TWVWindowFloatingKey];
}
- (IBAction)toogleFloating:(id)sender {
  BOOL floating = ![self _isWindowFloating];
  [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:floating] forKey:TWVWindowFloatingKey];
  [self _setFloatingState:floating];
}

- (void)_setFloatingState:(BOOL)floating {
  self.borderedWindow.level = floating ? NSStatusWindowLevel : NSNormalWindowLevel;
  self.borderlessWindow.level = floating ? NSStatusWindowLevel : NSNormalWindowLevel;
  self.borderedWindow.hasShadow = !floating;
  self.borderlessWindow.hasShadow = !floating;
  [_floatingToolbarButton setState:floating ? NSOnState : NSOffState];
  [_floatingToolbarButton setTitle:floating ? @"Floating" : @"Float"];
  [_floatingToolbarButton setImage:[NSImage imageNamed:floating ? @"FloatingWindowTemplate" : @"RegularWindowTemplate"]];
}

#pragma mark - Opacity

- (void)handleOpacityChange:(NSNotification *)notification {
  double opacity = [self _opacity];
  [self _setWebViewOpacity:opacity];
  [self _setOpacityMenuItemsEnabledForOpacity:opacity];
}

- (double)_opacity {
  double opacity = [[NSUserDefaults standardUserDefaults] doubleForKey:TWVOpacityKey];
  return opacity;
}

- (void)_setWebViewOpacity:(double)opacity {
  // Set window alpha because hardware accelerated views in the webview won't follow it's alphaValue :(
  self.borderlessWindow.alphaValue = (float)opacity;
  self.borderedWindow.alphaValue = (float)opacity;
}

- (void)_setOpacityMenuItemsEnabledForOpacity:(double)opacity {
  _decreaseOpacityMenuItem.enabled = opacity > 0.0;
  _increaseOpacityMenuItem.enabled = opacity < 1.0;
}

- (void)_setOpacityPreference:(double)opacity {
  if (preferenceController != nil) {
    [preferenceController setOpacityValue:opacity setPreference:YES];
    return;
  }
  
  // Set the value in the Defaults
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults setObject:[NSNumber numberWithDouble:opacity] forKey:TWVOpacityKey];
  [defaults synchronize];
  
  // Send a notification
  [[NSNotificationCenter defaultCenter] postNotificationName:TWVOpacityChangedNotification object:self];
}

- (IBAction)increaseOpacity:(id)sender {
  double opacity = MIN([self _opacity] + kOpacityInterval, 1.0);
  [self _setOpacityPreference:opacity];
}

- (IBAction)decreaseOpacity:(id)sender {
  double opacity = MAX([self _opacity] - kOpacityInterval, 0.0);
  [self _setOpacityPreference:opacity];
}


#pragma mark -
#pragma mark NSWindow Delegate Methods

- (void)windowDidResize:(NSNotification *)notification {
	// Save the frame (since it wasn't working out of the box on our own created windows)
	[window saveFrameUsingName:TWVMainTransparantWindowFrameKey];

}

- (void)windowDidMove:(NSNotification *)notification {
	// Save the frame (since it wasn't working out of the box on our own created windows)
	[window saveFrameUsingName:TWVMainTransparantWindowFrameKey];
}

#pragma mark -

- (void)dealloc {
	[urlString release];
	[preferenceController release];
	[automaticReloadTimer invalidate];
	[automaticReloadTimer release];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

@end
