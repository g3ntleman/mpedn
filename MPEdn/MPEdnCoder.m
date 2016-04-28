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

static NSMutableArray *defaultWriters;

@implementation MPEdnCoder {
  NSMutableString *outputStr;
}


- (NSString*) ednFromObject: (id <EdnValue>) value {
    outputStr = [[NSMutableString alloc] init];
    [self writeObject: value];
    return outputStr;
}


- (void) writeString: (NSString*) string {
    [outputStr appendString: string];
}

- (void) writeStrings: (NSString *) firstArg, ... {
    va_list args;
    va_start(args, firstArg);
    for (NSString* arg = firstArg; arg != nil; arg = va_arg(args, NSString*)) {
        [outputStr appendString: arg];
    }
    va_end(args);
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

@end

@implementation NSObject (MPEdnWriter)

- (NSString*) objectToEdnString {
  return [[[MPEdnCoder alloc] init] ednFromObject: (id<EdnValue>)self];
}

+ (NSString*) ednTag {
    return nil;
}

@end
