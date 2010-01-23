// build@ build.win32.bat
{
firebird-fpc-udfs main source file
Copyright (c) 2009 Cosmin Apreutesei

Author:		Cosmin Apreutesei <cosmin.apreutesei@gmail.com>
License:	MIT (see LICENSE.txt)
Homepage:	http://code.google.com/p/firebird-fpc-udfs/

All this code is freepascal in DELPHI dialect!

See http://code.google.com/p/firebird-lua-udfs/wiki/UdfWritingTips
for tips and how understand this code.
}

{$LONGSTRINGS ON}
{$MODE DELPHI}

library fpc_udf;

uses
    {$IFDEF UNIX}
    cthreads, // must be included before anything else for multithreaded apps, hell knows why
    {$ENDIF}
    md5,
    classes,
    fpc_udf_malloc,
    fpc_udf_utf8,
    sysutils;

const
    // ParamDsc.dsc_dtype
    DTYPE_UNKNOWN = 0;
    DTYPE_TEXT    = 1;  // CHAR; dsc_length = length of the field, not content; actual length must be computed by trimming the padding spaces.
    DTYPE_CSTRING = 2;  // CSTRING; dsc_length = length of the field, not content + 1; actual length must be computed with strlen()
    DTYPE_VARYING = 3;  // VARCHAR; dsc_length = length of the field, not content + 2; actual length is at dsc_address[0]; content is at dsc_address[2] !
    DTYPE_PACKED  = 6;
    DTYPE_BYTE    = 7;  // ?
    DTYPE_SHORT   = 8;  // SMALLINT ?
    DTYPE_LONG    = 9;  // INTEGER ?
    DTYPE_QUAD    = 10;
    DTYPE_REAL    = 11;
    DTYPE_DOUBLE  = 12; // DOUBLE PRECISION ?
    DTYPE_D_FLOAT = 13;
    DTYPE_SQL_DATE = 14;
    DTYPE_SQL_TIME = 15;
    DTYPE_TIMESTAMP = 16;
    DTYPE_BLOB    = 17;
    DTYPE_ARRAY   = 18;
    DTYPE_INT64   = 19;

    // ParamDsc.dsc_sub_type for text types
    DSC_TEXT_TYPE_NONE      = 0; // normal text
    DSC_TEXT_TYPE_FIXED     = 1; // can have #0 in it
    DSC_TEXT_TYPE_METADATA  = 2; // for metadata

    // ParamDsc.dsc_sub_type for dsc_dtype in (short, long, quad)
    DSC_NUM_TYPE_NONE       = 0; // SMALLINT or INTEGER
    DSC_NUM_TYPE_NUMERIC    = 1; // NUMERIC(n,m)
    DSC_NUM_TYPE_DECIMAL    = 2; // DECIMAL(n,m)

    // ParamDsc.dsc_flags
    DSC_NULL        = 1;
    DSC_NO_SUBTYPE  = 2;
    DSC_NULLABLE    = 3;

type
  ParamDsc = record
    dsc_dtype   : Byte;             // one of DTYPE_* (sure is not a bitmask?)
    dsc_scale   : ShortInt;         // where's precision?
    dsc_length  : Word;             // size of buffer, including trailing #0, etc.
    dsc_sub_type: SmallInt;         // one of DSC_*_TYPE
    dsc_flags   : Word;             // a bitmask of DSC_* constants
    dsc_address : Pointer;          // a cstring begins as dsc_address[2] !!
  end;
  PParamDsc = ^ParamDsc;

{--- test udfs ---}

// declare ... integer, <idem> returns integer by value ...
function test_int(var i1, i2: Longint): Longint; cdecl; export;
begin
    result := i1 + i2;
end;

// declare ... double precision, <idem> returns double precision by value ...
function test_double(var d1, d2: Double): Double; cdecl; export;
begin
    result := d1 / d2; // OBS: when d2 = 0 you get INF, instead of a div-by-zero error.
end;

// declare ... cstring(N) chaset <any-single-byte-charset> null, <idem> returns cstring(2*N) free_it ...
function test_freeit(s1, s2: PChar): PChar; cdecl; export;
begin
    if (s1 = nil) or (s2 = nil) then
    begin
        result := nil;
        exit;
    end;
    result := malloc(strlen(s1) + strlen(s2) + 1);
    Move(s1^, result^, strlen(s1));
    Move(s2^, result[strlen(s1)], strlen(s2));
    result[strlen(s1) + strlen(s2)] := #0;
end;

// declare ... cstring( >= Length(s) ) null returns parameter 1 ...
function test_retparam(s1: PChar): PChar; cdecl; export;
var
    s: string;
