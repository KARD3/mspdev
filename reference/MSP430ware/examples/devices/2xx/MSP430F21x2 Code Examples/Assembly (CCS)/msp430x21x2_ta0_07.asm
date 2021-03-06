;******************************************************************************
;  MSP430F21x2 Demo - Timer0_A3, Toggle P1.0-3, Cont. Mode ISR, DCO SMCLK
;
;  Description: Use Timer0_A3 CCRx units and overflow to generate four
;  independent timing intervals. For demonstration, TA0CCR0, TA0CCR1 and TA0CCR2
;  output units are optionally selected with port pins P1.1, P1.2 and P1.3
;  in toggle mode. As such, these pins will toggle when respective TA0CCRx
;  registers match the TA0R counter. Interrupts are also enabled with all
;  TA0CCRx units, software loads offset to next interval only - as long as
;  the interval offset is added to TACCRx, toggle rate is generated in
;  hardware. Timer0_A1 overflow ISR is used to toggle P1.0 with software.
;  Proper use of the TA0IV interrupt vector generator is demonstrated.
;  ACLK = n/a, MCLK = SMCLK = TA0CLK = default DCO ~1.2MHz
;
;  As coded with TACLK ~1.2MHz DCO, toggle rates are:
;  P1.1 = TA0CCR0 = 1.2MHz/(2*200) ~3000Hz
;  P1.2 = TACCR1 = 1.2MHz/(2*1000) ~600Hz
;  P1.3 = TACCR2 = 1.2MHz/(2*10000) ~60Hz
;  P1.0 = overflow = 1.2MHz/(2*65536) ~9Hz
;
;              MSP430F21x2
;            -----------------
;        /|\|              XIN|-
;         | |                 |
;         --|RST          XOUT|-
;           |                 |
;           |         P1.1/TA0|--> TA0CCR0
;           |         P1.2/TA1|--> TACCR1
;           |         P1.3/TA2|--> TACCR2
;           |             P1.0|--> Overflow/software
;
;  JL Bile
;  Texas Instruments Inc.
;  May 2008
;  Built with Code Composer Essentials: v3 FET
;*******************************************************************************
 .cdecls C,LIST, "msp430x21x2.h"
;-------------------------------------------------------------------------------
 			.text							; Program Start
;-------------------------------------------------------------------------------
RESET       mov.w   #025Fh,SP         ; Initialize stackpointer
StopWDT     mov.w   #WDTPW+WDTHOLD,&WDTCTL  ; Stop WDT
SetupP1     bis.b   #00Eh,&P1SEL            ; P1.1 - P1.3 option select
            bis.b   #00Fh,&P1DIR            ; P1.0-3 outputs
SetupC0     mov.w   #OUTMOD_4+CCIE,&TA0CCTL0 ; TACCR0 toggle, interrupt enabled
SetupC1     mov.w   #OUTMOD_4+CCIE,&TA0CCTL1 ; TACCR1 toggle, interrupt enabled
SetupC2     mov.w   #OUTMOD_4+CCIE,&TA0CCTL2 ; TACCR2 toggle, interrupt enabled
SetupTA     mov.w   #TASSEL_2+MC_2+TAIE,&TA0CTL   ; SMCLK, contmode, interrupt
                                            ;
Mainloop    bis.w   #CPUOFF+GIE,SR          ; CPU off, interrupts enabled
            nop                             ; Required for debugger
                                            ;
;-------------------------------------------------------------------------------
TA0_ISR;
;-------------------------------------------------------------------------------
            add.w   #200,&TA0CCR0            ; Offset until next interrupt
            reti                            ;
                                            ;
;-------------------------------------------------------------------------------
TAX_ISR;    Common ISR for TACCR1-2 and overflow
;-------------------------------------------------------------------------------
            add.w   &TAIV,PC                ; Add Timer_A offset vector
            reti                            ;
            jmp     TA0CCR1_ISR              ; TACCR1
            jmp     TA0CCR2_ISR              ; TACCR2
            reti                            ;
            reti                            ;
TA_over     xor.b   #001h,&P1OUT            ; Toggle P1.0
            reti                            ; Return from overflow ISR
                                            ;
TA0CCR1_ISR  add.w   #1000,&TACCR1           ; Offset until next interrupt
            reti                            ; Return ISR
                                            ;
TA0CCR2_ISR  add.w   #10000,&TACCR2          ; Offset until next interrupt
            reti                            ; Return ISR
                                            ;
;-------------------------------------------------------------------------------
;			Interrupt Vectors
;-------------------------------------------------------------------------------
            .sect	".reset"				; MSP430 RESET Vector
            .short	RESET                   ;
            .sect	".int09"		        ; Timer_A0 Vector
            .short	TA0_ISR                 ;
            .sect	".int08"        		; Timer_AX Vector
            .short	TAX_ISR                 ;
            .end                        
 
 