%option noyywrap
%option yylineno

%{
#include "y.tab.h"
int current_indent = 0;
static int end = -1;
int handle_indent(int new_indent);
%}

%x STATE 
%%
<INITIAL>"\x02"         {
                            printf("(DEDENT %d) ", current_indent);
                            current_indent--;
                            return DEDENT;
                        }

<STATE>^"#".*"\n"       {BEGIN(STATE);}
<STATE>[ \t]*"#".*"\n"  {BEGIN(STATE);}
<STATE>"\x02"           {
                            printf("(DEDENT %d) ", current_indent);
                            current_indent--;
                            return DEDENT;
                        }



<STATE>^[ \t]+          {   
                            int spaces = 0, tabs = 0;
                            for (int i = 0; yytext[i]; ++i) {
                                if (yytext[i] == ' ') spaces++;
                            else tabs++;
                            }
                            int new_indent = tabs + spaces/2;
                            int a =  handle_indent(new_indent);
                            if (a==1)
                                return INDENT;
                            else if (a==2)
                                return DEDENT;
                        }

<STATE>^[ \n]           { }

<STATE>.                {   
                            BEGIN(INITIAL); 
                            yyless(0);
                            int a = handle_indent(0);
                            if (a==1)
                                return INDENT;
                            else if (a==2)
                                return DEDENT;
                        }

-{3}                    {BEGIN(STATE); printf("\nDEL\n"); return DEL;}
-{3}[ \t]*#.*\n         {BEGIN(STATE); printf("\nDEL\n"); return DEL;}
-{3}[ \t]*#.*           {BEGIN(STATE); printf("\nDEL\n"); return DEL;}
-{3}[ \t]*\n            {BEGIN(STATE); printf("\nDEL\n"); return DEL;}    
 
^[ \t]+\n               {printf("2\n"); BEGIN(STATE);}
^[\n]                   {}
[\n]                    {printf("\n"); BEGIN(STATE); return ENTER;}

[\-\:\[\]\{\}\,>|]      {printf("%c", yytext[0]); return yytext[0];}

\"(?:[^"\\]|\\.)*\"     {printf("VAR_IN"); return VAR_IN;}

\'(?:[^"\\]|\\.)*\'     {printf("VAR_IN"); return VAR_IN;}


"True"|"true"    { printf("TRUE"); return VAR; }
"False"|"false"    { printf("FALSE"); return VAR; }
-?[0-9]+(\.[0-9]+)?    { printf("VAR_NUM"); return VAR; }
[A-Za-z0-9_/\(\)~!&<\*\.][A-Za-z0-9\+\*\!\(\)\^_/.\ \%\"\-=<>|\'&]*       {printf("VAR"); return VAR;}

^"#".*"\n"              {BEGIN(STATE);}

"#".*"\n"               {BEGIN(STATE);return ENTER;}

[ ]+                    {printf(" ");}

<<EOF>>                 {   
                            BEGIN(INITIAL); 
                            if (end==-1)
                            {
                                if(current_indent == 0)
                                    return 0;
                                end=current_indent;
                                printf("\n(DEDENT %d) ", end);
                                end--;
                                return DEDENT;
                            }
                            if (end==0)
                                return 0;
                            if (end>0)
                            {
                                printf("\n(DEDENT %d) ", end);
                                end--;
                                return DEDENT;
                            }
                        }

.                       {fprintf(stderr, "Unexpected character '%c' at line %d\n", yytext[0], yylineno);}

%%

int handle_indent(int new_indent) {
    if (new_indent - current_indent == 1) {
        current_indent = new_indent;
        printf("(INDENT %d) ", current_indent);
        BEGIN(INITIAL);
        return 1;
    } else if (new_indent - current_indent  > 1) {
        printf("ERROR new_indent=%d current_indent=%d\n",new_indent,current_indent);
        exit(-1);
    } else if (current_indent - new_indent == 1) {
        printf("(DEDENT %d) ", current_indent);
        current_indent = new_indent;
        BEGIN(INITIAL);
        return 2;
    }
    else if (current_indent - new_indent > 1) {
            int diff = current_indent - new_indent;
            BEGIN(INITIAL);
            for (int i = 0; i < diff-1; i++)
                unput('\x02');
            printf("(DEDENT %d) ", current_indent);
            current_indent--;  
            return 2;
    }
    
    BEGIN(INITIAL);
    return 3;
}