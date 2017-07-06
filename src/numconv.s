.include "defs.inc"

number		= $14

.export numout
.export numclear
.export numberbuf
.export numtostring
.export stringtonum

.code

numout:
                jsr     numtostring
                ldx     #0
no_loop:        lda     numberbuf,x
                beq     no_skip
                jsr     CHROUT
no_skip:        inx
                cpx     #3
                bne     no_loop
                rts

numtostring:
		sta	number
		jsr	numclear
                ldx     #8
nts_bcdloop:	ldy	#2
nts_addloop:    lda     numberbuf,y
                cmp     #5
                bmi     nts_noadd
                adc     #2
                sta     numberbuf,y
nts_noadd:	dey
		bpl	nts_addloop
nts_noadd2:     ldy	#2
		lda	number
                asl     a
                sta	number
nts_rolloop:    lda     numberbuf,y
		rol	a
		cmp	#$10		; C=1 when bit 4 is set
                and     #$f
		sta     numberbuf,y
nts_rolnext:	dey
		bpl	nts_rolloop
                dex
                bne     nts_bcdloop

                lda     numberbuf+2
                ora     #$30
                sta     numberbuf+2
		ldy	#1
nts_tochrloop:  lda     numberbuf,y
                beq     nts_done
                ora     #$30
                sta     numberbuf,y
		dey
		bpl	nts_tochrloop
nts_done:       rts

stringtonum:
		lda	numberbuf+2
		bne	stn_start
		lda	numberbuf+1
		sta	numberbuf+2
		lda	numberbuf
		sta	numberbuf+1
		lda	#0
		sta	numberbuf
		beq	stringtonum
stn_start:	ldy	#2
stn_tonumloop:	lda	numberbuf,y
		beq	stn_skip0
		and	#$cf
		sta	numberbuf,y
stn_skip0:	dey
		bpl	stn_tonumloop

		ldx	#8
stn_loop:	ldy	#$7d
		clc
stn_rorloop:	lda	numberbuf-$7d,y
		bcc	stn_skipbit
		ora	#$10
stn_skipbit:	lsr	a
		sta	numberbuf-$7d,y
		iny
		bpl	stn_rorloop
		lda	number
		ror	a
		dex
		bne	stn_sub
stn_done:	rts
stn_sub:	sta	number
		ldy	#2
stn_subloop:	lda	numberbuf,y
		cmp	#8
		bmi	stn_nosub
		sbc	#3
		sta	numberbuf,y
stn_nosub:	dey
		bpl	stn_subloop
		bmi	stn_loop

numclear:
                lda     #0
                sta     numberbuf
                sta     numberbuf+1
                sta     numberbuf+2
		rts

.bss

numberbuf:      .res    3               ; buffer for converting numbers

