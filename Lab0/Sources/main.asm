;Main.asm by Johnny Gaddis
;1/15/17
;Lab 0

; Include derivative-specific definitions
            INCLUDE 'derivative.inc'
            
; export symbols
            XDEF _Startup, main, interrupt	;       
            XREF __SEG_END_SSTACK   ; symbol defined by the linker for the end of the stack

; variable/data section
RAMSPACE	EQU $0060
ROMSPACE 	EQU $E000
		ORG	RAMSPACE
value 		RMB 1
		ORG ROMSPACE
		
main:
_Startup:
			;Disable watchdog and enable PTB7 as an output(Will be PTA0 eventually)
			LDA #$53
            STA SOPT1
            BSET 0,PTADD
            LDA #$00
            STA PTBDD
            LDA #$FF
            STA PTBD
            BCLR 0,PTAD
            
            ;For part 2 set up a 1 second delay with TPM
			***** PART 2 CODE *****
			*LDHX #$78D1
			*STHX TPMMODH
		  	*LDA #$4F
		  	*STA TPMSC
		  	
		  	;Part 3 Setup
		  	BSET 6, MTIMSC
		  	BCLR 4,MTIMSC
		  	LDA #$0F
		  	STA MTIMCLK
		  	LDA #$FF
		  	STA MTIMMOD
		  	****USING TPM*****
		  	*LDHX #$FFFF
		  	*STHX TPMMODH
		  	*LDA #$48
		  	*STA TPMSC
		  	
		  	;Enable interupts and give value an initial value
		  	LDA #61
 			STA value
		  	CLI		
		  	
		  	;Main loop for doing nothing
mainLoop:
			BSET 3,PTBD
			NOP
			NOP
			NOP	
         	BCLR 3,PTBD
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
 			LDA #$00
 			STA PTBD
 			LDA #61
 			STA value
 			RTI
 			
			
***** PART 1 CODE (Goes in main loop) *****		
*			LDA #$0F
*			STA value 
* 			loop:
* 				LDA #$FF
* 				STA value0
* 				innerLoop:
* 					LDA #$FF
* 					STA value1
* 					innerLoop0:
*      					LDA value1
*      					DECA
*    					STA value1
*	          			BNE innerLoop0  
*      				LDA value0
*      				DECA
*    				STA value0
*	          		BNE innerLoop  
*      			LDA value
*      			DECA
*    			STA value
*	       		BNE loop  				
