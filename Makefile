.SUFFIXES:
SUFFIXES =
.SUFFIXES: .c .cpp .h .hpp .rc .res .inl .o .d .asm


#==============================================================================
MAKEFLAGS += --no-print-directory
#==============================================================================

SHELL := /bin/sh

# Build platform
PLATFORM?=linux
# Build description (Primarily uses Debug/Release)
BUILD?=Release
_BUILDL := $(shell echo $(BUILD) | tr A-Z a-z)
ifeq ($(BUILD),Tests)
	_BUILDL := release
endif

# The sub-folder containing the target source files
SRC_TARGET?=
ifneq ($(SRC_TARGET),)
	_SRC_TARGET := /$(SRC_TARGET)
endif

# Maximum parallel jobs during build process
MAX_PARALLEL_JOBS?=8

# Dump assembly?
DUMP_ASSEMBLY?=false

# Clean output?
CLEAN_OUTPUT?=true

# If dll, build as a static library?
BUILD_STATIC?=false

# Platform specific environment variables
-include env/.all.mk
-include env/.$(_BUILDL).mk
-include env/$(PLATFORM).all.mk
-include env/$(PLATFORM).$(_BUILDL).mk

# Target specific variables
ifneq ($(SRC_TARGET),)
-include env/$(SRC_TARGET)/.all.mk
-include env/$(SRC_TARGET)/.$(_BUILDL).mk
-include env/$(SRC_TARGET)/$(PLATFORM).all.mk
-include env/$(SRC_TARGET)/$(PLATFORM).$(_BUILDL).mk
endif

#==============================================================================
# File/Folder dependencies for the production build recipe (makeproduction)
PRODUCTION_DEPENDENCIES?=
# Extensions to exclude from production builds
PRODUCTION_EXCLUDE?=
# Folder location (relative or absolute) to place the production build into
PRODUCTION_FOLDER?=build
PRODUCTION_FOLDER_RESOURCES := $(PRODUCTION_FOLDER)

#==============================================================================
# Library directories (separated by spaces)
LIB_DIRS?=
INCLUDE_DIRS?=
# Link libraries (separated by spaces)
LINK_LIBRARIES?=

# Precompiled header filename (no extension)
# This file will be excluded from Rebuild, but if the bin/(build) directory is removed, it will be as well.
PRECOMPILED_HEADER?=

# Build-specific preprocessor macros
BUILD_MACROS?=
# Build-specific compiler flags to be appended to the final build step (with prefix)
BUILD_FLAGS?=

# Build dependencies to copy into the bin/(build) folder - example: openal32.dll
BUILD_DEPENDENCIES?=

# NAME should always be passed as an argument from tasks.json as the root folder name, but uses a fallback of "game.exe"
# This is used for the output filename (game.exe)
NAME?=game.exe

#==============================================================================
# The source file directory
SRC_DIR := src$(_SRC_TARGET)
LIB_DIR := lib

# Project .cpp or .rc files (relative to $(SRC_DIR) directory)
SOURCE_FILES := $(patsubst $(SRC_DIR)/%,%,$(shell find $(SRC_DIR) -name '*.cpp' -o -name '*.c' -o -name '*.cc' -o -name '*.rc'))
# Project subdirectories within $(SRC_DIR)/ that contain source files
PROJECT_DIRS := $(patsubst $(SRC_DIR)/%,%,$(shell find $(SRC_DIR) -mindepth 1 -maxdepth 99 -type d))

# Add prefixes to the above variables
_INCLUDE_DIRS := $(patsubst %,-I%,$(SRC_DIR)/ $(LIB_DIR)/ $(INCLUDE_DIRS))

_BUILD_MACROS := $(BUILD_MACROS:%=-D%)
_LINK_LIBRARIES := $(LINK_LIBRARIES:%=-l%)

#==============================================================================
# Unit Testing
TEST_DIR :=
ifeq ($(BUILD),Tests)
	TEST_DIR := test
	SOURCE_FILES := $(SOURCE_FILES:Main.cpp=)
	SOURCE_FILES := $(patsubst $(TEST_DIR)/%,.$(TEST_DIR)/%,$(shell find $(TEST_DIR) -name '*.cpp' -o -name '*.c' -o -name '*.cc' -o -name '*.rc')) $(SOURCE_FILES)
	_INCLUDE_DIRS := $(patsubst %,-I%,$(TEST_DIR)/) $(_INCLUDE_DIRS)
	PROJECT_DIRS := .$(TEST_DIR) $(PROJECT_DIRS)
	BUILD_FLAGS := $(BUILD_FLAGS:-mwindows=)
