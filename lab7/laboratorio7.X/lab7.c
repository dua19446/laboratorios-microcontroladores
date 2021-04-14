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

char DISPLAY[10] = {0b00111111,0b00000110,0b01011011,0b01001111,0b01100110,
0b01101101,0b01111101,0b00000111,0b01111111,0b01101111}; 
//------------------------------------------------------------------------------
//                                VARIABLES
//------------------------------------------------------------------------------
char COTA; // variable de 8 bits para la cuenta de centas, decenas y unidades.
int MULTIPLEXADO; // variable de 8 bits para el multiplexado.
char CENTENA;
char DECENA;
char UNIDAD;
char RESIDUO;
//------------------------------------------------------------------------------
//                           PROTOTIPOS FUNCIONES 
//------------------------------------------------------------------------------
void setup(void);
char division(void);

void __interrupt() isr(void){

    if (T0IF == 1)
    {   
        PORTEbits.RE2 = 0;
        PORTEbits.RE0 = 1;
        PORTC = (DISPLAY[CENTENA]);
        MULTIPLEXADO = 0b00000001;
        
        if (MULTIPLEXADO == 0b00000001)
        { 
            PORTEbits.RE0 = 0;
            PORTEbits.RE1 = 1;
            PORTC = (DISPLAY[DECENA]);
            MULTIPLEXADO = 0b00000010;
        }
        if (MULTIPLEXADO == 0b00000010)
        {
            PORTEbits.RE1 = 0;
            PORTEbits.RE2 = 1;
            PORTC = (DISPLAY[UNIDAD]);
            MULTIPLEXADO = 0b00000000;
        }
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
        COTA = PORTA;
        division();
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
    TRISE = 0X00;
    TRISBbits.TRISB0 = 1;
    TRISBbits.TRISB1 = 1;
    
    PORTA = 0X00;
    PORTC = 0X00;
    PORTB = 0X00;
    PORTE = 0X00;
    
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
char division(void){
    CENTENA = COTA/100;
    RESIDUO = COTA%100;
    DECENA = RESIDUO/10;
    UNIDAD = RESIDUO%10;
}