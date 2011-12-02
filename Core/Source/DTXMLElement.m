//
//  DTXMLElement.m
//
//  Created by Oliver on 02.09.09.
//  Copyright 2009 Drobnik.com. All rights reserved.
//

#import "DTXMLElement.h"

@implementation DTXMLElement

@synthesize name, text, children, attributes, parent;


- (id) initWithName:(NSString *)elementName
{
	if (self = [super init])
	{
		self.name = elementName; 
		self.text = [NSMutableString string];
		//self.children = [NSMutableArray array];
	}
	
	return self;
}

- (void) dealloc
{
	[name release];
	[text release];
	[children release];
	[attributes release];
	
	[super dealloc];
}


// as XML
- (NSString *)description
{
	NSMutableString *attributeString = [NSMutableString string];
	
	for (NSString *oneAttribute in [attributes allKeys])
	{
		[attributeString appendFormat:@" %@=\"%@\"", oneAttribute, [[attributes objectForKey:oneAttribute] stringByReplacingOccurrencesOfString:@"&" withString:@"&amp;"]];
	}
	
	if ([children count])
	{
		NSMutableString *childrenString = [NSMutableString string];
		
		for (DTXMLElement *oneChild in children)
		{
			[childrenString appendFormat:@"%@", oneChild];
		}
		
		return [NSString stringWithFormat:@"<%@%@>%@</%@>", name, attributeString, childrenString, name];
	}
	else {
		return [NSString stringWithFormat:@"<%@%@>%@</%@>", name, attributeString, text, name];
	}
	
}

- (DTXMLElement *) getNamedChild:(NSString *)childName
{
	for (DTXMLElement *oneChild in self.children)
	{
		if ([oneChild.name isEqualToString:childName])
		{
			return oneChild;
		}
	}
	
	return nil;
}

- (NSArray *) getNamedChildren:(NSString *)childName
{
	NSMutableArray *tmpArray = [NSMutableArray array];
	
	for (DTXMLElement *oneChild in self.children)
	{
		if ([oneChild.name isEqualToString:childName])
		{
			[tmpArray addObject:oneChild];
		}
	}
	
	return [NSArray arrayWithArray:tmpArray]; // non-mutable
}

- (void) removeNamedChild:(NSString *)childName
{
	DTXMLElement *childToDelete = [self getNamedChild:childName];
	[self.children removeObject:childToDelete];
}

- (void) changeTextForNamedChild:(NSString *)childName toText:(NSString *)newText
{
	DTXMLElement *childToModify = [self getNamedChild:childName];
	[childToModify.text setString:newText];
}



- (DTXMLElement *) addChildWithName:(NSString *)childName text:(NSString *)childText
{
	DTXMLElement *newChild = [[[DTXMLElement alloc] initWithName:childName] autorelease];
	if (childText)
	{
		newChild.text = [NSString stringWithString:childText];
	}
	newChild.parent = self;
	[self.children addObject:newChild];
	
	return newChild;
}



#pragma mark virtual properties
- (NSString *)title
{
	DTXMLElement *titleElement = [self getNamedChild:@"title"];
	return titleElement.text;
}

- (NSMutableDictionary *) attributes
{
	// make dictionary if we don't have one
	if (!attributes)
	{
		self.attributes = [NSMutableDictionary dictionary];
	}
	
	return attributes;
}

- (NSMutableArray *) children
{
	// make array if we don't have one
	if (!children)
	{
		self.children = [NSMutableArray array];
	}
	
	return children;
}


- (NSURL *)link
{
	DTXMLElement *linkElement = [self getNamedChild:@"link"];
	NSString *linkString = [linkElement.attributes objectForKey:@"href"];
	
	// workaround
	//linkString = [linkString stringByReplacingOccurrencesOfString:@"http://192.168.1.78:8080/ELO-AFS/app" withString:@"http://divos.dyndns.org:8080/afs-elo/afs"];
	
	return linkString?[NSURL URLWithString:linkString]:nil;
}

- (NSString *) content
{
	return [self valueForKey:@"content"];
}

- (id) valueForKey:(NSString *)key
{
	DTXMLElement *titleElement = [self getNamedChild:key];
	return titleElement.text;
}


@end
