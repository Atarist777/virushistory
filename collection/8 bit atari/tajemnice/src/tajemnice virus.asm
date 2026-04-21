BOOT EQU $09 
DOSI EQU $0C 
FCNT EQU $1D 
BYTE EQU $1E 
DATA EQU $2F 
HTBS EQU $31A 
SELF EQU $C901

     ORG $600

BEGN DTA A(BEGN)
     DTA A(BEGN+LGTH-1)

MAIN EQU *
* 'D' entry search
     LDX #0
DSRC LDA HTBS,X
     CMP #'D'
     BEQ FOUN
     INX
     INX
     INX
     CPX #36
     BCC DSRC
     RTS
* trap table address
FOUN LDA #6  page 6!
     CMP HTBS+2,X
     BEQ RETU
     LDY #1
TTLP LDA HTBS+2,X
     STA ADDR,Y
     LDA MTAD,Y
     STA HTBS+2,X
     DEX
     DEY
     BPL TTLP
RETU RTS

*--- open

XOPN LDA SELF
     STA DOSI+1
     LDY #2
     STY FCNT
     DEY        1 
     STY BOOT
     BPL DOPR

*--- put byte

XPUT LDY FCNT
     DEY
     BMI GOPU
     CMP #255
     BEQ *+4
     LDY #255
     STY FCNT
GOPU LDY #7
     BPL DOPR  (JMP)

* --- close

XCLO LDY FCNT
     BNE GOCL
     LDY #4
     STY BYTE
     JSR REPL
     LDY #0
     STY FCNT
     LDY <LGTH
     STY BYTE
     JSR REPL
     LDY <LGHT-6
     STY FCNT
     JSR REPL
GOCL LDY #3
     BPL DOPR  (JMP)

*--- body repl

LOOP INC FCNT
     LDA BEGN,Y
     JSR GOPU
REPL LDY FCNT
     CPY BYTE 
     BNE LOOP
     RTS

*--- do std proc

XGET LDY #5
     BPL DOPR  (JMP)
XSTA LDY #9
     BPL DOPR  (JMP)
XSPE LDY #11
DOPR STA DATA 
XADR LDA *,Y 
ADDR EQU *-2 
     PHA 
     DEY 
     TYA
     ROR @
     BCC XADR
     LDA DATA
     RTS

*--- new table

MTAD DTA A (MYTA)
MYTA DTA A(XOPN-1) 0
     DTA A(XCLO-1) 2
     DTA A(XGET-1) 4
     DTA A(XPUT-1) 6
     DTA A(XSTA-1) 8
     DTA A(XSPE-1) A

*--- init. vect.

     DTA A($2E2)
     DTA A($2E3)
     DTA A(MAIN)

*--- total length

LGTH EQU *-BEGN

*--- do it!

     ORG $2E2
     DTA A(MAIN)

     END