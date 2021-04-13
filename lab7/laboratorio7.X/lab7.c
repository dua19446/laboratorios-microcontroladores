/*
 * File:   lab7.c
 * Author: duart
 *
 * Created on 12 de abril de 2021, 03:41 PM
 */


#include <xc.h>
#include <stdint.h>
//------------------------------------------------------------------------------
//                         BITS DE CONFIGURACION
//------------------------------------------------------------------------------
// CONFIG1
#pragma config FOSC = INTRC_NOCLKOUT// Oscillator Selection bits (INTOSCIO 
                                   //oscillator: I/O function on RA6/OSC2/CLKOUT
                                   //pin, I/O function on RA7/OSC1/CLKIN)
#pragma config WDTE = OFF       // Watchdog Timer Enable bit (WDT enabled)
#pragma config PWRTE = OFF      // Power-up Timer Enable bit (PWRT disabled)
#pragma config MCLRE = OFF      // RE3/MCLR pin function select bit (RE3/MCLR 
                                //pin function is MCLR)
#pragma config CP = OFF         // Code Protection bit (Program memory code 
                                //protection is disabled)
#pragma config CPD = OFF        // Data Code Protection bit (Data memory code
                                //protection is disabled)
#pragma config BOREN = OFF      // Brown Out Reset Selection bits (BOR enabled)
#pragma config IESO = OFF       // Internal External Switchover bit 
                                //(Internal/External Switchover mode is enabled)
#pragma config FCMEN = OFF      // Fail-Safe Clock Monitor Enabled bit 
                                //(Fail-Safe Clock Monitor is enabled)
#pragma config LVP = OFF        // Low Voltage Programming Enable bit (RB3/PGM 
                                //pin has PGM function, low voltage programming 
                                //enabled)

// CONFIG2
#pragma config BOR4V = BOR40V   // Brown-out Reset Selection bit (Brown-out 
                                //Reset set to 4.0V)
#pragma config WRT = OFF        // Flash Program Memory Self Write Enable bits 
                                //(Write protection off)

//------------------------------------------------------------------------------
//                                VARIABLES
//------------------------------------------------------------------------------


//------------------------------------------------------------------------------
//                           PROTOTIPOS FUNCIONES 
//------------------------------------------------------------------------------
void setup(void);

void __interrupt() isr(void){

    if (T0IF == 1)
    {
        PORTC = PORTC + 1;
        INTCONbits.T0IF = 0;
        TMR0 = 255;
    }
    
    if (RBIF == 1)
    {
        if (PORTBbits.RB0 == 0)
        {
            PORTA = PORTA + 1;
        }
        if (PORTBbits.RB1 == 0)
        {
            PORTA = PORTA - 1;
        }
        INTCONbits.RBIF = 0;
    }
}
//------------------------------------------------------------------------------
//                             CICLO PRINCIPAL 
//------------------------------------------------------------------------------
void main(void){
    
    setup();
            
    while (1)
    {
    }
    //return;
}
//------------------------------------------------------------------------------
//                             CONFIGURACIONES
//------------------------------------------------------------------------------
void setup(void){
    // configuracion de puertos 
    ANSEL = 0X00;
    ANSELH = 0X00;
    
    TRISA = 0X00;
    TRISC = 0X00;
    TRISBbits.TRISB0 = 1;
    TRISBbits.TRISB1 = 1;
    
    PORTA = 0X00;
    PORTC = 0X00;
    PORTB = 0X00;
    
    // configuracion del oscilador 
    OSCCONbits.IRCF2 = 0;
    OSCCONbits.IRCF1 = 1;
    OSCCONbits.IRCF0 = 0; //Se configura el oscilador a una frecuencia de 250kHz
    OSCCONbits.SCS = 1;
    
    // configuracion del timer 0 y pull-up internos
    OPTION_REGbits.T0CS = 0;
    OPTION_REGbits.PSA = 0;
    OPTION_REGbits.PS2 = 1;
    OPTION_REGbits.PS1 = 1;
    OPTION_REGbits.PS0 = 1;
    //TMR0 = 255;
    
    OPTION_REGbits.nRBPU = 0;
    WPUB = 0b00000011;
    IOCBbits.IOCB0 = 1;
    IOCBbits.IOCB1 = 1;
    
    // configuracion de interrupciones 
    INTCONbits.GIE = 1;
    INTCONbits.RBIF = 0;
    INTCONbits.RBIE = 1;
    INTCONbits.T0IE = 1;
    INTCONbits.T0IF = 0;
    
}