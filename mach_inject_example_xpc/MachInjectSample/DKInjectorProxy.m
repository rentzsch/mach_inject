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

+ (void)appendLog:(NSString *)log {
    NSLog(@"LOG injector: %@", log);
}


+ (BOOL)inject:(NSError **)error {
    
    
    xpc_connection_t connection = xpc_connection_create_mach_service("com.erwanb.MachInjectSample.Injector", NULL, XPC_CONNECTION_MACH_SERVICE_PRIVILEGED);
    
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
    
    xpc_object_t message = xpc_dictionary_create(NULL, NULL, 0);
    const char* request = "Hi there, helper service.";
    xpc_dictionary_set_string(message, "request", request);
    
    [self appendLog:[NSString stringWithFormat:@"Sending request: %s", request]];
    
    xpc_connection_send_message_with_reply(connection, message, dispatch_get_main_queue(), ^(xpc_object_t event) {
        const char* response = xpc_dictionary_get_string(event, "reply");
        [self appendLog:[NSString stringWithFormat:@"Received response: %s.", response]];
    });
    return YES;
}

@end
