%{
#include <stdio.h>
#include <string.h>

void yyerror(const char *s);
int yylex(void);
void convertToSQL(const char *collection, const char *criteria, const char *projection);
void convertToProjection(const char *projection, char *sql);

char collection[256];
char criteria[512] = "";
char projection[256] = "";

extern FILE *yyin; // Add this line
%}

%union {
    char str[1024];
}

%token <str> COLLECTION CRITERIA PROJECTION

%%

input:
    db_find_list
    ;

db_find_list:
    db_find
    | db_find_list db_find
    ;

db_find:
    "db." COLLECTION ".find(" find_params ")" {
        convertToSQL(collection, criteria, projection);
    }
    ;

find_params:
    CRITERIA {
        strcpy(criteria, $1);
    }
    | CRITERIA "," PROJECTION {
        strcpy(criteria, $1);
        strcpy(projection, $3);
    }
    | PROJECTION {
        strcpy(projection, $1);
    }
    | /* empty */ {
        criteria[0] = '\0';
        projection[0] = '\0';
    }
    ;

%%

void yyerror(const char *s) {
    fprintf(stderr, "Error: %s\n", s);
}

int main(int argc, char **argv) {
    FILE *file = fopen("input.mongo", "r");
    
    if (!file) {
        fprintf(stderr, "Error: Could not open input.mongo\n");
        return 1;
    }

    yyin = file; // Redirect input to read from input.mongo
    yyparse();   // Start parsing
    
    fclose(file); // Close the file after processing
    return 0;
}