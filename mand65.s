.cpu _45gs02
.encoding "petscii_upper"

#import "mega65defs.s"
#import "mega65macros.s"
#import "fixedpt32defs.s"
#import "mandelbrot32defs.s"
#import "vic4fcm_macros.s"

// set to 1 to enable debugging
.eval DEBUG = 0

// some locations need to be defined
.const BASEPAGE  = ((>theend)+1) // right after our program
.const VICSTATE  = $f0    // basepage storage for old vic state
.const SCREENMEM = (theend & $ff00) + $200
.const GRAPHMEM  = $40000 // this is character ram
.const COLORRAM  = $81000 // this is in high ram $ff 8 0000

/*
 * Start of Mandelbrot Explorer 65
 */

	Basic65Upstart()

	GoFaster()
	UnmapMemory()
	EnableVIC4()

	MoveBasePage(BASEPAGE)
        UARTClearKey()

/*
 * Initialize Graphics
 */
        VIC4_StoreState(VICSTATE)

        FCM_InitScreenMemory(0, SCREENMEM, GRAPHMEM, 0, COLORRAM, 1)

        FCM_ScreenOn(SCREENMEM, GRAPHMEM, COLORRAM)
        
        lda #0
        sta VICIV_BORDERCOL
        sta VICIV_SCREENCOL     // black back and border

        lda #%01010101          // default palette is %11 = 3
        sta VICIV_PALETTE       // toggle palette to something else

        // copy palette
        lda #0
        sta DMA_ADDRBANK
        lda #>dma_copypal
        sta DMA_ADDRMSB
        lda #<dma_copypal
        sta DMA_ADDRLSB_ETRIG   // copy commander x16 palette

//
// MANDELBROT
//
        jsr mb_init             // initialize dr, di

        FP_MOV(mand_base_r0, mand_cr)   // set cr
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
        FP_MOV(mand_base_i0, mand_ci)   // set ci
        lda #200
        sta scrn_y              // y = 200
yloop:
        jsr mb_iter             // calculate mandelbrot

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

#if JUSTUSEQ
        ldq mand_ci
        clc
        adcq mand_di
        stq mand_ci
#else
        FP_MOV(mand_ci, FP_A)
        FP_MOV(mand_di, FP_B)
        jsr fp_add
        FP_MOV(FP_C, mand_ci)   // advance c.i
#endif

        lda #8
        clc
        adc scrn_point
        sta scrn_point
        bcc !nov+
        inc scrn_point+1        // move point one down the row
!nov:   dec scrn_y              // dec yloop counter
        bne yloop

#if JUSTUSEQ
        ldq mand_cr
        clc
        adcq mand_dr
        stq mand_cr
#else
        FP_MOV(mand_cr, FP_A)
        FP_MOV(mand_dr, FP_B)
        jsr fp_add
        FP_MOV(FP_C, mand_cr)   // advance c.r
#endif

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
#if !BENCHMARK
        UARTWaitKey()
#endif

        VIC4_RestoreState(VICSTATE)

        lda #0
        tab                     // restore base-page to 0
        //dec $D019              // this before the cli to clear pending interrupt?
        //cli                    // allow interrupts - BASIC SYS handles this
        rts                     // return

dma_copypal:
        .byte $0a, $00  // 11 byte mode
        .byte DMA_COPY
        .word $300
        .word palette
        .byte $00
        .word VICIII_PALRED
        .byte $80       // dma visible(7)
        .word $0000

#import "vic4fcm.s"
#import "fixedpt32.s"
#import "mandelbrot32.s"
#import "palette.s"

// Mandeldata:
mand_base:
        .byte 48 // 48 iterations
        .byte $67, $66, $a6, $fd  // rs=-2.35
        .byte $00, $00, $40, $01  // re=+1.25
        .byte $00, $00, $e0, $fe  // is=-1.125
        .byte $00, $00, $20, $01  // ie=+1.125

theend: .byte 0
