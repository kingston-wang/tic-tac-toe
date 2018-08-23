.equ STACK,0x04000000
.equ MOUSE,0xFF200100
.equ TIMER,0xFF202000
.equ CHAR_BUFFER,0x09000000
.equ PIXEL_BUFFER,0x08000000
.equ LEGO_CONTROLLER,0xFF200060
.equ VGA_FRONT_BUFFER,0xFF203020
.equ VGA_BACK_BUFFER1,0x01000000
.equ VGA_BACK_BUFFER_END,0x01012C00

.equ ADDR_VGA, 0x08000000
.equ ADDR_CHAR, 0x09000000
.equ JTAG_UART, 0xFF201000

	.section .data
	.align 2
BACKGROUND:
	.incbin "test.bmp"
PLAYER_1_EMPTY:
	.incbin "player1_emptyboard.bmp"
PLAYER_2_EMPTY:
	.incbin "player2_emptyboard.bmp"
PLAYER_1_WIN:
	.incbin "player1_winscreen.bmp"
PLAYER_2_WIN:
	.incbin "player2_winscreen.bmp"
STALEMATE_SCREEN:
	.incbin "stalemate.bmp"
O_SYMBOL:
	.incbin "o_symbol.bmp"
X_SYMBOL:
	.incbin "x_symbol.bmp"

	.align 2
GAME_BOARD:
	.word 0, 0, 0, 0, 0, 0, 0, 0, 0

PREVIOUS_MOVE: .word 0

XCOUNT: .word 320
YCOUNT: .word 240

#COORDINATES FOR SYMBOLS#
COUNTSYMBOL: .word 40
MIDDLE_SLOT_LOWERLEFT_X: .word 141
MIDDLE_SLOT_LOWERLEFT_Y: .word 139

BOX_COORDINATES_X: .word 57,130,210,57,130,210,57,130,210
BOX_COORDINATES_Y: .word 75,75,75,145,145,145,200,200,200

X_CRANE: .word 1
Y_CRANE: .word 1
X_CURSOR: .word 160
Y_CURSOR: .word 120
X_POSITION: .word 160
Y_POSITION: .word 120
MOUSE_BUTTONS: .word 0

#VGA_COPY: .skip 76800

.section	.exceptions,"ax"
.global ISR
ISR:
    addi  sp,sp,-28
    stw   ra,(sp)
    stw   r2,4(sp)
    stw   r3,8(sp)
    stw   r4,12(sp)
    stw   r5,16(sp)
    stw   r6,20(sp)
    stw   r7,24(sp)

    rdctl et,ipending
    andi  et,et,0x80
    bne   et,r0,MOUSE_INTERRUPT

    br ISR_EXIT

MOUSE_INTERRUPT:
    call  READ_MOUSE_PACKET
    call  REDRAW_CURSOR

ISR_EXIT:
    ldw   ra,(sp)
    ldw   r2,4(sp)
    ldw   r3,8(sp)
    ldw   r4,12(sp)
    ldw   r5,16(sp)
    ldw   r6,20(sp)
    ldw   r7,24(sp)
    addi  sp,sp,28

    addi  ea,ea,-4
    eret


	.section .text
	.global _start
_start:

  	movia sp, STACK

    call  RESET_MOUSE

    movia r8,0x800080
    wrctl ienable,r8

    movi  r8,1
    wrctl status,r8

    movia r9,MOUSE
    stwio r8,4(r9)
    stwio r8,12(r9)

    movia r8,LEGO_CONTROLLER

    movia r9,0x07F557FF
    stwio r9,4(r8)

    movia r9,0xFFFFFFFF
    stwio r9,(r8)

	call  DRAW_SCREEN
LOOP:

  call  READ_SENSOR0
  call  READ_SENSOR1
	movia r4, BACKGROUND
	call  DRAW_SCREEN
	call  REDRAW_CURSOR

	movi  r4,108
	movi  r5,209
	movi  r6,114
	movi  r7,38

	call  CLICK_RECT_2
	beq   r2,r0,LOOP

	movi  r4,108
	movi  r5,209
	movi  r6,114
	movi  r7,38
	call  CLICK_RECT_1
	beq   r2,r0,LOOP

	movia r4, 100000000
	call DELAY

GAME:
	call  DRAW_SCREEN_PLAYER_BOARD
	call DRAW_ON_BOARD
	call  REDRAW_CURSOR

	movi r4, 0x88
	call TEST_WIN
	bne r2, r0, X_WIN

	movi r4, 0x34
	call TEST_WIN
	bne r2, r0, Y_WIN

	call TEST_STALEMATE
	bne r2, r0, STALEMATE

	movia r4,2000000
	call  DELAY
	br GAME

X_WIN:
	movia r4, PLAYER_1_WIN
	call DRAW_SCREEN
	call REDRAW_CURSOR
	movi r4, 95
	movi r5, 154
	movi r6, 126
	movi r7, 64
	call CLICK_RECT_2
	beq r2, r0, X_WIN

	call CLICK_RECT_1
	beq r2, r0, X_WIN

	movia r2, GAME_BOARD
	stw r0, (r2)
	stw r0, 4(r2)
	stw r0, 8(r2)
	stw r0, 12(r2)
	stw r0, 16(r2)
	stw r0, 20(r2)
	stw r0, 24(r2)
	stw r0, 28(r2)
	stw r0, 32(r2)

	movia r16, PREVIOUS_MOVE
	movi r17, 0x34
	stw r17, 0(r16)
	br LOOP

