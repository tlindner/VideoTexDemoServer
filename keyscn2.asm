;*********************************************************************
;* Title: KEYSCN2
;*********************************************************************
;* Author: R. Allen Murphey
;*
;* License:
;*     Copyright (c) 2022 R. "Allen" Murphey aka "Exile In Paradise"
;*     Released to you under Creative Commons Attribution-Share Alike (CC-BY-SA)
;*     Additional/other licenses possible by request.
;*
;* Description: Color Computer and Dragon keyboard driver
;*
;* Documentation:
;*     https://exileinparadise.com/tandy_color_computer:keyscn2
;*     https://exileinparadise.com/tandy_color_computer:keyscn
;*
;* Include Files: none
;*
;* Assembler: lwasm from LWtools 4.19+
;*
;* Revision History:
;* Rev #     Date      Who     Comments
;* -----  -----------  ------  ---------------------------------------
;* 00     2022         RAM     Created initial file
;* 01     11/2022      TJL     Ported to the AgVision/VideoTex
;*********************************************************************

VIDRAM:     equ   $0400       ; start of video memory
JOYBUF:     equ   $0400       ; just store stuff on the screen for now
KEYBUF:     equ   $0401       ; just store more on the screen for now
PIA0AD:     equ   $FF1C       ; PIA0 port A data = keyboard row inputs
PIA0BD:     equ   $FF1E       ; PIA0 port B data = keyboard column strobe out
RESET:      equ   $FFFE       ; Address of MPU Reset Vector
VECCOCO:    equ   $A027       ; CoCo 1/2 reset vector value
VECDRGN:    equ   $B3B4       ; Dragon32/64 reset vector value
VECCOCO3:   equ   $8C1B       ; CoCo3 reset vector value
VEVDOTX:	equ   $A091       ; AgVision / VideoTex reset vector value

KEY_UP:     equ   27
KEY_DOWN:   equ   28
KEY_LEFT:   equ   29
KEY_RIGHT:  equ   30
KEY_ENTER:  equ   48
KEY_CLEAR:  equ   49
KEY_BREAK:  equ   50
KEY_ALT:    equ   51
KEY_CTRL:   equ   52
KEY_F1:     equ   53
KEY_F2:     equ   54
KEY_SHIFT:  equ   55

            org   $0E00       ; some place to live
INIT:       
            orcc #$AF
            bsr   CLS         ; clear screen
            ldx   RESET       ; Get RESET vector
            cmpx  #VECDRGN    ; if Dragon
            beq   CFGDRGN     ; swap keymaps
                              ; fallthru for VIDEOTEX/CoCo1/2/3
CFGCOCO:
            ldx   #COCOKEYS   ; get address of CoCo key table
            stx   KEYTABLE    ; set the pointer
            ldx   #COCOPOS    ; get address of CoCo screen addrs
            stx   POSTABLE    ; set that point
            bra   MAIN        ; configured, lets go!   

CFGDRGN:
            ldx   #DRGNKEYS   ; get address of CoCo key table
            stx   KEYTABLE    ; set the pointer
            ldx   #DRGNPOS    ; get address of CoCo screen addrs
            stx   POSTABLE    ; set that point
                              ; fallthru to MAIN
MAIN:
            bsr   KEYSCN      ; poll keys
            bsr   DECODE      ; can we find the key?
            bra   MAIN        ; endless loop

CLS:
            pshs  X,D,CC      ; save our registers
            ldd   #$8080      ; fade to black
            ldx   #VIDRAM     ; point to start of video memory
CLS010:     std   ,X++        ; clear two characters
            cmpx  #VIDRAM+512 ; reached end of video memory?
            bne   CLS010      ; go back
            puls  X,D,CC,PC   ; restore registers and bail

DELAY:
            pshs  X,CC        ; save our registers
            ldx   #$045E      ; some delay
DELAY010:   leax  -1,X        ; countdown X
            bne   DELAY010    ; done counting?
            puls  X,CC,PC     ; restore registers and bail

KEYSCN:
            pshs  X,A,CC      ; save our registers
            ldx   #JOYBUF     ; point to place to save polled data
            lda   #$FF        ; all bits high
            sta   PIA0BD      ; disable all keyboard column strobes
            andcc #%11111110  ; CLC clear carry
KEY010:     lda   PIA0AD      ; read the keyboard rows, first joy, then keys
            sta   ,X+         ; store to pointer and advance to next save ptr
            rol   PIA0BD      ; move the zero bit right to strobe next column
            bcs   KEY010      ; keep reading until we hit our original CLC
            puls  X,A,CC,PC   ; restore registers and bail

