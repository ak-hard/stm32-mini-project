#include <stdint.h>

#include <stm32f10x.h>

#define CPU_FREQ HSI_VALUE
#define LED_PORT GPIOC
#define LED_PIN 13

enum GPIO_PIN_MODE
{
	GPIO_INPUT_ANALOG = 0 << 2,
	GPIO_INPUT_FLOATING = 1 << 2,
	GPIO_INPUT_PULLED = 2 << 2,

	GPIO_OUTPUT_PUSH_PULL = 0 << 2,
	GPIO_OUTPUT_OPEN_DRAIN = 1 << 2,

	GPIO_AF_PUSH_PULL = 2 << 2,
	GPIO_AF_OPEN_DRAIN = 3 << 2,
};

enum GPIO_PIN_SPEED
{
	GPIO_INPUT = 0,
	GPIO_OUTPUT_SPEED_LOW = 2,
	GPIO_OUTPUT_SPEED_MEDIUM = 1,
	GPIO_OUTPUT_SPEED_HIGH = 3,
};

void gpio_configure_pin(GPIO_TypeDef *port, unsigned pin, unsigned mode)
{
	unsigned reg_index = pin / 8u;
	volatile uint32_t *CR = &port->CRL;
	pin %= 8u;
	CR[reg_index] = (CR[reg_index] & ~(0x0f << (pin * 4))) | (mode << (pin * 4));
}

unsigned systick_time_diff(uint32_t t0, uint32_t t)
{
	return (t0 - t) & 0xffffffu;
}

unsigned systick_time_interval(uint32_t *t0)
{
	uint32_t t = SysTick->VAL;
	unsigned delta = systick_time_diff(*t0, t);
	*t0 = t;
	return delta;
}

int periodic_timer(unsigned *timer, unsigned interval, unsigned elapsed)
{
	uint32_t t = *timer + elapsed;
	int f = t >= interval;
	if (f)
		t -= interval;
	*timer = t;
	return f;
}

int main()
{
	SysTick->LOAD = SysTick_LOAD_RELOAD_Msk;
	SysTick->VAL = 0;
	SysTick->CTRL = SysTick_CTRL_CLKSOURCE_Msk | SysTick_CTRL_ENABLE_Msk;

	RCC->APB2ENR |= RCC_APB2ENR_IOPCEN;
	__asm volatile("dsb");
	__asm volatile("dsb");

	gpio_configure_pin(LED_PORT, LED_PIN, GPIO_OUTPUT_PUSH_PULL | GPIO_OUTPUT_SPEED_LOW);

	uint32_t clock = SysTick->VAL;
	unsigned led_time = 0;
	while (1)
	{
		unsigned elapsed = systick_time_interval(&clock);
		if (periodic_timer(&led_time, CPU_FREQ / 2, elapsed))
			LED_PORT->ODR ^= 1 << LED_PIN;
	}

	return 0;
}
