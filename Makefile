APP       = VantaDesktop
BUILD_DIR = build
APP_PATH  = $(BUILD_DIR)/Build/Products/Release/$(APP).app
INSTALL   = /Applications/$(APP).app

.PHONY: all run install uninstall clean

all: run

run:
	@./build.sh

install:
	@./build.sh install

uninstall:
	@./build.sh uninstall

clean:
	@./build.sh clean
