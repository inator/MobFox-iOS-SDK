//
//  MobFoxBannerView.m
//
//  Created by Oliver Drobnik on 9/24/10.
//  Copyright 2010 Drobnik.com. All rights reserved.
//  Modified by Michael Kaye sendmetospace.co.uk

#import "MobFoxBannerView.h"
#import "NSString+MobFox.h"
#import "DTXMLDocument.h"
#import "DTXMLElement.h"
#import "UIView+FindViewController.h"
#import "NSURL+MobFox.h"
#import "MobFoxAdBrowserViewController.h"
#import "RedirectChecker.h"
#import "UIDevice+IdentifierAddition.h"
#include "OpenUDID.h"

NSString * const MobFoxErrorDomain = @"MobFox";


@interface MobFoxBannerView () // private

- (void)requestAd;

@end




@implementation MobFoxBannerView
{
	RedirectChecker *redirectChecker;
}

- (void)setup
{
	self.autoresizingMask = UIViewAutoresizingNone;
	self.backgroundColor = [UIColor clearColor];
	
	refreshAnimation = UIViewAnimationTransitionFlipFromLeft;
	
	// need notification to activate/deactivate timer
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
}

- (id)initWithFrame:(CGRect)frame 
{
    if ((self = [super initWithFrame:frame])) 
	{
		[self setup];
    }
    return self;
}

- (void)awakeFromNib
{
	[self setup];
}

- (void)dealloc 
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	delegate = nil;
	
	[_refreshTimer invalidate], _refreshTimer = nil;
}

#pragma mark Utilities

- (NSString *)userAgent
{
	NSString *device = [UIDevice currentDevice].model;
	NSString *agent = @"MobFox";
	
	return [NSString stringWithFormat:@"%@/%@ (%@)", agent, SDK_VERSION, device];
}

- (UIImage*)darkeningImageOfSize:(CGSize)size
{
	UIGraphicsBeginImageContext(size);
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	
	CGContextSetGrayFillColor(ctx, 0, 1);
	CGContextFillRect(ctx, CGRectMake(0, 0, size.width, size.height));
	
	UIImage *cropped = UIGraphicsGetImageFromCurrentImageContext();
	
	//pop the context to get back to the default
	UIGraphicsEndImageContext();
	
	//Note: this is autoreleased
	return cropped;
}

- (NSURL *)serverURL
{
	return [NSURL URLWithString:@"http://my.mobfox.com/request.php"];
}

#pragma mark Properties
- (void)setBounds:(CGRect)bounds
{
	[super setBounds:bounds];
	
	for (UIView *oneView in self.subviews)
	{
		oneView.center = CGPointMake(roundf(self.bounds.size.width / 2.0), roundf(self.bounds.size.height / 2.0));
	}
}

- (void)setTransform:(CGAffineTransform)transform
{
	[super setTransform:transform];
	
	for (UIView *oneView in self.subviews)
	{
		oneView.center = CGPointMake(roundf(self.bounds.size.width / 2.0), roundf(self.bounds.size.height / 2.0));
	}
}

- (void)setDelegate:(id <MobFoxBannerViewDelegate>)newDelegate
{
	if (newDelegate != delegate)
	{
		delegate = newDelegate;
		
		if (delegate)
		{
			[self requestAd];
		}
	}
}

- (void)setRefreshTimerActive:(BOOL)active
{
	BOOL currentlyActive = (_refreshTimer!=nil);
	
	if (active == currentlyActive)
	{
		return;
	}
	
	if (active && !bannerViewActionInProgress)
	{
		if (_refreshInterval)
		{
			_refreshTimer = [NSTimer scheduledTimerWithTimeInterval:_refreshInterval target:self selector:@selector(requestAd) userInfo:nil repeats:YES];
		}
	}
	else 
	{
		[_refreshTimer invalidate], _refreshTimer = nil;
	}
}

