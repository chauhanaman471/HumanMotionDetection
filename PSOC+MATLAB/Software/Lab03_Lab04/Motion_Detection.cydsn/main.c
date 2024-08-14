/* ========================================
 *
 * Copyright YOUR COMPANY, THE YEAR
 * All Rights Reserved
 * UNPUBLISHED, LICENSED SOFTWARE.
 *
 * CONFIDENTIAL AND PROPRIETARY INFORMATION
 * WHICH IS THE PROPERTY OF your company.
 *
 * ========================================
*/
#include "project.h"
#include "fft_application.h" //Including FFT Library
#define SAMPLES = 1024;  //Transmitting 1024 samples
int32 fft_array[2*1024] = {0}; //FFT Array containing 1024*2 = 2048 samples from FFT Calculation

CY_ISR_PROTO(isr_button); //ISR declaration for Push_Button
CY_ISR_PROTO(isr_rx); //ISR declaration for UART-rx

typedef enum
{
    IDLE,
    SAMPLING,
    TRANSFER
} State;  //Enum variables declaration for three states
State Currentstate = IDLE; //Initial state: IDLE State

static uint8_t count =0; 
uint16_t ADC_Output;
uint16_t SamplingArray[1024] = {0};
uint8_t push_button_flag = 0;
uint8_t uart_rx_sflag = 0;
uint8_t uart_rx_oflag = 0;
void statemachine(); //Function Declaration of State Machine

int main(void)
{
    CyGlobalIntEnable; /* Enable global interrupts. */
    //Initialisation of ISR + Drivers
    isr_Button_StartEx(isr_button);
    isr_rx_StartEx(isr_rx);
    UART_1_Start(); 
    WaveDAC8_1_Start(); 
    ADC_DelSig_1_Start(); 
    for(;;)
    {
        statemachine(); //This will call the function statemachine
    }
}

/*
Function: Statemachine Logic
(1) It implements a statemachine logic
(2) Three states: Idle,Sampling and Transfer state
*/
void statemachine()
{
    switch (Currentstate)
    {
        //IDLE State: Count =0. State changes to 'SAMPLING' if push_button is pressed (flag set via Interrupt)
        case IDLE:
        {
            Red_LED_Write(1);  //Red LED indicating User is at IDLE State
            Yellow_LED_Write(0);
            Green_LED_Write(0);
            count = 0;
            if (push_button_flag ==1)
            {
                push_button_flag = 0;
                Currentstate = SAMPLING;
            }
            break;
        }
        
        /*
        SAMPLING State:
            - Collect 1024 (each 16 bits) sample from ADC and store in Array
            - If sampling finished and 's' is received from MATLAB via UART then State changes to 'TRANSFER'
            - If no 's' is received, state continues
        */
        case SAMPLING:
        {
            Red_LED_Write(0);
            Yellow_LED_Write(1); //Yellow LED indicating User is at SAMPLING State
            Green_LED_Write(0);
            // Initialising SamplingArray to 0
            for (int i = 0; i < 1024; i++) 
                {
                    SamplingArray[i] = 0;
                }
            //Sampling Starts
            ADC_DelSig_1_StartConvert();
            for (int sample_count =0; sample_count<1024; sample_count++)
            {
                ADC_Output = (uint16_t)ADC_DelSig_1_Read32(); //Getting results from ADC
                SamplingArray[sample_count] = ADC_Output; //Storing results to Array
            }
            //Sampling Ends
            //Getting and checking for 's' character from MATLAB via UART            
            if (uart_rx_sflag ==1)
            {
                uart_rx_sflag =0;  //reset sflag of uart_rx
                Currentstate = TRANSFER;
            }
            break;
            
        }
        /*
        TRANSFER STATE:
            -Transfer 1024 samples from Array to MATLAB via UART and Increment count
            -Receive "o" 
                count <10 : State Transition > SAMPLING
                count ==10 : State Transition > TRANSFER
        */           
        case TRANSFER:
        {
            Red_LED_Write(0);
            Yellow_LED_Write(0);
            Green_LED_Write(1);   //Green LED indicating User is at TRANSFER State
            //Transfering ADC Sample to MATLAB via UART for FFT Calculation
            
            for (int send_count =0; send_count<1024; send_count++)
            {
                //Since UART transmits only 8 bits , conversion for 16 bits 
                uint8 lower8bits = SamplingArray[send_count]& 0xFF; //lower 8 bits >> Bitwise AND operation
                UART_1_PutChar(lower8bits);
                
                uint8 higher8bits = (SamplingArray[send_count]>>8)& 0xFF; //Higher 8 bits >> Right shift and Bitwise AND
                UART_1_PutChar(higher8bits);
            }
            //Transfer Ends
            
            //FFT Calculation via PSOC Library:
            fft_app(SamplingArray,fft_array,1024);
            //Transfering FFT Calculated data to MATLAB
            
            for (int i = 0; i<2048;i++)
            {
                UART_1_PutChar(fft_array[i]);  //Transferring lowest byte
                UART_1_PutChar(fft_array[i] >> 8); //Transferring second lowest byte
                UART_1_PutChar(fft_array[i] >> 16);//Transferring third lowest byte
                UART_1_PutChar(fft_array[i] >> 24);//Transferring highest byte
            }
            //Transfer Ends
            count++;
            //Getting and checking for 'o' character from MATLAB via UART ans  
            //count <10 : SAMPLING State else count ==10 : IDLE State
            if (uart_rx_oflag ==1 && count <10)
            {
                uart_rx_oflag = 0;
                Currentstate = SAMPLING;
            }
            else if (uart_rx_oflag ==1 && count >=10)
            {
                uart_rx_oflag = 0;
                Currentstate = IDLE;
            }
        break;
        }
        default:
        break;
    }
}


//ISR-Button Logic:
CY_ISR(isr_button)
{
    push_button_flag =1;
}
//ISR-UART Logic:
CY_ISR(isr_rx)
{
    uint8_t character = UART_1_GetChar();
    if (character == 's')
    {
        uart_rx_sflag =1;
        character = '\0';
    }
    else if (character == 'o')
    {
        uart_rx_oflag =1;
        character = '\0';
    }
}

/* [] END OF FILE */
