;Main.asm by Johnny Gaddis
;3/2/17
;Lab 3

;Include derivative-specific definitions
            INCLUDE 'derivative.inc'
            
;Export symbols
            XDEF _Startup, main, interrupt        
            XREF __SEG_END_SSTACK   ;Symbol defined by the linker for the end of the stack

;Variable/data section
RAMSPACE	EQU $0060
ROMSPACE 	EQU $E000
		ORG	RAMSPACE
count0      RMB 1
value 		RMB 1
temp 		RMB 1
tempa 		RMB 1
tempb 		RMB 1
tempc 		RMB 1
tempd 		RMB 1
tempe 		RMB 1
tempf 		RMB 1
tempg 		RMB 1
temph       RMB 1
tempi       RMB 1
tempj		RMB 1
tempASCII   RMB 1
count1      RMB 1
ledVal1     RMB 1
ledVal2     RMB 1
sub_low 	RMB 1
sub_high 	RMB 1
div_result  RMB 1
neg_flag    RMB 1
CHAR_VAR 	RMB 1
MSG_COUNTER RMB 1
ddiv_result RMB 1
highvar     RMB 1
lowvar      RMB 1
		ORG ROMSPACE
lm19val     	DC.B $07, $48
ascii      		DC.B '0','1','2','3','4','5','6','7','8','9'
TEMP_CONST_HIGH DC.B $48
TEMP_CONST_LOW  DC.B $D1

main:
_Startup:
			;Disable watchdog & enable reset
			LDA #$53
            STA SOPT1
           
            ;Initialize port B and keyboard
            LDA #$FF
            STA PTBDD
            LDA #%11111011
            STA PTADD
            LDA #$00
            STA PTBD
            STA PTAD
            LDA #%00001000
            STA ledVal1
            LDA #%00001001
            STA ledVal2
            			
			LDA #$20
			STA count1
			LDA #$FF 
			STA count0
    		
		  	;Heartbeat Setup
		  	BSET 6, MTIMSC
		  	BCLR 4,MTIMSC
		  	LDA #$0F
		  	STA MTIMCLK
		  	LDA #$FF
		  	STA MTIMMOD
		  	LDA #61
 			STA value
		  	CLI
		  			
		  	;Initialize the LCD
		  	JSR initLCD
		  	JSR reset
		  	
		  	;Initialize the A to D
		  	LDA #%00000000
		  	STA ADCCFG		  	
		  	
		  	;Main loop for polling and seting LED values
mainLoop:			
			JSR delay10 
			JSR delay10 
			JSR led
			JSR poll
			
            BRA mainLoop        
			    
            ;Clear the interupt flag and decrement value then return if value is greater than 0
interrupt:
			BCLR 7,MTIMSC				
			LDA value
			DECA
			STA value
			BEQ toggle
			RTI
			
			;Togle the LED and reset value then return
toggle:
			LDA #$80
            EOR ledVal1
 			STA ledVal1
 	 			
 			LDA #61
 			STA value 			
 				
 			RTI
		
			;Update LEDS
led:
			LDA #$FF
			STA PTBDD
			
			LDA ledVal1
			STA PTBD
			
			BCLR 3,PTBD
			BSET 3,PTBD
			
			LDA ledVal2
			STA PTBD
			
			BCLR 3,PTBD	
			BSET 3,PTBD	
				
			RTS

			;Run characters
runA:
			JSR takeData			
			BRA mainLoop
			
runB:
			JSR charB
			BRA mainLoop
			
runC:
			JSR charC
			BRA mainLoop
			
runD:
			JSR charD
			BRA mainLoop
			
			;Keypad Polling
