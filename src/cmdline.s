.include "numconv.inc"
.include "buffer.inc"
.include "text80.inc"
.include "kbinput.inc"

.export prompt
.export readline
.export readnumber
.export getij
.export getijabs
.export line

.exportzp V_C
.exportzp V_I
.exportzp V_J

.segment "ZP": zeropage
V_MASK_PRINT:	.res	1
V_C:		.res	1
V_I:		.res	1
V_J:		.res	1
V_OFF_I:	.res	1
V_OFF_J:	.res	1
GIJ_OFF:	.res	1

.segment "INIT"

                ldx     #$60
                stx     V_MASK_PRINT

.code

prompt:
                lda     V_Y
                cmp     V_R
                bcc     numprompt
                ldy     #0
                lda     (V_LP),y
                cmp     V_X
                bpl     numprompt
                lda     #'e'
                jsr     t80_chrout
                lda     #'n'
                jsr     t80_chrout
                lda     #'d'
                jsr     t80_chrout
                bcc     promptend
numprompt:      ldy     V_Y
                jsr     numout
                lda     #','
                jsr     t80_chrout
                ldy     V_X
                jsr     numout
promptend:      lda     #'>'
                jsr     t80_chrout
                lda     #' '
                jmp     t80_chrout
		; rts

readline:
                ldx     #0
                stx     V_C
readinput:      jsr     kb_in
                beq     readinput
                bit     V_MASK_PRINT
                beq     ctrlinput
                ldx     V_C
                cpx     #$50
                beq     readinput
                jsr     t80_chrout
                sta     line,x
                inx
                stx     V_C
                bpl     readinput
ctrlinput:      cmp     #KBC_ENTER
                bne     ci_noreturn
                jsr     t80_chrout
                lda     #0
                ldx     V_C
                sta     line,x
		rts
ci_noreturn:    cmp     #KBC_BACKSPACE
                bne     readinput
                ldx     V_C
                beq     readinput
                jsr     t80_chrout
                dex
                stx     V_C
                bpl     readinput

readnumber:
                sta     rn_offdst1
                sta     rn_offdst2
                jsr     numclear
                ldy     #0
                lda     line,x
                beq     rn_done
                cmp     #'+'
                bne     rn_noplus
                lda     #1
rn_offdst1      = *+1
                sta     $ff
                inx
                bne     rn_nooff
rn_noplus:      cmp     #'-'
                bne     rn_nominus
                lda     #$ff
rn_offdst2      = *+1
                sta     $ff
                inx
rn_nooff:       lda     line,x
rn_nominus:     beq     rn_done
                cmp     #$30
                bmi     rn_done
                cmp     #$3a
                bpl     rn_done
                sta     numberbuf,y
                inx
                iny
                cpy     #3
                bpl     rn_done
                bmi     rn_nooff
rn_done:        rts

getij:
                stx     GIJ_OFF
                ldy     #0
                sty     V_OFF_I
                sty     V_OFF_J
                dey
                sty     V_I
                sty     V_J
                lda     #V_OFF_I
                jsr     readnumber
                cpx     GIJ_OFF
                beq     gij_comma
                stx     GIJ_OFF
                jsr     stringtonum
                sta     V_I
                ldx     GIJ_OFF
gij_comma:      lda     line,x
                cmp     #','
                bne     gij_done
                inx
                stx     GIJ_OFF
                lda     #V_OFF_J
                jsr     readnumber
                cpx     GIJ_OFF
                beq     gij_done
                jsr     stringtonum
                sta     V_J
gij_done:       rts

getijabs:
                jsr     getij
                lda     #1
                bit     V_OFF_I
                beq     gija_ydone
                bpl     gija_plusy
                lda     V_I
                cmp     V_Y
                bmi     gija_minusy
                lda     #1
                sta     V_I
                bne     gija_ydone
gija_minusy:    lda     V_Y
                sec
                sbc     V_I
                sta     V_I
                bne     gija_ydone
gija_plusy:     lda     V_Y
                clc
                adc     V_I
                sta     V_I
                bcc     gija_ydone
                lda     #0
                sta     V_I
gija_ydone:     lda     #1
                bit     V_OFF_J
                beq     gija_done
                bpl     gija_plusx
                lda     V_J
                cmp     V_X
                bmi     gija_minusx
                lda     #1
                sta     V_J
                bne     gija_done
gija_minusx:    lda     V_X
                sec
                sbc     V_J
                sta     V_J
                bne     gija_done
gija_plusx:     lda     V_X
                clc
                adc     V_J
                sta     V_J
                bcc     gija_done
                lda     #0
                sta     V_J
gija_done:      rts

.bss

line:           .res    $52             ; 81 character input buffer

