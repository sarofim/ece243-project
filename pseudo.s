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
    INIT:
    # init devices
    #display initial screen
    
    WaitForStartLoop:
    # start timer (if we're doing that)
    # enables interrupts for GPIO (PS2 for first implementation) /TIMER
    # break out of loop when triggered by button press? (not interrupt)
    
    GameSetUp:
    # call drawAllCards
    # flip cards - have an image with all cards flipped? set timer for a certain amount of time
        #timer not interrupt based
    # flip cards back after timer

    MainLoop:
    #branch out of loop when either score reaches max value
    #display winner on screen
    #br on timer to GameDone
    
    GameDone:
    #restore flipped values
    #restore locations and scores
    #Display initial screen
    #br WaitForStartLoop

.section .exceptions, "ax"
IHANDLER:
    # disable interrupts (set PIE to 0)
    # check cause of interrupt
    br to TIMER_IH, if TIMER
    br to INPUT_IH if HEX PAD / PS2  
    br EXIT_IH 

    TIMER_IH:
    #display time out message on screen
    # change values stored in memory for current and previous player
    #restore all flipped values
    #restore numIncremented
    #restore LOC1 and LOC2
    
    br EXIT_IH

    INPUT_IH:
    #check numSelected
    #if 0
        #update LOC1
        #change flipped value (boolean) of selected card
        #increment numSelected
        #branch to EXIT_IH
    #if 1
        #update LOC2
        #change flipped value (boolean) of selected card
        # call drawAllCards - wait for timer before moving on (so it displays for a certain amount of time)
        #call checkIfPair
        #if pair, updateScore
        #restore all flipped values
        #restore LOC1 and LOC2
        #reset numSelected
        #update current and previous player
    #drawAllCards      
    br EXIT_IH

    EXIT_IH:
    # restore registers
    #enable interrupts (PIE to 1)
    subi ea, ea, 4
eret



# check if selected pair is valid pair
checkIfPair:
# save registers (ra + used)
#compare values in LOC1 and LOC2
#set return value - 0 if not pair, 1 if pair
# restore registers (ra + used)
    ret


# updateScore
updateScore:
    # increment score of current player
    ret


drawAllCards:
    # goes through all cards and draws them at the respective locations
    # if bool flipped draw face of card, 
