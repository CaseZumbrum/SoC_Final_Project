import os
import mmap
import struct

XADC_BASE_ADDR = 0x44A00000
MAP_SIZE = 4096 

def main():
    try:
        fd = os.open("/dev/mem", os.O_RDWR | os.O_SYNC)
    except PermissionError:
        print("ERROR: Run as root (sudo).")
        return

    try:
        mem = mmap.mmap(fd, 
                        length=MAP_SIZE, 
                        flags=mmap.MAP_SHARED, 
                        prot=mmap.PROT_READ | mmap.PROT_WRITE, 
                        offset=XADC_BASE_ADDR)

        target_offset = 0x00
        mem.seek(target_offset)
        raw_bytes = mem.read(4)
        reg_value = struct.unpack('<I', raw_bytes)[0]
        
        print(f"Value at {hex(target_offset)}: {hex(reg_value)}")
        mem.close()
    finally:
        os.close(fd)

if __name__ == "__main__":
    main()
