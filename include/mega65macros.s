#importonce
/*
 * Some useful macros for MEGA65
 */
.cpu _45gs02

#import "mega65defs.s"

/*
 * Generate BASIC65 Boilerplate at $2001
 *    10 BANK0:SYS$addr
 * and starts segment Main with label main right after this
 */
.macro Basic65Upstart() {
        * = $2001 "BASIC Upstart"

        .encoding "petscii_upper"
        .word !nextline+, 10    // line 10
#if BENCHMARK
        .byte $9c               // CLRTI
        .text "TI:"
#endif
        .byte $fe, $02          // BANK0
        .text "0:"
        .byte $9e               // SYS$addr
        .text "$"
        .byte $30 + ((!main+>>12) & $f)
        .byte $30 + ((!main+>>8) & $f)
        .byte $30 + ((!main+>>4) & $f)
        .byte $30 + (!main+ & $f)
#if BENCHMARK
        .text ":ET"             // ET=TI
        .byte $b2
        .text "TI"
#endif
        .byte 0                 // eol
!nextline:
#if BENCHMARK
        .word !lastline+, 20    // line 20
        .byte $e8, $3a, $99     // SCNCLR:PRINTET
        .text "ET"
        .byte 0                 // eol
!lastline:
#endif
        .word 0                 // eop

!main:
        * = * "Main"
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
        eom                     // zero out memory mapping
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
        sei                     // disable interupts
        cld                     // no binary decimals
        lda #basepage
        tab                     // move base-page so we can use base page addresses for everything
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