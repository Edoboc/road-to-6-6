/*
 * Capteurthermo.asm
 *
 *  Created: 15.05.2018 15:37:41
 *   Author: Loïc
 */ 
 .include "fonction.asm"

 ; === interrupt table
.org 0
		jmp reset
.org ADCCaddr
		jmp ADDCint

; === interrupte service routines


reset:	
			LDSP RAMEND
			OUTI DDRB,0xff
			OUTI ADCSR, (1<<ADEN)+(1<<ADIE)+6
			call ws2812b4_init
			call ws2812b4_reset		 
			rcall LCD_init
			rcall wire1_init
			sei
			rjmp init

ADDCint:
			push w
			in w,PIND
			cpi w,0b11111110
			breq reset
			pop w
			reti

					

.include "lcd.asm"
.include "printf.asm"
.include "wire1.asm"
.include "math.asm"

; === program start
init:
			rcall LCD_clear
			ldi xl, low(Sauvegarde)
			ldi xh, high(Sauvegarde)
			ldi b0,0b00000000
			st x,b0
			ldi zl, low(Tref)
			ldi zh, high(Tref)
			ldi b0,0b10010000
			ldi b1,0b00000001
			st z+,b1
			st z,b0
			ldi a0,0b00110000	; Tsup LSByte
			ldi a1,0b00000010	; Tsup MSByte : Tsup (initialement) = 35C
			ldi a2,0b11110000	; Tinf LSByte
			ldi a3,0b00000000	; Tinf MSByte : Tinf (initialement) = 15C
			ldi b2,0b01000000	; Table LSByte
			ldi b3,0b00000001	; Table MSByte : Table (initialement) = 20C


Trefset:	
			rcall LCD_clear
			WAIT_MS 200
			PRINTF LCD
.db "Set Tref", LF, 0
			
			ldi xl, low(Sauvegarde)
			ldi xh, high(Sauvegarde)
			ld b0,x

			sbrc b0,4 
			rjmp Mode0

			ldi zl, low(Tref)
			ldi zh, high(Tref)
			ld b1, z+
			ld b0, z
			PRINTF LCD
.db "Tref =",FFRAC2+FSIGN, b, 4, $42, "C", LF, 0
			LED_COLOR 0x05,0x05,0x05	; affiche la couleur blanche

			
			rjmp Trefinc

Mode0:
			ldi zl, low(Tref)
			ldi zh, high(Tref)
			ld b1, z+
			ld b0, z
			MODE b0,b1
			PRINTF LCD
.db "Tref =",FFRAC2+FSIGN, b, 4, $42, "F", LF, 0
			LED_COLOR 0x05,0x05,0x05	; affiche la couleur blanche

Trefinc:	
			
			in r16, PIND
			cpi r16, 0b11101111				; increment Tref, Tsup and Tinf if PD4 is pressed
			_BRNE Trefdec					; go to Trefdec if not
			ldi zl, low(Tref)
			ldi zh, high(Tref)
			ld b1, z+
			ld b0, z
			INCT b0,b1,1
			ldi zl, low(Tref)
			ldi zh, high(Tref)
			st z+,b1
			st z, b0
			INCT a0,a1,1
			INCT a2,a3,1
			
			ldi xl, low(Sauvegarde)
			ldi xh, high(Sauvegarde)
			ld b0,x

			sbrc b0,4
			rjmp ModeD1

			ldi zl, low(Tref)
			ldi zh, high(Tref)
			ld b1, z+
			ld b0, z

			PRINTF LCD
.db "Tref =",FFRAC2+FSIGN, b, 4, $42, "C", LF, 0
			WAIT_MS 200
			rjmp Trefdec


ModeD1:		
			ldi zl, low(Tref)
			ldi zh, high(Tref)
			ld b1, z+
			ld b0, z
			MODE b0,b1
			PRINTF LCD
.db "Tref =",FFRAC2+FSIGN, b, 4, $42, "F", LF, 0
			WAIT_MS 200
			

Trefdec:
			cpi r16, 0b11110111				; decrement Tref, Tsup and Tinf if PD3 is pressed
			_BRNE Trefnext					; go to Trefnext if not
			ldi zl, low(Tref)
			ldi zh, high(Tref)
			ld b1, z+
			ld b0, z
			DECT b0,b1,1
			ldi zl, low(Tref)
			ldi zh, high(Tref)
			st z+,b1
			st z, b0
			DECT a0,a1,1
			DECT a2,a3,1

			ldi xl, low(Sauvegarde)
			ldi xh, high(Sauvegarde)
			ld b0,x

			sbrc b0,4
			rjmp ModeD2 
			
			ldi zl, low(Tref)
			ldi zh, high(Tref)
			ld b1, z+
			ld b0, z
			PRINTF LCD
