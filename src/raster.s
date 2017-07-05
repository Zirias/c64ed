.include "vic.inc"
.include "keyboard.inc"

.export raster_on
.export raster_off
.export empty_isr
.export show_cursor

.segment "ZPLOW": zeropage

SAVE_A:		.res 1
SAVE_X:		.res 1
CURS_COUNT:	.res 1

.segment "INIT"
		ldx	#1
		stx	CURS_COUNT
.code

raster:
		sta	SAVE_A
		stx	SAVE_X
		dec	CURS_COUNT
		bne	skip_cursor
		lda	#24
		sta	CURS_COUNT
		lda	#1
		eor	SPRITE_SHOW
		sta	SPRITE_SHOW
skip_cursor:	jsr	kb_check
		lda	#$ff
		sta	VIC_IRR
		ldx	SAVE_X
		lda	SAVE_A
empty_isr:	rti

show_cursor:
		sei
		ldy	#1
		sty	SPRITE_SHOW
		ldy	#24
		sty	CURS_COUNT
		cli
		rts

raster_on:
		lda	#%01111111
		sta	$dc0d
		lda	$dc0d
		lda	#%00000001
		sta	VIC_IRM
		sta	VIC_IRR
		lda	#$10
		sta	VIC_RASTER
		lda	VIC_CTL1
		and	#%01111111
		sta	VIC_CTL1
		lda	#<raster
		sta	$fffe
		lda	#>raster
		sta	$ffff
		rts

raster_off:
		lda	#0
		sta	VIC_IRM
		sta	VIC_IRR
		lda	#%10000011
		sta	$dc0d
		rts

