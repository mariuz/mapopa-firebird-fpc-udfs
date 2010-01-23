{
firebird-fpc-udfs utf8 udfs
Copyright (c) 2009 Cosmin Apreutesei

Author:		Cosmin Apreutesei <cosmin.apreutesei@gmail.com>
License:	MIT (see LICENSE.txt)
Homepage:	http://code.google.com/p/firebird-fpc-udfs/

All this code is freepascal in DELPHI dialect!
}

{$LONGSTRINGS ON}
{$MODE DELPHI}

unit
    fpc_udf_utf8;

interface

uses
    fpc_udf_malloc;

function sbc_string_replace_chars(search_chars, replace_chars, source: PChar): PChar; cdecl;
function utf8_string_replace_chars(search_chars, replace_chars, source: PChar): PChar; cdecl;
function utf8_string_made_of(char_list, target: PChar): Longint; cdecl;

implementation

{--- utf8 helpers ---}

function utf8_char_size(p: PChar): Longint;
var
    b: byte;
begin
    b := byte(p[0]);
    if b <= 127 then
        result := 1
    else
    if (b >= $C0) and (b <= $DF) then
        result := 2
    else
    if (b >= $E0) and (b <= $EF) then
        result := 3
    else
    if (b >= $F0) and (b <= $F4) then
        result := 4
    else
        result := 0;
end;

function utf8_advance(p: PChar): PChar;
var
    k: Longint;
begin
    k := utf8_char_size(p);
    if (k > 0) then
        result := @p[k]
    else
        result := nil;
end;

function utf8_string_length(p: PChar): LongInt;
var
    k: LongInt;
begin
    result := 0;
    if p = nil then
        exit;

    k := 0;
    while p[0] <> #0 do
    begin
        inc(k);
        p := utf8_advance(p);
        if p = nil then
            exit;
    end;
    result := k;
end;

function utf8_char_equal(p1, p2: PChar): Boolean;
var
    l1, l2: Longint;
begin
    l1 := utf8_char_size(p1);
    l2 := utf8_char_size(p2);
    result := (l1 <> 0) and (l1 = l2) and (CompareByte(p1[0], p2[0], l1) = 0);
end;

function utf8_char_copy(target, source: PChar): PChar;
var
    cs: Longint;
begin
    cs := utf8_char_size(source);
    if (cs > 0) then
    begin
        Move(source[0], target[0], cs);
        result := @target[cs];
    end
    else
        result := nil;
end;

{--- utf8 UDFs ---}

// declare ... cstring(N) charset <any-single-byte-charset> null, ... returns parameter 3 ...
function sbc_string_replace_chars(search_chars, replace_chars, source: PChar): PChar; cdecl; export;
var
    s, r, t: PChar;
begin
    if (search_chars = nil) or (replace_chars = nil) or (source = nil) then
        result := nil
    else
    begin
        result := source;
        t := source;
        while t[0] <> #0 do
        begin
            s := search_chars;
            r := replace_chars;
            while (s[0] <> #0) and (r[0] <> #0) do
            begin
                if t[0] = s[0] then
                begin
            	    t[0] := r[0];
                    break;
                end;
                s := @s[1];
                // we allow replace_chars to be shorter than search_chars, in which case
                // we use the last char of replace_chars.
                if (r[1] <> #0) then
                    r := @r[1];
            end;
            t := @t[1];
        end;
    end;
end;

// declare ... cstring(N) charset utf8 null, ... returns cstring(N) charset utf8 free_it
function utf8_string_replace_chars(search_chars, replace_chars, source: PChar): PChar; cdecl; export;
var
    s, r, test_s, test_r, sp, rp: PChar;
    slen: LongInt;
begin
    if (search_chars = nil) or (replace_chars = nil) or (source = nil) then
    begin
        result := nil;
        exit;
    end;

    slen := utf8_string_length(source);
    result := malloc(slen*4 + 1);

    sp := source;
    rp := result;

    while sp[0] <> #0 do
    begin
        s := search_chars;
        r := replace_chars;
        while (s[0] <> #0) and (r[0] <> #0) do
        begin
            if utf8_char_equal(sp, s) then
            begin
                rp := utf8_char_copy(rp, r);
                break;
            end;
            test_s := utf8_advance(s); if test_s = nil then exit;
            if test_s[0] = #0 then
                rp := utf8_char_copy(rp, sp);
            s := test_s;
            // we allow replace_chars to be shorter than search_chars, in which case
            // we use the last char of replace_chars.
            test_r := utf8_advance(r); if test_r = nil then exit;
            if test_r[0] <> #0 then
                r := test_r;
        end;
        sp := utf8_advance(sp); if sp = nil then exit;
    end;
    rp[0] := #0;
end;

// declare ... cstring(N) charset utf8 null, ... returns integer by value
function utf8_string_made_of(char_list, target: PChar): Longint; cdecl; export;
var
    p: PChar;
begin
    utf8_string_made_of := 0;
    if (char_list = nil) or (target = nil) then
        exit;
    while target[0] <> #0 do
    begin
        p := char_list;
        while p[0] <> #0 do
            if utf8_char_equal(target, p) then
                break
            else
                p := utf8_advance(p);
        if p[0] = #0 then exit;
        target := utf8_advance(target);
        if target = nil then exit;
    end;
    utf8_string_made_of := 1;
end;

end.