Y_WIN:
	movia r4, PLAYER_2_WIN
	call DRAW_SCREEN
	call REDRAW_CURSOR
	movi r4, 95
	movi r5, 154
	movi r6, 126
	movi r7, 64
	call CLICK_RECT_2
	beq r2, r0, Y_WIN

	call CLICK_RECT_1
	bne r2, r0, Y_WIN

	movia r2, GAME_BOARD
	stw r0, (r2)
	stw r0, 4(r2)
	stw r0, 8(r2)
	stw r0, 12(r2)
	stw r0, 16(r2)
	stw r0, 20(r2)
	stw r0, 24(r2)
	stw r0, 28(r2)
	stw r0, 32(r2)
	movia r16, PREVIOUS_MOVE
	movi r17, 0x34
	stw r17, 0(r16)
	br LOOP

STALEMATE:
	movia r4, STALEMATE_SCREEN
	call DRAW_SCREEN
	call REDRAW_CURSOR

	movi r4, 95
	movi r5, 150
	movi r6, 126
	movi r7, 73
	call CLICK_RECT_2
	beq r2, r0, STALEMATE

	call CLICK_RECT_1
	bne r2, r0, STALEMATE

	movia r2, GAME_BOARD
	stw r0, (r2)
	stw r0, 4(r2)
	stw r0, 8(r2)
	stw r0, 12(r2)
	stw r0, 16(r2)
	stw r0, 20(r2)
	stw r0, 24(r2)
	stw r0, 28(r2)
	stw r0, 32(r2)
	movia r16, PREVIOUS_MOVE
	movi r17, 0x88
	stw r17, 0(r16)

	br LOOP


DRAW_SCREEN:
	subi sp, sp, 36
	stw r16, (sp)
	stw r17, 4(sp)
	stw r18, 8(sp)
	stw r19, 12(sp)
	stw r20, 16(sp)
	stw r21, 20(sp)
	stw r22, 24(sp)
	stw r23, 28(sp)
	stw sp, 32(sp)

  movia r18, XCOUNT
  movia r19, YCOUNT
  movia r16, ADDR_VGA
  mov r17, r4
	addi r17, r17, 138

	ldw r18, 0(r18)
  ldw r19, 0(r19)
	mov r20, r0

DRAW_Y:
  beq r19, r0, STOP_LOOP
DRAW_X:
  beq r20, r18, SUB1_Y
  muli r22, r20, 2
  add r23, r16, r22
	muli r22, r19, 1024
  add r23, r23, r22

	ldh r21, 0(r17)
	sthio r21, 0(r23)
	addi r17, r17, 2

	addi r20, r20, 1
    br DRAW_X

SUB1_Y:
	mov r20, r0
	subi r19, r19, 1
  br DRAW_Y

STOP_LOOP:
	ldw r16, (sp)
	ldw r17, 4(sp)
	ldw r18, 8(sp)
	ldw r19, 12(sp)
	ldw r20, 16(sp)
	ldw r21, 20(sp)
	ldw r22, 24(sp)
	ldw r23, 28(sp)
	ldw sp, 32(sp)
	addi sp, sp, 36

	ret

DRAW_SCREEN_PLAYER_BOARD:
	subi sp, sp, 36
	stw r16, (sp)
	stw r17, 4(sp)
	stw r18, 8(sp)
	stw r19, 12(sp)
	stw r20, 16(sp)
	stw r21, 20(sp)
	stw r22, 24(sp)
	stw r23, 28(sp)
	stw ra, 32(sp)

	movia r16, PREVIOUS_MOVE
	ldw r16, 0(r16)

	movi r17, 0x88
	beq r16, r17,PLAYER_1_BOARD

PLAYER_2_BOARD:
	movia r17, PLAYER_1_EMPTY
	br START_DRAW_BOARD

PLAYER_1_BOARD:
	movia r17, PLAYER_2_EMPTY

START_DRAW_BOARD:
	movia r16, ADDR_VGA
	movia r18, XCOUNT
	movia r19, YCOUNT


	addi r17, r17, 138
	ldw r18, 0(r18)
	ldw r19, 0(r19)
	mov r20, r0

DRAW_Y_P:
	beq r19, r0, STOP_LOOP_P
DRAW_X_P:
	beq r20, r18, SUB1_Y_P
	muli r22, r20, 2
	add r23, r16, r22
	muli r22, r19, 1024
	add r23, r23, r22

	ldh r21, 0(r17)
	sthio r21, 0(r23)
	addi r17, r17, 2

	addi r20, r20, 1
	br DRAW_X_P

SUB1_Y_P:
	mov r20, r0
	subi r19, r19, 1
	br DRAW_Y_P

STOP_LOOP_P:
    movia r16,GAME_BOARD
    movia r17,BOX_COORDINATES_X
    movia r18,BOX_COORDINATES_Y

    addi  r16,r16,36
    addi  r17,r17,36
    addi  r18,r18,36
    movi  r19,9

BOARD_LOOP:
    addi  r16,r16,-4
    addi  r17,r17,-4
    addi  r18,r18,-4
    addi  r19,r19,-1

    ldw   r5,(r17)
    ldw   r6,(r18)

    ldw   r20,(r16)
    beq   r20,r0,CONTINUE_BOARD_LOOP
    movi  r21,0x34
    beq   r20,r21,DRAW_O_SYMBOL

DRAW_X_SYMBOL:
	movia r4,X_SYMBOL
    call  DRAW_SYMBOL
    br    CONTINUE_BOARD_LOOP

DRAW_O_SYMBOL:
    movia r4,O_SYMBOL
    call  DRAW_SYMBOL

CONTINUE_BOARD_LOOP:
    bne   r19,r0,BOARD_LOOP

STOP_BOARD_LOOP:
	ldw r16, (sp)
	ldw r17, 4(sp)
	ldw r18, 8(sp)
	ldw r19, 12(sp)
	ldw r20, 16(sp)
	ldw r21, 20(sp)
	ldw r22, 24(sp)
	ldw r23, 28(sp)
	ldw ra, 32(sp)

	addi sp, sp, 36

	ret

