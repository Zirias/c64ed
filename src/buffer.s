.include "defs.inc"

.export linepointer
.export linesdown
.export linesup
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

linesdown:
                ldx     V_R
                inx
                stx     V_R
ld_loop:        stx     ld_x
                lda     #>cpl_dst
                ldy     #<cpl_dst
                jsr     linepointer
ld_x            = *+1
                ldx     #$ff
                dex
                stx     ld_x2
                cpx     V_Y
                bpl     ld_currline
                lda     #>cpl_src
                ldy     #<cpl_src
                jsr     linepointer
                jsr     copyline
ld_x2           = *+1
                ldx     #$ff
                bpl     ld_loop
ld_currline:    lda     cpl_dst
                sta     ld_tgt
                sta     ld_cols
                lda     cpl_dst+1
                sta     ld_tgt+1
                sta     ld_cols+1
                ldy     #0
                lda     (V_LP),y
                sta     ld_y
                dec     V_X
                sec
                sbc     V_X
                pha
                lda     V_X
                sta     (V_LP),y
                pla
                tax
ld_cols         = *+1
                stx     $ffff
                beq     ld_emptyline
ld_y            = *+1
                ldy     #$ff
ld_lineloop:    lda     (V_LP),y
ld_tgt          = *+1
                sta     $ffff,x
                dey
                dex
                bne     ld_lineloop
ld_emptyline:   ldx     #1
                stx     V_X
                ldx     V_Y
                inx
                stx     V_Y
                rts

linesup:
                ldx     V_Y
                cpx     V_R
                beq     lu_done
                inx
                lda     #>lu_src
                ldy     #<lu_src
                jsr     linepointer
                lda     lu_src
                sta     lu_srccols
                lda     lu_src+1
                sta     lu_srccols+1
                ldy     #0
                lda     (V_LP),y
lu_srccols      = *+1
                ldx     $ffff
                beq     lu_emptyline
                stx     lu_x
                clc
lu_x            = *+1
                adc     #$ff
                sta     (V_LP),y
                tay
lu_src          = *+1
lu_lineloop:    lda     $ffff,x
                sta     (V_LP),y
                dey
                dex
                bne     lu_lineloop
lu_emptyline:   ldx     V_Y
                inx
lu_loop:        cpx     V_R
                beq     lu_decrows
                stx     lu_x2
                lda     #>cpl_dst
                ldy     #<cpl_dst
                jsr     linepointer
lu_x2           = *+1
                ldx     #$ff
                inx
                stx     lu_x3
                lda     #>cpl_src
                ldy     #<cpl_src
                jsr     linepointer
                jsr     copyline
lu_x3           = *+1
                ldx     #$ff
                bne     lu_loop
lu_decrows:     dec     V_R
lu_done:        rts

copyline:
                lda     cpl_src
                sta     cpl_len
                lda     cpl_src+1
                sta     cpl_len+1
cpl_len         = *+1
                ldx     $ffff
cpl_src         = *+1
cpl_loop:       lda     $ffff,x
cpl_dst         = *+1
                sta     $ffff,x
                dex
                bpl     cpl_loop
                rts

.data

index:          .byte   $00,$60,$c0,$21,$81,$e1,$42,$a2

.bss

lptemp:         .res    1               ; for calculating line pointer

.segment "BUF"

buffer:         .res    $ff * $60       ; text buffer, 255 lines of 95 chars

