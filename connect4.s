;
; CS1022 Introduction to Computing II 2018/2019
; Mid-Term Assignment - Connect 4 - SOLUTION
;
; get, put and puts subroutines provided by jones@scss.tcd.ie
;

PINSEL0	EQU	0xE002C000
U0RBR	EQU	0xE000C000
U0THR	EQU	0xE000C000
U0LCR	EQU	0xE000C00C
U0LSR	EQU	0xE000C014

ROWS	EQU	6
COLUMNS	EQU	7

	AREA	globals, DATA, READWRITE
BOARD	DCB	0,0,0,0,0,0,0
	DCB	0,0,0,0,0,0,0
	DCB	0,0,0,0,0,0,0
	DCB	0,0,0,0,0,0,0
	DCB	0,0,0,0,0,0,0
	DCB	0,0,0,0,0,0,0


	AREA	RESET, CODE, READONLY
	ENTRY

	; initialise SP to top of RAM
	LDR	R13, =0x40010000	; initialse SP

	; initialise the console
	BL	inithw

	;
	; your program goes here
	;
Restart	LDR	R0,=BOARD	;R0->address of the board
	LDR	R1,=ROWS	;R1->number of rows
	LDR	R2,=COLUMNS	;R2-> number of columns
	BL	Initialize	;initialise board to 0's
	MOV	R12,#'R'	;Current player='R'
	LDR	r0,=str_go	;load starting message
	BL	puts		;put 
	LDR	R0,=str_game_mode;
	BL	puts		;
	BL	get		;ask the user whether they want to play single or multi player
	BL 	put		;
	CMP	R0,#'m'		;if m input, play multiplayer
	BEQ	multi		;
single	LDR	R0,=BOARD	;load address of the board
	LDR	R1,=ROWS	;r1=number of rows
	LDR	R2,=COLUMNS	;r2=number of columns
	BL	Draw		;draw board
	CMP	R12,#'R'	;if(piece=='R' 
	BEQ	player		;go to player move
	BL	ComputerMove	;else make computerMove
	MOV	R12,#'R'	;after computer change the piece to player
	B	single		;nextMove
player	LDR	R0,=str_input	;load input message
	BL	puts		;put
	LDR	r0,=str_piece	;Output message about current piece
	BL	puts		;
	MOV	R0,R12		;R0=current piece
	BL	put		;output current piece
	MOV	R0,#0xA		;load new line
	BL	put		;put new line
	BL	get		;get index of the column
	BL	put		;
	CMP	R0,#'q'		;if (input='q')
	BEQ	Restart		;reset the game
	SUB	R4,R0,#0x31	;else change index from char to index of the array
	MOV	R1,R4		;move index to r1
	LDR	R0,=BOARD	;load address of the board
	BL	CanMakeMove	;check if the move to this column is valid
	CMP	R0,#0		;if(!canMakeMove)
	BEQ	NotValid	;move is not valid
	LDR	r0,=BOARD	;Load address of the board
	MOV	R1,R4		;Column to insert
	MOV	R2,R12		;Piece to insert
	BL	MakeMove	;Make move
	CMP	R0,#4		;if(result>=4
	BHS	Won		;Game won
	MOV	R12,#'Y'	;else switch to computer
	B	single		;go to next move
stop	B	stop		;stop


multi	LDR	R0,=BOARD	;load address of the board
	LDR	R1,=ROWS	;r1=number of rows
	LDR	R2,=COLUMNS	;r2=number of columns
	BL	Draw		;draw board
	LDR	R0,=str_input	;load input message
	BL	puts		;put
	LDR	r0,=str_piece	;Output message about current piece
	BL	puts		;
	MOV	R0,R12		;R0=current piece
	BL	put		;output current piece
	MOV	R0,#0xA		;load new line
	BL	put		;put new line
	BL	get		;get index of the column
	BL	put		;
	CMP	R0,#'q'		;if (input='q')
	BEQ	Restart		;reset the game
	SUB	R4,R0,#0x31	;else change index from char to index of the array
	MOV	R1,R4		;move index to r1
	LDR	R0,=BOARD	;load address of the board
	BL	CanMakeMove	;check if the move to this column is valid
	CMP	R0,#0		;if(!canMakeMove)
	BEQ	NotValidM	;move is not valid
	LDR	r0,=BOARD	;Load address of the board
	MOV	R1,R4		;Column to insert
	MOV	R2,R12		;Piece to insert
	BL	MakeMove	;Make move
	CMP	R0,#4		;if(result>=4
	BHS	Won		;Game won
	CMP	R12,#'R'
	BNE	toR
	MOV	R12,#'Y'	;else switch to computer
	B	multi
