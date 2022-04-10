!to "qtest.prg", cbm
!cpu m65
!convtab pet

DEBUG=0

!source "../benchmark/include/mega65defs.asm"

!zone main

        * = $2001

!address {
        SCREENPOS = $0800
        scrnptr   = $20
        strptr    = $22
        regprefix = $24
        test1ptr  = $30
}

!macro FAKE_LDQ .addr {
        lda .addr
        ldx .addr+1
        ldy .addr+2
        ldz .addr+3
}

!macro FAKE_LDQ_PSAVE .addr {
        php
        lda .addr
        ldx .addr+1
        ldy .addr+2
        ldz .addr+3
        plp
}

!macro FAKE_STQ .addr {
        sta .addr
        stx .addr+1
        sty .addr+2
        stz .addr+3
}

!macro FILL_Q {
        ldz #$87
        ldy #$65
        ldx #$43
        lda #$21
}

!macro STORE_STATE {
        php
        pha
        phx
        phy
        phz
}

!macro RESTORE_STATE {
        plz
        ply
        plx
        pla
        plp
}

basic:
        !word @line20, 10       ; line 10
        !byte $fe, $02          ; BANK
        !text "0:"              ; 0:
        !byte $9e               ; SYS $9e
        ; start address in hex as ascii codes
        !text "$"
@this:                          ; macro won't work with forward def'ed label
        +label2hexstr @this+20  ; 4 bytes hexstr, 3 bytes 0 (eol and eop)
        !byte 0                 ; eol
@line20:
        !word @last, 20         ; line 20
        !byte $fe, $41, $91     ; cursor on
        !text ",1,21"
        !byte 0                 ; eol
@last:
        !word 0                 ; eop

start:
        jmp test

start_str:  !scr "start value", $00
start_val:  !byte $21, $43, $65, $01

test1_str:  !scr "ldq ($nn)", $00
test1_val:  !byte $02, $04, $04, $02, $03, $01, $03, $01

test2_str:  !scr "adcq ($nn)", $00

test3_str:  !scr "stq $nnnn", $00
test3_val:  !byte $fe, $fe, $fe, $fe

test:
	;; Enable VIC-IV with magic knock
	lda #$47
        sta VICIV_KEY
        lda #$53
        sta VICIV_KEY
        ;; memory map
        lda #0
        ldx #0
        ldy #0
        ldz #%10110000
        map                     ; set memory map to give us IO and some ROM (right?)
        eom
        sei

        lda #0
        sta DMA_ADDRBANK
        lda #>dma_cls
        sta DMA_ADDRMSB
        lda #<dma_cls
        sta DMA_ADDRLSB_ETRIG   ; clear screen & cram

        lda #$2f
        tab
        lda #<SCREENPOS
        sta scrnptr
        lda #>SCREENPOS
        sta scrnptr+1
        lda #17         ; Q
        sta regprefix

        lda #<test1_val
        sta test1ptr
        lda #>test1_val
        sta test1ptr+1

        lda #<start_str
        ldx #>start_str
        jsr display_string
        lda #25
        jsr advance_screen

startval:
        lda start_val
        ldx start_val+1
        ldy start_val+2
        ldz start_val+3
        cmp #0
        clc
        +STORE_STATE

@display:
        jsr display_registers
        lda #55
        jsr advance_screen

        lda #<test1_str
        ldx #>test1_str
        jsr display_string
        lda #25
        jsr advance_screen

doldq:
        +RESTORE_STATE
        ldq (test1ptr)
        +STORE_STATE

@display:
        jsr display_registers
        lda #55
        jsr advance_screen

        lda #<test2_str
        ldx #>test2_str
        jsr display_string
        lda #25
        jsr advance_screen

doadcq:
        +RESTORE_STATE
        clc
        adcq (test1ptr)
        +STORE_STATE

@display:
        jsr display_registers
        lda #55
        jsr advance_screen

        +RESTORE_STATE

