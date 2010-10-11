#pragma once

#ifndef COMMANDHEADER
#define COMMANDHEADER

#include <vector>

enum MODE_ENUM {PRINT=1, XOR, OR, AND, NOT};

class Command {

public:

    Command();
	~Command();
    
    MODE_ENUM mode;
    int start;

    bool range;
    int end;

    char* filename;

    std::vector<int> data;
    int dataCount;

    void print();
    
    void printOperation();
    void writeOperation();

    bool verbose;


};

static Command* theCommand;

bool checkCharacterBounds(char);

void processCommand(Command*);

#endif
