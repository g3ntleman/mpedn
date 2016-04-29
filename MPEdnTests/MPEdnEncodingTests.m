#import "MPEdnEncodingTests.h"

#import "MPEdnCoder.h"
#import "MPEdn.h"


#define MPAssertSerialisesOK(value, correct)             \
{                                                        \
  MPEdnCoder *writer = [[MPEdnCoder alloc] init];               \
  NSString *str = [writer ednFromObject: value];        \
  XCTAssertEqualObjects (str, correct, @"Serialise");     \
}

@implementation MPEdnEncodingTests

- (void) testNumbers {
  MPAssertSerialisesOK (@1, @"1");
  MPAssertSerialisesOK (@-1, @"-1");
  
  MPAssertSerialisesOK ([NSNumber numberWithShort: 1234], @"1234");
  MPAssertSerialisesOK ([NSNumber numberWithInt: 1234], @"1234");
  MPAssertSerialisesOK ([NSNumber numberWithUnsignedInt: 1234], @"1234");
  MPAssertSerialisesOK ([NSNumber numberWithLong: 1234], @"1234");
  MPAssertSerialisesOK ([NSNumber numberWithLongLong: 1234], @"1234");
  MPAssertSerialisesOK ([NSNumber numberWithUnsignedLongLong: 1234], @"1234");
  
  MPAssertSerialisesOK ([NSNumber numberWithDouble: 1.1], @"1.100000000000000E+00");
  MPAssertSerialisesOK ([NSNumber numberWithFloat: 1.1], @"1.1000000E+00");
  MPAssertSerialisesOK (@1.1e-5, @"1.100000000000000E-05");
  
  // decimals
  MPAssertSerialisesOK ([NSDecimalNumber decimalNumberWithString: @"0"], @"0M");
  MPAssertSerialisesOK ([NSDecimalNumber decimalNumberWithString: @"0.00"], @"0M");
  MPAssertSerialisesOK ([NSDecimalNumber decimalNumberWithString: @"1.2300"], @"1.23M");
  MPAssertSerialisesOK ([NSDecimalNumber decimalNumberWithString: @"123E-2"], @"1.23M");
  MPAssertSerialisesOK ([NSDecimalNumber decimalNumberWithString: @"0.123E1"], @"1.23M");
  
  MPAssertSerialisesOK ([NSDecimalNumber decimalNumberWithString: @"5.568E15"], @"5568000000000000M");
  
  // boolean
  MPAssertSerialisesOK (@YES, @"true");
  MPAssertSerialisesOK (@NO, @"false");
  
  // characters
  // NSNumber is pretty broken wrt characters. [NSNumber numberWithChar: 'a']
  // produces a number that is reported as a character, but '\n' doesn't. As
  // as workaround, you can force a number to be seen as a character using
  // MPEdnTagAsCharacter. See discussion here:
  // http://www.cocoabuilder.com/archive/cocoa/136956-nsnumber-is-completely-broken.html
  MPAssertSerialisesOK (@'a', @"\\a");

  //  NSLog (@"********** %s", [[NSNumber numberWithChar: '\n'] objCType]);
  //  NSLog (@"********** %@", [[NSNumber numberWithChar: '\n'] class]);
  //  NSLog (@"********** %li", CFNumberGetType ((CFNumberRef)[NSNumber numberWithChar: '\n']));

  {
    NSNumber *newline = [[NSNumber alloc] initWithChar: '\n'];
    
    // NB: this GPF's under Xcode 5.1/iOS 7.1
    //MPEdnTagAsCharacter (newline);

    // BUT the test passes: it seems numberWithChar is fixed
    XCTAssertEqual ((char)'c', (char)[newline objCType][0], @"NSNumber numberWithChar");

    MPAssertSerialisesOK (newline, @"\\\n");
  }
}