poll:
			LDA #%11101010
			STA PTBD
			
			BCLR 3,PTBD
			BSET 3,PTBD
			
			LDA #$0F
			STA PTBDD
			
			LDA #%00001011
			STA PTBD
			
			BCLR 3,PTBD
			BSET 3,PTBD
			
			LDA PTBD
			CBEQA #%01111011, runA
			CBEQA #%10111011, runB
			CBEQA #%11011011, runC
			CBEQA #%11101011, runD
			
			LDA #$FF
			STA PTBDD
			
			
			LDA #%11011010
			STA PTBD
			
			BCLR 3,PTBD
			BSET 3,PTBD
			
			LDA #$0F
			STA PTBDD
			
			LDA #%00001011
			STA PTBD
			
			BCLR 3,PTBD
			BSET 3,PTBD
			
			LDA PTBD
			CBEQA #%01111011, run3
			CBEQA #%10111011, run6
			CBEQA #%11011011, run9
			CBEQA #%11101011, runHash
			
			LDA #$FF
			STA PTBDD
			
			
			LDA #%10111010
			STA PTBD
			
			BCLR 3,PTBD
			BSET 3,PTBD
			
			LDA #$0F
			STA PTBDD
			
			LDA #%00001011
			STA PTBD
			
			BCLR 3,PTBD
			BSET 3,PTBD
			
			LDA PTBD
			CBEQA #%01111011, run2
			CBEQA #%10111011, run5
			CBEQA #%11011011, run8
			CBEQA #%11101011, run0
			
			LDA #$FF
			STA PTBDD
			
			
			LDA #%01111010
			STA PTBD
			
			BCLR 3,PTBD
			BSET 3,PTBD
			
			LDA #$0F
			STA PTBDD
			
			LDA #%00001011
			STA PTBD
			
			BCLR 3,PTBD
			BSET 3,PTBD
			
			LDA PTBD
			CBEQA #%01111011, run1
			CBEQA #%10111011, run4
			CBEQA #%11011011, run7
			CBEQA #%11101011, runStar
			
			LDA #$FF
			STA PTBDD			 
			
			RTS		
			
			;Run more characters			
run3:
			JSR takeData
			JSR mainLoop
			
run6:
			JSR takeData
			JSR mainLoop
			
run9:
			JSR takeData
			JSR mainLoop
			
runHash:
			JSR charF
			JSR mainLoop
			
run1:
			JSR takeData
			JSR mainLoop
			
run4:
 			JSR takeData
			JSR mainLoop
			
run7:
			JSR takeData
			JSR mainLoop
			
runStar:
			JSR reset
			JSR mainLoop
				
run2:
			JSR takeData			
			JSR mainLoop
			
run5:
			JSR takeData
			JSR mainLoop
			
run8:
			JSR takeData
			JSR mainLoop
			
run0:
			JSR takeData
			JSR mainLoop
			
			;Initialize LCD			
initLCD:
			JSR delay
			JSR delay
			JSR delay
			JSR delay
			JSR delay
			JSR delay
			
			LDA #%00111100
			STA PTBD
			
			BCLR 3,PTBD
			BSET 3,PTBD
			
			JSR delay
			JSR delay
			
			LDA #%00111100
			STA PTBD
			
			BCLR 3,PTBD
			BSET 3,PTBD
			
			JSR delay
			JSR delay 
			
			LDA #%00111100
			JSR lcd_write
			
			BCLR 3,PTBD
			BSET 3,PTBD
			
			JSR delay
			JSR delay 
			
			LDA #%00101100
			JSR lcd_write
			
			LDA #%00101100
			JSR lcd_write
			LDA #%10001100
			JSR lcd_write 
			
			LDA #%00001100
			JSR lcd_write 
			LDA #%10001100
			JSR lcd_write 
			
			LDA #%00001100
			JSR lcd_write 
			JSR delay 
			JSR delay 
			LDA #%00011100
			JSR lcd_write 
			JSR delay 
			JSR delay 
			
			LDA #%00001100
			JSR lcd_write 
			LDA #%11111100
			JSR lcd_write
			
			JSR delay 
			JSR delay 
			JSR delay 
			
			LDA #%00001100
			JSR lcd_write 
			LDA #%01101100
			JSR lcd_write	
			
			JSR delay 
			JSR delay 
			JSR delay	
			
			LDA #%10001100 
			JSR lcd_addr
			LDA #%00001100
			JSR lcd_addr		
		
			RTS             
			 
