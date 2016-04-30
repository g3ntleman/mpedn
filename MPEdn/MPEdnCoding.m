/*
 *  MPEdn: An EDN (extensible data notation) I/O library for OS X and
 *  iOS. See https://github.com/scramjet/mpedn and
 *  https://github.com/edn-format/edn.
 *
 *  Copyright (c) 2013 Matthew Phillips <m@mattp.name>
 *  Copyright (c) 2016 Dirk Theisen <d.theisen@objectpark.org>
 *
 *  The use and distribution terms for this software are covered by
 *  the Eclipse Public License 1.0
 *  (http://opensource.org/licenses/eclipse-1.0.php). By using this
 *  software in any fashion, you are agreeing to be bound by the terms
 *  of this license.
 *
 *  You must not remove this notice, or any other, from this software.
 */

#import "MPEdnCoding.h"
#import "MPEdnCoder.h"
//#import <objc/runtime.h>

static NSCharacterSet* QUOTE_CHARS;
static NSCharacterSet* NON_KEYWORD_CHARS;
static NSCharacterSet* NON_SYMBOL_CHARS;
static NSMutableSet* keywords;
static NSMutableSet* symbols;

//const NSString *MPEDN_CHARACTER_TAG = @"MPEDN_CHARACTER_TAG";
//
//BOOL MPEdnIsCharacter (NSNumber *number)
//{
//    return objc_getAssociatedObject (number, (__bridge const void *)MPEDN_CHARACTER_TAG) != nil;
//}

@implementation NSString (MPEdn)

+ (void) load {
    if (! keywords) {
        symbols = [[NSMutableSet alloc] initWithCapacity: 20];
        NSMutableCharacterSet* nonSymbolChars =
        [NSMutableCharacterSet characterSetWithCharactersInString: @".*+!-_?$<>'=/"];
        [nonSymbolChars formUnionWithCharacterSet: [NSCharacterSet alphanumericCharacterSet]];
        [nonSymbolChars invert];
        NON_SYMBOL_CHARS = [nonSymbolChars copy];

        keywords = [[NSMutableSet alloc] initWithCapacity: 20];
        NSMutableCharacterSet* nonKeywordChars =
        [NSMutableCharacterSet characterSetWithCharactersInString: @".*+!-_?$%&=/"];
        [nonKeywordChars formUnionWithCharacterSet: [NSCharacterSet alphanumericCharacterSet]];
        [nonKeywordChars invert];
        NON_KEYWORD_CHARS = [nonKeywordChars copy];
        
        QUOTE_CHARS = [NSCharacterSet characterSetWithCharactersInString: @"\\\"\n\r"];
    }
}


- (BOOL) isValidKeyword {
    return [self rangeOfCharacterFromSet: NON_KEYWORD_CHARS].location == NSNotFound;
}

- (BOOL) isValidSymbol {
    // A symbol string begins with a non-numeric character and can contain
    // alphanumeric characters and *, +, !, -, _, and ?.  (see
    // http://clojure.org/reader for details).

    return [self rangeOfCharacterFromSet: NON_SYMBOL_CHARS].location == NSNotFound;
}

- (NSString*) asKeyword {
    NSString* result = [keywords member: self];
    if (! result) {
        NSParameterAssert([self isValidKeyword]); // Todo: thow Exception
        result = [self copy];
        [keywords addObject: self];
    }
    return result;
}

- (NSString*) asSymbol {
    NSString* result = [keywords member: self];
    if (! result) {
        if (! [self isValidSymbol]) {
            NSParameterAssert([self isValidSymbol]); // Todo: thow Exception
        }
        result = [self copy];
        [symbols addObject: self];
    }
    return result;
}


- (BOOL) isKeyword {
    return [keywords member: self] == self;
}

- (BOOL) isSymbol {
    return [symbols member: self] == self;
}


