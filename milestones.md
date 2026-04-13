# Timeline/Milestones

## Circuitry - Case
 1. Test filter/pre-amp on an actual amp

## Audio Hardware - Case
1. read in signal across ADC (DONE)
2. PDM converter (DONE)
3. create audio pass-through system (no effect) running through fpga (DONE)
4. Store audio wave in buffer (DONE)
5. read from buffer to output across pdm (DONE)

## Processor Hardware - William
1. Define hardware in vivado
2. Build FIFO/buffer system
3. Use AXI connects to map buffers to memory
4. Figure out DMA for reading/transferring buffers
4. Build XSA file

## OS - Cameron
1. Find what OS modules we need/basic OS setup
2. Figure out how to add custom module
3. Figure out how to pre-load files into the filesystem
4. DMA from user space (or more likely from OS module)?
5. Figure out how to get buffers into user space

## Software - Jacob
1. Build out module to send out control signals (probably just like a binary number that selects an effect)
2. CLI interface
3. Implement a simple software transparent effect (read in audio buffer, output audio buffer without a change)
4. Implement an audio saving system (look into wav standard probably)
5. Look into software effects we could do
