
PORTA	EQU $0
PORTB	EQU $1
DDRA	EQU $2
DDRB	EQU $3
PORTM	EQU $250
DDRM	EQU $252

; Timer stuff
TSCR1	EQU $46
TSCR2	EQU $4D
TCTL1	EQU $48
TSCNT	EQU $44
TIOS	EQU $40
TFLG1	EQU $4E
TC4	EQU $58

		ORG $1000
; Global variables
COUNTER	DS 2
MINUTE	DS 1
HOUR	DS 1
PREVBUT DS 1
RNDOFFSET DS 1

; This initialization routine assumes the existence
; of Delay1MS and Delay routines as developed in Lab 2.
; The initialization routine implements the initialization
; routine in section section 2.2.2.1 of the LCD manual.  It
; is best to run this in the debugger to ensure the power
; supply has a chance to settle.


		ORG $400
		LDS #$4000
		JSR InitLCD		; Start LCD
		JSR InitButtons ; Start buttons
		
		; Init timer
		LDAA #$90
		STAA TSCR1		; Enable timer
		
		LDAA #$03
		STAA TSCR2		; Set frequency to 1MHz
		
		LDAA #$10
		STAA TIOS		; Set pin 4 to output compare
		
		LDAA #$01
		STAA TCTL1		; Set pin 4 to toggle
		
		
		LDD #$0
		STD COUNTER
		STAA MINUTE
		STAA HOUR
		STAA PREVBUT
		STAA RNDOFFSET
		
		BRA TOP			; Start the loop



  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                          ;;
;;      SUBROUTINES         ;;
;;                          ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;


TOP:

		;Increment counter by 1
		LDX COUNTER
		INX
		STX COUNTER
		
		CPX #!600			; Has one minute passed?
		BLO END
		
		LDD #$0				;reset counter to 0
		STD COUNTER
		
		INC MINUTE			;increment minute
		LDAA MINUTE			;compare minute to 60 (ie 1 hour)
		CMPA #!60
		BLO END
		
		LDAA #$0			;reset minute and increment hour
		STAA MINUTE
		INC HOUR
		LDAA HOUR
		CMPA #!24			;check if hour is back to midnight
		BLO END
		
		LDAA #$0			;reset hour to 0
		STAA HOUR

END:	
		; Only display on button press
		DES					; Save space for return value
		JSR ShouldDisplay	; Check if a button has been pressed
		PULB				; Bring result into accumulator B (zero = "no display", non-zero = "yes display")

		CMPB #0			;if button is 0 then turn off the screen
		BEQ OFFSCREEN

		LDAA PREVBUT
		CBA
		BEQ SKIPRAND		;if button was previously pressed, skip turning on screen and generating offset
		JSR ONSCREEN		;if button is just now being pressed then determine new random offset and turn on screen
		LDAA #$1		;store current button state as previous button state for next loop
		STAA PREVBUTT

SKIPRAND:	DES
		DES
		JSR RandomTime		;load current time + offset into stack
		JSR WriteTime		;display time+offset to lcd
		INS			;clean up stack
		INS
		
		BRA TOP			;restart loop

OFFSCREEN:	
		LDAA #$08	;Turn off the screen
		PSHA
		LDAA #1
		PSHA
		JSR SendWithDelay
		PULA
		PULA

		LDAA #0		;reset values
		STAA PREVBUT
		STAA RNDOFFSET
		BRA TOP

ONSCREEN:

		LDAA #$0E		;turn on the screen
		PSHA
		LDAA #1
		PSHA
		JSR SendWithDelay	
		PULA
		PULA

		LDD TSCNT	;generate random value
		LDX #!10
		IDIV
		STAB RNDOFFSET	;stores random value in random offset
		RTS

RandomTime:
		
		LDY RNDOFFSET		; get the current offset
		
		LDAB MINUTE
		LDAA HOUR

LOOP:
		CPY #$0			;until Y = 0 increment B (minute)
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

END2:
		STAB 3,SP		;store time+offset in stack
		STAA 2,SP
		RTS

ExitSubroutine:
		RTS

