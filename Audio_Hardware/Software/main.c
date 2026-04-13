#include "xsysmon.h"
#include "xparameters.h"
#include "stdio.h"
#include "xstatus.h"
#include <xsysmon_hw.h>


XSysMon XadcInst;

int main() {
    XSysMon_Config *ConfigPtr;
    u16 RawData;
    u16* gpio = (u16 *) XPAR_XGPIO_0_BASEADDR;

    // Initialize the XADC driver
    ConfigPtr = XSysMon_LookupConfig(XPAR_XADC_WIZ_0_BASEADDR);
    if (ConfigPtr == NULL) return XST_FAILURE;
    
    XSysMon_CfgInitialize(&XadcInst, ConfigPtr, ConfigPtr->BaseAddress);

    // Configure the Sequencer
    // First, set to Safe Mode to allow configuration changes
    XSysMon_SetSequencerMode(&XadcInst, XSM_SEQ_MODE_SAFE);

    // Enable aux channel  
    XSysMon_SetSeqChEnables(&XadcInst, XSM_SEQ_CH_AUX01);

    // Set ADC to keep running (not event based)
    XSysMon_SetSequencerMode(&XadcInst, XSM_SEQ_MODE_CONTINPASS);

    while(1) {
        // Wait for data to finish
        while ((XSysMon_GetStatus(&XadcInst) & XSM_SR_EOS_MASK) != XSM_SR_EOS_MASK);

        // Read channel data
        RawData = XSysMon_GetAdcData(&XadcInst, XSM_CH_AUX_MIN + 1);
        
        // TRANSFORMS HAPPEN HERE

        // Send data to GPIO
        gpio[0] = RawData;
    }

    return 0;
}
