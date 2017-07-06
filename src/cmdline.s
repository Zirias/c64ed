.include "numconv.inc"
.include "buffer.inc"
.include "text80.inc"
.include "kbinput.inc"

.export prompt
.export readline
.export readnumber
.export getij
.export getijabs

.exportzp line
.exportzp V_C
.exportzp V_I
.exportzp V_J

.segment "ZPLOW": zeropage
V_C:            .res    1
V_P:            .res    1
V_I:            .res    1
V_J:            .res    1
V_OFF_I:        .res    1
V_OFF_J:        .res    1
GIJ_OFF:        .res    1
RL_ROWTMP:      .res    1
RL_COLTMP:      .res    1
RL_BASECOL:     .res    1
RL_BASEROW:     .res    1
RL_DONE:        .res    1

.segment "ZPHIGH": zeropage
line:           .res    $51             ; 81 character input buffer

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
numprompt:      lda     V_Y
                jsr     numout
                lda     #','
                jsr     t80_chrout
                lda     V_X
                jsr     numout
promptend:      lda     #'>'
                jsr     t80_chrout
                lda     #' '
                jmp     t80_chrout
                ; rts

readline:
                ldx     T80_COL
                stx     RL_BASECOL
                ldx     T80_ROW
                stx     RL_BASEROW
                ldy     #0
                sty     V_C
                sty     V_P
                sty     RL_DONE
readinput:      ldy     RL_DONE
                beq     rl_in
                lda     #KBC_ENTER
                jsr     t80_chrout
                rts
rl_in:          jsr     kb_in
                bcs     readinput
                bvs     ctrlinput

                ; insert
                ldy     V_C
                cpy     #$50
                beq     readinput
rl_instloop:    cpy     V_P
                beq     rl_inst
                ldx     line-1,y
                stx     line,y
                dey
                bpl     rl_instloop

rl_inst:        jsr     t80_chrout
                ldx     T80_ROW
                stx     RL_ROWTMP
                ldx     T80_COL
                stx     RL_COLTMP
                bne     rl_noscr0
                ldx     T80_ROW
                cpx     RL_BASEROW
                bne     rl_noscr0
                dec     RL_BASEROW
rl_noscr0:      sta     line,y
                iny
                sty     V_P
                inc     V_C
rl_instoutloop: cpy     V_C
                beq     rl_instdone
                lda     line,y
                jsr     t80_chrout
                lda     T80_COL
                bne     rl_noscr
                lda     #24
                cmp     RL_ROWTMP
                bne     rl_noscr
                cmp     T80_ROW
                bne     rl_noscr
                dec     RL_ROWTMP
                dec     RL_BASEROW
rl_noscr:       iny
                bpl     rl_instoutloop
rl_instdone:    ldx     RL_ROWTMP
                stx     T80_ROW
                ldx     RL_COLTMP
                stx     T80_COL
                jsr     t80_setcrsr
                bpl     readinput

ctrlinput:      cmp     #KBC_ENTER
                bne     ci_noreturn
                inc     RL_DONE
                bne     ci_end
ci_noreturn:    cmp     #KBC_RIGHT
                bne     ci_noright
                ldx     V_P
                cpx     V_C
                beq     readinput
                inc     V_P
                bpl     rl_adjpos
ci_noright:     cmp     #KBC_LEFT
                bne     ci_noleft
                ldx     V_P
                beq     rl_jmpback1
                dec     V_P
                bpl     rl_adjpos
ci_noleft:      cmp     #KBC_HOME
                bne     ci_nopos1
                ldx     #0
                stx     V_P
                bpl     rl_adjpos
ci_nopos1:      cmp     #KBC_CLEAR
                bne     ci_noend
ci_end:         ldx     V_C
                stx     V_P
rl_adjpos:      ldx     RL_BASEROW
                stx     T80_ROW
                clc
                lda     RL_BASECOL
                adc     V_P
                cmp     #80
                sta     T80_COL
                bcc     rlap_setcrsr
                sbc     #80
                sta     T80_COL
                inc     T80_ROW
rlap_setcrsr:   jsr     t80_setcrsr
rl_jmpback1:    jmp     readinput
ci_noend:       cmp     #KBC_BACKSPACE
                bne     rl_jmpback1
                ldy     V_P
                beq     rl_jmpback1
                dey
                dec     V_C
                sty     V_P
bs_mvloop:      cpy     V_C
                beq     bs_mvdone
                ldx     line+1,y
                stx     line,y
                iny
                bpl     bs_mvloop
bs_mvdone:      jsr     t80_chrout
                ldx     T80_ROW
                stx     RL_ROWTMP
                ldx     T80_COL
                stx     RL_COLTMP
                ldy     V_P
bs_outloop:     cpy     V_C
                beq     bs_done
                lda     line,y
                jsr     t80_chrout
                iny
                bpl     bs_outloop
bs_done:        lda     #' '
                jsr     t80_chrout
                ldx     RL_ROWTMP
                stx     T80_ROW
                ldx     RL_COLTMP
                stx     T80_COL
                jsr     t80_setcrsr
                jmp     readinput

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

