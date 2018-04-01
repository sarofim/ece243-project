# DESCRIPTION #
# functions to drawScreen : bacground, cards, 
# PIXELS : 320 x 240
# CHARS  : 80  x 60 

.text 
# VGA CONSTANTS #
.equ pixelBase, 0x08000000
.equ MAXSQUAREOFFSET, 0xEC76  # 2*(59) + 1024*(59) = 60534
# .global drawScreen - later when seperating into different functions
.global _start

# reg usage #

.global _start
# .global _drawBoard

_start:
# drawBoard:
    movi r16, 0 # current squar ecounter
    movia r17, STARTING_OFFSETS # offsets
    movia r18, FACEUP_IMG

    drawBoardBigLoop:
    movi r20, 15 # r20 temp register
    beq r16, r20, drawingBoardDone # check if board done

    # call function to check if flipped
    # br incrementSquare # (otherwise)
    # branches to flipped up if true    
    flippedUp:
    # get starting_offset for box --> passed address = 4*(r16) + STARTING_OFFSETS
    muli r20, r16, 4
    # get draw image (need to figure out size) - ignoring for now
    # image address = sizeimg*(r16) + FACEUP_IMG
    # muli r21, r16, img_size
    # using same image for now
    movia r5, FACEDOWN_IMG
    
    # clear registers
    movi r4, 0
    # movi r5, 0
    add r4, r20, r17 # starting offset + square offset
    # add source of image
    call drawSquare

    incrementSquare:
    addi r16, 1
    br drawBoardBigLoop

    drawingBoardDone:
        br board

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
    mov r14, r5 # start offset

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
	# movia r13, 0xF81F
    sthio r13, 0(r12)
    
    # check if new row
    movi r12, 59
    bgt r11, r12, incRow 
    addi r9, r9, 2   # increment file address by 2 bytes (color = 16bits)
    addi r10, r10, 1 # increment x counter
    br drawSquareBigLoop

    incRow: 
        addi r11, r11, 1
        movi r10, 0
        br drawSquareBigLoop

    drawingSquareDone: 
        # restore ra
        ldw ra, 0(sp)
        addi sp, sp, 4
        ret

# DATA #
.data
# offsets #
STARTING_OFFSETS:
    00: .word 0x09E    # 2*(79) + 1024(0) = 0x9E
    01: .word 0x0116   # 2*(139) + 1024(0)
    02: .word 0x018E   # 2*(199) + 1024(0)
    03: .word 0x0206   # 2*(259) + 1024(0)
    04: .word 0x0EC9E  # 2*(79) + 1024(59)
    05: .word 0x0ED16  # 2*(139) + 1024(59)
    06: .word 0x0ED8E  # 2*(199) + 1024(59)
    07: .word 0x0EE06  # 2*(259) + 1024(59)
    08: .word 0x01DC9E # 2*(79) + 1024(119)
    09: .word 0x01DD16 # 2*(139) + 1024(119)
    10: .word 0x01DD8E # 2*(199) + 1024(119)
    11: .word 0x01DE06 # 2*(259) + 1024(119)
    12: .word 0x02CC9E # 2*(79) + 1024(179)
    13: .word 0x02CC8B # 2*(139) + 1024(179)
    14: .word 0x02CD8E # 2*(199) + 1024(179)
    15: .word 0x02CE06 # 2*(259) + 1024(179)

# images #
FACEUP_IMG: 
    img0:
    img1: 
    img2: 
    img3: 
    img4:
    img5: 
    img6: 
    img7: 
    img8: 
FACEDOWN_IMG: 