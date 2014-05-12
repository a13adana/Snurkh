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
.DEF posX				= r25
.DEF posY				= r15

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

	/*ldi arg0, 0
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

	*/

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

	// --- Set A/D converter stuff
	clr direction

	// Configure ADMUX to use right analog input and 8-bit mode
	ldi tmp0, 0b01100000
	sts ADMUX, tmp0
	//sbi ADMUX, 7
	//sbi ADMUX, 6
	// Configure ADSCRA to enable conversion
	ldi tmp0, 0b10000111
	sts ADCSRA, tmp0

main:
	ldi YH, HIGH(light_rows)
	ldi YL, LOW(light_rows)
	// Offset with rows
	clr tmp0
	ldi tmp1, 1
	st Y, tmp0
	add	YL,	tmp1
	st Y, tmp0
	add	YL,	tmp1
	st Y, tmp0
	add	YL,	tmp1
	st Y, tmp0
	add	YL,	tmp1
	st Y, tmp0
	add	YL,	tmp1
	st Y, tmp0
	add	YL,	tmp1
	st Y, tmp0
	add	YL,	tmp1
	st Y, tmp0
	add	YL,	tmp1

	call update_joystick
	clr arg0
	bst direction, 0
	bld arg0, 0
	add posY, arg0
	ldi arg0, 0b11111000
	and arg0, posY
	sub posY, arg0

	clr arg0
	bst direction, 1
	bld arg0, 0
	add posX, arg0
	ldi arg0, 0b11111000
	and arg0, posX
	sub posX, arg0

	and arg0, zero
	and arg1, zero
	or arg0, posX
	or arg1, posY
	call set_bit
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

update_joystick: // TODO - Add logic for X-axis
	// load the current analog settings
	lds tmp0, ADMUX
	// wipe the settings of input specs
	ldi tmp1, 0b11110000
	and tmp0, tmp1
	// set the desired input
	ldi tmp1, 4
	or tmp0, tmp1
	sts ADMUX, tmp0

	// Start analog conversion by setting the ADSC bit to 1
	lds tmp0, ADCSRA
	ldi tmp1, 0b01000000
	or tmp0, tmp1
	sts ADCSRA, tmp0

update_joystick_wait_Y:
	lds tmp0, ADCSRA
	ldi tmp1, 0b01000000
	and tmp0, tmp1
	cpi	tmp0 , 0 // check if the ADSC bit is 0 (ready)
	brne update_joystick_wait_Y


	lds tmp0, ADCH

	cpi tmp0, 96
	brlo update_joystick_is_down
	cpi tmp0, 161
	brsh update_joystick_is_up
	// if neutral
	jmp update_joystick_Y_done

update_joystick_is_down:
	ldi tmp0, 0b11111100
	and tmp0, direction
	ldi tmp1, 0b00000010 // set bit 1 (up) in direction to 1
	or tmp0, tmp1
	mov direction, tmp0
	jmp update_joystick_Y_done

update_joystick_is_up:
	ldi tmp0, 0b11111100
	and tmp0, direction
	ldi tmp1, 0b00000001 // set bit 0 (down) in direction to 1
	or tmp0, tmp1
	mov direction, tmp0
	jmp update_joystick_Y_done
update_joystick_Y_done:
	/*in tmp0, PORTC
	bst tmp0, 5
	bld tmp1, 0 // X
	bst tmp0, 4
	bld tmp1, 1 // Y*/


	ret