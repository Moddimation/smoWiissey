#---------------------------------------------------------------------------------
# Project smoWiissey Makefile
# Code made by Moddimation,
# Makefile made by ChatGPT.
#
#---------------------------------------------------------------------------------

#---------------------------------------------------------------------------------
# Environment Setup
#---------------------------------------------------------------------------------
.SUFFIXES:
MAKEFLAGS += --no-print-directory
ifeq ($(strip $(DEVKITPPC)),)
  $(error "Please set DEVKITPPC in your environment: export DEVKITPPC=<path>")
endif
include $(DEVKITPPC)/wii_rules

#--------------
# Configuration
#--------------

CONFIG ?= Debug
TARGET       := smoWiissey
LIBS         := -lwiiuse -lbte -logc -lm
SRCROOT      := Source
LIBDIRS      :=
INCLUDES     :=
SILENT := @
INCLUDES += $(DEVKITPRO)/libogc/include
CFLAGS    := -O3 -Wall -Wfatal-errors $(MACHDEP) $(addprefix -I,$(INCLUDES))
CXXFLAGS  :=
LDFLAGS   := $(MACHDEP) -Wl,-Map,$(notdir $@).map

#---------------------------------------------------------------------------------
# Compiler and Linker Flags per Configuration
#---------------------------------------------------------------------------------
ifeq ($(CONFIG),Debug)
  CFLAGS    += -g -Og -Wextra -Wpedantic -Wconversion -Wshadow -Wstrict-prototypes
  CXXFLAGS  += $(CFLAGS) -Weffc++
  LDFLAGS   += -g
else ifeq ($(CONFIG),Release)
  CFLAGS    += -O3 -fomit-frame-pointer -fexpensive-optimizations -flto
  CXXFLAGS  += $(CFLAGS)
  LDFLAGS   += -s
endif
CFLAGS += -std=gnu11
CXXFLAGS += -std=gnu++11
export LIBPATHS	:= -L$(LIBOGC_LIB) $(foreach dir,$(LIBDIRS),-L$(dir)/lib)

#---------------------------------------------------------------------------------
# Build Directories
#---------------------------------------------------------------------------------
BUILD_D := Build
BIN_D   := Game
BUILD := $(BUILD_D)/$(CONFIG)
BIN   := $(BIN_D)/$(CONFIG)

#---------------------------------------------------------------------------------
# Phony Targets
#---------------------------------------------------------------------------------
.PHONY: Debug Release all clean run
Debug:
	@$(MAKE) CONFIG=Debug all
Release:
	@$(MAKE) CONFIG=Release all
D: Debug
Deb: Debug
R: Release
Rel: Release
all: directories $(BIN)/$(TARGET).dol

#---------------------------------------------------------------------------------
# Create Output Directories
#---------------------------------------------------------------------------------
directories:
	$(SILENT)mkdir -p $(BUILD)/$(SRCROOT) $(BIN)

#---------------------------------------------------------------------------------
# Source File Discovery
#---------------------------------------------------------------------------------
SRCS := $(shell find $(SRCROOT) -type f \( -name '*.c' -o -name '*.cpp' -o -name '*.s' -o -name '*.S' \))
BINFILES := $(shell [ -d data ] && find data -type f || echo)

# Map source to object files
C_SRCS   := $(filter %.c,$(SRCS))
CPP_SRCS := $(filter %.cpp,$(SRCS))
S_SRCS   := $(filter %.s,$(SRCS))
SU_SRCS  := $(filter %.S,$(SRCS))
OFILES_S := $(C_SRCS:$(SRCROOT)/%.c=$(BUILD)/%.o) \
            $(CPP_SRCS:$(SRCROOT)/%.cpp=$(BUILD)/%.o) \
            $(S_SRCS:$(SRCROOT)/%.s=$(BUILD)/%.o) \
            $(SU_SRCS:$(SRCROOT)/%.S=$(BUILD)/%.o)
OFILES_B := $(BINFILES:data/%=$(BUILD)/%)
export OFILES := $(OFILES_S) $(OFILES_B)

# Determine Linker
CPPFILES := $(filter %.cpp,$(SRCS))
ifeq ($(CPPFILES),)
  export LD := $(CC)
else
  export LD := $(CXX)
endif

#---------------------------------------------------------------------------------
# Build Rules
#---------------------------------------------------------------------------------
$(BUILD)/%.o: $(SRCROOT)/%.c
	$(SILENT)echo "    CC  $@"
	$(SILENT)mkdir -p $(dir $@)
	$(SILENT)$(CC) -MMD -MP -MF $(BUILD)/$*.d $(CFLAGS) -c $< -o $@
$(BUILD)/%.o: $(SRCROOT)/%.cpp
	$(SILENT)echo "   CXX  $@"
	$(SILENT)mkdir -p $(dir $@)
	$(SILENT)$(CXX) -MMD -MP -MF $(BUILD)/$*.d $(CXXFLAGS) -c $< -o $@
$(BUILD)/%.o: $(SRCROOT)/%.s
	$(SILENT)echo "    AS  $@"
	$(SILENT)mkdir -p $(dir $@)
	$(SILENT)$(AS) $(MACHDEP) -c $< -o $@
$(BUILD)/%.o: $(SRCROOT)/%.S
	$(SILENT)echo "    AS  $@"
	$(SILENT)mkdir -p $(dir $@)
	$(SILENT)$(AS) $(MACHDEP) -c $< -o $@
$(BUILD)/%: data/%
	$(SILENT)echo "  DATA  $@"
	$(SILENT)mkdir -p $(dir $@)
	$(SILENT)$(bin2o) --input $< --output $@ --header $(BUILD)/$(notdir $<)_jpg.h

#---------------------------------------------------------------------------------
# Link and Package
#---------------------------------------------------------------------------------
$(BIN)/$(TARGET).elf: $(OFILES)
	$(SILENT)echo "  LINK  $@"
	$(SILENT)$(LD) $(OFILES) $(LDFLAGS) $(LIBPATHS) $(LIBS) -o $@
$(BIN)/$(TARGET).dol: $(BIN)/$(TARGET).elf
	$(SILENT)echo "   OUT  $@"
	$(SILENT)elf2dol $< $@
-include $(OFILES_S:.o=.d)

#---------------------------------------------------------------------------------
# Clean and Run
#---------------------------------------------------------------------------------
cleanRelease:
	$(SILENT)echo " CLEAN  Release"
	$(SILENT)rm -rf $(BUILD_D)/Release $(BIN_D)/Release
cleanDebug:
	$(SILENT)echo " CLEAN  Debug"
	$(SILENT)rm -rf $(BUILD_D)/Debug $(BIN_D)/Debug
clean: cleanRelease cleanDebug
	$(SILENT)rm -rf $(BUILD_D) $(BIN_D)
run:
	$(SILENT)echo "   RUN  Wii"
	$(SILENT)wiiload $(BIN)/$(TARGET).dol
