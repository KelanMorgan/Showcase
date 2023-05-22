*-----------------------------------------------------------
* Title      : Endless_Runner
* Written by : Kelan Morgan
* Date       : 08/03/2023
* Description: Endless Runner Project Starter Kit
*-----------------------------------------------------------
    ORG    $1000
START:                  ; first instruction of program

*-----------------------------------------------------------
* Section       : Trap Codes
* Description   : Trap Codes used throughout StarterKit
*-----------------------------------------------------------
* Trap CODES
TC_SCREEN   EQU         33          ; Screen size information trap code
TC_S_SIZE   EQU         00          ; Places 0 in D1.L to retrieve Screen width and height in D1.L
                                    ; First 16 bit Word is screen Width and Second 16 bits is screen Height
TC_KEYCODE  EQU         19          ; Check for pressed keys
TC_DBL_BUF  EQU         92          ; Double Buffer Screen Trap Code
TC_CURSR_P  EQU         11          ; Trap code cursor position

TC_EXIT     EQU         09          ; Exit Trapcode

*-----------------------------------------------------------
* Section       : Charater Setup
* Description   : Size of Player and Enemy and properties
* of these characters e.g Starting Positions and Sizes
*-----------------------------------------------------------
PLYR_W_INIT EQU         14          ; Players initial Width
PLYR_H_INIT EQU         14          ; Players initial Height

ENMY_W_INIT EQU         14          ; Enemy initial Width
ENMY_H_INIT EQU         14          ; Enemy initial Height

*-----------------------------------------------------------
* Subroutine    : First play
* Description   : for the first time the player palays the game
*-----------------------------------------------------------
FIRST_PLAY:
    MOVE.L  #0, RECORD_TIME_M
    MOVE.L  #0, RECORD_TIME_S

*-----------------------------------------------------------
* Subroutine    : Initialise
* Description   : Initialise game data into memory such as 
* screen size and player position
*-----------------------------------------------------------
INITIALISE:
    ; Screen Size
    MOVE.B  #TC_SCREEN, D0          ; access screen information
    MOVE.L  #TC_S_SIZE, D1          ; placing 0 in D1 triggers loading screen size information
    TRAP    #15                     ; interpret D0 and D1 for screen size
    MOVE.W  D1,         SCREEN_H    ; place screen height in memory location
    SWAP    D1                      ; Swap top and bottom word to retrive screen size
    MOVE.W  D1,         SCREEN_W    ; place screen width in memory location

    ;start time
    CLR         D1
    MOVEQ       #8, d0              ; get time in 1/100 ths seconds
    TRAP        #15
    MOVE.L      D1, START_TIME      ;move the start time to the start time 

    MOVE.L      #0, RECORD_TIME

    ;Column positions
    CLR.L   D1
    MOVE.W  SCREEN_W,   D1
    DIVU.W  #2,         D1
    MOVE.W  D1,         COL_E       ; Column E value

    CLR.L   D1
    MOVE.W  COL_E,     D1      
    SUB.W   #51,       D1
    MOVE.W  D1,        COL_W        ;Column W value

    CLR.L   D1
    MOVE.W  COL_W,     D1      
    SUB.W   #51,       D1
    MOVE.W  D1,        COL_Q        ;Column Q value

    CLR.L   D1
    MOVE.W  COL_E,     D1      
    ADD.W   #51,       D1
    MOVE.W  D1,        COL_R        ;Column R value

    CLR.L   D1
    MOVE.W  COL_R,     D1      
    ADD.W   #51,       D1
    MOVE.W  D1,        COL_T        ;Column T value

    ; Place the Player at the center of the screen
    MOVE.W  COL_E,      PLAYER_X    ; Players X Position

    CLR.L   D1                      ; Clear contents of D1 (XOR is faster)
    MOVE.W  SCREEN_H,   D1          ; Place Screen width in D1
    SUB.L   #40,        D1          ; divide by 2 for center on Y Axis
    MOVE.L  D1,         PLAYER_Y    ; Players Y Position

    ; initial health and hit boolean
    MOVE.B  #0,         HIT
    MOVE.B  #3,         Health
    MOVE.B  #0,         DEAD

    ; initial speed up variable
    MOVE.B  #0,         SPEED_UPDATE  

    ;Initialize the key pressed boolean
    MOVE.L  #0,         KEY_PRESSED

    ; Initial Position for Enemy
    MOVE.W  COL_Q,      ENEMY_Q_X     ; Enemy X Position
    MOVE.L  #0,         ENEMY_Q_Y     ; Enemy Y Position

    MOVE.W  COL_W,      ENEMY_W_X     ; Enemy X Position
    MOVE.L  #0,         ENEMY_W_Y     ; Enemy Y Position

    MOVE.W  COL_E,      ENEMY_E_X     ; Enemy X Position
    MOVE.L  #0,         ENEMY_E_Y     ; Enemy Y Position

    MOVE.W  COL_R,      ENEMY_R_X     ; Enemy X Position
    MOVE.L  #0,         ENEMY_R_Y     ; Enemy Y Position

    MOVE.W  COL_T,      ENEMY_T_X     ; Enemy X Position
    MOVE.L  #0,         ENEMY_T_Y     ; Enemy Y Position

    ; Enemy default speed
    MOVE.B  #2,         ENEMY_Q_SPEED
    MOVE.B  #1,         ENEMY_W_SPEED
    MOVE.B  #1,         ENEMY_E_SPEED
    MOVE.B  #2,         ENEMY_R_SPEED
    MOVE.B  #1,         ENEMY_T_SPEED
    MOVE.L  #1,         SPEED_UPDATE

    ; Enable the screen back buffer(see easy 68k help)
	MOVE.B  #TC_DBL_BUF,D0          ; 92 Enables Double Buffer
    MOVE.B  #17,        D1          ; Combine Tasks
	TRAP	#15                     ; Trap (Perform action)

    ; Clear the screen (see easy 68k help)
    MOVE.B  #TC_CURSR_P,D0          ; Set Cursor Position
	MOVE.W  #$FF00,     D1          ; Fill Screen Clear
	TRAP	#15                     ; Trap (Perform action)

*-----------------------------------------------------------
* Subroutine    : Game
* Description   : Game including main GameLoop. GameLoop is like
* a while loop in that it runs forever until interupted
* (Input, Update, Draw). The Enemies Run at Player Jump to Avoid
*-----------------------------------------------------------
GAMELOOP:
    MOVEQ       #8,d0               ; get time in 1/100 ths seconds
    TRAP        #15
    MOVE.L      D1, ELAPSED_TIME    ; store the elapsed time

    MOVE.l    d1,-(sp)              ; push time on the stack

    ; Main Gameloop
    BSR     TIME
    BSR     SPEED_UP
    BSR     INPUT                   ; Check Keyboard Input
    BSR     UPDATE                  ; Update positions and points
    BSR     DRAW                    ; Draw the Scene
    BSR     CHECK_COLLISIONS        ; Check for Collisions

    MOVE.l    (sp)+,d7              ;pop the time from the stack into d7

