/*
 *  The scanner definition for COOL.
 */

/*
 *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
 *  output, so headers and global definitions are placed here to be visible
 * to the code in the file.  Don't remove anything that was here initially
 */
%{
#include "../src/ast.h"
#ifdef __linux__
#include "../bin/parser_cool.h"
#else
#include "../compiler_parser/cool.tab.h"
#endif
#include <ctype.h>
#include <vector>
#include <stdexcept>

/* Max size of string constants */
#define MAX_STR_CONST 1025

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the Cool compiler.
 */
#define YY_NO_UNPUT
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
	if ( (result = fread( (char*)buf, sizeof(char), max_size, yyin)) < 0) \
		YY_FATAL_ERROR( "read() in flex scanner failed");

#define print(s)    fprintf(yyout, "%d %s\n", yylineno, (s));
#define print_long(s, s2) fprintf(yyout, "%d %s %s\n", yylineno, (s), (s2));

#ifndef __linux__
    #define snprintf _snprintf
#endif

char string_buf[MAX_STR_CONST]; /* to assemble string constants */
char *string_buf_ptr;

extern int curr_lineno;
extern int verbose_flag;
extern YYSTYPE cool_yylval;

/*
 *  Add Your own definitions here
 */

 //number of errors
 int numErrors = 0;

%}

%option nounput
%option yylineno
%option noyywrap


/*
 * Define names for regular expressions here.
 */

