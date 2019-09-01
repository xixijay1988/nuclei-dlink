


ifeq ($(LINK),)
	LINK = hifive1
endif

include src/link/$(LINK)/Makefile

TARGET = k210

BUILD_DIR = build
EXE = $(LINK)-$(TARGET)


C_SOURCES +=  \
src/tap/rvl_tap.c \
src/main.c

C_INCLUDES +=  \
-Isrc/tap \
-Isrc/lib 

CC   = $(PREFIX)gcc
AS   = $(PREFIX)gcc -x assembler-with-cpp
COPY = $(PREFIX)objcopy
AR   = $(PREFIX)ar
SIZE = $(PREFIX)size
HEX  = $(COPY) -O ihex
BIN  = $(COPY) -O binary -S
DUMP = $(PREFIX)objdump

OPT = -Og

CFLAGS += -Wall -fdata-sections -ffunction-sections
CFLAGS += -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@:%.o=%.d)"
CFLAGS += -fstack-usage
CFLAGS += -g $(OPT) $(C_DEFS) $(C_INCLUDES)

ASFLAGS += -Wall -fdata-sections -ffunction-sections
ASFLAGS += -g $(OPT) $(C_DEFS) $(C_INCLUDES) $(AS_DEFS) $(AS_INCLUDES)

LDFLAGS += -g $(OPT) $(LIBDIR) $(LIBS) -Wl,-Map=$(BUILD_DIR)/$(EXE).map,--cref -Wl,--gc-sections




all: $(BUILD_DIR)/$(EXE).elf $(BUILD_DIR)/$(EXE).hex $(BUILD_DIR)/$(EXE).bin $(BUILD_DIR)/$(EXE).disasm

# list of objects
OBJECTS = $(addprefix $(BUILD_DIR)/,$(notdir $(C_SOURCES:.c=.o)))
vpath %.c $(sort $(dir $(C_SOURCES)))
# list of ASM program objects
OBJECTS += $(addprefix $(BUILD_DIR)/,$(notdir $(ASM_SOURCES:.S=.o)))
vpath %.S $(sort $(dir $(ASM_SOURCES)))

$(BUILD_DIR)/%.o: %.c Makefile | $(BUILD_DIR) 
	$(CC) -c $(CFLAGS) -Wa,-a,-ad,-alms=$(BUILD_DIR)/$(notdir $(<:.c=.lst)) $< -o $@

$(BUILD_DIR)/%.o: %.S Makefile | $(BUILD_DIR)
	$(AS) -c $(ASFLAGS) $< -o $@

$(BUILD_DIR)/$(EXE).elf: $(OBJECTS) Makefile
	$(CC) $(OBJECTS) $(LDFLAGS) -o $@
	$(SIZE) $@

$(BUILD_DIR)/%.hex: $(BUILD_DIR)/%.elf | $(BUILD_DIR)
	$(HEX) $< $@
	
$(BUILD_DIR)/%.bin: $(BUILD_DIR)/%.elf | $(BUILD_DIR)
	$(BIN) $< $@	
	
$(BUILD_DIR)/%.disasm: $(BUILD_DIR)/%.elf | $(BUILD_DIR)
	$(DUMP) -d $< > $@	
	
$(BUILD_DIR):
	mkdir $@

#######################################
# clean up
#######################################
clean:
	-rm -fR .dep $(BUILD_DIR)
  
#######################################
# dependencies
#######################################
-include $(shell mkdir .dep 2>/dev/null) $(wildcard .dep/*)
