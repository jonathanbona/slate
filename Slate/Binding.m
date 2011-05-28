//
//  Binding.m
//  Slate
//
//  Created by Jigish Patel on 5/18/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Binding.h"
#import "Constants.h"
#import "OperationUtil.h"
#import "StringTokenizer.h"


@implementation Binding

@synthesize op;
@synthesize keyCode;
@synthesize modifiers;
@synthesize hotKeyRef;

static NSDictionary *dictionary = nil;

- (id)init {
  self = [super init];
  if (self) {
    // Initialization code here.
  }

  return self;
}

// Yes, this method is huge. Deal with it.
- (id)initWithString: (NSString *)binding {
  self = [self init];
  if (self) {
    // bind <key:modifiers> <op> <parameters>
    NSArray *tokens = [StringTokenizer tokenize:binding maxTokens:3];
    if ([tokens count] <=2) {
      @throw([NSException exceptionWithName:@"Unrecognized Bind" reason:binding userInfo:nil]);
    }
    NSString *keystroke = [tokens objectAtIndex:1];
    NSArray *keyAndModifiers = [keystroke componentsSeparatedByString:COLON];
    if ([keyAndModifiers count] >= 1) {
      [self setKeyCode:(UInt32)[[[Binding asciiToCodeDict] objectForKey:[keyAndModifiers objectAtIndex:0]] integerValue]];
      [self setModifiers:0];
      if ([keyAndModifiers count] >= 2) {
        NSArray *modifiersArray = [[keyAndModifiers objectAtIndex:1] componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@",;"]];
        NSEnumerator *modEnum = [modifiersArray objectEnumerator];
        NSString *mod = [modEnum nextObject];
        while (mod) {
          if ([mod isEqualToString:CONTROL]) {
            modifiers += controlKey;
          } else if ([mod isEqualToString:OPTION]) {
            modifiers += optionKey;
          } else if ([mod isEqualToString:COMMAND]) {
            modifiers += cmdKey;
          } else if ([mod isEqualToString:SHIFT]) {
            modifiers += shiftKey;
          } else {
            NSLog(@"ERROR: Unrecognized modifier '%s'", [mod cStringUsingEncoding:NSASCIIStringEncoding]);
            @throw([NSException exceptionWithName:@"Unrecognized Modifier" reason:[NSString stringWithFormat:@"Unrecognized modifier '%@' in '%@'", mod, binding] userInfo:nil]);
          }
          mod = [modEnum nextObject];
        }
      }
    }
    
    [self setOp:[OperationUtil operationFromString:[tokens objectAtIndex:2]]];
    
    if (op == nil) {
      NSLog(@"ERROR: Unable to create binding");
      @throw([NSException exceptionWithName:@"Unable To Create Binding" reason:[NSString stringWithFormat:@"Unable to create '%@'", binding] userInfo:nil]);
    }
    
    @try {
      [op getDimensionsWithCurrentTopLeft:NSMakePoint(1,1) currentSize:NSMakeSize(1,1)];
      [op getTopLeftWithCurrentTopLeft:NSMakePoint(1,1) currentSize:NSMakeSize(1,1) newSize:NSMakeSize(1,1)];
    } @catch (NSException *ex) {
      NSLog(@"ERROR: Unable to test binding '%s'", [binding cStringUsingEncoding:NSASCIIStringEncoding]);
      @throw([NSException exceptionWithName:@"Unable To Parse Binding" reason:[NSString stringWithFormat:@"Unable to parse '%@' in '%@'", [ex reason], binding] userInfo:nil]);
    }
    [tokens release];
  }

  return self;
}

- (void)dealloc {
  [self setOp:nil];
  [self setHotKeyRef:nil];
  [super dealloc];
}

// This returns a dictionary containing mappings from ASCII to keyCode
+ (NSDictionary *)asciiToCodeDict {
  if (dictionary == nil) {
    dictionary = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"ASCIIToCode" ofType:@"plist"]];
    [dictionary retain];
  }
  return dictionary;
}

@end
