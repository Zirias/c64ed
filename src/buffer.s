.export linepointer
.export linesdown
.export linesup
.export buffer

.exportzp V_R
.exportzp V_Y
.exportzp V_X
.exportzp V_LP

.segment "ZPLOW": zeropage
V_R:		.res	1
V_Y:		.res	1
V_X:		.res	1
V_LP:		.res	2
V_TLPDST:	.res	2
V_TLPSRC:	.res	2
lptemp:         .res    1               ; for calculating line pointer
temp:		.res	1

.code

linepointer:
                sty     lp_low
                iny
                sty     lp_high
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
lp_high         = *+1
                sta     $ff
                lda     index,y
                and     #$f0
lp_low          = *+1       
                sta     $ff
                rts

linesdown:
                ldx     V_R
                inx
                stx     V_R
ld_loop:        stx     temp
                ldy     #V_TLPDST
                jsr     linepointer
                dec     temp
                ldx	temp
                cpx     V_Y
                beq     ld_currline
                bmi     ld_currline
                ldy     #V_TLPSRC
                jsr     linepointer
                jsr     copyline
                ldx     temp
                bpl     ld_loop
ld_currline:    lda     V_TLPDST
                sta     ld_tgt
                lda     V_TLPDST+1
                sta     ld_tgt+1
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
ld_cols         = *+1
		ldy	#0
                sta     (V_TLPDST),y
                tax
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
		cpx	V_R
		beq	ld_done
                inx
                stx     V_Y
ld_done:        rts

linesup:
                ldx     V_Y
                cpx     V_R
                beq     lu_done
                inx
                ldy     #V_TLPSRC
                jsr     linepointer
                lda     V_TLPSRC
                sta     lu_src
                lda     V_TLPSRC+1
                sta     lu_src+1
                ldy     #0
                lda     (V_TLPSRC),y
                beq     lu_emptyline
		tax
                lda     (V_LP),y
                stx     temp
                clc
                adc     temp
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
                stx     temp
lu_loop:        cpx     V_R
                beq     lu_decrows
                ldy     #V_TLPDST
                jsr     linepointer
		inc	temp
		ldx	temp
                ldy     #V_TLPSRC
                jsr     linepointer
                jsr     copyline
                ldx     temp
                bne     lu_loop
lu_decrows:     dec     V_R
lu_done:        rts

copyline:
		ldy	#0
                lda     (V_TLPSRC),y
		tay
cpl_loop:       lda     (V_TLPSRC),y
                sta     (V_TLPDST),y
                dey
                bpl     cpl_loop
                rts

.data

index:          .byte   $00,$60,$c0,$21,$81,$e1,$42,$a2

.segment "BUF"

buffer:         .res    $ff * $60       ; text buffer, 255 lines of 95 chars

