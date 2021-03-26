; Archivo:     lab6.s
; Dispositivo: PIC16F887
; Autor:       Alejandro Duarte
; Compilador:  pic-as (v2.30), MPLABX V5.40
;
; Programa:    contador con diferentes timers
; Hardware:    DISPLAY de 7 segmentos en puertos C y led en el puerto D
;
; Creado: 23 MARZO, 2021
; Última modificación: , 2021

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
  SENAL:     DS 1 ; Se utiliza como indicador para el cambio de display
  NIBBLE:    DS 2 ; Se usa para separar los niblos del puertoA
  DIS:       DS 2 ; Se guarda el valor traducido por la tabla de la variable NIBBLE
  PARTE1:    DS 1 ; Variable interna que se incrementa por el timer1
  T2:        DS 1 ; Bandera para hacer titilar los LED y Display 
    
;Instrucciones de reset
PSECT resVect, class=code, abs, delta=2
;----------------------------vector reset---------------------------------------
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
      BANKSEL PORTB
      BTFSC TMR1IF   ; verifica si se desbordo el timer0
      CALL INC  ; llama a la subrrutina de interrupcion del tiemer 0
      BTFSC TMR2IF
      CALL TITILEO
      BTFSC T0IF   ; verifica si se desbordo el timer0
      CALL INT_T0  ; llama a la subrrutina de interrupcion del tiemer 0
      
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
    
    BANKSEL TRISA
    BCF TRISC, 0  ; 
    BCF TRISC, 1
    BCF TRISC, 2
    BCF TRISC, 3
    BCF TRISC, 4
    BCF TRISC, 5
    BCF TRISC, 6
    BCF TRISC, 7  ; Se ponen los pines del puerto C como salida
    
    BCF TRISD,0
    BCF TRISD,1
    BCF TRISD,2   ; Se ponen los primero 3 pines del puerto D como salida
    
    BANKSEL OPTION_REG
    BCF T0CS ; Se establece que se usara oscilador interno 
    BCF PSA  ; el prescaler se asigna al timer 0
    BSF PS2
    BSF PS1
    BSF PS0  ; el prescaler es de 256 
    
    BANKSEL OSCCON ; Se ingresa al banco donde esta el registro OSCCON
    bcf	    IRCF2   
    bsf	    IRCF1   
    bcf	    IRCF0  ; Se configura el oscilador a una frecuencia de 250kHz 
    bsf	    SCS	 
    
    BANKSEL INTCON
    BSF  GIE ; Se activan las interrupciones globales
    BSF  T0IE ; Permite interrupion del timer 0
    BCF  T0IF ; limpia bandera de desbordamiento de timer 0
    
    ;Configuracion del timer1
    BANKSEL PIE1
    BSF TMR1IE ; Se activa la interrupcion del timer1
    BANKSEL PIR1 
    BCF TMR1IF ; Se limpia la bandera del timer1
    BANKSEL T1CON
    BSF TMR1ON ; Se activa el timer1 
    BCF TMR1CS ; Reloj interno 
    BSF T1CKPS0  
    BSF T1CKPS1 ; pre-scaler de 1:8
    
   ;Configuracion del timer2
    BANKSEL PIE1
    BSF TMR2IE ; Se activa la interrupcion del timer1
    BANKSEL PIR1 
    BCF TMR2IF ; Se limpia la bandera del timer1
    BANKSEL T2CON
    BSF TOUTPS3
    BSF TOUTPS2
    BSF TOUTPS1
    BSF TOUTPS0 ; Post-sacaler de 1:16
    BSF TMR2ON ; Se activa el timer1
    BSF T2CKPS1
    BSF T2CKPS0 ; Pre-scaler 1:16
    
    BANKSEL PORTA
    CLRF PORTC 
    CLRF PORTD ; Se limpian todos los puertos del pic
    BANKSEL PORTA 
    
loop:
    CALL SEP_NIBBLE ;Sirve para separar los nibbles de la variable que se incrementa
    BTFSC T2, 0
    CALL MOSTRAR_DIS_Y_ON ; Se pasan los nibbles traducidos por la tabla a nuevas variables y se prende la LED
    BTFSS T2, 0
    CALL OFF ; SUBRRUTINA para hacer titilar los display y lED
    GOTO loop; loop por siempre 
 
; Sub-rutina de interrupcion del timer1    
INC:
    BANKSEL TMR1H
    MOVLW 0xE1
    MOVWF TMR1H
    BANKSEL TMR1L
    MOVLW 0x7C
    MOVWF TMR1L ; Se carga el valor adecuado de trabajo a los registros del TMR1
    INCF PARTE1 ; Se incrementa la variable cada vez.
    BCF  TMR1IF ; Se limpia la bandera activada.
    RETURN 
       
TIM2:
    MOVLW 61
    MOVWF PR2 ; Se carga el valor adecuado de trabajo al PR2
    BCF  TMR2IF ; Se limpia la bandera activada del timer2
    RETURN
    
; Sub-rutina de interrupcion del timer2
TITILEO:
    CALL TIM2
    BTFSC T2, 0
    GOTO APAGADO
PRENDIDO:
    BSF T2, 0 ; Prende el bit 1 de la variable T2
    RETURN
APAGADO:
    BCF T2, 0 ; Apaga el bit 1 de la variable T2
    RETURN
    
OFF:
    CLRF DIS
    CLRF DIS+1 ; Se apaga por un instante los displays para hacer el titileo
    BCF PORTD,2 ; Se apaga el LED
    RETURN

SEP_NIBBLE:
    MOVF PARTE1, W
    ANDLW 00001111B
    MOVWF NIBBLE ; Se realiza la operacion AND del nibble menos significativo del puertoA y se guarda en NIBBLE
    SWAPF PARTE1, W; Se realiza un cambio de los nibbles del puertoA 
    ANDLW 00001111B
    MOVWF NIBBLE+1; Se realiza la misma opericio de antes, con ello se obtiene los nibbles del puertoA separados
    RETURN

MOSTRAR_DIS_Y_ON:
    MOVF  NIBBLE, W
    CALL  TABLA 
    MOVWF DIS ; Se guarda en la variable DIS lo que contiene la variable NIBBLE
    MOVF  NIBBLE+1, W
    CALL  TABLA 
    MOVWF DIS+1; Se guarda en la variable DIS+1 lo que contiene la variable NIBBLE+1
    BSF PORTD, 2 ; Se prende el LED del puerto D 
    RETURN
    
R_TIMER0:
    BANKSEL PORTA
    MOVLW  255
    MOVWF  TMR0; Se ingresa al registro TMR0 el numero desde donde empieza a contar
    BCF  T0IF ; Se pone en 0 el bit T0IF  
    RETURN
    
INT_T0: 
    CALL R_TIMER0
    BCF PORTD, 0
    BCF PORTD, 1 ;Se limpian los puertos donde estan conectados los transistores
    BTFSC SENAL, 0
    GOTO DIS2
DIS1:
    MOVF DIS, W 
    MOVWF PORTC 
    BSF PORTD,0;Se pone el valor de DIS en el puerto C y se activa su display respectivo
    GOTO NEXT_DIS
DIS2:
    MOVF DIS+1, W 
    MOVWF PORTC
    BSF PORTD,1;Se pone el valor de DIS+1 en el puerto C y se activa su display respectivo
NEXT_DIS:
    MOVLW 1
    XORWF SENAL, F ; Se da el cambio del bit 1 en la variable para hacer el cambio
    RETURN
 
END