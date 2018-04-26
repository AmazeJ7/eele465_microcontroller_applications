;Main.asm by Johnny Gaddis
;4/18/17
;Lab 6

;Include derivative-specific definitions
            INCLUDE 'derivative.inc'
            
;Export symbols
            XDEF _Startup, main, interrupt        
            XREF __SEG_END_SSTACK   ;Symbol defined by the linker for the end of the stack

;Variable/data section
RAMSPACE	EQU $0060
ROMSPACE 	EQU $E000
		ORG	RAMSPACE
count RMB 1
count1 RMB 1
count2 RMB 1
count3 RMB 1
count4 RMB 1
count5 RMB 1
count6 RMB 1
count7 RMB 1
count8 RMB 1
count9 RMB 1
count10 RMB 1
count11 RMB 1
count12 RMB 1
pattern RMB 1
patternCnt RMB 1
patternCnst RMB 1
heartbeat RMB 1
char RMB 1
flag RMB 1
data RMB 7
data1 RMB 2
data3 RMB 12
boolean RMB 1
input_boolean_timer RMB 1
address RMB 1
state RMB 4
result RMB 1
		ORG ROMSPACE
hex DC.B $0, $1, $2, $3, $4, $5, $6, $7, $8, $9, $A, $B, $C, $D, $E, $F
ascii DC.B ".TEC state: "
ascii1 DC.B "T92:"
ascii2 DC.B "K@T="
ascii3 DC.B "Heat"
ascii4 DC.B "Cool"
ascii5 DC.B "Off "
		
main:
_Startup:
			LDHX   #__SEG_END_SSTACK ; initialize the stack pointer
            TXS
			CLI				; enable interrupts
			LDA #$53		; disable watchdog
			STA SOPT1
	
			LDA #$03
			STA PTADD
			
			LDA #$FF
			STA PTBDD
			BCLR 3, PTBD
		
			LDA #60
			STA count
			LDA #$FF
			STA count1

			LDHX #$78D0
			STHX TPMMODH
			LDA #$0F
			STA TPMSC
			LDA #$40
			STA MTIMSC
			LDA #$00
			STA MTIMCLK
			LDA #$FF
			STA MTIMMOD
			
			LDA #$99
			STA heartbeat
			
			LDA #8
			STA PTBD

			LDA #150
			STA count2
			JSR delay
			
			LDA #$00
			STA PTAD	
					
			LDA #$3C
			STA PTBD
			
			BCLR 3, PTBD ; Clock the LCD
			BSET 3, PTBD
			
			LDA #20
			STA count2 ; delay for at least 4.1 ms
			JSR delay
			
			BCLR 3, PTBD ; Clock again
			BSET 3, PTBD
			
			LDA #13
			STA count2
			JSR delay
			
			BCLR 3, PTBD ; Clock
			BSET 3, PTBD
			
			LDA #13
			STA count2
			JSR delay
			
			LDA #$2C	 ; set to 4-bit interface mode
			STA PTBD
			
			BCLR 3, PTBD ; Clock
			BSET 3, PTBD
			
			LDA #13
			STA count2
			JSR delay
			
			BCLR 3, PTBD ; First write
			BSET 3, PTBD
			
			LDA #13
			STA count2
			JSR delay
			
			LDA #$8C	 ; Function set (N and F)
			STA PTBD
			BCLR 3, PTBD ; Clock
			BSET 3, PTBD
			
			LDA #13
			STA count2
			JSR delay
			
			LDA #$0C	 ; First write to turn display on
			STA PTBD
			BCLR 3, PTBD ; Clock
			BSET 3, PTBD
			
			LDA #13
			STA count2
			JSR delay
			
			LDA #$FC	 ; Second write to turn on display with blinking cursor
			STA PTBD
			BCLR 3, PTBD ; Clock
			BSET 3, PTBD
			
			LDA #13
			STA count2
			JSR delay
			
			LDA #$0C
			STA PTBD
			BCLR 3, PTBD ; Clock
			BSET 3, PTBD
			
			LDA #13
			STA count2
			JSR delay
			
			LDA #$1C
			STA PTBD
			BCLR 3, PTBD
			BSET 3, PTBD
			
			LDA #13
			STA count2
			JSR delay
			
			LDA #$0C
			STA PTBD
			BCLR 3, PTBD ; Clock
			BSET 3, PTBD
			
			LDA #13
			STA count2
			JSR delay
			
			LDA #$6C	 ; Set cursor and shift display settings
			STA PTBD
			BCLR 3, PTBD ; Clock
			BSET 3, PTBD
			
			LDA #13
			STA count2
			JSR delay
			
			; --- SET DDRAM ADDRESS TO '00'
			LDA #$8C
			STA PTBD
			BCLR 3, PTBD ; Clock
			BSET 3, PTBD
			
			LDA #13
			STA count2
			JSR delay
			
			LDA #$0C
			STA PTBD
			BCLR 3, PTBD ; Clock
			BSET 3, PTBD
			
			LDA #53
			STA count2
			JSR delay
			
			LDA #$FF
			STA flag
			
			LDA #$00
			STA count4
			
			LDA #$00
			STA count3
			STA boolean
	
			LDA #$00
			STA count8
			STA count6		

