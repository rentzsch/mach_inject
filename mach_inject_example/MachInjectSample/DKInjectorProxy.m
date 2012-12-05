//
//  InjectorWrapper.m
//  Dark
//
//  Created by Erwan Barrier on 8/6/12.
//  Copyright (c) 2012 Erwan Barrier. All rights reserved.
//

#import <ServiceManagement/ServiceManagement.h>
#import <mach/mach_error.h>

#import "DKInjector.h"
#import "DKInjectorProxy.h"

@implementation DKInjectorProxy

+ (BOOL)inject:(NSError **)error {
  NSConnection *c = [NSConnection connectionWithRegisteredName:@"com.erwanb.MachInjectSample.Injector.mach" host:nil];
  assert(c != nil);

  DKInjector *injector = (DKInjector *)[c rootProxy];
  assert(injector != nil);

  pid_t pid = [[[NSRunningApplication runningApplicationsWithBundleIdentifier:@"com.apple.finder"]
                lastObject] processIdentifier];
  
  NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"Payload" ofType:@"bundle"];

  NSLog(@"Injecting Finder (%@) with %@", [NSNumber numberWithInt:pid], bundlePath);

  mach_error_t err = [injector inject:pid withBundle:[bundlePath fileSystemRepresentation]];

  if (err == 0) {
    NSLog(@"Injected Finder");
    return YES;
  } else {
    NSLog(@"an error occurred while injecting Finder: %@ (error code: %@)", [NSString stringWithCString:mach_error_string(err) encoding:NSASCIIStringEncoding], [NSNumber numberWithInt:err]);

    *error = [[NSError alloc] initWithDomain:DKErrorDomain
                                        code:DKErrInjection
                                    userInfo:@{NSLocalizedDescriptionKey: DKErrInjectionDescription}];

    return NO;
  }
}

@end
