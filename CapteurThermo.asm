/*
 * Capteurthermo.asm
 *
 *  Created: 15.05.2018 15:37:41
 *   Author: Lo�c
 */

 .include "fonction.asm"

 ; === interrupt table
.org 0
		jmp reset
.org INT0addr
		jmp	ext_int0
.org INT1addr
		jmp	ext_int1

; === interrupte service routines

reset:		
			sei
			LDSP RAMEND
			OUTI DDRB,0xff
			cbi DDRE,SPEAKER
			OUTI ADCSR, (1<<ADEN)+(1<<ADIE)+6
			call ws2812b4_init
			call ws2812b4_reset		 
			rcall LCD_init
			rcall wire1_init
			rjmp init

ext_int0:
			
			rjmp reset
			reti

ext_int1:
			
			sbic PIND,1
			rjmp PC-1
			sbis PIND,1
			rjmp PC-1
			ldi xl, low(Selection)
			ldi xh, high(Selection)
			ld b0, x
			ADDI b0, 0b00010000
			st x, b0
			rjmp Trefset
			reti

.include "lcd.asm"
.include "printf.asm"
.include "wire1.asm"
.include "math.asm"


; === program start
init:		
			OUTI EIMSK, 0x03
			sei
			rcall LCD_clear

			ldi xl, low(Selection)
			ldi xh, high(Selection)
			ldi b0, 0b00000000 ; initialisation compteur
			st x, b0

			ldi xl, low(Tref)
			ldi xh, high(Tref)
			ldi b0, 0b10010000 ; Tref LSByte
			ldi b1, 0b00000001 ; Tref MSByte, initialisation � 25�C
			st x+, b1
			st x, b0

			ldi a0,0b00110000	; Tsup LSByte
			ldi a1,0b00000010	; Tsup MSByte, initialisation � 35�C
			ldi a2,0b11110000	; Tinf LSByte
			ldi a3,0b00000000	; Tinf MSByte, initialisation � 15�C
			ldi b2,0b01000000	; Plage LSByte
			ldi b3,0b00000001	; Plage MSByte, initialisation � 20�C


Trefset:	
			sei
			rcall LCD_clear
			WAIT_MS 200
			PRINTF LCD
.db "Set Tref", LF, 0
			
			ldi xl, low(Selection)
			ldi xh, high(Selection)
			ld b0, x

			sbrc b0,4 
			rjmp Mode_F0

			ldi xl, low(Tref)
			ldi xh, high(Tref)
			ld b1, x+
			ld b0, x

			PRINTF LCD
.db "Tref =",FFRAC2+FSIGN, b, 4, $42, "C", LF, 0
			LED_COLOR 0x05,0x05,0x05	; affiche la couleur blanche

			rjmp Trefinc

Mode_F0:
			ldi xl, low(Tref)
			ldi xh, high(Tref)
			ld b1, x+
			ld b0, x
			MODE b0,b1
			PRINTF LCD
.db "Tref =",FFRAC2+FSIGN, b, 4, $42, "F", LF, 0
			LED_COLOR 0x05,0x05,0x05	; affiche la couleur blanche

Trefinc:	
			
			in r16, PIND
			cpi r16, 0b11011111				; increment Tref, Tsup and Tinf if PD4 is pressed
			_BRNE Trefdec					; go to Trefdec if not
			ldi xl, low(Tref)
			ldi xh, high(Tref)
			ld b1, x+
			ld b0, x
			INCT b0,b1,1
			ldi xl, low(Tref)
			ldi xh, high(Tref)
			st x+,b1
			st x, b0
			INCT a0,a1,1
			INCT a2,a3,1
			
			ldi xl, low(Selection)
			ldi xh, high(Selection)
			ld b0, x

			sbrc b0, 4
			rjmp Mode_F1

			ldi xl, low(Tref)
			ldi xh, high(Tref)
			ld b1, x+
			ld b0, x

			
			PRINTF LCD
.db "Tref =",FFRAC2+FSIGN, b, 4, $42, "C", LF, 0
			WAIT_MS 200
			rjmp Trefdec


Mode_F1:		
			ldi xl, low(Tref)
			ldi xh, high(Tref)
			ld b1, x+
			ld b0, x
			MODE b0,b1
			PRINTF LCD
.db "Tref =",FFRAC2+FSIGN, b, 4, $42, "F", LF, 0
			WAIT_MS 200
			

Trefdec:	
			in r16, PIND
			cpi r16, 0b11101111				; decrement Tref, Tsup and Tinf if PD3 is pressed
			_BRNE Trefnext					; go to Trefnext if not
			ldi xl, low(Tref)
			ldi xh, high(Tref)
			ld b1, x+
			ld b0, x
			DECT b0,b1,1
			ldi xl, low(Tref)
			ldi xh, high(Tref)
			st x+,b1
			st x, b0
			DECT a0,a1,1
			DECT a2,a3,1

			ldi xl, low(Selection)
			ldi xh, high(Selection)
			ld b0,x

			sbrc b0,4
			rjmp Mode_F2 
			
			ldi xl, low(Tref)
			ldi xh, high(Tref)
			ld b1, x+
			ld b0, x
			PRINTF LCD