mainLoop:
            NOP
            NOP
            NOP
            JSR LED_write         
			JSR keypad
			JSR Temp_control_output
            
            BRA mainLoop
            

delay:
			NOP
			NOP
			NOP
			NOP
			NOP
			LDA count2
			DECA
			STA count2
			BNE delay
			RTS
			
Read_data:
			JSR Startbit
			JSR LongDelay
			
			; send slave address and word address
			LDA address
			JSR Transfer
			LDA #0
			JSR Transfer
			JSR LongDelay
LM92_read_start:
			JSR Startbit
			LDA address
			INCA
			JSR Transfer
			
			LDA #0
			STA count9
			
			
Read_byte:
			; Should read 7 bytes and then stop and condition the data
			BCLR 2, PTADD
			LDA #0
			STA count10
			
; each byte will read in 8 bits and store in the data1 variable
Read_bit:
			LDA count10
			CBEQA #8, read_ack_check
			BCLR 3, PTAD
			JSR ShortDelay
			; rising edge of clock
			BSET 3, PTAD
			
			; put the current byte in the accumulator and shift left
			LDHX #$0000
			LDX count9
			LDA data1, X
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
			LDX count9
			STA data1, X
			INC count10
			BCLR 3, PTAD
			BRA Read_bit
			
read_ack_check:
			LDA count9
			CBEQA #1, condition_read_data
			
read_ack:
			; send ack to RTC
			BSET 2, PTADD
			BCLR 2, PTAD
			JSR ShortDelay
			BSET 3, PTAD
			JSR LongDelay
			BCLR 3, PTAD
			BCLR 2, PTADD
			
			INC count9
			BRA Read_byte
			
convert_to_decimal:
			LDA result
			AND #$7F
			SUB #10
			;CMP #10
			BMI write_decimal
			;BRA write_decimal
			
increment_tens:
			INC count12
			STA result
			BRA convert_to_decimal
			;LDA count12
			;LDA result
			;SUB #10
			;STA result
			;BRA convert_to_decimal
						
write_decimal:
			; convert dec to ascii			
			LDA count12
			AND #$0F
			ADD #$30
			STA char
			JSR clear_skip
			
			LDA result
			AND #$0F
			ADD #$30
			STA char
			JSR clear_skip
			
			LDA #$00
			;STA result
			STA count12	
			;JSR set_to_second_line
			;JSR bottom_line_write				
			RTS
			

condition_read_data:
			JSR master_noAck
			JSR LongDelay
			JSR Stopbit
			JSR ShortDelay
			BSET 2, PTADD
			; use data1 to output to LCD
			LDA address
			CBEQA #$D0, condition_timer
			LDA #0
			STA count8
			LDA data1
			LSLA
			STA data1
			LDHX #0001
			LDA data1, X
			LSLA
			BCC dont_add
			LDA data1
			ADD #1
			STA data1
dont_add:
			LDA data1
			STA result
			JSR convert_to_decimal
			RTS
condition_timer:
			; --- MINUTES ---
			LDHX #0
			LDX #1
			LDA data1, X
			AND #$F0
			NSA
			ADD #$30
			STA char
			JSR clear_skip
			
			LDHX #0
			LDX #1
			LDA data1, X
			AND #$0F
			ADD #$30
			STA char
			JSR clear_skip
			
			LDA #':'
			STA char
			JSR clear_skip
			
			; --- SECONDS ---
			LDHX #0
			LDA data1, X
			AND #$F0
			NSA
			ADD #$30
			STA char
			JSR clear_skip
			
			LDHX #0
			LDA data1, X
			AND #$0F
			ADD #$30
			STA char
			JSR clear_skip
			
			RTS
			
