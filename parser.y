%{
    #include <stdio.h>
    #include <stdlib.h>

    extern int yylex (void);
    extern FILE *yyin;
    void yyerror (const char *s){ fprintf(stderr,"error: %s\n",s); exit(1); }           
%}


%token VAR VAR_IN NUMBER ENTER INDENT DEDENT DEL              
%start program

%%                               

program:
    /* empty */
    | block
    | program DEL program
    | DEL program

block:
    lists
    | vocs

lists:
    list
    | lists list

vocs:
    vocabulary
    | vocs vocabulary 

list:
    '-' value ':' value
    | '-' ENTER INDENT lists DEDENT
    | '-' value ':'
    | '-' value ':' value ENTER
    | '-' value ':' ENTER
    | '-' value ENTER
    | '-' value
    | '-' value ENTER INDENT vocs DEDENT
    | '-' value ':' value ENTER INDENT vocs DEDENT
    | '-' value ':' ENTER INDENT vocs DEDENT
    | '-' value ':' ENTER INDENT lists DEDENT

vocabulary:
    value ':' value
    | value ':' '-' value
    | value ':' '>' ENTER INDENT text DEDENT
    | value ':' '|' ENTER INDENT text DEDENT
    | value ':'
    | value ':' ENTER
    | value ':' value ENTER
    | value ':' '-' value ENTER
    | value ':' value ENTER INDENT vocs DEDENT
    | value ':' ENTER INDENT vocs DEDENT
    | value ':' ENTER INDENT lists DEDENT
    | value ':' ENTER lists

text:
    text text
    | value ENTER
    | value

value:
    string
    | dict_str
    | list_str

string:
    VAR
    | VAR_IN
    | string VAR
    | string VAR_IN

pair:
    value ':' value

dict_str:
    '{' var_dict_str '}'
    | '{' '}' 

list_str:
    '[' var_list_str ']'
    | '[' ']'

var_dict_str:
    pair
    | var_dict_str ',' pair

var_list_str:
    value
    | var_list_str ',' value

%%
                              
int main (int argc, char **argv)
{
    if (argc < 2)
    { 
        fprintf(stderr, "Usage: %s [filename]\n", argv[0]);
        return 1;
    }

    if (!(yyin = fopen(argv[1],"r")))
    { 
        perror(argv[1]);
        return 1; 
    }

    puts("Start parsing...");
    if (yyparse() == 0)
        puts("\n\nFile is correct.");
    else
        puts("Error file.");
    fclose(yyin);

    return 0;
}