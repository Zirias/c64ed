C64SYS?=c64
C64AS?=ca65
C64LD?=ld65
CC?=gcc

C64ASFLAGS?=-t $(C64SYS) -g
C64LDFLAGS?=-Ln ed.lbl -m ed.map -Csrc/ed.cfg
CFLAGS?=-std=c11 -Wall -Wextra -pedantic -O3 -g0
LDFLAGS?= -O3 -g0 -s

ifeq ($(OS),Windows_NT)
EXE:=.exe
else
EXE:=
endif

ed_OBJS:=$(addprefix obj/,main.o text80.o keyboard.o raster.o gfx-core.o \
	kbinput.o ed.o buffer.o cmdline.o numconv.o font.o)
ed_BIN:=ed.prg

bmp2c64_OBJS:=$(addprefix obj/,bmp2c64.o)
bmp2c64_BIN:=bmp2c64$(EXE)

mprg2bas_OBJS:=$(addprefix obj/,mprg2bas.o)
mprg2bas_BIN:=mprg2bas$(EXE)

all: $(ed_BIN) edldr.bas

src/font.s: res/font_topaz_80col_petscii_western.bmp $(bmp2c64_BIN)
	./$(bmp2c64_BIN) >$@ -s DATA $<

edldr.bas: $(ed_BIN) $(mprg2bas_BIN)
	./$(mprg2bas_BIN) >$@ <$<

$(ed_BIN): $(ed_OBJS)
	$(C64LD) -o$@ $(C64LDFLAGS) $^

$(bmp2c64_BIN): $(bmp2c64_OBJS)
	$(CC) -o$@ $(LDFLAGS) $^

$(mprg2bas_BIN): $(mprg2bas_OBJS)
	$(CC) -o$@ $(LDFLAGS) $^

obj:
	mkdir obj

obj/%.o: src/%.s src/ed.cfg Makefile | obj
	$(C64AS) $(C64ASFLAGS) -o$@ $<

obj/%.o: src/%.c Makefile | obj
	$(CC) -c -o$@ $(CFLAGS) $<

clean:
	rm -fr obj *.lbl *.map

distclean: clean
	rm -f $(ed_BIN) $(mprg2bas_BIN)

.PHONY: all clean distclean

