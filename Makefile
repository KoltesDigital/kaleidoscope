# Makefile

CC = g++
CFLAGS = -g -Wall -pedantic


all : kaleidoscope examples


kaleidoscope : bin/kaleidoscope

bin/kaleidoscope : build/data.o build/lexer.o build/main.o build/parser.o
	mkdir -p $(dir $@)
	$(CC) $(CFLAGS) $^ -o $@ -lfl -lfirm -lm

build/parser.c : src/kaleidoscope.y src/data.c
	mkdir -p $(dir $@)
	bison -d -v $< -o $@

build/lexer.c : src/kaleidoscope.lex build/parser.c
	flex -o $@ $<

build/%.o : src/%.c
	mkdir -p $(dir $@)
	$(CC) $(CFLAGS) -c $< -o $@ -Isrc

build/%.o : build/%.c
	$(CC) $(CFLAGS) -c $< -o $@ -Isrc -Ibuild


examples : bin/answer bin/transform

build-examples/%.s : examples/%.kal bin/kaleidoscope
	mkdir -p $(dir $@)
	bin/kaleidoscope -o $@ $<

bin/answer : build-examples/answer.s examples/kalutil.c
	gcc -m32 $^ -o $@

bin/transform : build-examples/transform.s examples/kalutil.c
	gcc -m32 $^ -o $@


clean :
	rm -rf bin build build-examples

