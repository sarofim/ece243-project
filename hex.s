.equ JP1, 0xFF200060

.global _start

start: 

interruptInit:
    #enable correct IRQ line 11
    movia r10, 0b100000000000
    wrctl ctl3, r10 #enable IRQ11 for JP1 Hex Keypad

    call HexInit
    #enable PIE
    movia r10, 1
    wrctl ctl0, r10 #enable interrupts globally on processor
    Loop:
    br Loop


HexInit:
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

################################################################################################################
.section .exceptions, "ax"
IHANDLER:
	movi r9, JP1
	rdctl et, ctl4
    andi et, et, 0b100000000000 # check if interrupt pending from IRQ8 (ctl4:bit8)
    movi r8, 0b100000000000
    bne et, r8, I_EXIT #if not JP1

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
	stw r14, 0(r4)

#r14 holds number
	I_EXIT:
    movia r8, 0xFFFFFFFF
    stw r8, 12(r9)
	subi ea, ea, 4
eret