clear:
			LDA #$FF
			STA PTBDD
			
			BCLR 0, PTAD
			LDA #%00001100
			JSR lcd_write 
			JSR delay 
			JSR delay 
			LDA #%00011100
			JSR lcd_write 
			JSR delay 
			JSR delay 
			BSET 0, PTAD
			
			RTS

			;Initialize the LCD with "Enter n:"
reset:
			LDA #$FF
			STA PTBDD
			
			BCLR 0, PTAD
			LDA #%00001100
			JSR lcd_write 
			JSR delay 
			JSR delay 
			LDA #%00011100
			JSR lcd_write 
			JSR delay 
			JSR delay 
			BSET 0, PTAD
			
			LDA #%01001100
			JSR lcd_write
			LDA #%01011100
			JSR lcd_write
			
			LDA #%01101100
			JSR lcd_write
			LDA #%11101100
			JSR lcd_write
			
			LDA #%01111100
			JSR lcd_write
			LDA #%01001100
			JSR lcd_write
			
			LDA #%01101100
			JSR lcd_write
			LDA #%01011100
			JSR lcd_write
			
			LDA #%01111100
			JSR lcd_write
			LDA #%00101100
			JSR lcd_write
			
			LDA #%00011100
			JSR lcd_write
			LDA #%00001100
			JSR lcd_write
			
			LDA #%01101100
			JSR lcd_write
			LDA #%11101100
			JSR lcd_write
			
			LDA #%00111100
			JSR lcd_write
			LDA #%10101100
			JSR lcd_write
			
			RTS
			
			;Write LCD adress
lcd_addr:
			BCLR 0, PTAD
			STA PTBD
			
			BCLR 3,PTBD
			BSET 3,PTBD
			
			JSR delay 
			JSR delay 
			JSR delay 
			JSR delay 
			
			BSET 0, PTAD
			RTS	

			;Write LCD value for initialization
lcd_write:	
			STA PTBD
			
			BCLR 3,PTBD
			BSET 3,PTBD
			
			JSR delay 
			JSR delay 
			JSR delay 
			JSR delay  
			
			RTS
			
			;Delay Subroutine 
delay: 
			LDA #$FF
			STA count0
d:
			LDA count0 
			DECA 
			STA count0
			NOP
			NOP
			NOP
			NOP
			
			NOP
			NOP
			NOP
			NOP
			
			NOP
			NOP
			NOP
			NOP
			
			NOP
			NOP
			NOP
			NOP
			
			NOP
			NOP
			NOP
			NOP
			
			NOP
			NOP
			NOP
			NOP
			
			NOP
			NOP
			NOP
			NOP
			
			NOP
			NOP
			NOP
			NOP
			
			NOP
			NOP
			NOP
			NOP
			
			NOP
			NOP
			NOP
			NOP
			
			BNE d
			
			RTS
			
delay10:
			JSR delay 
			JSR delay 
			JSR delay 
			JSR delay 
			JSR delay 
			JSR delay 
			JSR delay 
			JSR delay 
			JSR delay 
			JSR delay 
			JSR delay 
			JSR delay 
			JSR delay 
			JSR delay 
			JSR delay 
			JSR delay 
			JSR delay 
			JSR delay 
			JSR delay 
			JSR delay 
			JSR delay 
			
			RTS
			
			;Character Subroutines
char0:			
			LDA #$FF
			STA PTBDD
			LDA #%00111100
			JSR lcd_write 
			LDA #%00001100
			JSR lcd_write

			LDA #%00001001
    		STA ledVal2

			RTS
			
char1:
			LDA #$FF
			STA PTBDD
			LDA #%00111100
			JSR lcd_write 
			LDA #%00011100
			JSR lcd_write

			LDA #%00011001
    		STA ledVal2
    		
			RTS
			
char2:
			LDA #$FF
			STA PTBDD
			LDA #%00111100
			JSR lcd_write
			LDA #%00101100
			JSR lcd_write
			
			LDA #%00101001
    		STA ledVal2

			RTS
			
char3:
			LDA #$FF
			STA PTBDD
			LDA #%00111100
			JSR lcd_write 
			LDA #%00111100
			JSR lcd_write
			
    		LDA #%00111001
    		STA ledVal2

			RTS
			
