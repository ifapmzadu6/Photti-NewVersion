//
//  PWXMLReader.h
//  PWXMLReader
//
//  Created by Benoit C on 10/31/13.
//  Copyright (c) 2013 Benoit Caccinolo. All rights reserved.
//

@import Foundation;


@interface PWXMLReader : NSObject <NSXMLParserDelegate> {
    NSMutableArray *dictionaryStack;
    NSMutableString *textInProgress;
}

+ (NSDictionary *)dictionaryForXMLData:(NSData *)data error:(NSError **)errorPointer;
+ (NSDictionary *)dictionaryForXMLString:(NSString *)string error:(NSError **)errorPointer;

@end
