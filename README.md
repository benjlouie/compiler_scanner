README file for Programming Assignment 2 (C++ edition)
=====================================================

Your directory should now contain the following files:

 README                                 | readme (this file)
 cool.flex                              | flex scanner file
 test_files/                            | directory (duh)
    acc_accepted_weird.cl               | accepted by lexer only
    acc_hairyscary.cl                   | completely accepted
    acc_hello_yen.cl                    | completely accepted
    acc_no_whitespace.cl                | completely accepted
    acc_tokens.cl                       | accepted by lexer only
    err_hello_yen_with_break.cl         | should error on unescaped newline
    err_non-chars.cl                    | characters not accepted by cool
    err_strings.cl                      | tests for errors in strings
    err_too_long.cl                     | string limit test
    test.cl                             | full test for complete compiler

The include (.h) files for this assignment can be found in 
[course dir]/include/PA2

	The Makefile contains targets for compiling and running your
	program. (remove -R and its arguments to compile)

Write-up for PA2
----------------

cool.flex:
Makes use of <ctype.h> and <vector> to properly process strings.
We defined regular expressions for everything found in the cool language.
This includes expressions for things not in the cool language that we use to catch errors.
On finding one of these expressions in the passed in file, most rules simply output the text properly formatted.
There are certain cases where this is not true. Multi-line comments are ignored, except for the newline characters.
Whitespace is completely ignored. Inline comments are also ignored, except for the newline.
Strings are heavily modified. They grab the string and account for all possible errors with that string.
This includes strings containing null characters, unterminated strings, octal conversions, escaped character conversions, and unescaped newlines.
Miscellaneous characters are grabbed and an error is reported.

test_files/*:
All files used to test the output of our scanner. Files that start with "acc" are accepted by either just the lexer or the entire compiler.
Files that start with "err" properly run with the lexer, but generate the appropriate error messages.
test.cl contains a full program that should work with every level of the compiler. Also contains every token that cool should accept.

Our scanner was tested correctly with all files against Stanford's lexer provided in the virtual machine.
Our lexer even did better than Stanford's lexer, which output line numbers incorrectly for unterminated newlines in strings.




















