import os
import mmap

XADC_BASE_ADDR = 0x44A00000
ADC_OFFSET = 0x200 + (17 << 2)

PWM_BASE_ADDR = 0x40000000

DMA_BASE_ADDR = 0x44a10000
DMA_SRC_OFFSET = 0x00000018
DMA_DEST_OFFSET = 0x00000020
DMA_START_LENGTH_OFFSET = 0x00000028
DMA_CR_OFFSET = 0x00

MAP_SIZE = 4096 

LENGTH = 4

def main():
    try:
        fd = os.open("/dev/mem", os.O_RDWR | os.O_SYNC)
    except PermissionError:
        print("ERROR: Run as root (sudo).")
        return

    try:
        adc = mmap.mmap(fd, 
                        length=MAP_SIZE, 
                        flags=mmap.MAP_SHARED, 
                        prot=mmap.PROT_READ | mmap.PROT_WRITE, 
                        offset=XADC_BASE_ADDR)
        pwm = mmap.mmap(fd, 
                        length=MAP_SIZE, 
                        flags=mmap.MAP_SHARED, 
                        prot=mmap.PROT_READ | mmap.PROT_WRITE, 
                        offset=PWM_BASE_ADDR)
        
        dma = mmap.mmap(fd, 
                        length=MAP_SIZE, 
                        flags=mmap.MAP_SHARED, 
                        prot=mmap.PROT_READ | mmap.PROT_WRITE, 
                        offset=DMA_BASE_ADDR)

        # Reset DMA
        # dma[DMA_CR_OFFSET:DMA_CR_OFFSET+4] = (0x4).to_bytes(4, 'little')
        
        dma[DMA_SRC_OFFSET:DMA_SRC_OFFSET+4] = (XADC_BASE_ADDR + ADC_OFFSET).to_bytes(4, 'little')
        dma[DMA_DEST_OFFSET:DMA_DEST_OFFSET+4] = PWM_BASE_ADDR.to_bytes(4, 'little')
        print("Starting")
        while True:
            dma[DMA_START_LENGTH_OFFSET:DMA_START_LENGTH_OFFSET+4] = LENGTH.to_bytes(4, 'little')
            # pwm[0:2] = adc[ADC_OFFSET:ADC_OFFSET+2]
            
    except OSError as e:
        print(e)
    finally:
        os.close(fd)

if __name__ == "__main__":
    main()
