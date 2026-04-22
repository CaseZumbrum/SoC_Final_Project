"""
mmap_example.py

Created by: Cameron Doig-Daniels, Case Zumbrum, Jacob Mack

Used for testing of memory mapped io in the user space, constantly moves data between adc and pwm values

Generally too slow to be very useful
"""
import os
import mmap
import sys
import select

XADC_BASE_ADDR = 0x44A00000
ADC_OFFSET = 0x200 + (17 << 2)

PWM_BASE_ADDR = 0x40000000

DMA_BASE_ADDR = 0x44a10000
DMA_SRC_OFFSET = 0x00000018
DMA_DEST_OFFSET = 0x00000020
DMA_START_LENGTH_OFFSET = 0x00000028
DMA_CONTROL_OFFSET = 0x00
DMA_STATUS_OFFSET = 0x04

MAP_SIZE = 4096 

LENGTH = 4

def bit_set(n:bytes, k:int):
    return (n[k//8] & (1 << (k%8))) != 0
    # return (n[len(n) - 1 - k//8] & (1 << (k%8))) != 0

def main():
    mode = 0
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


        print("Software-Side Guitar Pedal\n"
        "0 - Direct Wire to Output (No transform)\n"
        "1 - Hard Clipping Transform\n"
        "2 - Fuzz Transform")
        
        while True:
            if select.select([sys.stdin], [], [], 0)[0]:
                try:
                    mode = int(sys.stdin.readline().strip())
                    print(f"Mode changed to {mode}")
                except:
                    pass
            # check if bit is set
            if mode == 0:
                pwm[0:2] = adc[ADC_OFFSET:ADC_OFFSET+2]
            else:
                raw = int.from_bytes(adc[ADC_OFFSET:ADC_OFFSET+2], 'little')
                sample = (raw & 0x0FFF)
                if mode == 1:
                    sample = max(1000, min(3000, sample))
                if mode == 2:
                    midpoint = 2048

                    diff = sample - midpoint
                    diff = diff * 3
                    diff = int(diff / (1 + abs(diff)/2048))

                    sample = midpoint + diff
                sample = sample
                sample = max(0, min(4095, sample))

                pwm[0:2] = int(sample).to_bytes(2, 'little')
            
            
    except OSError as e:
        print(e)
    finally:
        os.close(fd)

if __name__ == "__main__":
    main()
