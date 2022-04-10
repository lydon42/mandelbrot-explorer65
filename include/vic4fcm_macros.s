#importonce

.cpu _45gs02

#import "mega65defs.s"

.macro VIC4_StoreState(vicstate) {
        // vicstate must have 14 bytes for storage
        // store VIC states for later restore
        lda VICIII_SCRNMODE
        sta vicstate
        lda VICIV_SCRNMODE
        sta vicstate+1
        lda VICIV_SCRNPTR1
        sta vicstate+2
        lda VICIV_SCRNPTR2
        sta vicstate+3
        lda VICIV_SCRNPTR3
        sta vicstate+4
        lda VICIV_SCRNPTR4
        sta vicstate+5
        lda VICIV_LINESTEPLO
        sta vicstate+6
        lda VICIV_LINESTEPHI
        sta vicstate+7
        lda VICIV_PALETTE
        sta vicstate+8
        lda VICIV_CHRCOUNT
        sta vicstate+9
        lda VICIV_COLPTRLO
        sta vicstate+10
        lda VICIV_COLPTRHI
        sta vicstate+11
        lda VICIV_SCREENCOL
        sta vicstate+12
        lda VICIV_BORDERCOL
        sta vicstate+13
}

.macro VIC4_RestoreState(vicstate) {
        lda vicstate
        sta VICIII_SCRNMODE
        lda vicstate+1
        sta VICIV_SCRNMODE
        lda vicstate+6
        sta VICIV_LINESTEPLO
        lda vicstate+7
        sta VICIV_LINESTEPHI
        lda vicstate+9
        sta VICIV_CHRCOUNT
        lda vicstate+2
        sta VICIV_SCRNPTR1
        lda vicstate+3
        sta VICIV_SCRNPTR2
        lda vicstate+4
        sta VICIV_SCRNPTR3
        lda vicstate+5
        sta VICIV_SCRNPTR4
        lda vicstate+8
        sta VICIV_PALETTE
        lda vicstate+10
        sta VICIV_COLPTRLO
        lda vicstate+11
        sta VICIV_COLPTRHI
        lda vicstate+12
        sta VICIV_SCREENCOL
        lda vicstate+13
        sta VICIV_BORDERCOL
}

//
// Clear the RAM used for colour and Graphics using a DMA job
//
.macro FCM_InitScreenMemory(bpbase, scrram, gfxram, gfxcol, colram, colour) {
        .var scrn_ptr = bpbase
        .var scrn_row = bpbase+2

        lda #<[gfxram>>6]       // fill screen with pointers to gfxram by dividing by 64
        sta scrn_ptr
        lda #>[gfxram>>6]
        sta scrn_ptr+1          // set scrn_ptr to current charcode gfxram/64
        ldz #0                  // z loop index (x coord)
!loopx:
        lda #<scrram            // set addr ptr to scrmem:
        sta scrn_row            // each y column starts with the same
        lda #>scrram            // addr, as we use z to index into the
        sta scrn_row+1          // row
        ldy #25                 // y loop counter (y coord)
!loopy:
        lda scrn_ptr
        sta (scrn_row),z        // put low byte of char on screen
        inz                     // next index
        lda scrn_ptr+1
        sta (scrn_row),z        // put high byte of char on screen
        dez                     // prev index
        inc scrn_ptr
        bne !ov+
        inc scrn_ptr+1          // increment scr_row value by one
!ov:    lda #80
        clc
        adc scrn_row
        sta scrn_row
        bcc !ov+
        inc scrn_row+1          // add 80 to scrn_row
!ov:    dey
        bne !loopy-             // next y
        inz
        inz                     // inc x coord by 2 (16bit characters!)
        cpz #80                 // cmp x coord to 80 (end of line)
        bne !loopx-             // next x

        lda #0                  // call DMA controller to fill screen & charram
        sta DMA_ADDRBANK
        lda #>!fcm_dma+
        sta DMA_ADDRMSB
        lda #<!fcm_dma+
        sta DMA_ADDRLSB_ETRIG   // trigger extended DMA job
        bra !fcm_dma_end+       // branch over DMA job data

!fcm_dma:
        // clear character ram
        .byte $0a, $00                  // 11 byte mode
        .byte DMA_FILL|DMA_CHAIN        // fill, chain next job
        .word 64*40*25
        .word [gfxcol & $ff]            // colour code to fill with, one byte
        .byte $00                       // src bank (ignored)
        .word [gfxram & $ffff]          // dest
        .byte [(gfxram>>16) & $f]       // destbnk(0-3) + flags
        .word $0000                     // modulo (ignored)
        // clear colour ram low-bytes with 0
        .byte $0a                       // 11 byte mode
        .byte $81, $ff                  // dest bank $ff
        .byte $85, $02                  // increment by 2
        .byte $00                       // eol
        .byte DMA_FILL|DMA_CHAIN        // fill, chain next job
        .word 1000                      // 40*25 (chr16 lowres)
        .word 0                         // clear
        .byte $00                       // src bank (ignored)
        .word [colram & $ffff]          // dest
        .byte [(colram>>16) & $f]       // destbnk -> FF 8 0000
        .word $0000                     // modulo (ignored)
        // fill colour ram high-bytes with colour
        .byte $0a                       // 11 byte mode
        .byte $81, $ff                  // dest bank $ff
        .byte $85, $02                  // increment by 2
        .byte $00                       // eol
        .byte DMA_FILL                  // fill, last job
        .word 1000                      // 40*25
        .word [colour & $f]             // colour (high byte)
        .byte $00                       // src bank (ignored)
        .word [(colram+1) & $ffff]      // dest
        .byte [((colram+1)>>16) & $f]   // destbnk -> FF 8 0000
        .word $0000                     // modulo (ignored)

!fcm_dma_end:
}

