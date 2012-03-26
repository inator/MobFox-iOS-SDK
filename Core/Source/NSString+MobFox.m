//
//  NSString+MobFox.m
//
//  Created by Oliver Drobnik on 9/24/10.
//  Copyright 2010 Drobnik.com. All rights reserved.
//  Modified by Michael Kaye sendmetospace.co.uk

#import "NSString+MobFox.h"
#import <CommonCrypto/CommonDigest.h>

@implementation NSString (MobFox)


- (NSString *)stringByUrlEncoding
{
	return (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(NULL,  (__bridge CFStringRef)self,  NULL,  (CFStringRef)@"!*'();:@&=+$,/?%#[]",  kCFStringEncodingUTF8);
}


//// method to calculate a standard md5 checksum of this string, check against: http://www.adamek.biz/md5-generator.php
//- (NSString * )md5
//{
//	const char *cStr = [self UTF8String];
//	unsigned char result [CC_MD5_DIGEST_LENGTH];
//	CC_MD5( cStr, strlen(cStr), result );
//	
//	return [NSString 
//			stringWithFormat: @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
//			result[0], result[1],
//			result[2], result[3],
//			result[4], result[5],
//			result[6], result[7],
//			result[8], result[9],
//			result[10], result[11],
//			result[12], result[13],
//			result[14], result[15]
//			];
//}

// Based on http://www.makebetterthings.com/iphone/how-to-get-md5-and-sha1-in-objective-c-ios-sdk/
-(NSString*)sha1
{
    const char *cstr = [self cStringUsingEncoding:NSUTF8StringEncoding];
    NSData *data = [NSData dataWithBytes:cstr length:self.length];
    
    uint8_t digest[CC_SHA1_DIGEST_LENGTH];
    
    CC_SHA1(data.bytes, data.length, digest);
    
    NSMutableString* output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
    
    for(int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x", digest[i]];
    
    return output;
    
}

- (NSString *)md5
{
    const char *cStr = [self UTF8String];
    unsigned char digest[16];
    CC_MD5( cStr, strlen(cStr), digest ); // This is the md5 call
    
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x", digest[i]];
    
    return  output;
    
}

@end



@implementation DummyString

@end