- (void)hideStatusBar
{
	UIApplication *app = [UIApplication sharedApplication];
	
	if (!app.statusBarHidden)
	{
		if ([app respondsToSelector:@selector(setStatusBarHidden:withAnimation:)])
		{
			// >= 3.2
			[app setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
		}
		else 
		{
			// < 3.2
			[app setStatusBarHidden:YES];
		}
		
		_statusBarWasVisible = YES;
	}
}

- (void)showStatusBarIfNecessary
{
	if (_statusBarWasVisible)
	{
		UIApplication *app = [UIApplication sharedApplication];
		
		if ([app respondsToSelector:@selector(setStatusBarHidden:withAnimation:)])
		{
			// >= 3.2
			[app setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
		}
		else 
		{
			// < 3.2
			[app setStatusBarHidden:NO];
		}
	}
}

#pragma mark Ad Handling
- (void)reportSuccess
{
	bannerLoaded = YES;
	
	if ([delegate respondsToSelector:@selector(mobfoxBannerViewDidLoadMobFoxAd:)])
	{
		[delegate mobfoxBannerViewDidLoadMobFoxAd:self];
	}
}

- (void)reportError:(NSError *)error
{
	bannerLoaded = NO;
	
	if ([delegate respondsToSelector:@selector(mobfoxBannerView:didFailToReceiveAdWithError:)])
	{
		[delegate mobfoxBannerView:self didFailToReceiveAdWithError:error];
	}
}

- (void)setupAdFromXml:(DTXMLDocument *)xml
{
	
	if ([xml.documentRoot.name isEqualToString:@"error"])
	{
		NSString *errorMsg = xml.documentRoot.text;
		
		NSDictionary *userInfo = [NSDictionary dictionaryWithObject:errorMsg forKey:NSLocalizedDescriptionKey];
		
		NSError *error = [NSError errorWithDomain:MobFoxErrorDomain code:MobFoxErrorUnknown userInfo:userInfo];
		[self performSelectorOnMainThread:@selector(reportError:) withObject:error waitUntilDone:YES];
		return;	
	}
	
	
	// previous views will be removed if setup works
	NSArray *previousSubviews = [NSArray arrayWithArray:self.subviews];
	
	NSString *clickType = [xml.documentRoot getNamedChild:@"clicktype"].text;
	
	if ([clickType isEqualToString:@"inapp"])
	{
		_tapThroughLeavesApp = NO;
	}
	else
	{
		_tapThroughLeavesApp = YES;
	}
	
	NSString *clickUrlString = [xml.documentRoot getNamedChild:@"clickurl"].text;
	if ([clickUrlString length])
	{
		_tapThroughURL = [NSURL URLWithString:clickUrlString];
	}
	
	_shouldScaleWebView = [[xml.documentRoot getNamedChild:@"scale"].text isEqualToString:@"yes"];
	
	_shouldSkipLinkPreflight = [[xml.documentRoot getNamedChild:@"skippreflight"].text isEqualToString:@"yes"];
	
	UIView *newAdView = nil;
	
	NSString *adType = [xml.documentRoot.attributes objectForKey:@"type"];
	
	if ([adType isEqualToString:@"imageAd"]) 
	{
		if (!_bannerImage)
		{
			NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Error loading banner image" forKey:NSLocalizedDescriptionKey];
			
			NSError *error = [NSError errorWithDomain:MobFoxErrorDomain code:MobFoxErrorUnknown userInfo:userInfo];
			[self performSelectorOnMainThread:@selector(reportError:) withObject:error waitUntilDone:YES];
			return;
		}
		
		CGFloat bannerWidth = [[xml.documentRoot getNamedChild:@"bannerwidth"].text floatValue];
		CGFloat bannerHeight = [[xml.documentRoot getNamedChild:@"bannerheight"].text floatValue];
		
		UIButton *button=[UIButton buttonWithType:UIButtonTypeCustom];
		[button setFrame:CGRectMake(0, 0, bannerWidth, bannerHeight)];
		[button addTarget:self action:@selector(tapThrough:) forControlEvents:UIControlEventTouchUpInside];
		
		[button setImage:_bannerImage forState:UIControlStateNormal];
		button.center = CGPointMake(roundf(self.bounds.size.width / 2.0), roundf(self.bounds.size.height / 2.0));
		//		button.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
		
		newAdView = button;
	}
	else if ([adType isEqualToString:@"textAd"]) 
	{
		NSString *html = [xml.documentRoot getNamedChild:@"htmlString"].text;
		
		CGSize bannerSize = CGSizeMake(320, 50);
		if (UI_USER_INTERFACE_IDIOM()==UIUserInterfaceIdiomPad)
		{
			bannerSize = CGSizeMake(728, 90);
		}
		
		UIWebView *webView=[[UIWebView alloc]initWithFrame:CGRectMake(0, 0, bannerSize.width, bannerSize.height)];
		webView.delegate = (id)self;
		webView.userInteractionEnabled = NO;
		
		[webView loadHTMLString:html baseURL:nil];
		
		
		// add an invisible button for the whole area
		UIImage *grayingImage = [self darkeningImageOfSize:bannerSize];
		
		UIButton *button=[UIButton buttonWithType:UIButtonTypeCustom];
		[button setFrame:webView.bounds];
		[button addTarget:self action:@selector(tapThrough:) forControlEvents:UIControlEventTouchUpInside];
		[button setImage:grayingImage forState:UIControlStateHighlighted];
		button.alpha = 0.47;
		
		button.center = CGPointMake(roundf(self.bounds.size.width / 2.0), roundf(self.bounds.size.height / 2.0));
		//		button.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
		
		[self addSubview:button];

		// we want the webview to be translucent so that we see the developer's custom background
		webView.backgroundColor = [UIColor clearColor];
		webView.opaque = NO;
		
		newAdView = webView;
	} 
	else if ([adType isEqualToString:@"noAd"]) 
	{
		NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"No inventory for ad request" forKey:NSLocalizedDescriptionKey];
		
		NSError *error = [NSError errorWithDomain:MobFoxErrorDomain code:MobFoxErrorInventoryUnavailable userInfo:userInfo];
		[self performSelectorOnMainThread:@selector(reportError:) withObject:error waitUntilDone:YES];
	}
	else if ([adType isEqualToString:@"error"])
	{
		NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Unknown error" forKey:NSLocalizedDescriptionKey];
		
		NSError *error = [NSError errorWithDomain:MobFoxErrorDomain code:MobFoxErrorUnknown userInfo:userInfo];
		[self performSelectorOnMainThread:@selector(reportError:) withObject:error waitUntilDone:YES];
		return;
	}
	else 
	{
		NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"Unknown ad type '%@'", adType] forKey:NSLocalizedDescriptionKey];
		
		NSError *error = [NSError errorWithDomain:MobFoxErrorDomain code:MobFoxErrorUnknown userInfo:userInfo];
		[self performSelectorOnMainThread:@selector(reportError:) withObject:error waitUntilDone:YES];
		return;
	}
	
	if (newAdView)
	{
		if (CGRectEqualToRect(self.bounds, CGRectZero))
		{
			self.bounds = newAdView.bounds;
		}
		
		// animate if there was a previous ad
		
		if ([previousSubviews count])
		{
			[UIView beginAnimations:@"flip" context:nil];
			[UIView setAnimationDuration:1.5];
			[UIView setAnimationTransition:refreshAnimation forView:self cache:NO];
		}
		
		[self insertSubview:newAdView atIndex:0]; // goes below button
		[previousSubviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
		
		if ([previousSubviews count])
		{
			[UIView commitAnimations];
		}
		else 
		{
			// only inform delegate if its not a refresh
			[self performSelectorOnMainThread:@selector(reportSuccess) withObject:nil waitUntilDone:YES];
		}
	}		
	
	// start new timer
	_refreshInterval = [[xml.documentRoot getNamedChild:@"refresh"].text intValue];
	[self setRefreshTimerActive:YES];
}

