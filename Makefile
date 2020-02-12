PREFIX=arm-none-eabi-
ARM_CMSIS=$(HOME)/arm-cmsis
STM32_CMSIS=$(HOME)/stm32-cmsis
STM32_LIB=$(HOME)/stm32-mini-lib

MCU = STM32F10X_MD
CPU_OPT = -mcpu=cortex-m3
LDFLAGS += -Wl,--defsym=SRAM_SIZE=20K,--defsym=FLASH_SIZE=64K

OPTIONS += -D_DEBUG #-DNDEBUG

COMMON_OPTS = $(CPU_OPT) -mthumb
COMPILE_OPTS = $(COMMON_OPTS) -fno-tree-loop-distribute-patterns -fdata-sections -ffunction-sections -Wall -g -O3 -D$(MCU) $(OPTIONS)
INCLUDE_DIRS = -I$(ARM_CMSIS) -I$(STM32_CMSIS) -I$(STM32_LIB)
LIBRARY_DIRS = -L$(STM32_LIB)

CFLAGS += $(COMPILE_OPTS) $(INCLUDE_DIRS)
CXXFLAGS += $(COMPILE_OPTS) $(INCLUDE_DIRS) -fno-exceptions -fno-rtti
ASFLAGS += $(COMPILE_OPTS)
LDFLAGS += $(COMMON_OPTS) -Wl,--gc-sections,-Map=$@.map,-cref,-Tmain.ld -nostartfiles $(LIBRARY_DIRS)

include $(STM32_LIB)/Makefile.inc

BINARIES=main

BIN_FILES=$(patsubst %,$(BINDIR)/%.bin,$(BINARIES))
CLEAN_FILES += $(BIN_FILES)

all: $(BINDIR)/main.bin

STM32_LIB_SRC=startup.c
STM32_LIB_OBJ=$(patsubst %.c, $(OBJDIR)/%.o, $(STM32_LIB_SRC))
$(foreach d,$(STM32_LIB_SRC),$(eval $(call make-obj-c,$d,$(STM32_LIB))))

MAIN_SRC=main.c
MAIN_OBJ=$(patsubst %.c, $(OBJDIR)/%.o, $(MAIN_SRC))
$(foreach d,$(MAIN_SRC),$(eval $(call make-obj-c,$d,.)))

ALL_OBJ=$(MAIN_OBJ) $(STM32_LIB_OBJ)

$(BINDIR)/main: $@ $(ALL_OBJ) $(STM32_LIB)/$(LD_SCRIPT) Makefile
	$(LD) $(LDFLAGS) -o $@ $(ALL_OBJ)
	$(OBJDUMP) -h -S -C $@ >$@.lst

$(BINDIR)/main.bin: $(BINDIR)/main
	$(OBJCP) $(OBJCPFLAGS) $< $@

CLEAN_FILES += $(BINDIR)/main $(BINDIR)/main.map $(BINDIR)/main.lst

.PHONY: clean
clean:
	-rm $(CLEAN_FILES)
