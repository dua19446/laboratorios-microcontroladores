/*
 * File:   lab10.c
 * Author: Alejandro Duarte
 *
 * Created on 3 de mayo de 2021, 01:11 AM
 */

#include <xc.h>
#include <stdint.h>
#include <stdio.h>// Libreria para poder usar printf junto a la funcion putch.

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
void menu(void);
void putch(char data);
void receptar(void);

// Se establece la funcion de interrupcion
void __interrupt() isr(void){

}
//------------------------------------------------------------------------------
//                             CICLO PRINCIPAL 
//------------------------------------------------------------------------------
void main(void) {
    setup();// Se llama a la funcion setup para configuracion de I/O
    
    while (1) // Se implemta el loop
    {
        menu(); // Se llama a la funcion menu para desplegar el menu de opciones
        receptar();// Se llama a funcion para determinar que hace cada opcion 
                   // del menu establecido 
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
    TRISB = 0X00;// Se establecen los puertos A, B y D como salidas 
    
    PORTA = 0X00;
    PORTB = 0X00;//Se limpian los puertos utilizados
    
    // configuracion del oscilador 
    OSCCONbits.IRCF2 = 1;
    OSCCONbits.IRCF1 = 1;
    OSCCONbits.IRCF0 = 0; //Se configura el oscilador a una frecuencia de 4 MHz.
    OSCCONbits.SCS = 1;

    //Configuracion TX y RX 
    TXSTAbits.BRGH = 1;  // Para alta velocidad.
    BAUDCTLbits.BRG16 = 1; // Se usan los 16 bits
    
    TXSTAbits.SYNC = 0; // transmision asincrona
    RCSTAbits.SPEN = 1; // Se enciende el modulo 
    RCSTAbits.CREN = 1; // Se abilita la recepcion 
    
    TXSTAbits.TXEN = 1; // Se abilita la transmision 
    
    RCSTAbits.RX9 = 0; // Se determina que no se quieren 9 bits
    
    SPBRG = 103; //BAUD RATE de 9600
    SPBRGH = 0;
    
    // configuracion de interrupciones 
    INTCONbits.GIE = 1;
    INTCONbits.PEIE = 1;
}
//------------------------------------------------------------------------------
//                               FUNCIONES
//------------------------------------------------------------------------------
void menu(void){
     __delay_ms(50);
     printf("\rQue accion desea ejecutar? \r");
     __delay_ms(50);
     printf("\r(1) Desplegar cadena de caracteres \r");
     __delay_ms(50);
     printf("(2) Cambiar PORTA \r");
     __delay_ms(50);
     printf("(3) Cambiar PORTB \r");
     // Se despliegan, en filas de caracteres, las opciones del menu establecido
     // usando prinf que llama automaticamante a la funcion putch para que sea 
     // transmitido con un delay de 50 ms.
}
void putch(char info){//Se transmite la cadena de caracteres a esta funcion 
                      // por el printf
    while (TXIF == 0);// Se espera algo que haya que transmitir
    TXREG = info;// lo que hay en data se pasa al registro de transmision para 
                 // para que se depliegue en la terminal virtual.
}
void receptar(void){
    while(RCIF == 0); //Se espera algo que recibir (CARACTER).
    char entregado = RCREG;//Se crea un variable local que equivale al registro 
                           // de recepcion para usarlo en las condicionales if.
    
    if (entregado == '1'){//si la opcion que se recibe es 1 se hace lo siguiente
        __delay_ms(50);
        printf("\r YA SALIO LA PRIMERA PARTE. \r");//Se despliega la fila de
    }                                             //caracteres.
    if (entregado == '2'){//si la opcion que se recibe es 2 se hace lo siguiente
        __delay_ms(50);
        printf("\r Por favor, ingrese un caracter. \r");//Se despliega la fila
                                                        //de caracteres.
        while(RCIF == 0);//Se espera algo que recibir (CARACTER)elegido por 
                         // el usuario.
        PORTA = RCREG;// El caracter que se recibe se transmitira al puerto A.
    }
    if (entregado == '3'){//si la opcion que se recibe es 3 se hace lo siguiente
        __delay_ms(50);
        printf("\r Por favor, ingrese un caracter. \r");//Se despliega la fila
                                                        //de caracteres.
        while(RCIF == 0);//Se espera algo que recibir (CARACTER)elegido por 
                         // el usuario.
        PORTB = RCREG;// El caracter que se recibe se transmitira al puerto B.
    }
}