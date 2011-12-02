//
//  DTXMLDocument.m
//  iCatalog
//
//  Created by Oliver Drobnik on 8/23/10.
//  Copyright 2010 Drobnik.com. All rights reserved.
//

#import "DTXMLDocument.h"
#import "DTXMLElement.h"

@implementation DTXMLDocument


#pragma mark Factory Methods
+ (DTXMLDocument *) documentWithData:(NSData *)data
{
	return [[[DTXMLDocument alloc] initWithData:data] autorelease];
}

+ (DTXMLDocument *) documentWithContentsOfFile:(NSString *)path
{
	return [[[DTXMLDocument alloc] initWithContentsOfFile:path] autorelease];
}

+ (DTXMLDocument *) documentWithContentsOfFile:(NSString *)path delegate:(id<DTXMLDocumentDelegate>)delegate
{
	return [[[DTXMLDocument alloc] initWithContentsOfFile:path delegate:delegate] autorelease];
}

+ (DTXMLDocument *) documentWithContentsOfURL:(NSURL *)url delegate:(id<DTXMLDocumentDelegate>)delegate
{
	return [[[DTXMLDocument alloc] initWithContentsOfURL:url delegate:delegate] autorelease];
}



#pragma mark Initializer
// designated initializer	
- (id) init
{
	if (self = [super init])
	{
	}
	
	return self;
}

- (id) initWithData:(NSData *)data
{
	if (self = [super init])
	{
		// create parser
		NSXMLParser *parser = [[[NSXMLParser alloc] initWithData:data] autorelease];	
		[parser setShouldProcessNamespaces: YES];
		[parser setShouldReportNamespacePrefixes:YES];
		[parser setShouldResolveExternalEntities:NO];
		[parser setDelegate:(id)self];
		
		if ([parser parse])
		{
			if ([_delegate respondsToSelector:@selector(didFinishLoadingXmlDocument:)])
			{
				[_delegate didFinishLoadingXmlDocument:self];
			}
		}
		else 
		{
			[self release];
			return nil;
		}
	}
	
	return self;
}
		
		

- (id) initWithContentsOfFile:(NSString *)path
{
	if (self = [super init])
	{
		// make a file path out of the parameter
		NSURL *fileURL = [NSURL fileURLWithPath:path]; 
		
		// create parser
		NSXMLParser *parser = [[[NSXMLParser alloc] initWithContentsOfURL:fileURL] autorelease];	
		[parser setShouldProcessNamespaces: YES];
		[parser setShouldReportNamespacePrefixes:YES];
		[parser setShouldResolveExternalEntities:NO];
		[parser setDelegate:(id)self];
		
		if ([parser parse])
		{
			if ([_delegate respondsToSelector:@selector(didFinishLoadingXmlDocument:)])
			{
				[_delegate didFinishLoadingXmlDocument:self];
			}
		}
	}
	
	return self;
}

- (id) initWithContentsOfFile:(NSString *)path delegate:(id<DTXMLDocumentDelegate>)delegate
{
	if (self = [super init])
	{
		self.delegate = delegate;
		
		// make a file path out of the parameter
		NSURL *fileURL = [NSURL fileURLWithPath:path]; 
		
		// create parser
		NSXMLParser *parser = [[[NSXMLParser alloc] initWithContentsOfURL:fileURL] autorelease];	
		[parser setShouldProcessNamespaces: YES];
		[parser setShouldReportNamespacePrefixes:YES];
		[parser setShouldResolveExternalEntities:NO];
		[parser setDelegate:(id)self];
		
		if ([parser parse])
		{
			if ([_delegate respondsToSelector:@selector(didFinishLoadingXmlDocument:)])
			{
				[_delegate didFinishLoadingXmlDocument:self];
			}
		}
	}
	
	return self;
}

