#importonce
/*
 * Some useful macros for MEGA65
 */
.cpu _45gs02

#import "mega65defs.s"

/*
 * Generate BASIC65 Boilerplate at $2001
 *    10 BANK0:SYS$addr
 * earliest addr you can use is $2012
 */
.macro Basic65Upstart(addr) {
        * = $2001 "BASIC Upstart"

        .encoding "petscii_upper"
        .word !eop+, 10         // line 10
        .byte $fe, $02          // BANK0
        .text "0:"
        .byte $9e               // SYS$addr
        .text "$"
        .text toHexString(addr)
        .byte 0                 // eol
!eop:
        .word 0                 // eop
}

.macro Basic65Benchmark(addr) {
        * = $2001 "BASIC Upstart"

        .encoding "petscii_upper"
        .word !line10+, 10      // line 10
        .byte $9c               // CLRTI
        .text "TI:"
        .byte $fe, $02          // BANK0
        .text "0:"
        .byte $9e               // SYS$addr
        .text "$"
        .text toHexString(addr)
        .text ":ET"             // ET=TI
        .byte $b2
        .text "TI"
        .byte 0                 // eol
!line10:
        .word !eop+, 20         // line 20
        .byte $e8, $3a, $99     // SCNCLR:PRINTET
        .text "ET"
        .byte 0                 // eol
!eop:
        .word 0                 // eop
}

.macro GoFaster() {
        lda #65
        sta $00                 // switch to 40.5 MHz
}

.macro UnmapMemory() {
        lda #0
        tax
        tay
        taz
        map
        eom                        // zero out memory mapping
}

.macro EnableVIC4() {
        lda #$47                // do the magic knock
        sta $d02f
        lda #$53
        sta $d02f
}

.macro EnableVIC3() {
        lda #$a5                // do the magic knock
        sta $d02f
        lda #$96
        sta $d02f
}

.macro DisableC65ROM() {
        lda #$70
        sta $d640
        eom
}

//
// Disabled Interrupts, clears Decimal flag and moves BasePage
//
.macro MoveBasePage(basepage) {
        sei                // disable interupts
        cld                // no binary decimals
        lda #basepage
        tab                // move base-page so we can use base page addresses for everything
}

.macro ResetBasePage() {
        lda #0
        tab
}

.macro UARTClearKey() {
        // clear key buffer
!loop:  lda UART_ASCIIKEY
        beq !enduart+
        sta UART_ASCIIKEY
        bra !loop-
!enduart:
}

// read ASCII key is in accumulator
.macro UARTWaitKey() {
!loop:  lda UART_ASCIIKEY
        beq !loop-
        sta UART_ASCIIKEY
}