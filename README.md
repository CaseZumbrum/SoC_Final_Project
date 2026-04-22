# SoC_Final_Project

Final project repository for EEL4930

## Team Members
1. Case Zumbrum (Undergraduate)
2. Jacob Mack (Undergraduate)
3. Cameron Doig-Daniels (Undergraduate)
4. William Jones (Graduate)

### Audio Processor
Essentially we created a guitar pedal. Takes in single ended audio signal (across ADC since there is no dedicated audio I can find) and produces some output (delay, distortion, wah).

* OS: Handle which effect is currently playing, software to do simple transforms. Would need to store audio waveform in buffer.
* Hardware: FPGA FFT for mixing control, hardware acceleration for delay possibly, audio output control

![Audio Pedal Chart](./images/audio_brainstorm.png)

#### Implementation

###### Hardware
* XADC system: Already on Urbana board, 12bit ~1MHz, supports AXI interface, produces sampled audio
* Audio buffer: Use AXI/DMA possibly to read in data from XADC, stores a frame of sampled audio
* Echo Effect: Take in audio samples, store in buffer and add past samples to current sample (with some delay)
* Reverb Effect: Take in audio samples, store in buffer and add past samples to current sample (with some shorter delay), will recursively store past values for a gradual reverb.
* PWM System: Consumes audio output buffer and converts it from sampled audio into a PWM signal (to be sent across audio jack)

###### Software
* Control System: setup DMA, control effects from CLI
* Clip Effect: Take in audio samples and clip to a configurable threshold value
* Fuzz Effect: Take in audio samples, clip to threshold, and scale to introduce distortion 