WriteTime:
		; Clear LCD
		LDAA #$01	
		PSHA
		LDAA #$1
		PSHA
		JSR SendWithDelay
		PULA
		PULA

		CLRA
		LDAB 2,SP			;get the hour from stack
		LDX #!10	
		IDIV				;Divide hour by 10; remainder goes to D, quotient goes to X
		
		PSHD				; Push lower digit
		PSHX				; Push upper digit
		PULD				; Get upper digit of hour
		
		ADDD #$30
		PSHB
		LDAA #$1
		PSHA
		BSET PORTM,$04
		JSR SendWithDelay
		BCLR PORTM,$04
		PULA
		PULA
	
		PULD				; Get lower digit of hour
		;Write lower digit
		ADDD #$30
		PSHB
		LDAA #$1
		PSHA
		BSET PORTM,$04
		JSR SendWithDelay
		BCLR PORTM,$04
		PULA
		PULA
		
		LDAA #$3A			; Write : to lcd
		PSHA
		LDAA #$1
		PSHA
		BSET PORTM,$04
		JSR SendWithDelay
		BCLR PORTM,$04
		PULA
		PULA
	
		CLRA
		LDAB 3,SP			;get current minute + offset from stack
		LDX #!10	
		IDIV				; Divide minute by 10; remainder goes to D, quotient goes to X
		
		PSHD				; Push lower digit
		PSHX				; Push upper digit
		PULD				; Get upper digit of minute
		
		ADDD #$30			; Write higher digit to lcd
		PSHB
		LDAA #$1
		PSHA
		BSET PORTM,$04
		JSR SendWithDelay
		BCLR PORTM,$04
		PULA
		PULA
		
		PULD				; Get lower digit of minute
		ADDD #$30			; Write lower digit to lcd
		PSHB
		LDAA #$1
		PSHA
		BSET PORTM,$04
		JSR SendWithDelay
		BCLR PORTM,$04
		PULA
		PULA
		
		RTS

InitLCD:
		; Set port A to output for now
		LDAA #$FF 
		STAA DDRA

		LDAA #$1C			; Set port M bits 4,3,2
		STAA DDRM


		LDAA #$30			; We need to send this command a bunch of times
		PSHA
		LDAA #5
		PSHA
		JSR SendWithDelay	; Store 0x30 in PORTA, toggle PORTM[4], delay 5 ms
		PULA

		LDAA #1
		PSHA
		JSR SendWithDelay	; Store 0x30 in PORTA, toggle PORTM[4], delay 1 ms
		JSR SendWithDelay	; same
		JSR SendWithDelay	; same
		PULA
		PULA

		LDAA #$08
		PSHA
		LDAA #1
		PSHA
		JSR SendWithDelay	; Store 0x08 in PORTA, toggle PORTM[4], delay 1 ms
		PULA
		PULA

		LDAA #1
		PSHA
		PSHA
		JSR SendWithDelay	; Store 0x1 in PORTA, toggle PORTM[4], delay 1 ms
		PULA
		PULA

		LDAA #6
		PSHA
		LDAA #1
		PSHA
		JSR SendWithDelay	; Store 0x6 in PORTA, toggle PORTM[4], delay 1 ms
		PULA
		PULA

		LDAA #$0E
		PSHA
		LDAA #1
		PSHA
		JSR SendWithDelay	; Store 0xE in PORTA, toggle PORTM[4], delay 1 ms
		PULA
		PULA

		RTS

SendWithDelay:
		TSX
		LDAA 3,X
		STAA PORTA

		BSET PORTM,$10		; Turn on bit 4
		JSR Delay1MS
		BCLR PORTM,$10		; Turn off bit 4

		TSX
		LDAA 2,X
		PSHA
		CLRA
		PSHA
		JSR Delay
		PULA
		PULA
		RTS

Delay1MS:
		PSHX
		LDX #$2				; use whatever value leads to 1ms delay
msLoop:
		DEX
		BNE msLoop
		PULX
		RTS					; Use your Delay1MS routine from part 1

Delay:
		PSHX
		TSX
		LDX 2,X
