//
//  MobFoxAdBrowserViewController.h
//
//  Created by Oliver Drobnik on 9/24/10.
//  Copyright 2010 Drobnik.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MobFoxAdBrowserViewController;

@protocol MobFoxAdBrowserViewController <NSObject>

- (void)mobfoxAdBrowserControllerDidDismiss:(MobFoxAdBrowserViewController *)mobfoxAdBrowserController;

@end



@interface MobFoxAdBrowserViewController : UIViewController <UIWebViewDelegate>
{
	UIWebView *_webView;
	NSURL *_url;
	
	// manual loading
	NSString *userAgent;
	NSString *mimeType;
	NSString *textEncodingName;
	NSMutableData *receivedData;
	
	id <MobFoxAdBrowserViewController> delegate;
}

@property (nonatomic, retain) NSString *userAgent;
@property (nonatomic, readonly, retain) NSURL  *url;

@property (nonatomic, retain) UIWebView *webView;

@property (nonatomic, assign) id <MobFoxAdBrowserViewController> delegate;

- (id)initWithUrl:(NSURL *)url;
//- (id)initWithHTML:(NSString *)html baseURL:(NSURL *)url

@end
