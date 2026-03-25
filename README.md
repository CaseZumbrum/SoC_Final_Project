# SoC_Final_Project

Final project repository for EEL4930

## Team Members
1. Case Zumbrum (Undergraduate)

## Brainstorming

### Audio Processor
Essentially we would create a guitar pedal. Takes in single ended audio signal (probably across ADC since there is no dedicated audio I can find) and produces some output (delay, distortion, wah). I (case) did something similar but fully on FPGA before.

* OS: Handle which effect is currently playing, software to do simple transforms. Would need to store audio waveform in buffer.
* Hardware: FPGA FFT for mixing control, hardware acceleration for delay possibly, audio output control
* Circuitry: Possibly need to extend (or use cusom) adc

![Audio Pedal Chart](./images/audio_brainstorm.png)