/*
 *  The scanner definition for COOL.
 */

/*
 *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
 *  output, so headers and global definitions are placed here to be visible
 * to the code in the file.  Don't remove anything that was here initially
 */
%{
#ifdef __linux__
#include "../src/ast.h"
#include "../bin/parser_cool.h"
#else
#include "ast.h"
#include "cool.tab.h"
#endif

#include <ctype.h>
#include <vector>

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
        
char string_buf[MAX_STR_CONST]; /* to assemble string constants */
char *string_buf_ptr;

extern int curr_lineno;
extern int verbose_flag;
extern YYSTYPE cool_yylval;

/*
 *  Add Your own definitions here
 */

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
TRUE            true
FALSE           false
INLINECOMMENT	--[^\n]*[\n]
MULTICOMMENT	"(*"([^*]|(\*+[^*)]))*\*+\)
MISC			[\1-\11|\16-\37|\200-\377|\[|\]|\&|\%|\$|\#|\!|\>|\`]



%%

{NEWLINE}	{yylineno++; return 1;}
{INLINECOMMENT}	{yylineno++; return 1;}
{MULTICOMMENT}	{
			int i = 0;
			int len = strlen(yytext);
			while(i < len) {
				if(yytext[i] == '\n'){
					yylineno++;
				}
				i++;
			}
			return 1;
		}
{WHITESPACE} {return 1;}
{RARROW}	{print("RARROW"); return RARROW;}
{LARROW}	{print("LARROW"); return LARROW;}
{ELSE}		{print("ELSE"); return ELSE;}
{IF}		{print("IF"); return IF;}
{FI}		{print("FI"); return FI;}
{THEN}		{print("THEN"); return THEN;}
{LET}		{print("LET"); return LET;}
{IN}		{print("IN"); return IN;}
{LOOP}		{print("LOOP"); return LOOP;}
{POOL}		{print("POOL"); return POOL;}
{WHILE}		{print("WHILE"); return WHILE;}
{CASE}		{print("CASE"); return CASE;}
{OF}		{print("OF"); return OF;}
{ESAC}		{print("ESAC"); return ESAC;}
{NOT}		{print("NOT"); return NOT;}
{CLASS}		{print("CLASS"); return CLASS;}
{TYPE}		{print_long("TYPEID",yytext); return TYPE;}
{INHERITS}	{print("INHERITS"); return INHERITS;}
{NEW}		{print("NEW"); return NEW;}
{ISVOID}	{print("ISVOID"); return ISVOID;}
{STRING}	{
			int len = yyleng;
			int newlineCount = 0;
			std::vector<int> newlinePositions; //2 places at a time, (start,end) of escaped newline
			newlinePositions.push_back(0); //offset so start/end is the usable sections
			bool escapeError = false;
			
			if(len > 1026) {
				print("ERROR \"String constant too long\"");
			} else {
				for(int i = 0; i < len; i++) {
					if(yytext[i] == '\n') {
						newlineCount++;
						int j = 1;
						while(isspace(yytext[i - j])) {
							j--;
						}
						if(yytext[i - j] != '\\') {
							print("ERROR \"Unterminated string constant\"");
							escapeError = true;
						} else {
							newlinePositions.push_back(i - j); //start of escape
							newlinePositions.push_back(i); //end of escape
						}
					} else if(yytext[i] == '\0') {
						print("ERROR \"String contains null character.\"");
						escapeError = true;
					}
				}
				newlinePositions.push_back(len);
				if(!escapeError) {
                    std::string resultString = "";
					resultString = "STR_CONST ";
					int vectLen = newlinePositions.size();
					for(int j = 0; j < vectLen; j+= 2) {
						int start = newlinePositions[j];
						int end = newlinePositions[j+1];
						for(int i = start; i <  end; i++) {
							if(yytext[i] == '\n') {
								resultString += "\\n";
							}
							else if(yytext[i] < 32 || yytext[i] > 126) {
                                char buf[100];
								_snprintf(buf,5, "\\%o",yytext[i] & 0xFF);
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
					resultString += "\n";
                    print(resultString.c_str());
				}
				yylineno += newlineCount;
			}
             return STRING;
		}
{INTEGERLITERAL}	{print_long("INT_CONST",yytext); return INTEGERLITERAL;} //TODO: account for ints > INT_MAX
{FALSE}		{print_long("BOOL_CONST",yytext); return FALSE;}
{TRUE}		{print_long("BOOL_CONST",yytext); return TRUE;}
{IDENTIFIER}		{print_long("IDENTIFIER",yytext); return IDENTIFIER;}
{COMMA}		{print("','"); return COMMA;}
{DOT}		{print("'.'"); return DOT;}
{LBRACE}	{print("'{'"); return LBRACE;}
{RBRACE}	{print("'}'"); return RBRACE;}
{SEMI}  	{print("';'"); return SEMI;}
{COLON}		    {print("':'"); return COLON;}
{RPAREN}	{print("')'"); return RPAREN;}
{LPAREN}	    {print("'('"); return LPAREN;}
{PLUS}          {print("'+'"); return PLUS;} 
{MINUS}         {print("'-'"); return MINUS;}
{TIMES}           {print("'*'"); return TIMES;}
{DIVIDE}           {print("'/'"); return DIVIDE;}
{LE}           {print("LE"); return LE;}
{LT}            {print("'<'"); return LT;}
{EQUALS}            {print("'='"); return EQUALS;}
{AT}		    {print("'@'"); return AT;}
{TILDE}		    {print("'~'");  return TILDE;}
{MISC}		{
				if(yytext[0] < 32 || yytext[0] > 126) {
                
                    char buf[100];
                    _snprintf(buf,7, "\"\\%o\"",yytext[0] & 0xFF);
					print_long("ERROR", buf);
				}
				else {
                    std::string thing = "\"";
                    thing += yytext;
                    thing += "\"";
					print_long("ERROR",thing.c_str());
				}
                return 1; //misc errnum
			}
<<EOF>> {return 0;} //tell driver.cpp we're done
%%