- (void)asyncRequestAdWithPublisherId:(NSString *)publisherId
{
	@autoreleasepool 
	{
	NSString *requestType;
	if (UI_USER_INTERFACE_IDIOM()==UIUserInterfaceIdiomPhone)
	{
		requestType = @"iphone_app";
	}
	else
	{
		requestType = @"ipad_app";
	}
	
	NSString *userAgent=[self userAgent];
	NSString *m=@"live";
	NSString *osVersion = [UIDevice currentDevice].systemVersion;
	
    NSString *MD5MacAddress = [[UIDevice currentDevice] uniqueGlobalDeviceIdentifier];
    NSString *SHA1MacAddress = [[UIDevice currentDevice] uniqueGlobalDeviceIdentifierSHA1];
    
    NSString* openUDID = [OpenUDID value];
	
    NSString *requestString=[NSString stringWithFormat:@"rt=%@&u=%@&o_mcmd5=%@&o_mcsha1=%@&v=%@&m=%@&s=%@&o_openudid=%@&iphone_osversion=%@&spot_id=%@",
                             [requestType stringByUrlEncoding],
                             [[self userAgent] stringByUrlEncoding],
                             [MD5MacAddress stringByUrlEncoding], // o_mcmd5
                             [SHA1MacAddress stringByUrlEncoding], // o_mcsha1
                             [openUDID stringByUrlEncoding], // o_openudid
                             [SDK_VERSION stringByUrlEncoding],
                             [m stringByUrlEncoding],
                             [publisherId stringByUrlEncoding],
                             [osVersion stringByUrlEncoding],
                             [advertisingSection?advertisingSection:@"" stringByUrlEncoding]];
	
	NSURL *serverURL = [self serverURL];
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@?%@", serverURL, requestString]];
	
	NSMutableURLRequest *request;
	NSError *error;
    NSURLResponse *response;
    NSData *dataReply;
	
    request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod: @"GET"];
    [request setValue:@"text/xml" forHTTPHeaderField:@"Accept"];
	[request setValue:userAgent forHTTPHeaderField:@"User-Agent"];
	
	dataReply = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
	
	DTXMLDocument *xml = [DTXMLDocument documentWithData:dataReply];
	
	if (!xml)
	{		
		NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Error parsing xml response from server" forKey:NSLocalizedDescriptionKey];
		
		NSError *error = [NSError errorWithDomain:MobFoxErrorDomain code:MobFoxErrorUnknown userInfo:userInfo];
		[self performSelectorOnMainThread:@selector(reportError:) withObject:error waitUntilDone:YES];
		return;
	}
	
	// also load banner image in background
	NSString *bannerUrlString = [xml.documentRoot getNamedChild:@"imageurl"].text;
	
	if ([bannerUrlString length])
	{
		NSURL *bannerUrl = [NSURL URLWithString:bannerUrlString];
		_bannerImage = [[UIImage alloc]initWithData:[NSData dataWithContentsOfURL:bannerUrl]];
	}
	
	// rest of setup on main thread to prevent weird image loading effect
	
	[self performSelectorOnMainThread:@selector(setupAdFromXml:) withObject:xml waitUntilDone:YES];
	
	}

}

