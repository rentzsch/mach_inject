/*******************************************************************************
	mach_inject_bundle_stub.h
		Copyright (c) 2003-2009 Jonathan 'Wolf' Rentzsch: <http://rentzsch.com>
		Some rights reserved: <http://opensource.org/licenses/mit-license.php>
		
	Design inspired by SCPatchLoader, by Jon Gotow of St. Clair Software:
		<http://www.stclairsoft.com>

	***************************************************************************/

#ifndef		_mach_inject_bundle_stub_
#define		_mach_inject_bundle_stub_

#include <stddef.h> // for ptrdiff_t

typedef	struct	{
	ptrdiff_t	codeOffset;
	char		bundlePackageFileSystemRepresentation[1];
}	mach_inject_bundle_stub_param;

#endif	//	_mach_inject_bundle_stub_