toR	MOV	R12,#'R'	
	B	multi		;go to next move

NotValid
	LDR	R0,=str_not_valid	;output not valid message
	BL	puts
	B	single		;get new input
	
NotValidM
	LDR	R0,=str_not_valid	;output not valid message
	BL	puts
	B	single		;get new input
	
Won	LDR	R0,=BOARD	;r0=adress of the board
	LDR	R1,=ROWS	;r1=ammount of rows
	LDR	R2,=COLUMNS	;r2=ammount of columns
	BL	Draw		;draw board
	LDR	R0,=str_congratulations
	BL	puts
	MOV	R0,R12
	BL 	put
	LDR	R0,=str_win_message	;display win message
	BL	puts		;
	B	stop
;
; your subroutines go here
;
;Initialise subroutine
;Sets all value in the BOARD to 0
;takes in the address of the Board in R0
;The number of rows in R1
;The number of columns in R2
;no return
Initialize
		PUSH	{R4-R10 ,LR}	;save registers
		MOV	R4,R0		;R4=address of the BOARD
		MOV	R5,R1		;R5=number of rows
		MOV	R6,R2		;R6=number of columns
		MOV	R7,#0		;for(i=0;
Fori		CMP	R7,R5		;i<ROW{	
		BHS	INITEND		;finish Fori
		MOV	R8,#0		;for(j=0;
Forj		CMP	R8,R6		;j<COLUMN{
		BHS	eForj		;end j loop
		MUL	R9,R7,R6	;index=i*numberOfColumns
		ADD	R9,R9,R8	;index+=j
		MOV	R10,#0x30	;0 to reset the array
		STRB	R10,[R4,R9]	;store the 0 at Board[i,j]
		ADD	R8,R8,#1	;j++
		B	Forj		;}
eForj		ADD	R7,R7,#1	;i++
		B	Fori		;}
INITEND		POP	{R4-R10,PC}	;restore registers

;Function that makes move in specified column.
;Takes in r0:address of the board
;R1: column where the move is made
;R2:piece to insert
;Returns:
;The length of the longest substring of that color after making move
MakeMove
	PUSH	{R4-R12,LR}	;save registers
	MOV	R4,R0		;r4->address of board
	MOV	R5,R1		;R5->column to insert
	MOV	R6,R2		;R6-> Piece to insert(R or Y)
	LDR	R9,=COLUMNS	;load number of columns
	MOV	R7,#0		;For i=0;
LOOP	MUL	R8,R7,R9	;Calculate the 1d index of i-th column
	ADD	R8,R8,R5	;1d index of Board[i,j]
	LDRB	R10,[R4,R8]	;load byte Board[i,j]
	CMP	R10,#0x30	;if R10!=0, insert at row (i-1)
	BNE	INSERT		;
	ADD	R7,R7,#1	;else i++
	CMP	R7,#ROWS	;if i is last row
	BEQ	INSERT		;insert
	B	LOOP		;else try next row
INSERT	SUB	R7,R7,#1	;go to previous row
	MUL	R8,R7,R9	;calculate the 1d index of Board[i,j]
	ADD	R8,R8,R5	;
	STRB	R6,[R4,R8]	;insert piece at Board[i,j]
	MOV	R12,#0		;maxResult=0
	LDR	R0,=BOARD	;r0=adress of the board
	MOV	R1,R7		;r1= index of the row where the piece was inserted
	MOV	R2,R6		;r2= piece inserted
	BL	CountRow	;count the pieces in the row
	CMP	R12,R0		;if currentMax>=result
	BHS	MM0		;calculate next
	MOV	R12,R0		;else currentMax=result