- (void)showErrorLabelWithText:(NSString *)text
{
	UILabel *label = [[UILabel alloc] initWithFrame:self.bounds];
	label.numberOfLines = 0;
	label.backgroundColor = [UIColor whiteColor];
	label.font = [UIFont boldSystemFontOfSize:12];
	label.textAlignment = UITextAlignmentCenter;
	label.textColor = [UIColor redColor];
	label.shadowOffset = CGSizeMake(0, 1);
	label.shadowColor = [UIColor blackColor];
	
	label.text = text;
	
	[self addSubview:label];
}

- (void)requestAd
{
	if (!delegate)
	{
		[self showErrorLabelWithText:@"MobFoxBannerViewDelegate not set"];
		
		return;
	}
	
	if (![delegate respondsToSelector:@selector(publisherIdForMobFoxBannerView:)])
	{
		[self showErrorLabelWithText:@"MobFoxBannerViewDelegate does not implement publisherIdForMobFoxBannerView:"];
		
		return;
	}	
	
	
	NSString *publisherId = [delegate publisherIdForMobFoxBannerView:self];
	
	if (![publisherId length])
	{
		[self showErrorLabelWithText:@"MobFoxBannerViewDelegate returned invalid publisher ID."];
		
		return;
	}
	
	[self performSelectorInBackground:@selector(asyncRequestAdWithPublisherId:) withObject:publisherId];
}

#pragma mark Interaction

- (void)checker:(RedirectChecker *)checker detectedRedirectionTo:(NSURL *)redirectURL
{
	if ([redirectURL isDeviceSupported])
	{
		[[UIApplication sharedApplication] openURL:redirectURL];
		return;
	}
	
	UIViewController *viewController = [self firstAvailableUIViewController];
	
	MobFoxAdBrowserViewController *browser = [[MobFoxAdBrowserViewController alloc] initWithUrl:redirectURL];
	browser.delegate = (id)self;
	browser.userAgent = [self userAgent];
	browser.webView.scalesPageToFit = _shouldScaleWebView;
	
	[self hideStatusBar];
	[viewController presentModalViewController:browser animated:YES];
	
	bannerViewActionInProgress = YES;
}

