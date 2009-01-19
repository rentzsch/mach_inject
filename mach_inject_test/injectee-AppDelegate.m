#import "injectee-AppDelegate.h"

@interface NSObject (mach_inject_test_injector_app)
- (void)notifyInjectorReadyForInjection;
- (void)notifyInjectorSuccessfullyInjected;
@end

@implementation injectee_AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification*)notification_ {
	id injector = [NSConnection rootProxyForConnectionWithRegisteredName:@"mach_inject_test_injector_app" host:nil];
	assert( injector );
	[injector notifyInjectorReadyForInjection];
}

- (void)notifyInjecteeSuccessfullyInjected {
	id injector = [NSConnection rootProxyForConnectionWithRegisteredName:@"mach_inject_test_injector_app" host:nil];
	assert( injector );
	[injector notifyInjectorSuccessfullyInjected];
}

@end
