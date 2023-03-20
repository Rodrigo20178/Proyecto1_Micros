;Archivo: Proyecto_1.s
;Dispositivo: PIC16F887
;Autor: Rodrigo Garc�a
;
;Programa: generador de frecuencias
;Hardware: LEDs,DAC, Display 
;
;Creado: 3 de marzo, 2023
    
PROCESSOR 16F887
#include <xc.inc>
; CONFIG1
  CONFIG  FOSC = INTRC_NOCLKOUT ; OSCILADOR INTERNO
  CONFIG  WDTE = OFF            ; Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
  CONFIG  PWRTE = ON            ; Power-up Timer Enable bit (PWRT enable)
  CONFIG  MCLRE = OFF           ; RE3/MCLR pin function select bit (RE3/MCLR pin function is digital input, MCLR internally tied to VDD)
  CONFIG  CP = OFF              ; Code Protection bit (Program memory code protection is disabled)
  CONFIG  CPD = OFF             ; Data Code Protection bit (Data memory code protection is disabled)
  CONFIG  BOREN = OFF           ; Brown Out Reset Selection bits (BOR disabled)
  CONFIG  IESO = OFF            ; Internal External Switchover bit (Internal/External Switchover mode is disabled)
  CONFIG  FCMEN = OFF           ; Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
  CONFIG  LVP = OFF              ; Low Voltage Programming Enable bit (RB3/PGM pin has PGM function, low voltage programming enabled)

; CONFIG2
  CONFIG  BOR4V = BOR40V        ; Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
  CONFIG  WRT = OFF             ; Flash Program Memory Self Write Enable bits (Write protection off)   

  PSECT udata_bank0	; common memory
    Freq:           DS 1	; Variable para valor del TMR0
    Contador:       DS 1	; Variable para la se�al triangular
    Flag:           DS 1	; Bandera para el cambio de se�ales
    MAX:            DS 1	; Bandera utilizada para la se�al triangular
;----------------------------------MACROS---------------------------------------
RESET_TMR0 MACRO 
    BANKSEL TMR0		; seleccionar el banco 2 para timer0
    movf    Freq, w		; cargar el valor a w
    movwf   TMR0		; cargarlo al registro del timer0
    bcf	    T0IF		; limpiar bandera del timer0
    endm 
 

;--------------------------VARIABLES EN MEMORIA--------------------------------
PSECT udata_shr			
    W_TEMP:		DS 1	
    STATUS_TEMP:	DS 1	
    
PSECT resVect, CLASS=CODE, ABS, DELTA=2
;--------------------------- VECTOR RESET -----------------------------------
    ORG 00h	    ;Posici�n 0 para el reset
resetVec:
    PAGESEL main    ;Vamos a la p�gina de main
    goto    main    ;Vamos al label de main
    
 PSECT intVect, class = CODE, abs, delta = 2, abs
 ORG 04h			; Posici�n de la interrupci�n
 
;--------------------------INTERRUPCIONES--------------------
 
PUSH:
    movwf   W_TEMP		; 
    swapf   STATUS, W		; intercambiar status con registro w
    movwf   STATUS_TEMP		; cargar valor a la variable temporal
    
ISR: 
    btfsc   RBIF		; interrupci�n PORTB, SI=1 NO=0
    call    INT_IOCB		; si es igual a 1, ejecutar interrupci�n
    
    btfsc   T0IF		; interrupci�n TMR0, SI=1 NO=0
    call    SELECT_SIGNAL    	; si es igual a 1, ejecutar interrupci�n
  
    
POP:
    swapf   STATUS_TEMP, W	
    movwf   STATUS		
    swapf   W_TEMP, F		
    swapf   W_TEMP, W		
    retfie

;----------------------------INTERRUPCIONES SUBRUTINAS------------------------------------    
//CONFIGURACI�N DE PUSHBUTTONS
INT_IOCB:
    BANKSEL PORTB		
    btfss   PORTB, 0		; Revisar si el primer bot�n ha cambiado a 0
    call    INC_TMR0		; Llamar a incremento de frecuencia
    btfss   PORTB, 1		; Revisar si el segundo bot�n ha cambiado a 0
    call    DEC_TMR0		; Llamar a decremento de frecuencia
    btfss   PORTB, 2		; Revisar si el tercer bot�n ha cambiado a 0
    call    SWITCH		; Llamar a subrutina del cambio de se�al
    bcf	    RBIF		; Limpiar bandera del puerto B
    return 

//CAMBIO DE SE�AL   
SWITCH:
    movf Flag, w		; Mover valor de bandera a w
    xorlw  0xFF			; Hacer un XOR con la Badera y 0xFF
    movwf Flag			; Mover el valor a la bandera
    return
    
SELECT_SIGNAL:
    btfsc Flag, 0		; Revisar si la bandera esta encendida
    goto  INT_TMR01		; Si est� encendida, ir a la subrutina de la se�al cuadrada
    goto  INT_TMR02		; Si est� apagada, ir a la subrutina de la se�al triangular
    
//SE�AL CUADRADA
INT_TMR01:
    RESET_TMR0
    btfsc PORTA, 7		; Revisar si el ultimo pin del puerto A est� encendido
    goto  OFF			; Si est� encendido y a la subrutina OFF para apagarlo
    bsf   PORTA, 7		; Si est� apagado, prender el pin
    goto  END_TMR01		; Ir a la subrutina para apagar bandera del TMR0
    