.db "Tref =",FFRAC2+FSIGN, b, 4, $42, "C", LF, 0
			WAIT_MS 200
			rjmp Trefnext


ModeD2:		
			ldi zl, low(Tref)
			ldi zh, high(Tref)
			ld b1,z+
			ld b0,z
			MODE b0,b1
			PRINTF LCD
.db "Tref =",FFRAC2+FSIGN, b, 4, $42, "F", LF, 0
			WAIT_MS 200

Trefnext:	
			cpi r16,0b11111110
			brne PC+6
			sbic PIND,0
			rjmp PC-1
			sbis PIND,0
			rjmp PC-1						; go to Temp_color if any button pressed
			rjmp reset
			cpi r16, 0b10111111
			brne PC+3						; go to main if PD6 is pressed
			rcall LCD_clear
			rjmp main	
			cpi r16, 0b11111011
			brne PC+3						; clear LCD and go to Tableset if PD2 is pressed
			rcall LCD_clear
			rjmp Tableset
			cpi r16, 0b11111101				; clear LCD and go to Tableset if PD1 is pressed
			brne PC+3
			rcall LCD_clear
			rjmp Tableset		
			cpi r16,0b11011111
			_BRNE Trefinc
			sbic PIND,5
			rjmp PC-1
			sbis PIND,5
			rjmp PC-1
			ldi xl, low(Sauvegarde)
			ldi xh, high(Sauvegarde)
			ld b0,x
			ADDI b0, 0b00010000
			st x,b0
			rjmp Trefset
			rjmp Trefinc					; if any button is pressed, return to Trefinc

Tableset:
			rcall LCD_clear
			WAIT_MS 200
			PRINTF LCD
.db "Set Table", LF, 0

			ldi xl, low(Sauvegarde)
			ldi xh, high(Sauvegarde)
			ld b0,x

			sbrc b0,4 
			rjmp ModeD6
			
			PRINTF LCD
.db "Table =",FFRAC2+FSIGN, b+2, 4, $42, "C", LF, 0
			WAIT_MS 200
			rjmp Tableinc

ModeD6:	
			MODE b2,b3
			PRINTF LCD
.db "Table =",FFRAC2+FSIGN, b, 4, $42, "F", LF, 0
			WAIT_MS 200
			


Tableinc:	

			in r16, PIND
			cpi r16, 0b11111011				; increment Table, Tsup and Tinf if PD2 is pressed
			_BRNE Tabledec					; go to Tabledec if not
			INCT b2,b3,1
			INCT a0,a1,0
			DECT a2,a3,0

			ldi xl, low(Sauvegarde)
			ldi xh, high(Sauvegarde)
			ld b0,x

			sbrc b0,4
			rjmp ModeD7

			PRINTF LCD
.db "Table =",FFRAC2+FSIGN, b+2, 4, $42, "C", LF, 0
			WAIT_MS 200
			rjmp Tabledec


ModeD7:		

			MODE b2,b3
			PRINTF LCD
.db "Table =",FFRAC2+FSIGN, b, 4, $42, "F", LF, 0
			WAIT_MS 200
		
Tabledec:
			cpi r16, 0b11111101				; decrement Tref, Tsup and Tinf if PD1 is pressed
			_BRNE Tablenext					; go to Tablenext if not
			DECT b2,b3,1
			DECT a0,a1,0
			INCT a2,a3,0

			ldi xl, low(Sauvegarde)
			ldi xh, high(Sauvegarde)
			ld b0,x

			sbrc b0,4
			rjmp ModeD8

			PRINTF LCD
.db "Table =",FFRAC2+FSIGN, b+2, 4, $42,"C", LF, 0
			WAIT_MS 200
			rjmp Tablenext
ModeD8:	
			MODE b2,b3
			PRINTF LCD
.db "Table =",FFRAC2+FSIGN, b, 4, $42,"F", LF, 0
			WAIT_MS 200

