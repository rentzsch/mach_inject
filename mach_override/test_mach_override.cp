#include <stdio.h>
#include <assert.h>
#include <string.h>
#include <errno.h>
#include "mach_override.h"

#define	assertStrEqual( EXPECTED, ACTUAL ) if( strcmp( (EXPECTED), (ACTUAL) ) != 0 ) { printf( "EXPECTED: %s\nACTUAL: %s\n", (EXPECTED), (ACTUAL)); assert( strcmp( (EXPECTED), (ACTUAL) ) == 0 ); }
#define	assertIntEqual( EXPECTED, ACTUAL ) if( (EXPECTED) != (ACTUAL) ) { printf( "EXPECTED: %d\nACTUAL: %d\n", (EXPECTED), (ACTUAL)); assert( (EXPECTED) == (ACTUAL) ); }

//------------------------------------------------------------------------------
#pragma mark Test Local Override by Pointer

const char* localFunction() {
	asm("nop;nop;nop;nop;");
	return __FUNCTION__;
}
const char* (*localOriginalPtr)() = localFunction;

void testLocalFunctionOverrideByPointer() {
	//	Test original.
	assertStrEqual( "localFunction", localOriginalPtr() );

	//	Override local function by pointer.
	kern_return_t err;
	
	MACH_OVERRIDE( const char*, localFunction, (), err ) {
		//	Test calling through the reentry island back into the original
		//	implementation.
		assertStrEqual( "localFunction", localFunction_reenter() );
		
		return "localFunctionOverride";
	} END_MACH_OVERRIDE(localFunction);
	assert( !err );
	
	//	Test override took effect.
	assertStrEqual( "localFunctionOverride", localOriginalPtr() );
}

//------------------------------------------------------------------------------
#pragma mark Test System Override by Pointer

char* (*strerrorPtr)(int) = strerror;

void testSystemFunctionOverrideByPointer() {
	//	Test original.
	assertStrEqual( "Unknown error: 0", strerrorPtr( 0 ) );
	
	//	Override system function by pointer.
	kern_return_t err;
	MACH_OVERRIDE( char*, strerror, (int errnum), err ) {
		//	Test calling through the reentry island back into the original
		//	implementation.
		assertStrEqual( "Unknown error: 0", strerror_reenter( 0 ) );
		
		return (char *)"strerrorOverride";
	} END_MACH_OVERRIDE(strerror);
	assert( !err );
	
	//	Test override took effect.
	assertStrEqual( "strerrorOverride", strerrorPtr( 0 ) );
}

//------------------------------------------------------------------------------
#pragma mark Test System Override by Name

int strerror_rOverride( int errnum, char *strerrbuf, size_t buflen );
int (*strerror_rPtr)( int, char*, size_t ) = strerror_r;
int (*gReentry_strerror_r)( int, char*, size_t );

void testSystemFunctionOverrideByName() {
	//	Test original.
	assertIntEqual( ERANGE, strerror_rPtr( 0, NULL, 0 ) );
	
	//	Override local function by pointer.
	kern_return_t err = mach_override( (char*)"_strerror_r",
									   NULL,
									   (void*)&strerror_rOverride,
									   (void**)&gReentry_strerror_r );
	
	//	Test override took effect.
	assertIntEqual( 0, strerror_rPtr( 0, NULL, 0 ) );
}

int strerror_rOverride( int errnum, char *strerrbuf, size_t buflen ) {
	assertIntEqual( ERANGE, gReentry_strerror_r( 0, NULL, 0 ) );
	
	return 0;
}

//------------------------------------------------------------------------------
#pragma mark main

int main( int argc, const char *argv[] ) {
	testLocalFunctionOverrideByPointer();
	testSystemFunctionOverrideByPointer();
	testSystemFunctionOverrideByName();
	
	printf( "success\n" );
	return 0;
}