endif

#==============================================================================
# Linux Specific
PRODUCTION_LINUX_ICON?=icon

# The full working directory
ifeq ($(PLATFORM),linux)
	_LINUX_GREP_CWD := $(shell echo $(CURDIR) | sed 's/\//\\\//g')
endif

#==============================================================================
# MacOS Specific
PRODUCTION_MACOS_ICON?=icon
PRODUCTION_MACOS_BUNDLE_COMPANY?=developer
PRODUCTION_MACOS_BUNDLE_DISPLAY_NAME?=App
PRODUCTION_MACOS_BUNDLE_NAME?=App
PRODUCTION_MACOS_MAKE_DMG?=true
PRODUCTION_MACOS_BACKGROUND?=dmg-background

ifeq ($(PLATFORM),osx)
	PRODUCTION_MACOS_BUNDLE_COMPANY := '$(PRODUCTION_MACOS_BUNDLE_COMPANY)'
	PRODUCTION_MACOS_BUNDLE_DISPLAY_NAME := '$(PRODUCTION_MACOS_BUNDLE_DISPLAY_NAME)'
	PRODUCTION_MACOS_BUNDLE_NAME := '$(PRODUCTION_MACOS_BUNDLE_NAME)'
	PRODUCTION_FOLDER_MACOS := $(PRODUCTION_FOLDER)
	PRODUCTION_FOLDER := $(PRODUCTION_FOLDER)/$(PRODUCTION_MACOS_BUNDLE_NAME).app/Contents
	PRODUCTION_FOLDER_RESOURCES := $(PRODUCTION_FOLDER)/Resources
	PRODUCTION_DEPENDENCIES := $(PRODUCTION_DEPENDENCIES)
	PRODUCTION_MACOS_DYLIBS := $(PRODUCTION_MACOS_DYLIBS:%=%.dylib)
	MACOS_FRAMEWORKS?=CoreFoundation
	PRODUCTION_MACOS_FRAMEWORKS := $(PRODUCTION_MACOS_FRAMEWORKS:%=%.framework)
	PRODUCTION_MACOS_BACKGROUND := env/osx/$(PRODUCTION_MACOS_BACKGROUND)
	MACOS_FRAMEWORK_PATHS := $(MACOS_FRAMEWORK_PATHS:%=-F%)
	BUILD_FLAGS := $(BUILD_FLAGS) $(MACOS_FRAMEWORK_PATHS) $(MACOS_FRAMEWORKS:%=-framework %)
endif

#==============================================================================
# Directories & Dependencies
BLD_DIR := bin/$(BUILD)
ifeq ($(BUILD),Tests)
	BLD_DIR := bin/Release
endif
BLD_DIR := $(BLD_DIR:%/=%)
_BASENAME := $(basename $(NAME))
ifeq ($(BUILD_STATIC),true)
ifeq ($(suffix $(NAME)),$(filter $(suffix $(NAME)),.dll .dylib .so))
ifneq ($(suffix $(NAME)),)
	NAME := $(_BASENAME)-s.a
endif
endif
endif
TARGET := $(BLD_DIR)/$(NAME)

ifneq ($(SRC_TARGET),)
	LIB_DIRS := $(LIB_DIRS) $(BLD_DIR)
endif
_LIB_DIRS := $(LIB_DIR:%=-L%/) $(LIB_DIRS:%=-L%)

_SOURCES_IF_RC := $(if $(filter windows,$(PLATFORM)),$(SOURCE_FILES),$(SOURCE_FILES:%.rc=))

OBJ_DIR := $(BLD_DIR)/obj$(_SRC_TARGET)
_OBJS := $(_SOURCES_IF_RC:.c=.c.o)
_OBJS := $(_OBJS:.cpp=.cpp.o)
_OBJS := $(_OBJS:.cc=.cc.o)
_OBJS := $(_OBJS:.rc=.res)
OBJS := $(_OBJS:%=$(OBJ_DIR)/%)
OBJ_SUBDIRS := $(PROJECT_DIRS:%=$(OBJ_DIR)/%)