DRAW_ON_BOARD:
	subi  sp, sp, 16
	stw   ra,(sp)
  stw   r16,4(sp)
  stw   r17,8(sp)
	stw   r18,12(sp)

	movia r16, PREVIOUS_MOVE
	ldw r16, 0(r16)

	movi r17, 0x88
	beq r16, r17, X_TURN

O_TURN:
	movi r16, 0x88
	br START_CHECK

X_TURN:
	movi r16, 0x34

START_CHECK:
	movia r17, GAME_BOARD

	call  BOX_CLICKED_ALL
	beq   r2, r0, DRAW_BEGIN_2

  addi  r18, r0, 0x1
  beq   r2, r18, UPPER_LEFT

  addi  r18, r0, 0x2
  beq   r2, r18, UPPER_MIDDLE

  addi  r18, r0, 0x3
  beq   r2, r18, UPPER_RIGHT

  addi  r18, r0, 0x4
  beq   r2, r18, MIDDLE_LEFT

  addi  r18, r0, 0x5
  beq   r2, r18, MIDDLE_MIDDLE

  addi  r18, r0, 0x6
  beq   r2, r18, MIDDLE_RIGHT

  addi  r18, r0, 0x7
  beq   r2, r18, LOWER_LEFT

  addi  r18, r0, 0x8
  beq   r2, r18, LOWER_MIDDLE

  addi  r18, r0, 0x9
  beq   r2, r18, LOWER_RIGHT

UPPER_LEFT:
  ldw   r18,(r17)
	bne   r18,r0,DRAW_BEGIN_2
	
	movi  r4,0
	call  ADJUST_X_POSITION
	
	movi  r4,0
	call  ADJUST_Y_POSITION
	
	call  MOTOR3_FORWARD
    movia r4,5000000
    call  DELAY
	
	call  MOTOR3_OFF
	movia r4,100000000
    call  DELAY
	
	call  MOTOR3_REVERSE
    movia r4,5000000
    call  DELAY
	
	call  MOTOR3_OFF
	
	stw   r16,(r17)
	br    DRAW_BEGIN

UPPER_MIDDLE:
	ldw   r18,4(r17)
	bne   r18,r0,DRAW_BEGIN_2
	
	movi  r4,1
	call  ADJUST_X_POSITION
	
	movi  r4,0
	call  ADJUST_Y_POSITION
	
	call  MOTOR3_FORWARD
    movia r4,5000000
    call  DELAY
	
	call  MOTOR3_OFF
	movia r4,100000000
    call  DELAY
	
	call  MOTOR3_REVERSE
    movia r4,5000000
    call  DELAY
	
	call  MOTOR3_OFF
	
	stw   r16,4(r17)
	br    DRAW_BEGIN

UPPER_RIGHT:
	ldw   r18,8(r17)
	bne   r18,r0,DRAW_BEGIN_2
	
	movi  r4,2
	call  ADJUST_X_POSITION
	
	movi  r4,0
	call  ADJUST_Y_POSITION
	
	call  MOTOR3_FORWARD
    movia r4,5000000
    call  DELAY
	
	call  MOTOR3_OFF
	movia r4,100000000
    call  DELAY
	
	call  MOTOR3_REVERSE
    movia r4,5000000
    call  DELAY
	
	call  MOTOR3_OFF
	
	stw   r16,8(r17)
	br    DRAW_BEGIN

MIDDLE_LEFT:
	ldw   r18,12(r17)
	bne   r18,r0,DRAW_BEGIN_2
	
	movi  r4,0
	call  ADJUST_X_POSITION
	
	movi  r4,1
	call  ADJUST_Y_POSITION
	
	call  MOTOR3_FORWARD
    movia r4,5000000
    call  DELAY
	
	call  MOTOR3_OFF
	movia r4,100000000
    call  DELAY
	
	call  MOTOR3_REVERSE
    movia r4,5000000
    call  DELAY
	
	call  MOTOR3_OFF
	
	stw   r16,12(r17)
	br    DRAW_BEGIN

MIDDLE_MIDDLE:
	ldw   r18,16(r17)
	bne   r18,r0,DRAW_BEGIN_2
	
	movi  r4,1
	call  ADJUST_X_POSITION
	
	movi  r4,1
	call  ADJUST_Y_POSITION
	
	call  MOTOR3_FORWARD
    movia r4,5000000
    call  DELAY
	
	call  MOTOR3_OFF
	movia r4,100000000
    call  DELAY
	
	call  MOTOR3_REVERSE
    movia r4,5000000
    call  DELAY
	
	call  MOTOR3_OFF
	
	stw   r16,16(r17)
	br    DRAW_BEGIN

MIDDLE_RIGHT:
	ldw   r18,20(r17)
	bne   r18,r0,DRAW_BEGIN_2
	
	movi  r4,2
	call  ADJUST_X_POSITION
	
	movi  r4,1
	call  ADJUST_Y_POSITION
	
	call  MOTOR3_FORWARD
    movia r4,5000000
    call  DELAY
	
	call  MOTOR3_OFF
	movia r4,100000000
    call  DELAY
	
	call  MOTOR3_REVERSE
    movia r4,5000000
    call  DELAY
	
	call  MOTOR3_OFF
	
	stw   r16,20(r17)
	br    DRAW_BEGIN

LOWER_LEFT:
	ldw   r18,24(r17)
	bne   r18,r0,DRAW_BEGIN_2
	
	movi  r4,0
	call  ADJUST_X_POSITION
	
	movi  r4,2
	call  ADJUST_Y_POSITION
	
	call  MOTOR3_FORWARD
    movia r4,5000000
    call  DELAY
	
	call  MOTOR3_OFF
	movia r4,100000000
    call  DELAY
	
	call  MOTOR3_REVERSE
    movia r4,5000000
    call  DELAY
	
	call  MOTOR3_OFF
	
	stw   r16,24(r17)
	br    DRAW_BEGIN

