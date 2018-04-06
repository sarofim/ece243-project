# DESCRIPTION #
# functions to drawScreen : bacground, cards, 
# PIXELS : 320 x 240
# CHARS  : 80  x 60 

.text 
# VGA CONSTANTS #
.equ pixelBase, 0x08000000
.equ MAXSQUAREOFFSET, 0xEC76  # 2*(59) + 1024*(59) = 60534
# .global drawBoard - later when seperating into different functions
.global _start

# reg usage #
# .global _drawBoard

_start:
# drawBoard: 
    movi r16, 0 # current squar ecounter
    movia r17, s00 # offsets
    movia r18, img0

    drawBoardBigLoop:
    movi r20, 15 # r20 temp register
    bgt r16, r20, drawingBoardDone # check if board done

    # call function to check if flipped
    # call CHECK_IF_FLIPPED
    # br incrementSquare # (otherwise)
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
        br drawingBoardDone 

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

# DATA #
.data
# offsets #
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

# images #
# trying wit different colors rn #
FACEUP_IMG: 
    img0: .incbin "img_bin/test_down_60x60.bin"
    img1: .incbin "img_bin/test_down_60x60.bin"
    img2: .incbin "img_bin/test_down_60x60.bin"
    img3: .incbin "img_bin/test_down_60x60.bin"
    img4: .incbin "img_bin/test_down_60x60.bin"
    img5: .incbin "img_bin/test_down_60x60.bin"
    img6: .incbin "img_bin/test_down_60x60.bin"
    img7: .incbin "img_bin/test_down_60x60.bin"
    img8: .incbin "img_bin/test_down_60x60.bin"
    img9: .incbin "img_bin/test_down_60x60.bin"
    img10: .incbin "img_bin/test_down_60x60.bin"
    img11: .incbin "img_bin/test_down_60x60.bin"
    img12: .incbin "img_bin/test_down_60x60.bin"
    img13: .incbin "img_bin/test_down_60x60.bin"
    img14: .incbin "img_bin/test_down_60x60.bin"
    img15: .incbin "img_bin/test_down_60x60.bin"