master_noAck:			
			BSET 3, PTAD
			JSR ShortDelay
			BCLR 3, PTAD
			RTS
			
			
			
			
data_in_check:
			LDA boolean
			CBEQA #1, data_condition_skip
			LDA count8
			CMP #12
			BNE data_condition_skip
			LDA #1
			STA boolean
			LDA #0
			STA count8
			STA count6
			
data_condition:
			; Load data comes from I2C
			; Store data goes to data
			; count8 is the offset for I2C
			; count6 is the offset for data
			
			LDA count6
			CBEQA #3, Load_Day
			
			LDHX #0
			LDX count8
			LDA data3, X
			NSA
			AND #$F0
			LDX count6
			STA data, X
			
			INC count8
			LDX count8
			
			LDA data3, X
			LDX count6
			
			ADD data, X
			STA data, X
			
			INC count6
			INC count8
			
			LDA count6
			CBEQA #7, data_condition_stop
			BRA data_condition
			
Load_Day:
			LDHX #0
			LDX count6
			LDA #0
			STA data, X
			INC count6
			BRA data_condition
			
data_condition_stop:
			LDA #0
			STA count8
			STA count6
			
			; Transmit the data to the RTC
			JSR Start
			
			LDA #0
			STA count8
			STA count6
			
data_condition_skip:
			RTS

			     
Temp_control_output:
			LDA flag
			CBEQA #$00, end_write_state
			JSR clear_LCD
			JSR write_TEC_msg
			JSR set_state_message
			JSR set_to_second_line
			JSR write_T92_msg
			LDA #' '
			STA char
			JSR clear_skip
			LDA #$00
			STA data1
			LDA #$90
			STA address
			JSR Read_data
			JSR write_KatT_msg
			LDA #$00
			STA data1
			LDA #$D0
			STA address
			JSR Read_data
			LDA #$00
			STA flag
			RTS
			
set_state_message:		
			LDHX #$0000	
			LDA patternCnt
			CBEQA #$0, set_off_state
			CBEQA #$1, set_heat_state
			
set_cool_state:
			LDA ascii4, X
			STA state, X
			INCX
			CBEQX #$4, write_state
			BRA set_cool_state
			
set_heat_state:
			LDA ascii3, X
			STA state, X
			INCX
			CBEQX #$4, write_state
			BRA set_heat_state

set_off_state:
			LDA ascii5, X
			STA state, X
			INCX
			CBEQX #$4, write_state
			BRA set_off_state

write_state:
			LDHX #$0000
			STX count11
write_state_internal:
			LDHX #$0000
			LDX count11
			LDA state, X
			STA char
			JSR clear_skip
			INC count11
			LDA count11
 			CBEQA #$4, end_write_state
			BRA write_state_internal
			
end_write_state:
			RTS
			
Clear_timer:
			JSR Stopbit
			JSR ShortDelay
			JSR Startbit
			JSR ShortDelay
			LDA #$D0
			JSR Transfer
			LDA #$00
			JSR Transfer
			LDA #$00
			JSR Transfer
			LDA #$00
			JSR Transfer
			JSR ShortDelay
			JSR Stopbit
			
			            
LED_write:
			; ; ---
			LDHX #$0000
			LDX patternCnt
			
			LDA #$08			; select first device
            STA PTBD
            
            BCLR 3, PTBD		; lower clock on first 273
            LDA hex,X			; indexed addressing from the start of variables to the current pattern
            NSA
            AND #$F0      		; set multiplexer enable low / select "000" to be low
            STA PTBD
            
            BSET 3, PTBD		; Generate rising edge for clock
            
            ; select second 273 '001'
            BCLR 2, PTBD
            BCLR 1, PTBD
            BSET 0, PTBD
            
            BCLR 3, PTBD		; lower clock on second 273
            LDA heartbeat		; load heartbeat for lower 4 bits
            
            AND #$F0
            ADD #1
            STA PTBD
            BSET 3, PTBD
            
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
			
			LDA #13
			STA count2
			JSR delay
			
			LDA #$1C
			STA PTBD
			BCLR 3, PTBD ; Clock
			BSET 3, PTBD
			
			LDA #13
			STA count2
			JSR delay
			
			; reset count3
			LDA #$00
			STA count3
			
			PULA
			STA PTAD
			
			LDA #200
			STA count2
			JSR delay
			;JSR LCD_write
			
			RTS
            
