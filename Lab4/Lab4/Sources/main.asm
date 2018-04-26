; Include derivative-specific definitions
            INCLUDE 'derivative.inc'
            

; export symbols
            XDEF _Startup, main, receiveData, transmitData
            ; we export both '_Startup' and 'main' as symbols. Either can
            ; be referenced in the linker .prm file or from C/C++ later on
            
            
            
            XREF __SEG_END_SSTACK   ; symbol defined by the linker for the end of the stack

;Variable/data section
RAMSPACE	EQU $0060
ROMSPACE 	EQU $E000
		ORG	RAMSPACE
data        RMB 18

		ORG ROMSPACE
lm19val     	DC.B $07, $48

main:
_Startup:
            LDA #$53
            STA SOPT1
            
            LDA #$00
            STA SCIBDH
            LDA #26
            STA SCIBDL
            LDA #0
            STA SCIC1
            LDA #%00101100
            STA SCIC2
            LDA #%00000000
            STA SCIC3
            LDX #0 
            
			CLI			; enable interrupts

mainLoop:
            NOP
  
            BRA    mainLoop

receiveData:
			LDA SCID
			CBEQA #%11111111, transmitData
			STA data, X
			INCX
			BRA mainLoop
			
transmitData:
			LDX #0
			LDA data, X
			STA SCID
			NOP
			INCX
			CBEQX #17, mainLoop
			BRA transmitData
