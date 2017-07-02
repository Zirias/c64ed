.include "defs.inc"

.import linepointer
.import buffer

.import prompt
.import readline
.import readnumber
.import getij
.import getijabs
.import line

.segment "LDADDR"
                .word   $c000

.segment "INIT"

                ldx     #$36
                stx     $1              ; disable BASIC rom
                ldx     #1
                stx     V_X
                stx     V_Y
                dex
                stx     buffer
                stx     buffer+1
                stx     V_R

.segment "MAIN"

mainloop:       ldx     V_Y
                lda     #0
                ldy     #V_LP
                jsr     linepointer
		jsr	prompt
		jsr	readline
                
                ldx     V_C
                beq     cmd_enter
                dex
                dex
                bpl     pl_cntplus
                ldx     #0
pl_cntplus:     stx     arglen
                lda     line
                cmp     #'e'
                beq     cmd_e
                cmp     #'b'
                beq     cmd_b
                cmp     #'L'
                beq     cmd_L
                cmp     #'l'
                beq     cmd_l
                cmp     #'p'
                beq     cmd_p
                cmp     #'A'
                beq     cmd_A
                cmp     #'i'
                beq     cmd_i
                cmp     #'r'
                beq     cmd_r
                cmp     #'I'
                beq     cmd_I
                cmp     #'d'
                beq     cmd_d
                cmp     #'j'
                beq     cmd_j

                ; focus position command:
                ldx     #0
                jsr     getijabs
                lda     V_I
pl_pos:         ldx     V_R
                jsr     adjustrange
                cmp     #$ff
                beq     pl_noypos
                sta     V_Y
		tax
                lda     #0
                ldy     #V_LP
                jsr     linepointer
pl_noypos:      ldy	#0
		lda     (V_LP),y
                tax
		inx
                lda     V_J
                cmp     #$ff
                bne     pl_xpos
		lda	V_X
pl_xpos:        jsr     adjustrange
                sta     V_X
		bpl     mainloop

cmd_enter:

cmd_e:
		lda	#0
		sta	V_J
		beq	pl_pos

cmd_b:
		lda	#1
		sta	V_J
		bne	pl_pos

cmd_L:
cmd_l:
cmd_p:
cmd_A:          
		ldx     V_R
                inx
                stx     V_R
                stx     V_Y
                lda     #0
                ldy     #V_LP
                jsr     linepointer
		lda	#0
		tay
		sta	(V_LP),y
		iny
		sty	V_X
		jsr	insertat
                jmp     mainloop

cmd_i:
cmd_r:
cmd_I:
cmd_d:
cmd_j:

insertat:
		lda	V_LP
		adc	V_X
		sta	ia_mvsrcbase
		sta	ia_instgtbase
		lda	V_LP+1
		adc	#0
		sta	ia_mvsrcbase+1
		sta	ia_instgtbase+1
		lda	ia_mvsrcbase
		adc	arglen
		sta	ia_mvdstbase
		lda	ia_mvsrcbase+1
		adc	#0
		sta	ia_mvdstbase+1
		ldy	#0
		lda	(V_LP),y
		sec
		sbc	V_X
		bmi	ia_nomove
		tax
		clc
ia_mvsrcbase	= *+1
ia_moveloop:	lda	$ffff,x
ia_mvdstbase	= *+1
		sta	$ffff,x
		dex
		bpl	ia_moveloop
ia_nomove:	ldx	arglen
		dex
		bpl	ia_insert
		rts
ia_insert:	lda	line+2,x
ia_instgtbase	= *+1
		sta	$ffff,x
		dex
		bpl	ia_insert
		ldy	#0
		lda	(V_LP),y
		clc
		adc	arglen
		sta	(V_LP),y
		lda	V_X
		sec
		adc	arglen
		sta	V_X
		rts

adjustrange:
                sta     ajr_compare
                cmp     #$ff
                beq     ajr_done
                cmp     #0
                beq     ajr_cap
ajr_compare     = *+1
ajr_doadjust:   cpx     #$ff
                bpl     ajr_done
ajr_cap:        txa
ajr_done:       rts

.bss

arglen:         .res    1               ; length of argument to command