MM0	LDR	R0,=BOARD	;r0=adress of the board
	MOV	R1,R5		;r1= index of the column where the piece was inserted
	MOV	R2,R6		;r2= piece inserted
	BL	CountCol	;count the pieces in the column
	CMP	R12,R0		;if currentMax>=result
	BHS	MM1		;calculate next
	MOV	R12,R0		;else currentMax=result
MM1	LDR	R0,=BOARD	;r0=adress of the board
	MOV	R1,R7		;r1= index of the row where the piece was inserted
	MOV	R2,R5		;r2= index of the column where the piece was inserted
	MOV	R3,R6		;r3= piece inserted
	BL	CountUpDown	;Count along top left to bottom right diagonal
	CMP	R12,R0		;if currentMax>=result
	BHS	MM2		;calculate next
	MOV	R12,R0		;else currentMax=result
MM2	LDR	R0,=BOARD	;r0=adress of the board
	MOV	R1,R7		;r1= index of the row where the piece was inserted
	MOV	R2,R5		;r2= index of the column where the piece was inserted
	MOV	R3,R6		;r3= piece inserted
	BL	CountDownUp	;Count along bottom left to top right diagonal
	CMP	R12,R0		;if currentMax<result, return result
	BLS	MM3	
	MOV	R0,R12		;else resultToReturn=currentMax
MM3	POP	{R4-R12,PC}	;restore registers and return the lenght of the longest substring of the inserted pieces

;Draw
;Draws Board to console
;Input:
;R0->Address of the board
;R1->Number of rows
;R2->number of columns
Draw
	PUSH	{R4-R7,LR}	;save registers
	MOV	R4,R0		;r4=address
	MOV	R5,R1		;r5=number of rows
	MOV	R6,R2		;r6=number of columns
	MOV	R0,#10		;r0=new line
	BL	put		;put new line
;writing column numbers
	MOV	R0,#32		;R0=SPACE
	BL	put		;put space
	MOV	R7,#0		;for(i=0
DRAW0	CMP	R7,R6		;i<COLUMNS
	BHS	DRAW1		;
	MOV	R0,#32		;R0=SPACE
	BL	put		;put Space
	ADD	R0,R7,#1	;R0=i+1
	ADD	R0,R0,#0x30	;r0= char(i+1)
	BL	put		;put char(i+1)
	ADD	R7,R7,#1	;i++
	B	DRAW0		;loop to for
;drawing board	
DRAW1	MOV	R7,#0		;for(i=0
DRAW4	CMP	R7,R5		;i<ROWS
	BHS	DRAW5		;
	MOV	R0,#10		;R0=new line
	BL	put		;put new line
	ADD	R0,R7,#0x31	;R0=char(i+1)
	BL	put		;put char(i+1)
	MOV	R8,#0		;for(j=0
DRAW2	CMP	R8,R6		;j<Columns
	BHS	DRAW3		;
	MOV	R0,#32		;R0->space
	BL	put		;put space
	MUL	R10,R7,R6	;index=i*Columns
	ADD	R10,R10,R8	;index+=j
	LDRB	R0,[R4,R10]	;R0=byte Board[i,j]
	BL	put		;put Board[i,j] to console
	ADD	R8,R8,#1	;j++
	B	DRAW2		;loop back
DRAW3	ADD	R7,R7,#1	;i++
	B	DRAW4		;loop back
DRAW5	MOV	R0,#10		;put new line
	BL	put
	POP	{R4-R7,PC}	;restore registers
