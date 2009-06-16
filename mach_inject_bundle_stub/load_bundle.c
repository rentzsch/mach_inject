/*******************************************************************************
	load_bundle.c
		Copyright (c) 2003-2009 Jonathan 'Wolf' Rentzsch: <http://rentzsch.com>
		Some rights reserved: <http://opensource.org/licenses/mit-license.php>

	***************************************************************************/

#include "load_bundle.h"
#include <CoreServices/CoreServices.h>
#include <sys/syslimits.h> // for PATH_MAX.
#include <mach-o/dyld.h>
#include <dlfcn.h>

	mach_error_t
load_bundle_package(
		const char *bundlePackageFileSystemRepresentation )
{
	printf("LBP\n");
	assert( bundlePackageFileSystemRepresentation );
	assert( strlen( bundlePackageFileSystemRepresentation ) );
	
	mach_error_t err = err_none;
	mach_error("mach error on bundle load", err);

	//	Morph the FSR into a URL.
	CFURLRef bundlePackageURL = NULL;
	if( !err ) {
		bundlePackageURL = CFURLCreateFromFileSystemRepresentation(
			kCFAllocatorDefault,
			(const UInt8*)bundlePackageFileSystemRepresentation,
			strlen(bundlePackageFileSystemRepresentation),
			true );
		if( bundlePackageURL == NULL )
			err = err_load_bundle_url_from_path;
	}
	mach_error("mach error on bundle load", err);

	//	Create bundle.
	CFBundleRef bundle = NULL;
	if( !err ) {
		bundle = CFBundleCreate( kCFAllocatorDefault, bundlePackageURL );
		if( bundle == NULL )
			err = err_load_bundle_create_bundle;
	}
	mach_error("mach error on bundle load", err);

	//	Discover the bundle's executable file.
	CFURLRef bundleExecutableURL = NULL;
	if( !err ) {
		assert( bundle );
		bundleExecutableURL = CFBundleCopyExecutableURL( bundle );
		if( bundleExecutableURL == NULL )
			err = err_load_bundle_package_executable_url;
	}
	mach_error("mach error on bundle load", err);

	//	Morph the executable's URL into an FSR.
	char bundleExecutableFileSystemRepresentation[PATH_MAX];
	if( !err ) {
		assert( bundleExecutableURL );
		if( !CFURLGetFileSystemRepresentation(
			bundleExecutableURL,
			true,
			(UInt8*)bundleExecutableFileSystemRepresentation,
			sizeof(bundleExecutableFileSystemRepresentation) ) )
		{
			err = err_load_bundle_path_from_url;
		}
	}
	mach_error("mach error on bundle load", err);

	//	Do the real work.
	if( !err ) {
		assert( strlen(bundleExecutableFileSystemRepresentation) );
		err = load_bundle_executable( bundleExecutableFileSystemRepresentation);
	}
	
	//	Clean up.
	if( bundleExecutableURL )
		CFRelease( bundleExecutableURL );
	/*if( bundle )
		CFRelease( bundle );*/
	if( bundlePackageURL )
		CFRelease( bundlePackageURL );
	
	mach_error("mach error on bundle load", err);
	return err;
}

	mach_error_t
load_bundle_executable(
		const char *bundleExecutableFileSystemRepresentation )
{
	assert( bundleExecutableFileSystemRepresentation );
	
	printf("FS rep %s\n", bundleExecutableFileSystemRepresentation);
	void *image = dlopen(bundleExecutableFileSystemRepresentation, RTLD_NOW);
	printf("OH shit load? %p\n", image);
	if (!image) {
		dlerror();
		return err_load_bundle_NSObjectFileImageFailure;
	}
	return 0;
}