/*
 * Snurkh.asm
 *
 *  Created: 2014-04-25 13:34:23
 *   Author: Tesla Hassel, Vicktor Knutsson, Niklas Blindlagd, Adam Örondal
 */ 

.DEF tmp0				= r16
.DEF tmp1				= r17
.DEF tmp2				= r18
.DEF tmp3				= r19
.DEF tmp4				= r24
.DEF arg0				= r20
.DEF arg1				= r21
.DEF arg2				= r22
.DEF direction			= r23
.DEF zero				= r0

.DSEG
light_rows:	.BYTE		8

.CSEG
.ORG 0x0000
	jmp init
.ORG INT_VECTORS_SIZE
init:
// --- Initialise stack pointer ---
	ldi tmp0 , HIGH(RAMEND)
	out SPH, tmp0 
	ldi tmp0 , LOW(RAMEND)
	out SPL, tmp0 
	
// --- Set zero register ---
	clr zero

// --- Set data in light matrix ---
	ldi XH, HIGH(light_rows)
	ldi XL, LOW(light_rows)

	ldi tmp2, 0b00000000
	st	X+, tmp2
	ldi	tmp2, 0b00000000
	st	X+, tmp2
	ldi	tmp2, 0b00000000
	st	X+, tmp2
	ldi	tmp2, 0b00000000
	st	X+, tmp2
	ldi	tmp2, 0b00000000
	st	X+, tmp2
	ldi	tmp2, 0b00000000
	st	X+, tmp2
	ldi	tmp2, 0b00000000
	st	X+, tmp2
	ldi	tmp2, 0b00000000
	st	X+, tmp2

	ldi arg0, 0
	ldi arg1, 0
	call set_bit_at

	ldi arg0, 0
	ldi arg1, 7
	call set_bit_at

	ldi arg0, 7
	ldi arg1, 0
	call set_bit_at

	ldi arg0, 7
	ldi arg1, 7
	call set_bit_at


	// --- Set DDR registers to output on LEDs and input on everything else ---
	ldi tmp0 , 0b00111111
	out DDRB, tmp0 
	ldi tmp0 , 0b00001111
	out DDRC, tmp0 
	ldi tmp0 , 0b11111100
	out DDRD, tmp0 

	ldi tmp0 , 0x00
	out PORTB, tmp0 
	out PORTC, tmp0 
	out PORTD, tmp0 

main:
// --- Display code ---
	
// --- Row to output is put in tmp2 ---
	//ldi	tmp2, 0b00011100
	clr tmp2
	ldi XH, HIGH(light_rows)
	ldi XL, LOW(light_rows)
	
	
// --- Iterate over first four rows ---
	ldi	tmp0 , 0b00000001 // first row, port C
render_loop1:
	
	ld tmp2, X+
	// set column(s) to "render"
	// tmp2 contains the row to render in "raw form"
	// tmp1 is output
	
// --- Set proper bits for columns ---
	// --- Set the D port ---
	clr	tmp1 // clear register used for output
	bst	tmp2, 0 // copy bit 0
	bld	tmp1, 6 // paste to bit 6
	bst	tmp2, 1 // copy bit 1
	bld	tmp1, 7 // paste to bit 7
	
	// --- Set the B port ---
	mov	tmp3,  tmp2 // tmp3 = tmp2
	lsr tmp3 // shift right
	lsr tmp3 // shift right

	out PORTC, zero
	// NOPS
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	// LOL MOAR NOPS
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	out PORTB, tmp3
	out PORTD, tmp1
	out PORTC, tmp0 

	lsl	tmp0 // shift left
	cpi	tmp0 , 0b00010000 // check if we have passed the first four rows
	brlo render_loop1 // iterate over first four rows

	// we'll get here after the first four rows
	
	 // we are done with port C
// --- Iterate over last for rows ----
	ldi	tmp0 , 0b00000100 // fifth row, port D

render_loop2:
	// set column(s) to "render"
	// tmp2 contains the row to render in "raw form"
	// tmp1 is output

	ld tmp2, X+
// --- Set proper bits for columns ---
	// --- Set the D port ---
	// copy iteration reg into output reg so that we don't overwrite the row bits in it
	//ld tmp2, X+
	mov	tmp1, tmp0 
	bst	tmp2, 0 // copy bit 0
	bld	tmp1, 6 // paste to bit 6
	bst	tmp2, 1 // copy bit 1
	bld	tmp1, 7 // paste to bit 7
	
	// --- Set the B port ---
	mov	tmp3,  tmp2 // tmp3 = tmp2
	lsr tmp3 // shift right
	lsr tmp3 // shift right
	
	out PORTC, zero
	out PORTD, zero

	//NOPS
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop

	out PORTB, tmp3
	out PORTD, tmp1
	
	lsl	tmp0 
	cpi	tmp0 , 0b01000000 // check if we have passed the last for rows
	brlo render_loop2 // iterate over last four rows
	// NOPS
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	out PORTD, zero
	
jmp main

// --- Bitflippers ---
__do_lolStuffOMG12__:
set_bit_at:
set_bit: // arg0 = row, arg1 = column
	// Load base addr
	ldi YH, HIGH(light_rows)
	ldi YL, LOW(light_rows)
	// Offset with rows
	// Fuck overflow 4 lyfe #YOLO_SWAG
	add	YL,	arg0
	// Load byte
	ld tmp0, Y

	ldi tmp4, 0 // counter
	ldi tmp3, 1 // bitmask

	// Shifts the bit until right
	loop_start_shifty:
	cp tmp4, arg1
	brge out_of_loop
	lsl tmp3
	adiw tmp4, 1
	jmp loop_start_shifty
	out_of_loop:
	
	// or and store!
	or tmp0, tmp3
	st Y, tmp0

	ret