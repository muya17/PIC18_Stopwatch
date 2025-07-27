LIST P=18F4520
#include <P18F4520.INC>

; Configuration bits
CONFIG OSC = XT         ; 4 MHz crystal
CONFIG WDT = OFF        ; Disable watchdog
CONFIG LVP = OFF        ; Disable low-voltage programming

; Variables
CBLOCK 0x020
    DELAY_U             ; Delay counter upper
    DELAY_H             ; Delay counter high
    MS_L                ; Milliseconds (00-99, BCD)
    SEC_L               ; Seconds (00-99, BCD)
    RUNNING             ; 1=running, 0=stopped
    DIGIT_SEL           ; Current 7-segment digit (0-3)
    REFRESH_FLAG        ; Display refresh flag
    TEMP_W              ; WREG backup in ISR
    TEMP_STATUS         ; STATUS backup in ISR
ENDC

; Vector table
ORG 0x0000
    GOTO    Main

ORG 0x0008              ; High-priority ISR (buttons)
    GOTO    HighISR

ORG 0x0018              ; Low-priority ISR (Timer0)
    GOTO    LowISR

; Main program
ORG 0x0100
Main:
    ; Initialize ports
    CLRF    PORTA       ; PORTA available for debugging
    CLRF    PORTB
    CLRF    PORTC       ; PORTC = digit select
    CLRF    PORTD       ; PORTD = segments
    MOVLW   0x0F
    MOVWF   ADCON1      ; All pins digital
    CLRF    TRISA       ; PORTA outputs (optional debug)
    MOVLW   0x03
    MOVWF   TRISB       ; RB0=start/stop, RB1=reset
    CLRF    TRISC       ; PORTC outputs
    CLRF    TRISD       ; PORTD outputs

    ; Initialize variables
    CLRF    MS_L
    CLRF    SEC_L
    CLRF    RUNNING
    CLRF    DIGIT_SEL
    CLRF    REFRESH_FLAG

    ; Timer0: 16-bit, prescaler 1:64 (10ms at 4MHz)
    MOVLW   b'10000101' ; T0CON = enabled, 16-bit, 1:64
    MOVWF   T0CON
    MOVLW   0xFD        ; Reload value for 10ms: 0xFD8F
    MOVWF   TMR0H
    MOVLW   0x8F
    MOVWF   TMR0L

    ; Interrupt setup
    BSF     RCON, IPEN  ; Enable priority levels
    BCF     INTCON2, TMR0IP ; Timer0 = LOW priority
    BSF     INTCON3, INT1IP ; INT1 = HIGH priority
    BSF     INTCON, GIEH    ; Enable high-priority interrupts
    BSF     INTCON, GIEL    ; Enable low-priority interrupts
    BSF     INTCON, T0IE    ; Enable Timer0 interrupt
    BSF     INTCON, INT0IE  ; Enable INT0 (start/stop)
    BCF     INTCON2, INTEDG0 ; INT0 on falling edge
    BSF     INTCON3, INT1IE ; Enable INT1 (reset)
    BCF     INTCON2, INTEDG1 ; INT1 on falling edge

; Main loop
Loop:
    BTFSS   REFRESH_FLAG, 0 ; Wait for Timer0 refresh
    BRA     Loop
    
    BCF     REFRESH_FLAG, 0
    MOVLW   HIGH UpdateDisplay ; <<< Safe call setup
    MOVWF   PCLATH
    CALL    UpdateDisplay
    BRA     Loop

; High-priority ISR (physical buttons)
HighISR:
    CLRF    PCLATH      ; <<< Critical for stability
    MOVWF   TEMP_W
    MOVFF   STATUS, TEMP_STATUS

    ; Check INT0 (start/stop - RB0)
    BTFSC   INTCON, INT0IF
    BRA     HandleINT0

    ; Check INT1 (reset - RB1)
    BTFSC   INTCON3, INT1IF
    BRA     HandleINT1

    BRA     HighISR_Exit

HandleINT0:
    BCF     INTCON, INT0IF
    BTG     RUNNING, 0  ; Toggle run/stop state
    BRA     HighISR_Exit

