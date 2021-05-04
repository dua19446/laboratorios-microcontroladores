/*
 * File:   lab10.c
 * Author: Alejandro Duarte
 *
 * Created on 3 de mayo de 2021, 01:11 AM
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

#define _XTAL_FREQ 4000000//Para usar la funcion de 'delay'

//------------------------------------------------------------------------------
//                                VARIABLES
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//                          PROTOTIPOS FUNCIONES 
//------------------------------------------------------------------------------
void setup(void);

void __interrupt() isr(void){
    if (PIR1bits.TXIF){
        TXREG = 64;
        TXREG = 98;
    }
    __delay_ms(50);
    if (PIR1bits.RCIF){
        PORTB = RCREG;
    }
}
//------------------------------------------------------------------------------
//                             CICLO PRINCIPAL 
//------------------------------------------------------------------------------
void main(void) {
    setup();// Se llama a la funcion setup para configuracion de I/O
    
    while (1) // Se implemta el loop
    {
       
    }            
}
//------------------------------------------------------------------------------
//                             CONFIGURACIONES
//------------------------------------------------------------------------------
void setup(void){
    // configuracion de puertos 
    ANSEL = 0X00; 
    ANSELH = 0X00;//se establecen los pines como entras y salidas digitales
    
    TRISA = 0X00;
    TRISB = 0X00;
    TRISD = 0X00;// Se establecen los puertos A, B y D como salidas 
    
    PORTA = 0X00;
    PORTB = 0X00;
    PORTD = 0X00;//Se limpian los puertos utilizados
    
    // configuracion del oscilador 
    OSCCONbits.IRCF2 = 1;
    OSCCONbits.IRCF1 = 1;
    OSCCONbits.IRCF0 = 0; //Se configura el oscilador a una frecuencia de 4 MHz.
    OSCCONbits.SCS = 1;

    //Configuracion TX y RX 
    TXSTAbits.BRGH = 1;
    BAUDCTLbits.BRG16 = 1;
    
    TXSTAbits.SYNC = 0;
    RCSTAbits.SPEN = 1;
    RCSTAbits.CREN = 1;
    
    TXSTAbits.TXEN = 1;
    
    RCSTAbits.RX9 = 0;
    
    SPBRG = 103; //BAUD RATE de 600
    SPBRGH = 0;
    
    // configuracion de interrupciones 
    INTCONbits.GIE = 1;
    INTCONbits.PEIE = 1;
    PIR1bits.RCIF = 0; // BANDERA de interrupcion del receptor
    PIE1bits.RCIE = 1; // Habilita la interrupcion del receptor
    PIE1bits.TXIE = 1;
    PIR1bits.TXIF = 0;
}