LOWER_MIDDLE:
	ldw   r18,28(r17)
	bne   r18,r0,DRAW_BEGIN_2
	
	movi  r4,1
	call  ADJUST_X_POSITION
	
	movi  r4,2
	call  ADJUST_Y_POSITION
	
	call  MOTOR3_FORWARD
    movia r4,5000000
    call  DELAY
	
	call  MOTOR3_OFF
	movia r4,100000000
    call  DELAY
	
	call  MOTOR3_REVERSE
    movia r4,5000000
    call  DELAY
	
	call  MOTOR3_OFF
	
    stw   r16,28(r17)
	br    DRAW_BEGIN

LOWER_RIGHT:
	ldw   r18,32(r17)
	bne   r18,r0,DRAW_BEGIN_2
	
	movi  r4,2
	call  ADJUST_X_POSITION
	
	movi  r4,2
	call  ADJUST_Y_POSITION
	
	call  MOTOR3_FORWARD
    movia r4,5000000
    call  DELAY
	
	call  MOTOR3_OFF
	movia r4,100000000
    call  DELAY
	
	call  MOTOR3_REVERSE
    movia r4,5000000
    call  DELAY
	
	call  MOTOR3_OFF
	
    stw   r16,32(r17)
	br    DRAW_BEGIN

DRAW_BEGIN:
		movia r17, PREVIOUS_MOVE
		stw   r16, 0(r17)
DRAW_BEGIN_2:
		ldw   ra,(sp)
    ldw   r16,4(sp)
    ldw   r17,8(sp)
		ldw   r18,12(sp)
		addi  sp,sp,16

	ret

BOX_CLICKED_ALL:
	subi  sp, sp, 4
	stw   ra, 0(sp)
	mov   r2, r0

START_BOX_CHECK:
	call  CLICK_RECT_2
	beq   r2,r0,EXIT_BOX_CLICKED_ALL
	movi  r6, 40
	movi  r7, 40

BOX_1_CLICKED:
    movi  r4,53
    movi  r5,40
    call  CLICK_RECT_1

    beq   r2,r0,BOX_2_CLICKED
	movui r2, 0x1
	br    EXIT_BOX_CLICKED_ALL

BOX_2_CLICKED:
    movi  r4,125
    movi  r5,40
    call  CLICK_RECT_1

    beq   r2,r0,BOX_3_CLICKED
    movui r2, 0x2
	br    EXIT_BOX_CLICKED_ALL

BOX_3_CLICKED:
    movi  r4,205
    movi  r5,40
    call  CLICK_RECT_1

    beq   r2,r0,BOX_4_CLICKED
	movui r2, 0x3
	br    EXIT_BOX_CLICKED_ALL

BOX_4_CLICKED:
    movi  r4,53
    movi  r5,91
    call  CLICK_RECT_1

    beq   r2,r0,BOX_5_CLICKED
	movui r2, 0x4
	br    EXIT_BOX_CLICKED_ALL

BOX_5_CLICKED:
    movi  r4,125
    movi  r5,91
    call  CLICK_RECT_1

    beq   r2,r0,BOX_6_CLICKED
	movui r2, 0x5
	br    EXIT_BOX_CLICKED_ALL

BOX_6_CLICKED:
    movi  r4,205
    movi  r5,91
    call  CLICK_RECT_1

    beq   r2,r0,BOX_7_CLICKED
	movui r2, 0x6
	br    EXIT_BOX_CLICKED_ALL

BOX_7_CLICKED:
    movi  r4,53
    movi  r5,160
    call  CLICK_RECT_1

    beq   r2,r0,BOX_8_CLICKED
	movui r2, 0x7
	br    EXIT_BOX_CLICKED_ALL

BOX_8_CLICKED:
    movi  r4,125
    movi  r5,160
    call  CLICK_RECT_1

    beq   r2,r0,BOX_9_CLICKED
	movui r2, 0x8
	br    EXIT_BOX_CLICKED_ALL

BOX_9_CLICKED:
    movi  r4,205
    movi  r5,160
    call  CLICK_RECT_1

    beq   r2,r0,EXIT_BOX_CLICKED_ALL
	movui r2, 0x9

EXIT_BOX_CLICKED_ALL:
	ldw   ra, 0(sp)
	addi  sp, sp, 4

	ret

DRAW_SYMBOL:
	  subi sp, sp, 36
	  stw r16, 0(sp)
	  stw r17, 4(sp)
	  stw r18, 8(sp)
	  stw r19, 12(sp)
	  stw r20, 16(sp)
	  stw r21, 20(sp)
	  stw r22, 24(sp)
	  stw r23, 28(sp)
	  stw ra, 32(sp)

	  # r17 stores the bitmap of the x or o
	  # r18 stores the smallest y coordinate of the symbol to be drawn
	  # r19 stores the lower left x-coordinate to start drawing
	  # r20 stores the largest x-coordinate to be drawn (the one on the right)
	  # r21 is temporary register to a) do the pixel location = 2*x + 1024*y and b) move the color to the pixel buffer
	  # r22 is the lower left y-coordinate to start drawing
	  # r23 is used to store the value of pixel location = 2*x + 1024*y (so that, in terms of registers r23 = 2*r19 + 1024*r22)
	  movia r16, ADDR_VGA

	  mov r17, r4 # r4 contained the address to the x/o bitmap
	  mov r19, r5 # r5 contained the x-coordinate to draw the symbol
	  mov r22, r6 # r6 contained the y-coordinate to draw the symbol
		addi r17, r17, 138

DRAW_SYMBOL_BEGIN:
		addi r20, r19, 40 # Largest x-coordinate
		subi r18, r22, 40 # Smallest y coordinate

DRAW_Y_SYMB:
		beq r22, r18, STOP_DRAWING # Check if looped through y coordinates 40 times
