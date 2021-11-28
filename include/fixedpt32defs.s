#importonce
.cpu _45gs02

.const FP_A  = $80
.const FP_B  = $84
.const FP_C  = $88
.const FP_R  = $8C

// load 32 data from one address to another
.macro FP_MOV(from, to) {
#if JUSTUSEQ
        ldq from
        stq to
#else
        lda from
        sta to
        lda from+1
        sta to+1
        lda from+2
        sta to+2
        lda from+3
        sta to+3
#endif
}

// load 32bit data from one address into two others
.macro FP_MOV2(from, to1, to2) {
#if JUSTUSEQ
        ldq from
        stq to1
        stq to2
#else
        lda from
        sta to1
        sta to2
        lda from+1
        sta to1+1
        sta to2+1
        lda from+2
        sta to1+2
        sta to2+2
        lda from+3
        sta to1+3
        sta to2+3
#endif
}

// load whole integer value (8bit)
.macro FP_STOR_II(val, addr) {
        lda #val       // load 8 bit immidiate value
        sta addr+3     // into high byte
        lda #0
        sta addr
        sta addr+1
        sta addr+2     // fraction to zero
}

// make .from negative and store in .to
.macro FP_NEG(from, to) {
#if JUSTUSEQ
        lda #0
        tax
        tay
        taz
        sec
        sbcq from
        stq to
#else
        lda #0
        sec
        sbc from
        sta to
        lda #0
        sbc from+1
        sta to+1
        lda #0
        sbc from+2
        sta to+2
        lda #0
        sbc from+3
        sta to+3
#endif
}

// make .from negative and store in .to1 and .to2
.macro FP_NEG2(from, to1, to2) {
#if JUSTUSEQ
        lda #0
        tax
        tay
        taz
        sec
        sbcq from
        stq to1
        stq to2
#else
        lda #0
        sec
        sbc from
        sta to1
        sta to2
        lda #0
        sbc from+1
        sta to1+1
        sta to2+1
        lda #0
        sbc from+2
        sta to1+2
        sta to2+2
        lda #0
        sbc from+3
        sta to1+3
        sta to2+3
#endif
}

// check sign of from
// if negative to = 0-from
.macro FP_ABS(from, to) {
        bit from+3
        bpl !pos+
        FP_NEG(from,to)
        bra !end+
!pos:
#if JUSTUSEQ
        ldq from
        stq to
#else
        lda from
        sta to
        lda from+1
        sta to+1
        lda from+2
        sta to+2
        lda from+3
        sta to+3
#endif
!end:
}

// shift .addr(32) right .count times
.macro FP_SR_X(addr, count) {
#if JUSUSEQ
        .for(var i=0; i<count; i++) {
                asrq addr
        }
#else
        ldx #count
!loop:
        asr addr+3
        ror addr+2
        ror addr+1
        ror addr
        dex
        bne !loop-
#endif
}

// shift .addr(32) left .count times
.macro FP_SL_X(addr, count) {
#if JUSUSEQ
        .for(var i=0; i<count; i++) {
                aslq addr
        }
#else
        ldx #count
!loop:
        asl addr
        rol addr+1
        rol addr+2
        rol addr+3
        dex
        bne !loop-
#endif
}

.macro FP_ADD() {
#if JUSTUSEQ
        ldq FP_A
        clc
        adcq FP_B
        stq FP_C
#else
        jsr fp_add
#endif
}

.macro FP_SUB() {
#if JUSTUSEQ
        ldq FP_A
        sec
        sbcq FP_B
        stq FP_C
#else
        jsr fp_subtract
#endif
}

.macro FP_SQUARE_CODE() {
        bit FP_A+3
        bpl !plus+
        FP_NEG2(FP_A, MATH_IN_A, MATH_IN_B)    // put negated (now positive) A into hwmult
        bra !end+
!plus:  FP_MOV2(FP_A, MATH_IN_A, MATH_IN_B)    // put A into hwmult
!end:   FP_MOV(MATH_MULTOUT+3, FP_C)           // 64 bit result, 16.48, fetch 8.24 from it
}

.macro FP_SQUARE() {
#if JUSTUSEQ
        FP_SQUARE_CODE()
#else
        jsr fp_square
#endif
}

.macro FP_MULTIPLY_CODE() {
        FP_ABS(FP_A, MATH_IN_A)
        FP_ABS(FP_B, MATH_IN_B)
        // check and copy or negate result
        bit FP_A+3
        bmi !neg+
        bit FP_B+3
        bmi !nneg+
        bra !plus+
!neg:   bit FP_B+3
        bmi !plus+
!nneg:  FP_NEG(MATH_MULTOUT+3, FP_C) // 64 bit result, negate shifted 3 byte
        bra !end+
!plus:  FP_MOV(MATH_MULTOUT+3, FP_C) // 64 bit result, shifted 3 byte
!end:
}

.macro FP_MULTIPLY() {
#if JUSTUSEQ
        FP_MULTIPLY_CODE()
#else
        jsr fp_multiply
#endif
}
