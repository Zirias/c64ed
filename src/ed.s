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
                jsr     prompt
                jsr     readline
                
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
                jmp     mainloop
cmd_p:
cmd_A:          
                ldx     V_R
                inx
                stx     V_R
                stx     V_Y
                lda     #0
                ldy     #V_LP
                jsr     linepointer
                lda     #0
                tay
                sta     (V_LP),y
                iny
                sty     V_X
                jsr     insertat
                jmp     mainloop

cmd_i:
cmd_r:
cmd_I:
cmd_d:
cmd_j:
                jmp     mainloop

cL:
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
                jsr     CHROUT
                bne     cL_lineout
cL_currline:    lda     #'>'
                jsr     CHROUT
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
cL_colloop:     jsr     CHROUT
                dex
                bne     cL_colloop
                lda     #'^'
                jsr     CHROUT
                lda     #$d
                jsr     CHROUT
                jmp     mainloop

printline:
                lda     #>pl_base
                ldy     #<pl_base
                jsr     linepointer
                ldx     pl_base
                inx
                stx     pl_read
                ldx     pl_base+1
                stx     pl_read+1
pl_base         = *+1
                ldx     $ffff
                stx     pl_cmp
                ldy     #0
pl_read         = *+1
pl_loop:        lda     $ffff,y
                jsr     CHROUT
                iny
pl_cmp          = *+1
                cpy     #$ff
                bne     pl_loop
                lda     #$d
                jmp     CHROUT
                ; rts

insertat:
                lda     V_LP
                adc     V_X
                sta     ia_mvsrcbase
                sta     ia_instgtbase
                lda     V_LP+1
                adc     #0
                sta     ia_mvsrcbase+1
                sta     ia_instgtbase+1
                lda     ia_mvsrcbase
                adc     arglen
                sta     ia_mvdstbase
                lda     ia_mvsrcbase+1
                adc     #0
                sta     ia_mvdstbase+1
                ldy     #0
                lda     (V_LP),y
                sec
                sbc     V_X
                bmi     ia_nomove
                tax
                clc
ia_mvsrcbase    = *+1
ia_moveloop:    lda     $ffff,x
ia_mvdstbase    = *+1
                sta     $ffff,x
                dex
                bpl     ia_moveloop
ia_nomove:      ldx     arglen
                dex
                bpl     ia_insert
                rts
ia_insert:      lda     line+2,x
ia_instgtbase   = *+1
                sta     $ffff,x
                dex
                bpl     ia_insert
                ldy     #0
                lda     (V_LP),y
                clc
                adc     arglen
                sta     (V_LP),y
                lda     V_X
                clc
                adc     arglen
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

.bss

arglen:         .res    1               ; length of argument to command

