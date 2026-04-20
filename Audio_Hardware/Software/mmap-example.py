import os
import mmap

XADC_BASE_ADDR = 0x44A00000
PWM_BASE_ADDR = 0x40000000
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

        adc_offset = 0x200 + (17 << 2)
                
        while True:
            pwm[0:2] = adc[adc_offset:adc_offset+2]
            
    except OSError as e:
        print(e)
    finally:
        os.close(fd)

if __name__ == "__main__":
    main()