HandleINT1:
    BCF     INTCON3, INT1IF
    BTFSC   RUNNING, 0  ; Only reset if stopped
    BRA     HighISR_Exit
    CLRF    MS_L        ; Clear time
    CLRF    SEC_L

HighISR_Exit:
    MOVFF   TEMP_STATUS, STATUS
    MOVF    TEMP_W, W
    RETFIE  FAST

; Low-priority ISR (Timer0 - 10ms interrupts)
LowISR:
    CLRF    PCLATH      ; 
    MOVWF   TEMP_W
    MOVFF   STATUS, TEMP_STATUS

    BTFSS   INTCON, T0IF
    BRA     LowISR_Exit

    ; Reload Timer0 for precise 10ms (0xFD8F)
    BCF     INTCON, T0IF
    MOVLW   0xFD
    MOVWF   TMR0H
    MOVLW   0x8F
    MOVWF   TMR0L

    BSF     REFRESH_FLAG, 0 ; Trigger display update

    ; Timekeeping (only when RUNNING=1)
    BTFSS   RUNNING, 0
    BRA     LowISR_Exit

    ; Increment milliseconds (BCD)
    MOVLW   0x01
    ADDWF   MS_L, F
    MOVLW   0x99
    CPFSEQ  MS_L
    BRA     LowISR_Exit
    CLRF    MS_L        ; Rollover at 99

    ; Increment seconds (BCD)
    MOVLW   0x01
    ADDWF   SEC_L, F
    MOVLW   0x99
    CPFSEQ  SEC_L
    BRA     LowISR_Exit
    CLRF    SEC_L       ; Rollover at 99

LowISR_Exit:
    MOVFF   TEMP_STATUS, STATUS
    MOVF    TEMP_W, W
    RETFIE


; 2ms delay for multiplex stability
Delay_Mux:
        MOVLW   02h
        MOVWF   DELAY_U
DM_LOOP1:
        MOVLW   0FFh
        MOVWF   DELAY_H
DM_LOOP2:
        MOVLW   0FFh
        MOVWF   DELAY_L
DM_WAIT:
        DECFSZ  DELAY_L, F
        GOTO    DM_WAIT
        DECFSZ  DELAY_H, F
        GOTO    DM_LOOP2
        DECFSZ  DELAY_U, F
        GOTO    DM_LOOP1
        RETURN

        ; Digit strobe routine
UpdateDisplay:
        ; disable all digits
        CLRF    PORTC
        ; call appropriate handler based on index without PC arithmetic
        ; Test for DIGIT_SEL == 0
        MOVF    DIGIT_SEL, W
        XORLW   0
        BTFSC   STATUS, Z
            CALL    D0
        ; Test for DIGIT_SEL == 1
        MOVF    DIGIT_SEL, W
        XORLW   1
        BTFSC   STATUS, Z
            CALL    D1
        ; Test for DIGIT_SEL == 2
        MOVF    DIGIT_SEL, W
        XORLW   2
        BTFSC   STATUS, Z
            CALL    D2
        ; Otherwise DIGIT_SEL == 3
        CALL    D3
        GOTO    UD_Done

D0:     MOVF    MS_L, W
        ANDLW   0Fh
        MOVWF   TMP_IDX
        CALL    BCD_7Seg
        MOVWF   PORTD
        MOVLW   01h
        MOVWF   PORTC
        GOTO    UD_Done

D1:     MOVF    MS_L, W
        MOVWF   TMP_IDX
        SWAPF   TMP_IDX, W
        ANDLW   0Fh
        MOVWF   TMP_IDX
        CALL    BCD_7Seg
        IORLW   10000000b    ; decimal point
        MOVWF   PORTD
        MOVLW   02h
        MOVWF   PORTC
        GOTO    UD_Done

D2:     MOVF    SEC_L, W
        ANDLW   0Fh
        MOVWF   TMP_IDX
        CALL    BCD_7Seg
        MOVWF   PORTD
        MOVLW   04h
        MOVWF   PORTC
        GOTO    UD_Done

D3:     MOVF    SEC_L, W
        MOVWF   TMP_IDX
        SWAPF   TMP_IDX, W
        ANDLW   0Fh
        MOVWF   TMP_IDX
        CALL    BCD_7Seg
        MOVWF   PORTD
        MOVLW   08h
        MOVWF   PORTC