- (void)checker:(RedirectChecker *)checker didFinishWithData:(NSData *)data
{
	UIViewController *viewController = [self firstAvailableUIViewController];
	
	MobFoxAdBrowserViewController *browser = [[MobFoxAdBrowserViewController alloc] initWithUrl:nil];
	browser.delegate = (id)self;
	browser.userAgent = [self userAgent];
	browser.webView.scalesPageToFit = _shouldScaleWebView;
	
	NSString *scheme = [_tapThroughURL scheme];
	NSString *host = [_tapThroughURL host];
	NSString *path = [[_tapThroughURL path] stringByDeletingLastPathComponent];
	
	NSURL *baseURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@://%@%@/", scheme, host, path]];
	
	
	[browser.webView loadData:data MIMEType:checker.mimeType textEncodingName:checker.textEncodingName baseURL:baseURL];
	
	[self hideStatusBar];
	[viewController presentModalViewController:browser animated:YES];
	
	bannerViewActionInProgress = YES;
}

- (void)checker:(RedirectChecker *)checker didFailWithError:(NSError *)error
{
	bannerViewActionInProgress = NO;
}

- (void)tapThrough:(id)sender
{
	if ([delegate respondsToSelector:@selector(mobfoxBannerViewActionShouldBegin:willLeaveApplication:)])
	{
		BOOL allowAd = [delegate mobfoxBannerViewActionShouldBegin:self willLeaveApplication:_tapThroughLeavesApp];
		
		if (!allowAd)
		{
			return;
		}
	}
	
	if (_tapThroughLeavesApp || [_tapThroughURL isDeviceSupported])
	{
		[[UIApplication sharedApplication]openURL:_tapThroughURL];
		return; // if the URL was valid then we have left the app or sent it to the background
	}
	
	UIViewController *viewController = [self firstAvailableUIViewController];
	
	if (!viewController)
	{
		NSLog(@"Unable to find view controller for presenting modal ad browser");
		return;
	}
	
	[self setRefreshTimerActive:NO];
	
	// probes the URL (= record clickthrough) and acts based on the response
	
	if (!_shouldSkipLinkPreflight)
	{
		redirectChecker = [[RedirectChecker alloc] initWithURL:_tapThroughURL userAgent:[self userAgent] delegate:(id)self];
		return;
	}
	
	MobFoxAdBrowserViewController *browser = [[MobFoxAdBrowserViewController alloc] initWithUrl:_tapThroughURL];
	browser.delegate = (id)self;
	browser.userAgent = [self userAgent];
	browser.webView.scalesPageToFit = _shouldScaleWebView;
	
	[self hideStatusBar];
	[viewController presentModalViewController:browser animated:YES];
	
	bannerViewActionInProgress = YES;
}

- (void)mobfoxAdBrowserControllerDidDismiss:(MobFoxAdBrowserViewController *)mobfoxAdBrowserController
{
	[self showStatusBarIfNecessary];
	[mobfoxAdBrowserController dismissModalViewControllerAnimated:YES];
	
	bannerViewActionInProgress = NO;
	[self setRefreshTimerActive:YES];
	
	if ([delegate respondsToSelector:@selector(mobfoxBannerViewActionDidFinish:)])
	{
		[delegate mobfoxBannerViewActionDidFinish:self];
	}
}

#pragma mark WebView Delegate (Text Ads)

// obsolete, because there is full size transparent button over it
/*
 - (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
 {
 if (navigationType == UIWebViewNavigationTypeLinkClicked)
 {
 _tapThroughURL = [[request URL] retain];
 
 [self tapThrough:nil];
 
 return NO;
 }
 
 return YES;
 }
 */


#pragma mark Notifications
- (void) appDidBecomeActive:(NSNotification *)notification
{
	[self setRefreshTimerActive:YES];
}

- (void) appWillResignActive:(NSNotification *)notification
{
	[self setRefreshTimerActive:NO];
}



@synthesize delegate;
@synthesize advertisingSection;
@synthesize bannerLoaded;
@synthesize bannerViewActionInProgress;
@synthesize refreshAnimation;


@end

