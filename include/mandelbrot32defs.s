#importonce
.cpu _45gs02

/*
 * we are using 32bit fixed point intergers
 * with a 4.28 setup (-8 to +7.99999999627471)
 */
.const MAND_WIDTH   = 320       // this is val>>6 / 5 (5*2**5)
.const MAND_HEIGHT  = 200       // this is val>>3 / 5 / 5 (25*2**3)
.const MAND_MAXITER = 48

/*
 * we need some 32 bit base page variables
 *
 * this is our constant we will use in each iteration
 * we need the start value, an increment per pixel and a current value
 *
 * screen extend in complex numbers
 */
.const mand_rs    = $20    // start real
.const mand_is    = $24    // start imag
.const mand_re    = $28    // end real
.const mand_ie    = $2c    // end imag

// current c and increments
.const mand_cr    = $30    // current point real
.const mand_ci    = $34    // current point imag
.const mand_dr    = $38    // per pixel increment real
.const mand_di    = $3c    // per pixel increment imag

// iteration vars z, zr³, zi², zrtemp
.const mand_zr    = $40    // iteration point real
.const mand_zi    = $44    // iteration point imag
.const mand_zr2   = $48    // zr²
.const mand_zi2   = $4c    // zi²
.const mand_zrtmp = $50    // temp var for real part
.const mand_iter  = $54    // iteration counter (1 byte)
.const mand_debugpos = $55 // current debug position
.const mand_debug = $58    // pointer to debug area

// graphic pointers
.const scrn_point = $10    // start of one row (32b pointer)
.const scrn_row   = $14    // current pixel (word)
.const scrn_x     = $16    // word x pos 0-319
.const scrn_y     = $18    // byte y pos 0-199

/*
 * DEBUGGING MACROS
 *
 * to write iteration values in some memory area
 */

.var DEBUG = 0

.macro DEBUG_INIT(val) {
    .if (DEBUG==1) {
        lda #<val
        sta mand_debug
        lda #>val
        sta mand_debug+1
        lda #0
        sta mand_debugpos
    }
}

.macro DEBUG_VAL(addr) {
    .if (DEBUG==1) {
        ldz mand_debugpos
        lda addr
        sta (mand_debug),z
        inz
        lda addr+1
        sta (mand_debug),z
        inz
        lda addr+2
        sta (mand_debug),z
        inz
        lda addr+3
        sta (mand_debug),z
        inz
        stz mand_debugpos
    }
}

.macro DEBUG_LOOP() {
    .if (DEBUG==1) {
        lda mand_debugpos
        clc
        adc mand_debug
        sta mand_debug
        lda #0
        adc mand_debug+1
        sta mand_debug+1
        lda #0
        sta mand_debugpos
    }
}
