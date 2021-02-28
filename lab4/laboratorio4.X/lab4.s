; Archivo:     lab3.s
; Dispositivo: PIC16F887
; Autor:       Alejandro Duarte
; Compilador:  pic-as (v2.30), MPLABX V5.40
;
; Programa:    contador en el puerto A
; Hardware:    LEDS en el puerto A, DISPLAY de 7 segmentos en puertos C y D
;
; Creado: 23 feb, 2021
; Última modificación: 27 feb, 2021

; Assembly source line config statements
    
PROCESSOR 16F887  ; Se elige el microprocesador a usar
#include <xc.inc> ; libreria para el procesador 

; configuratión word 1
  CONFIG  FOSC =  INTRC_NOCLKOUT  ; Oscillator Selection bits (INTOSC oscillator: CLKOUT function on RA6/OSC2/CLKOUT pin, I/O function on RA7/OSC1/CLKIN)
  CONFIG  WDTE = OFF             ; Watchdog Timer Enable bit (WDT enabled)
  CONFIG  PWRTE = OFF        ; Power-up Timer Enable bit (PWRT disabled)
  CONFIG  MCLRE = OFF            ; RE3/MCLR pin function select bit (RE3/MCLR pin function is MCLR)
  CONFIG  CP = OFF               ; Code Protection bit (Program memory code protection is enabled)
  CONFIG  CPD = OFF              ; Data Code Protection bit (Data memory code protection is enabled)
  
  CONFIG  BOREN = OFF          ; Brown Out Reset Selection bits (BOR enabled)
  CONFIG  IESO = OFF            ; Internal External Switchover bit (Internal/External Switchover mode is enabled)
  CONFIG  FCMEN = OFF            ; Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is enabled)
  CONFIG  LVP = ON              ; Low Voltage Programming Enable bit (RB3/PGM pin has PGM function, low voltage programming enabled)

; configuration word 2
  CONFIG  BOR4V = BOR40V        ; Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
  CONFIG  WRT = OFF            ; Flash Program Memory Self Write Enable bits (0000h to 0FFFh write protected, 1000h to 1FFFh may be modified by EECON control)

  
  ;-------------------------------varibles--------------------------------------
  
PSECT udata_shr ;common memory
  W_T:       DS 1 ; variable que de interrupcio para w
  STATUS_T:  DS 1 ; variable que de interrupcio que guarda STATUS
  CONT_T0:   DS 1 ; variable intera de timer 0
  CUENTA:    DS 2 ; variable que incrementa uno de los displays de 7s
  
;Instrucciones de reset
PSECT resVect, class=code, abs, delta=2
;--------------vector reset----------------
ORG 00h        ;posicion 0000h para el reset
resetVec:
    PAGESEL main
    GOTO main
   
    
PSECT intVect, class=CODE, ABS, DELTA=2
;------------------------VECTOR DE INTERRUPCION---------------------------------
ORG 04h
    PUSH:
       MOVWF W_T
       SWAPF STATUS, W
       MOVWF STATUS_T
       
    ISR:
      BTFSC RBIF ; confirma si hubo una interrucion en el puerto B
      CALL INC_DEC ; llama a la subrrutina de la interrupcion del contador binario
      BTFSC T0IF; verifica si se desbordo el timer0
      CALL INT_T0; llama a la subrrutina de interrupcion del tiemer 0
      
    POP: 
      SWAPF STATUS_T, W
      MOVWF STATUS
      SWAPF W_T, F
      SWAPF W_T, W
      RETFIE
    

PSECT code, delta=2, abs
ORG 100h    ; Posicion para el codigo
; se establece la tabla para traducir los numeros y que el numero correspondiente
; se marque en el display
TABLA:
    CLRF    PCLATH
    BSF     PCLATH, 0 
    ANDLW   0x0f
    ADDWF   PCL
    retlw   00111111B	; 0
    retlw   00000110B	; 1
    retlw   01011011B	; 2
    retlw   01001111B	; 3
    retlw   01100110B	; 4
    retlw   01101101B	; 5
    retlw   01111101B	; 6
    retlw   00000111B	; 7
    retlw   01111111B	; 8
    retlw   01101111B	; 9
    retlw   01110111B	; A
    retlw   01111100B	; b
    retlw   00111001B	; C
    retlw   01011110B	; d
    retlw   01111001B	; E
    retlw   01110001B	; F
main:
    BANKSEL ANSEL ; Entramos al banco donde esta el registro ANSEL
    CLRF ANSEL
    CLRF ANSELH  ; se establecen los pines como entras y salidas digitales
    
   
    BANKSEL TRISA ; Entramos al banco donde esta el TRISA
    BCF TRISA, 0 
    BCF TRISA, 1 
    BCF TRISA, 2 
    BCF TRISA, 3  ; Se ponen los cuatro primeros pines del puerto A como entradas
    
    BCF TRISC, 0  ; 
    BCF TRISC, 1
    BCF TRISC, 2
    BCF TRISC, 3
    BCF TRISC, 4
    BCF TRISC, 5
    BCF TRISC, 6
    BCF TRISC, 7  ; Se ponen los pines del puerto C como salida
        
    BCF TRISD, 0
    BCF TRISD, 1
    BCF TRISD, 2
    BCF TRISD, 3
    BCF TRISD, 4
    BCF TRISD, 5
    BCF TRISD, 6
    BCF TRISD, 7 ; Se ponen todos pines del puerto D como salida
    
    BSF TRISB,0
    BSF TRISB,1 ; Se ponen los dos primeros pines como salida
    
