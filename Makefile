RDMD=rdmd --build-only --force
SRC_DIR=source
WORK_DIR=tmp
BUILD_DIR=
MODULES=$(SRC_DIR)/moo/app.d
TARGET=$(BUILD_DIR)/remoo
COMMON_OPTS=-de -I$(SRC_DIR) -od$(BUILD_DIR)/obj -of$(TARGET) -property -w
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
	strip -s $(TARGET)

test:
	$(RDMD) $(COMMON_OPTS) $(TEST_OPTS) $(MODULES)

clean:
	rm -r $(WORK_DIR)/*
