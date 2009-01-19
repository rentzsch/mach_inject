#import "injector-AppDelegate.h"
#import <mach_inject_bundle/mach_inject_bundle.h>

NSTask *gInjecteeTask;

@interface NSObject (mach_inject_test_injected_bundle)
- (unsigned)testInjectedBundle;
@end

@interface mach_inject_test_injector_app : NSObject {}
- (void)notifyInjectorReadyForInjection;
@end
@implementation mach_inject_test_injector_app
- (void)notifyInjectorReadyForInjection {
	NSString *injectedBundlePath = [[NSBundle mainBundle] pathForResource:@"mach_inject_test_injected"
																   ofType:@"bundle"];
	assert( injectedBundlePath );
	
	mach_error_t err = mach_inject_bundle_pid( [injectedBundlePath fileSystemRepresentation],
											   [gInjecteeTask processIdentifier] );
	assert( !err );
}
- (void)notifyInjectorSuccessfullyInjected {
	id injectedBundle = [NSConnection rootProxyForConnectionWithRegisteredName:@"mach_inject_test_injected_bundle" host:nil];
	assert( injectedBundle );
	assert( 42 == [injectedBundle testInjectedBundle] );
	
	[gInjecteeTask terminate];
	[NSApp terminate:nil];
}
@end

@implementation injector_AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification*)notification_ {
	NSConnection *connection = [[NSConnection defaultConnection] retain];
    [connection setRootObject:[[[mach_inject_test_injector_app alloc] init] autorelease]];
    [connection registerName:[[connection rootObject] className]];
	
	assert( ![NSConnection rootProxyForConnectionWithRegisteredName:@"mach_inject_test_injected_bundle" host:nil] );
	
	NSString *injecteeAppPath = [[NSBundle mainBundle] pathForResource:@"mach_inject_test_injectee"
																ofType:@"app"];
	assert( injecteeAppPath );
	gInjecteeTask = [NSTask launchedTaskWithLaunchPath:[injecteeAppPath stringByAppendingString:@"/Contents/MacOS/mach_inject_test_injectee"]
											 arguments:[NSArray array]];
	assert( gInjecteeTask );
}

@end
