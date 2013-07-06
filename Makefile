RDMD=rdmd --build-only --force
SRC_DIR=source
WORK_DIR=tmp
BUILD_DIR=
MODULES=$(SRC_DIR)/app.d
COMMON_OPTS=-de -I$(SRC_DIR) -od$(BUILD_DIR)/obj -of$(BUILD_DIR)/remoo -property -w
DEBUG_OPTS=-debug -g -gs
RELEASE_OPTS=-inline -noboundscheck -O -release
TEST_OPTS=-unittest

debug: 		BUILD_DIR=$(WORK_DIR)/debug
release:	BUILD_DIR=$(WORK_DIR)/release
test:		BUILD_DIR=$(WORK_DIR)/test

debug:
	$(RDMD) $(COMMON_OPTS) $(DEBUG_OPTS) $(MODULES)

release:
	$(RDMD) $(COMMON_OPTS) $(RELEASE_OPTS) $(MODULES)

test:
	$(RDMD) $(COMMON_OPTS) $(TEST_OPTS) $(MODULES)

clean:
	rm -r tmp/*
