;Main.asm by Johnny Gaddis
;2/14/17
;Lab 2

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
count0      RMB 1
count1      RMB 1
ledVal1     RMB 1
ledVal2     RMB 1
		ORG ROMSPACE
		
main:
_Startup:
			;Disable watchdog & enable reset
			LDA #$53
            STA SOPT1
           
            ;Initialize port B and keyboard
            LDA #$FF
            STA PTBDD
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
			JSR charA			
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
			JSR char3
			JSR mainLoop
			
run6:
			JSR char6
			JSR mainLoop
			
run9:
			JSR char9
			JSR mainLoop
			
runHash:
			JSR charF
			JSR mainLoop
			
run1:
			JSR char1
			JSR mainLoop
			
run4:
 			JSR char4
			JSR mainLoop
			
run7:
			JSR char7
			JSR mainLoop
			
runStar:
			JSR charE
			JSR mainLoop
				
run2:
			JSR char2			
			JSR mainLoop
			
run5:
			JSR char5
			JSR mainLoop
			
run8:
			JSR char8
			JSR mainLoop
			
run0:
			JSR char0
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
			
			;Write LCD value for characters
lcd_write_char:
			BCLR 0, PTAD	
			BSET 0, PTAD
			
			STA PTBD
			
			BCLR 3,PTBD
			BSET 3,PTBD
			
			JSR delay 
			JSR delay  
			JSR delay 
			JSR delay
			
			LDA count1
			DECA
			STA count1
			BEQ count1reset
		
			RTS		
			
			;Reset the counter and clear the LCD	
count1reset:
			LDA #$20
			STA count1
			
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
			
			;10 Delay Subroutines
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
			JSR lcd_write_char 
			LDA #%00001100
			JSR lcd_write_char

			LDA #%00001001
    		STA ledVal2

			RTS
			
char1:
			LDA #$FF
			STA PTBDD
			LDA #%00111100
			JSR lcd_write_char 
			LDA #%00011100
			JSR lcd_write_char

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
			JSR lcd_write_char 
			LDA #%00111100
			JSR lcd_write_char
			
    		LDA #%00111001
    		STA ledVal2

			RTS
			
char4:
			LDA #$FF
			STA PTBDD
			LDA #%00111100
			JSR lcd_write_char 
			LDA #%01001100
			JSR lcd_write_char
			
   			LDA #%01001001
    		STA ledVal2

			RTS
			
char5:
			LDA #$FF
			STA PTBDD
			LDA #%00111100
			JSR lcd_write_char 
			LDA #%01011100
			JSR lcd_write_char
			
			LDA #%01011001
    		STA ledVal2

			RTS
			
			
char6:
			LDA #$FF
			STA PTBDD
			LDA #%00111100
			JSR lcd_write_char 
			LDA #%01101100
			JSR lcd_write_char
			
			LDA #%01101001
    		STA ledVal2

			RTS
			
char7:
			LDA #$FF
			STA PTBDD
			LDA #%00111100
			JSR lcd_write_char 
			LDA #%01111100
			JSR lcd_write_char
			
    		LDA #%01111001
    		STA ledVal2
  
			RTS
			
char8:
			LDA #$FF
			STA PTBDD
			LDA #%00111100
			JSR lcd_write_char 
			LDA #%10001100
			JSR lcd_write_char
			
			LDA #%10001001
    		STA ledVal2

			RTS
			
char9:
			LDA #$FF
			STA PTBDD
			LDA #%00111100
			JSR lcd_write_char
			LDA #%10011100
			JSR lcd_write_char
			
			LDA #%10011001
    		STA ledVal2

			RTS
			
charA:
			LDA #$FF
			STA PTBDD
			LDA #%01001100
			JSR lcd_write_char
			LDA #%00011100
			JSR lcd_write_char
			
			LDA #%10101001
    		STA ledVal2

			RTS
			
charB:
			LDA #$FF
			STA PTBDD
			LDA #%01001100
			JSR lcd_write_char 
			LDA #%00101100
			JSR lcd_write_char
			
    		LDA #%10111001
    		STA ledVal2
    		
    		JSR poll
			JSR led
			
			RTS
			
charC:		
			LDA #$FF
			STA PTBDD
			LDA #%01001100
			JSR lcd_write_char 
			LDA #%00111100
			JSR lcd_write_char
			
    		LDA #%11001001
    		STA ledVal2
			
			RTS
			
charD:
			LDA #$FF
			STA PTBDD
			LDA #%01001100
			JSR lcd_write_char 
			LDA #%01001100
			JSR lcd_write_char
			
    		LDA #%11011001
    		STA ledVal2

			RTS
			
charE:
			LDA #$FF
			STA PTBDD
			LDA #%01001100
			JSR lcd_write_char 
			LDA #%01011100
			JSR lcd_write_char
			
    		LDA #%11101001
    		STA ledVal2

			RTS
			
charF:
			LDA #$FF
			STA PTBDD
			LDA #%01001100
			JSR lcd_write_char 
			LDA #%01101100
			JSR lcd_write_char
			
    		LDA #%11111001
    		STA ledVal2
			
			RTS
			
			
			
