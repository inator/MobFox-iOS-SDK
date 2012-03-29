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
	
    float buttonSize;
    
	__unsafe_unretained id <MobFoxAdBrowserViewController> delegate;
}

@property (nonatomic, strong) NSString *userAgent;
@property (nonatomic, readonly, strong) NSURL  *url;

@property (nonatomic, strong) UIWebView *webView;

@property (nonatomic, assign) __unsafe_unretained id <MobFoxAdBrowserViewController> delegate;

- (id)initWithUrl:(NSURL *)url;
//- (id)initWithHTML:(NSString *)html baseURL:(NSURL *)url

@end