*-----------------------------------------------------------
* Subroutine    : Delta Time
* Description   : makes the game have a delay based on the
* change in time since the start of the game loop
*-----------------------------------------------------------
DELTATIME:
    MOVEQ        #8,d0                ; get time in 1/100 ths seconds
    TRAP         #15

    SUB.l        d7,d1                ; subtract previous time from current time
    CMP.b        #2,d1                ; compare with 2/100ths
    BMI.s        DELTATIME            ; loop if time not up yet

    BRA        GAMELOOP               ; loop forever

*-----------------------------------------------------------
* Subroutine    : time elapsed
* Description   : calculate the time since start
*-----------------------------------------------------------
TIME:
    ; get the elapsed time
    MOVE.L  ELAPSED_TIME,   D1
    MOVE.L  START_TIME,     D2
    SUB.L   D2,             D1  

    DIVU    #100,           D1
    AND.L   #$FFFF,         D1

    ; get the minutes
    DIVU    #60,            D1
    MOVE.W  D1,             ELAPSED_TIME_M

    ;get the seconds
    SWAP    D1
    MOVE.W  D1,             ELAPSED_TIME_S
    
CHECK_RECORD_TIME:
    CLR.L   D1
    CLR.L   D2
    CLR.L   D3
    CLR.L   D4

    MOVE.W  ELAPSED_TIME_M, D1
    MOVE.W  ELAPSED_TIME_S, D2
    MOVE.W  RECORD_TIME_M,  D3
    MOVE.W  RECORD_TIME_S,  D4

    CMP.W   D1, D3
    BEQ     CHECK_RECORD_TIME_S

    CMP.W   D3, D1
    BGT     UPDATE_RECORD_TIME_M

    RTS

UPDATE_RECORD_TIME_M:
    MOVE.W  D1, RECORD_TIME_M
    MOVE.W  #0, RECORD_TIME_S

    RTS

CHECK_RECORD_TIME_S:
    CMP.W   D4, D2
    BGE     UPDATE_RECORD_TIME_S

    RTS

UPDATE_RECORD_TIME_S:
    MOVE.W  D2, RECORD_TIME_S

    RTS
*-----------------------------------------------------------
* Subroutine    : Speed up
* Description   : speeds up the game
*-----------------------------------------------------------
SPEED_UP:
    CLR.L   D1
    CLR.L   D2
    CLR.L   D3
    
    MOVE.W  ELAPSED_TIME_S, D1
    MOVE.W  ELAPSED_TIME_M, D2
    MOVE.L  SPEED_UPDATE,   D3

MINUTE_CHECK:
    CMP.B   #0, D2
    BEQ     MINUTE_0
    CMP.B   #1, D2
    BEQ     MINUTE_1
    CMP.B   #2, D2
    BEQ     MINUTE_2

    RTS

MINUTE_0:
    ; Check if it has been 5 seconds
    CMP.W   #5,     D1
    BEQ     CHECK_SPEED_UPDATE_1
    CMP.W   #10,    D1
    BEQ     CHECK_SPEED_UPDATE_2
    CMP.W   #15,    D1
    BEQ     CHECK_SPEED_UPDATE_3
    CMP.W   #20,    D1
    BEQ     CHECK_SPEED_UPDATE_4
    CMP.W   #25,    D1
    BEQ     CHECK_SPEED_UPDATE_5
    CMP.W   #30,    D1
    BEQ     CHECK_SPEED_UPDATE_6
    CMP.W   #35,    D1
    BEQ     CHECK_SPEED_UPDATE_7
    CMP.W   #40,    D1
    BEQ     CHECK_SPEED_UPDATE_8
    CMP.W   #45,    D1
    BEQ     CHECK_SPEED_UPDATE_9
    CMP.W   #50,    D1
    BEQ     CHECK_SPEED_UPDATE_10
    CMP.W   #55,    D1
    BEQ     CHECK_SPEED_UPDATE_11
    RTS

MINUTE_1:
    ; Check if it has been 5 seconds
    CMP.W   #0,     D1
    BEQ     CHECK_SPEED_UPDATE_12
    CMP.W   #5,     D1
    BEQ     CHECK_SPEED_UPDATE_13
    CMP.W   #10,    D1
    BEQ     CHECK_SPEED_UPDATE_14
    CMP.W   #15,    D1
    BEQ     CHECK_SPEED_UPDATE_15
    CMP.W   #20,    D1
    BEQ     CHECK_SPEED_UPDATE_16
    CMP.W   #25,    D1
    BEQ     CHECK_SPEED_UPDATE_17
    CMP.W   #30,    D1
    BEQ     CHECK_SPEED_UPDATE_18
    CMP.W   #35,    D1
    BEQ     CHECK_SPEED_UPDATE_19
    CMP.W   #40,    D1
    BEQ     CHECK_SPEED_UPDATE_20
    CMP.W   #45,    D1
    BEQ     CHECK_SPEED_UPDATE_21
    CMP.W   #50,    D1
    BEQ     CHECK_SPEED_UPDATE_22
    CMP.W   #55,    D1
    BEQ     CHECK_SPEED_UPDATE_23
    RTS

MINUTE_2:
    ; Check if it has been 5 seconds
    CMP.W   #0,     D1
    BEQ     CHECK_SPEED_UPDATE_24
    CMP.W   #5,     D1
    BEQ     CHECK_SPEED_UPDATE_25
    CMP.W   #10,    D1
    BEQ     CHECK_SPEED_UPDATE_26
    CMP.W   #15,    D1
    BEQ     CHECK_SPEED_UPDATE_27
    CMP.W   #20,    D1
    BEQ     CHECK_SPEED_UPDATE_28
    CMP.W   #25,    D1
    BEQ     CHECK_SPEED_UPDATE_29
    CMP.W   #30,    D1
    BEQ     CHECK_SPEED_UPDATE_30
    CMP.W   #35,    D1
    BEQ     CHECK_SPEED_UPDATE_31
    CMP.W   #40,    D1
    BEQ     CHECK_SPEED_UPDATE_32
    CMP.W   #45,    D1
    BEQ     CHECK_SPEED_UPDATE_33
    CMP.W   #50,    D1
    BEQ     CHECK_SPEED_UPDATE_34
    CMP.W   #55,    D1
    BEQ     CHECK_SPEED_UPDATE_35
    RTS

CHECK_SPEED_UPDATE_1:
    CMP     #1, D3
    BEQ     SPEED_UP_1
    RTS

SPEED_UP_1:
    ADD.B   #1, ENEMY_W_SPEED
    ADD.L   #1, SPEED_UPDATE
    RTS