delayLoop:
		JSR Delay1MS
		DEX
		BNE delayLoop
		PULX
		RTS					; Implement a variable delay using a stack parameter



  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                          ;;
;;      DARRYL SUBS         ;;
;;                          ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; General Structure:
;;
;; Don't call *blah*_internal: they just help out
;; Processor register state is saved (not CCR though)
;; 
;; General internal conventions:
;; Return location address is stored in X.
;; Value to save to *X is usually stored in B.

InitButtons:
		BSET DDRB,$F0		; Set port B to input/output (automatically pull-down)
		; Set up PortB
		PSHA
		LDAA #$0
		STAA PORTB
		PULA
		RTS

ButtonRowPressCheck_internal:	; FIXME: Change to interrupt-driven, or at least event-driven
		; Be a nice guy, save the processor registers before working
		PSHD
		PSHX
		PSHY

		LEAX 8,SP	; Store the return address location in X

		; Listen to button row (its stored on A already)
		STAA PORTB							; Set button listening to that row
		JSR Delay1MS						; Give PORTB time to settle

pChkLoop_internal:
		BRSET PORTB,$01,Depress_internal	; A button was pressed
		BRSET PORTB,$02,Depress_internal	; A button was pressed
		BRSET PORTB,$04,Depress_internal	; A button was pressed
		BRSET PORTB,$08,Depress_internal	; A button was pressed
NoPress_internal:
		; At request of Tom.
		LDAA #!10							; Yes, switch press detected, now debounce
		LDAB #!0
		PSHD
		BSR Delay							; 10mS delay for debounce FIXME: Use microprocessor timer unit
		PULD

		; Set return value to zero
		CLRA
		BRA SaveReturn_internal

Depress_internal:
		LDAA #!10							; Yes, switch press detected, now debounce
		LDAB #!0
		PSHD
		BSR Delay							; 10mS delay for debounce FIXME: Use microprocessor timer unit
		PULD
		BRSET PORTB,$01,Unpress_internal	; A button was pressed
		BRSET PORTB,$02,Unpress_internal	; A button was pressed
		BRSET PORTB,$04,Unpress_internal	; A button was pressed
		BRSET PORTB,$08,Unpress_internal	; A button was pressed
		BRA pChkLoop_internal 				; If switch press not detected after debounce, return to check loop
Unpress_internal:
		;BRSET PORTB,$01,*					; A button was pressed
		;BRSET PORTB,$02,*					; A button was pressed
		;BRSET PORTB,$04,*					; A button was pressed
		;BRSET PORTB,$08,*					; A button was pressed
		;LDAA #!10							; 10mS delay for release of switch press
		;LDAB #!0
		;PSHD
		;BSR Delay							; FIXME: Use microprocessor timer unit
		;PULD
		;BRSET PORTB,$01,Unpress_internal	; A button was pressed
		;BRSET PORTB,$02,Unpress_internal	; A button was pressed
		;BRSET PORTB,$04,Unpress_internal	; A button was pressed
		;BRSET PORTB,$08,Unpress_internal	; A button was pressed
		
		; Done, store return value
		LDAB #!1
		BRA SaveReturn_internal


ShouldDisplay:
		; Be a nice guy, save the processor registers before working
		PSHD
		PSHX
		PSHY

		LEAX 8,SP							; Store the return address location in X

		; Scan through buttons
		LDAA #10							; Start at first button
DisLoop_internal:
		DES									; Leave space for the return value
		JSR ButtonRowPressCheck_internal	; Check row for button press
		PULB								; Get result from stack
		CMPB #$1							; Compare B to see if true
		BEQ SaveReturn_internal				; If true, save and RTS
		LSLA								; Shift to next row
		CMPA #10							; Check if there's no more rows to Check
		BGE DisLoop_internal				; More rows to Check
		CLRB								; No more rows, return 0
		BRA SaveReturn_internal

SaveReturn_internal:
		STAB 0,X							; Save value to save location
		BRA NiceGuyRTS_internal				; Return

NiceGuyRTS_internal:
		; Restore registers and exit subroutine
		PULY
		PULX
		PULD
		RTS
