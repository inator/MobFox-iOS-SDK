//
//  MobFoxBannerView.h
//
//  Created by Oliver Drobnik on 9/24/10.
//  Copyright 2010 Drobnik.com. All rights reserved.
//

#import <UIKit/UIKit.h>

enum {
    MobFoxErrorUnknown = 0,
    MobFoxErrorServerFailure = 1,
    MobFoxErrorInventoryUnavailable = 2,
};

@class MobFoxBannerView;

@protocol MobFoxBannerViewDelegate <NSObject>

- (NSString *)publisherIdForMobFoxBannerView:(MobFoxBannerView *)banner;

@optional

// called if an ad has been successfully retrieved
- (void)mobfoxBannerViewDidLoadMobFoxAd:(MobFoxBannerView *)banner;

// called if no banner is available or there is an error
- (void)mobfoxBannerView:(MobFoxBannerView *)banner didFailToReceiveAdWithError:(NSError *)error;

// called when user taps on a banner
- (BOOL)mobfoxBannerViewActionShouldBegin:(MobFoxBannerView *)banner willLeaveApplication:(BOOL)willLeave;

// called when the modal web view is cancelled and the user is returning to your app
- (void)mobfoxBannerViewActionDidFinish:(MobFoxBannerView *)banner;

@end




@interface MobFoxBannerView : UIView 
{
	NSString *advertisingSection;  // formerly know as "spot"
	BOOL bannerLoaded;
	BOOL bannerViewActionInProgress;
	UIViewAnimationTransition refreshAnimation;
	
	__unsafe_unretained id <MobFoxBannerViewDelegate> delegate;
	
	// internals
	UIImage *_bannerImage;
	BOOL _tapThroughLeavesApp;
	BOOL _shouldScaleWebView;
	BOOL _shouldSkipLinkPreflight;
	BOOL _statusBarWasVisible;
	NSURL *_tapThroughURL;
	NSInteger _refreshInterval;
	
	NSTimer *_refreshTimer;
}

@property(nonatomic, assign) IBOutlet __unsafe_unretained id <MobFoxBannerViewDelegate> delegate;
@property(nonatomic, copy) NSString *advertisingSection;
@property(nonatomic, assign) UIViewAnimationTransition refreshAnimation;


@property(nonatomic, readonly, getter=isBannerLoaded) BOOL bannerLoaded;
@property(nonatomic, readonly, getter=isBannerViewActionInProgress) BOOL bannerViewActionInProgress;

@end

extern NSString * const MobFoxErrorDomain;