CHECK_SPEED_UPDATE_2:
    CMP     #2, D3
    BEQ     SPEED_UP_2
    RTS

SPEED_UP_2:
    ADD.B   #1, ENEMY_Q_SPEED
    ADD.L   #1, SPEED_UPDATE
    RTS

CHECK_SPEED_UPDATE_3:
    CMP     #3, D3
    BEQ     SPEED_UP_3
    RTS

SPEED_UP_3:
    ADD.B   #1, ENEMY_E_SPEED
    ADD.L   #1, SPEED_UPDATE
    RTS

CHECK_SPEED_UPDATE_4:
    CMP     #4, D3
    BEQ     SPEED_UP_4
    RTS

SPEED_UP_4:
    ADD.B   #1, ENEMY_R_SPEED
    ADD.L   #1, SPEED_UPDATE
    RTS

CHECK_SPEED_UPDATE_5:
    CMP     #5, D3
    BEQ     SPEED_UP_5
    RTS

SPEED_UP_5:
    ADD.L   #1, ENEMY_W_SPEED
    ADD.L   #1, SPEED_UPDATE
    RTS

CHECK_SPEED_UPDATE_6:
    CMP     #6, D3
    BEQ     SPEED_UP_6
    RTS

SPEED_UP_6:
    ADD.B   #1, ENEMY_Q_SPEED
    ADD.L   #1, SPEED_UPDATE
    RTS

CHECK_SPEED_UPDATE_7:
    CMP     #7, D3
    BEQ     SPEED_UP_7
    RTS

SPEED_UP_7:
    ADD.B   #1, ENEMY_T_SPEED
    ADD.L   #1, SPEED_UPDATE
    RTS

CHECK_SPEED_UPDATE_8:
    CMP     #8, D3
    BEQ     SPEED_UP_8
    RTS

SPEED_UP_8:
    ADD.B   #1, ENEMY_Q_SPEED
    ADD.L   #1, SPEED_UPDATE
    RTS

CHECK_SPEED_UPDATE_9:
    CMP     #9, D3
    BEQ     SPEED_UP_9
    RTS

SPEED_UP_9:
    ADD.B   #1, ENEMY_T_SPEED
    ADD.L   #1, SPEED_UPDATE
    RTS

CHECK_SPEED_UPDATE_10:
    CMP     #10, D3
    BEQ     SPEED_UP_10
    RTS

SPEED_UP_10:
    ADD.B   #1, ENEMY_T_SPEED
    ADD.L   #1, SPEED_UPDATE
    RTS

CHECK_SPEED_UPDATE_11:
    CMP     #11, D3
    BEQ     SPEED_UP_11
    RTS

SPEED_UP_11:
    ADD.B   #1, ENEMY_W_SPEED
    ADD.L   #1, SPEED_UPDATE
    RTS

CHECK_SPEED_UPDATE_12:
    CMP     #12, D3
    BEQ     SPEED_UP_12
    RTS

SPEED_UP_12:
    ADD.B   #1, ENEMY_W_SPEED
    ADD.B   #1, ENEMY_R_SPEED
    ADD.L   #1, SPEED_UPDATE
    RTS

CHECK_SPEED_UPDATE_13:
    CMP     #13, D3
    BEQ     SPEED_UP_13
    RTS

SPEED_UP_13:
    ADD.B   #2, ENEMY_E_SPEED
    ADD.L   #1, SPEED_UPDATE
    RTS

CHECK_SPEED_UPDATE_14:
    CMP     #14, D3
    BEQ     SPEED_UP_14
    RTS

SPEED_UP_14:
    ADD.B   #1, ENEMY_Q_SPEED
    ADD.B   #1, ENEMY_R_SPEED
    ADD.L   #1, SPEED_UPDATE
    RTS

CHECK_SPEED_UPDATE_15:
    CMP     #15, D3
    BEQ     SPEED_UP_15
    RTS

SPEED_UP_15:
    ADD.B   #1, ENEMY_Q_SPEED
    ADD.B   #1, ENEMY_R_SPEED
    ADD.L   #1, SPEED_UPDATE
    RTS

CHECK_SPEED_UPDATE_16:
    CMP     #16, D3
    BEQ     SPEED_UP_16
    RTS

SPEED_UP_16:
    ADD.B   #1, ENEMY_W_SPEED
    ADD.B   #1, ENEMY_T_SPEED
    ADD.L   #1, SPEED_UPDATE
    RTS

CHECK_SPEED_UPDATE_17:
    CMP     #17, D3
    BEQ     SPEED_UP_17
    RTS

SPEED_UP_17:
    ADD.B   #1, ENEMY_E_SPEED
    ADD.B   #1, ENEMY_T_SPEED
    ADD.L   #1, SPEED_UPDATE
    RTS

CHECK_SPEED_UPDATE_18:
    CMP     #18, D3
    BEQ     SPEED_UP_18
    RTS

SPEED_UP_18:
    ADD.B   #1, ENEMY_W_SPEED
    ADD.B   #1, ENEMY_E_SPEED
    ADD.L   #1, SPEED_UPDATE
    RTS

CHECK_SPEED_UPDATE_19:
    CMP     #19, D3
    BEQ     SPEED_UP_19
    RTS

SPEED_UP_19:
    ADD.B   #1, ENEMY_E_SPEED
    ADD.B   #1, ENEMY_T_SPEED
    ADD.L   #1, SPEED_UPDATE
    RTS

CHECK_SPEED_UPDATE_20:
    CMP     #20, D3
    BEQ     SPEED_UP_20
    RTS

SPEED_UP_20:
    ADD.B   #1, ENEMY_Q_SPEED
    ADD.B   #1, ENEMY_R_SPEED
    ADD.L   #1, SPEED_UPDATE
    RTS

CHECK_SPEED_UPDATE_21:
    CMP     #21, D3
    BEQ     SPEED_UP_21
    RTS

SPEED_UP_21:
    ADD.B   #1, ENEMY_E_SPEED
    ADD.B   #1, ENEMY_T_SPEED
    ADD.L   #1, SPEED_UPDATE
    RTS

CHECK_SPEED_UPDATE_22:
    CMP     #22, D3
    BEQ     SPEED_UP_22
    RTS

SPEED_UP_22:
    ADD.B   #1, ENEMY_Q_SPEED
    ADD.B   #1, ENEMY_E_SPEED
    ADD.L   #1, SPEED_UPDATE
    RTS

CHECK_SPEED_UPDATE_23:
    CMP     #23, D3
    BEQ     SPEED_UP_23
    RTS

SPEED_UP_23:
    ADD.B   #2, ENEMY_R_SPEED
    ADD.L   #1, SPEED_UPDATE
    RTS

CHECK_SPEED_UPDATE_24:
    CMP     #24, D3
    BEQ     SPEED_UP_24
    RTS

