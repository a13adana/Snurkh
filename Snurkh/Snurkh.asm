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
.DEF ticks				= r3 // Most significant bit used to determine whether to update

.DEF zero				= r0 // Always 0

.DSEG
light_rows:	.BYTE		8 // light matrix
snurkh_body: .BYTE		64

.CSEG
// ----------------------------- Set interrupt jumps -----------------------------
.ORG 0x0000
	jmp init
.ORG 0x0020 // Timer overflow interrupt
	jmp on_timer_interrupt
init:
// ----------------------------- Initialise stack pointer -----------------------------
	ldi tmp0 , HIGH(RAMEND)
	out SPH, tmp0 
	ldi tmp0 , LOW(RAMEND)
	out SPL, tmp0 

	ldi posX, 0
	and posY, zero
	and ticks, zero
// ----------------------------- Set zero register -----------------------------
	clr zero

// ----------------------------- Zero data in light matrix -----------------------------
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

	// Code to light up corners
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
	call set_bit_at*/

// ----------------------------- Zero out snurkh_body memory -----------------------------
	ldi XH, HIGH(snurkh_body)
	ldi XL, LOW(snurkh_body)

	ldi tmp0, 0b00000000
	ldi tmp1, 64

snurkh_body_zero_loop:
	st	X+, tmp0
	subi tmp1, 1
	cpi tmp1, 0
	brge snurkh_body_zero_loop

// ----------------------------- Create Snurkh head, set start direction -----------------------------
	ldi XH, HIGH(snurkh_body)
	ldi XL, LOW(snurkh_body)

	ldi tmp0, 0b00011011		// 7 unused, 6 follow, 3-5 Ypos, 0-2 Xpos
	st	X, tmp0
	ldi direction, 0b00000001	// 0000 Down Up Left Right

// ------------------- Set DDR registers to output on LEDs and input on everything else -------------------
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

// ----------------------------- Set A/D converter stuff -----------------------------

	// Configure ADMUX to use right analog input and 8-bit mode
	ldi tmp0, 0b01100000
	sts ADMUX, tmp0
	//sbi ADMUX, 7
	//sbi ADMUX, 6
	// Configure ADSCRA to enable conversion
	ldi tmp0, 0b10000111
	sts ADCSRA, tmp0
	
// ----------------------------- Activate interrupt handling and start timer -----------------------------
	
	// Configure pre-scaling
	lds tmp1, TCCR0B
	ldi tmp0, 0b11111000
	and tmp1, tmp0
	ldi tmp0, 0b00000101
	or tmp1, tmp0
	out TCCR0B, tmp1

	// Enable global interrupts
	sei

	// Activate overflow interrupt for timer0
	ldi tmp0, 0b00000001
	lds tmp1, TIMSK0
	or tmp1, tmp0
	sts TIMSK0, tmp1

// ----------------------------- Main loop -----------------------------
main:
	clr ticks // Zero out ticks before it is used.

// Clear matrix
	ldi YH, HIGH(light_rows)
	ldi YL, LOW(light_rows)
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

	call update_joystick // TODO: insert code here
	// spawn food
	call update_snurkh // TODO: insert code here

	/*subi posX, -1
	clr arg1
	or arg1, posX
	ldi arg0, 0
	call set_bit*/

// ----------------------------- Display code -----------------------------
draw:	
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
	sbrc ticks, 7 // Check if we should stop draw loop
jmp main
jmp draw // Draw until interrupt from timer

// ----------------------------- Timer interrupt code -----------------------------
on_timer_interrupt:
	push tmp0
	inc ticks
	ldi tmp0, 30 // ticks/update
	cp ticks, tmp0
	brlo on_timer_interrupt_end
// Set update flag
	ldi tmp0, 0b10000000
	or ticks, tmp0
on_timer_interrupt_end:
	pop tmp0
reti

// ----------------------------- Set bit specified by arguments -----------------------------
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