LCD_write:

			LDA TPMSC
			AND #$80
			CMP #$80
			BNE skip
			
			INC count3
			LDA count3
			CMP #$11
			BNE clear_skip
			JSR clear_LCD
			
clear_skip:

			BSET 1, PTAD
			LDA char
			AND #$F0
			ADD #$0C
			STA PTBD
			BCLR 3, PTBD
			BSET 3, PTBD
			
			LDA #13
			STA count2
			JSR delay
			
			LDA char
			NSA
			AND #$F0
			ADD #$0C
			STA PTBD
			BCLR 3, PTBD
			BSET 3, PTBD
			
			LDA #255
			STA count2
			JSR delay
			
			BCLR 1, PTAD
 			JSR counter_reset
skip:			
			RTS
            
keypad:
			LDA #$FF
			STA PTBDD
			
; --- Check for Row 1 buttons pressed
			LDA #$E8
			STA PTBD
			
			JSR clk_n_read	; writes to 273, and reads from 245
			
			ADD #$0E
			CMP #$7E
			BNE skip_A
			JSR run_A
			RTS
skip_A:
			CMP #$BE
			BNE skip_3
			JSR run_3
			RTS
skip_3:
			CMP #$DE
			BNE skip_2
			JSR run_2
			RTS
skip_2:
			CMP #$EE
			BNE skip_1
			JSR run_1
			RTS
skip_1:
			
			
			LDA #$FF		; reset PTBD to outputs
			STA PTBDD
			
; --- Check for Row 2 buttons pressed
			LDA #$D8
			STA PTBD
			
			JSR clk_n_read
			
			ADD #$0D
			CMP #$7D
			BNE skip_B
			JSR run_B
			RTS
skip_B:
			CMP #$BD
			BNE skip_6
			JSR run_6
			RTS
skip_6:
			CMP #$DD
			BNE skip_5
			JSR run_5
			RTS
skip_5:
			CMP #$ED
			BNE skip_4
			JSR run_4
			RTS
skip_4:
			
			LDA #$FF		; reset PTBD to outputs
			STA PTBDD
			
; --- Check for Row 3 buttons pressed
			LDA #$B8
			STA PTBD
			
			JSR clk_n_read
			
			ADD #$0B
			CMP #$7B
			BNE skip_C
			JSR run_C
			RTS
skip_C:
			CMP #$BB
			BNE skip_9
			JSR run_9
			RTS
skip_9:
			CMP #$DB
			BNE skip_8
			JSR run_8
			RTS
skip_8:
			CMP #$EB
			BNE skip_7
			JSR run_7
			RTS
skip_7:
			
			LDA #$FF		; reset PTBD to outputs
			STA PTBDD
			
; --- Check for Row 4 buttons pressed
			LDA #$78
			STA PTBD
			
			JSR clk_n_read
			
			ADD #$07
			CMP #$77
			BNE skip_D
			JSR run_D
			RTS
skip_D:
			CMP #$B7
			BNE skip_pound
			JSR run_pound
			RTS
skip_pound:
			CMP #$D7
			BNE skip_0
			JSR run_0
			RTS
skip_0:
			CMP #$E7
			BNE skip_star
			JSR run_star
			RTS
skip_star:
			
			LDA #$FF		; reset PTBD to outputs
			STA PTBDD
			
			RTS

			

; --- run_X sets the pattern variables for pattern X ; ---
; --- used when writing to the LED ; ---
; --- FIRST ROW ---
run_A:
			LDA #$A
			;STA patternCnt
			LDA #'A'
			STA char	
			JSR LCD_write		
			LDA #$00
			STA flag
			;LDA #128
			;STA CNT
			;JSR calculate_int_temp
			RTS
run_3:
			LDHX #$0000
			LDX count8
			LDA #$3
			STA data3, X
			;STA patternCnt
			LDA #'3'
			STA char	
			JSR LCD_write		
			LDA #$00
			STA flag
			RTS
