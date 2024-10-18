%{
#include <stdio.h>
#include <string.h>

void convertToSQL(const char *collection, const char *criteria, const char *projection);
void convertToProjection(const char *projection, char *sql);
%}

%%

db\.([a-zA-Z_][a-zA-Z0-9_]*)\.find\((.*)\) {
    char collection[256];   
    char criteria[512] = ""; 
    char projection[256] = "";

    // Extract collection 
    sscanf(yytext, "db.%255[^.].find(", collection);

    // Extract the part inside the find() function
    char findParams[1024];
    sscanf(yytext, "db.%*[^.].find(%1023[^)])", findParams);

    // Now parse the criteria and projection separately
    char *criteriaStart = strchr(findParams, '{');
    if (criteriaStart != NULL) {
        char *criteriaEnd = strchr(criteriaStart, '}');
        if (criteriaEnd != NULL) {
            // Extract criteria
            size_t criteriaLength = criteriaEnd - criteriaStart + 1;
            strncpy(criteria, criteriaStart, criteriaLength);
            criteria[criteriaLength] = '\0';

            // Check if there is a projection part
            char *projectionStart = strchr(criteriaEnd + 1, '{');
            if (projectionStart != NULL) {
                char *projectionEnd = strchr(projectionStart, '}');
                if (projectionEnd != NULL) {
                    // Extract projection
                    size_t projectionLength = projectionEnd - projectionStart + 1;
                    strncpy(projection, projectionStart, projectionLength);
                    projection[projectionLength] = '\0';
                }
            }
        }
    }

    // Call the function to convert and print the SQL statement
    convertToSQL(collection, criteria, projection);
}
[ \t\n]+ ; // Ignore whitespace
. { /* Ignore any unrecognized characters */ }

%%

// Function to handle the conversion and print the SQL statement
void convertToSQL(const char *collection, const char *criteria, const char *projection) {
    // Initialize SQL statement
    char sql[1024] = "SELECT ";

    // Handle projection if provided
    if (strlen(projection) > 0) {
        convertToProjection(projection, sql);
    } else {
        strcat(sql, "*"); // Select all if no projection is specified
    }

    strcat(sql, " FROM ");
    strcat(sql, collection);

    // Check if there are criteria and format the SQL statement accordingly
    if (strlen(criteria) > 1) {
        strcat(sql, " WHERE ");
        
        // Create a mutable copy of the criteria for tokenization
        char criteriaCopy[512];
        strncpy(criteriaCopy, criteria + 1, sizeof(criteriaCopy) - 1); // Start after '{'
        criteriaCopy[sizeof(criteriaCopy) - 1] = '\0'; // Null-terminate

        // Remove the curly braces and split the criteria by comma
        char *token = strtok(criteriaCopy, ",}");
        int isFirstCondition = 1; // To handle the first condition in the WHERE clause

        // Process each key-value pair
        while (token != NULL) {
            char key[256], value[256], operator[256];
            
            if (sscanf(token, "%255[^:]:{\"%255[^\"]\":%255[^}]", key, operator, value) == 3) {
                if (!isFirstCondition) {
                    strcat(sql, " AND ");
                }
                isFirstCondition = 0;

                if (strcmp("$gt", operator) == 0) {
                    strcat(sql, key);
                    strcat(sql, " > ");
                    strcat(sql, value);
                } else if (strcmp("$gte", operator) == 0) {
                    strcat(sql, key);
                    strcat(sql, " >= ");
                    strcat(sql, value);
                } else if (strcmp("$lt", operator) == 0) {
                    strcat(sql, key);
                    strcat(sql, " < ");
                    strcat(sql, value);
                } else if (strcmp("$lte", operator) == 0) {
                    strcat(sql, key);
                    strcat(sql, " <= ");
                    strcat(sql, value);
                }
            } else if (sscanf(token, "%255[^:]: \"%255[^\"]\"", key, value) == 2) {
                if (!isFirstCondition) {
                    strcat(sql, " AND ");
                }
                isFirstCondition = 0;

                strcat(sql, key);
                strcat(sql, " = \"");
                strcat(sql, value);
                strcat(sql, "\"");
            } else if (sscanf(token, "%255[^:]: %255[^,\"]", key, value) == 2) {
                if (!isFirstCondition) {
                    strcat(sql, " AND ");
                }
                isFirstCondition = 0;

                strcat(sql, key);
                strcat(sql, " = ");
                strcat(sql, value);
            }

            token = strtok(NULL, ",}");
        }
    }

    strcat(sql, ";\n"); // End the SQL statement
    printf("%s", sql); // Print the SQL statement
    fflush(stdout); // Ensure the output is flushed immediately
}

// Function to handle projections and append them to SQL statement
void convertToProjection(const char *projection, char *sql) {
    char projectionCopy[256];
    
    strncpy(projectionCopy, projection + 1, sizeof(projectionCopy) - 1); // Start after '{'
    projectionCopy[sizeof(projectionCopy) - 1] = '\0'; // Null-terminate

    char *token = strtok(projectionCopy, ",}");
    int isFirstColumn = 1; // To handle commas between columns

    while (token != NULL) {
        char key[256];
        if (sscanf(token, "%255[^:]:", key) == 1) { 
            if (!isFirstColumn) {
                strcat(sql, ", ");
            }
            isFirstColumn = 0; 
            strcat(sql, key); 
        }
        token = strtok(NULL, ",}");
    }
}

int main(int argc, char **argv) {
    FILE *file = fopen("input.mongo", "r");
    
    if (!file) {
        fprintf(stderr, "Error: Could not open input.mongo\n");
        return 1;
    }

    yyin = file; // Redirect input to read from input.mongo
    yylex();     // Start lexical analysis
    
    fclose(file); // Close the file after processing
    return 0;
}
