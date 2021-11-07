.cpu _45gs02
.encoding "petscii_upper"

#import "include/mega65macros.s"
#import "include/mega65defs.s"
#import "include/fixedpt32defs.s"
#import "include/mandelbrot32defs.s"

// set to 1 to enable debugging
.eval DEBUG = 0

// some locations need to be defined
.const BASEPAGE  = ((>theend)+1) // right after our program
.const VICSTATE  = $f0    // basepage storage for old vic state
.const SCREENMEM = $3000
.const GRAPHMEM  = $40000 // this is character ram

/*
 * Start of Mandelbrot Explorer 65
 */

	Basic65Upstart($2012)

	* = $2012 "Program"

	GoFaster()
	UnmapMemory()
	EnableVIC4()

	sei		// disable interupts
	cld		// no binary decimals
	lda #BASEPAGE
	tab		// move base-page so we can use base page addresses for everything

/*
 * Initialize Graphics
 */
        lda #0
        sta DMA_ADDRBANK
        lda #>dma_cls
        sta DMA_ADDRMSB
        lda #<dma_cls
        sta DMA_ADDRLSB_ETRIG   // clear screen & charram
        lda #0
        sta DMA_ADDRBANK
        lda #>dma_clscol
        sta DMA_ADDRMSB
        lda #<dma_clscol
        sta DMA_ADDRLSB_ETRIG   // clear colorram

        // store VIC states for later restore (in basepage)
        lda VICIII_SCRNMODE
        sta VICSTATE
        lda VICIV_SCRNMODE
        sta VICSTATE+1
        lda VICIV_SCRNPTR1
        sta VICSTATE+2
        lda VICIV_SCRNPTR2
        sta VICSTATE+3
        lda VICIV_SCRNPTR3
        sta VICSTATE+4
        lda VICIV_SCRNPTR4
        sta VICSTATE+5
        lda VICIV_LINESTEPLO
        sta VICSTATE+6
        lda VICIV_LINESTEPHI
        sta VICSTATE+7
        lda VICIV_PALETTE
        sta VICSTATE+8
        lda VICIV_CHRCOUNT
        sta VICSTATE+9
        
        //// copied from basic.
        //// 40x25 - 80x50 screen, with screen RAM at $3000-$3FFF, colour RAM at $FF80000-$FF81FFF
        ////
        //// IMPORTANT: setting scrnmode must come before changing scrnptr!
        ////
        lda #%10001000          // clear H640 and V400 for 320x200
        trb VICIII_SCRNMODE
        lda #%00000101          // set FCLRHI CHR16 for super extended attr mode
        tsb VICIV_SCRNMODE

        lda #80
        sta VICIV_LINESTEPLO
        lda #0
        sta VICIV_LINESTEPHI    // one line of 40 chars is 80 byte

        lda #40
        sta VICIV_CHRCOUNT      // we are drawing only 40 chars

        lda #<SCREENMEM
        sta VICIV_SCRNPTR1
        lda #>SCREENMEM
        sta VICIV_SCRNPTR2
        lda #<[SCREENMEM >> 16]
        sta VICIV_SCRNPTR3
        sta scrn_point+2
        lda #0
        sta VICIV_SCRNPTR4
        sta scrn_point+3

        sta VICIV_BORDERCOL
        sta VICIV_SCREENCOL     // black back and border

        lda #%01010101
        sta VICIV_PALETTE       // toggle palette to something else

        // copy palette
        lda #0
        sta DMA_ADDRBANK
        lda #>dma_copypal
        sta DMA_ADDRMSB
        lda #<dma_copypal
        sta DMA_ADDRLSB_ETRIG   // copy commander x16 palette

        // fill screen with pointers to $40000 y by x
        lda #<[GRAPHMEM>>6]
        sta scrn_row
        lda #>[GRAPHMEM>>6]
        sta scrn_row+1          // set $14/$15 to current charcode $1000 = $40000 absolute
        ldz #0                  // z loop index
scrnfilx:
        lda #<SCREENMEM
        sta scrn_point
        lda #>SCREENMEM
        sta scrn_point+1 // set low word of addr ptr to $3000
        ldy #25          // y loop counter
scrnfily:
        lda scrn_row
        sta ((scrn_point)),z      // put low byte of char on screen
        inz                     // next index
        lda scrn_row+1
        sta ((scrn_point)),z      // put high byte of char on screen
        dez                     // prev index
        inc scrn_row
        bne !ov+
        inc scrn_row+1   // increment character by one
!ov:    lda #80
        clc
        adc scrn_point
        sta scrn_point
        bcc !ov+
        inc scrn_point+1 // add 80 to pointer
!ov:    dey
        bne scrnfily    // next y
        inz
        inz             // inc x index by 2
        cpz #80         // cmp to 80 (end of line)
        bne scrnfilx

//
// MANDELBROT
//
        jsr mb_init             // initialize dr, di

        // set cr
        FP_MOV(mand_base_r0, mand_cr)
        lda #0
        sta scrn_x
        sta scrn_x+1            // x = 0
        sta scrn_row
        sta scrn_row+1
        sta scrn_point
        sta scrn_point+1
        sta scrn_point+3
        lda #[[GRAPHMEM & $ff0000]>>16]
        sta scrn_point+2        // scrn_row = $0000, scrn_point = $0004.0000
