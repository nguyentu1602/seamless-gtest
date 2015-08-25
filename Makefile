#########################
# compiler and common flags
#########################
CXX:= g++
PROJECT:= proj
WARNINGS := -Wall -Wextra
# pretty print makefile - you can disable it.
Q := @


#########################
# directory listing
#########################
SRC_DIR := src
BUILD_DIR := build
BUILD_INCLUDE_DIR := $(BUILD_DIR)/src
INCLUDE_DIRS += $(BUILD_INCLUDE_DIR) ./src ./include


########################
# Get all sources files
########################
# CXX_SRCS are the source files excluding test ones
CXX_SRCS := $(shell find $(SRC_DIR)/$(PROJECT) ! -name "*_unittest.cc" -name "*.cc")
# TEST_SRCS are the test source files
TEST_MAIN_SRC := $(shell find $(SRC_DIR)/$(PROJECT)/test -name "test_main.cc")
TEST_SRCS := $(shell find $(SRC_DIR)/$(PROJECT)/test -name "*_unittest.cc")
TEST_SRCS := $(filter-out $(TEST_MAIN_SRC), $(TEST_SRCS))
GTEST_SRC := $(SRC_DIR)/gtest/gtest-all.cc


########################
# Derive generated files
########################
CXX_OBJS := $(addprefix $(BUILD_DIR)/,  ${CXX_SRCS:.cc=.o})
TEST_OBJS := $(addprefix $(BUILD_DIR)/, ${TEST_SRCS:.cc=.o})
GTEST_OBJ := $(addprefix $(BUILD_DIR)/, ${GTEST_SRC:.cc=.o})

# Gather all objects files that needed to be built
OBJS := $(CXX_OBJS)


# Output files for automatic dependency generation
# each .d file shows the dependencies for the associated .o file
DEPS := ${CXX_OBJS:.o=.d} ${TEST_OBJS:.o=.d}
# The target shared library name
LIB_BUILD_DIR := $(BUILD_DIR)/lib
LIBRARY_DIRS += $(LIB_BUILD_DIR)

STATIC_NAME := $(LIB_BUILD_DIR)/lib$(PROJECT).a
DYNAMIC_NAME := $(LIB_BUILD_DIR)/lib$(PROJECT).so

# it is quite tricky how $ORIGIN is passed to rpath
ORIGIN := \$$ORIGIN


#########################
# compile and link flags
#########################
COMMON_FLAGS += $(foreach includedir,$(INCLUDE_DIRS),-I$(includedir))

CFLAGS += -pthread -fPIC $(COMMON_FLAGS) $(WARNINGS)
LFLAGS += -pthread -fPIC $(COMMON_FLAGS) $(WARNINGS)
LDFLAGS += $(foreach librarydir,$(LIBRARY_DIRS), -L$(librarydir))

# Automatic dependency generation - it will create lots of .ld files
# one per .o file. These .d files will be picked up by the -include
# directive in the Makefile later
CFLAGS += -MMD -MP


TEST_BIN_DIR := $(BUILD_DIR)/test
TEST_ALL_BIN := $(TEST_BIN_DIR)/test_all.testbin
TEST_BINS := $(addsuffix .testbin, $(addprefix $(TEST_BIN_DIR)/,\
	$(foreach obj, $(TEST_OBJS), $(basename $(notdir $(obj))))))

TEST_BUILD_DIR := $(BUILD_DIR)/$(SRC_DIR)/$(PROJECT)/test

# Get all directory containing code
SRC_DIRS := $(shell find * -type d -exec bash -c "find {} -maxdepth 1 \
	\( -name '*.cc' -o -name '*.cc' \) | grep -q ." \; -print)

ALL_BUILD_DIRS := $(sort $(BUILD_DIR) $(addprefix $(BUILD_DIR)/, $(SRC_DIRS)) \
	$(TEST_BIN_DIR) $(LIB_BUILD_DIR) $(TEST_BUILD_DIR))



.PHONY: all test runtest clean

all: $(OBJS)

test: $(TEST_ALL_BIN) $(TEST_BINS)

runtest: $(TEST_ALL_BIN)
	$(TEST_ALL_BIN) --gtest_shuffle $(TEST_FILTER)

clean:
	rm -rf build


#######################
# Implicit rules:
#######################

# create all needed build directories. -p avoids hierachial dependency
$(ALL_BUILD_DIRS):
	@ mkdir -p $@

$(DYNAMIC_NAME): $(OBJS) | $(LIB_BUILD_DIR)
	@ echo LD -o $@
	$(Q)$(CXX) -shared -o $@ $(OBJS) $(LFLAGS) $(LDFLAGS)

$(STATIC_NAME): $(OBJS) | $(LIB_BUILD_DIR)
	@ echo AR -o $@
	$(Q)ar rcs $@ $(OBJS)

# For the .o objects in /build
$(BUILD_DIR)/%.o: %.cc | $(ALL_BUILD_DIRS)
	@ echo CXX $<
	$(Q) $(CXX) $(CFLAGS) -c $< -o $@

# Link the aggregate test file dynamically. It uses -rpath and require a libproj.so fie
# in the location specified by rpath. $(ORIGIN) is resolved once done.
$(TEST_ALL_BIN): $(TEST_MAIN_SRC) $(TEST_OBJS) $(GTEST_OBJ) \
	| $(DYNAMIC_NAME) $(TEST_BIN_DIR)
	@ echo CXX/LD -o $@ $<
	$(Q) $(CXX) $(TEST_MAIN_SRC) $(TEST_OBJS) $(GTEST_OBJ) -o $@ \
		$(LFLAGS) $(LDFLAGS) -l$(PROJECT) -Wl,-rpath,$(ORIGIN)/../lib

# You can also choose to link the aggregate test file staticly.
# You need the libproj.a file when linking, but once it's done you can run it as a
# standalone against libproj.a. I use -Wl flag in gcc to pass flag to the linker.
# It's REQUIRED that '-Wl -Bdynamic' is trailing because
# it let all the other libraries compiled dynamically.
# $(TEST_ALL_BIN): $(TEST_MAIN_SRC) $(TEST_OBJS) $(GTEST_OBJ) \
# 	| $(STATIC_NAME) $(TEST_BIN_DIR)
# 	@ echo CXX/LD -o $@ $<
# 	$(Q) $(CXX) $(TEST_MAIN_SRC) $(TEST_OBJS) $(GTEST_OBJ) -o $@ \
# 		$(LFLAGS) $(LDFLAGS) -Wl,-Bstatic -l$(PROJECT) -Wl,-Bdynamic

# use dynamic linking to libproj.so here to save disk space
$(TEST_BINS): $(TEST_BIN_DIR)/%.testbin: $(TEST_BUILD_DIR)/%.o \
	$(GTEST_OBJ) | $(DYNAMIC_NAME) $(TEST_BIN_DIR)
	@ echo LD $<
	$(Q) $(CXX) $(TEST_MAIN_SRC) $< $(GTEST_OBJ) -o $@ \
		$(LFLAGS) $(LDFLAGS) -l$(PROJECT) -Wl,-rpath,$(ORIGIN)/../lib


# for automatic dependency generation:
# it will include all the .d files that generate by the -MMD flag of gcc
-include $(DEPS)
