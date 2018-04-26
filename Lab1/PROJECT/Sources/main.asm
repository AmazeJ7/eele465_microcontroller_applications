;Main.asm by Johnny Gaddis
;1/22/17
;Lab 1

;Include derivative-specific definitions
            INCLUDE 'derivative.inc'
            
;Export symbols
            XDEF _Startup, main, interrupt        
            XREF __SEG_END_SSTACK   ;Symbol defined by the linker for the end of the stack

;Variable/data section
RAMSPACE	EQU $0060
ROMSPACE 	EQU $E000
		ORG	RAMSPACE
value 		RMB 1
runBcount   RMB 1
runCcount   RMB 1
runDcount   RMB 1
ledVal1     RMB 1
ledVal2     RMB 1
		ORG ROMSPACE
	;All LED states for B, C, and D
runDv       DC.B %00111100, %00000000, %00011110, %00000000, %00001111, %00000000, %00000111, %00000000, %00000011, %00000000, %00000001, %00000000, %00000011, %00000000, %00000111, %00000000, %00001111, %00000000, %00011110, %00000000, %00111100, %00000000
runBv       DC.B %01111111, %00000000, %10111111, %00000000, %11011111, %00000000, %11101111, %00000000, %11110111, %00000000, %11111011, %00000000, %11111101, %00000000, %11111110, %00000000
runCv       DC.B %00011000, %00000000, %00100100, %00000000, %01000010, %00000000, %10000001, %00000000, %01000010, %00000000, %00100100, %00000000, %00011000, %00000000

		
main:
_Startup:
			;Disable watchdog & enable reset
			LDA #$53
            STA SOPT1
           
            ;Initialize port B and keyboard
            LDA #$FF
            STA PTBDD
            LDA #$FF
            STA PTBD
            LDA #%10101000
            STA ledVal1
            LDA #%10101001
            STA ledVal2
    		LDA #$00
    		STA runBcount
    		STA runCcount
    		STA runDcount
    		
		  	;Heartbeat Setup
		  	BSET 0,PTADD
            BCLR 0,PTAD
		  	BSET 6, MTIMSC
		  	BCLR 4,MTIMSC
		  	LDA #$0F
		  	STA MTIMCLK
		  	LDA #$FF
		  	STA MTIMMOD
		  	LDA #61
 			STA value
		  	CLI		
		  	
		  	;Main loop for doing nothing
mainLoop:			
			NOP
			NOP
			NOP	
			JSR runA
			
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
			LDA #$01
            EOR PTAD
 			STA PTAD
 			
 			LDA runBcount 
 			INCA
 			STA runBcount
 			
 			LDA runCcount 
 			INCA
 			STA runCcount
 			
 			LDA runDcount 
 			INCA
 			STA runDcount
 	 			
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
			
			RTS
			
			;Run LED pattern A	
runA:
			LDA #%10101000
			STA ledVal1
			LDA #%10101001
			STA ledVal2
    
    		JSR poll
			JSR led
			
			BRA runA
			
			;Run LED pattern B		
runB:
			LDA #$00
    		STA runBcount
rB:
			LDX runBcount
			LDA runBv, X
			STA ledVal1
			BCLR 0,ledVal1
			BCLR 1,ledVal1
			BCLR 2,ledVal1
				
			LDX runBcount
			LDA runBv, X
			NSA
			STA ledVal2
			BSET 0,ledVal2
			BCLR 1,ledVal2
			BCLR 2,ledVal2
			
			JSR poll
			JSR led
			
			LDA runBcount 
			CBEQA #%00010000, runB
			BRA rB

			;Run LED pattern C				
runC:
			LDA #$00
    		STA runCcount
rC:
			LDX runCcount
			LDA runCv, X
			STA ledVal1
			BCLR 0,ledVal1
			BCLR 1,ledVal1
			BCLR 2,ledVal1
				
			LDX runCcount
			LDA runCv, X
			NSA
			STA ledVal2
			BSET 0,ledVal2
			BCLR 1,ledVal2
			BCLR 2,ledVal2
			
			JSR poll
			JSR led
			
			LDA runCcount 
			CBEQA #%00001110, runC
			BRA rC
			
									
			;Run LED pattern D	
runD:
			LDA #$00
    		STA runDcount
rD:
			LDX runDcount
			LDA runDv, X
			STA ledVal1
			BCLR 0,ledVal1
			BCLR 1,ledVal1
			BCLR 2,ledVal1
				
			LDX runDcount
			LDA runDv, X
			NSA
			STA ledVal2
			BSET 0,ledVal2
			BCLR 1,ledVal2
			BCLR 2,ledVal2
			
			JSR poll
			JSR led
			
			LDA runDcount 
			CBEQA #%00010110, runD
			BRA rD
			
