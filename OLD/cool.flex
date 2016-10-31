/*
 *  The scanner definition for COOL.
 */

/*
 *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
 *  output, so headers and global definitions are placed here to be visible
 * to the code in the file.  Don't remove anything that was here initially
 */
%{
#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>
#include <ctype.h>
#include <vector>

/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex

/* Max size of string constants */
#define MAX_STR_CONST 1025
#define YY_NO_UNPUT   /* keep g++ happy */

extern FILE *fin; /* we read from this file */

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the Cool compiler.
 */
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
	if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
		YY_FATAL_ERROR( "read() in flex scanner failed");

char string_buf[MAX_STR_CONST]; /* to assemble string constants */
char *string_buf_ptr;

extern int curr_lineno;
extern int verbose_flag;

extern YYSTYPE cool_yylval;

/*
 *  Add Your own definitions here
 */

%}

/*
 * Define names for regular expressions here.
 */

DARROW          =>
ASSIGN			<-
STRING          "\""([!|#-\377| |\t|\x00]|\\\n|\\\")*["\""|\n]
ID              [a-z][a-zA-Z0-9_]*
INTEGER         [0-9]+
TYPE            [A-Z][a-zA-Z0-9_]*
PLUS            [+]
MINUS           [-]
MUL             \*
DIV             [/]
LT              <
LTE             <=
EQ              [=]
AT              [@]
DOT             [.]
TILDE           [~]
LEFTBRACE       [{]
RIGHTBRACE      [}]
LEFTPAREN       [(]
RIGHTPAREN      [)]
SEMICOLON       [;]
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

{NEWLINE}	yylineno++;
{INLINECOMMENT}	yylineno++;
{MULTICOMMENT}	{
			int i = 0;
			int len = strlen(yytext);
			while(i < len) {
				if(yytext[i] == '\n'){
					yylineno++;
				}
				i++;
			}
		}
{WHITESPACE}
{DARROW}	fprintf(stdout,"#%d DARROW\n",yylineno);
{ASSIGN}	fprintf(stdout,"#%d ASSIGN\n",yylineno);
{ELSE}		fprintf(stdout,"#%d ELSE\n",yylineno);
{IF}		fprintf(stdout,"#%d IF\n",yylineno);
{FI}		fprintf(stdout,"#%d FI\n",yylineno);
{THEN}		fprintf(stdout,"#%d THEN\n",yylineno);
{LET}		fprintf(stdout,"#%d LET\n",yylineno);
{IN}		fprintf(stdout,"#%d IN\n",yylineno);
{LOOP}		fprintf(stdout,"#%d LOOP\n",yylineno);
{POOL}		fprintf(stdout,"#%d POOL\n",yylineno);
{WHILE}		fprintf(stdout,"#%d WHILE\n",yylineno);
{CASE}		fprintf(stdout,"#%d CASE\n",yylineno);
{OF}		fprintf(stdout,"#%d OF\n",yylineno);	
{ESAC}		fprintf(stdout,"#%d ESAC\n",yylineno);
{NOT}		fprintf(stdout,"#%d NOT\n",yylineno);
{CLASS}		fprintf(stdout,"#%d CLASS\n",yylineno);
{TYPE}		fprintf(stdout,"#%d TYPEID %s\n",yylineno,yytext);
{INHERITS}	fprintf(stdout,"#%d INHERITS\n",yylineno);
{NEW}		fprintf(stdout,"#%d NEW\n",yylineno);
{ISVOID}	fprintf(stdout,"#%d ISVOID\n",yylineno);
{STRING}	{
			int len = yyleng;
			int newlineCount = 0;
			std::vector<int> newlinePositions; //2 places at a time, (start,end) of escaped newline
			newlinePositions.push_back(0); //offset so start/end is the usable sections
			bool escapeError = false;
			
			if(len > 1026) {
				fprintf(stdout,"#%d ERROR \"String constant too long\"\n",yylineno);
			} else {
				for(int i = 0; i < len; i++) {
					if(yytext[i] == '\n') {
						newlineCount++;
						int j = 1;
						while(isspace(yytext[i - j])) {
							j--;
						}
						if(yytext[i - j] != '\\') {
							fprintf(stdout,"#%d ERROR \"Unterminated string constant\"\n",yylineno);
							escapeError = true;
						} else {
							newlinePositions.push_back(i - j); //start of escape
							newlinePositions.push_back(i); //end of escape
						}
					} else if(yytext[i] == '\0') {
						fprintf(stdout,"#%d ERROR \"String contains null character.\"\n",yylineno);
						escapeError = true;
					}
				}
				newlinePositions.push_back(len);
				if(!escapeError) {
					fprintf(stdout,"#%d STR_CONST ",yylineno);
					int vectLen = newlinePositions.size();
					for(int j = 0; j < vectLen; j+= 2) {
						int start = newlinePositions[j];
						int end = newlinePositions[j+1];
						for(int i = start; i <  end; i++) {
							if(yytext[i] == '\n') {
								fprintf(stdout,"\\n");
							}
							else if(yytext[i] < 32 || yytext[i] > 126) {
								fprintf(stdout,"\\%o",yytext[i] & 0xFF);
							}
							else if(yytext[i] == '\\' && (i+1) < len
								&& yytext[i + 1] != '\n'
								&& yytext[i + 1] != 'b'
								&& yytext[i + 1] != 't'
								&& yytext[i + 1] != 'n'
								&& yytext[i + 1] != 'f'
								&& yytext[i + 1] != '"') {
								fprintf(stdout,"%c",yytext[i + 1]);
								i++;
							}
							else {
								fprintf(stdout,"%c",yytext[i]);
							}
						}
					}
					fprintf(stdout, "\n");
				}
				yylineno += newlineCount;
			}
		}
{INTEGER}	fprintf(stdout,"#%d INT_CONST %s\n",yylineno,yytext);
{FALSE}		fprintf(stdout,"#%d BOOL_CONST %s\n",yylineno,yytext);
{TRUE}		fprintf(stdout,"#%d BOOL_CONST %s\n",yylineno,yytext);
{ID}		fprintf(stdout,"#%d OBJECTID %s\n",yylineno,yytext);
{COMMA}		fprintf(stdout,"#%d ','\n",yylineno);
{DOT}		fprintf(stdout,"#%d '.'\n",yylineno);
{LEFTBRACE}	fprintf(stdout,"#%d '{'\n",yylineno);
{RIGHTBRACE}	fprintf(stdout,"#%d '}'\n",yylineno);
{SEMICOLON}  	fprintf(stdout,"#%d ';'\n",yylineno);
{COLON}		fprintf(stdout,"#%d ':'\n",yylineno);
{RIGHTPAREN}	fprintf(stdout,"#%d ')'\n",yylineno);
{LEFTPAREN}	fprintf(stdout,"#%d '('\n",yylineno);
{PLUS}          fprintf(stdout,"#%d '+'\n",yylineno);  
{MINUS}         fprintf(stdout,"#%d '-'\n",yylineno);  
{MUL}           fprintf(stdout,"#%d '*'\n",yylineno);  
{DIV}           fprintf(stdout,"#%d '/'\n",yylineno);  
{LTE}           fprintf(stdout,"#%d LE\n",yylineno);  
{LT}            fprintf(stdout,"#%d '<'\n",yylineno);  
{EQ}            fprintf(stdout,"#%d '='\n",yylineno); 
{AT}		fprintf(stdout,"#%d '@'\n",yylineno);
{TILDE}		fprintf(stdout,"#%d '~'\n",yylineno); 
{MISC}		{
				if(yytext[0] < 32 || yytext[0] > 126) {
					fprintf(stdout,"#%d ERROR \"\\%o\"\n",yylineno,yytext[0] & 0xFF);
				}
				else {
					fprintf(stdout,"#%d ERROR \"%s\"\n",yylineno,yytext);
				}
			}
%%