- (id) initWithContentsOfURL:(NSURL *)url delegate:(id<DTXMLDocumentDelegate>)xmlDelegate
{
	if (self = [super init])
	{
		self.delegate = xmlDelegate;
		
		NSURLRequest *request=[NSURLRequest requestWithURL:url
											   cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
										   timeoutInterval:60.0];
		
		theConnection=[[NSURLConnection alloc] initWithRequest:request delegate:self];
		
		if (theConnection) 
		{
			receivedData=[[NSMutableData data] retain];
		}
	}
	
	return self;
}


- (void) dealloc
{
	[_url release];

	[theConnection release];
	[documentRoot release];
	
	[receivedData release];
	
	[super dealloc];
}



#pragma mark Parser Protocol

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{	
	DTXMLElement *newElement = [[DTXMLElement alloc] initWithName:elementName];
	newElement.attributes = [NSMutableDictionary dictionaryWithDictionary:attributeDict];
	
	// if we don't have a root element yet, this is it
	if (!currentElement)
	{
		self.documentRoot = newElement;
		currentElement = documentRoot;
	}
	else
	{
		[currentElement.children addObject:newElement];
		newElement.parent = currentElement;
	}
		
	currentElement = newElement;
	[newElement release];  // still retained as documentRoot or a child
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
	[currentElement.text appendString:string];
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
	currentElement = currentElement.parent;
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError
{
	doneLoading = YES;
	
	if ([_delegate respondsToSelector:@selector(xmlDocument:didFailWithError:)])
	{
		[_delegate xmlDocument:self didFailWithError:parseError];
	}
}

- (void)parser:(NSXMLParser *)parser validationErrorOccurred:(NSError *)validationError
{
	doneLoading = YES;
	
	if ([_delegate respondsToSelector:@selector(xmlDocument:didFailWithError:)])
	{
		[_delegate xmlDocument:self didFailWithError:validationError];
	}
}


#pragma mark URL Loading
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	// could be redirections, so we set the Length to 0 every time
	[receivedData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	[receivedData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	[receivedData release];
	receivedData = nil;
	
	
	doneLoading = YES;
	
	if ([_delegate respondsToSelector:@selector(xmlDocument:didFailWithError:)])
	{
		[_delegate xmlDocument:self didFailWithError:error];
	}
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	NSXMLParser *parser = [[[NSXMLParser alloc] initWithData:receivedData] autorelease];	
	[receivedData release];	
	receivedData = nil;
	
	[parser setShouldProcessNamespaces: YES];
	[parser setShouldReportNamespacePrefixes:YES];
	[parser setShouldResolveExternalEntities:NO];
	[parser setDelegate:(id)self];
	
	doneLoading = YES;
	
	if ([parser parse])
	{
		
		if ([_delegate respondsToSelector:@selector(didFinishLoadingXmlDocument:)])
		{
			[_delegate  didFinishLoadingXmlDocument:self];
		}
	}
	
}


-(void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
	if ([challenge previousFailureCount] == 0) 
	{
		NSURLCredential *newCredential;
		
		if ([_delegate respondsToSelector:@selector(userCredentialForAuthenticationChallenge:)])
		{
			newCredential = [_delegate userCredentialForAuthenticationChallenge:challenge];
			
			if (newCredential)
			{
				[[challenge sender] useCredential:newCredential forAuthenticationChallenge:challenge];
			}
			else
			{
				[[challenge sender] cancelAuthenticationChallenge:challenge];
			}
			
		}
		else 
		{
			[[challenge sender] cancelAuthenticationChallenge:challenge];
		}
		
	} 
	else 
	{
		[[challenge sender] cancelAuthenticationChallenge:challenge];
	}
}

#pragma mark External methods
- (void) cancelLoading
{
	doneLoading = YES;
	
	[theConnection cancel];  // this cancels, no further callbacks
}

- (NSString *)description
{
	return [documentRoot description];
}

@synthesize url = _url;
@synthesize delegate = _delegate;
@synthesize documentRoot;
@synthesize doneLoading;

@end
