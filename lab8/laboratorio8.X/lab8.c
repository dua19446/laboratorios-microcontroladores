/*
 * File:   lab8.c
 * Author: Alejandro Duarte
 *
 * Created on 18 de abril de 2021, 11:25 PM
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


//matriz realizada para la traduccion de los valores del contador para display
char DISPLAY[10] = {0b00111111,0b00000110,0b01011011,0b01001111,0b01100110,
0b01101101,0b01111101,0b00000111,0b01111111,0b01101111}; 

//------------------------------------------------------------------------------
//                                VARIABLES
//------------------------------------------------------------------------------
int MULTIPLEXADO; // variable de 8 bits para el multiplexado.
char GUARDADO; //variable donde se guarda ADRESH para hacer la division
               //y que se muestre en el display para el canal AN1
char CENTENA; //variable para la asignacion de la centena del canal AN1
char DECENA; //variable para la asignacion de la decena del canal AN1
char UNIDAD; //variable para la asignacion de la unidad del canal AN1
char RESIDUO; //variable hecha para el residuo de la division entre 100

//------------------------------------------------------------------------------
//                          PROTOTIPOS FUNCIONES 
//------------------------------------------------------------------------------
void setup(void); 
void division(void);//se mencionan las funciones que se tienen 

// Se establece el vector de interrupcion
void __interrupt() isr(void){

    if (T0IF == 1) // Interrupcion por la bandera del timer0
    {   
        PORTEbits.RE2 = 0;//Se apaga el tercer display de 7 seg 
        PORTEbits.RE0 = 1;//Se activa el primer display de 7 seg
        PORTC = (DISPLAY[CENTENA]);//Se despliega el valor de centena traducido
        MULTIPLEXADO = 0b00000001; // se cambia el valor de bandera para pasar
                                   //al siguiente display
        
        if (MULTIPLEXADO == 0b00000001) // si la bandera tiene este valor se dan
        {                               // la siguientes instrucciones
            PORTEbits.RE0 = 0;//Se apaga el primer display
            PORTEbits.RE1 = 1;// Se enciende el segundo display
            PORTC = (DISPLAY[DECENA]);//despliega el valor de decena traducido  
            MULTIPLEXADO = 0b00000010;// se cambia el valor de bandera para 
        }                             // pasar al siguiente display  
        if (MULTIPLEXADO == 0b00000010)// si la bandera tiene este valor se dan
        {                              // la siguientes instrucciones
            PORTEbits.RE1 = 0;//Se apaga el segundo display
            PORTEbits.RE2 = 1;//Se enciende el tercer display
            PORTC = (DISPLAY[UNIDAD]);//despliega el valor de unidad traducido
            MULTIPLEXADO = 0b00000000;//se limpia la bandera
        }
        INTCONbits.T0IF = 0;// Se limpia la bandera del timer0
        TMR0 = 255;//Se carga valor al timer0 para que trabaje a 5ms
    }  
    
    if (PIR1bits.ADIF == 1)//Interrupcion del ADC 
    {
        if (ADCON0bits.CHS == 1)//si se esta en este canal que haga lo siguiente
        {
            ADCON0bits.CHS = 0;//Se cambia el valor del canal
            GUARDADO = ADRESH;// Se guarda el valor de ADRESH en una variable.
        }                     // para luego realizar la division. 
        else {
            ADCON0bits.CHS = 1;//Se cambia el valor de canal 
            PORTB = ADRESH;}// Se guarda el valor de ADRESH en el puerto B
                            // para que se muestre en los 8 leds
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
        division();// se llama la subrrutina para hacer la division de centena,
    }              // decena y unidades del contador.
}
//------------------------------------------------------------------------------
//                             CONFIGURACIONES
//------------------------------------------------------------------------------
void setup(void){
    // configuracion de puertos 
    ANSEL = 0b00000011; //setea AN0 y AN1
    ANSELH = 0X00;//se establecen los pines como entras y salidas digitales
    
    TRISB = 0X00;
    TRISC = 0X00;
    TRISE = 0X00;// Se establecen los puertos A, C y E como salidas 
    TRISAbits.TRISA0 = 1;
    TRISAbits.TRISA1 = 1;//Se ponen como entradas los primeros pines del puertoB
    
    PORTA = 0X00;
    PORTC = 0X00;
    PORTB = 0X00;
    PORTE = 0X00;//Se limpian los puertos utilizados
    
    // configuracion del oscilador 
    OSCCONbits.IRCF2 = 0;
    OSCCONbits.IRCF1 = 1;
    OSCCONbits.IRCF0 = 0; //Se configura el oscilador a una frecuencia de 250KHz
    OSCCONbits.SCS = 1;
    
    // configuracion del timer 0 y pull-up internos
    OPTION_REGbits.T0CS = 0;
    OPTION_REGbits.PSA = 0;
    OPTION_REGbits.PS2 = 1;
    OPTION_REGbits.PS1 = 1;
    OPTION_REGbits.PS0 = 1;
    
    // configuracion del ADC
  
    ADCON0bits.CHS = 0; // CANAL AN0
    
    ADCON0bits.ADCS1 = 1;
    ADCON0bits.ADCS0 = 1; //Frc que trabaja con el oscilador interno
    
    ADCON0bits.ADON = 1; //Activa el modulo ADC
    
    ADCON1bits.ADFM = 0; // justificacion a la izquierda.
    ADCON1bits.VCFG0 = 0;
    ADCON1bits.VCFG1 = 0;  //Vss y Vcc
    
    // configuracion de interrupciones 
    INTCONbits.GIE = 1;
    PIR1bits.ADIF = 0; // BANDERA de interrupcion del ADC
    PIE1bits.ADIE = 1; // Habilita la interrupcion del ADC
    INTCONbits.PEIE = 1; // Interrupcion de los perifericos
    INTCONbits.T0IE = 1;
    INTCONbits.T0IF = 0;
    
}
void division(void){
    CENTENA = GUARDADO/100;//Se almacena en centena lo que resulta dividir entre 
                           //100
    RESIDUO = GUARDADO%100;//Se almacena el residuo de la division entre 100 
    DECENA = RESIDUO/10;//Se divide entre 10 lo que quedo en residuo y se guarda
    UNIDAD = RESIDUO%10;//Se guarda el residuo de la division entre 10
}