//
//  RedirectChecker.m
//  BannerDemo
//
//  Created by Oliver Drobnik on 9/25/10.
//  Copyright 2010 Drobnik.com. All rights reserved.
//

#import "RedirectChecker.h"


@implementation RedirectChecker

@synthesize delegate = _delegate;
@synthesize mimeType;
@synthesize textEncodingName;

- (id)initWithURL:(NSURL *)url userAgent:(NSString *)userAgent delegate:(id<RedirectCheckerDelegate>) delegate
{
	if (self = [super init])
	{
		_delegate = delegate;
		
		NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
		[request addValue:userAgent forHTTPHeaderField:@"User-Agent"];
		
		_connection=[[NSURLConnection alloc] initWithRequest:request delegate:self];
		
		receivedData = [[NSMutableData alloc] init];
		[_connection start];
		[self retain];
	}
	
	return self;
}



- (void)dealloc 
{
	[_connection release];
	[receivedData release];
	[mimeType release];
	[textEncodingName release];
    [super dealloc];
}

- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse
{
	if (redirectResponse)
	{
		[_delegate checker:self detectedRedirectionTo:[request URL]];
		
		[_connection cancel];

		[self release];

		return nil;
	}
	
	return request;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	self.mimeType = [response MIMEType];
	self.textEncodingName = [response textEncodingName];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	[receivedData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	[_delegate checker:self didFinishWithData:receivedData];
	[self release];
	
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error;
{
	if ([_delegate respondsToSelector:@selector(checker:didFailWithError:)])
	{
		[_delegate checker:self didFailWithError:error];
	}
	
	[self release];
}

@end
