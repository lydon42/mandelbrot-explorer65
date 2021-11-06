
;
; 32bit fixed point math unit
;
; assumes 8.24 numbers (easier to fetch mult/div result if whole part is 8)
;
fp_subtract:    ; FP_C = FP_A - FP_B
        lda FP_A
        sec
        sbc FP_B
        sta FP_C
        lda FP_A+1
        sbc FP_B+1
        sta FP_C+1
        lda FP_A+2
        sbc FP_B+2
        sta FP_C+2
        lda FP_A+3
        sbc FP_B+3
        sta FP_C+3
        rts

fp_add:         ; FP_C = FP_A + FP_B
        lda FP_A
        clc
        adc FP_B
        sta FP_C
        lda FP_A+1
        adc FP_B+1
        sta FP_C+1
        lda FP_A+2
        adc FP_B+2
        sta FP_C+2
        lda FP_A+3
        adc FP_B+3
        sta FP_C+3
        rts

fp_multiply:    ; FP_C = FP_A * FP_A
        +FP_ABS FP_A, MATH_IN_A
        +FP_ABS FP_B, MATH_IN_B
        ; check and copy or negate result
        bit FP_A+3
        bmi +
        bit FP_B+3
        bmi ++
        bra +++
+       bit FP_B+3
        bmi +++
++      +FP_NEG MATH_MULTOUT+3, FP_C ; 64 bit result, negate shifted 3 byte
        rts
+++     +FP_MOV MATH_MULTOUT+3, FP_C ; 64 bit result, shifted 3 byte
        rts

; special, because we do not need to care about the sign for the result
fp_square:      ; FP_C = FP_A * FP_A
        bit FP_A+3
        bpl +
        +FP_NEG FP_A, MATH_IN_A, MATH_IN_B      ; put negated (now positive) A into hwmult
        bra ++
+       +FP_MOV FP_A, MATH_IN_A, MATH_IN_B     ; put A into hwmult
++      +FP_MOV MATH_MULTOUT+3, FP_C            ; 64 bit result, 16.48, fetch 8.24 from it
        rts

fp_divide:      ; FP_C = FP_A / FP_B
        +FP_ABS FP_A, MATH_IN_A
        +FP_ABS FP_B, MATH_IN_B
        ; delay until result is ready (16 cycles)
        lda MATH_DIVOUT
        lda MATH_DIVOUT ; wait 16 cycles
        lda MATH_DIVOUT ; perhaps one less? count cycles...
        bit FP_A+3
        bmi +
        bit FP_B+3
        bmi ++
        bra +++
+       bit FP_B+3
        bmi +++
++      +FP_NEG MATH_DIVOUT+1, FP_C ; 64 bit result, 32.32, fetch 8.24 from it, negate
        rts
+++     +FP_MOV MATH_DIVOUT+1, FP_C ; 64 bit result, 32.32, fetch 8.24 from it
        rts
