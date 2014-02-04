//
//  main.m
//  Injector
//
//  Created by Erwan Barrier on 8/7/12.
//  Copyright (c) 2012 Erwan Barrier. All rights reserved.
//

#import <launch.h>
#import <ServiceManagement/ServiceManagement.h>
#import <mach/mach_error.h>
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "DKInjector.h"

#include <syslog.h>
#include <xpc/xpc.h>


static void __XPC_Peer_Event_Handler(xpc_connection_t connection, xpc_object_t event) {
    syslog(LOG_NOTICE, "Received event in helper.");
    
	xpc_type_t type = xpc_get_type(event);
    
	if (type == XPC_TYPE_ERROR) {
		if (event == XPC_ERROR_CONNECTION_INVALID) {
			// The client process on the other end of the connection has either
			// crashed or cancelled the connection. After receiving this error,
			// the connection is in an invalid state, and you do not need to
			// call xpc_connection_cancel(). Just tear down any associated state
			// here.
            
		} else if (event == XPC_ERROR_TERMINATION_IMMINENT) {
			// Handle per-connection termination cleanup.
		}
        
	} else {
        xpc_connection_t remote = xpc_dictionary_get_remote_connection(event);
        
        NSString *payloadPath = @"/Users/h0xff/Library/Developer/Xcode/DerivedData/MachInjectSample-eunqttgqvojfetagfsxvibytdmul/Build/Products/Debug/Payload.bundle";
        
        DKInjector *injector = [DKInjector new];
        pid_t pid = [[[NSRunningApplication runningApplicationsWithBundleIdentifier:@"com.apple.finder"]
                      lastObject] processIdentifier];
        
        NSString *bundlePath = payloadPath; //[[NSBundle mainBundle] pathForResource:@"Payload" ofType:@"bundle"];
        
        NSLog(@"Injecting Finder (%@) with %@", [NSNumber numberWithInt:pid], bundlePath);
        
        mach_error_t err = [injector inject:pid withBundle:[bundlePath fileSystemRepresentation]];
        
        if (err == 0) {
            NSLog(@"Injected Finder");
            //return YES;
        } else {
            NSLog(@"an error occurred while injecting Finder: %@ (error code: %@)", [NSString stringWithCString:mach_error_string(err) encoding:NSASCIIStringEncoding], [NSNumber numberWithInt:err]);
            /*
            *error = [[NSError alloc] initWithDomain:DKErrorDomain
                                                code:DKErrInjection
                                            userInfo:@{NSLocalizedDescriptionKey: DKErrInjectionDescription}];
            */
            //return NO;
        }

        
        xpc_object_t reply = xpc_dictionary_create_reply(event);
        xpc_dictionary_set_string(reply, "reply", "Hi there, host application!");
        xpc_connection_send_message(remote, reply);
        xpc_release(reply);
	}
}

static void __XPC_Connection_Handler(xpc_connection_t connection)  {
    syslog(LOG_NOTICE, "Configuring message event handler for helper.");
    
	xpc_connection_set_event_handler(connection, ^(xpc_object_t event) {
		__XPC_Peer_Event_Handler(connection, event);
	});
	
	xpc_connection_resume(connection);
}



dispatch_source_t g_timer_source = NULL;




int main(int argc, char *argv[])
{
    xpc_connection_t service = xpc_connection_create_mach_service("com.erwanb.MachInjectSample.Injector",
                                                                  dispatch_get_main_queue(),
                                                                  XPC_CONNECTION_MACH_SERVICE_LISTENER);
    
    if (!service) {
        syslog(LOG_NOTICE, "Failed to create service.");
        exit(EXIT_FAILURE);
    }
    
    syslog(LOG_NOTICE, "Configuring connection event handler for helper");
    xpc_connection_set_event_handler(service, ^(xpc_object_t connection) {
        __XPC_Connection_Handler(connection);
    });
    
    xpc_connection_resume(service);
    
    dispatch_main();
    
    xpc_release(service);
    
    return EXIT_SUCCESS;
   
}
