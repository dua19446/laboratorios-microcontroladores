; Archivo:     lab3.s
; Dispositivo: PIC16F887
; Autor:       Alejandro Duarte
; Compilador:  pic-as (v2.30), MPLABX V5.40
;
; Programa:    contador en el puerto A
; Hardware:    LEDS en el puerto B, C, D y E
;
; Creado: 16 feb, 2021
; Última modificación:  feb, 2021

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
  
PSECT udata_SHR ;common memory
  W_T:       DS 1
  STATUS_T:  DS 1
  CONT_T0:   DS 1
  CUENTA:    DS 2
  
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
      BTFSC RBIF
      CALL INC_DEC
      BTFSC T0IF
      CALL INT_T0
      
    POP: 
      SWAPF STATUS_T, W
      MOVWF STATUS
      SWAPF W_T, F
      SWAPF W_T, W
      RETFIE
    
; Configuraciones
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
    BCF TRISA, 3  ; Se ponen los dos primeros pines del puerto A como entradas
    
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
    BSF TRISB,1
    
    BANKSEL OPTION_REG
    BCF OPTION_REG, 7
    BANKSEL WPUB
    BSF WPUB,0
    BSF WPUB,1
    BCF WPUB,2
    BCF WPUB,3
    BCF WPUB,4
    BCF WPUB,5
    BCF WPUB,6
    BCF WPUB,7   
     
    BANKSEL OPTION_REG
    BCF T0CS
    BCF PSA
    BSF PS2
    BSF PS1
    BSF PS0     
    
    BANKSEL OSCCON ; Se ingresa al banco donde esta el registro OSCCON
    bcf	    IRCF2   
    bsf	    IRCF1   
    bcf	    IRCF0  ; Se configura el oscilador a una frecuencia de 250kHz 
    bsf	    SCS	  
    
    BANKSEL IOCB
    BSF IOCB, 0
    BSF IOCB, 1
    
    BANKSEL TMR0
    CLRF TMR0
    
    BANKSEL INTCON
    BSF  GIE
    BCF  RBIF
    BSF  RBIE
    BSF  T0IE
    BANKSEL TMR0
    CLRF TMR0
    BCF  T0IF
    
    BANKSEL PORTA
    CLRF PORTA
    CLRF PORTB
    CLRF PORTC
    CLRF PORTD
    BANKSEL PORTA
loop:
    BANKSEL PORTA
    CALL CONT_DIS
    CALL INC_T0
    MOVF CUENTA,W
    CALL TABLA
    MOVWF PORTD
    GOTO loop

CONT_DIS:
    MOVF    PORTA, W ; Se mueve a W lo que hay en la variable CUENTA
    CALL    TABLA  ; Se llama a la subrrutina TABLA
    MOVWF   PORTC ; Se mueve al puerto D lo que hay en W
    RETURN
    
INC_DEC:
     BTFSS PORTB,0
     INCF  PORTA
     BTFSS PORTB,1
     DECF  PORTA
     BCF   RBIF
     RETURN
     
TIMER0:
    BANKSEL PORTA
    MOVLW  250
    MOVWF  TMR0; Se ingresa al registro TMR0 el numero desde donde empieza a contar
    BCF  T0IF ; Se pone en 0 el bit T0IF  
    RETURN
    
INT_T0:
    INCF   CONT_T0
    CALL   TIMER0
    RETURN
    
INC_T0:
    MOVLW  50
    SUBWF  CONT_T0, W
    BTFSS  STATUS, 2
    RETURN
    INCF   CUENTA
    CLRF   CONT_T0
    RETURN
    
END


