.include "text80.inc"

.export numout
.export numclear
.export numtostring
.export stringtonum

.exportzp numberbuf

.segment "ZP": zeropage
V_MASK_NIBBLE:	.res	1
numberbuf:	.res	3

.segment "INIT"
                ldx     #$f0
                stx     V_MASK_NIBBLE

.code

numout:
                jsr     numtostring
                ldx     #0
no_loop:        lda     numberbuf,x
                beq     no_skip
                jsr     t80_chrout
no_skip:        inx
                cpx     #3
                bne     no_loop
                rts

numtostring:
		jsr	numclear
                ldx     #8
nts_bcdloop:    lda     numberbuf+2
                cmp     #5
                bmi     nts_noadd0
                adc     #2
                sta     numberbuf+2
nts_noadd0:     lda     numberbuf+1
                cmp     #5
                bmi     nts_noadd1
                adc     #2
                sta     numberbuf+1
nts_noadd1:     lda     numberbuf
                cmp     #5
                bmi     nts_noadd2
                adc     #2
                sta     numberbuf
nts_noadd2:     tya
                asl     a
                tay
                rol     numberbuf+2
                lda     numberbuf+2
                clc
                bit     V_MASK_NIBBLE
                beq     nts_rol2
                and     #$f
                sta     numberbuf+2
                sec
nts_rol2:       rol     numberbuf+1
                lda     numberbuf+1
                clc
                bit     V_MASK_NIBBLE
                beq     nts_rol3
                and     #$f
                sta     numberbuf+1
                sec
nts_rol3:       rol     numberbuf
                dex
                bne     nts_bcdloop

                lda     numberbuf+2
                ora     #$30
                sta     numberbuf+2
                lda     numberbuf+1
                beq     nts_done
                ora     #$30
                sta     numberbuf+1
                lda     numberbuf
                beq     nts_done
                ora     #$30
                sta     numberbuf
nts_done:       rts

stringtonum:
		lda	numberbuf+2
		bne	stn_check0
		lda	numberbuf+1
		sta	numberbuf+2
		lda	numberbuf
		sta	numberbuf+1
		lda	#0
		sta	numberbuf
		lda	numberbuf+2
		bne	stn_check0
		lda	numberbuf+1
		sta	numberbuf+2
		lda	#0
		sta	numberbuf+1
		lda	numberbuf+2
stn_check0:	beq	stn_done
		and	#$cf
		sta	numberbuf+2
		lda	numberbuf+1
		and	#$cf
		sta	numberbuf+1
		lda	numberbuf
		and	#$cf
		sta	numberbuf
		ldy	#0
		ldx	#8
stn_loop:	lsr	numberbuf
		bcc	stn_noc0
		lda	numberbuf+1
		ora	#$10
		sta	numberbuf+1
stn_noc0:	lsr	numberbuf+1
		bcc	stn_noc1
		lda	numberbuf+2
		ora	#$10
		sta	numberbuf+2
stn_noc1:	lsr	numberbuf+2
		tya
		ror	a
		tay
		dex
		bne	stn_sub
stn_done:	rts
stn_sub:	lda	numberbuf+2
		cmp	#8
		bmi	stn_nosub0
		sbc	#3
		sta	numberbuf+2
stn_nosub0:	lda	numberbuf+1
		cmp	#8
		bmi	stn_nosub1
		sbc	#3
		sta	numberbuf+1
stn_nosub1:	lda	numberbuf
		cmp	#8
		bmi	stn_loop
		sta	numberbuf
		bpl	stn_loop

numclear:
                lda     #0
                sta     numberbuf
                sta     numberbuf+1
                sta     numberbuf+2
		rts