DRAW_X_SYMB:
		beq r19, r20, SUB1_Y_SYMB # Check if looped through x coordinates 40 times

		muli r21, r19, 2
		add r23, r16, r21
		muli r21, r22, 1024
		add r23, r23, r21

		ldh r21, 0(r17)
		sthio r21, 0(r23)
		addi r17, r17, 2

		addi r19, r19, 1
		br DRAW_X_SYMB

SUB1_Y_SYMB:
		subi r19, r20, 40
		subi r22, r22, 1 # Move 1 up
		br DRAW_Y_SYMB

STOP_DRAWING:
	  ldw r16, 0(sp)
	  ldw r17, 4(sp)
	  ldw r18, 8(sp)
	  ldw r19, 12(sp)
	  ldw r20, 16(sp)
	  ldw r21, 20(sp)
	  ldw r22, 24(sp)
	  ldw r23, 28(sp)
	  ldw ra, 32(sp)
	  addi sp, sp, 36
	  ret

# Possible win states:
# 1) ...|---|---
# 2) ---|...|---
# 3) ---|---|...
# 4) .--|-.-|--.
# 5) --.|-.-|.--
# 6) .--|.--|.--
# 7) -.-|-.-|-.-
# 8) --.|--.|--.

TEST_WIN:
    movia r8, GAME_BOARD
    ldw r10, 0(r8)

FIRST_WIN_CONDITION:
    bne r4, r10, SECOND_WIN_CONDITION

    addi r9, r8, 4
    ldw r10, 0(r9)
    bne r4, r10, SECOND_WIN_CONDITION

    addi r9, r8, 8
    ldw r10, 0(r9)
    bne r4, r10, SECOND_WIN_CONDITION

    br WIN

SECOND_WIN_CONDITION:
    addi r9, r8, 12
    ldw r10, 0(r9)
    bne r4, r10, THIRD_WIN_CONDITION

    addi r9, r8, 16
    ldw r10, 0(r9)
    bne r4, r10, THIRD_WIN_CONDITION

    addi r9, r8, 20
    ldw r10, 0(r9)
    bne r4, r10, THIRD_WIN_CONDITION

    br WIN

THIRD_WIN_CONDITION:
    addi r9, r8, 24
    ldw r10, 0(r9)
    bne r4, r10, FOURTH_WIN_CONDITION

    addi r9, r8, 28
    ldw r10, 0(r9)
    bne r4, r10, FOURTH_WIN_CONDITION

    addi r9, r8, 32
    ldw r10, 0(r9)
    bne r4, r10, FOURTH_WIN_CONDITION

    br WIN

FOURTH_WIN_CONDITION:
    ldw r10, 0(r8)
    bne r4, r10, FIFTH_WIN_CONDITION

    addi r9, r8, 16
    ldw r10, 0(r9)
    bne r4, r10, FIFTH_WIN_CONDITION

    addi r9, r8, 32
    ldw r10, 0(r9)
    bne r4, r10, FIFTH_WIN_CONDITION

    br WIN

FIFTH_WIN_CONDITION:
    addi r9, r8, 8
    ldw r10, 0(r9)
    bne r4, r10, SIXTH_WIN_CONDITION

    addi r9, r8, 16
    ldw r10, 0(r9)
    bne r4, r10, SIXTH_WIN_CONDITION

    addi r9, r8, 24
    ldw r10, 0(r9)
    bne r4, r10, SIXTH_WIN_CONDITION

    br WIN

SIXTH_WIN_CONDITION:
    ldw r10, 0(r8)
    bne r4, r10, SEVENTH_WIN_CONDITION

    addi r9, r8, 12
    ldw r10, 0(r9)
    bne r4, r10, SEVENTH_WIN_CONDITION

    addi r9, r8, 24
    ldw r10, 0(r9)
    bne r4, r10, SEVENTH_WIN_CONDITION

    br WIN

SEVENTH_WIN_CONDITION:
    addi r9, r8, 4
    ldw r10, 0(r9)
    bne r4, r10, EIGHTH_WIN_CONDITION

    addi r9, r8, 16
    ldw r10, 0(r9)
    bne r4, r10, EIGHTH_WIN_CONDITION

    addi r9, r8, 28
    ldw r10, 0(r9)
    bne r4, r10, EIGHTH_WIN_CONDITION

    br WIN

EIGHTH_WIN_CONDITION:
    addi r9, r8, 8
    ldw r10, 0(r9)
		    bne r4, r10, NO_WIN

		    addi r9, r8, 20
		    ldw r10, 0(r9)
		    bne r4, r10, NO_WIN

		    addi r9, r8, 32
		    ldw r10, 0(r9)
		    bne r4, r10, NO_WIN

		    br WIN

		NO_WIN:
		    mov r2, r0
		    br EXIT

		WIN:
		    addi r8, r0, 1
		    mov r2, r8
		    br EXIT

		EXIT:
		    ret



TEST_STALEMATE:
		    # Stalemate occurs when there are no further moves available, and no one has
		    # one yet. This specifically occurs when all the board elements are filled
		    # Return 0 if not stalemate, 1 if stalemate

		    subi sp, sp, 16
		    stw r16, 0(sp)
		    stw r17, 4(sp)
		    stw r18, 8(sp)
		    stw ra, 12(sp)

		    movia r16, GAME_BOARD
		    movi r17, 9

		LOOP_UNTIL_NINE:
		    beq r17, r0, STOP_CHECKING
		    ldw r18, 0(r16)
		    beq r18, r0, STILL_POSSIBLE_MOVES
		    subi r17, r17, 1
		    addi r16, r16, 4
		    br LOOP_UNTIL_NINE

		STILL_POSSIBLE_MOVES:
		    mov r2, r0
		    br EXIT_TEST

		STOP_CHECKING:
		    movi r2, 1
		    br EXIT_TEST

		EXIT_TEST:
		    ldw r16, 0(sp)
		    ldw r17, 4(sp)
		    ldw r18, 8(sp)
		    ldw ra, 12(sp)
		    addi sp, sp, 16
		    ret


