#basic data structure done
#main loop done
#checkIfPair done
#update score done
#interrupt handler for user input started - restoring and checking values (does not include receiving and using user input )


#still to do: 
#all inits
#start game - flip cards on timer
.equ MAXPIXOFFSET,  0x3BE7E # 2*(319) + 1024*(239) = 245374
.equ MAXCHAROFFSET, 0x1DCF  # 79 + 128*(59) = 7631
.equ MAXSQUAREOFFSET, 0xEC76  # 2*(59) + 1024*(59) = 60534


.equ JTAGUART, 0xFF201000
.equ BUTTONS, 0xFF200050
.equ TIMER, 0xFF202000
.equ pixelBase, 0x08000000
.equ charBase,  0x09000000

.global _start
.section .text

_start:
INIT:
    # init devices
    call initJTAGUART
    #call initTimer
    movia r4, START
    call drawScreen #start image

    #enable correct IRQ lines
    movia r10, 0b100000000
    wrctl ctl3, r10 #enable IRQ8 for JTAG

    #enable PIE
    movia r10, 1
    wrctl ctl0, r10 #enable interrupts globally on processor



WaitForStartLoop:
    movia r9, BUTTONS
    ldwio r9, 0(r9)
    beq r9, r0, WaitForStartLoop
    # break out of loop when triggered by button press
    
GameSetUp:
    movia r4, ALL_UP
    call drawScreen #front of cards
    
    #wait for timer
    movia r4, 0x1DCD6500 #period 
    call Timer
    movia r4, ALL_DOWN
    call drawScreen #back of cards



MainLoop:
    movia r9, MAXSCORE
	ldw r9, 0(r9)
    movia r10, PLAYER1
	ldw r10, 0(r10)
    beq r10, r9, gameDone #player 1 wins
    movia r10, PLAYER2
	ldw r10, 0(r10)
    beq r10, r9, gameDone #player 2 wins
    br MainLoop

gameDone:
    #call displayWinner - press button to start
    call restoreFlipped

    #restore LOC1 and LOC2
    movia r9, LOC1
    movia r10, LOC2
    movi r11, -1
    stw r11, 0(r9) #restore LOC2
    stw r11, 0(r10) #restore LOC1

    #restore score
    movia r10, PLAYER1
    movia r11, PLAYER2
    ldw r0, 0(r10)
    ldw r0, 0(r11)
	
	movi r10, 1
	movia r11, CURRENTPLAYER
	ldw r10, 0(r11)
    br WaitForStartLoop


initJTAGUART:
movia r9, JTAGUART
movia r10, 0b01
stwio r10, 4(r9) #turns interrupts on device
ret


 Timer:
   movia r20, TIMER #load address into register
   mov r16, r4 # load period to run timer
   andi  r21, r16, 0xFFFF # take lower 16 bits
   srli  r22, r16, 16 #take upper 16 bits

#load period into timer
   stwio r21, 8(r20) #load LSB into periodl
   stwio r22, 12(r20) #load MSB into periodh

   stwio r0, (r20) #reset timer

   movi r16, 0b100
   stwio r16, 4(r20) #start the timer by turning on 3rd bit

   loop:
   ldwio r16, 0(r20) #loads value of timer into r16
   andi r16, r16, 0b1 #if bit is 0, timer is still busy
   beq r0, r16, loop #branches if timer is still busy

DelayFinished:
   ret