!if 0 {
        lda #<test2_str
        ldx #>test2_str
        jsr display_string
        lda #25
        jsr advance_screen

        +RESTORE_STATE
        inq
        +STORE_STATE
        jsr display_registers
        lda #55
        jsr advance_screen

        lda #<test3_str
        ldx #>test3_str
        jsr display_string
        lda #25
        jsr advance_screen

        lda #13         ; M
        sta regprefix
        +RESTORE_STATE
        stq test3_val
        +FAKE_LDQ_PSAVE test3_val
        jsr display_registers
        lda #55
        jsr advance_screen
}
        lda #$00
        tab
        ; cli done by basic sys call
        rts

        ; adds A to scrnptr
advance_screen:
        clc
        adc scrnptr
        sta scrnptr
        lda #0
        adc scrnptr+1
        sta scrnptr+1
        rts

        ; writes 0 terminated string to scrnptr
        ; A - string pointer low
        ; X - string pointer high
        ; Y is used as index
display_string:
        sta strptr
        stx strptr+1
        ldy #0
-       lda (strptr),y
        beq +
        sta (scrnptr),y
        iny
        bne -
+       rts

        ; display the current registers
        ; needs all registers and flags
        ; changes everything.
        ; writes at scrnptr, does not change it
display_registers:
        php             ; first save the stuff
        pha             ; A is lsb of Q, we want this last
        phx
        phy
        phz             ; Z is msb of Q, so this needs to be first
        ldy #0
        lda regprefix   ; Q/M
        sta (scrnptr),y
        iny
        lda #61         ; =
        sta (scrnptr),y
        iny
        lda #36         ; $
        sta (scrnptr),y
        iny
        pla
        jsr display_byte
        pla
        jsr display_byte
        pla
        jsr display_byte
        pla
        jsr display_byte
        lda #32
        sta (scrnptr),y
        iny
        lda #27         ; [
        sta (scrnptr),y
        iny
        pla
        jsr display_flags
        lda #29         ; ]
        sta (scrnptr),y
        iny
        rts

        ; write byte to screen
        ; A - byte to write
        ; X - used in code
        ; Y - offset to scrnptr, is inc'ed 2 times
display_byte:
        tax             ; save for low nyb
        clc
        ror
        asr
        asr
        asr             ; high nyb first
        cmp #10         ; A-F?
        bcs +
        clc
        adc #48         ; 0-9
        bra ++
+       sec
        sbc #9
++      sta (scrnptr),y
        iny
        txa
        and #15
        cmp #10         ; A-F?
        bcs +
        clc
        adc #48         ; 0-9
        bra ++
+       sec
        sbc #9
++      sta (scrnptr),y
        iny
        rts

display_flags:
        tax
        and #$80
        beq +
        lda #14         ; N
        bra ++
+       lda #46         ; .
++      sta (scrnptr),y
        iny
        txa
        and #$02
        beq +
        lda #26         ; Z
        bra ++
+       lda #46         ; .
++      sta (scrnptr),y
        iny
        txa
        and #$04
        beq +
        lda #9          ; I
        bra ++
+       lda #46         ; .
++      sta (scrnptr),y
        iny
        txa
        and #$01
        beq +
        lda #3          ; C
        bra ++
+       lda #46         ; .
++      sta (scrnptr),y
        iny
        txa
        and #$08
        beq +
        lda #4          ; D
        bra ++
+       lda #46         ; .
++      sta (scrnptr),y
        iny
        txa
        and #$40
        beq +
        lda #22         ; V
        bra ++
+       lda #46         ; .
++      sta (scrnptr),y
        iny
        rts

dma_cls:
        ; clear screen and cram
        !byte $0a, $00  ; no enhanced options
        !byte DMA_FILL|DMA_CHAIN
        !word 80*25
        !word $0020     ; fill space
        !byte $00       ; src bank (ignored)
        !word SCREENPOS ; dest
        !byte $00       ; destbnk(0-3) + flags
        !word $0000     ; modulo (ignored)
        !byte $0a, $81, $ff, $00 ; 11 byte mode, dest bank $ff
        !byte DMA_FILL
        !word 2000      ; 2*40*25 (chr16 lowres)
        !word $0001     ; fill colour 1 (white)
        !byte $00       ; src bank (ignored)
        !word $0000     ; dest
        !byte $08       ; destbnk -> FF 8 0000
        !word $0000     ; modulo (ignored)