- (void) encodeWithEdnCoder: (MPEdnCoder*) coder {
    
    if (self.isSymbol) {
        [coder writeString: self];
        return;
    }
    
    if (self.isKeyword) {
        [coder writeFormat: @":%@", self];
        return;
    }
    
    NSRange quoteRange = [self rangeOfCharacterFromSet: QUOTE_CHARS];
    
    if (quoteRange.location == NSNotFound) {
        [coder writeFormat: @"\"%@\"", self];
    } else {
        NSUInteger start = 0;
        NSUInteger valueLen = [self length];
        
        [coder writeString: @"\""];
        
        do {
            if (quoteRange.location > start)
                [coder writeString: [self substringWithRange: NSMakeRange (start, quoteRange.location - start)]];
            
            unichar quoteCh = [self characterAtIndex: quoteRange.location];
            
            switch (quoteCh)
            {
                case '\n':
                    [coder writeString: @"\\n"];
                    break;
                case '\r':
                    [coder writeString: @"\\r"];
                    break;
                default:
                    [coder writeFormat: @"\\%C", quoteCh];
            }
            
            start = quoteRange.location + 1;
            
            if (start < valueLen)
            {
                quoteRange = [self rangeOfCharacterFromSet: QUOTE_CHARS
                                                    options: NSLiteralSearch
                                                      range: NSMakeRange (start, valueLen - start)];
            }
        } while (start < valueLen && quoteRange.location != NSNotFound);
        
        if (start < valueLen)
            [coder writeString: [self substringWithRange: NSMakeRange (start, valueLen - start)]];
        
        [coder writeString: @"\""];
    }
}

@end


@implementation NSNumber (MPEdn)

- (void) encodeWithEdnCoder: (MPEdnCoder*) coder {

    if ([self isKindOfClass: [NSDecimalNumber class]]) {
        [coder writeString: [self stringValue]];
        [coder writeString: @"M"];
    } else {
        switch ([self objCType] [0])
        {
            case 'i':
            case 'q':
            case 's':
                [coder writeString: [self description]];
                break;
            case 'd':
                [coder writeFormat: @"%.15E", [self doubleValue]];
                break;
            case 'f':
                [coder writeFormat: @"%.7E", [self doubleValue]];
                break;
            case 'c':
            {
                if ([NSStringFromClass ([self class]) isEqualToString: @"__NSCFBoolean"])
                    [coder writeString: [self boolValue] ? @"true" : @"false"];
                else
                    [coder writeFormat: @"\\%c", [self charValue]];
                
                break;
            default:
                [NSException raise: @"MPEdnWriterException"
                            format: @"Don't know how to handle NSNumber "
                 "value %@, class %@", self, [self class]];
            }
        }
    }
}

@end

@implementation NSNull (MPEdn)

- (void) encodeWithEdnCoder: (MPEdnCoder*) coder {
    [coder writeString: @"nil"];
}

@end

@implementation NSDictionary (MPEdn)

- (void) encodeWithEdnCoder: (MPEdnCoder*) coder {
    
    BOOL firstItem = YES;
    
    [coder writeString: @"{"];
    
    for (id<MPEdnCoding> key in self) {
        id<MPEdnCoding> value = self[key];
        
        if (!firstItem) {
            [coder writeString: @","];
        }
        
        [coder writeObject: key];
        [coder writeString: @" "];
        [coder writeObject: value];
        
        firstItem = NO;
    }
    
    [coder writeString: @"}"];
}

@end

@implementation NSArray (MPEdn)

- (void) encodeWithEdnCoder: (MPEdnCoder*) coder {

    BOOL firstItem = YES;
    
    [coder writeString: @"["];
    
    for (id<MPEdnCoding> item in self) {
        if (!firstItem) {
            [coder writeString: @","];
        }
        
        [coder writeObject: item];
        
        firstItem = NO;
    }
    
    [coder writeString: @"]"];
}

@end

@implementation NSSet (MPEdn)

- (void) encodeWithEdnCoder: (MPEdnCoder*) coder {
    
    BOOL firstItem = YES;
    
    [coder writeString: @"#{"];
    
    for (id item in self) {
        if (!firstItem) {
            [coder writeString: @","];
        }
        
        [coder writeObject: item];
        
        firstItem = NO;
    }
    
    [coder writeString: @"}"];
}

@end

@implementation NSDate (MPEdn)