#######################################################################
#display stuff
drawScreen:
	subi sp, sp, 4
	stw ra, 0(sp)
    movia r8, pixelBase
    mov r9, r4

    # r10 - temp storage for x
    # r11 - temp storage for y
    movi r10, 0
    movi r11, 0

    drawBigLoop:
    mov r4, r10
    mov r5, r11
    call computePixOffset
    # chetck if offscreen 
    movia r12, MAXPIXOFFSET
    bgt r2, r12, drawingDone
    add r12, r2, r8 # store address of pixel
    
    # load color from image
    ldh r13, 0(r9)
    sthio r13, 0(r12)
    
    # check if new row
    movi r12, 319
    bgt r10, r12, incRow 
    addi r9, r9, 2   # increment file address by 2 bytes (color = 16bits)
    addi r10, r10, 1 # increment x counter
    br drawBigLoop

    incRow: 
        addi r11, r11, 1
        movi r10, 0
        br drawBigLoop

    drawingDone: 
		ldw ra, 0(sp)
	addi sp, sp, 4
        ret


# compute pix offset
# offset = 2*x + 1024*y
# r4: x, r5: y
# returns offset in r2
computePixOffset:
    muli r4, r4, 2
    muli r5, r5, 1024
    add r2, r4, r5
    ret

# compute char offset
# offset = x + 128*y
# r4: x, r5: y
# returns offset in r2
computeCharOffset:
    muli r5, r5, 128
    add r2, r4, r5
    ret
drawBoard:
	subi sp, sp, 4
	stw ra, 0(sp) 
    movi r16, 0 # current squar ecounter
    movia r17, s00 # offsets
    movia r18, img0

    drawBoardBigLoop:
    movi r20, 15 # r20 temp register
    bgt r16, r20, drawingBoardDone # check if board done

    # call function to check if flipped
	mov r4, r16 #card number goes in r4
    call checkIfFlipped
	#r2 = 1 if card is flipped, 0 if not flipped
    beq r2, r0, incrementSquare #if not flipped, increment square
    # branches to flipped up if true    
    flippedUp:
    # get starting_offset for box --> passed address = 4*(r16) + STARTING_OFFSETS
    muli r20, r16, 4
    # get image address = sizeimg*(r16) + FACEUP_IMG
    # img size = 8K = 8*1024 = 8192
    muli r21, r16, 7200
    
    # clear registers
    movi r5, 0
    movi r4, 0
    add r5, r20, r17 # starting offset + square offset
    # add source of image
    add r4, r18, r21
    call drawSquare

    incrementSquare:
    addi r16, r16, 1
    br drawBoardBigLoop

    drawingBoardDone:
	ldw ra, 0(sp)
	addi sp, sp, 4
ret

# .global drawSquare
# DRAW SQUARE #
# draws 60x60 square given loc & file
# r4 - address of image
# r5 - starting offest (position)
drawSquare:
    # store ra
    subi sp, sp, 4
    stw ra, 0(sp)
    
    movia r8, pixelBase
    mov r9, r4  # img 
    # mov r14, r5 # start offset
	ldw r14, 0(r5)

    # r10 - temp storage for x
    # r11 - temp storage for y
    movi r10, 0
    movi r11, 0

    drawSquareBigLoop:
    mov r4, r10
    mov r5, r11

    call computePixOffset
    
    # chetck if offscreen 
    movia r12, MAXSQUAREOFFSET
    bgt r2, r12, drawingSquareDone
    add r12, r8, r14
    add r12, r12, r2 # store address of pixel
    
    # load color from image
    ldh r13, 0(r9)
	# movia r13, 0xFFBE
    sthio r13, 0(r12)
    
    # check if new row
    movi r12, 59
    bgt r10, r12, incSquareRow 
    addi r9, r9, 2   # increment file address by 2 bytes (color = 16bits)
    addi r10, r10, 1 # increment x counter
    br drawSquareBigLoop

    incSquareRow: 
        addi r11, r11, 1
        movi r10, 0
        br drawSquareBigLoop

    drawingSquareDone: 
        # restore ra
        ldw ra, 0(sp)
        addi sp, sp, 4
        ret


###############################################################################################################
#data


.section .data
# address of devices
# VGA (video buffer?)
# TIMER 1
# PS2 - 1 -  KEYBOARD
# GPIO (for hex keypad)
# Audio Core

