# Audio Hardware

## Vivado Environment
- in vivado run `source ADC_TOP.tcl`
- Generate bitstream
- Export XSA
## Vitis Environment
- All code is in `main.c`
## Current Usage
- Connect audio input to the `Horiz` pin on the Urbana board (bottom right of board). There are no headers, so I taped my connection down.
    - I am using my DAD board as audio input
    - Make sure the audio source shares ground with the Urbana
- Connect audio output to the audio jack (top left of board)
- Run the C code
## Explanation
- ADC is setup in main.c
- Audio samples are read across ADC, made available at XPAR_XADC_WIZ_0_BASEADDR + 17
- These samples are immediately written to PWM system (mapped at XPAR_XGPIO_0_BASEADDR)
- PWM system converts sample into PWM waveform
- On board circuitry converts PWM waveform to analog audio

## How to integrate with other stuff
- At OS level (when starting the system) setup ADC using similar code
- At OS level, start memory transfers (likely through a DMA system)
- At OS level, create syscalls for changing address that ADC is writing to (likely through a DMA system)
- To add effects, write audio samples to effect hardware (or software) and write output of that effect to the PWM system (basically just add a middle man)

## TODO
- Setup DMA system!!!
- Look into quality degredation
- Look into better way of accessing ADC (Avoid the hack)