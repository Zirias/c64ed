.include "vic.inc"
.include "vicconfig.inc"
.include "raster.inc"
.include "gfx-core.inc"
.include "text80.inc"
.include "petscii_lc.inc"

.import ed
.import __ZPSAVE_LOAD__

.segment "LDADDR"
                .word   $c000

.segment "ZPLOW": zeropage
border_save:    .res	1
bg_save:        .res	1
memctl_save:    .res	1
vicctl1_save:   .res	1

.segment "IOBSS"
zp_save:	.res	$fe

.segment "INIT"
		; no interrupts during initialization
		sei

		; select all RAM
		lda	#$34
		sta	$1

                ; save zeropage
                ldx     #2
zps_loop:	lda     $00,x
                sta     zp_save-2,x
                inx
                bne     zps_loop

		; initialize color data, bitmap and sprite
		lda	#$f
		ldx	#0
		jsr	gfx_setcolor
		jsr	gfx_clear
		ldx	#$7f
		lda	#0
spriteloop:	sta	vic_spriteset,x
		dex
		bpl	spriteloop
		lda	#$f0
		sta	vic_spriteset+18
		sta	vic_spriteset+21
		lda	#vic_sprite_baseptr
		sta	vic_sprite_vectors

		; re-enable I/O area
		lda	#$35
		sta	$1

                ; save vic config
                lda     BORDER_COLOR
                sta     border_save
                lda     BG_COLOR_0
                sta     bg_save
                lda     VIC_CTL1
                sta     vicctl1_save

		; "disable" NMI using no-ack trick
                lda     #<empty_isr
                sta     $fffa
                lda     #>empty_isr
                sta     $fffb
                lda     #0
                sta     $dd0e
                sta     $dd04
                sta     $dd05
                lda     #$81
                sta     $dd0d
                lda     #1
                sta     $dd0e

                ; configure VIC and enable raster IRQ handling
                lda     CIA2_DATA_A
                and     #vic_bankselect_and
                sta     CIA2_DATA_A
                lda     VIC_MEMCTL
                sta     memctl_save
                jsr     raster_on

		; set graphics mode and clear screen
		jsr	gfx_on

		; enable sprite
		lda	#$19
		sta	SPRITE_0_X
		lda	#$32
		sta	SPRITE_0_Y
		lda	#0
		sta	SPRITE_X_HB
		sta	SPRITE_DBL_X
		sta	SPRITE_DBL_Y
		sta	SPRITE_MULTI
		lda	#1
		sta	SPRITE_0_COL
		sta	SPRITE_LAYER
		sta	SPRITE_SHOW

		; initialize 80col text module
		lda	#0
		sta	T80_ROW
		sta	T80_COL
		sta	BORDER_COLOR

		; re-enable interrupts
		cli

.segment "MAIN"
main:		jsr	ed

		sei

                ; disable raster IRQ handling, reset VIC to normal
                jsr     raster_off
                lda     CIA2_DATA_A
                ora     #%00000011
                sta     CIA2_DATA_A
                lda     memctl_save
                sta     VIC_MEMCTL

                ; re-enable normal NMI
                lda     #1
                sta     $dd0d
                lda     $dd0d

                ; restore vic config
                lda     vicctl1_save
                sta     VIC_CTL1
                lda     border_save
                sta     BORDER_COLOR
                lda     bg_save
                sta     BG_COLOR_0
		lda	#0
		sta	SPRITE_SHOW

		; select all RAM
		lda	#$34
		sta	$1

                ; restore zeropage
                ldx     #2
zpr_loop:       lda     zp_save-2,x
                sta     $00,x
                inx
                bne     zpr_loop

		; restore normal mapping with BASIC and KERNAL
		lda	#$37
		sta	$1

		cli

                rts

.bss
