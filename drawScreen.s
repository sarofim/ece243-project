# DESCRIPTION #
# functions to drawScreen : bacground, cards, 
# PIXELS : 320 x 240
# CHARS  : 80  x 60 

.text 
# VGA CONSTANTS #
.equ pixelBase, 0x08000000
.equ charBase,  0x09000000
.equ MAXPIXOFFSET,  0x3BE7E # 2*(319) + 1024*(239) = 245374
.equ MAXCHAROFFSET, 0x1DCF  # 79 + 128*(59) = 7631

# .global drawScreen - later when seperating into different functions
.global _start

# reg usage #

_start:
# drawScreen:
    movia r8, pixelBase
    movia r9, BG
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
    sthio r9, 0(r12)
    
    # increment location counters
    addi r9, r9, 2 # increment file address by 2 bytes (color = 16bits)
    # check if new row
    movi r12, 239
    bgt r11, r12, incRow 
    addi r10, r10, 1
    br drawBigLoop

    incRow: 
        addi r11, r11, 1
        movi r10, 0
        br drawBigLoop

    drawingDone: 
        br drawingDone
        # ret - when becomes a func


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


# DATA #
.data
# images #
BG: .incbin "bg.bmp"