;CanMakeMove
;Checks whether the specified column is full
;Takes the address of the board in r0
;Takes in the number of column to check in r1
;Returns boolean in R0, true(1) if column is can make move and false(0) if not
CanMakeMove
	PUSH	{R4,LR}		;save registers
	CMP	R1,#0		;if(column<0)
	BLT	CMM0		;return false
	CMP	R1,#COLUMNS	;if column>=number of columns
	BGE	CMM0		;return false
	LDRB	R0,[R0,R1]	;load the highest character of column
	CMP	R0,#0x30	;if the character is 0
	BNE	CMM0		;set R0 to true
	MOV	r0,#1		;r0->true
	B	CMM1
CMM0	MOV	R0,#0		;else set R0 to false
CMM1	POP	{R4,PC}		;return
;
;Count_row
;Returns the lenght of the longest string of passed pieces in passed row
;Takes in Address of the board in R0
;index of row in R1
;Piece in R2
;Return:
;The resulting length in R0
CountRow
	PUSH	{R4-R12,LR}	;save registers
	MOV	R4,R0		;R4= address of the Board
	MOV	R5,R1		;R5->row number
	MOV	R6,R2		;R6->Piece to check
	MOV	R12,#0		;count=0
	MOV	R0,#0		;maxCount=0
	LDR	R7,=COLUMNS	;R7=number of elements in each row
	MUL	R9,R5,R7	;index of first element in the row we are checking
	MOV	R8,#0		;for(j=0;