# images
# audio samples

### MAX POSSIBLE SCORE ##
MAXSCORE: .word 8

### SCORES ###
PLAYER1: 
    .word 0
PLAYER2:
    .word 0

### CURRENT PLAYER ## initialized to player 1
CURRENTPLAYER:
    .word 1

### LOCATION OF CHOSEN CARDs ###
LOC1:
    .word -1
LOC2:
    .word -1

### NUMBER OF SELECTED CARDS ###
NUMSELECTED:
    .word 0

### CARD VALUES AND FLIPPED BOOLEAN ###
CARDS:
    A:  .word 3 #value
        .word 0 #flipped
    B:  .word 2 #value
        .word 0 #flipped
    C:  .word 1 #value
        .word 0 #flipped
    D:  .word 4 #value
        .word 0 #flipped
    E:  .word 1 #value
        .word 0 #flipped
    F:  .word 4 #value
        .word 0 #flipped
    G:  .word 7 #value
        .word 0 #flipped
    H:  .word 8 #value
        .word 0 #flipped
    I:  .word 5 #value
        .word 0 #flipped
    J:  .word 2 #value
        .word 0 #flipped
    K:  .word 3 #value
        .word 0 #flipped
    L:  .word 6 #value
        .word 0 #flipped
    M:  .word 6 #value
        .word 0 #flipped
    N:  .word 5 #value
        .word 0 #flipped
    O:  .word 8 #value
        .word 0 #flipped
    P:  .word 7 #value
        .word 0 #flipped

#####IMAGES#######
STARTING_OFFSETS:
    s00: .word 0x09E    # 2*(79) + 1024(0) = 0x9E
    s01: .word 0x0116   # 2*(139) + 1024(0)
    s02: .word 0x018E   # 2*(199) + 1024(0)
    s03: .word 0x0206   # 2*(259) + 1024(0)
    s04: .word 0x0EC9E  # 2*(79) + 1024(59)
    s05: .word 0x0ED16  # 2*(139) + 1024(59)
    s06: .word 0x0ED8E  # 2*(199) + 1024(59)
    s07: .word 0x0EE06  # 2*(259) + 1024(59)
    s08: .word 0x01DC9E # 2*(79) + 1024(119)
    s09: .word 0x01DD16 # 2*(139) + 1024(119)
    s10: .word 0x01DD8E # 2*(199) + 1024(119)
    s11: .word 0x01DE06 # 2*(259) + 1024(119)
    s12: .word 0x02CC9E # 2*(79) + 1024(179)
    s13: .word 0x02CD16 # 2*(139) + 1024(179)
    s14: .word 0x02CD8E # 2*(199) + 1024(179)
    s15: .word 0x02CE06 # 2*(259) + 1024(179)

ALL_DOWN: .incbin "img_bin/test_alldown.bin"

ALL_UP: .incbin "img_bin/test_allup.bin"

BG: .incbin "img_bin/test_bg.bin"

START: .incbin "img_bin/test_start.bin"

FACEUP_IMG: 
    img0: .incbin "img_bin/test_flipped_60x60.bin"
    img1: .incbin "img_bin/test_flipped_60x60.bin"
    img2: .incbin "img_bin/test_flipped_60x60.bin"
    img3: .incbin "img_bin/test_flipped_60x60.bin"
    img4: .incbin "img_bin/test_flipped_60x60.bin"
    img5: .incbin "img_bin/test_flipped_60x60.bin"
    img6: .incbin "img_bin/test_flipped_60x60.bin"
    img7: .incbin "img_bin/test_flipped_60x60.bin"
    img8: .incbin "img_bin/test_flipped_60x60.bin"
    img9: .incbin "img_bin/test_flipped_60x60.bin"
    img10: .incbin "img_bin/test_flipped_60x60.bin"
    img11: .incbin "img_bin/test_flipped_60x60.bin"
    img12: .incbin "img_bin/test_flipped_60x60.bin"
    img13: .incbin "img_bin/test_flipped_60x60.bin"
    img14: .incbin "img_bin/test_flipped_60x60.bin"
    img15: .incbin "img_bin/test_flipped_60x60.bin"

