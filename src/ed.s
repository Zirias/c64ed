.include "defs.inc"

.import linepointer
.import linesdown
.import linesup
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
                jsr     linesdown
                jmp     mainloop

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
                jmp     cp

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
                jmp     ci

cmd_r:
                jmp     cr

cmd_I:
                jsr     insertat
                jmp     mainloop

cmd_d:
                jmp     cd

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
                lda     arglen
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

cd:
                ldy     #0
                lda     (V_LP),y
                bne     cd_clearline
                lda     V_Y
                cmp     V_R
                bne     cd_linesup
                dec     V_Y
                iny
                sty     V_X
cd_linesup:     jsr     linesup
cd_main:        jmp     mainloop
cd_clearline:   tya
                sta     (V_LP),y
                iny
                sty     V_X
                bne     cd_main

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
jmpmain2:       jmp     mainloop

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
                jmp     mainloop

cr:
                ldy     #0
                ldx     V_X
                dex
                txa
                sta     (V_LP),y
                jsr     insertat
                inc     V_Y
                ldx     #1
                stx     V_X
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
                beq     pl_empty
                stx     pl_cmp
                ldy     #0
pl_read         = *+1
pl_loop:        lda     $ffff,y
                jsr     CHROUT
                iny
pl_cmp          = *+1
                cpy     #$ff
                bne     pl_loop
pl_empty:       lda     #$d
                jmp     CHROUT
                ; rts

insertat:
                lda     V_LP
                clc
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