run_2:
			;LDHX #$0000
			;LDX count8
			LDA #$2
			;STA data3, X
			STA patternCnt
			;LDA #'2'
			;STA char
			;JSR Temp_control_output			
			;JSR LCD_write
			JSR Clear_timer
			LDA #$00
			STA flag			
			RTS
run_1:		
			;LDHX #$0000
			;LDX count8
			LDA #$1
			;STA data3, X
			STA patternCnt
			;LDA #'1'
			;STA char
			;JSR Temp_control_output	
			;JSR LCD_write
			JSR Clear_timer		
			LDA #$00
			STA flag		
			RTS

		
; --- SECOND ROW ---	
run_B:
			LDA #$B
			;STA patternCnt
			LDA #'B'
			STA char	
			JSR LCD_write			
			LDA #$00
			STA flag
			RTS
			
run_6:
			LDHX #$0000
			LDX count8
			LDA #$6
			STA data3, X
			;STA patternCnt
			LDA #'6'
			STA char	
			JSR LCD_write		
			LDA #$00
			STA flag
			RTS
run_5:
			LDHX #$0000
			LDX count8
			LDA #$5
			STA data3, X
			;STA patternCnt
			LDA #'5'
			STA char	
			JSR LCD_write		
			LDA #$00
			STA flag
			RTS
run_4:
			LDHX #$0000
			LDX count8
			LDA #$4
			STA data3, X
			;STA patternCnt
			LDA #'4'
			STA char	
			JSR LCD_write		
			LDA #$00
			STA flag
			RTS
			
		
; --- THIRD ROW ---
run_C:
			LDA #$C
			;STA patternCnt
			LDA #'C'
			STA char	
			JSR LCD_write			
			LDA #$00
			STA flag
			RTS
			
run_9:
			LDHX #$0000
			LDX count8
			LDA #$9
			STA data3, X
			;STA patternCnt
			LDA #'9'
			STA char	
			JSR LCD_write			
			LDA #$00
			STA flag
			RTS
run_8:
			LDHX #$0000
			LDX count8
			LDA #$8
			STA data3, X
			;STA patternCnt
			LDA #'8'
			STA char	
			JSR LCD_write			
			LDA #$00
			STA flag
			RTS
			
run_7:
			LDHX #$0000
			LDX count8
			LDA #$7
			STA data3, X
			;STA patternCnt
			LDA #'7'
			STA char	
			JSR LCD_write		
			LDA #$00
			STA flag
			RTS

; --- FOURTH ROW ---
run_D:
			LDA #$D
			;STA patternCnt
			LDA #'D'
			STA char	
			JSR LCD_write		
			LDA #$00
			STA flag
			RTS
			
run_pound:
			;LDA #$F
			;STA patternCnt
			;LDA #'F'
			;STA char
			;JSR LCD_write		
			LDA #$00
			STA flag
			RTS
run_0:
			;LDHX #$0000
			;LDX count8
			LDA #$0
			;STA data3, X
			STA patternCnt
			;LDA #'0'
			;STA char
			JSR Clear_timer
			;JSR Temp_control_output	
			;JSR LCD_write			
			LDA #$00
			STA flag
			RTS
; Read data from LCD and store
run_star:
			JSR clear_LCD
			LDA #$00
			STA count4
			STA count8
			;JSR write_enter_msg
			RTS
			
counter_reset:
			LDHX #$78D0
			STHX TPMMODH
			
			LDA #$00
			STA TPMCNTH	
			
			INC count8		
			
			LDA TPMSC
			BCLR 7, TPMSC
			RTS			

			
clk_n_read:
; --- clock the 273 with the correct value on the data bus
			BSET 3, PTBD
			NOP
			
			LDA PTBD		; load value on PTBD that contains the value to be written to keypad
			AND #$F8		; mask the value so the clock portion is clear
			
			BSET 3, PTBD	; redundant sets to ensure clock is kept disabled
			STA PTBD
			BSET 3, PTBD
			
			; Set the device to be clocked
			; select device '010' (273 Dflipflop)
			BCLR 2, PTBD
			BSET 1, PTBD
			BCLR 0, PTBD

			; lower clock on selected device
			BCLR 3, PTBD
			NOP
			
			BSET 3, PTBD	; generate rising clock edge for the 273
			NOP
			
; --- change data direction to read from the 245
			LDA #$0F
			STA PTBDD

			BSET 3, PTBD 	; keep clock high
			