char4:
			LDA #$FF
			STA PTBDD
			LDA #%00111100
			JSR lcd_write 
			LDA #%01001100
			JSR lcd_write
			
   			LDA #%01001001
    		STA ledVal2

			RTS
			
char5:
			LDA #$FF
			STA PTBDD
			LDA #%00111100
			JSR lcd_write 
			LDA #%01011100
			JSR lcd_write
			
			LDA #%01011001
    		STA ledVal2

			RTS
			
			
char6:
			LDA #$FF
			STA PTBDD
			LDA #%00111100
			JSR lcd_write 
			LDA #%01101100
			JSR lcd_write
			
			LDA #%01101001
    		STA ledVal2

			RTS
			
char7:
			LDA #$FF
			STA PTBDD
			LDA #%00111100
			JSR lcd_write 
			LDA #%01111100
			JSR lcd_write
			
    		LDA #%01111001
    		STA ledVal2
  
			RTS
			
char8:
			LDA #$FF
			STA PTBDD
			LDA #%00111100
			JSR lcd_write 
			LDA #%10001100
			JSR lcd_write
			
			LDA #%10001001
    		STA ledVal2

			RTS
			
char9:
			LDA #$FF
			STA PTBDD
			LDA #%00111100
			JSR lcd_write
			LDA #%10011100
			JSR lcd_write
			
			LDA #%10011001
    		STA ledVal2

			RTS
			
charA:
			LDA #$FF
			STA PTBDD
			LDA #%01001100
			JSR lcd_write
			LDA #%00011100
			JSR lcd_write
			
			LDA #%10101001
    		STA ledVal2

			RTS
			
charB:
			LDA #$FF
			STA PTBDD
			LDA #%01001100
			JSR lcd_write 
			LDA #%00101100
			JSR lcd_write
			
    		LDA #%10111001
    		STA ledVal2
			
			RTS
			
charC:		
			LDA #$FF
			STA PTBDD
			LDA #%01001100
			JSR lcd_write 
			LDA #%00111100
			JSR lcd_write
			
    		LDA #%11001001
    		STA ledVal2
			
			RTS
			
charD:
			LDA #$FF
			STA PTBDD
			LDA #%01001100
			JSR lcd_write 
			LDA #%01001100
			JSR lcd_write
			
    		LDA #%11011001
    		STA ledVal2

			RTS
			
charE:
			LDA #$FF
			STA PTBDD
			LDA #%01001100
			JSR lcd_write 
			LDA #%01011100
			JSR lcd_write
			
    		LDA #%11101001
    		STA ledVal2

			RTS
			
charF:
			LDA #$FF
			STA PTBDD
			
			LDA #'H'
			AND #$F0
			ADD #12
			JSR lcd_write 
			
			LDA #'H'
			NSA
			AND #$F0
			ADD #12
			JSR lcd_write
			
    		LDA #%11111001
    		STA ledVal2
			
			RTS
			
tensplace: 
			LDA tempd
			SUB #$0A
			STA tempd
			LDA tempc
			INCA 
			STA tempc		
			BRA continue 
					
takeData:
			LDA #$FF
			STA PTBDD
			
			LDA #%00000010
		  	STA ADCSC1
		  	JSR delay10
		  	
		  	JSR delay10
		  	LDA ADCRL
		  	STA tempb	
			LDA ADCRH
			STA tempa
			
			LDA #129
			LDX tempb
 			MUL
			STA tempb
			STX tempa
		
			LDX #$01
			LDA tempb
			SUB TEMP_CONST_LOW
			STA sub_low
			
			LDA tempa
			SBC TEMP_CONST_HIGH
			STA sub_high
		
			LDHX sub_high
			LDA sub_low
			LDX #117
			DIV
			STA tempb
		  	
		  	JSR clear
		  	
		  	LDA tempb
			NSA
			AND #$0F
			LDX #16
			MUL
			STA ddiv_result
			LDA tempb
			AND #$0F
			ADD ddiv_result
			STA ddiv_result
			
			;;;;;;;;;;;;;;;;
			
			LDA ddiv_result
		  	AND #$F0
		  	ADD #$30
		  	STA tempc
		  		
		  	LDA ddiv_result
		  	AND #$0F
		  	ADD #$30
		  	STA tempd
		  	LDA ddiv_result
		  	AND #$0F
		  	CMP #$0A
		  	BPL tensplace
