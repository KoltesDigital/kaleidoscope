/* Lexical analyzer for Kaleidoscope */

%{
#include <data.h>
#include <parser.h>

int yyerror(char *s);
extern int yylineno;
%}

double_lit		-?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?
identifier		[A-Za-z_][0-9A-Za-z_]*

%%

"+"				{ return '+'; }
"*"				{ return '*'; }
","				{ return ','; }
"("				{ return '('; }
")"				{ return ')'; }
"def"			{ return DEF; }
"extern"		{ return EXTERN; }
"main"			{ return MAIN; }
{double_lit}	{ yylval.val = atof(yytext); return DOUBLE_LITERAL; }
{identifier}	{ yylval.str = strdup(yytext); return IDENTIFIER; }

[ \t]*			{}
(#.*)?\n		{ yylineno++;	}

.				{ yyerror("Bad character"); exit(1);	}
