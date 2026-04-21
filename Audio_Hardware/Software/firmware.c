#include "xsysmon.h"
#include "xparameters.h"
#include "xaxicdma.h"
#include <stdint.h>
#include "stdio.h"
#include "xuartlite.h"
#include "xstatus.h"
#include <xsysmon_hw.h>
#include "xuartlite_l.h"

#include "effects.h"


XStatus init_dma(XAxiCdma *DMA_inst){
    XAxiCdma_Config *DMA_ConfigPtr  = XAxiCdma_LookupConfig(XPAR_AXI_CDMA_0_BASEADDR);
    return XAxiCdma_CfgInitialize(DMA_inst, DMA_ConfigPtr,DMA_ConfigPtr->BaseAddress);
}

XStatus init_adc(XSysMon *ADC_inst){
    XSysMon_Config* ADC_ConfigPtr = XSysMon_LookupConfig(XPAR_XADC_WIZ_0_BASEADDR);
    if (ADC_ConfigPtr == NULL) return XST_FAILURE;
    
    XSysMon_CfgInitialize(ADC_inst, ADC_ConfigPtr, ADC_ConfigPtr->BaseAddress);

    // Configure the Sequencer
    // First, set to Safe Mode to allow configuration changes
    XSysMon_SetSequencerMode(ADC_inst, XSM_SEQ_MODE_SAFE);

    // Enable aux channel  
    XSysMon_SetSeqChEnables(ADC_inst, XSM_SEQ_CH_AUX01);

    // Set ADC to keep running (not event based)
    XSysMon_SetSequencerMode(ADC_inst, XSM_SEQ_MODE_CONTINPASS);

    XSysMon_SetSeqInputMode(ADC_inst, XSM_CFR0_DU_MASK);
    XSysMon_SetAvg(ADC_inst, XSM_AVG_64_SAMPLES);
    return XST_SUCCESS;
}

//Main Function:

int main() {

    // used for status signals
    XStatus status;

    // adc driver
    XSysMon ADC_inst;
    // dma driver
    XAxiCdma DMA_inst;

    u16 RawData;

    int mode = 0;
    u16 TransformedData = 0;

    u16* gpio = (u16 *) XPAR_XGPIO_0_BASEADDR;
    u16* adc = (u16 *) (XPAR_XADC_WIZ_0_BASEADDR + XSM_TEMP_OFFSET + (17 << 2));
    u16* echo = (u16 *) XPAR_ECHO_GPIO_BASEADDR;
    u16* reverb = (u16 *) XPAR_REVERB_GPIO_BASEADDR;


    // initialize DMA
    status = init_dma(&DMA_inst);
    if(status == XST_FAILURE){
        print("Failed to init dma");
        return -1;
    }

    // Initialize the XADC driver
    status = init_adc(&ADC_inst);
    if(status == XST_FAILURE){
        print("Failed to init adc");
        return -1;
    }

    print(
        "Select the type of Software Transform you'd like to perform:\n"
            "0. No Transform\n"
            "1. Distortion - Hard Clipping\n"
            "2. Distortion - Fuzz\n"
            "3. Delay - Echo\n"
            "4. Reverb\n"
        ); 

    while(1) {
        // Wait for data to finish
        while ((XSysMon_GetStatus(&ADC_inst) & XSM_SR_EOS_MASK) != XSM_SR_EOS_MASK);

        // Read channel data
        RawData = XSysMon_GetAdcData(&ADC_inst, XSM_CH_AUX_MIN + 1);
        // Apply Transform from Included Header File
        TransformedData = TransformSoftware(RawData, mode);
        // send data to PWM module
        reverb[0] = TransformedData;
        // send data to PWM module
        gpio[0] = reverb[0];

        // ADC SETUP (NOT AS USEFUL WHEN DOING SOFTWARE EFFECTS)
        // XStatus Status = XAxiCdma_SimpleTransfer(&DMA_inst, (UINTPTR)adc, (UINTPTR)gpio, sizeof(u16), NULL, NULL);
        // if(Status != XST_SUCCESS) 
        // {
        //     print("AXI CDMA 0 Transfer Failed\n\r");
        //     // send data manually
        //     gpio[0] = *adc;
            
        // }
        // while(XAxiCdma_IsBusy(&DMA_inst));
    }

    return 0;
}


