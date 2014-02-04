//
//  Injector.m
//  Dark
//
//  Created by Erwan Barrier on 8/8/12.
//  Copyright (c) 2012 Erwan Barrier. All rights reserved.
//

#import "mach_inject_bundle.h"
#import <mach/mach_error.h>

#import "DKInjector.h"

@implementation DKInjector

- (mach_error_t)inject:(pid_t)pid withBundle:(const char *)bundlePackageFileSystemRepresentation
{

  mach_error_t error = mach_inject_bundle_pid(bundlePackageFileSystemRepresentation, pid);
  

  return (error);
}

@end