CLICK_RECT_1:
    addi  sp,sp,-12
    stw   ra,(sp)
    stw   r16,4(sp)
    stw   r17,8(sp)

    movia r16,X_POSITION
    ldw   r16,(r16)
    add   r17,r4,r6

    blt   r16,r4,NOT_CLICKED_1
    bge   r16,r17,NOT_CLICKED_1

    movia r16,Y_POSITION
    ldw   r16,(r16)
    add   r17,r5,r7

    blt   r16,r5,NOT_CLICKED_1
    bge   r16,r17,NOT_CLICKED_1

CLICKED_1:
    movi  r2,1
    br CLICK_RECT_EXIT_1

NOT_CLICKED_1:
    mov   r2,r0

CLICK_RECT_EXIT_1:
    ldw   ra,(sp)
    ldw   r16,4(sp)
    ldw   r17,8(sp)
    addi  sp,sp,12

    ret

CLICK_RECT_2:
    addi  sp,sp,-8
    stw   ra,(sp)
    stw   r16,4(sp)

    movia r16,MOUSE_BUTTONS
    ldw   r16,(r16)
    andi  r16,r16,1

    beq   r16,r0,NOT_CLICKED_2

CLICKED_2:
    movi  r2,1
    br CLICK_RECT_EXIT_2

NOT_CLICKED_2:
    mov   r2,r0

CLICK_RECT_EXIT_2:
    ldw   ra,(sp)
    ldw   r16,4(sp)
    addi  sp,sp,8

    ret

DELAY:
    addi  sp, sp, -12
    stw   ra, (sp)
    stw   r16, 4(sp)
    stw   r17, 8(sp)

    movia r16, TIMER

    stwio r0, (r16)
    stwio r4, 8(r16)

    srli  r17, r4, 16
    stwio r17, 12(r16)

    movi  r17, 4
    stwio r17, 4(r16)

POLL_DELAY:
    ldwio r17, (r16)
    andi  r17, r17, 1
    beq   r17, r0, POLL_DELAY

    ldw   ra, (sp)
    ldw   r16, 4(sp)
    ldw   r17, 8(sp)
    addi  sp, sp, 12

    ret

REDRAW_CURSOR:
    addi  sp,sp,-16
    stw   ra,(sp)
    stw   r16,4(sp)
    stw   r17,8(sp)
    stw   r18,12(sp)

ERASE_CURSOR:
    movia r16,Y_CURSOR
    ldw   r16,(r16)

    movia r17,X_CURSOR
    ldw   r17,(r17)

    slli  r16,r16,9
    add   r16,r16,r17
    slli  r16,r16,1

    movia r17,PIXEL_BUFFER
    add   r16,r16,r17

    movia r18,0
    sthio r18,(r16)

UPDATE_CURSOR:
    movia r16,X_POSITION
    ldw   r16,(r16)

    movia r17,X_CURSOR
    stw   r16,(r17)

    movia r16,Y_POSITION
    ldw   r16,(r16)

    movia r17,Y_CURSOR
    stw   r16,(r17)

DRAW_CURSOR:
    movia r16,Y_CURSOR
    ldw   r16,(r16)

    movia r17,X_CURSOR
    ldw   r17,(r17)

    slli  r16,r16,9
    add   r16,r16,r17
    slli  r16,r16,1

    movia r17,PIXEL_BUFFER
    add   r16,r16,r17

	movia r17,0xFFFF
    sthio r17,(r16)

    ldw   ra,(sp)
    ldw   r16,4(sp)
    ldw   r17,8(sp)
    ldw   r18,12(sp)
    addi  sp,sp,16

    ret

READ_MOUSE_PACKET:
    addi  sp,sp,-16
    stw   ra,(sp)
    stw   r16,4(sp)
    stw   r17,8(sp)
    stw   r18,12(sp)

    call  READ_MOUSE_COMMAND
    movia r16,MOUSE_BUTTONS
    stw   r2,(r16)
    mov   r17,r2

READ_X_MOVEMENT:
    call  READ_MOUSE_COMMAND
    andi  r16,r17,0x10

    beq   r16,r0,POSITIVE_X_MOVEMENT
NEGATIVE_X_MOVEMENT:
    movia r16,X_POSITION
    ldw   r18,(r16)
    movia r16,0xFFFFFF00
    or    r16,r16,r2
    add   r18,r18,r16
	bge   r18,r0,NEGATIVE_X_MOVEMENT_UPDATE
	movi  r18,0

NEGATIVE_X_MOVEMENT_UPDATE:
    movia r16,X_POSITION
    stw   r18,(r16)

    br READ_Y_MOVEMENT

POSITIVE_X_MOVEMENT:
    movia r16,X_POSITION
    ldw   r18,(r16)
    add   r18,r18,r2
	movi  r16,320
    blt   r18,r16,POSITIVE_X_MOVEMENT_UPDATE
	movi  r18,319

POSITIVE_X_MOVEMENT_UPDATE:
    movia r16,X_POSITION
    stw   r18,(r16)

READ_Y_MOVEMENT:
    call  READ_MOUSE_COMMAND
    andi  r16,r17,0x20

    beq   r16,r0,POSITIVE_Y_MOVEMENT
NEGATIVE_Y_MOVEMENT:
    movia r16,Y_POSITION
    ldw   r18,(r16)
    movia r16,0xFFFFFF00
    or    r16,r16,r2
    sub   r18,r18,r16
	movi  r16,240
    blt   r18,r16,NEGATIVE_Y_MOVEMENT_UPDATE
	movi  r18,239

NEGATIVE_Y_MOVEMENT_UPDATE:
    movia r16,Y_POSITION
    stw   r18,(r16)

    br READ_MOUSE_PACKET_EXIT