################################################################################################################
.section .exceptions, "ax"
IHANDLER:
    subi sp, sp, 12
    stw r9, 0(sp)
    stw r10, 4(sp)
    stw ea, 8(sp) #not necessary currently - only once we add timer
    wrctl ctl0, r0 #disable interrupts (set PIE to 0)

    rdctl et, ctl4
    andi et, et, 0b100000000 # check if interrupt pending from IRQ8 (ctl4:bit8)
    movi r8, 0b100000000
    beq et, r8, INPUT_IH 
    br EXIT_IH 

    INPUT_IH:
    #check number selected
    movi r19, CARDS
    movi r16, NUMSELECTED
    ldw r23, 0(r16) #r16 holds the number of cards currently selected
    beq r23, r0, firstSelected
    br secondSelected

    firstSelected:
        #update LOC1
        movi r4, LOC1
        call updateLOC

        #change flipped value of selected card
        movi r18, LOC1
        ldw r4, 0(r18) 
        movi r5, 1
        call changeFlippedValue
       
        #update NUMSELECTED
        movi r17, 1
        stw r17, 0(r16)
        br EXIT_IH

    secondSelected:
        #update LOC2
        movi r4, LOC2
        call updateLOC

        #change flipped value (boolean) of selected card
        movi r18, LOC2
        ldw r4, 0(r18) 
        movi r5, 1
        call changeFlippedValue
        
        call checkIfPair
        beq r0, r2, pairNotFound
        #else pair was found
        call updateScore
        br prepareNextTurn

        pairNotFound:		
		movi r4, ALL_DOWN
    	call drawScreen #back of cardsdq
    	call drawBoard 
        movia r4, 0x1DCD6500 #set timer period
        call Timer

        movi r18, LOC1
        ldw r4, 0(r18) 
        movi r5, 0
        call changeFlippedValue
        
        movi r18, LOC2
        ldw r4, 0(r18) 
        movi r5, 0
        call changeFlippedValue
        
        prepareNextTurn:
        #restore LOC1 and LOC2
        movi r20, LOC1
        movi r18, LOC2
        movi r17, -1
        stw r17, 0(r20) #restore LOC2
        stw r17, 0(r18) #restore LOC1

        #restore NUMSELECTED
        movi r17, 0
        stw r17, 0(r16)

        #update current and previous player
        movi r17, 1
        movi r20, CURRENTPLAYER
        ldw r21, 0(r20) 
        beq r17, r21, player2Next
        #else player 1 next
        movi r17, 1
        stw r17, 0(r20)
        br EXIT_IH

        player2Next:
        movi r17, 2
        stw r17, 0(r20)
        
    EXIT_IH:
	movi r4, ALL_DOWN
    call drawScreen #back of cardsdq
    call drawBoard      
    ldw r9, 0(sp)
    ldw r10, 4(sp)
    ldw ea, 8(sp)  #not necessary currently - only once we add timer
    addi sp, sp, 12
    movi r22, 1
    wrctl ctl1, r22 #enable interrupts (set PIE to 1)
    subi ea, ea, 4
eret

checkIfPair:
    movi r8, CARDS

    movi r9, LOC1
    ldw r9, 0(r9) 
    muli r9, r9, 8
    add r9, r9, r8 #r9 holds address of card
    ldw r9, 0(r9) #r9 holds value of card at LOC1

    movi r8, CARDS
    movi r10, LOC2
    ldw r10, 0(r10) 
    muli r10, r10, 8
    add r10, r10, r8 #r10 holds address of card
    ldw r10, 0(r10) #r10 holds value of card at LOC2

    beq r9, r10, foundPair
    #not a pair
    movi r2, 0
    br doneChecking

