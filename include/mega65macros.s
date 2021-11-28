/*
 * Some useful macros for MEGA65
 */
.cpu _45gs02

/*
 * Generate BASIC65 Boilerplate at $2001
 *    10 BANK0:SYS$addr
 * earliest addr you can use is $2012
 */
.macro Basic65Upstart(addr) {
	* = $2001 "BASIC Upstart"

	.encoding "petscii_upper"
	.byte <eop, >eop	// next line
	.byte $0a, $00		// line 10
	.byte $fe, $02		// BANK
	.text "0:"
	.byte $9e		// SYS
	.text "$"
	.text toHexString(addr)
	.byte $00		// end of line
eop:
	.byte $00,$00		// end of program
}

.macro BenchmarkUpstart(addr) {
	* = $2001 "BASIC Upstart"

	.encoding "petscii_upper"
	.word line10, 10
	.byte $9c
	.text "TI:"
	.byte $fe, $02
	.text "0:"
	.byte $9c
	.text "TI:"
	.byte $9e
	.text "$"
	.text toHexString(addr)
        .text ":ET"
	.byte $b2
	.text "TI"
        .byte 0
line10:
        .word eop, 20
        .byte $e8, $3a, $99
        .text "ET"
        .byte 0
eop:
        .word 0
}

.macro GoFaster() {
	lda #65
	sta $00
}

.macro UnmapMemory() {
	lda #0
	tax
	tay
	taz
	map
	eom
}

.macro EnableVIC4() {
	lda #$47		// do the magic knock
	sta $d02f
	lda #$53
	sta $d02f
}

.macro EnableVIC3() {
	lda #$a5		// do the magic knock
	sta $d02f
	lda #$96
	sta $d02f
}

.macro DisableC65ROM() {
	lda #$70
	sta $d640
	eom
}
