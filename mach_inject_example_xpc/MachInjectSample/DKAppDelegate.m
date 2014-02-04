//
//  DKAppDelegate.m
//  MachInjectSample
//
//  Created by Erwan Barrier on 04/12/12.
//  Copyright (c) 2012 Erwan Barrier. All rights reserved.
//

#import "DKAppDelegate.h"
#import "DKInstaller.h"
#import "DKInjectorProxy.h"

#include <syslog.h>

@implementation DKAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    NSError *error;
    
    // Install helper tools
    if (//[DKInstaller isInstalled] == NO &&
        [DKInstaller install:&error] == NO)
    {
        assert(error != nil);
        
        NSLog(@"Couldn't install MachInjectSample (domain: %@ code: %@)", error.domain, [NSNumber numberWithInteger:error.code]);
        NSAlert *alert = [NSAlert alertWithError:error];
        [alert runModal];
        [NSApp terminate:self];
    }
    
    if ([DKInjectorProxy inject:&error] == FALSE) {
        assert(error != nil);
        
        NSLog(@"Couldn't inject Finder (domain: %@ code: %@)", error.domain, [NSNumber numberWithInteger:error.code]);
        NSAlert *alert = [NSAlert alertWithError:error];
        [alert runModal];
        [NSApp terminate:self];
    }
    
    //During debug I needed to pause the XPC connections so they wouldn't collide
    /*
     int64_t delayInSeconds = 12.0;
     dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
     dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
     // Inject Finder process
     NSError *error = nil;
     
     });*/
    
}

@end
