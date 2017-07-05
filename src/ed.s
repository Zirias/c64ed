.include "buffer.inc"
.include "cmdline.inc"
.include "text80.inc"
.include "petscii_lc.inc"

.export ed

.segment "ZPLOW": zeropage

ARGLEN:         .res 1          ; length of argument to command
PL_BASE:        .res 2
INST_BASE:      .res 2

.code

ed:
                ldx     #1
                stx     V_X
                stx     V_Y
                dex
                stx     buffer
                stx     V_R

mainloop:       ldx     V_Y
                ldy     #V_LP
                jsr     linepointer
                jsr     prompt
                jsr     readline
                
                ldx     V_C
                beq     cmd_enter
                dex
                dex
                bpl     pl_cntplus
                ldx     #0
pl_cntplus:     stx     ARGLEN
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
                cmp     #'q'
                bne     cmd_focus
                rts

                ; focus position command:
cmd_focus:      ldx     #0
                jsr     getijabs
                lda     V_I
pl_pos:         ldx     V_R
                cpx     #0
                beq     mainloop
                jsr     adjustrange
                cmp     #$ff
                beq     pl_noypos
                sta     V_Y
                tax
                ldy     #V_LP
                jsr     linepointer
pl_noypos:      ldy     #0
                lda     (V_LP),y
                tax
                inx
                lda     V_J
                cmp     #$ff
                bne     pl_xpos
                lda     V_X
pl_xpos:        jsr     adjustrange
                sta     V_X
                bpl     mainloop

cmd_enter:
                jsr     linesdown
                bpl     jmpmain

cmd_e:
                lda     #0
                sta     V_J
                beq     pl_pos

cmd_b:
                lda     #1
                sta     V_J
                bne     pl_pos

cmd_L:
                jmp     cL

cmd_l:
                ldx     V_Y
                jsr     printline
                bvc     jmpmain

cmd_p:
                beq     cp

cmd_A:          
                ldx     V_R
                inx
                stx     V_R
                stx     V_Y
                ldy     #V_LP
                jsr     linepointer
                lda     #0
                tay
                sta     (V_LP),y
                iny
                sty     V_X
                jsr     insertat
                bpl     jmpmain

cmd_i:
                beq     ci

cmd_r:
                beq     cr

cmd_I:
                jsr     insertat
                bpl     jmpmain

cmd_d:
                beq     cd

cmd_j:
                jsr     linesup
jmpmain:        jmp     mainloop

cp:
                ldx     V_R
                beq     jmpmain
                ldx     #1
                stx     V_I
                dex
                stx     V_J
                ldx     #2
                lda     ARGLEN
                beq     cp_noargs
                jsr     getij
cp_noargs:      lda     V_I
                ldx     V_R
                jsr     adjustrange
                cmp     #$ff
                bne     cp_havestart
                lda     #1
cp_havestart:   sta     V_I
                ldx     V_R
                lda     V_J
                cmp     #$ff
                bne     cp_haveend
                lda     #0
cp_haveend:     jsr     adjustrange
                sta     cp_cmpx
                ldx     V_I
cp_loop:        jsr     printline
                ldx     V_I
cp_cmpx         = *+1
                cpx     #$ff
                beq     jmpmain
                inx
                stx     V_I
                bne     cp_loop

ci:
                jsr     linesdown
                dec     V_Y
                ldy     #0
                lda     (V_LP),y
                sta     V_X
                inc     V_X
                jsr     insertat
                inc     V_Y
                ldx     #1
                stx     V_X
                bne     jmpmain

cr:
                ldy     #0
                ldx     V_X
                dex
                txa
                sta     (V_LP),y
                jsr     insertat
                ldx     V_R
                cpx     V_Y
                beq     jmpmain2
                inc     V_Y
                ldx     #1
                stx     V_X
                bne     jmpmain2

cd:
                ldy     #0
                cpy     V_R
                beq     jmpmain2
                lda     (V_LP),y
                bne     cd_clearline
                lda     V_Y
                cmp     V_R
                bne     cd_linesup
                dec     V_Y
                iny
                sty     V_X
cd_linesup:     jsr     linesup
                ldy     #1
                cpy     V_Y
                bmi     jmpmain2
                sty     V_Y
                bpl     jmpmain2
cd_clearline:   tya
                sta     (V_LP),y
                iny
                sty     V_X
                bne     jmpmain2

cL:
                ldx     V_R
                beq     jmpmain2
                ldx     V_Y
                ldy     #3
                dex
                beq     cL_loop
                iny
                dex
                beq     cL_loop
                iny
                dex
cL_loop:        inx
                sty     cL_y
                stx     cL_x
                cpx     V_Y
                beq     cL_currline
                lda     #' '
                jsr     t80_chrout
                bne     cL_lineout
cL_currline:    lda     #'>'
                jsr     t80_chrout
cL_lineout:     jsr     printline
cL_y            = *+1
                ldy     #$ff
cL_x            = *+1
                ldx     #$ff
                dey
                beq     cL_colmark
                cpx     V_R
                bne     cL_loop
cL_colmark:     lda     #' '
                ldx     V_X
cL_colloop:     jsr     t80_chrout
                dex
                bne     cL_colloop
                lda     #$26            ; ^
                jsr     t80_chrout
                lda     #$d
                jsr     t80_chrout
jmpmain2:       jmp     mainloop

printline:
                ldy     #PL_BASE
                jsr     linepointer
                ldy     #0
                lda     (PL_BASE),y
                beq     pl_empty
                sta     pl_cmp
                inc     PL_BASE
pl_loop:        lda     (PL_BASE),y
                jsr     t80_chrout
                iny
pl_cmp          = *+1
                cpy     #$ff
                bne     pl_loop
pl_empty:       lda     #$d
                jmp     t80_chrout
                ; rts

insertat:
                lda     V_LP
                clc
                adc     V_X
                sta     PL_BASE
                lda     V_LP+1
                adc     #0
                sta     PL_BASE+1
                lda     PL_BASE
                adc     ARGLEN
                sta     INST_BASE
                lda     PL_BASE+1
                adc     #0
                sta     INST_BASE+1
                ldy     #0
                lda     (V_LP),y
                sec
                sbc     V_X
                bmi     ia_nomove
                tay
ia_moveloop:    lda     (PL_BASE),y
                sta     (INST_BASE),y
                dey
                bpl     ia_moveloop
ia_nomove:      ldy     ARGLEN
                dey
                bpl     ia_insert
                rts
ia_insert:      lda     line+2,y
                sta     (PL_BASE),y
                dey
                bpl     ia_insert
                ldy     #0
                lda     (V_LP),y
                clc
                adc     ARGLEN
                sta     (V_LP),y
                lda     V_X
                clc
                adc     ARGLEN
                sta     V_X
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

