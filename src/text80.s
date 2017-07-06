.include "kbctrlcodes.inc"
.include "vic.inc"
.include "vicconfig.inc"
.include "raster.inc"

.import font_topaz_80col_petscii_western

.exportzp T80_ROW
.exportzp T80_COL

.export t80_putc
.export t80_chrout
.export t80_setcrsr

.segment "ZPLOW": zeropage
T80_ROW:        .res 1
T80_COL:        .res 1
PUTS_L:         .res 1
PUTS_H:         .res 1
CHAR_L:         .res 1
CHAR_H:         .res 1
WCOL:           .res 1
char:           .res 8
savey:          .res 1

.code

; get address of character data
; in:   a               character block offset in font
; out:  CHAR_L          address
getcharaddr:
                sta     CHAR_L
                lda     #0
                sta     CHAR_H
                lda     CHAR_L
                asl     a
                rol     CHAR_H
                asl     a
                rol     CHAR_H
                asl     a
                rol     CHAR_H
                sta     CHAR_L
                lda     #<font_topaz_80col_petscii_western
                clc
                adc     CHAR_L
                sta     CHAR_L
                lda     #>font_topaz_80col_petscii_western
                adc     CHAR_H
                sta     CHAR_H
                rts

; get address of screen position
; in:   T80_ROW         text row (0-24)
; in:   WCOL            text column (0-39)
; out:  PUTS_L          screen position address
getputaddr:
                lda     #0
                sta     PUTS_H
                lda     T80_ROW
                asl     a
                asl     a
                asl     a
                asl     a
                rol     PUTS_H
                asl     a
                rol     PUTS_H
                asl     a
                rol     PUTS_H
                sta     PUTS_L
                lda     PUTS_H
                adc     T80_ROW
                adc     #(vic_bitmap >> 8)
                sta     PUTS_H
                lda     WCOL
                asl     a
                asl     a
                asl     a
                bcc     thispage1
                inc     PUTS_H
                clc
thispage1:      adc     PUTS_L
                bcc     thispage2
                inc     PUTS_H
thispage2:      sta     PUTS_L
                rts

t80_scroll:
                ldy     #>vic_bitmap
                sty     PUTS_H
                iny
                sty     CHAR_H
                ldy     #$40
                sty     CHAR_L
                ldy     #0
                sty     PUTS_L
                ldx     #50
scr_loop:       lda     #0
                tay
scr_inner:      cpx     #3
                bmi     scr_noload
                lda     (CHAR_L),y
scr_noload:     sta     (PUTS_L),y
                iny
                cpy     #$a0
                bne     scr_inner
                dex
                beq     scr_done
                lda     #$9f
                adc     PUTS_L
                sta     PUTS_L
                bcc     scr_nextsrc
                inc     PUTS_H
                clc
scr_nextsrc:    lda     #$a0
                adc     CHAR_L
                sta     CHAR_L
                bcc     scr_loop
                inc     CHAR_H
                bcs     scr_loop
scr_done:       rts

t80_setcrsr:
                pha
                sty     savey
                jmp     cursorpos

t80_chrout:
                pha
                sty     savey
                cmp     #KBC_ENTER
                beq     co_cr
                cmp     #KBC_BACKSPACE
                beq     co_bs
                jsr     t80_putc
                inc     T80_COL
                ldy     #80
                cpy     T80_COL
                bne     cursorpos
co_cr:          ldy     #0
                sty     T80_COL
                inc     T80_ROW
                ldy     #25
                cpy     T80_ROW
                bne     cursorpos
                dec     T80_ROW
                jsr     t80_scroll
                beq     cursorpos
co_bs:          lda     #' '
                ldy     T80_COL
                beq     co_up
                dey
                sty     T80_COL
                bpl     co_out
co_up:          ldy     #79
                sty     T80_COL
                ldy     T80_ROW
                beq     co_home
                dey
                sty     T80_ROW
                bpl     co_out
co_home:        ldy     #0
                sty     T80_COL
                beq     cursorpos
co_out:         jsr     t80_putc
cursorpos:      lda     T80_ROW
                asl     a
                asl     a
                asl     a
                adc     #$32
                sta     SPRITE_0_Y
                lda     #0
                sta     SPRITE_X_HB
                lda     T80_COL
                asl     a
                asl     a
                bcc     cp_nohb
                inc     SPRITE_X_HB
                clc
cp_nohb:        adc     #$18
                bcc     cp_nohb2
                inc     SPRITE_X_HB
cp_nohb2:       sta     SPRITE_0_X
                jsr     show_cursor
                pla
                ldy     savey
                rts

; put character on screen in 80col mode
; in:   a               character code (petscii)
; in:   T80_ROW         text row (0-24)
; in:   T80_COL         text column (0-79)
t80_putc:
                clc
                lsr     a
                bcs     char_1
char_0:         jsr     getcharaddr
                ldy     #7
loop1:          lda     (CHAR_L),y
                and     #$f0
                sta     char,y
                dey
                bpl     loop1
                lda     T80_COL
                lsr     a
                sta     WCOL
                bcs     c0_put_l
c0_put_h:       jsr     getputaddr
                ldy     #7
loop2:          lda     (PUTS_L),y
                and     #$0f
                ora     char,y
                sta     (PUTS_L),y
                dey
                bpl     loop2
                rts
c0_put_l:       jsr     getputaddr
                ldy     #7
loop3:          lda     (PUTS_L),y
                and     #$f0
                lsr     a
                lsr     a
                lsr     a
                lsr     a
                lsr     a               ;shift to carry
                ora     char,y
                ror     a
                ror     a
                ror     a
                ror     a
                sta     (PUTS_L),y
                dey
                bpl     loop3
                rts
char_1:         jsr     getcharaddr
                ldy     #7
loop4:          lda     (CHAR_L),y
                and     #$0f
                sta     char,y
                dey
                bpl     loop4
                lda     T80_COL
                lsr     a
                sta     WCOL
                bcs     c1_put_l
c1_put_h:       jsr     getputaddr
                ldy     #7
loop5:          lda     (PUTS_L),y
                asl     a
                asl     a
                asl     a
                asl     a
                asl     a               ;shift to carry
                ora     char,y
                rol     a
                rol     a
                rol     a
                rol     a
                sta     (PUTS_L),y
                dey
                bpl     loop5
                rts
c1_put_l:       jsr     getputaddr
                ldy     #7
loop6:          lda     (PUTS_L),y
                and     #$f0
                ora     char,y
                sta     (PUTS_L),y
                dey
                bpl     loop6
                rts

; vim: et:si:ts=8:sts=8:sw=8
