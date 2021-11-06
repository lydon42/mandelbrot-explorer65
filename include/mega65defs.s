#importonce

.const M65_SCREEN_BANK = 0
.const M65_COLRAM_BANK = 1

// DMA

.const DMA_COPY  = %00000000
.const DMA_MIX   = %00000001
.const DMA_SWAP  = %00000010
.const DMA_FILL  = %00000011
.const DMA_CHAIN = %00000100

.const DMA_ADDRLSB_TRIG  = $d700
.const DMA_ADDRMSB       = $d701
.const DMA_ADDRBANK      = $d702
.const DMA_CONTROL       = $d703 // bit 1 = Enable F018b mode
.const DMA_ADDRLSB_ETRIG = $d705 // LSB for MEGA65 DMA Extensions
.const M65_SCREEN        = $0800
.const M65_COLRAM        = $f800

// VIC-III

// VICIII_ROMMAP bits
.const VICIII_ROM_E000   = $80
.const VICIII_ROM_C65CHR = $40
.const VICIII_ROM_C000   = $20
.const VICIII_ROM_A000   = $10
.const VICIII_ROM_8000   = $08
.const VICIII_ROM_PAL16  = $04
.const VICIII_ROM_EXTSYN = $02
.const VICIII_ROM_CRAM2K = $01

// VICIII_SCRNMODE bits
.const VICIII_SM_H640    = $80
.const VICIII_SM_FAST    = $40
.const VICIII_SM_ATTR    = $20
.const VICIII_SM_BPM     = $10
.const VICIII_SM_V400    = $08
.const VICIII_SM_H1280   = $04
.const VICIII_SM_MONO    = $02
.const VICIII_SM_INT     = $01

.const VICIII_ROMMAP    = $D030     // ROME CROM9 ROMC ROMA ROM8 PAL   EXTSYNC CRAM2K
.const VICIII_SCRNMODE  = $D031     // H640 FAST  ATTR BPM  V400 H1280 MONO    INT
.const VICIII_PALRED    = $D100
.const VICIII_PALGRN    = $D200
.const VICIII_PALBLU    = $D300

// VIC-IV

// VICIV_SCRNMODE bits
.const VICIV_SM_ALPHEN  = $80
.const VICIV_SM_VFAST   = $40
.const VICIV_SM_PALEMU  = $20
.const VICIV_SM_SPR640  = $10
.const VICIV_SM_SMTH    = $08
.const VICIV_SM_FCLRHI  = $04
.const VIVIV_SM_FCLRLO  = $02
.const VICIV_SM_CHR16   = $01

.const VICIV_BORDERCOL  = $D020
.const VICIV_SCREENCOL  = $D021
.const VICIV_KEY        = $D02F
.const VICIV_SCRNMODE   = $D054     // ALPHEN VFAST PALEMU SPR640 SMTH FCLRHI FCLRLO CHR16
.const VICIV_LINESTEPLO = $D058
.const VICIV_LINESTEPHI = $D059
.const VICIV_CHRCOUNT   = $D05E     // how many characters to draw
.const VICIV_SCRNPTR1   = $D060
.const VICIV_SCRNPTR2   = $D061
.const VICIV_SCRNPTR3   = $D062
.const VICIV_SCRNPTR4   = $D063     // EXGLYPH(1), EMPTY(1), CHRCOUNT(2), SCRNPTR(4)
.const VICIV_COLPTRLO   = $D064
.const VICIV_COLPTRHI   = $D065
.const VICIV_CHARPTRLO  = $D068
.const VICIV_CHARPTRHI  = $D069
.const VICIV_CHARPTRBN  = $D06A
.const VICIV_PALETTE    = $D070     // MAPEDPAL(2) BTPALSEL(2) SPRPALSEL(2) ABTPALSEL(2)

// C65 4551 UART
.const UART_ASCIIKEY    = $D610     // hardware accelerated keyboard scanner

// MATH ACCL
.const MATH_BUSY    = $D70F
.const MATH_IN_A    = $D770
.const MATH_IN_B    = $D774
.const MATH_MULTOUT = $D778
.const MATH_DIVOUT  = $D768
