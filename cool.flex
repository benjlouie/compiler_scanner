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

/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex

/* Our own split character */
#define SPLIT ",0xFE"

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
ASSIGN		<-
STRING          "\""([!|#-\377| |\t]|\\\")*"\""
ID              [a-z][a-zA-Z0-9_]*
INTEGER         [0-9]+
TYPE            [A-Z][a-zA-Z0-9_]*
PLUS            [+]
MINUS           [-]
MUL             \*
DIV             [/]
LT              <[^-]?
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
			int len = strlen(yytext);
			if(len > 1026) {
				fprintf(stdout,"#%d ERROR \"String constant too long\"\n",yylineno);
			} else {
				fprintf(stdout,"#%d STR_CONST ",yylineno);
				for(int i = 0; i <  len; i++) {
					if(yytext[i] < 32 || yytext[i] > 126) {
						fprintf(stdout,"\\%o",yytext[i] & 0xFF);
					}
					else {
						fprintf(stdout,"%c",yytext[i]);
					}
				}
				fprintf(stdout,"\n");
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


	




%%