POSITIVE_Y_MOVEMENT:
    movia r16,Y_POSITION
    ldw   r18,(r16)
    sub   r18,r18,r2
    bge   r18,r0,POSITIVE_Y_MOVEMENT_UPDATE
	movi  r18,0

POSITIVE_Y_MOVEMENT_UPDATE:
    stw   r18,(r16)

READ_MOUSE_PACKET_EXIT:
    ldw   ra,(sp)
    ldw   r16,4(sp)
    ldw   r17,8(sp)
    ldw   r18,12(sp)
    addi  sp,sp,16

    ret

RESET_MOUSE:
    addi  sp,sp,-4
    stw   ra,(sp)

    movi  r4,0xFF
    call  SEND_MOUSE_COMMAND
    call  READ_MOUSE_COMMAND
    #call  READ_MOUSE_COMMAND
    call  READ_MOUSE_COMMAND

    movi  r4,0xF4
    call  SEND_MOUSE_COMMAND
    call  READ_MOUSE_COMMAND

    ldw   ra,(sp)
    addi  sp,sp,4

    ret

SEND_MOUSE_COMMAND:
    addi  sp,sp,-8
    stw   ra,(sp)
    stw   r16,4(sp)

    movia r16,MOUSE
    stwio r4,(r16)

    ldw   ra,(sp)
    ldw   r16,4(sp)
    addi  sp,sp,8

    ret

READ_MOUSE_COMMAND:
    addi  sp,sp,-12
    stw   ra,(sp)
    stw   r16,4(sp)
    stw   r17,8(sp)

    movia r16,MOUSE

POLL_READ_MOUSE:
    ldwio r17,(r16)
    mov   r2,r17
    andi  r2,r2,0xFF
    andi  r17,r17,0x8000
    beq   r17,r0,POLL_READ_MOUSE

    ldw   ra,(sp)
    ldw   r16,4(sp)
    ldw   r17,8(sp)
    addi  sp,sp,12

    ret

DRAW_RECT:
    addi  sp,sp,-20
    stw   ra,(sp)
    stw   r16,4(sp)
    stw   r17,8(sp)
    stw   r18,12(sp)
    stw   r19,16(sp)

    mov   r16,r7
DRAW_RECT_OUTER_LOOP:
    addi  r16,r16,-1

    mov   r17,r6
DRAW_RECT_INNER_LOOP:
    addi  r17,r17,-1

    add   r18,r5,r16
    slli  r18,r18,9

    add   r18,r18,r4
    add   r18,r18,r17
    slli  r18,r18,1

    movia r19,PIXEL_BUFFER
    add   r18,r18,r19

    ldw   r19,20(sp)
    sthio r19,(r18)

    bne   r17,r0,DRAW_RECT_INNER_LOOP
    bne   r16,r0,DRAW_RECT_OUTER_LOOP

    ldw   ra,(sp)
    ldw   r16,4(sp)
    ldw   r17,8(sp)
    ldw   r18,12(sp)
    ldw   r19,16(sp)
    addi  sp,sp,20

    ret

MOTOR1_OFF:
    addi  sp,sp,-12
    stw   ra,(sp)
    stw   r16,4(sp)
    stw   r17,8(sp)

    movia r16,LEGO_CONTROLLER
    ldwio r17,(r16)
    ori   r17,r17,1
    stwio r17,(r16)

    ldw   ra,(sp)
    ldw   r16,4(sp)
    ldw   r17,8(sp)
    addi  sp,sp,12

    ret

MOTOR1_FORWARD:
    addi  sp,sp,-16
    stw   ra,(sp)
    stw   r16,4(sp)
    stw   r17,8(sp)
    stw   r18,12(sp)

    movia r16,LEGO_CONTROLLER
    ldwio r17,(r16)
    movia r18,0xFFFFFFFC
    and   r17,r17,r18
    stwio r17,(r16)

    ldw   ra,(sp)
    ldw   r16,4(sp)
    ldw   r17,8(sp)
    ldw   r18,12(sp)
    addi  sp,sp,16

    ret

MOTOR1_REVERSE:
    addi  sp,sp,-16
    stw   ra,(sp)
    stw   r16,4(sp)
    stw   r17,8(sp)
    stw   r18,12(sp)

    movia r16,LEGO_CONTROLLER
    ldwio r17,(r16)
    movia r18,0xFFFFFFFE
    and   r17,r17,r18
    ori   r17,r17,2
    stwio r17,(r16)

    ldw   ra,(sp)
    ldw   r16,4(sp)
    ldw   r17,8(sp)
    ldw   r18,12(sp)
    addi  sp,sp,16

    ret

MOTOR2_OFF:
    addi  sp,sp,-12
    stw   ra,(sp)
    stw   r16,4(sp)
    stw   r17,8(sp)

    movia r16,LEGO_CONTROLLER
    ldwio r17,(r16)
    ori   r17,r17,4
    stwio r17,(r16)

    ldw   ra,(sp)
    ldw   r16,4(sp)
    ldw   r17,8(sp)
    addi  sp,sp,12

    ret

MOTOR2_FORWARD:
    addi  sp,sp,-16
    stw   ra,(sp)
    stw   r16,4(sp)
    stw   r17,8(sp)
    stw   r18,12(sp)

    movia r16,LEGO_CONTROLLER
    ldwio r17,(r16)
    movia r18,0xFFFFFFF3
    and   r17,r17,r18
    stwio r17,(r16)

    ldw   ra,(sp)
    ldw   r16,4(sp)
    ldw   r17,8(sp)
    ldw   r18,12(sp)
    addi  sp,sp,16

    ret

