#include <stdio.h>
#include <stdint.h>
#include <xil_types.h>

#ifndef EFFECTS_H
#define EFFECTS_H


//for Echo
#define DELAY_SIZE 1024
static int delayBuffer[DELAY_SIZE] = {0};
static int writeIndex = 0; //use globals for memory.

//for Reverb
#define REVERB_SIZE 512
static int reverb1[REVERB_SIZE] = {0};
static int reverb2[REVERB_SIZE] = {0};
static int reverb3[REVERB_SIZE] = {0};

static int rIdx1 = 0;
static int rIdx2 = 0;
static int rIdx3 = 0;

//Begin Main

//Echo Function
int EchoSoftware(int x)
{
    x = x >> 1;   // reduce input level
    int delayed = delayBuffer[writeIndex];

    int wet = delayed >> 1;      // echo level
    int fb  = delayed >> 3;      // feedback level

    int out = x + wet;

    int newSample = x + fb;
    
    //clamp
    if (newSample > 2047) newSample = 2047;
    if (newSample < -2048) newSample = -2048;

    delayBuffer[writeIndex] = newSample;

    writeIndex++;
    if (writeIndex >= DELAY_SIZE)
        writeIndex = 0;

    // clamp again
    if (out > 2047) out = 2047;
    if (out < -2048) out = -2048;

    return out;
}


//Extremely Scuffed Reverb Function (idk how it sounds lol)
int ReverbSoftware(int x)
{
    x = x >> 1; 

    int d1 = reverb1[rIdx1];
    int d2 = reverb2[rIdx2];
    int d3 = reverb3[rIdx3];

    int wet = (d1 + d2 + d3) / 3;

    int out = x + (wet >> 1);

    int f1 = x + (d1 >> 2) + (d2 >> 3);
    int f2 = x + (d2 >> 2) + (d3 >> 3);
    int f3 = x + (d3 >> 2) + (d1 >> 3);

    reverb1[rIdx1] = f1;
    reverb2[rIdx2] = f2;
    reverb3[rIdx3] = f3;

    rIdx1 = (rIdx1 + 1) % REVERB_SIZE;
    rIdx2 = (rIdx2 + 3) % REVERB_SIZE;
    rIdx3 = (rIdx3 + 5) % REVERB_SIZE;

    if (out > 2047) out = 2047;
    if (out < -2048) out = -2048;

    return out;
}

//Simple Software Effects Function

u16 TransformSoftware(u16 data, int transformtype) {
  if (transformtype == 0) return data;

  //Normalize + Center
  //int standard = (int)(data >> 4) - 2048;
    int standard = data;
  //HARD CLIPPING ALGORITHM:
  if (transformtype == 1) {
    int threshold = 420; //CAN BE CHANGED!

    if (standard > threshold) standard = threshold;
    if (standard < -threshold) standard = -threshold;

    return (u16)(standard + 2048);
  }

  //FUZZ ALGORTHIM:
  if (transformtype == 2) {
    int threshold = 500; //CAN BE CHANGED
    if (standard > threshold) standard = threshold;
    if (standard < -threshold) standard = -threshold;

    standard = standard * 3;
    return (u16)(standard + 2048); //TOTAL VALUE OF STANDARD SHOULD NOT EXCEED 4095.
  }
  if (transformtype == 3) {
    return(u16)(EchoSoftware(standard) + 2048);
  }
  if (transformtype == 4) {
    return (u16)(ReverbSoftware(standard) + 2048);
  }
  
  return data;
}

#endif