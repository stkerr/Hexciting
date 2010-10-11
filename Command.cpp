#include "Command.h"
#include <cstring>
#include <stdio.h>
#include <stdlib.h>

#include <iostream>
#include <fstream>

Command::Command()
{
    filename = 0; // null
    dataCount = 0;
}

Command::~Command()
{
    free(filename);
}

void Command::print()
{
    printf("\n------\n");
    printf("Printing command info:\n");
    printf("------\n");

    printf("Mode:");
    switch(mode)
    {
            case PRINT:
                    printf("Print");
                    break;
            case XOR:
                    printf("Xor");
                    break;
            case OR:
                    printf("Or");
                    break;
            case AND:
                    printf("And");
                    break;
            case NOT:
                    printf("Not");
                    break;
    };
    printf("\n");

    printf("Range: ");
    if(range == true)
        printf("Yes\n");
    else
        printf("No\n");

    printf("Start: %#x\n", start);
    if(range == true)
        printf("End: %#x\n", end);

    printf("Filename: %s\n", filename);

    printf("Data count: %d\n", dataCount);
    for(int i = 0; i < dataCount; i++)
        printf("Data: %#x\n", (int)data[i]);
    
    printf("------\n");
}

void processCommand(Command* command)
{
    std::ifstream ifs(command->filename, std::ifstream::in | std::ifstream::binary);

    if(ifs.good() != true)
    {
        printf("Error opening %s\n", command->filename);
        ifs.close();
        return;
    }

    // calculate the total file size
    ifs.seekg(0, std::ios::end);
    if(ifs.good() != true)
    {
        printf("File operation failed!\n");
        ifs.close();
        return;
    }

    int fileSize = ifs.tellg();
    if(ifs.good() != true)
    {
        printf("File operation failed!\n");
        ifs.close();
        return;
    }

    if(command->end > fileSize)
        command->end = fileSize;
    if(command->start > fileSize)
    {
        printf("Error. Start is past end of file.\n");
        return;
    }
    if(command->start > command->end)
    {
        printf("Error. Start is greater than end.\n");
        return;
    }

    ifs.close();


    if(command->mode == PRINT)
        command->printOperation();
    else
        command->writeOperation();
}


void Command::printOperation()
{
	std::ifstream ifs(filename, std::ifstream::in | std::ifstream::binary);

        if(ifs.good() != true)
        {
            printf("Error opening %s\n", filename);
            ifs.close();
            return;
        }

	// calculate how many bytes we're printing
	int length = end - start;
	
	// TODO: Optimise this for large files (>64 kb(?))

	unsigned char dataBuffer[length];
	memset(dataBuffer, 0, length);

	// seek to the start and scan in
	ifs.seekg(start, std::ios::beg);
        if(ifs.good() != true)
        {
            printf("File operation failed!\n");
            ifs.close();
            return;
        }
	ifs.read((char*)dataBuffer, length);
        if(ifs.good() != true)
        {
            printf("File operation failed!\n");
            ifs.close();
            return;
        }

        ifs.close();

	int currentAddress = start;

	int hexBuffer[0x10];

	for(int i = 0; i < 0x10; i++)
            hexBuffer[i] = 0;

        // to prevent unwanted characters from being printed
        int numberCharsToPrint = 0;
        bool hasData = false;

	for(int i = 0; i < length; i++)
	{
            // new row, so print out the old data
            if(i % 0x10 == 0&& i != 0)
            {
                // print a row header
                printf("%#x:\t", currentAddress);
                currentAddress += 0x10;
                
                // print our hex data
                for(int j = 0; j < numberCharsToPrint; j++)
                    printf("%02x ", hexBuffer[j]);
                for(int j = 0; j < numberCharsToPrint; j++)
                {
                    if(checkCharacterBounds(hexBuffer[j]))
                        printf("%c", hexBuffer[j]);
                    else
                        printf(".");
                }

                printf("\n");
                numberCharsToPrint = 0;

                hasData = false;
            }
            
            
            hexBuffer[i % 0x10] = dataBuffer[i];
            numberCharsToPrint++;
            hasData = true;

	}
        
        // print any overflow data
        if(hasData == true)
        {
             // print a row header
            printf("%#x:\t", currentAddress);
            currentAddress += 0x10;

            // print our hex data
            for(int j = 0; j < 0x10; j++)
            {
                if(j < numberCharsToPrint)
                    printf("%02x ", hexBuffer[j]);
                else
                    printf("   ");
            }

            for(int j = 0; j < 0x10; j++)
            {
                if(j < numberCharsToPrint)
                    printf("%c", hexBuffer[j]);
                else
                    printf("   ");
            }

            printf("\n");

        }
}

void Command::writeOperation()
{
    if(dataCount < 1 && mode != NOT)
    {
        printf("Need data bytes to perform operation with!\n");
        return;
    }
    
    // create a stream to the file & verify its valid
    std::ifstream ifs(filename, std::ifstream::in | std::ifstream::binary);

    if(ifs.good() != true)
    {
        printf("Error opening %s", filename);
        return;
    }

    // copy our data into a buffer
    int length = end - start;

    // TODO: Optimise for large files, so large amounts of memory aren't used
    unsigned char buffer[length];
    memset(buffer, 0, length);

    ifs.seekg(start, std::ios::beg);
    ifs.read((char*)buffer, length);
    if(ifs.good() != true)
    {
        printf("Read error!\n");
        ifs.close();
        return;
    }

    ifs.close();

    // apply operation to the buffer
    // TODO: Possibly do this in parallel. Investigate GPU, SIMD, etc
    int dataIndex = 0;
    for(int i = 0; i < length; i++)
    {
        switch(mode)
        {
                case XOR:
                    buffer[i] ^= data[dataIndex];
                    break;
                case OR:
                    buffer[i] |= data[dataIndex];
                    break;
                case AND:
                    buffer[i] &= data[dataIndex];
                    break;
                case NOT:
                    buffer[i] = ~buffer[i];
                    break;
                default:
                    break;

        };

        // get the next element of data to operate with
        if(++dataIndex >= dataCount)
            dataIndex = 0;
    }

    // get a FILE* to write with
    FILE* output = fopen(filename, "r+");

    if(output == 0)
    {

        printf("Error opening %s", filename);
        return;
    }

    // move the pointer to the proper location
    if(fseek(output, start, SEEK_SET) != 0)
    {
        printf("File operation failed!\n");
        fclose(output);
        return;
    }

    // copy the buffer back into the file
    if(length != fwrite(buffer, sizeof(char), length, output))
    {
        printf("Error writing back to file!\n");
        fclose(output);
        return;
    }

    // close the stream
    fclose(output);

}

bool checkCharacterBounds(char theChar)
{
    if(theChar >= ' ' && theChar <= '~')
        return true;
    return false;
}