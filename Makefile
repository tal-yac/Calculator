all: calc

calc: calc.s
	nasm -f elf calc.s -o calc.o
	gcc -g -m32 -Wall calc.o -o calc

clean:
	rm -rf ./*.o calc