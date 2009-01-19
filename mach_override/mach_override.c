/*******************************************************************************
	mach_override.c
		Copyright (c) 2003-2005 Jonathan 'Wolf' Rentzsch: <http://rentzsch.com>
		Some rights reserved: <http://creativecommons.org/licenses/by/2.0/>

	***************************************************************************/

#include "mach_override.h"

#include <mach-o/dyld.h>
#include <mach/mach_host.h>
#include <mach/mach_init.h>
#include <mach/vm_map.h>
#include <sys/mman.h>

#include <CoreServices/CoreServices.h>

/**************************
*	
*	Constants
*	
**************************/
#pragma mark	-
#pragma mark	(Constants)

#if !defined(__ppc__) && !defined(__POWERPC__)
	#error "this code is currently PowerPC-only"
#endif

long kIslandTemplate[] = {
	0x9001FFFC,	//	stw		r0,-4(SP)
	0x3C00DEAD,	//	lis		r0,0xDEAD
	0x6000BEEF,	//	ori		r0,r0,0xBEEF
	0x7C0903A6,	//	mtctr	r0
	0x8001FFFC,	//	lwz		r0,-4(SP)
	0x60000000,	//	nop		; optionally replaced
	0x4E800420 	//	bctr
};
#define kAddressHi			3
#define kAddressLo			5
#define kInstructionHi		10
#define kInstructionLo		11

#define	kAllocateHigh		1
#define	kAllocateNormal		0

/**************************
*	
*	Data Types
*	
**************************/
#pragma mark	-
#pragma mark	(Data Types)

typedef	struct	{
	char	instructions[sizeof(kIslandTemplate)];
	int		allocatedHigh;
}	BranchIsland;

/**************************
*	
*	Funky Protos
*	
**************************/
#pragma mark	-
#pragma mark	(Funky Protos)

	mach_error_t
allocateBranchIsland(
		BranchIsland	**island,
		int				allocateHigh );

	mach_error_t
freeBranchIsland(
		BranchIsland	*island );

	mach_error_t
setBranchIslandTarget(
		BranchIsland	*island,
		const void		*branchTo,
		long			instruction );

/*******************************************************************************
*	
*	Interface
*	
*******************************************************************************/
#pragma mark	-
#pragma mark	(Interface)

	mach_error_t
mach_override(
		char *originalFunctionSymbolName,
		const char *originalFunctionLibraryNameHint,
		const void *overrideFunctionAddress,
		void **originalFunctionReentryIsland )
{
	assert( originalFunctionSymbolName );
	assert( strlen( originalFunctionSymbolName ) );
	assert( overrideFunctionAddress );
	
	//	Lookup the original function's code pointer.
	long	*originalFunctionPtr;
	if( originalFunctionLibraryNameHint )
		_dyld_lookup_and_bind_with_hint(
			originalFunctionSymbolName,
			originalFunctionLibraryNameHint,
			(void*) &originalFunctionPtr,
			NULL );
	else
		_dyld_lookup_and_bind(
			originalFunctionSymbolName,
			(void*) &originalFunctionPtr,
			NULL );
	
	return mach_override_ptr( originalFunctionPtr, overrideFunctionAddress,
		originalFunctionReentryIsland );
}

    mach_error_t
mach_override_ptr(
		void *originalFunctionAddress,
		const void *overrideFunctionAddress,
		void **originalFunctionReentryIsland )
{
	assert( originalFunctionAddress );
	assert( overrideFunctionAddress );
	
	long	*originalFunctionPtr = (long*) originalFunctionAddress;
	mach_error_t	err = err_none;
	
	//	Ensure first instruction isn't 'mfctr'.
	#define	kMFCTRMask			0xfc1fffff
	#define	kMFCTRInstruction	0x7c0903a6
	
	long	originalInstruction = *originalFunctionPtr;
	if( !err && ((originalInstruction & kMFCTRMask) == kMFCTRInstruction) )
		err = err_cannot_override;
	
	//	Make the original function implementation writable.
	if( !err ) {
		err = vm_protect( mach_task_self(),
				(vm_address_t) originalFunctionPtr,
				sizeof(long), false, (VM_PROT_ALL | VM_PROT_COPY) );
		if( err )
			err = vm_protect( mach_task_self(),
					(vm_address_t) originalFunctionPtr, sizeof(long), false,
					(VM_PROT_DEFAULT | VM_PROT_COPY) );
	}
	
	//	Allocate and target the escape island to the overriding function.
	BranchIsland	*escapeIsland = NULL;
	if( !err )	
		err = allocateBranchIsland( &escapeIsland, kAllocateHigh );
	if( !err )
		err = setBranchIslandTarget( escapeIsland, overrideFunctionAddress, 0 );
	
	//	Build the branch absolute instruction to the escape island.
	long	branchAbsoluteInstruction = 0; // Set to 0 just to silence warning.
	if( !err ) {
		long escapeIslandAddress = ((long) escapeIsland) & 0x3FFFFFF;
		branchAbsoluteInstruction = 0x48000002 | escapeIslandAddress;
	}
	
	//	Optionally allocate & return the reentry island.
	BranchIsland	*reentryIsland = NULL;
	if( !err && originalFunctionReentryIsland ) {
		err = allocateBranchIsland( &reentryIsland, kAllocateNormal );
		if( !err )
			*originalFunctionReentryIsland = reentryIsland;
	}
	
	//	Atomically:
	//	o If the reentry island was allocated:
	//		o Insert the original instruction into the reentry island.
	//		o Target the reentry island at the 2nd instruction of the
	//		  original function.
	//	o Replace the original instruction with the branch absolute.
	if( !err ) {
		int escapeIslandEngaged = false;
		do {
			if( reentryIsland )
				err = setBranchIslandTarget( reentryIsland,
						(void*) (originalFunctionPtr+1), originalInstruction );
			if( !err ) {
				escapeIslandEngaged = CompareAndSwap( originalInstruction,
										branchAbsoluteInstruction,
										(UInt32*)originalFunctionPtr );
				if( !escapeIslandEngaged ) {
					//	Someone replaced the instruction out from under us,
					//	re-read the instruction, make sure it's still not
					//	'mfctr' and try again.
					originalInstruction = *originalFunctionPtr;
					if( (originalInstruction & kMFCTRMask) == kMFCTRInstruction)
						err = err_cannot_override;
				}
			}
		} while( !err && !escapeIslandEngaged );
	}
	
	//	Clean up on error.
	if( err ) {
		if( reentryIsland )
			freeBranchIsland( reentryIsland );
		if( escapeIsland )
			freeBranchIsland( escapeIsland );
	}
	
	return err;
}

