//
//  NSData+AESCrypto.h
//  BNKAppCustomer
//
//  Created by fasol003 on 2015. 11. 27..
//  Copyright © 2015년 Sébastien MICHOY. All rights reserved.
//

#ifndef NSData_AESCrypto_h
#define NSData_AESCrypto_h

#import <Foundation/Foundation.h>

@interface NSData (AESCrypto)

- (NSData *)dataDecrypt;
- (NSData *)dataEncrypt;

+ (NSData *)dataWithBase64EncodedString:(NSString *)string;
- (id)initWithBase64EncodedString:(NSString *)string;

- (NSString *)base64Encoding;
- (NSString *)base64EncodingWithLineLength:(NSUInteger)lineLength;

@end

#endif /* NSData_AESCrypto_h */