static NSDateFormatter *dateFormatter = nil;

+ (void) load {
    if (! dateFormatter) {
        // NSDateFormatter is *very* slow to create, pre-allocate one
        // NB NSDateFormatter is thread safe only in iOS 7+ and OS X 10.9+
        // TODO warn if being compiled on a platform where this is unsafe
        dateFormatter = [[NSDateFormatter alloc] init];
        NSLocale *enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        dateFormatter.locale = enUSPOSIXLocale;
        dateFormatter.dateFormat = @"yyyy'-'MM'-'dd'T'HH':'mm':'ss.SSXXXXX";
        dateFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation: @"UTC"];
        
        [MPEdnCoder registerDefaultClass: self];
    }
}

- (void) encodeWithEdnCoder: (MPEdnCoder*) coder {
    NSString* dateString = [dateFormatter stringFromDate: self];
    [coder writeString: dateString];
}

+ (NSString*) ednTag {
    return @"inst";
}

+ (id) newWithEdnString: (NSString*) value error: (NSError**) errorPtr {
    
    NSDate* date = nil;
    NSError* formatterError = nil;
    [dateFormatter getObjectValue: &date forString: value range: NULL error: &formatterError];
    
    if (! date && formatterError) {
        *errorPtr = [NSError errorWithDomain: @"MPEdn" code: ERROR_TAG_READER_ERROR
                     
                            userInfo: @{NSLocalizedDescriptionKey :
                                            [NSString stringWithFormat: @"Bad RFC 3339 date: %@", value],
                                                NSUnderlyingErrorKey : formatterError}];
    }
    return date;
}


@end

@implementation NSUUID (MPEdn)

+ (void) load {
    [MPEdnCoder registerDefaultClass: self];
}

- (void) encodeWithEdnCoder: (MPEdnCoder*) coder {
    NSString* uuidString = [self UUIDString];
    [coder writeString: uuidString];
}

+ (NSString*) ednTag {
    return @"uuid";
}

+ (id) newWithEdnString: (NSString*) value error: (NSError**) errorPtr {
        NSUUID *uuid = [[NSUUID alloc] initWithUUIDString: value];
        
        if (! uuid && errorPtr) {
            *errorPtr = [NSError errorWithDomain: @"MPEdn" code: ERROR_TAG_READER_ERROR
                                        userInfo: @{NSLocalizedDescriptionKey :
                                                        [NSString stringWithFormat: @"Bad UUID: %@", value]}];
        }
    return uuid;
}

@end




@implementation NSData (MPEdn)

+ (void) load {
    [MPEdnCoder registerDefaultClass: self];
}

- (void) encodeWithEdnCoder: (MPEdnCoder*) coder {
    NSString* base64String = [self base64EncodedStringWithOptions: 0];
    [coder writeString: base64String];
}

+ (NSString*) ednTag {
    return @"base64";
}

+ (id) newWithEdnString: (NSString*) value error: (NSError**) errorPtr {
    
    value = [value copy];
    
    NSData* data = [[NSData alloc] initWithBase64EncodedString: value
                                                       options: 0];
    
    if (! data && errorPtr) {
        *errorPtr = [NSError errorWithDomain: @"MPEdn" code: ERROR_TAG_READER_ERROR
                                    userInfo: @{NSLocalizedDescriptionKey : @"Bad Base64 data"}];
    }

    return data;
}

@end

@implementation NSURL (MPEdn)

+ (NSString*) ednTag {
    return @"url";
}


- (void) encodeWithEdnCoder: (MPEdnCoder*) coder {
    NSString* urlString = [self absoluteString];
    [coder writeString: urlString];
}

+ (id) newWithEdnString: (NSString*) value error: (NSError**) errorPtr {
    
    NSURL* url = [[NSURL alloc] initWithString: value];
    
    if (url && errorPtr) {
        *errorPtr = [NSError errorWithDomain: @"MPEdn" code: ERROR_TAG_READER_ERROR
                                    userInfo: @{NSLocalizedDescriptionKey :
                                                    [NSString stringWithFormat: @"Bad URL String: %@", value]}];
    }
    return url;
}


@end