.db "Tref =",FFRAC2+FSIGN, b, 4, $42, "C", LF, 0
			WAIT_MS 200
			rjmp Trefnext


Mode_F2:		
			ldi xl, low(Tref)
			ldi xh, high(Tref)
			ld b1, x+
			ld b0, x
			MODE b0,b1
			PRINTF LCD
.db "Tref =",FFRAC2+FSIGN, b, 4, $42, "F", LF, 0
			WAIT_MS 200

Trefnext:	

			in r16, PIND
			cpi r16, 0b10111111
			brne PC+7
			BOUTON 6						; go to main if PD6 is pressed
			rcall LCD_clear
			rjmp main	
			cpi r16, 0b11110111
			brne PC+7
			BOUTON 3					; clear LCD and go to Tableset if PD2 is pressed
			rcall LCD_clear
			rjmp Tableset
			cpi r16, 0b11111011				; clear LCD and go to Tableset if PD1 is pressed
			brne PC+7
			BOUTON 2
			rcall LCD_clear
			rjmp Tableset		

			rjmp Trefinc					; if any button is pressed, return to Trefinc

Tableset:
			rcall LCD_clear
			WAIT_MS 200
			PRINTF LCD
.db "Set Plage", LF, 0

			ldi xl, low(Selection)
			ldi xh, high(Selection)
			ld b0,x

			sbrc b0,4 
			rjmp Mode_F3
			
			PRINTF LCD
.db "Plage =",FFRAC2+FSIGN, b+2, 4, $42, "C", LF, 0
			WAIT_MS 200
			rjmp Tableinc

Mode_F3:	
			MODE b2,b3
			
			PRINTF LCD
.db "Plage =",FFRAC2+FSIGN, b, 4, $42, "F", LF, 0
			WAIT_MS 200
			


Tableinc:	

			in r16, PIND
			cpi r16, 0b11110111				; increment Table, Tsup and Tinf if PD2 is pressed
			_BRNE Tabledec					; go to Tabledec if not
			INCT b2,b3,1
			INCT a0,a1,0
			DECT a2,a3,0

			ldi xl, low(Selection)
			ldi xh, high(Selection)
			ld b0,x

			sbrc b0,4
			rjmp Mode_F4

			PRINTF LCD
.db "Plage =",FFRAC2+FSIGN, b+2, 4, $42, "C", LF, 0
			WAIT_MS 200
			rjmp Tabledec


Mode_F4:		

			MODE b2,b3
			PRINTF LCD
.db "Plage =",FFRAC2+FSIGN, b, 4, $42, "F", LF, 0
			WAIT_MS 200
		
Tabledec:	
			in r16, PIND
			cpi r16, 0b11111011				; decrement Tref, Tsup and Tinf if PD1 is pressed
			_BRNE Tablenext					; go to Tablenext if not
			DECT b2,b3,1
			DECT a0,a1,0
			INCT a2,a3,0

			ldi xl, low(Selection)
			ldi xh, high(Selection)
			ld b0, x

			sbrc b0,4
			rjmp Mode_F5

			PRINTF LCD
.db "Plage =",FFRAC2+FSIGN, b+2, 4, $42,"C", LF, 0
			WAIT_MS 200
			rjmp Tablenext
Mode_F5:	
			MODE b2,b3
			PRINTF LCD
.db "Plage =",FFRAC2+FSIGN, b, 4, $42,"F", LF, 0
			WAIT_MS 200

Tablenext:
			
			in r16, PIND
			cpi r16, 0b10111111
			brne PC+7
			BOUTON 6						; clear LCD and go to main if PD6 is pressed
			rcall LCD_clear
			rjmp main
			cpi r16, 0b11011111
			brne PC+7
			BOUTON 5						; clear LCD and return to Trefset if PD4 is pressed
			rcall LCD_clear
			rjmp Trefset
			cpi r16, 0b11101111
			brne PC+7
			BOUTON 4					; clear LCD and return to Trefset if PD3 is pressed
			rcall LCD_clear	
			rjmp Trefset
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

			in r16, PIND
			cpi r16, 0b01111111
			brne PC+7
			BOUTON 6						; clear LCD and return to Trefset if PD4 is pressed
			rcall LCD_clear
			rjmp main
			cpi r16, 0b10111111
			brne PC+7
			BOUTON 6						; clear LCD and return to Trefset if PD4 is pressed
			rcall LCD_clear
			rjmp main
			cpi r16, 0b11011111
			brne PC+7
			BOUTON 5						; clear LCD and return to Trefset if PD4 is pressed
			rcall LCD_clear
			rjmp Trefset
			cpi r16, 0b11101111
			brne PC+7
			BOUTON 4					; clear LCD and return to Trefset if PD3 is pressed
			rcall LCD_clear	
			rjmp Trefset
			cpi r16, 0b11110111
			brne PC+7
			BOUTON 3						; clear LCD and go to Tableset if PD2 is pressed
			rcall LCD_clear
			rjmp Tableset
			cpi r16, 0b11111011				; clear LCD and go to Tableset if PD1 is pressed
			brne PC+7
			BOUTON 2
			rcall LCD_clear
			rjmp Tableset
					
			call LCD_clear
			ldi xl, low(Selection)
			ldi xh, high(Selection)
			ld b0,x
			sbrc b0,4
			rjmp Mode_F6
			
			PRINTF LCD