DECODE:
            pshs  A,B,X,Y,CC  ; save our registers
            ldx   #KEYBUF     ; pointer to where we saved PIA data
            ldy   KEYTABLE    ; load Y with ptr to keys read in
            clrb              ; start with b empty as bit cursor
DECD000:    lda   ,X+         ; get read key bits into A to process

DECD010:    rora              ; move low bit into carry to test
            bcs   DECD020     ; bit high, key not processed, skip lookup

                              ; This next bit is our cheesy keyboard display
                              ; Replace this with whatever you want to do
                              ; with a key in B
            pshs  A,X,CC      ; stash A,X,CC for a couple of opcodes...
            ldx   POSTABLE    ; get pointer to screen position table
            tfr   B,A         ; copy B key index into A ...
            asla              ; to multiply by two for use as ...
            leax  A,X         ; the offset into the 2-byte address table
            lda   B,Y         ; get the key pressed [0-55]
            sta   [,X]        ; put on screen at address from *POS table
            jsr   DELAY       ; hang around for a while so we can see it
            lda   #$80        ; load up a black block
            sta   [,X]        ; put on screen over the key shown
            puls  A,X,CC      ; clean up registers and fall through
                              ; end of sample display code

DECD020:    addb  #8          ; move bit cursor to next column
            cmpb  #56         ; have we read past bit 6 of keybuf?
            blt   DECD010     ; no go get next key bit from current buffer
            subb  #55         ; yes, go back to row 0 of next column
            cmpb  #8          ; is bit cursor past end of column data?
            blt   DECD000     ; no go get next key buffer and decode it
DECD030:    puls  A,B,X,Y,CC,PC  ; restore registers and bail

COCOKEYS:   fcb   '@','A','B','C','D','E','F','G'
            fcb   'H','I','J','K','L','M','N','O'
            fcb   'P','Q','R','S','T','U','V','W'
            fcb   'X','Y','Z',KEY_UP,KEY_DOWN,KEY_LEFT,KEY_RIGHT,' '
            fcb   '0','1','2','3','4','5','6','7'
            fcb   '8','9',':',';',',','-','.','/'
            fcb   KEY_ENTER,KEY_CLEAR,KEY_BREAK,KEY_ALT,KEY_CTRL,KEY_F1,KEY_F2,KEY_SHIFT
COCOPOS:
            fdb   $0478,$04A5,$04EE,$04EA,$04A9,$0468,$04AB,$04AD
            fdb   $04AF,$0472,$04B1,$04B3,$04B5,$04F2,$04F0,$0474
            fdb   $0476,$0464,$046A,$04A7,$046C,$0470,$04EC,$0466
            fdb   $04E8,$046E,$04E6,$047C,$04FC,$04BB,$04BD,$052F
            fdb   $0435,$0423,$0425,$0427,$0429,$042B,$042D,$042F
            fdb   $0431,$0433,$0437,$04B7,$04F4,$0439,$04F6,$04F8
            fdb   $04B9,$047A,$043D,$0462,$04A3,$053B,$053D,$04E4   

DRGNKEYS:   fcb   '0','1','2','3','4','5','6','7'
            fcb   '8','9',':',';',',','-','.','/'
            fcb   '@','A','B','C','D','E','F','G'
            fcb   'H','I','J','K','L','M','N','O'
            fcb   'P','Q','R','S','T','U','V','W'
            fcb   'X','Y','Z',KEY_UP,KEY_DOWN,KEY_LEFT,KEY_RIGHT,' '
            fcb   KEY_ENTER,KEY_CLEAR,KEY_BREAK,KEY_ALT,KEY_CTRL,KEY_F1,KEY_F2,KEY_SHIFT
DRGNPOS:
            fdb   $0435,$0423,$0425,$0427,$0429,$042B,$042D,$042F
            fdb   $0431,$0433,$0437,$04B7,$04F4,$0439,$04F6,$04F8
            fdb   $0478,$04A5,$04EE,$04EA,$04A9,$0468,$04AB,$04AD
            fdb   $04AF,$0472,$04B1,$04B3,$04B5,$04F2,$04F0,$0474
            fdb   $0476,$0464,$046A,$04A7,$046C,$0470,$04EC,$0466
            fdb   $04E8,$046E,$04E6,$047C,$04FC,$04BB,$04BD,$052F
            fdb   $04B9,$047A,$043D,$0462,$04A3,$053B,$053D,$04E4   

KEYTABLE    rmb   2           ; pointer to CoCo or Dragon key decode table
POSTABLE    rmb   2           ; pointer to CoCo or Dragon screen addresses

            end   INIT

;*********************************************************************
;* End of keyscn2.asm
;*********************************************************************