SPEED_UP_24:
    ADD.B   #1, ENEMY_Q_SPEED
    ADD.B   #1, ENEMY_E_SPEED
    ADD.B   #1, ENEMY_R_SPEED
    ADD.L   #1, SPEED_UPDATE
    RTS

CHECK_SPEED_UPDATE_25:
    CMP     #25, D3
    BEQ     SPEED_UP_25
    RTS

SPEED_UP_25:
    ADD.B   #1, ENEMY_W_SPEED
    ADD.B   #2, ENEMY_T_SPEED
    ADD.L   #1, SPEED_UPDATE
    RTS

CHECK_SPEED_UPDATE_26:
    CMP     #26, D3
    BEQ     SPEED_UP_26
    RTS

SPEED_UP_26:
    ADD.B   #1, ENEMY_Q_SPEED
    ADD.B   #1, ENEMY_E_SPEED
    ADD.B   #1, ENEMY_T_SPEED
    ADD.L   #1, SPEED_UPDATE
    RTS

CHECK_SPEED_UPDATE_27:
    CMP     #27, D3
    BEQ     SPEED_UP_27
    RTS

SPEED_UP_27:
    ADD.B   #1, ENEMY_W_SPEED
    ADD.B   #1, ENEMY_E_SPEED
    ADD.B   #1, ENEMY_T_SPEED
    ADD.L   #1, SPEED_UPDATE
    RTS

CHECK_SPEED_UPDATE_28:
    CMP     #28, D3
    BEQ     SPEED_UP_28
    RTS

SPEED_UP_28:
    ADD.B   #1, ENEMY_Q_SPEED
    ADD.B   #2, ENEMY_W_SPEED
    ADD.L   #1, SPEED_UPDATE
    RTS

CHECK_SPEED_UPDATE_29:
    CMP     #29, D3
    BEQ     SPEED_UP_29
    RTS

SPEED_UP_29:
    ADD.B   #1, ENEMY_Q_SPEED
    ADD.B   #1, ENEMY_R_SPEED
    ADD.B   #1, ENEMY_T_SPEED
    ADD.L   #1, SPEED_UPDATE
    RTS

CHECK_SPEED_UPDATE_30:
    CMP     #30, D3
    BEQ     SPEED_UP_30
    RTS

SPEED_UP_30:
    ADD.B   #1, ENEMY_W_SPEED
    ADD.B   #1, ENEMY_E_SPEED
    ADD.B   #1, ENEMY_T_SPEED
    ADD.L   #1, SPEED_UPDATE
    RTS

CHECK_SPEED_UPDATE_31:
    CMP     #31, D3
    BEQ     SPEED_UP_31
    RTS

SPEED_UP_31:
    ADD.B   #1, ENEMY_Q_SPEED
    ADD.B   #1, ENEMY_E_SPEED
    ADD.B   #1, ENEMY_R_SPEED
    ADD.L   #1, SPEED_UPDATE
    RTS

CHECK_SPEED_UPDATE_32:
    CMP     #32, D3
    BEQ     SPEED_UP_32
    RTS

SPEED_UP_32:
    ADD.B   #1, ENEMY_Q_SPEED
    ADD.B   #1, ENEMY_R_SPEED
    ADD.B   #1, ENEMY_T_SPEED
    ADD.L   #1, SPEED_UPDATE
    RTS

CHECK_SPEED_UPDATE_33:
    CMP     #33, D3
    BEQ     SPEED_UP_33
    RTS

SPEED_UP_33:
    ADD.B   #2, ENEMY_W_SPEED
    ADD.B   #1, ENEMY_R_SPEED
    ADD.L   #1, SPEED_UPDATE
    RTS

CHECK_SPEED_UPDATE_34:
    CMP     #34, D3
    BEQ     SPEED_UP_34
    RTS

SPEED_UP_34:
    ADD.B   #1, ENEMY_W_SPEED
    ADD.B   #1, ENEMY_R_SPEED
    ADD.B   #1, ENEMY_T_SPEED
    ADD.L   #1, SPEED_UPDATE
    RTS

CHECK_SPEED_UPDATE_35:
    CMP     #35, D3
    BEQ     SPEED_UP_35
    RTS

SPEED_UP_35:
    ADD.B   #1, ENEMY_Q_SPEED
    ADD.B   #1, ENEMY_W_SPEED
    ADD.B   #1, ENEMY_R_SPEED
    ADD.L   #1, SPEED_UPDATE
    RTS

*-----------------------------------------------------------
* Subroutine    : Input
* Description   : Process Keyboard Input
*-----------------------------------------------------------
INPUT:
    ; Process Input
    CLR.L   D1                      ; Clear Data Register
    CLR.L   D2
    CLR.L   D3
    MOVE.L  KEY_PRESSED,    D3
    MOVE.B  #TC_KEYCODE,    D0          ; Listen for Keys
    MOVE.L  #$4144,         D1
    TRAP    #15                     ; Trap (Perform action)

    CMP.L   #1,         D3 ; Check if the key is still pressed
    BEQ     WAIT_KEY_RELEASE        ; If it is then wait untill it is released

PROCESS_INPUT:
    CMP.W   #$FF00, D1 
    BEQ     LEFT
    CMP.W   #$00FF, D1
    BEQ     RIGHT

    RTS

WAIT_KEY_RELEASE:                   
    CMP.W   #$0000, D1
    BEQ     ALLOW_INPUT        ; Wait until all keys are released

    RTS

ALLOW_INPUT:
    MOVE.L  #0, KEY_PRESSED     ; Allow input
    RTS

*-----------------------------------------------------------
* Subroutine    : Movement
* Description   : Move left and right
*-----------------------------------------------------------
LEFT:
    MOVE.W  COL_W,  D1
    MOVE.W  COL_E,  D2
    MOVE.W  COL_R,  D3
    MOVE.W  COL_T,  D4
    MOVE.L  #1, KEY_PRESSED

    CMP.W   PLAYER_X,   D1  ; If player is in column W move them to column Q
    BEQ     MOVE_COL_Q
    CMP.W   PLAYER_X,   D2  ; If player is in column E move them to column W
    BEQ     MOVE_COL_W
    CMP.W   PLAYER_X,   D3  ; If player is in column R move them to column E
    BEQ     MOVE_COL_E
    CMP.W   PLAYER_X,   D4  ; If player is in column T move them to column R
    BEQ     MOVE_COL_R

    RTS

RIGHT:
    MOVE.W  COL_Q,  D1
    MOVE.W  COL_W,  D2
    MOVE.W  COL_E,  D3
    MOVE.W  COL_R,  D4
    MOVE.L  #1, KEY_PRESSED

    CMP.W   PLAYER_X,   D1  ; If player is in column Q move them to column W
    BEQ     MOVE_COL_W
    CMP.W   PLAYER_X,   D2  ; If player is in column W move them to column E
    BEQ     MOVE_COL_E
    CMP.W   PLAYER_X,   D3  ; If player is in column E move them to column R
    BEQ     MOVE_COL_R
    CMP.W   PLAYER_X,   D4  ; If player is in column R move them to column T
    BEQ     MOVE_COL_T

    RTS