RARROW          =>
LARROW			<-
STRING          "\""([!|#-\377| |\t|\x00]|\\\n|\\\")*["\""|\n]
IDENTIFIER              [a-z][a-zA-Z0-9_]*
INTEGERLITERAL         [0-9]+
TYPE            [A-Z][a-zA-Z0-9_]*
PLUS            [+]
MINUS           [-]
TIMES             \*
DIVIDE             [/]
LT              <
LE             <=
EQUALS              [=]
AT              [@]
DOT             [.]
TILDE           [~]
LBRACE       [{]
RBRACE      [}]
LPAREN       [(]
RPAREN      [)]
SEMI       [;]
COLON           [:]
COMMA           [,]
WHITESPACE      [ \t\f\r\v]
NEWLINE         [\n]
IF              [iI][fF]
FI              [fF][iI]
ELSE            [Ee][Ll][Ss][Ee]
THEN            [Tt][Hh][Ee][Nn]
IN              [Ii][Nn]
INHERITS        [Ii][Nn][Hh][Ee][Rr][Ii][Tt][Ss]
ISVOID          [Ii][Ss][Vv][Oo][Ii][Dd]
LET             [Ll][Ee][Tt]
LOOP            [Ll][Oo][Oo][Pp]
POOL            [Pp][Oo][Oo][Ll]
WHILE           [Ww][Hh][Ii][Ll][Ee]
CASE            [Cc][Aa][Ss][Ee]
ESAC            [Ee][Ss][Aa][Cc]
NEW             [Nn][Ee][Ww]
OF              [Oo][Ff]
NOT             [Nn][Oo][Tt]
CLASS           [Cc][Ll][Aa][Ss][Ss]
TRUE            t[Rr][Uu][Ee]
FALSE           f[Aa][Ll][Ss][Ee]
INLINECOMMENT	--[^\n]*[\n]
MULTICOMMENT	"(*"([^*]|(\*+[^*)]))*\*+\)
MULTICOMMENTERROR "(*"([^*]|(\*+[^*)]))*
MISC			[\1-\11|\16-\37|\200-\377|\[|\]|\&|\%|\$|\#|\!|\>|\`]



%%

{NEWLINE}	{}
{INLINECOMMENT}	{}
{MULTICOMMENTERROR} {
					numErrors++;
					print("ERROR \"EOF in Multi Line Comment\"");
				}
{MULTICOMMENT}	{}
{WHITESPACE} {}
{RARROW}	{yylloc.first_line = yylineno; print("RARROW"); return RARROW;}
{LARROW}	{yylloc.first_line = yylineno; print("LARROW"); return LARROW;}
{ELSE}		{yylloc.first_line = yylineno; print("ELSE"); return ELSE;}
{IF}		{yylloc.first_line = yylineno; print("IF"); return IF;}
{FI}		{yylloc.first_line = yylineno; print("FI"); return FI;}
{THEN}		{yylloc.first_line = yylineno; print("THEN"); return THEN;}
{LET}		{yylloc.first_line = yylineno; print("LET"); return LET;}
{IN}		{yylloc.first_line = yylineno; print("IN"); return IN;}
{LOOP}		{yylloc.first_line = yylineno; print("LOOP"); return LOOP;}
{POOL}		{yylloc.first_line = yylineno; print("POOL"); return POOL;}
{WHILE}		{yylloc.first_line = yylineno; print("WHILE"); return WHILE;}
{CASE}		{yylloc.first_line = yylineno; print("CASE"); return CASE;}
{OF}		{yylloc.first_line = yylineno; print("OF"); return OF;}
{ESAC}		{yylloc.first_line = yylineno; print("ESAC"); return ESAC;}
{NOT}		{yylloc.first_line = yylineno; print("NOT"); return NOT;}
{CLASS}		{yylloc.first_line = yylineno; print("CLASS"); return CLASS;}
{INHERITS}	{yylloc.first_line = yylineno; print("INHERITS"); return INHERITS;}
{NEW}		{yylloc.first_line = yylineno; print("NEW"); return NEW;}
{ISVOID}	{yylloc.first_line = yylineno; print("ISVOID"); return ISVOID;}
{STRING}	{
			yylloc.first_line = yylineno;
			size_t len = yyleng;
			std::vector<int> newlinePositions; //2 places at a time, (start,end) of escaped newline
			newlinePositions.push_back(0); //offset so start/end is the usable sections
			bool escapeError = false;
			
			if(len > 1026) {
				print("ERROR \"String constant too long\"");
				numErrors++;
			} else {
				for(int i = 0; i < len; i++) {
					if(yytext[i] == '\n') {
						int j = 1;
						while(isspace(yytext[i - j])) {
							j--;
						}
						if(yytext[i - j] != '\\') {
							print("ERROR \"Unterminated string constant\"");
							escapeError = true;
							numErrors++;
						} else {
							newlinePositions.push_back(i - j); //start of escape
							newlinePositions.push_back(i); //end of escape
						}
					} else if(yytext[i] == '\0') {
						print("ERROR \"String contains null character.\"");
						escapeError = true;
						numErrors++;
					}
				}
				newlinePositions.push_back((int)len);
				if(!escapeError) {
                    std::string resultString = "";
					size_t vectLen = newlinePositions.size();
					for(size_t j = 0; j < vectLen; j+= 2) {
						int start = newlinePositions[j];
						int end = newlinePositions[j+1];
						for(int i = start; i <  end; i++) {
							if(yytext[i] == '\n') {
								resultString += "\\n";
							}
							else if(yytext[i] < 32 || yytext[i] > 126) {
                                char buf[100];
								snprintf(buf,5, "\\%o",yytext[i] & 0xFF);
                                resultString += buf;
							}
							else if(yytext[i] == '\\' && (i+1) < len
								&& yytext[i + 1] != '\n'
								&& yytext[i + 1] != 'b'
								&& yytext[i + 1] != 't'
								&& yytext[i + 1] != 'n'
								&& yytext[i + 1] != 'f'
								&& yytext[i + 1] != '"') {
								resultString += yytext[i + 1];
								i++;
							}
							else {
								resultString += yytext[i];
							}
						}
					}

					//correctly place string into Node
					yylval.Name = (char *)malloc((resultString.size() + 1) * sizeof(char));
					resultString = resultString.substr(1, resultString.size()-2);
					strcpy(yylval.Name, resultString.c_str());
                    print_long("STR_CONST", ("\"" + resultString + "\"").c_str());
				}
			}
             return STRING;
		}
{INTEGERLITERAL}	{
					yylloc.first_line = yylineno;
					print_long("INT_CONST",yytext);
					try {
						yylval.Value = stoi(yytext); //TODO: account for ints > INT_MAX (use strtol())
					}
					catch (const std::out_of_range& oor) {
						yylval.Value = INT32_MAX;
					}
					return INTEGERLITERAL;
					}
{FALSE}		{yylloc.first_line = yylineno; print_long("BOOL_CONST",yytext); return FALSE;}
{TRUE}		{yylloc.first_line = yylineno; print_long("BOOL_CONST",yytext); return TRUE;}
{IDENTIFIER}	{
				yylloc.first_line = yylineno;
				print_long("IDENTIFIER",yytext);
				yylval.Name = (char *)malloc((strlen(yytext) + 1) * sizeof(char));
				strcpy(yylval.Name, yytext);
				return IDENTIFIER;
				}
{COMMA}		{yylloc.first_line = yylineno; print("','"); return COMMA;}
{DOT}		{yylloc.first_line = yylineno; print("'.'"); return DOT;}
{LBRACE}	{yylloc.first_line = yylineno; print("'{'"); return LBRACE;}
{RBRACE}	{yylloc.first_line = yylineno; print("'}'"); return RBRACE;}
{SEMI}  	{yylloc.first_line = yylineno; print("';'"); return SEMI;}
{COLON}		    {yylloc.first_line = yylineno; print("':'"); return COLON;}
{RPAREN}	{yylloc.first_line = yylineno; print("')'"); return RPAREN;}
{LPAREN}	    {yylloc.first_line = yylineno; print("'('"); return LPAREN;}
{PLUS}          {yylloc.first_line = yylineno; print("'+'"); return PLUS;} 
{MINUS}         {yylloc.first_line = yylineno; print("'-'"); return MINUS;}
{TIMES}           {yylloc.first_line = yylineno; print("'*'"); return TIMES;}
{DIVIDE}           {yylloc.first_line = yylineno; print("'/'"); return DIVIDE;}
{LE}           {yylloc.first_line = yylineno; print("LE"); return LE;}
{LT}            {yylloc.first_line = yylineno; print("'<'"); return LT;}
{EQUALS}            {yylloc.first_line = yylineno; print("'='"); return EQUALS;}
{AT}		    {yylloc.first_line = yylineno; print("'@'"); return AT;}
{TILDE}		    {yylloc.first_line = yylineno; print("'~'");  return TILDE;}
{TYPE}		{
			yylloc.first_line = yylineno;
			print_long("TYPEID",yytext);
			yylval.Name = (char *)malloc((strlen(yytext) + 1) * sizeof(char));
			strcpy(yylval.Name, yytext);
			return TYPE;
			}
{MISC}		{
				yylloc.first_line = yylineno;
				if(yytext[0] < 32 || yytext[0] > 126) {
                
                    char buf[100];
                    snprintf(buf,7, "\"\\%o\"",yytext[0] & 0xFF);
					print_long("ERROR", buf);
					numErrors++;
				}
				else {
                    std::string thing = "\"";
                    thing += yytext;
                    thing += "\"";
					print_long("ERROR",thing.c_str());
					numErrors++;
				}
                //return 1; //misc errnum
			}
<<EOF>> {return 0;} //tell driver.cpp we're done
%%