; --- clock the 245 to transfer data from B to A
			; select device '011' (245 Tranceiver)
			BCLR 2, PTBD
			BSET 1, PTBD
			BSET 0, PTBD		
			
			; lower enable line on 245
			; level sensitive makes values change	
			BCLR 3, PTBD		
			NOP	
			
			LDA PTBD		; hold the value given by the 245			
			
			BSET 3, PTBD	; set the multiplexer enable high again
			AND #$F0		; only keep upper 4 bits (data bus)
			
			; reset data direction to output
			LDX #$FF
			STX PTBDD
			
			RTS		
			
			
write_TEC_msg:
			LDHX #$00
			LDX count4
			
			LDA ascii, X
			STA char
			JSR clear_skip
			
			LDA count4
			INCA
			STA count4
			CMP #12
			BNE write_TEC_msg
			
			;JSR set_to_second_line
			LDA #0
			STA count4
			RTS	
			
write_T92_msg:
			LDHX #$00
			LDX count4
			
			LDA ascii1, X
			STA char
			JSR clear_skip
			
			LDA count4
			INCA
			STA count4
			CMP #4
			BNE write_T92_msg
			MOV #0, count4
			
			RTS	
			
write_KatT_msg:
			LDHX #$00
			LDX count4
			
			LDA ascii2, X
			STA char
			JSR clear_skip
			
			LDA count4
			INCA
			STA count4
			CMP #4
			BNE write_KatT_msg
			
			MOV #0, count4
			RTS	
			
set_to_second_line:
			LDA PTAD
			PSHA
			
			BCLR 0, PTAD
			BCLR 1, PTAD
			
			LDA #$CC
			STA PTBD
			BCLR 3, PTBD ; Clock
			BSET 3, PTBD
			
			LDA #13
			STA count2
			JSR delay
			
			LDA #$0C
			STA PTBD
			BCLR 3, PTBD ; Clock
			BSET 3, PTBD
			
			LDA #13
			STA count2
			JSR delay
			
			PULA
			STA PTAD
			RTS
   
         
; inner loop of the interrupt count 
inner_loop:			
			LDA count1
			DECA
			STA count1
			BEQ loop
            BRA return

; Reusable toggle for all three parts, slightly modified for each
toggle_LED:
			; Performs heartbeat toggle
			
			LDA heartbeat
			EOR #$F0
			;ADD #$11
			STA heartbeat
			
			; count used for heartbeat LED
			LDA #60
			STA count
			LDA #$FF
			STA count1
			LDA #$FF
			STA flag
			
			; Toggle input boolean timer
			LDA #0
			STA input_boolean_timer
			
			
			BRA return
			
; timer interrupt for heartbeat and LED patterns
interrupt:
			; ; --- PUSH DATA DIRECTION ONTO STACK ; ---
			LDA PTBDD
			PSHA
			LDA PTADD
			PSHA
			
			
			; set data direction line
			LDA #$FF
			STA PTBDD
			
			BRA inner_loop
			

			
; outer loop for heartbeat count
loop:
			LDA count			; Check the count
			DECA
			STA count
			BEQ toggle_LED


; Toggle comes back here to return from interrupt
return:			
			; pull data direction off of the stack
			PULA
			STA PTADD
			PULA
			STA PTBDD
			
			LDA MTIMSC
			BCLR 7, MTIMSC		; Clear the interrupt flag
			
			RTI
			
; --- I2C Starts here ---
;-- Clock is 3
;-- Data is 2
Start:
			
			CLR count7
			
			BSET 2, PTADD
			BSET 3, PTADD
			BCLR 2, PTAD
			BCLR 3, PTAD
			


SendAddress:

			JSR Startbit
			
			; 7-bit Slave address is 1101000
			LDA #$90
			JSR Transfer
			
			; Send word address to RTC
			LDA #0
			JSR Transfer
			
			LDA #$00
			STA count8
			LDHX #0
			LDX count8
			
SendData:
			LDX count8
			LDA data, X
			JSR Transfer

			LDA count8
			CMP #7
			BNE SendData
				
			JSR Stopbit
			JSR LongDelay
			RTS
			
Transfer:

			LDX #$08
			STX count7
			
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
			DEC count7
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
			INC count8	
			
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
			BSET 2, PTADD
			BCLR 3, PTAD 
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

