
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
TC4		EQU	$58

; This initialization routine assumes the existence
; of Delay1MS and Delay routines as developed in Lab 2.
; The initialization routine implements the initialization
; routine in section section 2.2.2.1 of the LCD manual.  It
; is best to run this in the debugger to ensure the power
; supply has a chance to settle.


		ORG $400
		LDS #$4000
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
		
		PSHA
		PSHA
		JSR WriteTime
		
TOP		ldd TSCNT
		addd #!10000	;delays for 10 ms
		std TC4
		brclr TFLG1,$10,*	;wait for 10 ms to pass
		
		;Increment counter by 1
		LDX COUNTER
		INX
		STX COUNTER
		
		CPX #!600	;has one minute passed?
		BLO TOP
		
		LDD #$0
		STD COUNTER
		
		INC MINUTE
		LDAA MINUTE
		CMPA #!60
		BLO END
		
		LDAA #$0
		STAA MINUTE
		INC HOUR
		LDAA HOUR
		CMPA #!24
		BLO END
		
		LDAA #$0
		STAA HOUR
		
END		
	DES
	DES
	JSR AddTime
	
	JSR WriteTime

		BRA TOP

AddTime:
		LDD TSCNT
		LDX #!10
		IDIV
		
		PSHD
		PULY	;Transfer content of D to Y
		
		LDAB MINUTE
		LDAA HOUR
		
LOOP:	CPY #$0
		BEQ END2
		DEY
		INCB
		CMPB #!60
		BLO LOOP
		
		INCA
		LDAB #$0
		CMPA #!24
		BLO LOOP
		
		LDAA #$0
		BRA LOOP
		
END2:	STAB 3,SP
		STAA 2,SP
		RTS
		
		
WriteTime:
		LDAA #$01	;Clear lcd
		PSHA
		LDAA #!1
		PSHA
		JSR SendWithDelay
		PULA
		PULA
		
		CLRA
		LDAB 2,SP
		LDX #!10	
		IDIV	;Divide hour by 10; remainder goes to D, quotient goes to X
		
		PSHD	;push lower digit
		PSHX	;push upper digit
		PULD	;Get upper digit of hour
		
		ADDD #$30
		;LDAB #$31
		PSHB
		LDAA #$1
		PSHA
		BSET PORTM,$04
		JSR SendWithDelay
		BCLR PORTM,$04
		PULA
		PULA
		
		PULD	;Get lower digit of hour
		;Write lower digit
		ADDD #$30
		;LDAB #$32
		PSHB
		LDAA #$1
		PSHA
		BSET PORTM,$04
		JSR SendWithDelay
		BCLR PORTM,$04
		PULA
		PULA
		
		LDAA #$3A	;write : to lcd
		PSHA
		LDAA #$1
		PSHA
		BSET PORTM,$04
		JSR SendWithDelay
		BCLR PORTM,$04
		PULA
		PULA
		
		CLRA
		LDAB 3,SP
		LDX #!10	
		IDIV	;Divide minute by 10; remainder goes to D, quotient goes to X
		
		PSHD	;push lower digit
		PSHX	;push upper digit
		PULD	;Get upper digit of minute
		
		ADDD #$30	;Write higher digit to lcd
		;LDAB #$33
		PSHB
		LDAA #$1
		PSHA
		BSET PORTM,$04
		JSR SendWithDelay
		BCLR PORTM,$04
		PULA
		PULA
		
		PULD	;Get lower digit of minute
		ADDD #$30	;Write lower digit to lcd
		;LDAB #$34
		PSHB
		LDAA #$1
		PSHA
		BSET PORTM,$04
		JSR SendWithDelay
		BCLR PORTM,$04
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

		ldaa #$0C
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
			ldx #!2000 ;use whatever value leads to 1ms delay
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
			
			ORG $1000	
COUNTER	DS 2
MINUTE DS 1
HOUR DS 1