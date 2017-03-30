
PORTA		EQU $0
DDRA		EQU $2
PORTM		EQU $250
DDRM		EQU $252

;Timer stuff
TSCR1 	EQU $46
TSCR2 	EQU $4D
TCTL1 	EQU $48
TSCNT	EQU $44
TIOS 	EQU $40
TFLG1 	EQU $4E

; This initialization routine assumes the existence
; of Delay1MS and Delay routines as developed in Lab 2.
; The initialization routine implements the initialization
; routine in section section 2.2.2.1 of the LCD manual.  It
; is best to run this in the debugger to ensure the power
; supply has a chance to settle.


		ORG $400
		LDS $4000
		JSR InitLCD
		
		;Init timer
		ldaa #$90
		staa TSCR1		;Enable timer
		
		ldaa #$03
		staa TSCR2		;Set frequency to 1MHz
		
		ldaa #$10
		staa TIOS		;Set pin 4 to output compare
		
		ldaa #$01
		staa TCTL1		 ;Set pin 4 to toggle
		
		
		LDD #$0
		STD COUNTER
		STAA MINUTE
		STAA HOUR
		
		JSR WriteTime
		
TOP		ldd TSCNT
		addd #!10000	;delays for 10 ms
		std TC4
		brclr TFLG1,$10,*	;wait for 10 ms to pass
		
		;Increment counter by 1
		LDX COUNTER
		INX
		STX COUNTER
		
		CPX #!6000	;has one minute passed?
		BNE TOP
		
		INC MINUTE
		LDAA MINUTE
		CMPA #!60
		BNE END
		
		CLRA
		STAA MINUTE
		INC HOUR
		CMPA #!24
		BNE END
		
		CLRA
		STAA HOUR
		
END		
	
	JSR WriteTime

		BRA TOP
		
WriteTime:
		LDAA #$01	;Clear lcd
		PSHA
		LDAA #$1
		PSHA
		JSR SendWithDelay
		PULA
		PULA
		
		CLRA
		LDAB HOUR
		LDX #!10	
		FDIV	;Divide hour by 10; remainder goes to D, quotient goes to X
		
		PSHD	;push lower digit
		PSHX	;push upper digit
		PULD	;Get upper digit of hour
		
		ADDD #$30
		PSHB
		LDAA #$1
		PSHA
		JSR SendWithDelay
		PULA
		PULA
		
		PULD	;Get lower digit of hour
		;Write lower digit
		ADDD #$30
		PSHB
		LDAA #$1
		PSHA
		JSR SendWithDelay
		PULA
		PULA
		
		LDAA #$3A	;write : to lcd
		PSHA
		LDAA #$1
		PSHA
		JSR SendWithDelay
		PULA
		PULA
		
		CLRA
		LDAB MINUTE
		LDX #!10	
		FDIV	;Divide minute by 10; remainder goes to D, quotient goes to X
		
		PSHD	;push lower digit
		PSHX	;push upper digit
		PULD	;Get upper digit of minute
		
		ADDD #$30	;Write higher digit to lcd
		PSHB
		LDAA #$1
		PSHA
		JSR SendWithDelay
		PULA
		PULA
		
		PULD	;Get lower digit of minute
		ADDD #$30	;Write lower digit to lcd
		PSHB
		LDAA #$1
		PSHA
		JSR SendWithDelay
		PULA
		PULA
		
		RTS

InitLCD:	ldaa #$FF ; Set port A to output for now
		staa DDRA

                ldaa #$1C ; Set port M bits 4,3,2
		staa DDRM


		LDAA #$30	; We need to send this command a bunch of times
		psha
		LDAA #5
		psha
		jsr SendWithDelay	;Store 0x30 in PORTA, toggle PORTM[4], delay 5 ms
		pula

		ldaa #1
		psha
		jsr SendWithDelay	;Store 0x30 in PORTA, toggle PORTM[4], delay 1 ms
		jsr SendWithDelay	;same
		jsr SendWithDelay	;same
		pula
		pula

		ldaa #$08
		psha
		ldaa #1
		psha
		jsr SendWithDelay	;Store 0x08 in PORTA, toggle PORTM[4], delay 1 ms
		pula
		pula

		ldaa #1
		psha
		psha
		jsr SendWithDelay	;Store 0x1 in PORTA, toggle PORTM[4], delay 1 ms
		pula
		pula

		ldaa #6
		psha
		ldaa #1
		psha
		jsr SendWithDelay	;Store 0x6 in PORTA, toggle PORTM[4], delay 1 ms
		pula
		pula

		ldaa #$0E
		psha
		ldaa #1
		psha
		jsr SendWithDelay	;Store 0xE in PORTA, toggle PORTM[4], delay 1 ms
		pula
		pula

		rts

SendWithDelay:  TSX
		LDAA 3,x
		STAA PORTA

		bset PORTM,$10	 ; Turn on bit 4
		jsr Delay1MS
		bclr PORTM,$10	 ; Turn off bit 4

		tsx
		ldaa 2,x
		psha
		clra
		psha
		jsr Delay
		pula
		pula
		rts

Delay1MS:	pshx
			ldx #$2 ;use whatever value leads to 1ms delay
msLoop:  	dex
			bne msLoop
			pulx
			rts		; Use your Delay1MS routine from part 1
				
Delay:		tsx
			ldx 2,x
delayLoop:	jsr Delay1MS
			dex
			bne delayLoop
			rts		; Implement a variable delay using a stack parameter
		
COUNTER	DS 2
MINUTE DS 1
HOUR DS 1