xloop:
        // set ci
        FP_MOV(mand_base_i0, mand_ci)
        lda #200
        sta scrn_y              // y = 200
yloop:
        // do mandel stuff
        jsr mb_iter

.if (DEBUG==1) {
        // break at some point to inspect iteration data
        lda scrn_x
        cmp #150
        bne !end+
        lda scrn_y
        cmp #130
        bne !end+
        jmp endloop
!end:
}

        // draw pixel
        //lda scrn_y
        lda #128
        sec
        sbc mand_iter
        ldz #0
        sta ((scrn_point)),z

        FP_MOV(mand_ci, FP_A)
        FP_MOV(mand_di, FP_B)
        jsr fp_add
        FP_MOV(FP_C, mand_ci)   // advance c.i

        lda #8
        clc
        adc scrn_point
        sta scrn_point
        bcc !nov+
        inc scrn_point+1        // move point one down the row
!nov:   dec scrn_y              // dec yloop counter
        bne yloop

        FP_MOV(mand_cr, FP_A)
        FP_MOV(mand_dr, FP_B)
        jsr fp_add
        FP_MOV(FP_C, mand_cr)   // advance c.r

        inc scrn_x
        bne !nov+
        inc scrn_x+1
!nov:   lda scrn_x+1
        cmp #$01
        bne advrow
        lda scrn_x
        cmp #$40
        beq endloop

advrow:
        inc scrn_row
        lda #7
        bit scrn_row
        bne smallrow           // check if we reached 8
        lda #<1592              // one row of characters is 25*64-8 (we already advanced 8...)
        clc
        adc scrn_row
        sta scrn_row
        sta scrn_point
        lda #>1592
        adc scrn_row+1          // add 25*64-8 to scrn_row
        sta scrn_row+1
        sta scrn_point+1         // and store also in scrn_point(loW)
        jmp xloop

smallrow:
        lda scrn_row
        sta scrn_point
        lda scrn_row+1
        sta scrn_point+1
        jmp xloop

endloop:
        jsr waitkey

        lda VICSTATE
        sta VICIII_SCRNMODE
        lda VICSTATE+1
        sta VICIV_SCRNMODE
        lda VICSTATE+6
        sta VICIV_LINESTEPLO
        lda VICSTATE+7
        sta VICIV_LINESTEPHI
        lda VICSTATE+9
        sta VICIV_CHRCOUNT
        lda VICSTATE+2
        sta VICIV_SCRNPTR1
        lda VICSTATE+3
        sta VICIV_SCRNPTR2
        lda VICSTATE+4
        sta VICIV_SCRNPTR3
        lda VICSTATE+5
        sta VICIV_SCRNPTR4
        lda VICSTATE+8
        sta VICIV_PALETTE
        lda #6
        sta VICIV_SCREENCOL
        sta VICIV_BORDERCOL

        lda #0
        tab                     // restore base-page to 0
        //dec $D019              // this before the cli to clear pending interrupt?
        //cli                    // allow interrupts - BASIC SYS handles this
        rts                     // return

waitkey:
        // clear key buffer
!loop:  lda UART_ASCIIKEY
        beq !wait+
        sta UART_ASCIIKEY
        bra !loop-

!wait:  // wait for key
!loop:  lda UART_ASCIIKEY
        beq !loop-

        // clear key buffer
!loop:  lda UART_ASCIIKEY
        beq !end+
        sta UART_ASCIIKEY
        bra !loop-
!end:   rts

dma_cls:
        // clear character rom
        .byte $0a, $00  // no enhanced options
        .byte DMA_FILL
        .word 64*40*25
        .word $0000     // fill tile 0
        .byte $00       // src bank (ignored)
        .word [GRAPHMEM & $ffff]  // dest
        .byte <[GRAPHMEM>>16] // destbnk(0-3) + flags
        .word $0000     // modulo (ignored)

dma_clscol:
        .byte $0a, $81, $ff, $00 // 11 byte mode, dest bank $ff
        .byte DMA_FILL
        .word 2000      // 2*40*25 (chr16 lowres)
        .word $0001     // fill colour 1 (white)
        .byte $00       // src bank (ignored)
        .word $0000     // dest
        .byte $08       // destbnk -> FF 8 0000
        .word $0000     // modulo (ignored)

dma_copypal:
        .byte $0a, $00  // 11 byte mode
        .byte DMA_COPY
        .word $300
        .word palette
        .byte $00
        .word VICIII_PALRED
        .byte $80       // dma visible(7)
        .word $0000

#import "include/fixedpt32.s"
#import "include/mandelbrot32.s"
#import "include/palette.s"

// Mandeldata:
mand_base:
        .byte 48 // 48 iterations
        .byte $67, $66, $a6, $fd  // rs=-2.35
        .byte $00, $00, $40, $01  // re=+1.25
        .byte $00, $00, $e0, $fe  // is=-1.125
        .byte $00, $00, $20, $01  // ie=+1.125

theend: .byte 0
