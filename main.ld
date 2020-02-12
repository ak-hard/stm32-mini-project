INCLUDE "stm32_common.ld"

REGION_ALIAS("PROG", FLASH);
/*REGION_ALIAS("PROG", RAM);*/

__stack_end__ = SRAM_BASE + SRAM_SIZE;
MIN_STACK_SIZE = 0x100;

INCLUDE "stm32_sections.ld"
