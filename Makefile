CC = gcc
CFLAGS = -lreadline
TARGET = shell
SOURCE = shell.c

all: shell

shell: $(TARGET)
	$(CC) -o $(TARGET) $(SOURCE) $(CFLAGS) && ./$(TARGET)

clean: 
	rm shell

.PHONY: all clean
