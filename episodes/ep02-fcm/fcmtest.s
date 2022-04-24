.cpu _45gs02

#import "mega65defs.s"
#import "mega65macros.s"
#import "vic4fcm.s"

// some locations need to be defined
.const BASEPAGE  = (>theend)+1
.const VICSTATE  = $f0
.const SCREENMEM = (theend & $ff00) + $200 // this is screen ram
.const GRAPHMEM  = $40000        // this is character ram (or graphic in this case)
.const COLORRAM  = $ff81000      // this is in high ram $ff 8 1000

        // BASIC Boilerplate
	Basic65Upstart()

setup:
	GoFaster()
	UnmapMemory()
	EnableVIC4()

        MoveBasePage(BASEPAGE)
        UARTClearKey()

start:
        VIC4_StoreState(VICSTATE)

        lda #0
        sta VICIV_BORDERCOL
        sta VICIV_SCREENCOL             // black background and border

        FCM_InitScreenMemory(0, SCREENMEM, GRAPHMEM, 0, COLORRAM, 1)

        FCM_ScreenOn(SCREENMEM, COLORRAM)

        //
        // 03: write some text
        //
        ldx #0                          // text index
        ldy #0                          // screen index
!txtloop:
        lda display_text1,x
        beq !endloop+                   // zero terminated text
        sta SCREENMEM + 806,y
        iny
        lda #0
        sta SCREENMEM + 806,y           // zero high byte for text
        iny
        inx
        bra !txtloop-
!endloop:

        lda #$1E
        sta SCREENMEM + 4*80
        lda #0
        sta SCREENMEM + 4*80 + 1        // write a ^ where the pixel demo ends

        //
        // 02: tiledemo - duplicate tile 0101 in second column
        //
        lda #$01
        sta SCREENMEM + 2
        lda #$10
        sta SCREENMEM + 3               // write $1001 to first row, second column

        //
        // 01: just write bytes
        //
        lda #<(GRAPHMEM & $ffff)        // setup 32bit ptr to graphmem
        sta $10
        lda #>(GRAPHMEM & $ffff)
        sta $11
        lda #<(GRAPHMEM>>16)
        sta $12
        lda #>(GRAPHMEM>>16)
        sta $13
        ldz #0                          // start with zero
gfxloop:
        tza
        and #03
        clc
        adc #1                          // generate a colour from 1-4
        sta (($10)),z                   // write colour to graphmem via bp ptr
        UARTWaitKey()
        cmp #113                        // compare A to small 'q' ASCII
        beq endloop                     // end this loop if q was pressed
        inz                             // next graphmem location / colour
        bne gfxloop                     // still not zero (again)?
endloop:

        //
        // 04: bonus - DMA line drawing
        //
        FCM_DrawLine(GRAPHMEM + 3*$640 + 3*$40, $2000, 1)
        FCM_DrawLine(GRAPHMEM + 3*$640 + 3*$40, $4000, 2)
        FCM_DrawLine(GRAPHMEM + 3*$640 + 3*$40, $6000, 3)
        FCM_DrawLine(GRAPHMEM + 3*$640 + 3*$40, $8000, 4)
        FCM_DrawLine(GRAPHMEM + 3*$640 + 3*$40, $A000, 5)
        FCM_DrawLine(GRAPHMEM + 3*$640 + 3*$40, $C000, 6)
        FCM_DrawLine(GRAPHMEM + 3*$640 + 3*$40, $E000, 7)
        FCM_DrawLine(GRAPHMEM + 3*$640 + 3*$40, $ffff, 8)
        UARTWaitKey()

exit:
        VIC4_RestoreState(VICSTATE)
        ResetBasePage()
        rts

display_text1:
        .encoding "screencode_mixed"
        .text "press any key"
        .byte 0

theend:
	.byte 0
