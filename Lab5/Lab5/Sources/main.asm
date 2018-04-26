;Main.asm by Johnny Gaddis
;4/5/17
;Lab 5

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
datacheck   RMB 1
data_count  RMB 1
BitCounter  RMB 1
DataCounter RMB 1
temp_data   RMB 1
seconds     RMB 1
minutes     RMB 1
hours       RMB 1
date        RMB 1
month	    RMB 1
year	    RMB 1
input_boolean DS.B 1
read_bit_counter DS.B 1
input_boolean_timer DS.B 1
Data_in_Counter DS.B 1
READ_DATA DS.B 7
data        RMB 24
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
		    JSR data_in
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
			
data_in:
			CBEQX #12, sendI2C
			LDA datacheck
			CBEQA #5, store_data
			RTS	
					
store_data:
			LDA temp_data
			STA data, X
			INCX
			LDA #0
			STA datacheck
			RTS
			
sendI2C:
			LDX #0
			LDA data, X
			NSA
			AND #$F0
			STA seconds
			LDX #1
			LDA data, X
			ADD seconds
			STA seconds
			
			LDX #2
			LDA data, X
			NSA 
			AND #$F0
			STA minutes
			LDX #3 
			LDA data, X
			ADD minutes
			STA minutes
			
			LDX #4
			LDA data, X
			NSA 
			AND #$F0
			STA hours
			LDX #5 
			LDA data, X
			ADD hours
			STA hours
			
			LDX #6
			LDA data, X
			NSA 
			AND #$F0
			STA date
			LDX #7 
			LDA data, X
			ADD date
			STA date
			
			LDX #8
			LDA data, X
			NSA 
			AND #$F0
			STA month
			LDX #9 
			LDA data, X
			ADD month
			STA month
			
			LDX #10
			LDA data, X
			NSA 
			AND #$F0
			STA year
			LDX #11 
			LDA data, X
			ADD year
			STA year
			
Start:
			
			CLR BitCounter
			
			BSET 2, PTADD
			BSET 3, PTADD
			BCLR 2, PTAD
			BCLR 3, PTAD
			


SendAddress:

			JSR Startbit
			
			; 7-bit Slave address is 1101000
			LDA #%11010000
			JSR Transfer
			
			; Send word address to RTC
			LDA #0
			JSR Transfer
			
			LDA #$00
			STA DataCounter
			LDHX #0
			LDX DataCounter
			
SendData:
			LDX DataCounter
			LDA seconds, X
			JSR Transfer

			LDA DataCounter
			CMP #7
			BNE SendData
				
			JSR Stopbit
			JSR LongDelay
			RTS
			
Transfer:

			LDX #$08
			STX BitCounter
			
Nextbit:
			
			ROLA
			BCC SendLow
			
SendHigh:
			BSET 2, PTAD
			JSR ShortDelay
			
setup:
			BSET 3, PTAD
			JSR LongDelay
			BRA Cont
	
SendLow:
			BCLR 2, PTAD
			JSR ShortDelay
			BSET 3, PTAD
			JSR LongDelay				
			
Cont:
			BCLR 3, PTAD
			DEC BitCounter
			BEQ AckPoll
			BRA Nextbit
			
FakeAck:			
			BCLR 2, PTAD
			JSR ShortDelay
            BSET 3, PTAD
            JSR LongDelay
            BRSET 2, PTAD, NoAck
            BCLR 3, PTAD
            RTS
			
			
AckPoll:
			BSET 2, PTAD
			BCLR 2, PTADD
			JSR ShortDelay
			BSET 3, PTAD
			JSR LongDelay
			BRSET 2, PTAD, NoAck
			BCLR 3, PTAD
			BSET 2, PTADD	
			INC DataCounter	
			
			RTS
			
NoAck:
			BCLR 3, PTAD
			BSET 2, PTADD
			RTS
			
Startbit:
			BSET 2, PTADD
			BSET 3, PTADD
			BSET 2, PTAD
			BSET 3, PTAD
			
			BCLR 2, PTAD
			JSR ShortDelay
			BCLR 3, PTAD
			RTS
		

Stopbit:            
           BCLR 2, PTAD
           BSET 3, PTAD
           BSET 2, PTAD
           JSR LongDelay
           RTS 
           
           
ShortDelay:

			NOP
			NOP
			RTS

LongDelay:
			NOP
			NOP
			NOP
			NOP
			NOP
			RTS
			
Read_data:
			LDA input_boolean
			CBEQA #0, read_data_skip
			LDA input_boolean_timer
			CBEQA #1, read_data_skip
			
			BSET 2, PTADD
			BSET 3, PTADD
			BCLR 2, PTAD
			BCLR 3, PTAD
			
			JSR Startbit
			
			; send slave address and word address
			LDA #$D1
			JSR Transfer
			LDA #0
			JSR Transfer
			JSR LongDelay
			
			; repeated start with a read
			BSET 2, PTAD
			BSET 3, PTAD
			JSR Startbit
			LDA #$D1
			JSR Transfer
			
			LDA #0
			STA Data_in_Counter
			
			
Read_byte:
			; Should read 7 bytes and then stop and condition the data
			BCLR 2, PTADD
			LDA Data_in_Counter
			CBEQA #7, condition_read_data
			LDA #0
			STA read_bit_counter
			