foundPair:
    movi r2, 1

doneChecking:
    ret


# updateScore - increment by 1
updateScore:
    movi r8, CURRENTPLAYER
    ldw r8, 0(r8)
    movi r10, 1
    beq r8, r10, incP1Score
    #else increment player 2 score
    movi r9, PLAYER2
    br doneScore

incP1Score:
    movi r9, PLAYER1

doneScore:      
    ldw r11, 0(r9)
    addi r11, r11, 1
    stw r11, 0(r9)
ret

#r4 - card number
# r5 - number to change flipped value to
changeFlippedValue: 
    movi r19, CARDS
    muli r20, r4, 8
    add r20, r20, r19 #r4 holds address of card 
    stw r5, 4(r20) #change flipped value to value
ret

#r4 = card number
#r2 - 1 if flipped, 0 if not
checkIfFlipped:
    movi r19, CARDS
    muli r20, r4, 8
    add r20, r20, r19
    ldw r2, 4(r20)
ret


restoreFlipped:
    subi sp, sp, 4
    stw ra, 0(sp)
    movi r5, 0
    movi r4, 0
    movi r8, 16
    Flip:
    call changeFlippedValue
    addi r4, r4, 1
    bne r4, r8, Flip
    ldw ra, 0(sp)
    addi sp, sp, 4
ret

#r4 - address of LOC1 or LOC2
updateLOC:
movia r10, JTAGUART
ldwio r10, 0(r10) #Load from the JTAG
andi  r10, r10, 0x00FF # Data read is now in r10

convertCharacter:
    movi r11, '0'
    beq r10, r11, Zeroto0
    movi r11, '1'
    beq r10, r11, Oneto1
    movi r11, '2'
    beq r10, r11, Twoto2
    movi r11, '3'
    beq r10, r11, Threeto3  
    movi r11, '4'
    beq r10, r11, Fourto4
    movi r11, '5'
    beq r10, r11, Fiveto5
    movi r11, '6'
    beq r10, r11, Sixto6
    movi r11, '7'
    beq r10, r11, Sevento7
    movi r11, '8'
    beq r10, r11, Eightto8
    movi r11, '9'
    beq r10, r11, Nineto9
    movi r11, 'a'
    beq r10, r11, Ato10
    movi r11, 'b'
    beq r10, r11, Bto11
    movi r11, 'c'
    beq r10, r11, Cto12
    movi r11, 'd'
    beq r10, r11, Dto13
    movi r11, 'e'
    beq r10, r11, Eto14
    movi r11, 'f'
    beq r10, r11, Fto15
    br doneUpdatingLOC

    Zeroto0: movi r11, 0
        br doneUpdatingLOC
    Oneto1: movi r11, 1
        br doneUpdatingLOC
    Twoto2: movi r11, 2
        br doneUpdatingLOC
    Threeto3: movi r11, 3
        br doneUpdatingLOC
    Fourto4: movi r11, 4
        br doneUpdatingLOC
    Fiveto5: movi r11, 5
        br doneUpdatingLOC
    Sixto6: movi r11, 6
        br doneUpdatingLOC
    Sevento7: movi r11, 7
        br doneUpdatingLOC
    Eightto8: movi r11, 8
        br doneUpdatingLOC
    Nineto9: movi r11, 9
        br doneUpdatingLOC
    Ato10: movi r11, 10
        br doneUpdatingLOC
    Bto11: movi r11, 11
        br doneUpdatingLOC  
    Cto12: movi r11, 12
        br doneUpdatingLOC
    Dto13: movi r11, 13
        br doneUpdatingLOC  
    Eto14: movi r11, 14
        br doneUpdatingLOC  
    Fto15: movi r11, 15
        br doneUpdatingLOC

doneUpdatingLOC:
    stwio r11, 0(r4)
ret
