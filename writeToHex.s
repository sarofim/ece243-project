.equ HEX_P1, 0xFF200030
.equ HEX_P2, 0xFF200020

# gets 4bit number - converts to appropriate 6bit hex display shit
decodeTo7seg:
    beq r4, r0, hexNum0
    movi r20, 1
    beg r4, r20, hexNum1
    movi r20, 2
    beg r4, r20, hexNum2
    movi r20, 3
    beg r4, r20, hexNum3
    movi r20, 4
    beg r4, r20, hexNum4
    movi r20, 5
    beg r4, r20, hexNum5
    movi r20, 6
    beg r4, r20, hexNum6
    movi r20, 7
    beg r4, r20, hexNum7
    movi r20, 8
    beg r4, r20, hexNum8
    movi r20, 9
    beg r4, r20, hexNum9
    movi r20, 10
    beg r4, r20, hexNumA
    movi r20, 11
    beg r4, r20, hexNumB
    movi r20, 12
    beg r4, r20, hexNumC
    movi r20, 13
    beg r4, r20, hexNumD
    movi r20, 14
    beg r4, r20, hexNumE
    movi r20, 15
    beg r4, r20, hexNumF
    br decodeExit

    hexNum0:
        movi r2, 0b0111111
        br decodeExit
    hexNum1:
        movi r2, 0b0000110
        br decodeExit
    hexNum2:
        movi r2, 0b1011011
        br decodeExit
    hexNum3:
        movi r2, 0b1001111
        br decodeExit
    hexNum4:
        movi r2, 0b1100110
        br decodeExit
    hexNum5:
        movi r2, 0b1101101
        br decodeExit
    hexNum6:
        movi r2, 0b1111101
        br decodeExit
    hexNum7:
        movi r2, 0b0000111
        br decodeExit
    hexNum8:
        movi r2, 0b1111111
        br decodeExit
    hexNum9:
        movi r2, 0b1101111
        br decodeExit
    hexNumA:
        movi r2, 0b1110111
        br decodeExit
    hexNumB:
        movi r2, 0b1111100
        br decodeExit
    hexNumC:
        movi r2, 0b0111001
        br decodeExit
    hexNumD:
        movi r2, 0b1011110
        br decodeExit
    hexNumE:
        movi r2, 0b1111001
        br decodeExit
    hexNumF:
        movi r2, 0b1110001

    decodeExit:
ret

# takes in a word
# r4 - word
# r5 - address of hex display
# computes shit
writeTo7seg:
    # save ra to stack
    subi sp, sp, 4
    stw ra, 0(sp)

    andi r20, r4, 0xF
    sri, r4, r4, 4
    
    call decodeTo7seg
    mov r21, r2
    sli r21, r21, 6

    mov r4, r20
    call decodeTo7seg
    mov r20, r2

    add r21, r21, r20
    stw r21, 0(r5)

    writeToSegExit:
    ldw ra, 0(sp)
    addi sp, sp, 4
    ret

writeScoresToHex:
    # save ra to stack
    subi sp, sp, 4
    stw ra, 0(sp)

    movia r4, PLAYER1
    ldw r4, 0(r4)
    movia r5, HEX_P1
    call writeTo7seg

    movia r4, PLAYER2
    ldw r4, 0(r4)
    movia r5, HEX_P2
    call writeTo7seg

    writeScoresExit:
    ldw ra, 0(sp)
    addi sp, sp, 4
    ret
