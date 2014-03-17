RDMD=rdmd --build-only --force
SRC_DIR=source
WORK_DIR=tmp
BUILD_DIR=
MODULES=$(SRC_DIR)/moo/app.d
TARGET=$(BUILD_DIR)/remoo
COMMON_OPTS=-de -I$(SRC_DIR) -od$(BUILD_DIR)/obj -of$(TARGET) -w
DEBUG_OPTS=-debug -g -gs -property
RELEASE_OPTS=-inline -noboundscheck -O -release
TEST_OPTS=$(DEBUG_OPTS) -unittest
DDOC_OPTS=-c -D -Dd$(BUILD_DIR) viola.ddoc

debug: 		BUILD_DIR=$(WORK_DIR)/debug
release:	BUILD_DIR=$(WORK_DIR)/release
test:		BUILD_DIR=$(WORK_DIR)/test
docs:		BUILD_DIR=$(WORK_DIR)/docs

debug:
	$(RDMD) $(COMMON_OPTS) $(DEBUG_OPTS) $(MODULES)

release:
	$(RDMD) $(COMMON_OPTS) $(RELEASE_OPTS) $(MODULES)
	strip --strip-all $(TARGET)

test:
	$(RDMD) $(COMMON_OPTS) $(TEST_OPTS) $(MODULES)

docs:
	./make-docs
	$(RDMD) $(COMMON_OPTS) $(DDOC_OPTS) $(MODULES)

clean:
	rm --force --recursive $(WORK_DIR)/*
