$(CXX)=g++
$(CC)=gcc

EXECUTABLE = hexciting
OBJECTS =  CommandParser.tab.o CommandParser.yy.o Command.o
LIBRARIES = -lfl

all: $(EXECUTABLE)

debug: CXX += -DDEBUG -g
debug: CC += -DDEBUG -g
debug: $(EXECUTABLE)

$(EXECUTABLE): $(OBJECTS)
	$(CXX) -o $@ $^ $(LIBRARIES)

%.yy.o: *.l
	flex -o $*.yy.c $<
	$(CC) -c $*.yy.c

%.tab.o: CommandParser.y
	bison -d $<
	$(CXX) -c $*.tab.c

%.o: %.cpp
	$(CXX) -c $<

clean:
	rm -f $(EXECUTABLE) $(OBJECTS) *.yy.c *.tab.c