MOVE_COL_Q:
    MOVE.W  COL_Q,  PLAYER_X    ;move player to column Q
    BRA     WAIT_KEY_RELEASE

MOVE_COL_W:
    MOVE.W  COL_W,  PLAYER_X    ;move player to column W
    BRA     WAIT_KEY_RELEASE

MOVE_COL_E:
    MOVE.W  COL_E,  PLAYER_X    ;move player to column E
    BRA     WAIT_KEY_RELEASE

MOVE_COL_R:
    MOVE.W  COL_R,  PLAYER_X    ;move player to column R
    BRA     WAIT_KEY_RELEASE

MOVE_COL_T:
    MOVE.W  COL_T,  PLAYER_X    ;move player to column T
    BRA     WAIT_KEY_RELEASE


*-----------------------------------------------------------
* Subroutine    : Update
* Description   : Main update loop update Enemies
*-----------------------------------------------------------
UPDATE:
    CLR.L   D1                      ; Clear contents of D1 (XOR is faster)

    ; Check if enemy is off screen
    MOVE.L  ENEMY_Q_Y,  D1          ; Move the Enemy Y Position to D1
    CMP.W   SCREEN_H,   D1
    BGE     RESET_ENEMY_Q_POSITION  ; Reset Enemy if off Screen

    ; Check if enemy is off screen
    MOVE.L  ENEMY_W_Y,  D1          ; Move the Enemy Y Position to D1
    CMP.W   SCREEN_H,   D1
    BGE     RESET_ENEMY_W_POSITION  ; Reset Enemy if off Screen

    ; Check if enemy is off screen
    MOVE.L  ENEMY_E_Y,  D1          ; Move the Enemy Y Position to D1
    CMP.W   SCREEN_H,   D1
    BGE     RESET_ENEMY_E_POSITION  ; Reset Enemy if off Screen

    ; Check if enemy is off screen
    MOVE.L  ENEMY_R_Y,  D1          ; Move the Enemy Y Position to D1
    CMP.W   SCREEN_H,   D1
    BGE     RESET_ENEMY_R_POSITION  ; Reset Enemy if off Screen

    ; Check if enemy is off screen
    MOVE.L  ENEMY_T_Y,  D1          ; Move the Enemy Y Position to D1
    CMP.W   SCREEN_H,   D1
    BGE     RESET_ENEMY_T_POSITION  ; Reset Enemy if off Screen

    ; Move the Enemy
    BRA     MOVE_ENEMY              ; Move the Enemy

    RTS                             ; Return to subroutine  

*-----------------------------------------------------------
* Subroutine    : Move Enemy
* Description   : Move Enemy TOP to BOTTOM
*-----------------------------------------------------------
MOVE_ENEMY:
    CLR     D1
    CLR     D2
    CLR     D3
    CLR     D4
    CLR     D5

    MOVE.B  ENEMY_Q_SPEED,  D1
    MOVE.B  ENEMY_W_SPEED,  D2
    MOVE.B  ENEMY_E_SPEED,  D3
    MOVE.B  ENEMY_R_SPEED,  D4
    MOVE.B  ENEMY_T_SPEED,  D5

MOVE_ENEMY_Q:
    ADD.L   D1,  ENEMY_Q_Y   ; Move enemy by Y Value

MOVE_ENEMY_W:
    ADD.L   D2,  ENEMY_W_Y   ; Move enemy by Y Value

MOVE_ENEMY_E:
    ADD.L   D3,  ENEMY_E_Y   ; Move enemy by Y Value

MOVE_ENEMY_R:
    ADD.L   D4,  ENEMY_R_Y   ; Move enemy by Y Value

MOVE_ENEMY_T:
    ADD.L   D5,  ENEMY_T_Y   ; Move enemy by Y Value
    RTS

*-----------------------------------------------------------
* Subroutine    : Reset Enemy
* Description   : Reset Enemy if to passes 0 to Right of Screen
*-----------------------------------------------------------
RESET_ENEMY_Q_POSITION:
    MOVE.L  #0,         ENEMY_Q_Y     ; Enemy Y Position
    RTS

RESET_ENEMY_W_POSITION:
    MOVE.L  #0,         ENEMY_W_Y     ; Enemy Y Position
    RTS

RESET_ENEMY_E_POSITION:
    MOVE.L  #0,         ENEMY_E_Y     ; Enemy Y Position
    RTS

RESET_ENEMY_R_POSITION:
    MOVE.L  #0,         ENEMY_R_Y     ; Enemy Y Position
    RTS

RESET_ENEMY_T_POSITION:
    MOVE.L  #0,         ENEMY_T_Y     ; Enemy Y Position
    RTS

*-----------------------------------------------------------
* Subroutine    : Draw
* Description   : Draw Screen
*-----------------------------------------------------------
DRAW: 
    ; Clear the screen
    MOVE.B	#TC_CURSR_P,D0          ; Set Cursor Position
	MOVE.W	#$FF00,     D1          ; Clear contents
	TRAP    #15                     ; Trap (Perform action)

    BSR     DRAW_PLYR_DATA          ; Draw Draw Score, HUD, Player X and Y
    BSR     DRAW_PLAYER             ; Draw Player
    BSR     DRAW_ENEMYS             ; Draw Enemy
    BSR     DRAW_LANES              ; Draw lanes

    ; Enable back buffer
    MOVE.B  #94,        D0
    TRAP    #15

    RTS                             ; Return to subroutine

