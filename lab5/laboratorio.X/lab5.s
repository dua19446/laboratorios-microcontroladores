; Archivo:     lab3.s
; Dispositivo: PIC16F887
; Autor:       Alejandro Duarte
; Compilador:  pic-as (v2.30), MPLABX V5.40
;
; Programa:    contador en el puerto A
; Hardware:    LEDS en el puerto A, DISPLAY de 7 segmentos en puertos C y D
;
; Creado: 2 MARZO, 2021
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

PSECT udata_bank0
  UNIDAD:    DS 1   ; variable que se usa en la division para guardar la unidad
  DECENA:    DS 1   ; variable que se usa en la division para guardar la decena
  CENTENA:   DS 1   ; variable que se usa en la division para guardar la centena
  RESIDUO:   DS 1   ; Se usa para guardar lo que hay en el puertoA e ir restando en la division
  UNIDAD2:   DS 1   ; Se guarda el valor traducido por la tabla de la variable unidad
  DECENA2:   DS 1   ; Se guarda el valor traducido por la tabla de la variable decena
  CENTENA2:  DS 1   ; Se guarda el valor traducido por la tabla de la variable centena
  
PSECT udata_shr ;common memory
  W_T:       DS 1 ; variable que de interrupcio para w
  STATUS_T:  DS 1 ; variable que de interrupcio que guarda STATUS
  SENAL:     DS 1 ; Se utiliza como indicador para el cambio de display
  NIBBLE:    DS 2 ; Se usa para separar los niblos del puertoA
  DIS:       DS 2 ; Se guarda el valor traducido por la tabla de la variable NIBBLE

  
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
    BCF TRISA, 3
    BCF TRISA, 4
    BCF TRISA, 5
    BCF TRISA, 6
    BCF TRISA, 7  ; Se ponen los pines del puerto A como salidas
    
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
    BCF TRISD,2
    BCF TRISD,3
    BCF TRISD,4 ; Se colocan los primeros 5 pines del puertoD como salida 
   
    BSF TRISB,0
    BSF TRISB,1  ; Se ponen los dos primeros pines como salida
    
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

loop:
    CALL SEP_NIBBLE ; Se llama la subrrutina para separa los nibbles del puertoA
    CALL MOSTRAR_DIS; Se realizan las traducciones, con la tabla, de variables con valores
    CALL DIVISION ; Se llama a subrrutina para realizar operacion de division  
    GOTO loop; loop por siempre
    
PULL_UP:
    BANKSEL OPTION_REG
    BCF OPTION_REG, 7 ; Se abilitan los pull-up internos del puerto B
    BCF T0CS ; Se establece que se usara oscilador interno 
    BCF PSA  ; el prescaler se asigna al timer 0
    BSF PS2
    BSF PS1
    BSF PS0  ; el prescaler es de 256   
    CALL R_TIMER0
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

SEP_NIBBLE:
    MOVF PORTA, W
    ANDLW 00001111B
    MOVWF NIBBLE ; Se realiza la operacion AND del nibble menos significativo del puertoA y se guarda en NIBBLE
    SWAPF PORTA, W; Se realiza un cambio de los nibbles del puertoA 
    ANDLW 00001111B
    MOVWF NIBBLE+1; Se realiza la misma opericio de antes, con ello se obtiene los nibbles del puertoA separados
    RETURN
    
MOSTRAR_DIS:
    MOVF  NIBBLE, W
    CALL  TABLA 
    MOVWF DIS ; Se guarda en la variable DIS lo que contiene la variable NIBBLE
    MOVF  NIBBLE+1, W
    CALL  TABLA 
    MOVWF DIS+1 ; Se guarda en la variable DIS+1 lo que contiene la variable NIBBLE+1
    MOVF CENTENA, W
    CALL TABLA 
    MOVWF CENTENA2 ; Se guarda en la variable CENTANA lo que contiene la variable CENTANA2
    MOVF DECENA, W
    CALL TABLA 
    MOVWF DECENA2 ; Se guarda en la variable DECENA lo que contiene la variable DECENA2
    MOVF UNIDAD, W
    CALL TABLA 
    MOVWF UNIDAD2 ; Se guarda en la variable UNIDAD lo que contiene la variable UNIDAD2
    RETURN
    
    ;NUEVO