Tablenext:
			cpi r16,0b11111110
			brne PC+6
			sbic PIND,0
			rjmp PC-1
			sbis PIND,0
			rjmp PC-1						; go to Temp_color if any button pressed
			rjmp reset
			cpi r16, 0b10111111
			brne PC+3						; clear LCD and go to main if PD6 is pressed
			rcall LCD_clear
			breq main
			cpi r16, 0b11101111
			brne PC+3						; clear LCD and return to Trefset if PD4 is pressed
			rcall LCD_clear
			rjmp Trefset
			cpi r16, 0b11110111
			brne PC+3						; clear LCD and return to Trefset if PD3 is pressed
			rcall LCD_clear	
			rjmp Trefset		
			cpi r16,0b11011111
			_BRNE Tableinc
			sbic PIND,5
			rjmp PC-1
			sbis PIND,5
			rjmp PC-1
			ldi xl, low(Sauvegarde)
			ldi xh, high(Sauvegarde)
			ld b0,x
			ADDI b0, 0b00010000
			st x,b0
			rjmp Tableset
			rjmp Tableinc					; if any button is pressed, return to Tableinc


main:	
								
			push a0
			rcall	lcd_home				; place cursor to home position
			rcall	wire1_reset				; send a reset pulse
			CA	wire1_write, skipROM		; skip ROM identification
			CA	wire1_write, convertT		; initiate temp conversion
			rcall	wire1_reset				; send a reset pulse
			CA	wire1_write, skipROM
			CA	wire1_write, readScratchpad
			rcall	wire1_read				; read temperature LSByte
			mov	c2,a0
			rcall	wire1_read				; read temperature MSByte
			mov c3,a0
			pop a0  

			in r16,PIND
			cpi r16,0b11111110
			brne PC+6
			sbic PIND,0
			rjmp PC-1
			sbis PIND,0
			rjmp PC-1						; go to Temp_color if any button pressed
			rjmp reset
			cpi r16, 0b11101111
			brne PC+3						; clear LCD and return to Trefset if PD4 is pressed
			rcall LCD_clear
			rjmp Trefset
			cpi r16, 0b11110111
			brne PC+3						; clear LCD and return to Trefset if PD3 is pressed
			rcall LCD_clear	
			rjmp Trefset
			cpi r16, 0b11111011
			brne PC+3						; clear LCD and go to Tableset if PD2 is pressed
			rcall LCD_clear
			rjmp Tableset
			cpi r16, 0b11111101				; clear LCD and go to Tableset if PD1 is pressed
			brne PC+3
			rcall LCD_clear
			rjmp Tableset
			cpi r16,0b11011111
			brne nope
			sbic PIND,5
			rjmp PC-1
			sbis PIND,5
			rjmp PC-1
			ldi xl, low(Sauvegarde)
			ldi xh, high(Sauvegarde)
			ld b0,x
			ADDI b0, 0b00010000
			st x,b0

nope:		
			rcall LCD_clear
			ldi xl, low(Sauvegarde)
			ldi xh, high(Sauvegarde)
			ldi b1, 0b00000000
			ld b0,x
			sbrc b0,4
			rjmp ModeD5
			
			PRINTF LCD
.db			"Temp =",FFRAC2+FSIGN, c+2, 4, $42, "C",LF, 0
			
			WAIT_MS 50
			
			rjmp Temp_color

ModeD5:
		
			Mode c2,c3
			PRINTF LCD
.db "Temp =",FFRAC2+FSIGN, b, 4, $42, "F",LF, 0
			WAIT_MS 50



