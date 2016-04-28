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
 *  You must not remove this notice, or any other, from this software.
 */

#import <Foundation/Foundation.h>

@class MPEdnCoder;

@protocol EdnValue <NSObject>

- (void) encodeWithEdnCoder: (MPEdnCoder*) coder;

@end

@protocol EdnTaggedValue <EdnValue>

+ (NSString*) ednTag;
+ (id) newWithEdnString: (NSString*) value error: (NSError**) errorPtr;

@end

/**
 * Represents an EDN keyword instance.
 *
 * Keywords in EDN (e.g. `:keyword`) are singleton, string-like values
 * that can be efficiently compared for equality using `==`.
 *
 * Instances of this class are used to represent keywords by
 * `MPEdnParser` and `MPEdnWriter`.
 * 
 * See also [NSString(MPEdn) ednKeyword]
 */

@interface NSString (MPEdn) <EdnValue>

/**
 * Look up the EDN keyword string instance for this string.
 *
 * Keywords are singletons: only single instance will exist for a
 * given name, so it's safe to compare them with ==.
 *
 * This method will generate an exception on an attempt to generate a
 * keyword with illegal characters. Valid characters in a keyword are
 * any letter (upper or lower case), number, or any of the following
 * characters: `*+!-_?$%&=/`.
 * 
 * @see ednName
 * @see [MPEdnKeyword isValidKeyword:]
 */
- (NSString*) asKeyword;

/**
 * Test if a given name is a valid EDN keyword.
 *
 * Valid characters in a keyword are any letter (upper or lower case),
 * number, or any of the following characters: `*+!-_?$%&=/`.
 */
- (BOOL) isKeyword;

- (NSString*) asSymbol;
- (BOOL) isSymbol;


///**
// * Convenience method that simply returns self.
// *
// * The `ednName` method
// * can be used to compare EDN keywords, symbols and string names
// * without regard to type.
// */
//- (NSString *) ednValue;

@end

@interface NSDictionary (MPEdn) <EdnValue>

@end

@interface NSArray (MPEdn) <EdnValue>

@end

@interface NSNull (MPEdn) <EdnValue>

@end


@interface NSNumber (MPEdn) <EdnValue>

@end

@interface NSSet (MPEdn) <EdnValue>

@end


@interface NSDate (MPEdn) <EdnTaggedValue>

@end

@interface NSUUID (MPEdn) <EdnTaggedValue>

@end

@interface NSData (MPEdn) <EdnTaggedValue>

@end


