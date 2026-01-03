/*
 * This file is part of INAV.
 *
 * INAV is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * INAV is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with INAV.  If not, see <http://www.gnu.org/licenses/>.
 */

#include "DbgUtil.h"
#include "board.h"
#include "pin_mux.h"
#include "clock_config.h"
#include "fsl_lpuart.h"


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


// Some UART setup
// Config for this device
static lpuart_config_t uart_config_;

#define UART_TRANSFER_SIZE 50

// Buffer that memory is copied into for uart transfers.
volatile uint8_t transfer_buffer[UART_TRANSFER_SIZE] = {0};

// Receive buffer.
#define RING_BUFFER_SIZE 500
uint8_t receiveRingBuffer[RING_BUFFER_SIZE] = {0};

typedef struct
{
	bool tx_in_progress;
	bool rx_in_progress;
	bool tx_full;
	bool rx_full;
} UartWorkState;

static lpuart_handle_t uartHandle;

volatile static UartWorkState uart_device_state_ =
{
	.tx_in_progress = false,
	.rx_in_progress = false,
	.tx_full = false,
	.rx_full = false
};

void uartWorkerCallback(LPUART_Type *base, lpuart_handle_t *handle, status_t status, void *userData)
{
    if (kStatus_LPUART_TxIdle == status)
    {
    	uart_device_state_.tx_full        = false;
        uart_device_state_.tx_in_progress = false;
    }

    if (kStatus_LPUART_RxIdle == status)
    {
    	uart_device_state_.rx_full        = false;
        uart_device_state_.rx_in_progress = false;
    }
}

void initUartComms(uint32_t baud_rate)
{
	LPUART_GetDefaultConfig(&uart_config_);
	uart_config_.baudRate_Bps  = baud_rate;
	uart_config_.enableTx      = true;
	uart_config_.stopBitCount  = kLPUART_OneStopBit;
    uart_config_.parityMode    = kLPUART_ParityDisabled;
    uart_config_.dataBitsCount = kLPUART_EightDataBits;
	uart_config_.enableRx     = true;

	// Strange to see the debug frequency here, but checks if PLL or raw oscillator and applies
	// accordingly
    uint32_t uart_clock_freq = BOARD_DebugConsoleSrcFreq();
    LPUART_Init(LPUART6, &uart_config_, uart_clock_freq);
    // Setup handler, don't pass in any user data - not needed.
    LPUART_TransferCreateHandle(LPUART6, &uartHandle, uartWorkerCallback, NULL);
    LPUART_TransferStartRingBuffer(LPUART6, &uartHandle, receiveRingBuffer, RING_BUFFER_SIZE);
}

void handleReceivedUartEcho()
{

}

void reroutConsoleDebug(uint8_t uart_idx, uint32_t baud)
{
	DbgConsole_Init(uart_idx, baud, 1U, BOARD_DebugConsoleSrcFreq());
}