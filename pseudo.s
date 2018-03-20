.section .data
# address of devices
# VGA (video buffer?)
# TIMER 1
# PS2 - 1 -  KEYBOARD
# GPIO (for hex keypad)
# Audio Core

# IMAGES (don't know how VGA works)
# TODO - figure out how to store and load images into VGA 
# documentation: http://www-ug.eecg.utoronto.ca/desl/nios_devices_SoC/dev_videobuffer.html

# AUDIO Samples?
# documentaion: 

# location of score of each player
PLAYER1: 
    .skip 4
PLAYER2:
    .skip 4

# current player
# set to initial starting player
CURRENTPLAYER:
    .skip 4
PREVIOUSPLAYER:
    .skip 4

# location of CHOSEN
# maybe have them initialized as 0?
LOC1:
    .skip 4
LOC2:
    .skip 4
# number of selected cards
NUMSELECTED:
    .word 0

# Array of cards
# EITHER PREFILL BEFOREHAND? OR FILL depending on level?
# proposed dataStructure
struct cards{
    int number; //numbwe 
    bool flipped; 
    # store image here? or address to image 
}
cards[16]

# timer value : after peiod elapses player loses his/her turn?
.equ PERIOD, somethin


.global _start
.section .text

_start:
    INITSHITS:
    # init devices
    
    # draw shits on screen
    # flip cards
    # flip cards back

    # start game
    # start timer (if we're doing that)
    # enables interrupts for GPIO (PS2 for first implementation) /TIMER

    BIGBOYLOOP:


.section .exceptions, "ax"
IHANDLER:
    # disable interrupts (set PIE to 0)
    # check cause of interrupt
    br to TIMER_IH, if TIMER
    br to INPUT_IH if HEX PAD / PS2  
    br EXIT_IH 

    TIMER_IH:
    # do some shit
    br EXIT_IH

    INPUT_IH:
    # do some shit
    br EXIT_IH



EXIT_IH:
# restore shits
subi ea, ea, 4
eret



# check if selected pair is valid pair
checkIfPair:
# save registers (ra + used)
# restore registers (ra + used)
    ret


# updateScore
# r4 - player (or address of player score location)
# r5 - score to add (+1/-1)
updateScore:
    ret


drawAllCards:
    # goes through all cards and draws them at different locations
    # if bool flipped draws back facing card, 
    # implementation will depend on wha