; each byte will read in 8 bits and store in the READ_DATA variable
Read_bit:
			LDA read_bit_counter
			CBEQA #8, read_ack
			BCLR 3, PTAD
			JSR ShortDelay
			; rising edge of clock
			BSET 3, PTAD
			
			; put the current byte in the accumulator and shift left
			LDHX #0
			LDX Data_in_Counter
			LDA READ_DATA, X
			ASLA
			
			BRSET 2, PTAD, read_high
			BRA read_cont
			
read_data_skip:
			RTS
			
read_high:
			INCA
			BRA read_cont
			
read_cont:
			LDHX #0
			LDX Data_in_Counter
			STA READ_DATA, X
			INC read_bit_counter
			BCLR 3, PTAD
			BRA Read_bit
			
read_ack:
			; send ack to RTC
			BSET 2, PTADD
			BCLR 2, PTAD
			JSR ShortDelay
			BSET 3, PTAD
			JSR LongDelay
			BCLR 3, PTAD
			BCLR 2, PTADD
			
			INC Data_in_Counter
			BRA Read_byte
			

condition_read_data:
			JSR master_noAck
			BSET 2, PTADD
			; use READ_DATA to output to LCD
			LDA #0
			STA DataCounter
			
			JSR clear_LCD
			; write MM/DD/YY
			
			; --- MONTH ---
			LDHX #0
			LDX #5
			LDA READ_DATA, X
			AND #$F0
			NSA
			ADD #$30
			JSR lcd_write
			
			LDHX #0
			LDX #5
			LDA READ_DATA, X
			AND #$0F
			ADD #$30
			JSR lcd_write
			
			LDA #'/'
			JSR lcd_write
			
			; --- DAY ---
			LDHX #0
			LDX #4
			LDA READ_DATA, X
			AND #$F0
			NSA
			ADD #$30
			JSR lcd_write
			
			LDHX #0
			LDX #4
			LDA READ_DATA, X
			AND #$0F
			ADD #$30
			JSR lcd_write
			
			LDA #'/'
			JSR lcd_write
			
			; --- YEAR ---
			LDHX #0
			LDX #6
			LDA READ_DATA, X
			AND #$F0
			NSA
			ADD #$30
			JSR lcd_write
			
			LDHX #0
			LDX #6
			LDA READ_DATA, X
			AND #$0F
			ADD #$30
			JSR lcd_write
			
						
		
			; write hh:mm:ss
			
			; --- HOURS ---
			LDHX #0
			LDX #2
			LDA READ_DATA, X
			AND #$F0
			NSA
			ADD #$30
			JSR lcd_write
			
			LDHX #0
			LDX #2
			LDA READ_DATA, X
			AND #$0F
			ADD #$30
			JSR lcd_write
			
			LDA #':'
			JSR lcd_write
			
			; --- MINUTES ---
			LDHX #0
			LDX #1
			LDA READ_DATA, X
			AND #$F0
			NSA
			ADD #$30
			JSR lcd_write
			
			LDHX #0
			LDX #1
			LDA READ_DATA, X
			AND #$0F
			ADD #$30
			JSR lcd_write
			
			LDA #':'
			JSR lcd_write
			
			; --- SECONDS ---
			LDHX #0
			LDA READ_DATA, X
			AND #$F0
			NSA
			ADD #$30
			JSR lcd_write
			
			LDHX #0
			LDA READ_DATA, X
			AND #$0F
			ADD #$30
			JSR lcd_write
			
			
			LDA #1
			STA input_boolean_timer
			RTS
			
master_noAck:			
			BSET 3, PTAD
			JSR ShortDelay
			BCLR 3, PTAD
			RTS
			
			;Run characters
runA:
			JSR charA			
			JSR mainLoop
			
runB:
			JSR charB
			JSR mainLoop
			
runC:
			JSR charC
			JSR mainLoop
			
runD:
			JSR charD
			JSR mainLoop
			
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
			
clear_LCD:
			;CLEAR LCD			
			LDA PTAD
			PSHA
			
			BCLR 0, PTAD
			BCLR 1, PTAD
			
			LDA #$0C
			STA PTBD
			BCLR 3, PTBD ; Clock
			BSET 3, PTBD
			
			JSR delay
			
			LDA #$1C
			STA PTBD
			BCLR 3, PTBD ; Clock
			BSET 3, PTBD
			
			JSR delay
			
			PULA
			STA PTAD
			
			JSR delay10
			;JSR LCD_write
			
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

			LDA #0
			STA temp_data
			
			LDA #5
			STA datacheck
			
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

			LDA #1
			STA temp_data
						
			LDA #5
			STA datacheck	
			
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
			
			LDA #2
			STA temp_data
						
			LDA #5
			STA datacheck
			
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
			
			LDA #3
			STA temp_data
						
			LDA #5
			STA datacheck
			
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
			
			LDA #4
			STA temp_data
						
			LDA #5
			STA datacheck
			
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
			
			LDA #5
			STA temp_data
						
			LDA #5
			STA datacheck
			
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
			
			LDA #6
			STA temp_data
						
			LDA #5
			STA datacheck
			
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
			
			LDA #7
			STA temp_data
						
			LDA #5
			STA datacheck
			
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
			
			LDA #8
			STA temp_data
						
			LDA #5
			STA datacheck
			
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
			
			LDA #9
			STA temp_data
						
			LDA #5
			STA datacheck
			
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
			
			
			