.db			"Temp =",FFRAC2+FSIGN, c+2, 4, $42, "C",LF, 0
			
			WAIT_MS 50
			
			rjmp Temp_color

Mode_F6:
		
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

Alert_blue:
		_SUBI d0, 0
		brpl Pure_blue
		LED_COLOR 0x00,0x00,0x0f
		WAIT_MS 300
		LED_COLOR 0x00,0x00,0x00
		rjmp main
Pure_blue:
		_CPI d0, 0							; compare d0 to various numbers, up to 22
		brne Medium_blue					; branch to next comparison if not equal
		LED_COLOR 0x00,0x00,0x0f			; pure blue							
		rjmp main
Medium_blue:
		_CPI d0, 1
		brne Dodger_blue
		LED_COLOR 0x00,0x01,0x0e				
		rjmp main
Dodger_blue:
		_CPI d0, 2
		brne Deep_sky_blue
		LED_COLOR 0x00,0x03,0x0c
		rjmp main
Deep_sky_blue:
		_CPI d0, 3
		brne Dark_turquoise
		LED_COLOR 0x00,0x05,0x0a
		rjmp main
Dark_turquoise:
		_CPI d0, 4
		brne Turquoise
		LED_COLOR 0x00,0x07,0x08
		rjmp main
Turquoise:
		_CPI d0, 5
		brne Light_turquoise	
		LED_COLOR 0x00,0x09,0x06
		rjmp main
Light_turquoise:
		_CPI d0, 6
		brne Sea_green
		LED_COLOR 0x00,0x0b,0x04
		rjmp main
Sea_green:
		_CPI d0, 7
		brne Marine
		LED_COLOR 0x01,0x0c,0x02			
		rjmp main
Marine:
		_CPI d0, 8
		brne Azure
		LED_COLOR 0x02,0x0a,0x03
		rjmp main
Azure:
		_CPI d0, 9
		brne Ghost_white	
		LED_COLOR 0x03,0x08,0x04
		rjmp main
Ghost_white:
		_CPI d0, 10
		brne White	
		LED_COLOR 0x04,0x06,0x05
		rjmp main
White:
		_CPI d0, 11
		brne Ivory
		LED_COLOR 0x05,0x05,0x05			
		rjmp main
Ivory:
		_CPI d0, 12
		brne Lemon_chiffon
		LED_COLOR 0x06,0x06,0x03
		rjmp main
Lemon_chiffon:
		_CPI d0, 13
		brne Light_yellow
		LED_COLOR 0x07,0x06,0x02
		rjmp main
Light_yellow:
		_CPI d0, 14
		brne Yellow
		LED_COLOR 0x07,0x07,0x01
		rjmp main
Yellow:
		_CPI d0, 15
		brne Gold
		LED_COLOR 0x08,0x07,0x00			
		rjmp main
Gold:
		_CPI d0, 16
		brne Dark_gold
		LED_COLOR 0x09,0x06,0x00
		rjmp main
Dark_gold:
		_CPI d0, 17
		brne Orange
		LED_COLOR 0x0a,0x05,0x00
		rjmp main
Orange:
		_CPI d0, 18
		brne Light_orange_red
		LED_COLOR 0x0b,0x04,0x00			
		rjmp main
Light_orange_red:
		_CPI d0, 19
		brne Orange_red
		LED_COLOR 0x0c,0x03,0x00	
		rjmp main
Orange_red:
		_CPI d0, 20
		brne Dark_orange_red
		LED_COLOR 0x0d,0x02,0x00
		rjmp main
Dark_orange_red:
		_CPI d0, 21
		brne Pure_red
		LED_COLOR 0x0e,0x01,0x00
		rjmp main
Pure_red:
		_CPI d0, 22
		brne Alert_red
		LED_COLOR 0x0f,0x00,0x00			
		rjmp main
Alert_red:
		LED_COLOR 0x0f,0x00,0x00
		WAIT_MS 300
		LED_COLOR 0x00,0x00,0x00
		rjmp main


ws2812b4_reset:
		cbi PORTC, 1
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

Selection: .byte 2
Tref: .byte 2