continue:		  	
		  	LDA #$73 
		  	SUB ddiv_result
		  	STA tempe
		  	LDA #0
		  	STA tempf
checkloop:
		  	LDA tempe
 		  	CMP #$0A
		  	BPL tensplace1
		  	LDA tempf
			ADD #$30
			STA tempf
			LDA tempf
			SUB #10
			STA tempf
			LDA tempe
			ADD #$30
			STA tempe
		  	JSR calculate_int_temp	  	
tensplace1:
			LDA tempf
			INCA
			STA tempf
			LDA tempe
			SUB #10
			STA tempe
			BRA checkloop
			
writeit:
		  	
		  	LDA #'T'
			AND #$F0
			ADD #12
			JSR lcd_write 
			
			LDA #'T'
			NSA
			AND #$F0
			ADD #12
			JSR lcd_write
			
			LDA #','
			AND #$F0
			ADD #12
			JSR lcd_write 
			
			LDA #','
			NSA
			AND #$F0
			ADD #12
			JSR lcd_write
			
			LDA #'C'
			AND #$F0
			ADD #12
			JSR lcd_write 
			
			LDA #'C'
			NSA
			AND #$F0
			ADD #12
			JSR lcd_write
			
			LDA #':'
			AND #$F0
			ADD #12
			JSR lcd_write 
			
			LDA #':'
			NSA
			AND #$F0
			ADD #12
			JSR lcd_write
		  	
			LDA tempc
			AND #$F0
			ADD #12
			JSR lcd_write 
			LDA tempc
			NSA
			AND #$F0
			ADD #12
			JSR lcd_write
			
			LDA tempd
			AND #$F0
			ADD #12
			JSR lcd_write 
			LDA tempd
			NSA
			AND #$F0
			ADD #12
			JSR lcd_write
			
			LDA #' '
			AND #$F0
			ADD #12
			JSR lcd_write 
			
			LDA #' '
			NSA
			AND #$F0
			ADD #12
			JSR lcd_write
			
			LDA #'T'
			AND #$F0
			ADD #12
			JSR lcd_write 
			
			LDA #'T'
			NSA
			AND #$F0
			ADD #12
			JSR lcd_write
			
			LDA #','
			AND #$F0
			ADD #12
			JSR lcd_write 
			
			LDA #','
			NSA
			AND #$F0
			ADD #12
			JSR lcd_write
			
			LDA #'K'
			AND #$F0
			ADD #12
			JSR lcd_write 
			
			LDA #'K'
			NSA
			AND #$F0
			ADD #12
			JSR lcd_write
			
			LDA #':'
			AND #$F0
			ADD #12
			JSR lcd_write 
			
			LDA #':'
			NSA
			AND #$F0
			ADD #12
			JSR lcd_write
		  	
		  	LDA #'3'
			AND #$F0
			ADD #12
			JSR lcd_write 
			
			LDA #'3'
			NSA
			AND #$F0
			ADD #12
			JSR lcd_write
			
			LDA tempf
			AND #$F0
			ADD #12
			JSR lcd_write 
			LDA tempf
			NSA
			AND #$F0
			ADD #12
			JSR lcd_write
			
			LDA tempe
			AND #$F0
			ADD #12
			JSR lcd_write 
			LDA tempe
			NSA
			AND #$F0
			ADD #12
			JSR lcd_write
			
			LDA PTAD
			PSHA
			
			BCLR 0, PTAD
			BCLR 1, PTAD
			
			LDA #$CC
			STA PTBD
			BCLR 3, PTBD ; Clock
			BSET 3, PTBD
			
			JSR delay10
			
			LDA #$0C
			STA PTBD
			BCLR 3, PTBD ; Clock
			BSET 3, PTBD
			
			JSR delay10
			
			PULA
			STA PTAD
			
			
			LDA #'T'
			AND #$F0
			ADD #12
			JSR lcd_write 
			
			LDA #'T'
			NSA
			AND #$F0
			ADD #12
			JSR lcd_write
			
			LDA #','
			AND #$F0
			ADD #12
			JSR lcd_write 
			
			LDA #','
			NSA
			AND #$F0
			ADD #12
			JSR lcd_write
			
			LDA #'C'
			AND #$F0
			ADD #12
			JSR lcd_write 
			
			LDA #'C'
			NSA
			AND #$F0
			ADD #12
			JSR lcd_write
			
			LDA #':'
			AND #$F0
			ADD #12
			JSR lcd_write 
			
			LDA #':'
			NSA
			AND #$F0
			ADD #12
			JSR lcd_write
		  	
			LDA tempj
			AND #$F0
			ADD #12
			JSR lcd_write 
			LDA tempj
			NSA
			AND #$F0
			ADD #12
			JSR lcd_write
			
			LDA tempi
			AND #$F0
			ADD #12
			JSR lcd_write 
			LDA tempi
			NSA
			AND #$F0
			ADD #12
			JSR lcd_write
			
			LDA #' '
			AND #$F0
			ADD #12
			JSR lcd_write 
			
			LDA #' '
			NSA
			AND #$F0
			ADD #12
			JSR lcd_write
			
			LDA #'T'
			AND #$F0
			ADD #12
			JSR lcd_write 
			
			LDA #'T'
			NSA
			AND #$F0
			ADD #12
			JSR lcd_write
			
			LDA #','
			AND #$F0
			ADD #12
			JSR lcd_write 
			
			LDA #','
			NSA
			AND #$F0
			ADD #12
			JSR lcd_write
			
			LDA #'K'
			AND #$F0
			ADD #12
			JSR lcd_write 
			
			LDA #'K'
			NSA
			AND #$F0
			ADD #12
			JSR lcd_write
			
			LDA #':'
			AND #$F0
			ADD #12
			JSR lcd_write 
			
			LDA #':'
			NSA
			AND #$F0
			ADD #12
			JSR lcd_write
		  	
		  	LDA #'3'
			AND #$F0
			ADD #12
			JSR lcd_write 
			
			LDA #'3'
			NSA
			AND #$F0
			ADD #12
			JSR lcd_write
			
			LDA tempf
			AND #$F0
			ADD #12
			JSR lcd_write 
			LDA tempf
			NSA
			AND #$F0
			ADD #12
			JSR lcd_write
			
			LDA tempe
			AND #$F0
			ADD #12
			JSR lcd_write 
			LDA tempe
			NSA
			AND #$F0
			ADD #12
			JSR lcd_write
			
			JSR mainLoop