*-----------------------------------------------------------
* Subroutine    : Draw Player Data
* Description   : Draw Player X, Y, Velocity, Gravity and OnGround
*-----------------------------------------------------------
DRAW_PLYR_DATA:
    CLR.L   D1                      ; Clear contents of D1 (XOR is faster)

    ; Player TIME Message
    MOVE.B  #TC_CURSR_P,D0          ; Set Cursor Position
    MOVE.W  #$0201,     D1          ; Col 02, Row 01
    TRAP    #15                     ; Trap (Perform action)
    LEA     ELAPSED_TIME_MSG,  A1   ; TIME Message
    MOVE    #14,        D0          ; No Line feed
    TRAP    #15                     ; Trap (Perform action)

    ; Time minutes                   
    MOVE.B  #03,        D0          ; Display number at D1.L
    MOVE.W  ELAPSED_TIME_M,D1       ; Move TIME to D1.L
    TRAP    #15                     ; Trap (Perform action)

    ; Time divider
    LEA     TIME_DIVIDER,   A1
    MOVE.B  #14,            D0
    TRAP    #15

    ; Time seconds
    MOVE.W  ELAPSED_TIME_S, D1
    MOVE.B  #3,             D0
    TRAP    #15

    CLR.L   D1
    ; Player Record TIME Message
    MOVE.B  #TC_CURSR_P,    D0          ; Set Cursor Position
    MOVE.W  #$0202,         D1          ; Col 02, Row 01
    TRAP    #15                         ; Trap (Perform action)
    LEA     RECORD_TIME_MSG,    A1      ; TIME Message
    MOVE    #14,            D0          ; No Line feed
    TRAP    #15                         ; Trap (Perform action)

    ; Time minutes                   
    MOVE.B  #03,            D0          ; Display number at D1.L
    MOVE.W  RECORD_TIME_M,  D1          ; Move TIME to D1.L
    TRAP    #15                         ; Trap (Perform action)

    ; Time divider
    LEA     TIME_DIVIDER,   A1
    MOVE.B  #14,            D0
    TRAP    #15

    ; Time seconds
    MOVE.W  RECORD_TIME_S,  D1
    MOVE.B  #3,             D0
    TRAP    #15

    ; box for player control message
    CLR.L   D1
    CLR.L   D2
    CLR.L   D3
    CLR.L   D4
    MOVE.B  #87,    D0
    MOVE.W  #10,    D1
    MOVE.W  #70,    D2
    MOVE.W  #85,    D3
    MOVE.W  #95,    D4
    TRAP    #15

    ; Player Control Message
    MOVE.B  #TC_CURSR_P,D0          ; Set Cursor Position
    MOVE.W  #$0205,     D1          ; Col 02, Row 05
    TRAP    #15                     ; Trap (Perform action)
    LEA     CONTROLS_MSG, A1
    MOVE    #14,        D0
    TRAP    #15

    ; Left Message
    MOVE.B  #TC_CURSR_P,D0          ; Set Cursor Position
    MOVE.W  #$0207,     D1          ; Col 02, Row 07
    TRAP    #15                     ; Trap (Perform action)
    LEA     LEFT_MSG, A1
    MOVE    #14,        D0
    TRAP    #15

    ; Right Message
    MOVE.B  #TC_CURSR_P,D0          ; Set Cursor Position
    MOVE.W  #$0208,     D1          ; Col 02, Row 08
    TRAP    #15                     ; Trap (Perform action)
    LEA     RIGHT_MSG, A1
    MOVE    #14,        D0
    TRAP    #15

    ; Display Health and Message
    MOVE.B  #TC_CURSR_P,D0          ; Set Cursor Position
    MOVE.W  #$4001,     D1          ; Col 64, Row 01
    TRAP    #15                     ; Trap (Perform action)
    CLR.L   D1
    LEA     HEALTH_MSG, A1
    MOVE.B  HEALTH,     D1
    MOVE    #17,        D0
    TRAP    #15
    
    CMP.B   #1, DEAD
    BEQ     DISPLAY_PLAY_AGAIN

    RTS

DISPLAY_PLAY_AGAIN:
    ; Display play again Message
    MOVE.B  #TC_CURSR_P,D0          ; Set Cursor Position
    MOVE.W  #$3A03,     D1          ; Col 58, Row 03
    TRAP    #15                     ; Trap (Perform action)
    CLR.L   D1
    LEA     PLAY_AGAIN_MSG, A1
    MOVE.B  #13,        D0
    TRAP    #15

    RTS  

*-----------------------------------------------------------
* Subroutine    : Draw Player
* Description   : Draw Player Square
*-----------------------------------------------------------
DRAW_PLAYER:
    ; Set Pixel Colors
    MOVE.L  #WHITE,     D1          ; Set Background color
    MOVE.B  #80,        D0          ; Task for Background Color
    TRAP    #15                     ; Trap (Perform action)

    ; Set X, Y, Width and Height
    MOVE.W  PLAYER_X,   D1          ; X
    MOVE.L  PLAYER_Y,   D2          ; Y
    MOVE.W  PLAYER_X,   D3
    ADD.L   #PLYR_W_INIT,   D3      ; Width
    MOVE.L  PLAYER_Y,   D4 
    ADD.L   #PLYR_H_INIT,   D4      ; Height
    
    ; Draw Player
    MOVE.B  #87,        D0          ; Draw Player
    TRAP    #15                     ; Trap (Perform action)
    RTS                             ; Return to subroutine

*-----------------------------------------------------------
* Subroutine    : Draw Enemy
* Description   : Draw Enemy Square
*-----------------------------------------------------------
DRAW_ENEMYS:
    ; Set Pixel Colors
    MOVE.L  #RED,       D1          ; Set Background color
    MOVE.B  #80,        D0          ; Task for Background Color
    TRAP    #15                     ; Trap (Perform action)

    ; Set X, Y, Width and Height for enemy Q
    MOVE.W  ENEMY_Q_X,    D1          ; X
    MOVE.L  ENEMY_Q_Y,    D2          ; Y
    MOVE.W  ENEMY_Q_X,    D3
    ADD.L   #ENMY_W_INIT,   D3      ; Width
    MOVE.L  ENEMY_Q_Y,    D4 
    ADD.L   #ENMY_H_INIT,   D4      ; Height
    
    ; Draw Enemy    
    MOVE.B  #87,        D0          ; Draw Enemy
    TRAP    #15                     ; Trap (Perform action)

    ; Set X, Y, Width and Height for enemy W
    MOVE.W  ENEMY_W_X,    D1          ; X
    MOVE.L  ENEMY_W_Y,    D2          ; Y
    MOVE.W  ENEMY_W_X,    D3
    ADD.L   #ENMY_W_INIT,   D3      ; Width
    MOVE.L  ENEMY_W_Y,    D4 
    ADD.L   #ENMY_H_INIT,   D4      ; Height
    
    ; Draw Enemy    
    MOVE.B  #87,        D0          ; Draw Enemy
    TRAP    #15                     ; Trap (Perform action)

    ; Set X, Y, Width and Height for enemy E
    MOVE.W  ENEMY_E_X,    D1          ; X
    MOVE.L  ENEMY_E_Y,    D2          ; Y
    MOVE.W  ENEMY_E_X,    D3
    ADD.L   #ENMY_W_INIT,   D3      ; Width
    MOVE.L  ENEMY_E_Y,    D4 
    ADD.L   #ENMY_H_INIT,   D4      ; Height
    
    ; Draw Enemy    
    MOVE.B  #87,        D0          ; Draw Enemy
    TRAP    #15                     ; Trap (Perform action)

    ; Set X, Y, Width and Height for enemy R
    MOVE.W  ENEMY_R_X,    D1          ; X
    MOVE.L  ENEMY_R_Y,    D2          ; Y
    MOVE.W  ENEMY_R_X,    D3
    ADD.L   #ENMY_W_INIT,   D3      ; Width
    MOVE.L  ENEMY_R_Y,    D4 
    ADD.L   #ENMY_H_INIT,   D4      ; Height
    
    ; Draw Enemy    
    MOVE.B  #87,        D0          ; Draw Enemy
    TRAP    #15                     ; Trap (Perform action)

    ; Set X, Y, Width and Height for enemy T
    MOVE.W  ENEMY_T_X,    D1          ; X
    MOVE.L  ENEMY_T_Y,    D2          ; Y
    MOVE.W  ENEMY_T_X,    D3
    ADD.L   #ENMY_W_INIT,   D3      ; Width
    MOVE.L  ENEMY_T_Y,    D4 
    ADD.L   #ENMY_H_INIT,   D4      ; Height
    
    ; Draw Enemy    
    MOVE.B  #87,        D0          ; Draw Enemy
    TRAP    #15                     ; Trap (Perform action)

    RTS                             ; Return to subroutine