begin
    if s1 = nil then
    begin
        result := nil;
        exit;
    end;
    result := s1;
    s := 'TEST OK';
    Move(result^, s[1], Length(s));
    result[Length(s)] := #0;
end;

// declare ... integer by descriptor, integer by descriptor returns integer by value ...
function test_paramdsc(i1, i2: PParamDsc): Longint; cdecl; export;
begin
    result := -1;
    if (i1 = nil) or ((i1^.dsc_flags and DSC_NULL) <> 0) then
        exit;
    if (i2 = nil) or ((i2^.dsc_flags and DSC_NULL) <> 0) then
        exit;

    result := PLongint(i1^.dsc_address)^ + PLongint(i2^.dsc_address)^;
end;

{--- paramdsc helpers ---}

function paramdsc_is_null(p: PParamDsc): boolean;
begin
    result := (p = nil) or (p^.dsc_address = nil) or (p^.dsc_flags and DSC_NULL <> 0);
end;

function paramdsc_field_length(p: PParamDsc): Longint;
begin
    case p^.dsc_dtype of
        DTYPE_TEXT: result := p^.dsc_length;
        DTYPE_CSTRING: result := p^.dsc_length - 1;
        DTYPE_VARYING:  result := p^.dsc_length - 2;
    else
        result := 0;
    end;
end;

function paramdsc_text_length(p: PParamDsc): Longint;
begin
    case p^.dsc_dtype of
        DTYPE_TEXT: result := p^.dsc_length;  // we shall not look at padding spaces!
        DTYPE_CSTRING: result := strlen(p^.dsc_address);
        DTYPE_VARYING: result := PWord(p^.dsc_address)^;
    else
        result := 0;
    end;
end;

function paramdsc_text_pointer(P: PParamDsc): PChar;
begin
    case p^.dsc_dtype of
        DTYPE_TEXT: result := p^.dsc_address;
        DTYPE_CSTRING: result := p^.dsc_address;
        DTYPE_VARYING: result := p^.dsc_address + 2;
    else
        result := nil;
    end;
end;

function paramdsc_is_text(p: PParamDsc): boolean;
begin
    result := (p^.dsc_dtype >= DTYPE_TEXT) and (p^.dsc_dtype <= DTYPE_VARYING);
end;

function paramdsc_is_date(p: PParamDsc): boolean;
begin
    result := (p^.dsc_dtype >= DTYPE_SQL_DATE) and (p^.dsc_dtype <= DTYPE_TIMESTAMP);
end;

{--- utility udfs ---}

// declare ... cstring(N) charset <any-charset> null, ... returns varchar(16) charset octets free_it ...
function md5(token: PChar): PChar; cdecl; export;
begin
    result := nil;
    if (token = nil) then
        exit;

    result := malloc(2 + 16);
    Move(MD5String(token), result[2], 16);
    PWord(result)^ := 16;
end;

// declare ... varchar(N) charset octets null returns cstring(N*2) charset <any-sbc-or-utf8> free_it ...
function bin_to_hex(token: PChar): PChar; cdecl; export;
var
    len: Longint;
begin
    result := nil;
    if (token = nil) then
        exit;

    len := PWord(token)^;
    result := malloc(len*2 + 1);
    BinToHex(@token[2], result, len);
    result[len*2] := #0;
end;

// declare ... cstring(N) charset <any-sbc> null returns varchar(N/2) charset octets free_it
function hex_to_bin(token: PChar): PChar; cdecl; export;
var
    len: Longint;
begin
    result := nil;
    if (token = nil) then
        exit;

    len := strlen(token);
    if len mod 2 <> 0 then
        exit;

    result := malloc(2 + len div 2);
    PWord(result)^ := HexToBin(token, @result[2], len div 2);
end;

// declare ... cstring(N) charset <any-sbc> null returns integer by value
function file_is_readable(path: PChar): Longint; cdecl; export;
begin
   result := 0;
   if (path = nil) then
       exit;

   // TODO: for UNIX, also test if file is readable!!
   if FileExists(path) then result := 1 else result := 0;
end;


{--- applib stuff starts here ---}

exports
    // test udfs
    test_int,
    test_double,
    test_freeit,
    test_retparam,
    test_paramdsc,
    // utf8 udfs
    sbc_string_replace_chars,
    utf8_string_replace_chars,
    utf8_string_made_of,
    // utility udfs
    md5,
    bin_to_hex,
    hex_to_bin,
    file_is_readable
;

begin
    //this is required when loaded from firebird for UDFs.
    //in linux, don't forget to include cthreads before anything else!
    IsMultiThread := True;

end.