//
// Initialise FCM Screen 320x200
//
.macro FCM_ScreenOn(scrmem, gfxmem, colmem) {
        lda #(VICIII_SM_H640|VICIII_SM_V400)
        trb VICIII_SCRNMODE                   // clear H640 and V400 for 320x200
        lda VICIV_SCRNMODE
        ora #(VICIV_SM_FCLRHI|VICIV_SM_CHR16) // set FCLRHI + CHR16
        and #(~VIVIV_SM_FCLRLO)               // clear FCLRLO for super extended attr mode
        sta VICIV_SCRNMODE

        lda #80
        sta VICIV_LINESTEPLO
        lda #0
        sta VICIV_LINESTEPHI    // one line of 40 chars is 80 byte

        lda #40
        sta VICIV_CHRCOUNT      // we are drawing only 40 chars, high bits are in VICIV_SCRNPTR4

        lda #<scrmem            // set screen start address (28bit)
        sta VICIV_SCRNPTR1
        lda #>scrmem
        sta VICIV_SCRNPTR2
        lda #<[scrmem >> 16]
        sta VICIV_SCRNPTR3
        lda #>[scrmem >> 16]
        sta VICIV_SCRNPTR4      // also clears EXGLYPH and CHRCOUNT in high nibble

        lda #<colmem
        sta VICIV_COLPTRLO
        lda #>colmem
        sta VICIV_COLPTRHI      // set colorram start address
}

.macro FCM_DrawLine(start, slope, colour) {
        lda #0
        sta DMA_ADDRBANK
        lda #>!fcm_dma+
        sta DMA_ADDRMSB
        lda #<!fcm_dma+
        sta DMA_ADDRLSB_ETRIG   // clear screen & charram
        bra !fcm_dma_end+

!fcm_dma:
        // clear charact<er ram
        .byte $0a                       // 11 byte mode
        .byte $87, [(1600-8) & $ff]     // vertical stripe increment
        .byte $88, [(1600-8) >> 8]      // = 64*25 - 8
        .byte $8b, <slope               // line slope
        .byte $8c, >slope               // line slope
        .byte $8f, $c0                  // line draw, y, positive
        .byte $00                       // eol
        .byte DMA_FILL
        .word 150                       // 150 px?
        .word [colour & $ff]            // colour code to fill with, one byte
        .byte $00                       // src bank (ignored)
        .word [start & $ffff]           // dest
        .byte [start>>16 & $f]          // destbnk(0-3) + flags
        .word $0000                     // modulo (ignored)
!fcm_dma_end:
}