*-----------------------------------------------------------
* Subroutine    : Draw lanes
* Description   : Draw the lanes to show the user where the
* enemies can come form
*-----------------------------------------------------------
DRAW_LANES:
    ; Set pixel colors
    MOVE.L  #BLUE,  D1       ; Set Background color
    MOVE.B  #80,    D0       ; Task for Background Color
    TRAP    #15              ; Trap (Perform action)

    ;move X1=D1, Y1=D2, X2=D3, Y2=D4 to draw a line
    ;Left of column E
    MOVE.B  #84,        D0
    MOVE.W  COL_E,      D1
    SUB.W   #18,        D1
    MOVE.W  #0,         D2
    MOVE.W  D1,         D3
    MOVE.W  SCREEN_H,   D4
    TRAP    #15

    ;Left of column W
    MOVE.B  #84,        D0
    MOVE.W  COL_W,      D1
    SUB.W   #18,        D1
    MOVE.W  #0,         D2
    MOVE.W  D1,         D3
    MOVE.W  SCREEN_H,   D4
    TRAP    #15

    ;Left of column Q
    MOVE.B  #84,        D0
    MOVE.W  COL_Q,      D1
    SUB.W   #18,        D1
    MOVE.W  #0,         D2
    MOVE.W  D1,         D3
    MOVE.W  SCREEN_H,   D4
    TRAP    #15

    ;Right of column E
    MOVE.B  #84,        D0
    MOVE.W  COL_E,      D1
    ADD.W   #32,        D1
    MOVE.W  #0,         D2
    MOVE.W  D1,         D3
    MOVE.W  SCREEN_H,   D4
    TRAP    #15

    ;Right of column R
    MOVE.B  #84,        D0
    MOVE.W  COL_R,      D1
    ADD.W   #32,        D1
    MOVE.W  #0,         D2
    MOVE.W  D1,         D3
    MOVE.W  SCREEN_H,   D4
    TRAP    #15

    ;Right of column T
    MOVE.B  #84,        D0
    MOVE.W  COL_T,      D1
    ADD.W   #32,        D1
    MOVE.W  #0,         D2
    MOVE.W  D1,         D3
    MOVE.W  SCREEN_H,   D4
    TRAP    #15

    RTS

*-----------------------------------------------------------
* Subroutine    : Collision Check
* Description   : Axis-Aligned Bounding Box Collision Detection
* Algorithm checks for overlap on the 4 sides of the Player and 
*-----------------------------------------------------------
CHECK_COLLISIONS:
    CLR.L   D1                      ; Clear D1
    CLR.L   D2                      ; Clear D2
    CLR.L   D3
    CLR.L   D4

CHECK_PLAYER_ROW:
    
    MOVE.L  PLAYER_Y,   D1
    MOVE.W  PLAYER_X,   D3

    MOVE.W  COL_Q,      D4
    CMP.L   D3,         D4       ;check if player is in col Q
    BEQ     COLLISION_CHECK_Q

    MOVE.W  COL_W,      D4
    CMP.L   D3,         D4       ;check if player is in col W
    BEQ     COLLISION_CHECK_W

    MOVE.W  COL_E,      D4
    CMP.L   D3,         D4       ;check if player is in col E
    BEQ     COLLISION_CHECK_E

    MOVE.W  COL_R,      D4
    CMP.L   D3,         D4       ;check if player is in col R
    BEQ     COLLISION_CHECK_R

    MOVE.W  COL_T,      D4
    CMP.L   D3,         D4       ;check if player is in col T
    BEQ     COLLISION_CHECK_T

    RTS

; Collision for enemy Q
; BL = BOTTOM LEFT, TL = TOP LEFT, GE = GREATER OR EQUAL, LE = LESS OR EQUAL
COLLISION_CHECK_Q:
    MOVE.L  ENEMY_Q_Y,  D2
    ADD     #13,        D2

    CMP.B   #1, HIT
    BEQ     ENEMY_Q_HEIGHT_CHECK
    BRA     COLLISION_CHECK_Q_GE

ENEMY_Q_HEIGHT_CHECK:
    CMP.L   D2, D1
    BGT     ENEMY_Q_INVINCIBLE

    RTS

ENEMY_Q_INVINCIBLE:
    MOVE.B  #0, HIT

COLLISION_CHECK_Q_GE:
    CMP.L   D1, D2
    BGE     COLLISION_CHECK_Q_LE
    RTS

COLLISION_CHECK_Q_LE:
    ADD.L   #26,   D1
    CMP.L   D1, D2
    BLE     COLLISION

    RTS

;Collision for enemy W
COLLISION_CHECK_W:
    MOVE.L  ENEMY_W_Y,  D2
    ADD     #13,        D2

    CMP.B   #1, HIT
    BEQ     ENEMY_W_HEIGHT_CHECK
    BRA     COLLISION_CHECK_W_GE

ENEMY_W_HEIGHT_CHECK:
    CMP.L   D2, D1
    BGT     ENEMY_W_INVINCIBLE

    RTS

ENEMY_W_INVINCIBLE:
    MOVE.B  #0, HIT

COLLISION_CHECK_W_GE:
    CMP.L   D1, D2
    BGE     COLLISION_CHECK_W_LE
    RTS

COLLISION_CHECK_W_LE:
    ADD.L   #26,   D1
    CMP.L   D1, D2
    BLE     COLLISION
    RTS

;Collision for enemy E
COLLISION_CHECK_E:
    MOVE.L  ENEMY_E_Y,  D2
    ADD     #13,        D2

    CMP.B   #1, HIT
    BEQ     ENEMY_E_HEIGHT_CHECK
    BRA     COLLISION_CHECK_E_GE

ENEMY_E_HEIGHT_CHECK:
    CMP.L   D2, D1
    BGT     ENEMY_E_INVINCIBLE

    RTS

ENEMY_E_INVINCIBLE:
    MOVE.B  #0, HIT

COLLISION_CHECK_E_GE:
    CMP.L   D1, D2
    BGE     COLLISION_CHECK_E_LE
    RTS