// ----------------------------- Update direction register using joystick -----------------------------
update_joystick:
// --- Setting up for reading of Y ---
// load the current analog settings
	lds tmp0, ADMUX
// wipe the settings of input specs
	ldi tmp1, 0b11110000
	and tmp0, tmp1
// set the desired input
	ldi tmp1, 5
	or tmp0, tmp1
	sts ADMUX, tmp0

// Start analog conversion by setting the ADSC bit to 1
	lds tmp0, ADCSRA
	ldi tmp1, 0b01000000
	or tmp0, tmp1
	sts ADCSRA, tmp0

// --- Read Y ---
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
jmp update_joystick_X

update_joystick_is_down:
	ldi tmp2, 0b00001000
jmp update_joystick_direction

update_joystick_is_up:
	ldi tmp2, 0b00000100
jmp update_joystick_direction

update_joystick_X:
// --- Setting up for reading of X ---
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
// --- Read X ---
update_joystick_wait_X:
	lds tmp0, ADCSRA
	ldi tmp1, 0b01000000
	and tmp0, tmp1
	cpi	tmp0, 0 // check if the ADSC bit is 0 (ready)
brne update_joystick_wait_X

	lds tmp0, ADCH

	cpi tmp0, 96
	brlo update_joystick_is_right
	cpi tmp0, 161
	brsh update_joystick_is_left
// we only get here is both directions are neutral
jmp dont_update_joystick_direction

update_joystick_is_right:
	ldi tmp2, 0b00000001
jmp update_joystick_direction

update_joystick_is_left:
	ldi tmp2, 0b00000010
jmp update_joystick_direction

update_joystick_direction:
// Update direction using tmp2 which is set by joystick code
	ldi tmp0, 0b11110000
	and tmp0, direction // mask out relevant bits
	or tmp0, tmp2 // or in direction bits
	mov direction, tmp0

dont_update_joystick_direction:
ret

// ----------------------------- Move and store snurkh -----------------------------
update_snurkh:
// Get head position
	ldi XH, HIGH(snurkh_body)
	ldi XL, LOW(snurkh_body)

	ld tmp0, X // Store head position in tmp0

	ldi tmp1, 0b00000111 // mask for x
	and tmp1, tmp0 // get x value

	ldi tmp2, 0b00111000 // mask for y
	and tmp2, tmp0 // get y value
	lsr tmp2 // right align y bits
	lsr tmp2
	lsr tmp2


	sbrs direction, 0 // skip next if right = 1
jmp dont_snurkh_right
	subi tmp1, -1

	sbrc tmp1, 3
	subi tmp1, 8
dont_snurkh_right:

	sbrs direction, 1 // skip next if left = 1
jmp dont_snurkh_left
// if we are at 0 then set to 8 to wrap around
	cpse tmp1, zero // skip next skip if tmp1 = 0
	cpse zero, zero // always skip
	ldi tmp1, 8

	subi tmp1, 1
dont_snurkh_left:

	sbrs direction, 2 // skip next if up = 1
jmp dont_snurkh_up
// if we are at 0 then set to 8 to wrap around
	cpse tmp2, zero
	cpse zero, zero
	ldi tmp2, 8

	subi tmp2, 1
dont_snurkh_up:

	sbrs direction, 3 // skip next if down = 1
jmp dont_snurkh_down
	subi tmp2, -1

	sbrc tmp2, 3
	subi tmp2, 8
dont_snurkh_down:

// Write snurkh head to light matrix
	clr arg0
	or arg0, tmp1
	clr arg1
	or arg1, tmp2
	call set_bit

// Write snurkh head to memory
	lsl tmp2 // alight y pos properly
	lsl tmp2
	lsl tmp2
	or tmp2, tmp1 // or together the positions
	st X, tmp2 // store in head position

// calc target pos
// check for food at pos
update_snurkh_loop:
// fetch cur pos
// stor tar pos
// if end of snake && hasfood -> addpart
// if not end of snake -> loop

ret