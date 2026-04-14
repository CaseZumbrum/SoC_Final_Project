#include "xsysmon.h"
#include "xparameters.h"
#include "xaxicdma.h"
#include "stdio.h"
#include "xstatus.h"
#include <xsysmon_hw.h>


XSysMon XadcInst;

int main() {
    XSysMon_Config *ADC_ConfigPtr;
    XAxiCdma xAxiCdmaInstance;
    XAxiCdma_Config *DMA_ConfigPtr; 
    u16 RawData;
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
