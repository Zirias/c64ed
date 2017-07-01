.include "defs.inc"

.export linepointer
.export buffer

.code

linepointer:
                sta     lp_low_h
                sta     lp_high_h
                sty     lp_low_l
                iny
                sty     lp_high_l
                dex
                txa
                and     #$7     ; lookup index for index values
                tay
                txa
                lsr     a
                lsr     a
                lsr     a
                tax
                lda     #0
                clc
lp_nexthigh:    dex
                bmi     lp_highdone
                adc     #$3
                bcc     lp_nexthigh
lp_highdone:    sta     lptemp
                lda     index,y
                and     #$3
                adc     lptemp
                adc     #>buffer
lp_high_l       = *+1
lp_high_h       = *+2
                sta     $ffff
                lda     index,y
                and     #$f0
lp_low_l        = *+1
lp_low_h        = *+2       
                sta     $ffff
                rts

.data

index:          .byte   $00,$60,$c0,$21,$81,$e1,$42,$a2

.bss

lptemp:         .res    1               ; for calculating line pointer

.segment "BUF"

buffer:         .res    $ff * $60       ; text buffer, 255 lines of 95 chars

