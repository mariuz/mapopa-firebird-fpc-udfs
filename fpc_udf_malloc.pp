unit
	fpc_udf_malloc;

interface

{$IFDEF USE_C_MALLOC}
{$IFDEF UNIX}
function malloc(size: Longint): Pointer; cdecl; external 'libc' name 'malloc';
{$ELSE}
function malloc(size: Longint): Pointer; cdecl; external 'msvcrt' name 'malloc';
{$ENDIF}
{$ELSE}
function malloc(size: Longint): Pointer; cdecl; external 'ib_util' name 'ib_util_malloc';
{$ENDIF}

implementation

end.

