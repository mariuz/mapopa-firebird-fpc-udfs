DECLARE EXTERNAL FUNCTION ASCII_STRING_REPLACE_CHARS
    CSTRING(4096) CHARACTER SET ASCII,
    CSTRING(4096) CHARACTER SET ASCII,
    CSTRING(4096) CHARACTER SET ASCII
    RETURNS PARAMETER 3
    ENTRY_POINT 'sbc_string_replace_chars' MODULE_NAME 'fpc_udf';

COMMENT ON EXTERNAL FUNCTION ASCII_STRING_REPLACE_CHARS IS
'ascii_string_replace_chars(search_chars, replace_chars, target): result

- replaces search_chars[n] with replace_chars[n] form target[m], and returns the resulting string.
- replace_chars can be shorter than search_chars, in which case the last character of replace_chars is used.
- the parameters can be declared with any single-byte charset and collation, not only ascii.';

DECLARE EXTERNAL FUNCTION UTF8_STRING_REPLACE_CHARS
    CSTRING(4096) CHARACTER SET UTF8,
    CSTRING(4096) CHARACTER SET UTF8,
    CSTRING(4096) CHARACTER SET UTF8
    RETURNS CSTRING(4096) CHARACTER SET UTF8 FREE_IT
    ENTRY_POINT 'utf8_string_replace_chars' MODULE_NAME 'fpc_udf';

COMMENT ON EXTERNAL FUNCTION UTF8_STRING_REPLACE_CHARS IS
'utf8_string_replace_chars(search_chars, replace_chars, target): result

- replaces search_chars[n] with replace_chars[n] form target[m], and returns the resulting string.
- replace_chars can be shorter than search_chars, in which case the last character of replace_chars is used.';

DECLARE EXTERNAL FUNCTION UTF8_STRING_REPLACE_BUT_CHARS
    CSTRING(4096) CHARACTER SET UTF8,
    CSTRING(4096) CHARACTER SET UTF8,
    CSTRING(4096) CHARACTER SET UTF8
    RETURNS CSTRING(4096) CHARACTER SET UTF8 FREE_IT
    ENTRY_POINT 'utf8_string_replace_but_chars' MODULE_NAME 'fpc_udf';

COMMENT ON EXTERNAL FUNCTION UTF8_STRING_REPLACE_BUT_CHARS IS
'utf8_string_replace_but_chars(leave_chars, replace_chars, target): result

- replaces characters different than leave_chars[n] with replace_chars form target[m], and returns the resulting string.';

DECLARE EXTERNAL FUNCTION UTF8_STRING_MADE_OF
    CSTRING(4096) CHARACTER SET UTF8,
    CSTRING(4096) CHARACTER SET UTF8
    RETURNS INTEGER BY VALUE
    ENTRY_POINT 'utf8_string_made_of' MODULE_NAME 'fpc_udf';

COMMENT ON EXTERNAL FUNCTION UTF8_STRING_MADE_OF IS
'utf8_string_made_of(char_list, target): boolean

returns true if target contains only of characters from char_list.';