DEP_DIR := $(BLD_DIR)/dep$(_SRC_TARGET)
_DEPS := $(_SOURCES_IF_RC:%=%.d)
DEPS := $(_DEPS:%=$(DEP_DIR)/%) $(DEP_DIR)/$(PRECOMPILED_HEADER).d
DEP_SUBDIRS := $(PROJECT_DIRS:%=$(DEP_DIR)/%)

_PCH_HFILE := $(shell find $(SRC_DIR) -name '$(PRECOMPILED_HEADER).hpp' -o -name '$(PRECOMPILED_HEADER).h' -o -name '$(PRECOMPILED_HEADER).hh')
_PCH_HFILE := $(_PCH_HFILE:$(SRC_DIR)/%=%)
_PCH_EXT := $(_PCH_HFILE:$(PRECOMPILED_HEADER).%=%)
_PCH_COMPILER_EXT := $(if $(filter osx,$(PLATFORM)),p,g)ch

_SYMBOLS := $(if $(filter osx,$(PLATFORM)),,$(if $(filter Release,$(BUILD)),-s,))


_PCH := $(_PCH_HFILE:%=$(OBJ_DIR)/%)
ifneq ($(_PCH),)
	_PCH_GCH := $(_PCH).$(_PCH_COMPILER_EXT)
endif

ifeq ($(DUMP_ASSEMBLY),true)
	ASM_DIR := $(BLD_DIR)/asm$(_SRC_TARGET)
	_ASMS := $(_OBJS:%.res=)
	_ASMS := $(_ASMS:.o=.o.asm)
	ASMS := $(_ASMS:%=$(ASM_DIR)/%)
	ASM_SUBDIRS := $(PROJECT_DIRS:%=$(ASM_DIR)/%)
endif

_DIRECTORIES := $(sort bin $(BLD_DIR) $(OBJ_DIR) $(OBJ_SUBDIRS) $(DEP_DIR) $(DEP_SUBDIRS) $(ASM_DIR) $(ASM_SUBDIRS))

_CLEAN := $(filter true,$(CLEAN_OUTPUT))

_TARGET_DEPS := $(_PCH_GCH) $(OBJS) $(ASMS) $(TEST_DIR)

# Quiet flag
_Q := $(if $(_CLEAN),@)

#==============================================================================
# Compiler & flags
CC?=g++
RC?=windres.exe
CFLAGS?=-O2 -Wall -fdiagnostics-color=always

CFLAGS_DEPS = -MT $@ -MMD -MP -MF $(DEP_DIR)/$*.Td
CFLAGS_DEPS_T = -MT $@ -MMD -MP -MF $(DEP_DIR)/.$(TEST_DIR)/$*.Td
PCH_COMPILE = $(CC) $(CFLAGS_DEPS) $(_BUILD_MACROS) $(CFLAGS) $(_INCLUDE_DIRS) -o $@ -c $<
ifneq ($(_PCH),)
	_INCLUDE_PCH := -include $(_PCH)
endif

OBJ_COMPILE = $(CC) $(CFLAGS_DEPS) $(_BUILD_MACROS) $(_INCLUDE_DIRS) $(_INCLUDE_PCH) $(CFLAGS) -o $@ -c $<
OBJ_COMPILE_T = $(CC) $(CFLAGS_DEPS_T) $(_BUILD_MACROS) $(_INCLUDE_DIRS) $(_INCLUDE_PCH) $(CFLAGS) -o $@ -c $<

RC_COMPILE = -$(RC) -J rc -O coff --preprocessor-arg=-MT --preprocessor-arg=$@ --preprocessor-arg=-MMD --preprocessor-arg=-MP --preprocessor-arg=-MF --preprocessor-arg=$(DEP_DIR)/$*.rc.Td $(_BUILD_MACROS) $(_INCLUDE_DIRS) -i $< -o $@
ifeq ($(PLATFORM),osx)
	ASM_COMPILE = otool -tvV $< | c++filt > $@
else
	ASM_COMPILE = objdump -d -C -Mintel $< > $@