OFF:
    bcf  PORTA, 7		; Apagar pin del puerto A
    goto END_TMR01		; Ir a la subrutina para apagar bandera del TMR0
    
    
END_TMR01:
    bcf T0IF			; Apagar bandera del TMR0
    retfie
    

//SE�AL TRIANGULAR
INT_TMR02:
    RESET_TMR0
    btfss  MAX, 0		; Revisar si la bandera MAX esta en 0
    goto   TMR02_UP		; Si est� en 0, ir a subrutina para incrementar la se�al
    goto   TMR02_DOWN		; Si est� en 1, ir a subrutina para decrementar la se�al
    
TMR02_UP:
    incf   Contador		; Incrementar variable contador
    movf   Contador, w		; Cargar variable a w
    sublw  255			; Restar 255 para revisar si lleg� al m�ximo valor
    btfss  ZERO			; Revisar si la bandera del ZERO es igual a 0
    goto   END_TMR02		; Si est� en 0, ir a subrutina para apagar la bandera TMR0
    bsf    MAX, 0		; Si est� en 1, colocar en 1 la bandera de MAX
    goto   END_TMR02		; Ir a subrutina para apagar la bandera TMR0
    return
    
TMR02_DOWN:
    decfsz  Contador		; Decrementar el contador y revisar si ha llegado a 0
    goto    END_TMR02		; Ir a subrutina para apagar la bandera TMR0
    bcf     MAX, 0		; Limpiar bandera de MAX
    goto    END_TMR02		; Ir a subrutina para apagar la bandera TMR0
    return
    
END_TMR02:
    movf    Contador, w		; Mover valor del contador a w
    movwf   PORTA		; Mover valor al puerto A
    bcf     T0IF		; Limpiar bandera del TMR0
    return

//VARIACI�N DE FRECUENCIA  
INC_TMR0:
    movf Freq, w		; Mover el valor del TMR0 a w
    addlw 10			; Sumarle 10 al valor del TMR0
    andlw 255			; Hacer un AND para revisar si lleg� a 255
    movwf Freq			; Mover valor al TMR0
    return
    
DEC_TMR0:
    movf   Freq, w		; Mover el valor del TMR0 a w
    addlw  -10			; Restarle 10 al valor del TMR0
    btfsc  STATUS, 0		; Revisar si el valor ha llegado a cero
    movwf   Freq		; Mover valor al TMR0
    return
    

PSECT code, delta=2, abs
ORG 100h   
;------------------------------MAIN-------------------------------------
main:
    call    IO_CONFIG		; Configuraci�n de pines
    call    TMR0_CONFIG		; Configuriaci�n TMR0
    call    CLK_CONFIG   	; Configuraci�n de reloj
    call    IOCRB_CONFIG	; Configuraci�n del puerto b
    call    INT_CONFIG		; Configuraci�n de interrupciones
    BANKSEL PORTB
;------------------------------LOOP------------------------------------- 
loop:
    goto loop
 ;----------------------------- SUBRUTINAS --------------------------------------
 IOCRB_CONFIG:
    BANKSEL IOCB		; Seleccionar banco del IOCB
    bsf	    IOCB, 0		; Activar Pull-up del pin 0
    bsf	    IOCB, 1		; Activar Pull-up del pin 1
    bsf     IOCB, 2		; Activar Pull-up del pin 2
    
    BANKSEL PORTA		; Seleccionar banco 00
    movf    PORTB, W		; Cargar el valor del puerto B a w
    bcf	    RBIF		; Limpiar bandera de interrupci�n del puerto B
    return
//CONFIGURACI�N DE ENTRADAS Y SALIDAS
IO_CONFIG:
    BANKSEL ANSEL		
    clrf    ANSEL		
    clrf    ANSELH		; Colocar puertos en digital
    
    BANKSEL TRISA		; Seleccionar banco 01
    //SALIDA DE SE�AL
    clrf   TRISA		; Colocar puerto A como salida
    //PUSHBUTTONS
    bsf	    TRISB, 0		; Colocar pines del puerto B como entrada
    bsf	    TRISB, 1	
    bsf     TRISB, 2
    
    
    bcf	    OPTION_REG, 7	; Limpiar RBPU para colocar Pull-Up en el puerto B
    
    BANKSEL PORTA
    clrf   PORTA
    clrf   PORTC
    return
//CONFIGURACI�N DEL OSCILADOR INTERNO
CLK_CONFIG:
    BANKSEL OSCCON		; Configuraci�n de oscilador
    bsf	    SCS			; Usar oscilador interno
    bsf	    IRCF0		
    bsf	    IRCF1		;Oscilador a 500kHz
    bcf	    IRCF2		
    return
//CONFIGURACI�N DE INTERRUPCIONES   
INT_CONFIG:

    BANKSEL INTCON
    bsf GIE			; Activar interrupciones
    bsf RBIE			; Activar cambio de interrupciones en portB
    bcf RBIF			; Limpiar bandera de cambio del portB
    
    bsf T0IE			; Activar interrupciones del TMR0
    bcf T0IF			; Limpiar bandera del TMR0
    
    return
//CONFIGURACI�N DEL PRESCALER
TMR0_CONFIG:
    BANKSEL TRISA
    bcf     T0CS              ;Utilizar reloj interno
    bcf     PSA
    bcf     PS2
    bcf     PS1
    bcf     PS0               ;Prescaler 1:2   
    
    RESET_TMR0
    return  
    
END