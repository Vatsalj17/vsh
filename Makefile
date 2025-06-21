CC = gcc
CFLAGS = -lreadline -g
SRC = src
INC = include
OBJ = obj
BIN = vsh
BINDIR = /usr/local/bin
SRCS = $(wildcard $(SRC)/*.c)
OBJS = $(patsubst $(SRC)/%.c, $(OBJ)/%.o, $(SRCS))

all: $(BIN)

$(BIN): $(OBJS)
	$(CC) $(OBJS) -o $@ $(CFLAGS)

$(OBJ)/%.o: $(SRC)/%.c | $(OBJ)
	$(CC) $(CFLAGS) -c $< -o $@

$(OBJ):
	mkdir -p $(OBJ)

install: $(BIN)
	@echo "Installing $(BIN) to $(BINDIR)..."
	install -d $(BINDIR)
	install -m 755 $(BIN) $(BINDIR)/$(BIN)
	@echo "Installation complete!"

uninstall:
	@echo "Removing $(BIN) from $(BINDIR)..."
	rm -f $(BINDIR)/$(BIN)
	@echo "Uninstallation complete!"

clean:
	rm -rf $(BIN) $(OBJ)

.PHONY: all install uninstall clean
