#
# Makefile for U3 examples
#
U6EFUNCTIONS_SRC=u6EFunctions.c u6.c u6Feedback.c u6LJTDAC.c
U6EFUNCTIONS_OBJ=libU6.so

SRCS=$(wildcard *.c)
HDRS=$(wildcard *.h)

CFLAGS +=-Wall -g -fPIC
LDFLAGS= -shared -o
LIBS=-lm -llabjackusb

all: u6EFunctions

u6EFunctions: $(U3EFUNCTIONS_SRC) $(HDRS)
	$(CC) $(CFLAGS) $(U6EFUNCTIONS_SRC) $(LDFLAGS) $(U6EFUNCTIONS_OBJ) $(LIBS)

clean:
	rm -f *.so 
