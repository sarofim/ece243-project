#basic data structure done
#main loop done
#checkIfPair done
#update score done
#interrupt handler for user input started - restoring and checking values (does not include receiving and using user input )


#still to do: 
#all inits
#start game - flip cards on timer

.equ JTAGUART, 0xFF201000
.equ BUTTONS, 0xFF200050
.equ TIMER, 0xFF202000
.equ JP1, 0xFF200060


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
MAXSCORE: .word 1

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


# timer value : after peiod elapses player loses his/her turn?
#.equ PERIODLOW, somethin


.global _start
.section .text

_start:
INIT:
    # init devices
    call initJTAGUART
	call initHex
    #call initTimer
    #call drawScreen - start image

    #enable correct IRQ lines
	movia r10, 0b100100000000
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

    #call drawScreen - front of cards
    
    #wait for timer
    movia r4, 0x5F5E100 #period 
    call Timer
    #call drawScreen - back of cards



MainLoop:
    movi r9, MAXSCORE
	ldw r9, 0(r9)
    movi r10, PLAYER1
	ldw r10, 0(r10)
    beq r10, r9, gameDone #player 1 wins
    movi r10, PLAYER2
	ldw r10, 0(r10)
    beq r10, r9, gameDone #player 2 wins
    br MainLoop

gameDone:
    #call displayWinner - press button to start
    call restoreFlipped

    #restore LOC1 and LOC2
    movi r9, LOC1
    movi r10, LOC2
    movi r11, -1
    stw r11, 0(r9) #restore LOC2
    stw r11, 0(r10) #restore LOC1

    #restore score
    movi r10, PLAYER1
    movi r11, PLAYER2
    ldw r0, 0(r10)
    ldw r0, 0(r11)
	
	movi r10, 1
	movi r11, CURRENTPLAYER
	ldw r10, 0(r11)
    br WaitForStartLoop


initJTAGUART:
movia r9, JTAGUART
movia r10, 0b01
stwio r10, 4(r9) #turns interrupts on device
ret

initHex:
movia r9, JP1

#Lower bits - rows
#enable rows as inputs
movia r8, 0xF0 #0 - input
stwio r8, 4(r9) #direction register (input = 0, output = 1)

#enable correct interrupt bits - COLUMNS AS INPUTS
movia r8, 0x0F
stwio r8, 8(r9) #interrupt register (rows trigger interrupt)
stwio r0, 0(r9) #write 0 to all output pins
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

################################################################################################################
.section .exceptions, "ax"
IHANDLER:
    subi sp, sp, 12
    stw r9, 0(sp)
    stw r10, 4(sp)
    stw ea, 8(sp) #not necessary currently - only once we add timer

	#check if HEX keypad (JP1) caused interrupt
	movi r9, JP1
	rdctl et, ctl4
    andi et, et, 0b100000000000 # check if interrupt pending from IRQ11
    movi r8, 0b100000000000
	
    wrctl ctl0, r0 #disable interrupts
    bne et, r8, I_EXIT #if not JP1

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
        movi r18, LOC1
        ldw r4, 0(r18) 
        movi r5, 0
        call changeFlippedValue

        #call drawAllCards
        movia r4, 0x5F5E100 #set timer period
        call Timer
        
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
    # call drawScreen - back of cardsdq
    # call drawAllCards  
	movi r9, JP1
	movia r8, 0xFFFFFFFF
	stw r8, 12(r9)
    
    ldw r9, 0(sp)
    ldw r10, 4(sp)
    ldw ea, 8(sp)  #not necessary currently - only once we add timer
    addi sp, sp, 12
    movi r22, 1
    wrctl ctl0, r22 #enable interrupts (set PIE to 1)
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

drawAllCards:
ret

#r4 - address of LOC1 or LOC2
updateLOC:
movi r9, JP1
    #read in rows (inputs)
    ldwio r10, 0(r9) #r10 holds values
    andi  r10,r10,0xf # Mask out all but last 4 bits  - row values (0 = pressed)

    nor r10, r0, r10 #equivalent of ~r4 - 1 = pressed

    #reconfigure so columns are inputs - bits 4-7 are inputs
	movia r8, 0x0F #0 - input
	stwio r8, 4(r9) #direction register (input = 0, output = 1) 
	stwio r0, 0(r9) #write 0 to all output pins
    
    ldwio r11, 0(r9) #r10 holds values
	andi  r11,r11,0xf0 # Mask out all but inputs (4-7)
	srli r11, r11, 4 #4 bits right

    nor r11, r0, r11 #equivalent of ~r4 - 1 = pressed 

    #r11 holds columns, r10 holds rows

    movi r12, 0b1000
    beq, r10, r12, row0
    movi r12, 0b0100
    beq, r10, r12, row1
    movi r12, 0b0010
    beq, r10, r12, row2
    movi r12, 0b0001
    beq, r10, r12, row3
    findColumn:
    movi r12, 0b1000
    beq, r11, r12, col3
    movi r12, 0b0100
    beq, r11, r12, col2
    movi r12, 0b0010
    beq, r11, r12, col1
    movi r12, 0b0001
    beq, r11, r12, col0
    br computeNumber

    row0: movi r10, 0
    br findColumn
    row1: movi r10, 1
    br findColumn
    row2: movi r10, 2
    br findColumn
    row3:  movi r10, 3
    br findColumn

    col0: movi r11, 0
    br computeNumber
    col1:  movi r11, 1
    br computeNumber
    col2: movi r11, 2
    br computeNumber
    col3: movi r11, 3
    br computeNumber

computeNumber:
	muli r10, r10, 4
	addi r14, r11, r10
    stwio r14, 0(r4)
ret