endif
POST_COMPILE = mv -f $(DEP_DIR)/$*.Td $(DEP_DIR)/$*.d && touch $@
POST_COMPILE_T = mv -f $(DEP_DIR)/.$(TEST_DIR)/$*.Td $(DEP_DIR)/.$(TEST_DIR)/$*.d && touch $@
POST_COMPILE_RC = mv -f $(DEP_DIR)/$*.rc.Td $(DEP_DIR)/$*.rc.d && touch $@

#==============================================================================
# Unicode
UNI_COPY := ➦
UNI_LINK := ⇛
ifeq ($(PLATFORM),osx)
	UNI_COPY := ➦
	UNI_LINK := ⇛
endif
ifeq ($(PLATFORM),windows)
	UNI_COPY := \xE2\x9E\xA6
	UNI_LINK := \xE2\x87\x9B
endif

# Misc
ORIGIN_FLAG := '-Wl,-R$$ORIGIN'
ifeq ($(PLATFORM),osx)
	ORIGIN_FLAG :=
endif

#==============================================================================
# Build Scripts
all:
	@$(MAKE) makepch
	@$(MAKE) -j$(MAX_PARALLEL_JOBS) makebuild
.DELETE_ON_ERROR: all

rebuild: clean all
.PHONY: rebuild

buildprod: all makeproduction
.PHONY: buildprod

