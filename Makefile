ASM=nasm
ASMFLAGS=-f elf64
LD=ld
PYTHON=python3

.PHONY: clean

all: main

%.o: %.asm
		$(ASM) $(ASMFLAGS) -o $@ $<

main: main.o lib.o dict.o
		$(LD) -o main main.o lib.o dict.o

test: main
	$(PYTHON) test.py

clean:
		rm -rf *.o