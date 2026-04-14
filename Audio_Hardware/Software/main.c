#include "xsysmon.h"
#include "xparameters.h"
#include "xaxicdma.h"
#include <stdint.h>
#include "stdio.h"
#include "xuartlite.h"
#include "xstatus.h"
#include <xsysmon_hw.h>
#include "xuartlite_l.h"

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

XSysMon XadcInst;

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
  int standard = (int)(data >> 4) - 2048;

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

//Main Function:

int main() {
    XSysMon_Config *ADC_ConfigPtr;
    XAxiCdma xAxiCdmaInstance;
    XAxiCdma_Config *DMA_ConfigPtr; 
    u16 RawData;
    int mode = 0;
    u16 TransformedData = 0;
    u16* gpio = (u16 *) XPAR_XGPIO_0_BASEADDR;
    u16* adc = (u16 *) (XPAR_XADC_WIZ_0_BASEADDR + XSM_TEMP_OFFSET + (17 << 2));

    // initialize DMA
    DMA_ConfigPtr = XAxiCdma_LookupConfig(XPAR_AXI_CDMA_0_BASEADDR);
    XAxiCdma_CfgInitialize(&xAxiCdmaInstance, DMA_ConfigPtr,
					DMA_ConfigPtr->BaseAddress);

    // Initialize the XADC driver
    ADC_ConfigPtr = XSysMon_LookupConfig(XPAR_XADC_WIZ_0_BASEADDR);
    if (ADC_ConfigPtr == NULL) return XST_FAILURE;
    
    XSysMon_CfgInitialize(&XadcInst, ADC_ConfigPtr, ADC_ConfigPtr->BaseAddress);

    // Configure the Sequencer
    // First, set to Safe Mode to allow configuration changes
    XSysMon_SetSequencerMode(&XadcInst, XSM_SEQ_MODE_SAFE);

    // Enable aux channel  
    XSysMon_SetSeqChEnables(&XadcInst, XSM_SEQ_CH_AUX01);

    // Set ADC to keep running (not event based)
    XSysMon_SetSequencerMode(&XadcInst, XSM_SEQ_MODE_CONTINPASS);

    XSysMon_SetSeqInputMode(&XadcInst, XSM_CFR0_DU_MASK);
    XSysMon_SetAvg(&XadcInst, XSM_AVG_64_SAMPLES);

    printf(
        "Select the type of Software Transform you'd like to perform:\n"
            "0. No Transform\n"
            "1. Distortion - Hard Clipping\n"
            "2. Distortion - Fuzz\n"
            "3. Delay - Echo\n"
            "4. Reverb\n"
        ); 
    while(1) {
        // Wait for data to finish
        while ((XSysMon_GetStatus(&XadcInst) & XSM_SR_EOS_MASK) != XSM_SR_EOS_MASK);

        // DMA
        XStatus Status = XAxiCdma_SimpleTransfer(&xAxiCdmaInstance, (UINTPTR)adc, (UINTPTR)gpio, sizeof(u16), NULL, NULL);
        if(Status != XST_SUCCESS) 
        {
            print("AXI CDMA 0 Transfer Failed\n\r");
            // send data manually
            gpio[0] = *adc;
            
        }
        while(XAxiCdma_IsBusy(&xAxiCdmaInstance));
    }

    return 0;
}
