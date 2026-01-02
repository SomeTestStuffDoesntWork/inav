#include "DbgUtil.h"
#include "board.h"
#include "pin_mux.h"
#include "clock_config.h"


typedef struct
{
	gpio_pin_config_t config_;
	bool			  init_complete_;
	uint8_t			  pin_;
	GPIO_Type*		  handle_;
} DebugGpio_t;

// Debug GPIO configuration - Unless otherwise configured, this should be defaulted to
// GPIO from reset.
static DebugGpio_t kDebugGpio =
{
	.config_ =
	{
		.direction = kGPIO_DigitalOutput,
		.outputLogic = 0U,
		.interruptMode = kGPIO_NoIntmode
	},
	.init_complete_ = false,
	.pin_ = 3U,
	.handle_ = GPIO2
};

static void taskDelay(uint32_t msec)
{
	uint32_t delay_usec = msec * 1000;
	SDK_DelayAtLeastUs(delay_usec, SDK_DEVICE_MAXIMUM_CPU_CLOCK_FREQUENCY);
}

void blinkLed(uint32_t num_blink)
{
	if(!kDebugGpio.init_complete_)
	{
		GPIO_PinInit(kDebugGpio.handle_, kDebugGpio.pin_, &kDebugGpio.config_);
		kDebugGpio.init_complete_ = true;

		// Turn pin off & wait so user can see definitive start point. 1 sec is approx right.
		GPIO_PinWrite(kDebugGpio.handle_, kDebugGpio.pin_, 0U);
		taskDelay(1000);
	}

	// Loop for flash code.
	for(uint32_t current_blink = 0; current_blink < num_blink; current_blink++)
	{
		GPIO_PinWrite(kDebugGpio.handle_, kDebugGpio.pin_, 1U);
		taskDelay(200);
		GPIO_PinWrite(kDebugGpio.handle_, kDebugGpio.pin_, 0U);
		taskDelay(200);
	}
}

void indicateAlive(void)
{
    // Blink the LED four times, three times, then two times.
    blinkLed(4);
    taskDelay(1000);
    blinkLed(3);
    taskDelay(1000);
    blinkLed(2);
    taskDelay(1000);
}