#==============================================================================
# Functions
color_blue := \033[0;34m
color_purple := \033[0;35m

define compile_with
	$(if $(_CLEAN),@printf '   $(color_blue)$($(2):$(OBJ_DIR)/%=%)\n')
	$(_Q)$(3) && $(4)
endef

define linking_with
	$(if $(_CLEAN),@printf '\n$(color_blue)$(UNI_LINK)  Linking: $(1)')
endef

define build_deps
	$(foreach dep,$(BUILD_DEPENDENCIES),$(call copy_to,$(dep),$(BLD_DIR)))
endef

MKDIR := $(_Q)mkdir -p

makepch: $(_PCH_GCH)
	@printf ''
.PHONY: makepch

makebuild: $(TARGET)
ifeq ($(SRC_TARGET),)
	@printf '   $(color_blue)Target is up to date.\n'
else
	@printf '   $(color_blue)$(NAME): Target is up to date.\n'
endif
.PHONY: makebuild

#==============================================================================
# Build Recipes
$(OBJ_DIR)/%.o: $(SRC_DIR)/%
$(OBJ_DIR)/%.o: $(SRC_DIR)/% $(_PCH_GCH) $(DEP_DIR)/%.d | $(_DIRECTORIES)
	$(call compile_with,@,<,$(OBJ_COMPILE),$(POST_COMPILE))

$(OBJ_DIR)/.$(TEST_DIR)/%.o: $(TEST_DIR)/%
$(OBJ_DIR)/.$(TEST_DIR)/%.o: $(TEST_DIR)/% $(_PCH_GCH) $(DEP_DIR)/.$(TEST_DIR)/%.d | $(_DIRECTORIES)
	$(call compile_with,@,<,$(OBJ_COMPILE_T),$(POST_COMPILE_T))

$(OBJ_DIR)/%.$(_PCH_EXT).$(_PCH_COMPILER_EXT) : $(SRC_DIR)/%.$(_PCH_EXT)
$(OBJ_DIR)/%.$(_PCH_EXT).$(_PCH_COMPILER_EXT) : $(SRC_DIR)/%.$(_PCH_EXT) $(DEP_DIR)/%.d | $(_DIRECTORIES)
	$(call compile_with,@,<,$(PCH_COMPILE),$(POST_COMPILE))

$(OBJ_DIR)/%.res: $(SRC_DIR)/%.rc
$(OBJ_DIR)/%.res: $(SRC_DIR)/%.rc $(DEP_DIR)/%.rc.d | $(_DIRECTORIES)
	$(call compile_with,@,<,$(RC_COMPILE),$(POST_COMPILE_RC))

$(ASM_DIR)/%.o.asm: $(OBJ_DIR)/%.o
	$(if $(_CLEAN),@printf '   $(color_purple)$@\n')
	$(_Q)$(ASM_COMPILE)

$(BLD_DIR)/lib%-s.a: $(_TARGET_DEPS)
	$(call linking_with,$@)
	-$(_Q)rm -rf $@
	$(_Q)ar -c -r -s $@ $(OBJS)
	@printf '\n'

$(BLD_DIR)/$(_BASENAME).dll: $(_TARGET_DEPS)
	$(call linking_with,$@)
	-$(_Q)rm -rf $(BLD_DIR)/$(_BASENAME).def $(BLD_DIR)/$(_BASENAME).a
	$(_Q)$(CC) -shared -Wl,--output-def="$(BLD_DIR)/$(_BASENAME).def" -Wl,--out-implib="$(BLD_DIR)/$(_BASENAME).a" -Wl,--dll $(_LIB_DIRS) $(OBJS) -o $@ $(_SYMBOLS) $(_LINK_LIBRARIES) $(BUILD_FLAGS)
	@printf '\n'

$(BLD_DIR)/$(_BASENAME).so: $(_TARGET_DEPS)
	$(call linking_with,$@)
	$(_Q)$(CC) -shared $(_LIB_DIRS) $(OBJS) -o $@ $(_SYMBOLS) $(_LINK_LIBRARIES) $(BUILD_FLAGS)
	@printf '\n'

$(BLD_DIR)/$(_BASENAME).dylib: $(_TARGET_DEPS)
	$(call linking_with,$(BLD_DIR)/$(_BASENAME).dylib)
	$(_Q)$(CC) -dynamiclib -undefined suppress -flat_namespace $(_LIB_DIRS) $(OBJS) -o $@ $(_SYMBOLS) $(_LINK_LIBRARIES) $(BUILD_FLAGS)
	@printf '\n'

$(BLD_DIR)/$(_BASENAME).exe: $(_TARGET_DEPS)
	$(call linking_with,$@)
	$(_Q)$(CC) $(_LIB_DIRS) $(_SYMBOLS) -o $@ $(ORIGIN_FLAG) $(OBJS) $(_LINK_LIBRARIES) $(BUILD_FLAGS)
	@printf '\n'
	$(call build_deps)

$(BLD_DIR)/$(_BASENAME): $(_TARGET_DEPS)
	$(call linking_with,$@)
	$(_Q)$(CC) $(_LIB_DIRS) $(_SYMBOLS) -o $@ $(ORIGIN_FLAG) $(OBJS) $(_LINK_LIBRARIES) $(BUILD_FLAGS)
	@printf '\n'
	$(call build_deps)

$(_DIRECTORIES):
	$(if $(_CLEAN),,@printf '\$(color_blue)')
	$(MKDIR) $@

clean:
	$(if $(_CLEAN),@prtinf '   $(color_blue)Cleaning old build files & folders...\n\n')
	$(_Q)$(RM) $(TARGET) $(DEPS) $(OBJS)
.PHONY: clean

#==============================================================================
# Production recipes

rmprod:
	@printf '\n'
	-$(_Q)rm -rf $(if $(filter osx,$(PLATFORM)),$(PRODUCTION_FOLDER_MACOS),$(PRODUCTION_FOLDER))
ifeq ($(PLATFORM),linux)
	-$(_Q)rm -rf ~/.local/share/applications/$(NAME).desktop
endif
.PHONY: rmprod

mkdirprod:
	$(MKDIR) $(PRODUCTION_FOLDER)
.PHONY: mkdirprod

define do_copy_to_clean
	@printf  '$(color_blue)$(UNI_COPY)  Copying \"$(1)\" to \"$(CURDIR)/$(2)\"\n'
	$(shell cp -r $(1) $(2))
endef

define do_copy_to
	@printf  '$(color_blue)cp -r $(1) $(2)\n'
	$(shell cp -r $(1) $(2))
endef

define copy_to
	$(if $(wildcard $(2)/$(notdir $(1))),,$(if $(_CLEAN),$(call do_copy_to_clean,$(1),$(2)),$(call do_copy_to,$(1),$(2))))
endef

releasetoprod: $(TARGET)
ifeq ($(PLATFORM),osx)
	@printf '   $(color_blue)Creating the MacOS application bundle...\n'
	@printf '\n'
	$(MKDIR) $(PRODUCTION_FOLDER)/Resources $(PRODUCTION_FOLDER)/Frameworks $(PRODUCTION_FOLDER)/MacOS
	$(_Q)sips -s format icns env/osx/$(PRODUCTION_MACOS_ICON).png --out $(PRODUCTION_FOLDER)/Resources/$(PRODUCTION_MACOS_ICON).icns
	@printf '\n'
	$(_Q)plutil -convert binary1 env/osx/Info.plist.json -o $(PRODUCTION_FOLDER)/Info.plist
	$(_Q)plutil -replace CFBundleExecutable -string $(NAME) $(PRODUCTION_FOLDER)/Info.plist
	$(_Q)plutil -replace CFBundleName -string $(PRODUCTION_MACOS_BUNDLE_NAME) $(PRODUCTION_FOLDER)/Info.plist
	$(_Q)plutil -replace CFBundleIconFile -string $(PRODUCTION_MACOS_ICON) $(PRODUCTION_FOLDER)/Info.plist
	$(_Q)plutil -replace CFBundleDisplayName -string "$(PRODUCTION_MACOS_BUNDLE_DISPLAY_NAME)" $(PRODUCTION_FOLDER)/Info.plist
	$(_Q)plutil -replace CFBundleIdentifier -string com.$(PRODUCTION_MACOS_BUNDLE_DEVELOPER).$(PRODUCTION_MACOS_BUNDLE_NAME) $(PRODUCTION_FOLDER)/Info.plist
	$(_Q)cp $(TARGET) $(PRODUCTION_FOLDER)/MacOS
	$(_Q)chmod +x $(PRODUCTION_FOLDER)/MacOS/$(NAME)
else ifeq ($(PLATFORM),linux)
	$(_Q)cp $(TARGET) $(PRODUCTION_FOLDER)
	$(_Q)cp env/linux/$(PRODUCTION_LINUX_ICON).png $(PRODUCTION_FOLDER)/$(PRODUCTION_LINUX_ICON).png
	$(_Q)cp env/linux/exec.desktop $(PRODUCTION_FOLDER)/$(NAME).desktop
	$(_Q)sed -i 's/^Exec=.*/Exec=$(_LINUX_GREP_CWD)\/$(PRODUCTION_FOLDER)\/$(NAME)/' $(PRODUCTION_FOLDER)/$(NAME).desktop
	$(_Q)sed -i 's/^Path=.*/Path=$(_LINUX_GREP_CWD)\/$(PRODUCTION_FOLDER)/' $(PRODUCTION_FOLDER)/$(NAME).desktop
	$(_Q)sed -i 's/^Name=.*/Name=$(PRODUCTION_LINUX_APP_NAME)/' $(PRODUCTION_FOLDER)/$(NAME).desktop
	$(_Q)sed -i 's/^Comment=.*/Comment=$(PRODUCTION_LINUX_APP_COMMENT)/' $(PRODUCTION_FOLDER)/$(NAME).desktop
	$(_Q)sed -i 's/^Icon=.*/Icon=$(_LINUX_GREP_CWD)\/$(PRODUCTION_FOLDER)\/$(PRODUCTION_LINUX_ICON).png/' $(PRODUCTION_FOLDER)/$(NAME).desktop
	$(_Q)chmod +x $(PRODUCTION_FOLDER)/$(NAME)
	$(_Q)chmod +x $(PRODUCTION_FOLDER)/$(NAME).desktop
	$(_Q)cp $(PRODUCTION_FOLDER)/$(NAME).desktop ~/.local/share/applications
else
	$(_Q)cp $(TARGET) $(PRODUCTION_FOLDER)
	$(if $(_CLEAN),,@printf '\n')
endif
.PHONY: releasetoprod

makeproduction: rmprod mkdirprod releasetoprod
ifneq ($(PRODUCTION_DEPENDENCIES),)
	@printf '   $(color_blue)Adding dynamic libraries & project dependencies...\n'
	@printf '\n'
	$(foreach dep,$(PRODUCTION_DEPENDENCIES),$(call copy_to,$(dep),$(PRODUCTION_FOLDER_RESOURCES)))
	$(foreach excl,$(PRODUCTION_EXCLUDE),$(shell find $(PRODUCTION_FOLDER_RESOURCES) -name '$(excl)' -delete))
endif
ifeq ($(PLATFORM),osx)
	$(foreach dylib,$(PRODUCTION_MACOS_DYLIBS),$(call copy_to,$(dylib),$(PRODUCTION_FOLDER)/MacOS))
	$(_Q)install_name_tool -add_rpath @executable_path/../Frameworks $(PRODUCTION_FOLDER)/MacOS/$(NAME)
	$(_Q)install_name_tool -add_rpath @loader_path/.. $(PRODUCTION_FOLDER)/MacOS/$(NAME)
	$(foreach dylib,$(PRODUCTION_MACOS_DYLIBS),$(shell install_name_tool -change @rpath/$(notdir $(dylib)) @rpath/MacOS/$(notdir $(dylib)) $(PRODUCTION_FOLDER)/MacOS/$(NAME)))
	$(foreach dylib,$(PRODUCTION_MACOS_DYLIBS),$(shell install_name_tool -change $(notdir $(dylib)) @rpath/MacOS/$(notdir $(dylib)) $(PRODUCTION_FOLDER)/MacOS/$(NAME)))
	$(foreach dylib,$(PRODUCTION_MACOS_DYLIBS),$(shell install_name_tool -change $(dylib) @rpath/MacOS/$(notdir $(dylib)) $(PRODUCTION_FOLDER)/MacOS/$(NAME)))
	$(foreach framework,$(PRODUCTION_MACOS_FRAMEWORKS),$(call copy_to,$(framework),$(PRODUCTION_FOLDER)/Frameworks))
ifeq ($(PRODUCTION_MACOS_MAKE_DMG),true)
	$(shell hdiutil detach /Volumes/$(PRODUCTION_MACOS_BUNDLE_NAME)/ &> /dev/null)
	@printf '\n'
	@printf '   $(color_blue)Creating the dmg image for the application...\n'
	@printf '\n'
	$(_Q)hdiutil create -megabytes 54 -fs HFS+ -volname $(PRODUCTION_MACOS_BUNDLE_NAME) $(PRODUCTION_FOLDER_MACOS)/.tmp.dmg > /dev/null
	$(_Q)hdiutil attach $(PRODUCTION_FOLDER_MACOS)/.tmp.dmg > /dev/null
	$(_Q)cp -r $(PRODUCTION_FOLDER_MACOS)/$(PRODUCTION_MACOS_BUNDLE_NAME).app /Volumes/$(PRODUCTION_MACOS_BUNDLE_NAME)/
	-$(_Q)rm -rf /Volumes/$(PRODUCTION_MACOS_BUNDLE_NAME)/.fseventsd
	$(MKDIR) /Volumes/$(PRODUCTION_MACOS_BUNDLE_NAME)/.background
	$(_Q)tiffutil -cathidpicheck $(PRODUCTION_MACOS_BACKGROUND).png $(PRODUCTION_MACOS_BACKGROUND)@2x.png -out /Volumes/$(PRODUCTION_MACOS_BUNDLE_NAME)/.background/background.tiff
	$(_Q)ln -s /Applications /Volumes/$(PRODUCTION_MACOS_BUNDLE_NAME)/Applications
	$(_Q)appName=$(PRODUCTION_MACOS_BUNDLE_NAME) osascript env/osx/dmg.applescript
	$(_Q)hdiutil detach /Volumes/$(PRODUCTION_MACOS_BUNDLE_NAME)/ > /dev/null
	$(_Q)hdiutil convert $(PRODUCTION_FOLDER_MACOS)/.tmp.dmg -format UDZO -o $(PRODUCTION_FOLDER_MACOS)/$(PRODUCTION_MACOS_BUNDLE_NAME).dmg > /dev/null
	$(_Q)rm -f $(PRODUCTION_FOLDER_MACOS)/.tmp.dmg
	@printf '\n'
	@printf '   $(color_blue)Created $(PRODUCTION_FOLDER_MACOS)/$(PRODUCTION_MACOS_BUNDLE_NAME).dmg\n'
endif
endif
.PHONY: makeproduction

#==============================================================================
# Dependency recipes
$(DEP_DIR)/%.d: ;
.PRECIOUS: $(DEP_DIR)/%.d

include $(wildcard $(DEPS))
