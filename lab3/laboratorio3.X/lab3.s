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
  
PSECT udata_shr ;common memory
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

;-----------------------------Configuracion------------------------------------
 
main:
    BANKSEL ANSEL ; Entramos al banco donde esta el registro ANSEL
    CLRF ANSEL
    CLRF ANSELH  ; se establecen los pines como entras y salidas digitales
    
    BANKSEL PORTA ; Entramos al banco donde esta el puerto A
    CLRF PORTA    ; Se limpa el puerto A 
    BANKSEL TRISA ; Entramos al banco donde esta el TRISA
    BSF TRISA, 0  
    BSF TRISA, 1  ; Se ponen los dos primeros pines del puerto A como entradas
    
    BANKSEL PORTC ; Entramos al banco donde esta el puerto C
    CLRF PORTC    ; Se limpia el puerto C
    BANKSEL TRISC ; Entramos al banco donde esta el TRISC
    BCF TRISC, 0  ; 
    BCF TRISC, 1
    BCF TRISC, 2
    BCF TRISC, 3  ; Se ponen los primeros cuatro pines del puerto C como salida
        
    BANKSEL PORTD ; Entramos al banco donde esta el puerto D
    CLRF PORTD    ; Se limpia el puerto D
    BANKSEL TRISD ; Entramos al banco donde esta el TRISD
    BCF TRISD, 0
    BCF TRISD, 1
    BCF TRISD, 2
    BCF TRISD, 3
    BCF TRISD, 4
    BCF TRISD, 5
    BCF TRISD, 6
    BCF TRISD, 7 ; Se ponen todos pines del puerto D como salida
       
    BANKSEL PORTE ; Entramos al banco donde esta el puerto E
    CLRF    PORTE ; Se limpia el puerto E
    BANKSEL TRISE ;Entramos al banco donde esta el TRISE
    BCF     TRISE, 0 ; Se pone el primer pin del puerto E como salida
    
    BANKSEL  OPTION_REG ; Entramos al banco donde esta el registro OPTION_REG 
    MOVLW    11000110B ; Se guarda este numero binario en W
    MOVWF    OPTION_REG ; Se ingresa lo que hay en W al registro OPTION_REG
                        ; para el timerO
    CALL OSCILADOR ; Se llama la subrrutina OSCILADOR 
  
;-------------------------------SUBRRUTINAS-------------------------------------
loop:
    BANKSEL PORTA ; Entramos al banco donde esta el registro PORTA
    BTFSS   PORTA, 0 ; Se verfica si el PB en RA0 esta presionado	
    CALL    INCREMENTAR ; Se llama a la subrrutina INCREMENTAR
    
    BTFSS   PORTA, 1 ; Se verfica si el PB en RA1 esta presionado
    CALL    DECREMENTAR ; Se llama a la subrrutina DECREMENTAR

    btfss   T0IF    ; Se verifica si el bit TOIF esta en 1
    goto    $-1     ; Devuelve a una instruccion anterior si btfss es falso
    call    TIMER0  ; Llama a la subrrutina TIMERO si TOIF es 1
    incf    PORTC   ; Se incrementa en 1 el puerto C
    
    BCF    PORTE, 0 ; se limpia el primer pin del puerto E (LED  de alarma)
    CALL    ALARMA  ; Se llama a la subrrutina ALARMA                                                                     
   
    goto loop	    ; loop pra siempre	
    
INCREMENTAR:
    BTFSS   PORTA, 0 ; Se verfica si el PB en RA0 esta presionado
    GOTO    $-1      ; Devuelve a una instruccion anterior si btfss es falso
    INCF    CUENTA ; Se incrementa en 1 la variable CUENTA si btfss es verdadero
    MOVF    CUENTA, W ; Se mueve a W lo que hay en la variable CUENTA
    CALL    TABLA  ; Se llama a la subrrutina TABLA
    MOVWF   PORTD ; Se mueve al puerto D lo que hay en W
    RETURN
    
DECREMENTAR:
    BTFSS   PORTA, 1 ; Se verfica si el PB en RA1 esta presionado
    GOTO    $-1      ; Devuelve a una instruccion anterior si btfss es falso
    DECF    CUENTA ; Se decrementa en 1 la variable CUENTA si btfss es verdadero
    MOVF    CUENTA, W ; Se mueve a W lo que hay en la variable CUENTA
    CALL    TABLA  ; Se llama a la subrrutina TABLA
    MOVWF   PORTD  ; Se mueve al puerto D lo que hay en W
    RETURN
    
TIMER0:
    movlw   12	    
    movwf   TMR0; Se ingresa al registro TMR0 el numero desde donde empieza a contar
    bcf	    T0IF ; Se pone en 0 el bit T0IF   
    return
    
OSCILADOR:		    
    BANKSEL OSCCON ; Se ingresa al banco donde esta el registro OSCCON
    bcf	    IRCF2   
    bsf	    IRCF1   
    bcf	    IRCF0  ; Se configura el oscilador a una frecuencia de 250kHz 
    bsf	    SCS	   ; Se configura para usar el oscilador interno 
    return

ALARMA:
    MOVF PORTC, W ; Se mueve a W lo que hay en el puerto C
    SUBWF CUENTA, W ; Se resta lo que hay en el puerto C con la variable CUENTA
    BTFSC STATUS, 2 ; Verifica si el bit 3 de STATUS esta en 0
    CALL ACTIVACION ; Se llama a la subrrutina ACTIVACION 
    RETURN

ACTIVACION: 
    CLRF PORTE ; Se limpia el puerto E
    BSF PORTE, 0 ; Se pone en 1 el primer pin del puerto E (donde esta el led)
    CLRF PORTC; Se limpia el puerto C (se reinicia el contador binario)
    RETURN
    
END  