Temp_color:	
		PUSH4 a0,a1,a2,a3					; save registers
		PUSH4 b0,b1,c0,c1
		LDI2 b1,b0, 0x0170					; load 23 in b1 b0
		SUB2 a1,a0, a3,a2					; substract Tinf to Tsup, result stored in a1 a0
		rcall div22							; divide previous result by 23, result stored in c1 c0 (format 2 signed bytes, fix point at 4)
		MOV2 b1,b0, c1,c0					; move result to b1 b0
		SUB2 c3,c2, a3,a2					; Tempeture - Tinf
		MOV2 a1,a0, c3,c2					; move result to a1 a0
		rcall div22							; previous result/first division result
		mov d0,c0							; move result to d0 and change format
		_ANDI d0,0xf0						
		or d0,c1
		swap d0								
		POP4 b0,b1,c0,c1					; restore rgisters
		POP4 a0,a1,a2,a3
		_SUBI d0, 0
		brpl PC+57
		LED_COLOR 0x00,0x00,0x0f
		WAIT_MS 300
		LED_COLOR 0x00,0x00,0x00
		rjmp main
		_CPI d0, 0							; compare d0 to various numbers, up to 22
		brne PC+20							; branch to next comparison if not equal
		LED_COLOR 0x00,0x00,0x0f			; pure blue							
		rjmp main
		_CPI d0, 1
		brne PC+20
		LED_COLOR 0x00,0x01,0x0e				
		rjmp main
		_CPI d0, 2
		brne PC+20
		LED_COLOR 0x00,0x03,0x0c
		rjmp main
		_CPI d0, 3
		brne PC+20
		LED_COLOR 0x00,0x05,0x0a
		rjmp main
		_CPI d0, 4
		brne PC+20
		LED_COLOR 0x00,0x07,0x08
		rjmp main
		_CPI d0, 5
		brne PC+20	
		LED_COLOR 0x00,0x09,0x06
		rjmp main
		_CPI d0, 6
		brne PC+20
		LED_COLOR 0x00,0x0b,0x04
		rjmp main
		_CPI d0, 7
		brne PC+20
		LED_COLOR 0x01,0x0c,0x02			; green-ish
		rjmp main
		_CPI d0, 8
		brne PC+20
		LED_COLOR 0x02,0x0a,0x03
		rjmp main
		_CPI d0, 9
		brne PC+20	
		LED_COLOR 0x03,0x08,0x04
		rjmp main
		_CPI d0, 10
		brne PC+20	
		LED_COLOR 0x04,0x06,0x05
		rjmp main
		_CPI d0, 11
		brne PC+20
		LED_COLOR 0x05,0x05,0x05			; white
		rjmp main
		_CPI d0, 12
		brne PC+20
		LED_COLOR 0x06,0x06,0x03
		rjmp main
		_CPI d0, 13
		brne PC+20
		LED_COLOR 0x07,0x06,0x02
		rjmp main
		_CPI d0, 14
		brne PC+20
		LED_COLOR 0x07,0x07,0x01
		rjmp main
		_CPI d0, 15
		brne PC+20
		LED_COLOR 0x08,0x07,0x00			; yellow
		rjmp main
		_CPI d0, 16
		brne PC+20
		LED_COLOR 0x09,0x06,0x00
		rjmp main
		_CPI d0, 17
		brne PC+20
		LED_COLOR 0x0a,0x05,0x00
		rjmp main
		_CPI d0, 18
		brne PC+20
		LED_COLOR 0x0b,0x04,0x00			; orange
		rjmp main
		_CPI d0, 19
		brne PC+20
		LED_COLOR 0x0c,0x03,0x00	
		rjmp main
		_CPI d0, 20
		brne PC+20
		LED_COLOR 0x0d,0x02,0x00
		rjmp main
		_CPI d0, 21
		brne PC+20
		LED_COLOR 0x0e,0x01,0x00
		rjmp main
		_CPI d0, 22
		brne PC+20
		LED_COLOR 0x0f,0x00,0x00			; pure red
		rjmp main
		LED_COLOR 0x0f,0x00,0x00
		WAIT_MS 300
		LED_COLOR 0x00,0x00,0x00
		rjmp main


ws2812b4_reset:
		cbi PORTE, 1
		WAIT_US	50 							; 50 us are required, NO smaller works
		ret					

ws2812b4_init:
		OUTI	DDRE,0x02		
		ret
ws2812b4_byte3wr:

		ldi w,8
ws2b3_starta0:
		sbrc a0,7
		rjmp	ws2b3w1
		WS2812b4_WR0		
		rjmp	ws2b3_nexta0
ws2b3w1:
		WS2812b4_WR1
ws2b3_nexta0:
		lsl a0
		dec	w
		brne ws2b3_starta0

		ldi w,8
ws2b3_starta1:
		sbrc a1,7
		rjmp	ws2b3w1a1
		WS2812b4_WR0		
		rjmp	ws2b3_nexta1
ws2b3w1a1:
		WS2812b4_WR1
ws2b3_nexta1:
		lsl a1
		dec	w
		brne ws2b3_starta1

		ldi w,8
ws2b3_starta2:
		sbrc a2,7
		rjmp	ws2b3w1a2
		WS2812b4_WR0		
		rjmp	ws2b3_nexta2
ws2b3w1a2:
		WS2812b4_WR1
ws2b3_nexta2:
		lsl a2
		dec	w
		brne ws2b3_starta2
	
		ret

.dseg
.org 0x0101

sauvegarde: .byte 2
Tref: .byte 2