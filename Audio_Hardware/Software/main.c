#include "xsysmon.h"
#include "xparameters.h"
#include "stdio.h"
#include "xstatus.h"
#include <xsysmon_hw.h>


XSysMon XadcInst;

int main() {
    XSysMon_Config *ConfigPtr;
    u32 Status;
    u16 RawData;
    u16* gpio = (u16 *) XPAR_XGPIO_0_BASEADDR;
    float Voltage;

    // 1. Initialize the XADC driver
    ConfigPtr = XSysMon_LookupConfig(XPAR_XADC_WIZ_0_BASEADDR);
    if (ConfigPtr == NULL) return XST_FAILURE;
    
    XSysMon_CfgInitialize(&XadcInst, ConfigPtr, ConfigPtr->BaseAddress);

    // 2. Configure the Sequencer
    // First, set to Safe Mode to allow configuration changes
    XSysMon_SetSequencerMode(&XadcInst, XSM_SEQ_MODE_SAFE);

    // Enable specific Auxiliary Channels (e.g., AUX 0, 1, and 8)
    // Masks are defined in xsysmon.h (e.g., XSM_SEQ_CH_AUX00)
    
    XSysMon_SetSeqChEnables(&XadcInst, XSM_SEQ_CH_AUX01);

    // 3. Start the Sequencer in Continuous mode
    XSysMon_SetSequencerMode(&XadcInst, XSM_SEQ_MODE_CONTINPASS);

    while(1) {
        // Wait for the End of Sequence (EOS) to ensure fresh data
        while ((XSysMon_GetStatus(&XadcInst) & XSM_SR_EOS_MASK) != XSM_SR_EOS_MASK);

        // 4. Read Auxiliary Channel 0
        // Use XSM_CH_AUX_MIN + [Channel Number]
        RawData = XSysMon_GetAdcData(&XadcInst, XSM_CH_AUX_MIN + 1);
        
        gpio[0] = RawData;

        // Convert to Voltage (0 to 1.0V range for unipolar)
        //Voltage = ((float)RawData / 65536.0f) * 1.0f;

        //printf("AUX0 Raw: %d, Voltage: %.3fV\r\n", RawData, Voltage);

    }

    return 0;
}