/*******************************************************************************
*	
*	Implementation
*	
*******************************************************************************/
#pragma mark	-
#pragma mark	(Implementation)

/***************************************************************************//**
	Implementation: Allocates memory for a branch island.
	
	@param	island			<-	The allocated island.
	@param	allocateHigh	->	Whether to allocate the island at the end of the
								address space (for use with the branch absolute
								instruction).
	@result					<-	mach_error_t

	***************************************************************************/

	mach_error_t
allocateBranchIsland(
		BranchIsland	**island,
		int				allocateHigh )
{
	assert( island );
	
	mach_error_t	err = err_none;
	
	if( allocateHigh ) {
		vm_size_t pageSize;
		err = host_page_size( mach_host_self(), &pageSize );
		if( !err ) {
			assert( sizeof( BranchIsland ) <= pageSize );
			vm_address_t first = 0xfeffffff;
			vm_address_t last = 0xfe000000 + pageSize;
			vm_address_t page = first;
			int allocated = 0;
			vm_map_t task_self = mach_task_self();
			
			while( !err && !allocated && page != last ) {
				err = vm_allocate( task_self, &page, pageSize, 0 );
				if( err == err_none )
					allocated = 1;
				else if( err == KERN_NO_SPACE ) {
					page += pageSize;
					err = err_none;
				}
			}
			if( allocated )
				*island = (void*) page;
			else if( !allocated && !err )
				err = KERN_NO_SPACE;
		}
	} else {
		void *block = malloc( sizeof( BranchIsland ) );
		if( block )
			*island = block;
		else
			err = KERN_NO_SPACE;
	}
	if( !err )
		(**island).allocatedHigh = allocateHigh;
	
	return err;
}

/***************************************************************************//**
	Implementation: Deallocates memory for a branch island.
	
	@param	island	->	The island to deallocate.
	@result			<-	mach_error_t

	***************************************************************************/

	mach_error_t
freeBranchIsland(
		BranchIsland	*island )
{
	assert( island );
	assert( (*(long*)&island->instructions[0]) == kIslandTemplate[0] );
	assert( island->allocatedHigh );
	
	mach_error_t	err = err_none;
	
	if( island->allocatedHigh ) {
		vm_size_t pageSize;
		err = host_page_size( mach_host_self(), &pageSize );
		if( !err ) {
			assert( sizeof( BranchIsland ) <= pageSize );
			err = vm_deallocate(
					mach_task_self(),
					(vm_address_t) island, pageSize );
		}
	} else {
		free( island );
	}
	
	return err;
}

/***************************************************************************//**
	Implementation: Sets the branch island's target, with an optional
	instruction.
	
	@param	island		->	The branch island to insert target into.
	@param	branchTo	->	The address of the target.
	@param	instruction	->	Optional instruction to execute prior to branch. Set
							to zero for nop.
	@result				<-	mach_error_t

	***************************************************************************/

	mach_error_t
setBranchIslandTarget(
		BranchIsland	*island,
		const void		*branchTo,
		long			instruction )
{
	//	Copy over the template code.
    bcopy( kIslandTemplate, island->instructions, sizeof( kIslandTemplate ) );
    
    //	Fill in the address.
    ((short*)island->instructions)[kAddressLo] = ((long) branchTo) & 0x0000FFFF;
    ((short*)island->instructions)[kAddressHi]
    	= (((long) branchTo) >> 16) & 0x0000FFFF;
    
    //	Fill in the (optional) instuction.
    if( instruction != 0 ) {
        ((short*)island->instructions)[kInstructionLo]
        	= instruction & 0x0000FFFF;
        ((short*)island->instructions)[kInstructionHi]
        	= (instruction >> 16) & 0x0000FFFF;
    }
    
    //MakeDataExecutable( island->instructions, sizeof( kIslandTemplate ) );
	msync( island->instructions, sizeof( kIslandTemplate ), MS_INVALIDATE );
    
    return err_none;
}