CRow0	CMP	R8,R7		;j<number of elements in a row;
	BHS	endCRow		;{
	ADD	R11,R8,R9	;
	LDRB	R10,[R4,R11]	;load next char in the row
	CMP	R10,R6		;if char!=passed piece
	BNE	resCRow		;reset count; else
	ADD	R12,R12,#1	;count++
	B	CRowFor		;branch to j++
resCRow	CMP	R0,R12		;if(maxCount>=count
	BHS	CRow1		;then skip to count=0;
	MOV	R0,R12		;else maxCount=count
CRow1	MOV	R12,#0		;count=0;
CRowFor	ADD	R8,R8,#1	;j++
	B	CRow0		;}
endCRow	CMP	R0,R12		;at the end if(count<maxCount)
	BHS	RetCRow		;return maxCount
	MOV	R0,R12		;else maxCount=count
RetCRow	POP	{R4-R12,PC}	;restore registers and return

;CountColumn
;Returns the length of longest substring of passed piece in specified column
;Input:
;R0->address of the board
;R1->column number
;R2->which piece to count
;Return:
;R0->the length of the longest substring

CountCol
	PUSH	{R4-R12,LR}	;save registers
	MOV	R4,R0		;R4= address of the Board
	MOV	R5,R1		;R5->column number
	MOV	R6,R2		;R6->Piece to check
	MOV	R12,#0		;count=0
	MOV	R0,#0		;maxCount=0
	MOV	R7,#ROWS	;R7=number of columns
	MOV	R9,#COLUMNS	;R9=number of rows
	MOV	R8,#0		;for(i=0;
CCol0	CMP	R8,R7		;i<numberOfElements in a column;
	BHS	endCCol		;{
	LDRB	R10,[R4,R5]	;load next char in the column
	CMP	R10,R6		;if char!=passed piece
	BNE	resCCol		;reset count; else
	ADD	R12,R12,#1	;count++
	B	CColFor		;branch to j++
resCCol	CMP	R0,R12		;if(maxCount>=count
	BHS	CCol1		;then skip to count=0
	MOV	R0,R12		;maxCount=count
CCol1	MOV	R12,#0		;count=0
CColFor	ADD	R8,R8,#1	;i++
	ADD	R5,R5,R9	;go to next row
	B	CCol0		;}
endCCol	CMP	R0,R12		;if at the end (count<maxCount
	BHS	retCCol		;return maxCount
	MOV	R0,R12		;else maxCount=count
retCCol	POP	{R4-R12,PC}	;restore registers and return

;CountUpDown
;Returns the length of longest sequence of passed character in a diagonal containing passed cell
;Counts along the diagonal going from top-left to bottom-right
;Input:
;R0->address of the board
;R1->Row where the target cell is
;R2->Column where the target cell is
;R3->Piece which we want to count
;Output:
;R0->the length of the longest subsequence of passed piece
CountUpDown
	PUSH	{R4-R12,LR}	;save used registers
	MOV	R4,R0		;R4=address of the board
	MOV	R5,R1		;R5=starting row
	MOV	R6,R2		;R6->starting column
	MOV	R12,#0		;count=0
	MOV	R11,#COLUMNS	;R11=amount of columns
	MOV	R10,#ROWS	;R10=ammount of Rows
	MOV	R0,#0		;maxCount=0
	CMP	R6,R5		;(go to top left of the diagonal) if index of column<index of row
	BHS	CUD0
	SUB	R5,R5,R6	;index of row-=index of column
	MOV	R6,#0		;index of column=0
	B	CUD1
CUD0	SUB	R6,R6,R5	;else index of column-= index of row
	MOV	R5,#0		;index of row=0
CUD1	MUL	R8,R5,R11	;calculatin the 1d index of top left of the diagonal
	ADD	R8,R8,R6
CUD2	CMP	R5,R10		;while(index of row<number of rows&
	BHS	endCUD	
	CMP	R6,R11		;&&index of column< number of columns{	
	BHS	endCUD
	LDRB	R9,[R4,R8]	;load next char on the diagonal
	CMP	R9,R3		;if char!=passed piece
	BNE	resCUD		;reset count; else
	ADD	R12,R12,#1	;count++
	B	CUDFor		;branch to incrementing
resCUD	CMP	R0,R12		;if(maxCount>=count
	BHS	CUD3		;then skip to count=0
	MOV	R0,R12		;maxCount=count
CUD3	MOV	R12,#0		;count=0
CUDFor	ADD	R5,R5,#1	;indexOfRow++
	ADD	R6,R6,#1	;indexOfColumn++
	ADD	R8,R8,#COLUMNS	;go to next row
	ADD	R8,R8,#1	;go to next column
	B	CUD2		;loop back to while
endCUD	CMP	R0,R12		;if at the end (count<maxCount
	BHS	retCUD		;return maxCount
	MOV	R0,R12		;else maxCount=count
retCUD	POP	{R4-R12,PC}	;restore registers and return

CountDownUp
	PUSH	{R4-R12,LR}	;save used registers
	MOV	R4,R0		;R4=address of the board
	MOV	R5,R1		;R5=starting row
	MOV	R6,R2		;R6->starting column
	MOV	R12,#0		;count=0
	MOV	R11,#COLUMNS	;R11=ammount of columns
	MOV	R10,#ROWS	;R10=ammount of rows
	SUB	R10,R10,R5	;calculate the distance from last row to current row index
	SUB	R10,R10,#1	;
	MOV	R0,#0		;maxCount=0
	CMP	R6,R10		;Check which direction we need to move farther to get to bottom left of the diagonal
	BHS	CDU0		;
	ADD	R5,R5,R6	;if(distance to the left is smaller, row+=indexOfColumn
	MOV	R6,#0		;index of column=0
	B	CDU1
CDU0	SUB	R6,R6,R10	;else(indexOfColumn-=distance to the bottom
	MOV	R5,#ROWS
	SUB	R5,R5,#1	;row=last row
CDU1	MUL	R8,R5,R11	;calculating 1d index of bottom left of the diagonal
	ADD	R8,R8,R6	;
CDU2	CMP	R5,#0		;while(row>0
	BLS	endCDU		;
	CMP	R6,R11		;&& column<numberOfColumns
	BHS	endCDU		;{
	LDRB	R9,[R4,R8]	;load next char in the column
	CMP	R9,R3		;if char!=passed piece
	BNE	resCDU		;reset count; else
	ADD	R12,R12,#1	;count++
	B	CDUFor		;branch to j++
resCDU	CMP	R0,R12		;if(maxCount>=count
	BHS	CDU3		;then skip to count=0
	MOV	R0,R12		;maxCount=count
CDU3	MOV	R12,#0		;count=0
CDUFor	SUB	R5,R5,#1	;indexOfRow--
	ADD	R6,R6,#1	;index of Column++
	SUB	R8,R8,#COLUMNS	;go to previous row
	ADD	R8,R8,#1	;go to next column
	B	CDU2		;}go to while
endCDU	CMP	R0,R12		;if at the end (count<maxCount
	BHS	retCDU		;return maxCount
	MOV	R0,R12		;else maxCount=count
retCDU	POP	{R4-R12,PC}	;restore registers and return

;Computer Move
;Tries to make the best move on current board by checking what the result of moving in each column is and picking the best
;Makes the move by checking whats the longest string it can get, and whats the longest string the opponent could get by playing in each column
;Then in picks the highest of those and plays there, thanks to that it can try and block the player from winning
;No input
;No return
ComputerMove
	PUSH	{R4-R12,LR}	;save registers
	MOV	R12,#0		;best column result=0
	MOV	R11,#0		;best column index=0
	MOV	R4,#0		;for column index=0;
	LDR	R5,=COLUMNS	;column index< number of columns
nextCol	CMP	R4,R5		;{
	BHS	MOVE		;
	LDR	R0,=BOARD	;	R0->address of the board
	MOV	R1,R4		;	R1->column to move
	BL	CanMakeMove	;	invoke CanMakeMove
	CMP	R0,#1		;	if(!canMakeMove)
	BNE	INC		;	move to increment
	LDR	R0,=BOARD	;	R0->adress of the board
	MOV	R1,R4		;	R1->index of the column
	MOV	R2,#'Y'		;	R2->piece to move (Y is computer)
	BL	MakeMove	;	try to makeMove in this column
	CMP	R0,R12		;	if(count<=maxCount
	BLS	Rem		;	go to next column
	MOV	R12,R0		;	else	{maxCount=count
	MOV	R11,R4		;	indexOfBestColumn=columnIndex}
Rem	LDR	R0,=BOARD	;	R0->address of the board
	MOV	R1,R4		;	R1->column the last move was made in
	BL	Remove		;	Remove last move
	LDR	R0,=BOARD	;	R0->adress of the board
	MOV	R1,R4		;	R1->index of the column
	MOV	R2,#'R'		;	R2->piece to move (R is player)
	BL	MakeMove	;	try to makeMove in this column
	CMP	R0,R12		;	if(count<=maxCount
	BLS	Rem2		;	go to next column
	MOV	R12,R0		;	else	{maxCount=count
	MOV	R11,R4		;	indexOfBestColumn=columnIndex}
Rem2	LDR	R0,=BOARD	;	R0->address of the board
	MOV	R1,R4		;	R1->column the last move was made in
	BL	Remove		;	Remove last move
INC	ADD	R4,R4,#1	;	columnIndex++
	B	nextCol		;}
MOVE	LDR	R0,=str_com_move;Print out where the computer makes its move
	BL	puts		;
	ADD	R0,R11,#0x31	;Convert the index of the column to char+1
	BL	put		;put it out
	LDR	R0,=BOARD	;R0->address of the board
	MOV	R1,R11		;R1->best column to insert
	MOV	R2,#'Y'		;R2->piece to insert
	BL	MakeMove	;make the best move
	CMP	R0,#4		;check for win
	BLT	noWin		;if(!won) go return
	LDR	R0,=BOARD	;R0=address of the board
	LDR	R1,=ROWS	;R1=number of rows
	LDR	R2,=COLUMNS	;R2=number of columns
	BL	Draw		;Draw the state of the board after winning move
	LDR	R0,=str_com_win	;display computer win message
	BL	puts		;
	ADD	SP,SP,#40	;Pop all the registers of the stack
	B	stop		;stop the program
noWin	POP	{R4-R12,PC}	;restore used registers
	
;Remove	
;Takes in the address of the board and the index of the column 
;Changes the highest non-empty place in the column to 0
;input:
;R0->address of the board
;R1->column from which it removes
;no return
Remove
	PUSH	{R4-R8,LR}	;save registers
	MOV	R4,R0		;R4=address of the board
	MOV	R5,R1		;R5=index of the column
	MOV	R6,#COLUMNS	;R6=number of elements in a row
	MOV	R8,R5		;R8=index of current element in the board
Rem1	LDRB	R7,[R4,R8]	;load the element of the column
	CMP	R7,#0x30	;is r7='0'
	BEQ	Rem0		;if (r7=='0' read next element)
	MOV	R0,#0x30	;else 	{R0='0'
	STRB	R0,[R4,R8]	;	change the highest element to '0'
	B	RemFin		;	finished remove}
Rem0	ADD	R8,R8,R6	;go to next row in this column
	B	Rem1		;Load next character
RemFin	POP	{R4-R8,PC}	;Restore registers when finished
; inithw subroutines
; performs hardware initialisation, including console
; parameters:
;	none
; return value:
;	none
;
inithw
	LDR	R0, =PINSEL0		; enable UART0 TxD and RxD signals
	MOV	R1, #0x50
	STRB	R1, [R0]
	LDR	R0, =U0LCR		; 7 data bits + parity
	LDR	R1, =0x02
	STRB	R1, [R0]
	BX	LR

;
; get subroutine
; returns the ASCII code of the next character read on the console
; parameters:
;	none
; return value:
;	R0 - ASCII code of the character read on teh console (byte)
;
get	LDR	R1, =U0LSR		; R1 -> U0LSR (Line Status Register)
get0	LDR	R0, [R1]		; wait until
	ANDS	R0, #0x01		; receiver data
	BEQ	get0			; ready
	LDR	R1, =U0RBR		; R1 -> U0RBR (Receiver Buffer Register)
	LDRB	R0, [R1]		; get received data
	BX	LR			; return

;
; put subroutine
; writes a character to the console
; parameters:
;	R0 - ASCII code of the character to write
; return value:
;	none
;
put	LDR	R1, =U0LSR		; R1 -> U0LSR (Line Status Register)
	LDRB	R1, [R1]		; wait until transmit
	ANDS	R1, R1, #0x20		; holding register
	BEQ	put			; empty
	LDR	R1, =U0THR		; R1 -> U0THR
	STRB	R0, [R1]		; output charcter
put0	LDR	R1, =U0LSR		; R1 -> U0LSR
	LDRB	R1, [R1]		; wait until
	ANDS	R1, R1, #0x40		; transmitter
	BEQ	put0			; empty (data flushed)
	BX	LR			; return

;
; puts subroutine
; writes the sequence of characters in a NULL-terminated string to the console
; parameters:
;	R0 - address of NULL-terminated ASCII string
; return value:
;	R0 - ASCII code of the character read on teh console (byte)
;
puts	STMFD	SP!, {R4, LR} 		; push R4 and LR
	MOV	R4, R0			; copy R0
puts0	LDRB	R0, [R4], #1		; get character + increment R4
	CMP	R0, #0			; 0?
	BEQ	puts1			; return
	BL	put			; put character
	B	puts0			; next character
puts1	LDMFD	SP!, {R4, PC} 		; pop R4 and PC


;
; hint! put the strings used by your program here ...
;

str_go
	DCB	"Let's play Connect4!!",0xA, 0xD, 0

str_not_valid
	DCB	0xD,"You cannot make a move there, try again.",0x0

str_input
	DCB	"Please input the number of the column you want to use.(1-7,q to reset)",0xA,0xD,0
	
str_congratulations
	DCB	"Congratulations ",0
	
str_win_message
	DCB	", You have won!", 0xA, 0xD, 0

str_piece
	DCB	"Now playing: ",0
str_com_win
	DCB	"Computer wins!",0
str_com_move
	DCB	"Computer moved in column ",0
str_game_mode
	DCB	"Please input m if you want to play with another player, or s to play single player",0xA,0xD,0
	END	