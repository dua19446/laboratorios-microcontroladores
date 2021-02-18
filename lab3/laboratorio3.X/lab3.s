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
  CONFIG  PWRTE = ON           ; Power-up Timer Enable bit (PWRT disabled)
  CONFIG  MCLRE = OFF            ; RE3/MCLR pin function select bit (RE3/MCLR pin function is MCLR)
  CONFIG  CP = OFF               ; Code Protection bit (Program memory code protection is enabled)
  CONFIG  CPD = OFF              ; Data Code Protection bit (Data memory code protection is enabled)
  
  CONFIG  BOREN = OFF            ; Brown Out Reset Selection bits (BOR enabled)
  CONFIG  IESO = OFF            ; Internal External Switchover bit (Internal/External Switchover mode is enabled)
  CONFIG  FCMEN = OFF            ; Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is enabled)
  CONFIG  LVP = ON              ; Low Voltage Programming Enable bit (RB3/PGM pin has PGM function, low voltage programming enabled)

; configuration word 2
  CONFIG  BOR4V = BOR40V        ; Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
  CONFIG  WRT = OFF            ; Flash Program Memory Self Write Enable bits (0000h to 0FFFh write protected, 1000h to 1FFFh may be modified by EECON control)

  ;-------------------------------varibles--------------------------------------
  
PSECT udata_SHR ;common memory
  CUENTA: DS 2
;Instrucciones de reset
PSECT resVect, class=code, abs, delta=2
;--------------vector reset----------------
ORG 00h        ;posicion 0000h para el reset
resetVec:
    PAGESEL main
    goto main
    
; Configuraciones
PSECT code, delta=2, abs
ORG 100h    ; Posicion para el codigo

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

;-----------------------------Configuracion------------------------------------
 
main:
    BANKSEL ANSEL
    CLRF ANSEL
    CLRF ANSELH  
    
    BANKSEL PORTA
    CLRF PORTA 
    BANKSEL TRISA
    BSF TRISA, 0
    BSF TRISA, 1
    
    BANKSEL PORTC
    CLRF PORTC 
    BANKSEL TRISC
    BCF TRISC, 0
    BCF TRISC, 1
    BCF TRISC, 2
    BCF TRISC, 3
        
    BANKSEL PORTD
    CLRF PORTD 
    BANKSEL TRISD
    BCF TRISD, 0
    BCF TRISD, 1
    BCF TRISD, 2
    BCF TRISD, 3
    BCF TRISD, 4
    BCF TRISD, 5
    BCF TRISD, 6
    BCF TRISD, 7
       
    BANKSEL PORTE
    CLRF    PORTE 
    BANKSEL TRISE
    BCF     TRISE, 0
    
    BANKSEL  OPTION_REG
    MOVLW    11000110B
    MOVWF    OPTION_REG
    
    CALL OSCILADOR
  

loop:
    BANKSEL PORTA
    BTFSS   PORTA, 0	
    CALL    INCREMENTAR
    
    BTFSS   PORTA, 1
    CALL    DECREMENTAR

    btfss   T0IF	
    goto    $-1
    call    TIMER0	
    incf    PORTC
    
    BCF    PORTE, 0
    CALL    ALARMA
   
    goto loop			
    
INCREMENTAR:
    BTFSS   PORTA, 0
    GOTO    $-1
    INCF    CUENTA
    MOVF    CUENTA, W
    CALL    TABLA  
    MOVWF   PORTD
    RETURN
    
DECREMENTAR:
    BTFSS   PORTA, 1
    GOTO    $-1
    DECF    CUENTA
    MOVF    CUENTA, W
    CALL    TABLA  
    MOVWF   PORTD
    RETURN
    
TIMER0:
    movlw   12	    
    movwf   TMR0
    bcf	    T0IF    
    return
    
OSCILADOR:		    
    BANKSEL OSCCON
    bcf	    IRCF2   
    bsf	    IRCF1   
    bcf	    IRCF0   
    bsf	    SCS	    
    return

ALARMA:
    MOVF PORTC, W
    SUBWF CUENTA, W
    BTFSC STATUS, 2
    CALL ACTIVACION
    RETURN

ACTIVACION: 
    CLRF PORTE
    BSF PORTE, 0
    CLRF PORTC
    RETURN
    
END  