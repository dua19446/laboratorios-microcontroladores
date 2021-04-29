/*
 * File:   lab9.c
 * Author: Duarte
 *
 * Created on 27 de abril de 2021, 12:51 AM
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
#pragma config FCMEN = ON      // Fail-Safe Clock Monitor Enabled bit 
                                //(Fail-Safe Clock Monitor is enabled)
#pragma config LVP = OFF        // Low Voltage Programming Enable bit (RB3/PGM 
                                //pin has PGM function, low voltage programming 
                                //enabled)

// CONFIG2
#pragma config BOR4V = BOR40V   // Brown-out Reset Selection bit (Brown-out 
                                //Reset set to 4.0V)
#pragma config WRT = OFF        // Flash Program Memory Self Write Enable bits 
                                //(Write protection off)

#define _XTAL_FREQ 8000000//Para usar la funcion de 'delay'

//------------------------------------------------------------------------------
//                                VARIABLES
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//                          PROTOTIPOS FUNCIONES 
//------------------------------------------------------------------------------
void setup(void); 
// Se establece el vector de interrupcion
void __interrupt() isr(void){
    
    if (PIR1bits.ADIF == 1)//Interrupcion del ADC 
    {
        if (ADCON0bits.CHS == 1)//si se esta en este canal que haga lo siguiente
        {
            ADCON0bits.CHS = 0;//Se cambia el valor del canal
            CCPR2L = (ADRESH>>1) + 125; //Valores disponibles de 125 a 250
            CCP2CONbits.DC2B1 = ADRESH & 0b01;
            CCP2CONbits.DC2B0 = (ADRESL>>7); // bits menos significativos
        }                     
        else {
            ADCON0bits.CHS = 1;//Se cambia el valor de canal 
            CCPR1L = (ADRESH>>1) + 125; //Valores disponibles de 125 a 250
            CCP1CONbits.DC1B1 = ADRESH & 0b01;
            CCP1CONbits.DC1B0 = (ADRESL>>7);// bits menos significativos
        }
        __delay_us(50);//tiempo necesario para el cambio de canal 
        PIR1bits.ADIF = 0;//Se apaga el valor de la bandera de interrupcion ADC
    }
}
//------------------------------------------------------------------------------
//                             CICLO PRINCIPAL 
//------------------------------------------------------------------------------
void main(void) {
    
    setup();// Se llama a la funcion setup para configuracion de I/O
            
    while (1) // Se implemta el loop
    {
            ADCON0bits.GO = 1; //para empezar de nuevo la ejecucion del ADC
    }  
}
//------------------------------------------------------------------------------
//                             CONFIGURACIONES
//------------------------------------------------------------------------------
void setup(void){
    // configuracion de puertos 
    ANSEL = 0b00000011; //setea AN0 y AN1
    ANSELH = 0X00;//se establecen los pines como entras y salidas digitales
    
    TRISA = 0xff; // Se pone todo el puerto A como entrada.
    
    PORTA = 0X00;
    PORTC = 0X00;//Se limpian los puertos utilizados
    
    // configuracion del oscilador 
    OSCCONbits.IRCF2 = 1;
    OSCCONbits.IRCF1 = 1;
    OSCCONbits.IRCF0 = 1; //Se configura el oscilador a una frecuencia de 8 MHz
    OSCCONbits.SCS = 1;
   
    // configuracion del ADC
  
    ADCON0bits.CHS = 0; // CANAL AN0
    
    ADCON0bits.ADCS1 = 1;
    ADCON0bits.ADCS0 = 0; //Fosc/32
    
    ADCON0bits.ADON = 1; //Activa el modulo ADC
    
    ADCON1bits.ADFM = 0; // justificacion a la izquierda.
    ADCON1bits.VCFG0 = 0;
    ADCON1bits.VCFG1 = 0;  //Vss y Vcc
    
    // configuracion del PWM
    TRISCbits.TRISC2 = 1; //CCP1 se establece como entrada
    TRISCbits.TRISC1 = 1; //CCP2 se establece como entrada 
    PR2 = 250; // periodo de 2 ms para el timer 2
    CCP1CONbits.P1M = 0; // se configura como single output
    CCP1CONbits.CCP1M = 0b00001100; // Modo PWM
    CCP2CONbits.DC2B0 = 0;
    CCP2CONbits.DC2B1 = 0; // Modo PWM
    CCP2CONbits.CCP2M = 0b1111;// Modo PWM
    
    CCPR1L = 0x0f;  //Ciclo de trabajo inicial 
    CCP1CONbits.DC1B = 0; //bits menos significativos
    CCPR2L = 0x0f; //Ciclo de trabajo inicial
    
    PIR1bits.TMR2IF = 0; 
    T2CONbits.T2CKPS = 0b11; //Pre-scaler de 1:16
    T2CONbits.TMR2ON = 1; //Se prende timer 2
    
    while (PIR1bits.TMR2IF == 0);// Se espera ciclo del timer2
    PIR1bits.TMR2IF = 0;
    
    TRISCbits.TRISC2 = 0; //se pone como salida CCP1
    TRISCbits.TRISC1 = 0; //se pone como salida CCP2
    
    // configuracion de interrupciones 
    INTCONbits.GIE = 1;
    PIR1bits.ADIF = 0; // BANDERA de interrupcion del ADC
    PIE1bits.ADIE = 1; // Habilita la interrupcion del ADC
    INTCONbits.PEIE = 1; // Interrupcion de los perifericos
}