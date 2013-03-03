//
//  DKInstaller.m
//  Dark
//
//  Created by Erwan Barrier on 8/11/12.
//  Copyright (c) 2012 Erwan Barrier. All rights reserved.
//

#import <ServiceManagement/ServiceManagement.h>

#import "DKInstaller.h"
#import "DKFrameworkInstaller.h"

NSString *const DKInjectorExecutablLabel  = @"com.erwanb.MachInjectSample.Injector";
NSString *const DKInstallerExecutablLabel = @"com.erwanb.MachInjectSample.Installer";

@interface DKInstaller ()

+ (BOOL)askPermission:(AuthorizationRef *)authRef error:(NSError **)error;
+ (BOOL)installHelperTool:(NSString *)executableLabel authorizationRef:(AuthorizationRef)authRef error:(NSError **)error;
+ (BOOL)installMachInjectBundleFramework:(NSError **)error;
@end

@implementation DKInstaller


+ (BOOL)isInstalled {
  NSString *versionInstalled = [[NSUserDefaults standardUserDefaults] stringForKey:DKUserDefaultsInstalledVersionKey];
  NSString *currentVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];

  return ([currentVersion compare:versionInstalled] == NSOrderedSame);
}

+ (BOOL)install:(NSError **)error {
  AuthorizationRef authRef = NULL;
  BOOL result = YES;

  result = [self askPermission:&authRef error:error];

  if (result == YES) {
    result = [self installHelperTool:DKInstallerExecutablLabel authorizationRef:authRef error:error];
  }

  if (result == YES) {
    result = [self installMachInjectBundleFramework:error];
  }

  if (result == YES) {
    result = [self installHelperTool:DKInjectorExecutablLabel authorizationRef:authRef error:error];
  }

  if (result == YES) {
    NSString *currentVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    [[NSUserDefaults standardUserDefaults] setObject:currentVersion forKey:DKUserDefaultsInstalledVersionKey];

    NSLog(@"Installed v%@", currentVersion);
  }
  
  return result;
}

+ (BOOL)askPermission:(AuthorizationRef *)authRef error:(NSError **)error {
  // Creating auth item to bless helper tool and install framework
  AuthorizationItem authItem = {kSMRightBlessPrivilegedHelper, 0, NULL, 0};

  // Creating a set of authorization rights
	AuthorizationRights authRights = {1, &authItem};

  // Specifying authorization options for authorization
	AuthorizationFlags flags = kAuthorizationFlagDefaults | kAuthorizationFlagInteractionAllowed | kAuthorizationFlagExtendRights;

  // Open dialog and prompt user for password
	OSStatus status = AuthorizationCreate(&authRights, kAuthorizationEmptyEnvironment, flags, authRef);

  if (status == errAuthorizationSuccess) {
    return YES;
  } else {
    NSLog(@"%@ (error code: %@)", DKErrPermissionDeniedDescription, [NSNumber numberWithInt:status]);

    *error = [[NSError alloc] initWithDomain:DKErrorDomain
                                        code:DKErrPermissionDenied
                                    userInfo:@{NSLocalizedDescriptionKey: DKErrPermissionDeniedDescription}];

    return NO;
  }
}

+ (BOOL)installHelperTool:(NSString *)executableLabel authorizationRef:(AuthorizationRef)authRef error:(NSError **)error {
  CFErrorRef blessError = NULL;
  BOOL result;

  result = SMJobBless(kSMDomainSystemLaunchd, (__bridge CFStringRef)executableLabel, authRef, &blessError);

  if (result == NO) {
    CFIndex errorCode = CFErrorGetCode(blessError);
    CFStringRef errorDomain = CFErrorGetDomain(blessError);

    NSLog(@"an error occurred while installing %@ (domain: %@ (%@))", executableLabel, errorDomain, [NSNumber numberWithLong:errorCode]);

    *error = [[NSError alloc] initWithDomain:DKErrorDomain
                                        code:DKErrInstallHelperTool
                                    userInfo:@{NSLocalizedDescriptionKey: DKErrInstallDescription}];
  } else {
    NSLog(@"Installed %@ successfully", executableLabel);
  }

  return result;
}

+ (void)appendLog:(NSString *)log {
    NSLog(@"INSTALLER: %@", log);
}

+ (BOOL)installMachInjectBundleFramework:(NSError **)error {
    
    
    xpc_connection_t connection = xpc_connection_create_mach_service("com.erwanb.MachInjectSample.Installer", NULL, XPC_CONNECTION_MACH_SERVICE_PRIVILEGED);
    
    if (!connection) {
        [self appendLog:@"Failed to create XPC connection."];
        return NO;
    }
    
    xpc_connection_set_event_handler(connection, ^(xpc_object_t event) {
        xpc_type_t type = xpc_get_type(event);
        
        if (type == XPC_TYPE_ERROR) {
            
            if (event == XPC_ERROR_CONNECTION_INTERRUPTED) {
                [self appendLog:@"XPC connection interupted."];
                
            } else if (event == XPC_ERROR_CONNECTION_INVALID) {
                [self appendLog:@"XPC connection invalid, releasing."];
                xpc_release(connection);
                
            } else {
                [self appendLog:@"Unexpected XPC connection error."];
            }
            
        } else {
            [self appendLog:@"Unexpected XPC connection event."];
        }
    });
    
    xpc_connection_resume(connection);
    
    NSString *frameworkPath = [[NSBundle mainBundle] pathForResource:@"mach_inject_bundle" ofType:@"framework"];

    
    xpc_object_t message = xpc_dictionary_create(NULL, NULL, 0);
    const char* request = [frameworkPath UTF8String];
    xpc_dictionary_set_string(message, "request", request);
    
    [self appendLog:[NSString stringWithFormat:@"Sending request: %s", request]];
    
    xpc_connection_send_message_with_reply(connection, message, dispatch_get_main_queue(), ^(xpc_object_t event) {
        
        
        
        
        const char* response = xpc_dictionary_get_string(event, "reply");
        
        [self appendLog:[NSString stringWithFormat:@"Received response: %s.", response]];
    });
    
    return YES;
    
}

@end