MOTOR2_REVERSE:
    addi  sp,sp,-16
    stw   ra,(sp)
    stw   r16,4(sp)
    stw   r17,8(sp)
    stw   r18,12(sp)

    movia r16,LEGO_CONTROLLER
    ldwio r17,(r16)
    movia r18,0xFFFFFFFB
    and   r17,r17,r18
    ori   r17,r17,8
    stwio r17,(r16)

    ldw   ra,(sp)
    ldw   r16,4(sp)
    ldw   r17,8(sp)
    ldw   r18,12(sp)
    addi  sp,sp,16

    ret

MOTOR3_OFF:
    addi  sp,sp,-12
    stw   ra,(sp)
    stw   r16,4(sp)
    stw   r17,8(sp)

    movia r16,LEGO_CONTROLLER
    ldwio r17,(r16)
    ori   r17,r17,16
    stwio r17,(r16)

    ldw   ra,(sp)
    ldw   r16,4(sp)
    ldw   r17,8(sp)
    addi  sp,sp,12

    ret

MOTOR3_FORWARD:
    addi  sp,sp,-16
    stw   ra,(sp)
    stw   r16,4(sp)
    stw   r17,8(sp)
    stw   r18,12(sp)

    movia r16,LEGO_CONTROLLER
    ldwio r17,(r16)
    movia r18,0xFFFFFFCF
    and   r17,r17,r18
    stwio r17,(r16)

    ldw   ra,(sp)
    ldw   r16,4(sp)
    ldw   r17,8(sp)
    ldw   r18,12(sp)
    addi  sp,sp,16

    ret

MOTOR3_REVERSE:
    addi  sp,sp,-16
    stw   ra,(sp)
    stw   r16,4(sp)
    stw   r17,8(sp)
    stw   r18,12(sp)

    movia r16,LEGO_CONTROLLER
    ldwio r17,(r16)
    movia r18,0xFFFFFFEF
    and   r17,r17,r18
    ori   r17,r17,32
    stwio r17,(r16)

    ldw   ra,(sp)
    ldw   r16,4(sp)
    ldw   r17,8(sp)
    ldw   r18,12(sp)
    addi  sp,sp,16

    ret

ADJUST_X_POSITION:
    addi  sp,sp,-16
    stw   ra,(sp)
    stw   r16,4(sp)
    stw   r17,8(sp)
    stw   r18,12(sp)

    movia r16,X_CRANE
    ldw   r17,(r16)
    mov   r18,r4

CHECK_X_POSITION:
    beq   r17,r18,ADJUST_X_POSITION_EXIT
    blt   r17,r18,MOVE_RIGHT
MOVE_LEFT:
    call  MOTOR1_FORWARD
    movia r4,50000000
    call  DELAY
    addi  r17,r17,-1

    br    CHECK_X_POSITION

MOVE_RIGHT:
    call  MOTOR1_REVERSE
    movia r4,50000000
    call  DELAY
    addi  r17,r17,1

    br    CHECK_X_POSITION

ADJUST_X_POSITION_EXIT:
    call  MOTOR1_OFF
    stw   r17,(r16)

    ldw   ra,(sp)
    ldw   r16,4(sp)
    ldw   r17,8(sp)
    ldw   r18,12(sp)
    addi  sp,sp,16

    ret

ADJUST_Y_POSITION:
    addi  sp,sp,-16
    stw   ra,(sp)
    stw   r16,4(sp)
    stw   r17,8(sp)
    stw   r18,12(sp)

    movia r16,Y_CRANE
    ldw   r17,(r16)
    mov   r18,r4

CHECK_Y_POSITION:
    beq   r17,r18,ADJUST_Y_POSITION_EXIT
    blt   r17,r18,MOVE_UP
MOVE_DOWN:
    call  MOTOR2_FORWARD
    movia r4,40000000
    call  DELAY
    addi  r17,r17,-1

    br    CHECK_Y_POSITION

MOVE_UP:
    call  MOTOR2_REVERSE
    movia r4,40000000
    call  DELAY
    addi  r17,r17,1

    br    CHECK_Y_POSITION

ADJUST_Y_POSITION_EXIT:
    call  MOTOR2_OFF
    stw   r17,(r16)

    ldw   ra,(sp)
    ldw   r16,4(sp)
    ldw   r17,8(sp)
    ldw   r18,12(sp)
    addi  sp,sp,16

    ret

READ_SENSOR0:
    addi  sp,sp,-16
    stw   ra,(sp)
    stw   r16,4(sp)
    stw   r17,8(sp)
    stw   r18,12(sp)

    movia r16,LEGO_CONTROLLER
    ldwio r17,(r16)

    movia r18,0xFFFFFBFF
    and   r17,r17,r18
    stwio r17,(r16)

POLL_READ_SENSOR0:
    ldwio r4,(r16)
    andi  r18,r4, 0x0800
    bne   r18,r0,POLL_READ_SENSOR0

    ori   r17,r17,0x0400
    stwio r17,(r16)

    srli  r4,r4,27
    andi  r4,r4,0xF

    ldw   ra,(sp)
    ldw   r16,4(sp)
    ldw   r17,8(sp)
    ldw   r18,12(sp)
    addi  sp,sp,16

    ret

READ_SENSOR1:
    addi  sp,sp,-16
    stw   ra,(sp)
    stw   r16,4(sp)
    stw   r17,8(sp)
    stw   r18,12(sp)

    movia r16,LEGO_CONTROLLER
    ldwio r17,(r16)

    movia r18,0xFFFFEFFF
    and   r17,r17,r18
    stwio r17,(r16)

POLL_READ_SENSOR1:
    ldwio r4,(r16)
    andi  r18,r4,0x2000
    bne   r18,r0,POLL_READ_SENSOR1

    ori   r17,r17, 0x1000
    stwio r17,(r16)

    srli  r4,r4,27
    andi  r4,r4,0xF

    ldw   ra,(sp)
    ldw   r16,4(sp)
    ldw   r17,8(sp)
    ldw   r18,12(sp)
    addi  sp,sp,16

    ret
