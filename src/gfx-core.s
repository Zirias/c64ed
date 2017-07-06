;
; basic gfx-functions and global variables
;

.include "vic.inc"
.include "vicconfig.inc"

.export gfx_on
.export gfx_off
.export gfx_setcolor
.export gfx_clear

.segment "ZPLOW": zeropage
TMP_0:          .res    1
TMP_1:          .res    1

.code

gfx_on:
                lda     VIC_CTL1
                ora     #%00100000
                sta     VIC_CTL1
                lda     #vic_memctl_hires
                sta     VIC_MEMCTL
                rts

gfx_off:
                lda     VIC_CTL1
                and     #%11011111
                sta     VIC_CTL1
                lda     #vic_memctl_text
                sta     VIC_MEMCTL
                rts

gfx_setcolor:
                stx     TMP_0
                asl     a
                asl     a
                asl     a
                asl     a
                adc     TMP_0
                ldx     #>vic_colram
                stx     TMP_1
                ldy     #0
                sty     TMP_0
                ldx     #$04
sc_loop:        sta     (TMP_0),y
                iny
                bne     sc_loop
                inc     TMP_1
                dex
                bne     sc_loop
                rts

gfx_clear:
                lda     #0
                tay
                sta     TMP_0
                ldx     #>vic_bitmap
                stx     TMP_1
                ldx     #$1f
cl_loop:        sta     (TMP_0),y
                iny
                bne     cl_loop
                inc     TMP_1
                dex
                bne     cl_loop
                ldy     #$3f
cl_last:        sta     (TMP_0),y
                dey
                bpl     cl_last
                rts

; vim: et:si:ts=8:sts=8:sw=8
