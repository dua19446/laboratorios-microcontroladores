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

// matriz realizada para la traduccion de los valores del contador para display
char DISPLAY[10] = {0b00111111,0b00000110,0b01011011,0b01001111,0b01100110,
0b01101101,0b01111101,0b00000111,0b01111111,0b01101111}; 

//------------------------------------------------------------------------------
//                                VARIABLES
//------------------------------------------------------------------------------
char COTA; // variable donde se guarda el valor del contador.
int MULTIPLEXADO; // variable de 8 bits para el multiplexado.
char CENTENA; //variable para la asignacion de la centena del contador
char DECENA; //variable para la asignacion de la decena del contador
char UNIDAD; //variable para la asignacion de la unidad del contador
char RESIDUO; //variable hecha para el residuo de la division entre 100
//------------------------------------------------------------------------------
//                           PROTOTIPOS FUNCIONES 
//------------------------------------------------------------------------------
void setup(void); 
char division(void);//se mencionan las funciones que se tienen 

// Se establece el vector de interrupcion 
void __interrupt() isr(void){

    if (T0IF == 1) // Interrupcion por la bandera del timer0
    {   
        PORTEbits.RE2 = 0;//Se apaga el tercer display de 7 seg 
        PORTEbits.RE0 = 1;//Se activa el primer display de 7 seg
        PORTC = (DISPLAY[CENTENA]);//Se despliega el valor de centena
        MULTIPLEXADO = 0b00000001; // se cambia el valor de bandera para pasar
                                   //al siguiente display
        
        if (MULTIPLEXADO == 0b00000001) // si la bandera tiene este valor se dan
        {                               // la siguientes instrucciones
            PORTEbits.RE0 = 0;//Se apaga el primer display
            PORTEbits.RE1 = 1;// Se enciende el segundo display
            PORTC = (DISPLAY[DECENA]);//se despliega el valor de decena   
            MULTIPLEXADO = 0b00000010;// se cambia el valor de bandera para 
        }                             // pasar al siguiente display  
        if (MULTIPLEXADO == 0b00000010)// si la bandera tiene este valor se dan
        {                              // la siguientes instrucciones
            PORTEbits.RE1 = 0;//Se apaga el segundo display
            PORTEbits.RE2 = 1;//Se enciende el tercer display
            PORTC = (DISPLAY[UNIDAD]);//se despliega el valor de unidad
            MULTIPLEXADO = 0b00000000;//se limpia la bandera
        }
        INTCONbits.T0IF = 0;// Se limpia la bandera del timer0
        TMR0 = 255;//Se carga valor al timer0 para que trabaje a 5ms
    }
    
    if (RBIF == 1)// Interrupcion por la bandera del puerto B
    {
        if (PORTBbits.RB0 == 0)
        {
            PORTA = PORTA + 1;// Si se apacha el primer boton se incrementa el 
        }                     // el puerto A
        if (PORTBbits.RB1 == 0)
        {
            PORTA = PORTA - 1;// Si se apacha el segundo boton se decrementa el 
        }                     // el puerto A
        INTCONbits.RBIF = 0;// Se limpia la bandera de la interrupcion del 
    }                       // puerto B
}
//------------------------------------------------------------------------------
//                             CICLO PRINCIPAL 
//------------------------------------------------------------------------------
void main(void){
    
    setup();// Se llama a la funcion setup para configuracion de I/O
    while (1) // Se implemta el loop
    {
        COTA = PORTA;// Se le asigna el valor del puerto A a la varible COTA
                     // para realizar la division del contador.
        division();// se llama la subrrutina para hacer la division de centena,
    }              // decena y unidades del contador.
    //return;
}
//------------------------------------------------------------------------------
//                             CONFIGURACIONES
//------------------------------------------------------------------------------
void setup(void){
    // configuracion de puertos 
    ANSEL = 0X00;
    ANSELH = 0X00;//se establecen los pines como entras y salidas digitales
    
    TRISA = 0X00;
    TRISC = 0X00;
    TRISE = 0X00;// Se establecen los puertos A, C y E como salidas 
    TRISBbits.TRISB0 = 1;
    TRISBbits.TRISB1 = 1;//Se ponen como entradas los primeros pines del puertoB
    
    PORTA = 0X00;
    PORTC = 0X00;
    PORTB = 0X00;
    PORTE = 0X00;//Se limpian los puertos utilizados
    
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
    CENTENA = COTA/100;//Se almacena en centena lo que resulta dividir entre 100
    RESIDUO = COTA%100;//Se almacena el residuo de la division entre 100 
    DECENA = RESIDUO/10;//Se divide entre 10 lo que quedo en residuo y se guarda
    UNIDAD = RESIDUO%10;//Se guarda el residuo de la division entre 10
}