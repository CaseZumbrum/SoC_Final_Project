/*
audio_application.c

Main code for the audio transformation application

Created by: Case Zumbrum
*/

#include <stdio.h>
#include <stdint.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>

//              Addresses
// --------------------------------------
#define XADC_BASE_ADDR  0x44A00000
#define ADC_OFFSET      (0x200 + (17 << 2))

#define PWM_BASE_ADDR   0x40000000

#define ECHO_BASE_ADDR  0x40010000

#define REVERB_BASE_ADDR    0x40020000

#define DMA_BASE_ADDR   0x44A10000
#define DMA_SRC_OFFSET  0x18
#define DMA_DST_OFFSET  0x20
#define DMA_LEN_OFFSET  0x28
#define DMA_CTRL_OFFSET 0x00
#define DMA_STAT_OFFSET 0x04

//              Useful constants
// --------------------------------------
#define MAP_SIZE 4096
#define LENGTH   4

//              Bit operations
// --------------------------------------
static int bit_set(uint32_t value, int bit)
{
    return (value & (1 << bit)) != 0;
}

//          Supporting functions
// --------------------------------------

int DMA_Transfer(uint32_t *dma, uint32_t src, uint32_t dst, uint32_t length){
    // Wait until DMA idle
    while (!bit_set(dma[DMA_STAT_OFFSET / 4], 1));

    // Set source and destination
    dma[DMA_SRC_OFFSET / 4] = src;
    dma[DMA_DST_OFFSET / 4] = dst;
    // Trigger transfer
    dma[DMA_LEN_OFFSET / 4] = LENGTH;

    return 1;
}

uint16_t clip(uint16_t data){
  int threshold = 1500; //CAN BE CHANGED!

  if (data > threshold) data = threshold;
  if (data < -threshold) data = -threshold;

  return (uint16_t)(data + 2048);
}

uint16_t fuzz(uint16_t data){
  int threshold = 500; //CAN BE CHANGED
  if (data > threshold) data = threshold;
  if (data < -threshold) data = -threshold;

  data *= 3;
  return (uint16_t)(data + 2048); //TOTAL VALUE OF STANDARD SHOULD NOT EXCEED 4095.
}

//              Main code
// --------------------------------------
int main()
{
    // open os memory space (requires root access)
    int fd = open("/dev/mem", O_RDWR | O_SYNC);
    if (fd < 0) {
        perror("open /dev/mem failed (run as root)");
        return 1;
    }

    // create memory maps for IO
    void *adc_map = mmap(NULL, MAP_SIZE,
                         PROT_READ | PROT_WRITE,
                         MAP_SHARED,
                         fd,
                         XADC_BASE_ADDR);

    void *pwm_map = mmap(NULL, MAP_SIZE,
                         PROT_READ | PROT_WRITE,
                         MAP_SHARED,
                         fd,
                         PWM_BASE_ADDR);

    void *echo_map = mmap(NULL, MAP_SIZE,
                         PROT_READ | PROT_WRITE,
                         MAP_SHARED,
                         fd,
                         ECHO_BASE_ADDR);

    void *reverb_map = mmap(NULL, MAP_SIZE,
                         PROT_READ | PROT_WRITE,
                         MAP_SHARED,
                         fd,
                         REVERB_BASE_ADDR);

    void *dma_map = mmap(NULL, MAP_SIZE,
                         PROT_READ | PROT_WRITE,
                         MAP_SHARED,
                         fd,
                         DMA_BASE_ADDR);

    
    if (adc_map == MAP_FAILED || pwm_map == MAP_FAILED || dma_map == MAP_FAILED) {
        perror("mmap failed");
        close(fd);
        return 1;
    }

    // get pointers for memory maps
    volatile uint16_t *adc = (volatile uint16_t *)adc_map;
    volatile uint16_t *pwm = (volatile uint16_t *)pwm_map;
    volatile uint16_t *echo = (volatile uint16_t *)echo_map;
    volatile uint16_t *reverb = (volatile uint16_t *)reverb_map;

    volatile uint32_t *dma = (volatile uint32_t *)dma_map;

    int input;
    printf("0: Passthrough\n1: Echo\n2: Reverb\n3: Clipping (software)\n4: fuzz (software)\n"); 
    scanf("%d", &input);

    // fuzz
    if(input == 4){
        while(1){
            pwm[0] = fuzz(adc[ADC_OFFSET/2]);
        }
    }
    // clipping
    else if(input == 3){
        while(1){
            pwm[0] = clip(adc[ADC_OFFSET/2]);
        }
    }
    // hardware effects
    else{
        printf("Resetting DMA...\n");

        // Reset DMA
        dma[DMA_CTRL_OFFSET / 4] = 0x4;

        // Wait for idle
        while (!bit_set(dma[DMA_STAT_OFFSET / 4], 1));

        printf("Starting DMA loop...\n");

        // reverb
        if(input == 2){
            while (1){
                reverb[0] = adc[ADC_OFFSET/2];
                pwm[0] =  reverb[0];
                // DMA_Transfer(dma, (uint32_t) (XADC_BASE_ADDR + ADC_OFFSET), (uint32_t) REVERB_BASE_ADDR, (uint32_t) LENGTH);
                // DMA_Transfer(dma, (uint32_t) ECHO_BASE_ADDR, (uint32_t) REVERB_BASE_ADDR, (uint32_t) LENGTH);
            }   
        }
        // echo
        else if(input == 1){
            while (1)
            {
                echo[0] = adc[ADC_OFFSET/2];
                pwm[0] =  echo[0];
                // DMA_Transfer(dma, (uint32_t) (XADC_BASE_ADDR + ADC_OFFSET), (uint32_t) ECHO_BASE_ADDR, (uint32_t) LENGTH);
                // DMA_Transfer(dma, (uint32_t) ECHO_BASE_ADDR, (uint32_t) PWM_BASE_ADDR, (uint32_t) LENGTH);
            }
        }
        // passthrough
        else{
            // Set source and destination
            dma[DMA_SRC_OFFSET / 4] = (uint32_t) (XADC_BASE_ADDR + ADC_OFFSET);
            dma[DMA_DST_OFFSET / 4] = (uint32_t) PWM_BASE_ADDR;
            while (1)
            {
                // Wait until DMA idle
                while (!bit_set(dma[DMA_STAT_OFFSET / 4], 1));

                // Trigger transfer
                dma[DMA_LEN_OFFSET / 4] = LENGTH;
            }
        }      
    }
    
    munmap(adc_map, MAP_SIZE);
    munmap(pwm_map, MAP_SIZE);
    munmap(echo_map, MAP_SIZE);
    munmap(reverb_map, MAP_SIZE);
    munmap(dma_map, MAP_SIZE);
    close(fd);

    return 0;
}