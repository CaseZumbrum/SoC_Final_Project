"""
mmap_example.py

Created by: Cameron Doig-Daniels, Case Zumbrum

Used for testing of memory mapped io in the user space, constantly moves data between adc and pwm values

Generally too slow to be very useful
"""

import os
import mmap


XADC_BASE_ADDR = 0x44A00000
ADC_OFFSET = 0x200 + (17 << 2)

PWM_BASE_ADDR = 0x40000000

ECHO_BASE_ADDR = 0x40010000
REVERB_BASE_ADDR = 0x40020000

MAP_SIZE = 4096     

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
        echo = mmap.mmap(fd, 
                        length=MAP_SIZE, 
                        flags=mmap.MAP_SHARED, 
                        prot=mmap.PROT_READ | mmap.PROT_WRITE, 
                        offset=ECHO_BASE_ADDR)
        

        print("Starting")
        while True:
            pwm[0] = adc[ADC_OFFSET]
            pwm[1] = adc[ADC_OFFSET + 1]
    except OSError as e:
        print(e)
    finally:
        os.close(fd)

if __name__ == "__main__":
    main()
