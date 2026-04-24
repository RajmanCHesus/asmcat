# ==============================================================
# Makefile  -  asmcat
# Linux x64, NASM + ld
# ==============================================================

NASM   = nasm
LD     = ld
FLAGS  = -f elf64

TARGET = asmcat
OBJS   = main.o proc.o

.PHONY: all clean

all: $(TARGET)

$(TARGET): $(OBJS)
	$(LD) -o $@ $^

main.o: main.asm
	$(NASM) $(FLAGS) -o $@ $<

proc.o: proc.asm
	$(NASM) $(FLAGS) -o $@ $<

clean:
	rm -f $(OBJS) $(TARGET)