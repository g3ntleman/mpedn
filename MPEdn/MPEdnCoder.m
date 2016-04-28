/*
 *  MPEdn: An EDN (extensible data notation) I/O library for OS X and
 *  iOS. See https://github.com/scramjet/mpedn and
 *  https://github.com/edn-format/edn.
 *
 *  Copyright (c) 2013 Matthew Phillips <m@mattp.name>
 *
 *  The use and distribution terms for this software are covered by
 *  the Eclipse Public License 1.0
 *  (http://opensource.org/licenses/eclipse-1.0.php). By using this
 *  software in any fashion, you are agreeing to be bound by the terms
 *  of this license.
 *
 * You must not remove this notice, or any other, from this software.
 */

#import "MPEdnCoder.h"
#import "MPEdnValue.h"
#import "MPEdnTaggedValueWriter.h"
#import "MPEdn.h"

//#import <objc/runtime.h>

//NSNumber *MPEdnTagAsCharacter (NSNumber *number)
//{
//  objc_setAssociatedObject (number, (__bridge const void *)MPEDN_CHARACTER_TAG,
//                            MPEDN_CHARACTER_TAG, OBJC_ASSOCIATION_ASSIGN);
//
//  return number;
//}

//BOOL MPEdnIsCharacter (NSNumber *number)
//{
//  return objc_getAssociatedObject (number, (__bridge const void *)MPEDN_CHARACTER_TAG) != nil;
//}

//static NSMutableArray *copy(NSArray *array)
//{
//  NSMutableArray *arrayCopy = [NSMutableArray arrayWithCapacity: [array count]];
//  
//  for (id i in array)
//  {
//    if ([i respondsToSelector: @selector (copyWithZone:)])
//      [arrayCopy addObject: [i copy]];
//    else
//      [arrayCopy addObject: i];
//  }
//
//  return arrayCopy;
//}

static NSMutableArray *defaultWriters;

@implementation MPEdnCoder
{
  NSMutableString *outputStr;
}


//- (id) init {
//  if (self = [super init]) {
//  }
//
//  return self;
//}

- (NSString*) ednFromObject: (id <EdnValue>) value {
    outputStr = [[NSMutableString alloc] init];
    [self writeObject: value];
    return outputStr;
}


- (void) writeString: (NSString*) string {
    [outputStr appendString: string];
}

- (void) writeObject: (id <EdnValue>) object {
    
    if (object == nil) {
        [outputStr appendString: @"nil"];
        return;
    }
    
    if (! [object conformsToProtocol: @protocol(EdnValue)]) {
        [NSException raise: @"MPEdnWriterException"
                    format: @"Don't know how to handle value %@ of class %@", object, [object class]];

    }
    

//    if ([object isKindOfClass: [MPEdnSymbol class]]) {
//        [self outputSymbol: object];
//        return;
//    } else {
//        id<MPEdnTaggedValueWriter> tagWriter = [self tagWriterFor: object];
//        
//        if (tagWriter)
//        {
//            [outputStr appendFormat: @"#%@ ", [tagWriter tagName]];
//            
//            [tagWriter writeValue: object toWriter: self];
//        } else if ([object isKindOfClass: [MPEdnTaggedValue class]])
//        {
//            [outputStr appendFormat: @"#%@ ", ((MPEdnTaggedValue *)object).tag];
//            
//            [self outputObject: ((MPEdnTaggedValue *)object).value];
//        } else
//        {
//            [NSException raise: @"MPEdnWriterException"
//                        format: @"Don't know how to handle value of type %@ ", [object class]];
//        }
//        return;
//    }
    
    NSString* ednTag = [[object class] ednTag];
    
    if (ednTag.length) {
        [outputStr appendString: @"#"];
        [outputStr appendString: [[object class] ednTag]];
        [outputStr appendString: @" \""];
        [object encodeWithEdnCoder: self];
        [outputStr appendString: @"\""];
        return;
    }
    
    [object encodeWithEdnCoder: self];
}

//- (void) outputNumber: (NSNumber *) value
//{
//  if ([value isKindOfClass: [NSDecimalNumber class]])
//  {
//    [outputStr appendString: [value stringValue]];
//    [outputStr appendString: @"M"];
//  } else
//  {
//    switch ([value objCType] [0])
//    {
//      case 'i':
//      case 'q':
//      case 's':
//        [outputStr appendFormat: @"%@", value];
//        break;
//      case 'd':
//        [outputStr appendFormat: @"%.15E", [value doubleValue]];
//        break;
//      case 'f':
//        [outputStr appendFormat: @"%.7E", [value doubleValue]];
//        break;
//      case 'c':
//      {
//        if ([NSStringFromClass ([value class]) isEqualToString: @"__NSCFBoolean"])
//          [outputStr appendString: [value boolValue] ? @"true" : @"false"];
//        else
//          [outputStr appendFormat: @"\\%c", [value charValue]];
//
//        break;
//      default:
//        [NSException raise: @"MPEdnWriterException"
//                    format: @"Don't know how to handle NSNumber "
//                             "value %@, class %@", value, [value class]];
//      }
//    }
//  }
//}

//- (void) outputString: (NSString *) value
//{
//  NSRange quoteRange = [value rangeOfCharacterFromSet: QUOTE_CHARS];
//  
//  if (quoteRange.location == NSNotFound)
//  {
//    [outputStr appendFormat: @"\"%@\"", value];
//  } else
//  {
//    NSUInteger start = 0;
//    NSUInteger valueLen = [value length];
//    
//    [outputStr appendString: @"\""];
//    
//    do
//    {
//      if (quoteRange.location > start)
//        [outputStr appendString: [value substringWithRange: NSMakeRange (start, quoteRange.location - start)]];
//
//      unichar quoteCh = [value characterAtIndex: quoteRange.location];
//      
//      switch (quoteCh)
//      {
//        case '\n':
//          [outputStr appendString: @"\\n"];
//          break;
//        case '\r':
//          [outputStr appendString: @"\\r"];
//          break;
//        default:
//          [outputStr appendFormat: @"\\%C", quoteCh];
//      }
//
//      start = quoteRange.location + 1;
//      
//      if (start < valueLen)
//      {
//        quoteRange = [value rangeOfCharacterFromSet: QUOTE_CHARS
//                                            options: NSLiteralSearch
//                                              range: NSMakeRange (start, valueLen - start)];
//      }
//    } while (start < valueLen && quoteRange.location != NSNotFound);
//    
//    if (start < valueLen)
//      [outputStr appendString: [value substringWithRange: NSMakeRange (start, valueLen - start)]];
//    
//    [outputStr appendString: @"\""];
//  }
//}

//- (BOOL) outputKeywordNamed: (NSString *) name {
//    if ([name isValidKeyword]) {
//        [outputStr appendString: @":"];
//        [outputStr appendString: name];
//        
//        return YES;
//    } else {
//        return NO;
//    }
//}

//- (void) outputDictionary: (NSDictionary *) value {
//
//}
//
//
//- (void) outputSymbol: (MPEdnSymbol *) value
//{
//  [outputStr appendString: value.name];
//}

@end

@implementation NSObject (MPEdnWriter)

- (NSString *) objectToEdnString
{
  return [[[MPEdnCoder alloc] init] ednFromObject: self];
}

+ (NSString*) ednTag {
    return nil;
}

@end
