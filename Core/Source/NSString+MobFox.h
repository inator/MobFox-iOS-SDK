//
//  NSString+MobFox.h
//
//  Created by Oliver Drobnik on 9/24/10.
//  Copyright 2010 Drobnik.com. All rights reserved.

#import <Foundation/Foundation.h>


@interface NSString (MobFox)
- (NSString *)stringByUrlEncoding;
- (NSString * )md5;
- (NSString*)sha1;
@end


// this makes the -all_load linker flag unnecessary, -ObjC still needed
@interface DummyString : NSString

@end