- (void) testStrings {
  MPAssertSerialisesOK (@"", @"\"\"");
  MPAssertSerialisesOK (@"hello", @"\"hello\"");
  MPAssertSerialisesOK (@"a \n in it", @"\"a \\n in it\"");
  MPAssertSerialisesOK (@"a \" in it", @"\"a \\\" in it\"");
  MPAssertSerialisesOK (@"a \" and a \\ in it", @"\"a \\\" and a \\\\ in it\"");
  MPAssertSerialisesOK (@"\\", @"\"\\\\\"");
  MPAssertSerialisesOK (@"\\\"", @"\"\\\\\\\"\"");
  MPAssertSerialisesOK (@"\\ abc", @"\"\\\\ abc\"");
  MPAssertSerialisesOK (@"abc \\", @"\"abc \\\\\"");
  MPAssertSerialisesOK (@"abc \\e", @"\"abc \\\\e\"");
  MPAssertSerialisesOK (@"a\\", @"\"a\\\\\"");
  
  MPAssertSerialisesOK (@"line 1\nline 2", @"\"line 1\\nline 2\"");
  MPAssertSerialisesOK (@"line 1\r\nline 2", @"\"line 1\\r\\nline 2\"");
  
  XCTAssertEqualObjects ([@{@"a" : @1} objectToEdnString], @"{\"a\" 1}", @"Test category");
  XCTAssertEqualObjects ([@{[@"a" asKeyword] : @1} objectToEdnString], @"{:a 1}", @"Test category");
}

- (void) testNil {
  MPAssertSerialisesOK (nil, @"nil");
  MPAssertSerialisesOK ([NSNull null], @"nil");
}

- (void) testMaps {
  MPAssertSerialisesOK (@{}, @"{}");
  MPAssertSerialisesOK (@{@"a" : @1}, @"{\"a\" 1}");
  MPAssertSerialisesOK (@{[@"a" asKeyword] : @1}, @"{:a 1}");
  MPAssertSerialisesOK (@{@"a non keyword" : @1}, @"{\"a non keyword\" 1}");
}

- (void) testLists {
  MPAssertSerialisesOK (@[], @"[]");
  MPAssertSerialisesOK (@[@1], @"[1]");
  
  {
    NSArray *list = @[@"hello", @1];
    MPAssertSerialisesOK (list, @"[\"hello\",1]");
  }
}

- (void) testSets {
    {
        NSSet *set = [NSSet set];
        MPAssertSerialisesOK (set, @"#{}");
    }
    
    {
        NSSet *set = [NSSet setWithArray: @[@1, @"a"]];
        MPAssertSerialisesOK (set, @"#{\"a\",1}");
    }
}

- (void) testSymbols {
  MPAssertSerialisesOK ([@"my-symbol" asSymbol], @"my-symbol");
}

- (void) testKeywords {
    MPAssertSerialisesOK ([@"abc" asKeyword], @":abc");
  
  {
    NSArray *list = @[[@"abc" asKeyword], [@"def" asKeyword]];
    
    MPAssertSerialisesOK (list, @"[:abc,:def]");
  }
  
  MPAssertSerialisesOK (@{@":abc" : @1}, @"{\":abc\" 1}");
  MPAssertSerialisesOK (@{[@"e4faee275bb1740e2001d285a052474300c6921a" asKeyword] : @1}, @"{:e4faee275bb1740e2001d285a052474300c6921a 1}");
}

- (void) testDates {
    // date
    NSDate* date = [NSDate dateWithTimeIntervalSince1970: 63115200];
    
    MPEdnCoder* writer = [MPEdnCoder new];
    
    XCTAssertEqualObjects ([writer ednFromObject: date],
                           @"#inst \"1972-01-01T12:00:00.00Z\"", @"Serialise");
}

- (void) testUUID {
    
    NSUUID* uuid = [[NSUUID alloc] initWithUUIDString: @"F81D4FAE-7DEC-11D0-A765-00A0C91E6BF6"];
    
    MPEdnCoder* writer = [MPEdnCoder new];
    
    XCTAssertEqualObjects ([writer ednFromObject: uuid],
                           @"#uuid \"F81D4FAE-7DEC-11D0-A765-00A0C91E6BF6\"", @"Serialise");
}

- (void) testBase64 {
    // custom tag (base 64)
    uint8_t data [10] = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9};
    
    id map = @{[@"a" asKeyword] : [NSData dataWithBytes: data length: sizeof (data)]};
    
    MPEdnCoder* writer = [MPEdnCoder new];
    
    XCTAssertEqualObjects ([writer ednFromObject: map], @"{:a #base64 \"AAECAwQFBgcICQ==\"}", @"Serialise");
}

- (void) testURL {
    MPEdnCoder* writer = [MPEdnCoder new];
    
    XCTAssertEqualObjects ([writer ednFromObject: @{[@"a" asKeyword] : [[NSURL alloc] initWithString: @"http://example.com"]}],
                           @"{:a #url \"http://example.com\"}", @"Serialise");
}

@end