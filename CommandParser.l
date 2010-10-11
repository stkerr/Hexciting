
%{
#include <string.h>
#include "CommandParser.tab.h"
%}

%%

\t {
    //printf("TAB!\n");
}

" " {
    //printf("SPACE!\n");
}

\n {
	return;
}

-v {
    return VERBOSEFLAG;
}

-p {
    return PRINTMODE; 
}

-x {
    return XORMODE;
}

-n {
    return NOTMODE;
}

-a {
    return ANDMODE;
}

-o {
    return ORMODE;
}

-r {
    return RANGEFLAG;
}

-l {
	return LENGTHFLAG;
}

0[xX][0-9a-fA-F]+ {
    int retVal = sscanf(yytext, "%x",&(yylval.int_val));
    
    if(retVal != 1)
        return;
    return NUMBER;
}

[0-9]+ {
    yylval.int_val = atoi(yytext);
    return NUMBER;
}

[^ \t\n]+ {
    yylval.string_val = strdup(yytext);
    return ARGUMENT;
}


%%
void configBuffer(char* arguments)
{
#ifdef DEBUG
	printf("Given the buffer: %s:\n", arguments);
#endif
	yy_delete_buffer(YY_CURRENT_BUFFER);
	yy_scan_string(arguments);
}
