    # DESCRIPTION #
# functions to drawScreen : bacground, cards, 
# PIXELS : 320 x 240
# CHARS  : 80  x 60 

.text 
# VGA CONSTANTS #
.equ pixelBase, 0x08000000
.equ MAXSQUAREOFFSET, 0xEC76  # 2*(59) + 1024*(59) = 60534

.global _start

_start:

# .global drawSquare
# DRAW SQUARE #
# draws 60x60 square given loc & file
# r4 - address of image
# r5 - starting offest (position)
# drawSquare:
  
    # store ra
    # subi sp, sp, 4
    # stw ra, 0(sp)
    
    movia r8, pixelBase
    
    # load offset manually
    movia r14, s00

    # test with image
    # movia r9, 

    # mov r9, r4  # img 
    # mov r14, r5 # start offset
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
    # ldh r13, 0(r9)
	movia r13, 0xF81F
    sthio r13, 0(r12)
    
    # check if new row
    movi r12, 59
    bgt r10, r12, incRow 
    # addi r9, r9, 2   # increment file address by 2 bytes (color = 16bits)
    addi r10, r10, 1 # increment x counter
    br drawSquareBigLoop

    incRow: 
        addi r11, r11, 1
        movi r10, 0
        br drawSquareBigLoop

    drawingSquareDone: 
        # restore ra
        # ldw ra, 0(sp)
        # addi sp, sp, 4
        # ret
        br drawingSquareDone


# compute pix offset
# offset = 2*x + 1024*y
# r4: x, r5: y
# returns offset in r2
computePixOffset:
    muli r4, r4, 2
    muli r5, r5, 1024
    add r2, r4, r5
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
    s13: .word 0x02CC8B # 2*(139) + 1024(179)
    s14: .word 0x02CD8E # 2*(199) + 1024(179)
    s15: .word 0x02CE06 # 2*(259) + 1024(179)

# images #
# trying wit different colors rn #
# FACEDOWN_IMG: .incbin "test_down_60x60.bin"