// build@ build-for-test.win32.bat
{
firebird-fpc-udfs unit test file
Copyright (c) 2009 Cosmin Apreutesei

Author:		Cosmin Apreutesei <cosmin.apreutesei@gmail.com>
License:	MIT (see LICENSE.txt)
Homepage:	http://code.google.com/p/firebird-fpc-udfs/

All this code is freepascal in DELPHI dialect!
}

{$LONGSTRINGS ON}
{$MODE DELPHI}
{$ASSERTIONS ON}

uses
    sysutils;

// test funcs
function test_int(var i1, i2: Longint): Longint; cdecl; external 'fpc_udf';
function test_double(var d1, d2: Double): Double; cdecl; external 'fpc_udf';
function test_freeit(s1, s2: PChar): PChar; cdecl; external 'fpc_udf';
function test_retparam(s1: PChar): PChar; cdecl; external 'fpc_udf';
// lib funcs
function sbc_string_replace_chars(search_chars, replace_chars, source: PChar): PChar; cdecl; external 'fpc_udf';
function utf8_string_replace_chars(search_chars, replace_chars, source: PChar): PChar; cdecl; external 'fpc_udf';
function utf8_string_made_of(char_list, source: PChar): Longint; cdecl; external 'fpc_udf';
function md5(token: PChar): PChar; cdecl; external 'fpc_udf';
function bin_to_hex(token: PChar): PChar; cdecl; external 'fpc_udf';
function hex_to_bin(token: PChar): PChar; cdecl; external 'fpc_udf';

{$IFDEF UNIX}
function malloc(size: Longint): Pointer; cdecl; external 'libc' name 'malloc';
{$ELSE}
function malloc(size: Longint): Pointer; cdecl; external 'msvcrt' name 'malloc';
{$ENDIF}

// helpers
function to_cstring(s: string): PChar;
var
    len: Word;
begin
    len := length(s);
    result := malloc(len + 1);
    move(s[1], result^, len);
    result[len] := #0;
end;

function to_varchar(s: string): PChar;
var
    len: Word;
begin
    len := length(s);
    result := malloc(len + 2);
    PWord(result)^ := len;
    move(s[1], result[2], len);
end;

function from_varchar(p: PChar): string;
var
    len: Word;
begin
    len := PWord(p)^;
    SetLength(result, len);
    Move(p[2], result[1], len);
end;

// test routine
var
    p, p2: PChar;
    s: string;
    i1, i2, i3: Longint;
    d1, d2, d3: Double;
begin
	// test test udfs
    i1 := 5; i2 := -5;
    i3 := test_int(i1,i2);
    assert(i3 = i1+i2);

    d1 := 6; d2 := 3;
    d3 := test_double(d1, d2);
    assert(d3 = d1/d2, floattostr(d3) + ' <> ' + floattostr(d1/d2));

    p := test_freeit('123', 'abc');
    assert(p = '123abc');

    // test utf8 udfs
    p := sbc_string_replace_chars(to_cstring(' ;:'), to_cstring('_//'), to_cstring('words: foul; fall; foul'));
    assert(p = 'words/_foul/_fall/_foul');

    p := utf8_string_replace_chars(to_cstring(' ;:'), to_cstring('_//'), to_cstring('words: foul; fall; foul'));
    assert(p = 'words/_foul/_fall/_foul');

    i1 := utf8_string_made_of(to_cstring('abc'), to_cstring('abcccaaaabcbabbabb'));
    assert(i1 = 1);

    // test md5
    p := bin_to_hex(md5(to_cstring('hello'))); //md5 returns varchar, bin_to_hex takes varchar
    s := strupper('5d41402abc4b2a76b9719d911017c592');
    assert(p = s, p + ' <> ' + s);

    // test bin_to_hex & hex_to_bin
    p := to_varchar(chr($ff)+chr(1)+chr($7f));
    p2 := to_cstring('FF017F');
    assert(string(bin_to_hex(p)) = string(p2), bin_to_hex(p) + ' <> ' + p2);
    assert(from_varchar(hex_to_bin(p2)) = from_varchar(p));

end.

