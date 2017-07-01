.include "defs.inc"

.import linepointer
.import numout
.import numclear
.import numberbuf
.import stringtonum
.import buffer

V_C             = $02
V_MASK_PRINT	= $15
V_CURSOR        = $cc   ; cursor on/off
V_I             = $22
V_J             = $23
V_OFF_I         = $19
V_OFF_J         = $20

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
                inx
                ldx     #$60
                stx     V_MASK_PRINT
                ldx     #$80
                stx     $291            ; disable SHIFT+C=
                ldx     #$17
                stx     $d018           ; lowercase textmode

.segment "MAIN"

mainloop:       ldx     V_Y
                lda     #0
                ldy     #V_LP
                jsr     linepointer
                
                ; prompt
                lda     V_Y
                cmp     V_R
                bcc     numprompt
                ldy     #0
                lda     (V_LP),y
                cmp     V_X
                bpl     numprompt
                lda     #'e'
                jsr     CHROUT
                lda     #'n'
                jsr     CHROUT
                lda     #'d'
                jsr     CHROUT
                bcc     promptend
numprompt:      ldy     V_Y
                jsr     numout
                lda     #','
                jsr     CHROUT
                ldy     V_X
                jsr     numout
promptend:      lda     #'>'
                jsr     CHROUT
                lda     #' '
                jsr     CHROUT

                ; read a line
                ldx     #0
                stx     V_C
                stx     V_CURSOR
readinput:      jsr     GETIN
                beq     readinput
                bit     V_MASK_PRINT
                beq     ctrlinput
                ldx     V_C
                cpx     #$1e
                beq     readinput
                jsr     CHROUT
                sta     line,x
                inx
                stx     V_C
                bpl     readinput
ctrlinput:      cmp     #$d             ; return
                bne     ci_noreturn
                lda     #0
                ldx     V_C
                sta     line,x
                inc     V_CURSOR
                lda     #$20            ; hack to cleanup cursor
                jsr     CHROUT
                lda     #$d
                jsr     CHROUT
                lda     #0
                bpl     parseline
ci_noreturn:    cmp     #$14            ; "backspace"
                bne     readinput
                ldx     V_C
                beq     readinput
                jsr     CHROUT
                dex
                stx     V_C
                bpl     readinput

parseline:
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
                ldx     V_R
                jsr     adjustrange
                cmp     #$ff
                beq     pl_noypos
                sta     V_Y
                lda     #0
                ldy     #V_LP
                jsr     linepointer
pl_noypos:      lda     (V_LP),y
                tax
                lda     V_J
                jsr     adjustrange
                cmp     #$ff
                beq     pl_noxpos
                sta     V_X
pl_noxpos:      jmp     mainloop

cmd_enter:
cmd_e:
cmd_b:
cmd_L:
cmd_l:
cmd_p:
cmd_A:
cmd_i:
cmd_r:
cmd_I:
cmd_d:
cmd_j:

getij:
                stx     gij_off
                ldy     #0
                sty     V_OFF_I
                sty     V_OFF_J
                dey
                sty     V_I
                sty     V_J
                lda     #V_OFF_I
                jsr     readnumber
gij_off         = *+1
                cpx     #$ff
                beq     gij_comma
                stx     gij_offc
                jsr     stringtonum
                sta     V_I
gij_offc        = *+1
                ldx     #$ff
gij_comma:      lda     line,x
                cmp     #','
                bne     gij_done
                inx
                stx     gij_offj
                lda     #V_OFF_J
                jsr     readnumber
gij_offj        = *+1
                cpx     #$ff
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

.bss

line:           .res    $20             ; 32 character input buffer
arglen:         .res    1               ; length of argument to command
