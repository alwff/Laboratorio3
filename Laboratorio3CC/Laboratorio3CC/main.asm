;******************************************************************
;
; Universidad del Valle de Guatemala 
; IE2023:: Programación de Microcontroladores
; Laboratorio3CC.asm
; Autor: Alejandra Cardona 
; Proyecto: Laboratorio3
; Hardware: ATMEGA328P
; Creado: 13/02/2024
; Última modificación: 13/02/2024
;
;******************************************************************
; ENCABEZADO
;******************************************************************

.INCLUDE "M328PDEF.INC"
.CSEG
.ORG 0x00
	JMP MAIN

.ORG 0x0020 // Vector  
	JMP ISR_TIMER0_OVF 
;******************************************************************
; STACK POINTER
;******************************************************************

MAIN:

	LDI R16, LOW(RAMEND)
	OUT SPL, R16
	LDI R17, HIGH(RAMEND)
	OUT SPH, R17

;******************************************************************
; 
;		TABLA DE VALORES
; A	  B	  C	  D	  E	  F	  G 
; PC0 PC1 PC2 PC3 PC4 PC5 PD7
; 
;******************************************************************

t7s: .DB 0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x6F, 0x77, 0x7C, 0x39, 0x5E, 0x79, 0x71

;******************************************************************
; CONFIGURACIÓN 
;******************************************************************

Setup:
			
	;Setting

	LDI R17, (1 << PD7)|(1 << PD6)|(1 << PD5)|(1 << PD4)|(1 << PD3)|(1 << PD2)
	OUT DDRD, R17

	LDI R17, (1 << PC5)|(1 << PC4)|(1 << PC3)|(1 << PC2)|(1 << PC1)|(1 << PC0)
	OUT DDRC, R17

	SBI PORTB, PB0 ; Pullups -- BUT1 
	CBI DDRB, PB0	

	SBI PORTB, PB1 ; Pullups -- BUT2 
	CBI DDRB, PB1

	; TIMER0  
	LDI R16, (1 << CS02)|(1 << CS00) ;config prescaler 1024 
	OUT TCCR0B, R16 
	LDI R16, 99 ;valor desbordamiento 
	OUT TCNT0, R16 ; valor inicial contador 
	LDI R16, (1 << TOIE0) // Puede leer el overflow
	STS TIMSK0, R16 
	RET 
	SEI	; Activa la interrupciones
				
	; Contadores
	LDI R20, 0	// Contador
	LDI R21, 0  // Shift

;******************************************************************
; LOOP 
;******************************************************************

LOOP:
	
	CPI R20, 100 // 100 es 1s
	BREQ SET7SEG
	CLR R20
	JMP LOOP

;******************************************************************
; 7SEGMENTOS 
;******************************************************************

SET7SEG: 
	INC R18
	CPI R18, 15
	BRNE CLEAR 
LEDS:
 	MOV R17, R18
	LDI ZH, HIGH(t7s << 1)
	LDI ZL, LOW(t7s << 1)
	ADD ZL, R17
	LPM R17, Z
	MOV R22, R17
	ANDI R17, 0b0011_1111 // Solo requiero el valor de a-f
	ANDI R22, 0b0100_0000 // Solo requiero el valor de g
	LSL R22	//Shift a la derecha para colocar el valor que requiero de g en la posición deseada 
	OUT PORTD, R22
	OUT PORTC, R17
	RJMP LOOP

CLEAR: 
	CLR R18
	RJMP LOOP
;******************************************************************
; ISR_TIMER0_OVF  
;******************************************************************

ISR_TIMER0_OVF: 
	LDS R16, SREG
	LDI R16, 99
	OUT TCNT0, R16 
	SBI TIFR0, TOV0 
	INC R20	// dura 10 ms, si se quiere 1s se repite 100 veces. 
	OUT SREG, R16 
	RETI 