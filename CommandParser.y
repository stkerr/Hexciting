// this file contains the yacc/bison parsing code


%token PRINTMODE XORMODE ORMODE ANDMODE NOTMODE RANGEFLAG LENGTHFLAG VERBOSEFLAG

%union {
    char *string_val;
    int int_val;
}

%token <string_val> ARGUMENT
%token <int_val> NUMBER

%{
extern "C" int yylex();
#define yylex yylex
int yylex(void);
void yyerror(const char*);

#include <stdio.h>
#include <iostream>
#include <string.h>
#include "Command.h"

extern void yy_delete_buffer(char*);
extern void yy_scan_string(char*);
extern "C" void configBuffer(char*);

void printUsage();

bool verbose;
int rangeStart, rangeEnd;

%}



%%

command: 
    args
;

args:
    verbosity mode destination filename data
;

verbosity:
    VERBOSEFLAG {
        theCommand->verbose = true;
        verbose = true;
    }
    |
;

filename:
    ARGUMENT {
        theCommand->filename = strdup($1);
    }
;

data:
    data NUMBER {
		theCommand->dataCount++;
		theCommand->data.push_back($2);
    }
    |
;

mode:
    PRINTMODE {
        theCommand->mode = PRINT;
    }
    |
    XORMODE {
        theCommand->mode = XOR;
    }
    |
    ORMODE {
        theCommand->mode = OR;
    }
    |
    ANDMODE {
        theCommand->mode = AND;
    }
    |       
    NOTMODE {
        theCommand->mode = NOT;
    }
;

destination:
    range
    |
    length
    |
    NUMBER {
    }
;

length:
	LENGTHFLAG NUMBER NUMBER {
        theCommand->range = false;
        theCommand->start = $2;
        theCommand->end = $2+$3;
	}
;

range:
    RANGEFLAG NUMBER NUMBER	{
	theCommand->range = true;
        theCommand->start = $2;
        theCommand->end = $3;
	}
;

%%

void yyerror(const char * s)
{
    printUsage();
}

void printUsage()
{
	std::cout << "Usage: [-v] mode [[-r start end] [-l start distance]] filename [databytes]" << std::endl;
        if(theCommand->verbose == false)
            std::cout << "Use -v for more detailed information" << std::endl;
        else
        {
            std::cout << "Mode can be any (and must be one) of the following:" << std::endl;
            std::cout << "   -x for XOR operations" << std::endl;
            std::cout << "   -a for AND operations" << std::endl;
            std::cout << "   -o for OR operations" << std::endl;
            std::cout << "   -n for NOT operations" << std::endl;
            std::cout << "   -p for PRINT operations" << std::endl;
            std::cout << "" << std::endl;
            std::cout << "To apply an operation over a range of bytes," << std::endl;
            std::cout << "   use the -r flag and specify a start and end address." << std::endl;
            std::cout << "  Note that the start is inclusive and end is exclusive." << std::endl;
            std::cout << "" << std::endl;
            std::cout << "To apply an operation over a certain length," << std::endl;
            std::cout << "   use the -l flag and specify a start address and length" << std::endl;
            std::cout << "" << std::endl;
            std::cout << "filename is the file that will be operated on. It must exist." << std::endl;
            std::cout << "" << std::endl;
            std::cout << "databytes are the bytes of data that any operation requiring data " << std::endl;
            std::cout << "will use. They can be specified in either decimal or hexadecimal " << std::endl;
            std::cout << "by simply typing the number or prepending a 0x." << std::endl;
            std::cout << "If the range or length of the operation is greater than the " << std::endl;
            std::cout << "number of databytes supplied, the databytes will be looped over " << std::endl;
            std::cout << "until the operation has been completed." << std::endl;
            std::cout << "Note that the xor, or, and and operations REQUIRE data bytes." << std::endl;
            std::cout << "" << std::endl;
            std::cout << "Please make note of the endianness of your machine." << std::endl;
            std::cout << "Hexciting performs all operations on character sized elements, " << std::endl;
            std::cout << " so interpret the results properly, according to endianness." << std::endl;

        }
}

/*
TODO:
I found this code on the internet, and the original author
mentions that there is a memory leak.

Also, why is a char*** being used instead of a 
char**? Needs to be invesitaged
*/
int parseArguments(int argc, char** argv)
{
	int i;

	int sum = 0;
	// calculate the length of buffer we need
	for(i = 1; i < argc; i++)
	{
		sum += strlen(argv[i]) + 1;
	}

	if(sum <= 0)
		return 1;

	// make us a buffer and zero it out
	char tempBuffer[sum];
	memset(tempBuffer, 0, sum);

	// pointer to walk through our buffer
	int pos = 0;

	// copy arguments into the buffer
	for(i = 1; i < argc; i++)
	{
		memcpy(tempBuffer+pos, argv[i], strlen(argv[i]));
		pos += strlen(argv[i]);
		sprintf(tempBuffer+pos++, " ");
	}

	// give our arguments to lex for parsing
	configBuffer(tempBuffer);

	// use bison parsing
	int returnVal = yyparse();
	if(returnVal != 0)
	{
            return 1;
	}

        return 0;

}

int main(int argc, char** argv)
{
    // initialise our global
    theCommand = new Command();
    
    if(argc == 1)
    {
            printUsage();
            return 0;
    }

    // process our arguments
    if(parseArguments(argc, argv) != 0)
    {
        // something went wrong
        return 1;
    }

    // process the command
    processCommand(theCommand);

    #ifdef DEBUG
    theCommand->print();
    #endif
    
    return 0;
}
