# Tasks

## Audio Hardware - Case
- read in audio signal across ADC, store in buffer
- PDM converter to go from buffer to output
- Hardware audio effects

## Processor Hardware - William
- Set up microblaze
- Set up fifo/buffer for audio output
- setup axi interfaces
- setup dma system for buffer transfer

## OS - Cameron
- load linux onto FPGA
- add module onto linux
- auto-load files onto linux
- do DMA from user space?
- get control signals out
- handle several sources reading audio buffer (several audio buffers?)

## Software - Jacob
- Control module
- CLI interface for controls
- Software audio effects