calculate_int_temp:
			LDA #0
			STA tempj
			LDA #$FF
			STA PTBDD
			
			LDA #%00011010
		  	STA ADCSC1
		  	JSR delay10
		  	
		  	JSR delay10
		  	LDA ADCRL
		  	STA tempg	
			LDA #54
			CMP tempg         ; Compare to Vtemp25
			BMI high_slope
low_slope:
			; use the low slope
			LDA #16
			STA temph
			; Vtemp - Vtemp25
			LDA tempg
			SUB #54
			STA tempg
			
			LDA #129
			LDX tempg
			MUL
			
			STX highvar
			LDHX highvar
			LDX temph
			DIV
			STA lowvar
			LDA #25
			SUB lowvar
			STA tempi
			JSR calc_int
			
			
			
high_slope:
			; Use the high slope
			LDA #18
			STA temph
			; -(Vtemp25 - Vtemp)
			LDA #54
			SUB tempg
			STA tempg
			
			LDA #129
			LDX tempg
			MUL
			
			STX highvar
			LDHX highvar
			LDX temph
			DIV
			ADD #25
			STA tempi
			JSR calc_int
			
calc_int:
			LDA tempi
			CMP #10
			BPL inc_int
			BRA done_int
inc_int:
			LDA tempj
			INCA
			STA tempj
			LDA tempi
			SUB #10
			STA tempi
			BRA calc_int

done_int:
			JSR writeit	