; subrutinas de cofiguracion
    CALL PULL_UP
    CALL OSCILLATOR
    CALL CONF_IOC
    CALL CONF_INTCON ; Se llama a las diferentes subrrutinas de configuracion

    
    BANKSEL PORTA
    CLRF PORTA
    CLRF PORTB
    CLRF PORTC
    CLRF PORTD ; Se limpian todos los puertos del pic
    BANKSEL PORTA 
;-----------------------------loop principal------------------------------------
loop:
    BANKSEL PORTA
    CALL CONT_DIS ; Se llama a subrrutina para pasar el contador binario al display
    CALL INC_T0 ; Se llama intruccion para increntar la variable CUENTA 
    MOVF CUENTA,W; pasa lo que hay en la variable CUENTA a W
    CALL TABLA ; Se traduce lo que hay en CUENTA para el display de 7s
    MOVWF PORTD; la traduccion pasa al puerto D donde esta el display de 7s
    GOTO loop
    
;configuracion de pull-up del puerto B y timer 0
PULL_UP:
    BANKSEL OPTION_REG
    BCF OPTION_REG, 7 ; Se abilitan los pull-up internos del puerto B
    BCF T0CS ; Se establece que se usara oscilador interno 
    BCF PSA  ; el prescaler se asigna al timer 0
    BSF PS2
    BSF PS1
    BSF PS0  ; el prescaler es de 256   
    BANKSEL WPUB
    BSF WPUB,0
    BSF WPUB,1
    BCF WPUB,2
    BCF WPUB,3
    BCF WPUB,4
    BCF WPUB,5
    BCF WPUB,6
    BCF WPUB,7 ;Se estblece que pines del puerto B tendran activado el pull-up
    RETURN 
    
;configuracion de oscilador interno
OSCILLATOR:
    BANKSEL OSCCON ; Se ingresa al banco donde esta el registro OSCCON
    bcf	    IRCF2   
    bsf	    IRCF1   
    bcf	    IRCF0  ; Se configura el oscilador a una frecuencia de 250kHz 
    bsf	    SCS	  
    RETURN
    
;configuracion de pines para abilitacion de interrupt on change
CONF_IOC:   
    BANKSEL IOCB
    BSF IOCB, 0
    BSF IOCB, 1  ;Se activa el interrupt on change de los dos primeros pines del puerto B 
    RETURN
    
;abilitacion de interrupciones      
CONF_INTCON:
    BANKSEL INTCON
    BSF  GIE ; Se activan las interrupciones globales 
    BCF  RBIF ; Se colaca la bandera en 0 por precaucion
    BSF  RBIE ; Permite interrupciones en el puerto B
    BSF  T0IE ; Permite interrupion del timer 0
    BCF  T0IF ; limpia bandera de desbordamiento de timer 0
    RETURN

;----------------subrutinas de interrupcion y en loop---------------------------    
CONT_DIS:
    MOVF    PORTA, W ; Se mueve a W lo que hay en el puerto A
    CALL    TABLA  ; Se llama a la subrrutina TABLA
    MOVWF   PORTC ; Se mueve al puerto C lo que hay en W
    RETURN
    
INC_DEC:
     BTFSS PORTB,0 ; verifica si el PB del primer pin del puerto b esta activado
     INCF  PORTA ;incrementa el puerto A
     BTFSS PORTB,1 ; verifica si el PB del segundo pin del puerto b esta activado
     DECF  PORTA; decrementa el puerto A
     BCF   RBIF ; Se pone en cero la bandera por cambio de estado
     RETURN
     
TIMER0:
    BANKSEL PORTA
    MOVLW  251
    MOVWF  TMR0; Se ingresa al registro TMR0 el numero desde donde empieza a contar
    BCF  T0IF ; Se pone en 0 el bit T0IF  
    RETURN
    
INT_T0:
    INCF   CONT_T0; Se incrementa variable interna del timer 0
    CALL   TIMER0; llama a subrrutina para reiniciar el timer0
    RETURN; vuelve al isr
    
INC_T0:
    MOVLW  50 ; Determino que se repetira 50 veces 
    SUBWF  CONT_T0, W ; Se resta lo que esta en la variable con lo que hay en W
    BTFSS  STATUS, 2; verifica si la bandera zero esta activida
    RETURN  ; Regresa cuando la bandera zero esta activada 
    INCF   CUENTA ; Se incrementa la variable que va a pasar al display de 7s
    CLRF   CONT_T0 ; Se pone en cero la variable interna del timer 0
    RETURN
    
END