COLLISION_CHECK_E_LE:
    ADD.L   #26,   D1
    CMP.L   D1, D2
    BLE     COLLISION
    RTS

;Collision for enemy R
COLLISION_CHECK_R:
    MOVE.L  ENEMY_R_Y,  D2
    ADD     #13,        D2

    CMP.B   #1, HIT
    BEQ     ENEMY_R_HEIGHT_CHECK
    BRA     COLLISION_CHECK_R_GE

ENEMY_R_HEIGHT_CHECK:
    CMP.L   D2, D1
    BGT     ENEMY_R_INVINCIBLE

    RTS

ENEMY_R_INVINCIBLE:
    MOVE.B  #0, HIT

COLLISION_CHECK_R_GE:
    CMP.L   D1, D2
    BGE     COLLISION_CHECK_R_LE
    RTS

COLLISION_CHECK_R_LE:
    ADD.L   #26,   D1
    CMP.L   D1, D2
    BLE     COLLISION
    RTS

;Collision for enemy T
COLLISION_CHECK_T:
    MOVE.L  ENEMY_T_Y,  D2
    ADD     #13,        D2

    CMP.B   #1, HIT
    BEQ     ENEMY_T_HEIGHT_CHECK
    BRA     COLLISION_CHECK_T_GE

ENEMY_T_HEIGHT_CHECK:
    CMP.L   D2, D1
    BGT     ENEMY_T_INVINCIBLE

    RTS

ENEMY_T_INVINCIBLE:
    MOVE.B  #0, HIT

COLLISION_CHECK_T_GE:
    CMP.L   D1, D2
    BGE     COLLISION_CHECK_T_LE
    RTS

COLLISION_CHECK_T_LE:
    ADD.L   #26,   D1
    CMP.L   D1, D2
    BLE     COLLISION
    RTS

COLLISION:
    MOVE.B  #1, HIT
    SUB.B   #1, Health
    CMP.B   #0, Health
    BEQ     DIE
    RTS

DIE:
    MOVE.B  #1, DEAD
    BSR DRAW

    MOVE.B  #TC_KEYCODE,    D0          ; Listen for Keys
    MOVE.L  #$0D,         D1
    TRAP    #15                     ; Trap (Perform action)
    CMP.B   #$FF,   D1
    BNE     DIE     

    BRA     INITIALISE

*-----------------------------------------------------------
* Subroutine    : EXIT
* Description   : Exit message and End Game
*-----------------------------------------------------------
EXIT:
    SIMHALT

*-----------------------------------------------------------
* Section       : Messages
* Description   : Messages to Print on Console, names should be
* self documenting
*-----------------------------------------------------------
CONTROLS_MSG        DC.B    'Controls', 0       ; control message
LEFT_MSG            DC.B    'LEFT:  A', 0        ; Left message
RIGHT_MSG           DC.B    'RIGHT: D', 0       ; Right message
HEALTH_MSG          DC.B    'Health:  ', 0      ; health message
ELAPSED_TIME_MSG    DC.B    'Time:    ', 0      ; Time Message
TIME_DIVIDER        DC.B    ':', 0              ; Time Divider
PLAY_AGAIN_MSG      DC.B    'Enter to play again...', 0
RECORD_TIME_MSG     DC.B    'Record:  ', 0

*-----------------------------------------------------------
* Section       : Time
* Description   : get the time for display
*-----------------------------------------------------------
START_TIME          DS.L    01                  ; Start time of the game
ELAPSED_TIME        DS.L    01                  ; Time since game start
ELAPSED_TIME_S      DS.L    01                  ; Time since game start seconds
ELAPSED_TIME_M      DS.L    01                  ; Time since game start minutes
RECORD_TIME         DS.L    01
RECORD_TIME_M       DS.L    01
RECORD_TIME_S       DS.L    01

*-----------------------------------------------------------
* Section       : Graphic Colors
* Description   : Screen Pixel Color
*-----------------------------------------------------------
WHITE           EQU     $00FFFFFF
RED             EQU     $000000FF
BLUE            EQU     $00FF0000

*-----------------------------------------------------------
* Section       : Screen Size
* Description   : Screen Width and Height
*-----------------------------------------------------------
SCREEN_W        DS.W    01  ; Reserve Space for Screen Width
SCREEN_H        DS.W    01  ; Reserve Space for Screen Height

*-----------------------------------------------------------
* Section       : Keyboard Input
* Description   : Used for storing Keypresses
*-----------------------------------------------------------
CURRENT_KEY     DS.L    01  ; Reserve Space for Current Key Pressed
KEY_PRESSED     DS.L    01

*-----------------------------------------------------------
* Section       : Character Positions
* Description   : Player and Enemy Position Memory Locations
*-----------------------------------------------------------
PLAYER_X        DS.L    01  ; Reserve Space for Player X Position
PLAYER_Y        DS.L    01  ; Reserve Space for Player Y Position

ENEMY_Q_X         DS.L    01  ; Reserve Space for Enemy X Position
ENEMY_Q_Y         DS.L    01  ; Reserve Space for Enemy Y Position

ENEMY_W_X         DS.L    01  ; Reserve Space for Enemy X Position
ENEMY_W_Y         DS.L    01  ; Reserve Space for Enemy Y Position

ENEMY_E_X         DS.L    01  ; Reserve Space for Enemy X Position
ENEMY_E_Y         DS.L    01  ; Reserve Space for Enemy Y Position

ENEMY_R_X         DS.L    01  ; Reserve Space for Enemy X Position
ENEMY_R_Y         DS.L    01  ; Reserve Space for Enemy Y Position

ENEMY_T_X         DS.L    01  ; Reserve Space for Enemy X Position
ENEMY_T_Y         DS.L    01  ; Reserve Space for Enemy Y Position

*-----------------------------------------------------------
* Section       : Enemy Speed
* Description   : the speed of the enemies in pixels per tick
*-----------------------------------------------------------
ENEMY_Q_SPEED   DS.L    01
ENEMY_W_SPEED   DS.L    01
ENEMY_E_SPEED   DS.L    01
ENEMY_R_SPEED   DS.L    01
ENEMY_T_SPEED   DS.L    01
SPEED_UPDATE    DS.L    01

*-----------------------------------------------------------
* Section       : Columns
* Description   : the default x values of the columns
*-----------------------------------------------------------
COL_Q           DS.W    01 ; Reserve Space for column Q
COL_W           DS.W    01 ; Reserve Space for column W
COL_E           DS.W    01 ; Reserve Space for column E
COL_R           DS.W    01 ; Reserve Space for column R
COL_T           DS.W    01 ; Reserve Space for column T

*-----------------------------------------------------------
* Section       : Health
* Description   : the health of the player
*-----------------------------------------------------------
Health  DS.B    01
HIT     DS.B    01
DEAD    DS.B    01

*~Font name~Courier New~
    End     START
*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~