; Archivo:     lab2_micros.s
; Dispositivo: PIC16F887
; Autor:       Alejandro Duarte
; Compilador:  pic-as (v2.30), MPLABX V5.40
;
; Programa:    contador en el puerto A
; Hardware:    LEDS en el puerto B, C, D y E
;
; Creado: 9 feb, 2021
; Última modificación: 1 feb, 2021

; Assembly source line config statements

PROCESSOR 16F887
#include <xc.inc>

; configuratión word 1
  CONFIG  FOSC = XT   ; Oscillator Selection bits (INTOSC oscillator: CLKOUT function on RA6/OSC2/CLKOUT pin, I/O function on RA7/OSC1/CLKIN)
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

;----------------vector de reset-------------------
  
PSECT udata_SHR ;common memory
  cont_small: DS 1 ;1 byte
  cont_big:   DS 1 

  
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

;-----------------------------Configuracion------------------------------------
 
main:
    BANKSEL ANSEL
    CLRF ANSEL
    CLRF ANSELH  ; se colocan todos los pines como digitales 
    
    BANKSEL PORTA
    CLRF PORTA 
    BANKSEL TRISA
    BSF TRISA, 0
    BSF TRISA, 1
    BSF TRISA, 2
    BSF TRISA, 3
    BSF TRISA, 4
    BCF TRISA, 6  ; se ponen como entras los primeros 5 pines del puerto A
    BSF TRISA, 7  ; y se ponen como entrada el pin 7 y como salida el pin6
    
    BANKSEL PORTB
    CLRF PORTB 
    BANKSEL TRISB
    BCF TRISB, 0
    BCF TRISB, 1
    BCF TRISB, 2
    BCF TRISB, 3  ; se ponen como salida los primeros 4 pines del puerto B
    
    BANKSEL PORTC
    CLRF PORTC 
    BANKSEL TRISC
    BCF TRISC, 0
    BCF TRISC, 1
    BCF TRISC, 2
    BCF TRISC, 3 ; se ponen como salida los primeros 4 pines del puerto C

    BANKSEL PORTD
    CLRF PORTD 
    BANKSEL TRISD
    BCF TRISD, 0
    BCF TRISD, 1
    BCF TRISD, 2
    BCF TRISD, 3 
    BCF TRISD, 4 ; se ponen como salida los primeros 4 pines del puerto D
    
   


;-------------------------Loop principal(ANTIRREBOTE)---------------------------

loop1:
    BANKSEL PORTA
    CALL delay_small
    BTFSS PORTA, 0
    CALL cont_mas   ;Antirrebote del PB + del primer contador
          

    CALL delay_small
    BTFSS PORTA, 1
    CALL cont_menos ;Antirrebote del PB - del primer contador
    

    CALL delay_small
    BTFSS PORTA, 2
    CALL cont_mas2  ;Antirrebote del PB + del del segundo contador
    

    CALL delay_small
    BTFSS PORTA, 3
    CALL cont_menos2 ;Antirrebote del PB - del primer contador
    
    
    CALL delay_small
    BTFSS PORTA, 4
    CALL sumatoria
    
    GOTO  loop1 ; loop para siempre  
    
   
    
delay_big:
    movlw 199		; Valor inicial del contador
    movwf cont_big
    call delay_small	; Rutina de delay
    decfsz cont_big, 1  ; Decrementar el contador
    goto $-2		; Ejecutar dos lineas atras
    return
    
delay_small:
    movlw 249; Valor inicial del contador
    movwf cont_small	
    decfsz cont_small, 1   ; Decrmentar el contador
    goto $-1		   ; Ejecutar linea anterior
    return
    
cont_mas:
    BTFSS PORTA, 0
    GOTO $-1
    INCF PORTB, 1
    RETURN
    
cont_menos:
    BTFSS PORTA, 1
    GOTO $-1
    DECF PORTB, 1
    RETURN
    
cont_mas2:
    BTFSS PORTA, 2
    GOTO $-1
    INCF PORTC, 1
    RETURN
    
cont_menos2:
    BTFSS PORTA, 3
    GOTO $-1
    DECF PORTC, 1
    RETURN
    
sumatoria:
    BTFSS PORTA, 4
    GOTO $-1
    MOVF PORTB, 0
    ADDWF PORTC,0 
    MOVWF PORTD
    RETURN

    
;exter_osclla:
;    BANKSEL OSCCON
;    MOVLW   01001110B
;    MOVWF   OSCCON
    
END