UD_Done:
    INCF    DIGIT_SEL, F       ; increment index
    MOVLW   04h                ; test for wrap (4 digits)
    CPFSEQ  DIGIT_SEL          ; if equal, skip next (the branch)
    GOTO    UD_NoWrap          ; if not equal, jump past clear
    CLRF    DIGIT_SEL          ; if index == 4, wrap back to 0
UD_NoWrap:
    ; CALL    Delay_Mux         ; delay removed for testing
    RETURN
    
    ; Digit 0: MS_L low nibble
Digit0:
    MOVF    MS_L, W
    ANDLW   0x0F
    CALL    BCD_7Seg
    MOVWF   PORTD
    MOVLW   b'00000001'    ; Activate digit 0
    MOVWF   PORTC
    BRA     UpdateDone
    
    ; Digit 1: MS_L high nibble (with decimal point)
Digit1:
    MOVF    MS_L, W
    SWAPF   WREG, W
    ANDLW   0x0F
    CALL    BCD_7Seg
    IORLW   b'10000000'    ; Add decimal point
    MOVWF   PORTD
    MOVLW   b'00000010'    ; Activate digit 1
    MOVWF   PORTC
    BRA     UpdateDone
    
    ; Digit 2: SEC_L low nibble
Digit2:
    MOVF    SEC_L, W
    ANDLW   0x0F
    CALL    BCD_7Seg
    MOVWF   PORTD
    MOVLW   b'00000100'    ; Activate digit 2
    MOVWF   PORTC
    BRA     UpdateDone
    
    ; Digit 3: SEC_L high nibble
Digit3:
    MOVF    SEC_L, W
    SWAPF   WREG, W
    ANDLW   0x0F
    CALL    BCD_7Seg
    MOVWF   PORTD
    MOVLW   b'00001000'    ; Activate digit 3
    MOVWF   PORTC

UpdateDone:
    ; Cycle to next digit (0-3)
    INCF    DIGIT_SEL, F
    MOVLW   0x04
    CPFSEQ  DIGIT_SEL
    RETURN
    CLRF    DIGIT_SEL
    RETURN

UpdateDelay:
    ; Short delay for multiplexing (~1ms)
    CALL    Delay_1ms
    RETURN

; 1ms delay at 4MHz
Delay_1ms:
    MOVLW   0x01
    MOVWF   DELAY_U
Delay1ms_Loop:
    MOVLW   0xFA        ; 250 * 4 cycles = 1000 cycles
    MOVWF   DELAY_H
Delay1ms_Inner:
    NOP
    NOP
    DECF    DELAY_H, F
    BNZ     Delay1ms_Inner
    DECF    DELAY_U, F
    BNZ     Delay1ms_Loop
    RETURN

; BCD to 7-segment lookup table

BCD_7Seg:
        MOVWF   DIGIT_VAL             ; store digit in TMP_IDX
        MOVLW   LOW(BcdTable)
        MOVWF   TBLPTRL
        MOVLW   HIGH(BcdTable)
        MOVWF   TBLPTRH
        MOVF    DIGIT_VAL, W
        MOVWF   DIGIT_VAL
        RLNCF   DIGIT_VAL, F       ; Multiply index by 2 (logical shift left)       ; Multiply index by 2
        MOVF    DIGIT_VAL, W
        ADDWF   TBLPTRL, F
        BTFSC   STATUS, C
        INCF    TBLPTRH, F
        TBLRD*
        MOVF    TABLAT, W
        RETURN

ORG 0x1000
BcdTable:
        DB b'00111111' ; 0: 0x3F
        DB b'00000110' ; 1: 0x06
        DB b'01011011' ; 2: 0x5B
        DB b'01001111' ; 3: 0x4F
        DB b'01100110' ; 4: 0x66
        DB b'01101101' ; 5: 0x6D
        DB b'01111101' ; 6: 0x7D
        DB b'00000111' ; 7: 0x07
        DB b'01111111' ; 8: 0x7F
        DB b'01101111' ; 9: 0x6F

        END


END