DIVISION:
    BANKSEL PORTA
    CLRF CENTENA; Se limpia la variable CENTENA
    MOVF PORTA, 0
    MOVWF RESIDUO ; pasa lo que hay en el puertoA a RESIDUO	    
    MOVLW 100		    
    SUBWF RESIDUO, 0 ; Se resta 100 lo que hay en RESIDUO y se queda en W	    
    BTFSC STATUS, 0 ; Se asegura que se realizo la operacion 	    
    INCF CENTENA ; nuemero de centenas que caben en el numero del puertoA	    
    BTFSC STATUS, 0	    
    MOVWF RESIDUO ; El resultado de la resta se guarda en RESIDUO	    
    BTFSC STATUS, 0	    
    GOTO $-7	; Se repite por cada centena que pueda haber	    
    CLRF  DECENA ;Se limpia la variable CENTENA
    MOVLW 10		    
    SUBWF RESIDUO, 0 ; Se resta 10 lo que hay en RESIDUO y se queda en W	    
    BTFSC STATUS, 0 ; Se asegura que se realizo la operacion 
    INCF DECENA	; nuemero de decenas que caben en el numero del puertoA	    
    BTFSC STATUS, 0	    
    MOVWF RESIDUO ; El resultado de la resta se guarda en RESIDUO	    
    BTFSC STATUS, 0	    
    GOTO $-7 ; Se repite por cada decena que pueda haber	   
    CLRF UNIDAD ;Se limpia la variable CENTENA
    MOVLW 1		    
    SUBWF RESIDUO, F ; Se resta 1 de lo que hay en RESIDUO y se queda en F	    
    BTFSC STATUS, 0 ; Se asegura que se realizo la operacion	    
    INCF UNIDAD	; nuemero de unidades que caben en el numero del puertoA	    
    BTFSS STATUS, 0        
    RETURN
    GOTO $-6 ; Se resta el nuemro 1 cuanto se necesite para saber las unidades de lo que quedo de la resta anterior 		    
    
;----------------subrutinas de interrupcion y en loop---------------------------        
INC_DEC:
     BTFSS PORTB,0 ; verifica si el PB del primer pin del puerto b esta activado
     INCF  PORTA ;incrementa el puerto A
     BTFSS PORTB,1 ; verifica si el PB del segundo pin del puerto b esta activado
     DECF  PORTA; decrementa el puerto A
     BCF   RBIF ; Se pone en cero la bandera por cambio de estado
     RETURN
     
R_TIMER0:
    BANKSEL PORTA
    MOVLW  254
    MOVWF  TMR0; Se ingresa al registro TMR0 el numero desde donde empieza a contar
    BCF  T0IF ; Se pone en 0 el bit T0IF  
    RETURN
    
INT_T0:
    CALL R_TIMER0 ; llama a subrrutina para reiniciar el timer0
    BCF PORTD,0
    BCF PORTD,1
    BCF PORTD,2
    BCF PORTD,3
    BCF PORTD,4 ; Se limpian los pines donde estan conectador los transistores
    BTFSC SENAL, 0
    GOTO  DIS1
    BTFSC SENAL, 1
    GOTO  DIS2
    BTFSC SENAL, 2
    GOTO  DIS3
    BTFSC SENAL, 3
    GOTO  DIS4
    
DIS0:
    MOVF DIS, W
    MOVWF PORTC
    BSF PORTD, 0 ; Se pone el valor de DIS en el puerto D y se activa su display respectivo
    GOTO NEXT_D0; Se utiliza para cambiar el valor de SENAL y cambiar de display
    
DIS1:
    MOVF DIS+1, W
    MOVWF PORTC
    BSF PORTD, 1 ; Se pone el valor de DIS+1 en el puerto D y se activa su display respectivo
    GOTO NEXT_D1 ; Se utiliza para cambiar el valor de SENAL y cambiar de display
DIS2:
    MOVF CENTENA2, W
    MOVWF PORTC
    BSF PORTD, 2 ; Se pone el valor de CENTENA2 en el puerto D y se activa su display respectivo
    GOTO NEXT_D2 ; Se utiliza para cambiar el valor de SENAL y cambiar de display
    
DIS3:
    MOVF DECENA2, W
    MOVWF PORTC
    BSF PORTD, 3 ; Se pone el valor de DECENA2 en el puerto D y se activa su display respectivo
    GOTO NEXT_D3 ; Se utiliza para cambiar el valor de SENAL y cambiar de display
    
DIS4:
    MOVF UNIDAD2, W
    MOVWF PORTC
    BSF PORTD, 4 ; Se pone el valor de UNIDAD2 en el puerto D y se activa su display respectivo
    GOTO NEXT_D4 ; Se utiliza para cambiar el valor de SENAL y cambiar de display
    
NEXT_D0:
    MOVLW 00000001B
    XORWF SENAL, F
    RETURN ; Se utiliza la operacion xor para activar el primer bit de SENAL
NEXT_D1:
    MOVLW 00000011B
    XORWF SENAL, F
    RETURN; Se utiliza la operacion xor para activar el segundo bit de SENAL
NEXT_D2:
    MOVLW 00000110B
    XORWF SENAL, F
    RETURN; Se utiliza la operacion xor para activar el tercer bit de SENAL
NEXT_D3:
    MOVLW 00001100B
    XORWF SENAL, F
    RETURN; Se utiliza la operacion xor para activar el cuarto bit de SENAL
NEXT_D4:
    CLRF SENAL; Se limpia la variable SENAL
    RETURN
    
END