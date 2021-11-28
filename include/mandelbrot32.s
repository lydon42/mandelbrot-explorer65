.cpu _45gs02
#import "mandelbrot32defs.s"
#import "fixedpt32defs.s"
#import "fixedpt32.s"

/*
 * MEGA65 Mandelbrot
 *
 * Uses Hardware Math accelerator with 8.24 bit fractional numbers
 */

// global start coordinates

mand_base_r0: .byte $67, $66, $a6, $fd  // rs=-2.35
mand_base_r1: .byte $00, $00, $40, $01  // re=+1.25
mand_base_i0: .byte $00, $00, $e0, $fe  // is=-1.125
mand_base_i1: .byte $00, $00, $20, $01  // ie=+1.125

// mand_init: initialize 
mb_init:
        /* Calculates dx and dy from min/max coordinates
         *
         * mand_dr = (mand_base_r1 - mand_base_r0) / 320 (loose the rest..., ugly!)
         */
        FP_MOV(mand_base_r1, FP_A)
        FP_MOV(mand_base_r0, FP_B)
        FP_SUB()                  // base_r1 - base_r0 -> FP_C
        FP_MOV(FP_C, FP_A)        // FP_C -> FP_A
        FP_SR_X(FP_A, 6)          // FP_A >> 6  (divide by 64)
        FP_STOR_II(5, FP_B)       // we can't divide by 320, because we only have 8 bit
        jsr fp_divide             // (base_r1 - base_r0) / 64 / 5 -> FP_C
        FP_MOV(FP_C, mand_dr)
        /*
         * mand_di = (mand_base_i1 - mand_base_i0) / 200 (loose the rest..., ugly!)
         */
        FP_MOV(mand_base_i1, FP_A)
        FP_MOV(mand_base_i0, FP_B)
        FP_SUB()                  // base_i1 - base_i0 -> FP_C
        FP_MOV(FP_C, FP_A)        // FP_C -> FP_A
        FP_SR_X(FP_A, 3)          // FP_A >> 3  (divide by 8)
        FP_STOR_II(5, FP_B)       // 5.0 -> FP_B
        jsr fp_divide             // (base_i1 - base_i0) / 8 / 5 -> FP_C
        FP_MOV(FP_C, FP_A)        // FP_C -> FP_A, FP_B still 5.0
        jsr fp_divide             // (base_i1 - base_i0) / 8 / 5 / 5 -> FP_C
        FP_MOV(FP_C, mand_di)
        
        rts

mb_iter:
        /* algo:
         *
         *   zr = cr
         *   zi = ci
         *   iter = max_iter-1
         *   do until zr² + zi² > 4
         *     zr' = zr² - zi² + cr
         *     zi' = zr*zi + ci
         *     iter--
         *   loop while iter > 0
         *   return iter
         */
        DEBUG_INIT($4000)
        lda #MAND_MAXITER-1             // we decrement iterations, because it's easier to check if done
        sta mand_iter
        FP_MOV(mand_cr, mand_zr)
        FP_MOV(mand_ci, mand_zi)        // first iteration done! that was fast!
loopiter:
        DEBUG_VAL(mand_zr)
        DEBUG_VAL(mand_zi)
        FP_MOV(mand_zi, FP_A)
        FP_SQUARE()
        DEBUG_VAL(FP_C)
        FP_MOV(FP_C, FP_B)              // FP_B = zi²
        FP_MOV(mand_zr, FP_A)
        FP_SQUARE()
        DEBUG_VAL(FP_C)
        FP_MOV(FP_C, FP_A)              // FP_A = zr²
        FP_ADD()                        // FP_C = FP_A(zr²) + FP_B(zi²)
        DEBUG_VAL(FP_C)
        lda FP_C+3
        cmp #4                          // FP_C[3] > 4?
        bcc !cont+
        jmp enditer                     // we can stop here
!cont:  FP_SUB()                        // FP_C = FP_A(zr²) - FP_B(zi²)
        DEBUG_VAL(FP_C)
        FP_MOV(FP_C, FP_A)
        FP_MOV(mand_cr, FP_B)
        FP_ADD()                        // FP_C(zr') = zr² - zi² + cr
        FP_MOV(mand_zr, FP_A)
        FP_MOV(mand_zi, FP_B)           // preload next op, so we can save zr
        FP_MOV(FP_C, mand_zr)           // zr' = FP_C
        FP_MULTIPLY()                   // FP_C = zr*zi
        DEBUG_VAL(FP_C)
        FP_SL_X(FP_C, 1)                // FP_C << 1 (*2)
        DEBUG_VAL(FP_C)
        FP_MOV(FP_C, FP_A)
        FP_MOV(mand_ci, FP_B)
        FP_ADD()                        // FP_C = 2*zr*zi+ci
        FP_MOV(FP_C, mand_zi)           // zi' = FP_C
        dec mand_iter
        beq enditer

        DEBUG_LOOP()

        jmp loopiter

enditer:
        rts
