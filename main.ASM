;北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北?
; 32-bit Assembly Example
;
; Empty asm example.
;北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北?
IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT


INCLUDE "video.inc"
INCLUDE "rand.inc"
INCLUDE "move.inc"
INCLUDE "main.inc"

;北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北?
; CODE
;北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北?
CODESEG

;鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍?
; Entry To ASM Code
; In:
;   CS - Code Selector    Base: 00000000h - Limit: 4G
;   DS - Data Selector    Base: 00000000h - Limit: 4G
;   ES - PSP Selector     Base: PSP Seg   - Limit: 100h
;   FS - ?
;   GS - ?
;   SS - Data Selector    Base: 00000000h - Limit: 4G
;   ESP -> STACK segment
;   Direction Flag - ?
;   Interrupt Flag - ?
;
;   All Other Registers Are Undefined!
;鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍?


PROC waitVBlank
	 USES    eax, edx

    mov     dx, 03dah           ; VGA status port
@@waitVBlank_wait1:             ; if already in VB, then wait until VB finishes
    in      al, dx              ; read status
    and     al, 8               ; test bit 3
    jnz     @@waitVBlank_wait1  ; busy wait if in VB
@@waitVBlank_wait2:             ; wait until begin of a new VB
    in      al, dx              ; read status
    and     al, 8               ; test bit 3
    jz      @@waitVBlank_wait2  ; busy wait if NOT in VB

    ret
ENDP waitVBlank

PROC keys
	uses eax, edx

	mov ah, 01h
	int 16h
	jz donothing
	
	mov ah, 00h 
	int 16h
	cmp al, 27; escape om de spel af te sluiten
	je quit
	cmp ah, 48h ;48 up arrow
	je turn
	cmp ah, 4Dh ; arrow right
	je moveR
	cmp ah, 4Bh ; arrow left
	je moveL
	
	
	jne donothing
	
	turn:
		call turnblock
		
		ret
	
	moveR:
		call moveright
		
		ret
		
	moveL:
		call moveleft
		
		ret
		
	quit:
		call    setVideoMode, 3h

		mov eax, 4c00h                  ; AH = 4Ch - Exit To DOS
		int 21h                         ; DOS INT 21h
	donothing:
	
	ret
ENDP keys

PROC randomblok
	uses eax, edx, ecx, ebx
	
	mov [dword ptr current_position], 4	
	
	call rand
	mov ebx,7   ; waarde tussen 0 en 6  om een block te kiezen door random getalen te delen door 7
	mov edx,0
	idiv ebx ; modulo 7 in edx
	mov [dword ptr current_block], edx
	mov [dword ptr current_orientation], 0

	ret
ENDP randomblok



PROC checkremovelines
	uses esi, ecx , ebx,  edx 
	
	mov esi, offset blockarray
	
	mov ebx, 20       ; row
	checkline:
			mov ecx,10  ;position in row  
			checkpixel: 
				mov edx, 9   ; if we jump to next row we have to remove from 10 ecx to jump to the next row 
				lodsb
				cmp al, 255    ;check if pixel is 255 (do nothing)
				je checknextrow ;check next pixel
				cmp ecx, 1 ; check if we are in the last pixel of the row 
				jne checknextpixel
				mov eax, ebx	;if row is full return the row in eax ( we have to do 20 - row later becaus if we are on the last row it will return 20)
				ret
				checknextrow:
					sub edx, ecx 
					mov ecx, 0
					jmp nextrow
					checknextpixel:
						dec ecx						
					nextrow:
						
						cmp ecx, 0
						jnz checkpixel	
			inc edx   ; code that help us to go to the right row if we jump out the lus 
			mov eax, 9
			sub eax, edx 
			
			add esi, eax 		
			dec ebx
			jnz checkline
	mov eax, ebx ; return value of ebx if the loop is done (return normaly 0)
	ret

ENDP checkremovelines
	

PROC removelines
ARG rowoffset: dword
	uses eax, edi, ecx
	
	mov eax, [rowoffset] ; lijn dat men moet verwijderen deze moeten we nog maal 10 doen
	mov edi, offset blockarray  
	
	imul eax, 10 
	add edi, eax
	
	
	mov ch, 10
	removeline:
		mov al, 255
		mov [edi], al
		inc edi
		dec ch
		jnz removeline
	ret

ENDP removelines


PROC gamelogic
	uses eax, ebx, edx
	
	inc [dword ptr counter]   ; eerste deel voor senlheid van het vallen van een block
	mov eax, [dword ptr counter]
	mov edx, 0
	mov ebx, 10 
	idiv ebx
	
	cmp edx, 0
	je falling
	ret
	
	falling:
		call fall
		cmp eax,1
		je insert
		ret
		
		insert:
			call returnBlockOffset	
			call inserblockinarray, eax, [dword ptr current_position]
			checkifwecanremoveline:
				call checkremovelines   ;check if a row is full
				cmp eax, 0              ; if eax zero wil say that there is no full rows we can call a next random block
				je donextstep
				mov ebx, 20		;delete 20 to the row
				mov ecx, eax
				sub ebx, eax
				call removelines, ebx
				cmp ecx,0
				jnz checkifwecanremoveline
				
			donextstep:
				call randomblok
	ret
ENDP gamelogic


PROC drawall
	call drawarray
	call returnBlockOffset	
	call drawblock, eax, [dword ptr current_position]
	
	call copyScreen ; dubbele buffering
	call waitVBlank
	ret
ENDP drawall

PROC start

        sti                             ; Set The Interrupt Flag
        cld                             ; Clear The Direction Flag

        push ds 						; Put value of DS register on the stack
        pop es 							; And write this value to ES

		

		; Your code comes here		
		call setVideoMode, 13h
		call rand_init
		; eerst initialesern van array en een random block op scherm tekenen
		call drawcolor 
		call randomblok;kies een random block 
		call    drawRect, 82, 162 ;randen tekenen
		playloop:

			call keys     ; key functie activeren
			call gamelogic
			call drawall
			
			jmp playloop		
ENDP start

;北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北?
; DATA
;北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北?
DATASEG

	; Your data comes here
pal db 0, 0, 0, 63, 63, 63

			
blockarray  db 10*20 dup(255) ; array veld


			
blok_I_0    db 1, 0, 0, 0
			db 1, 0, 0, 0
			db 1, 0, 0, 0
			db 1, 0, 0, 0

blok_I_1	db 0, 0, 0, 0			
			db 0, 0, 0, 0
			db 0, 0, 0, 0
			db 1, 1, 1, 1

blok_J_0	db 0, 0, 0, 0
			db 0, 0, 0, 0
			db 40, 0, 0, 0
			db 40, 40, 40, 0
			

blok_J_1	db 0, 0, 0, 0
			db 40, 40, 0, 0
			db 40, 0, 0, 0
			db 40, 0, 0 , 0 
			

blok_J_2	db 0, 0, 0, 0
			db 0, 0, 0, 0
			db 40, 40, 40, 0
			db 0, 0, 40, 0
			

blok_J_3	db 0, 0, 0, 0
			db 0, 40, 0, 0
			db 0, 40, 0, 0
			db 40, 40, 0, 0 
			

blok_O_0	db 50, 50, 0, 0
			db 50, 50, 0, 0
			db 0, 0, 0, 0
			db 0, 0, 0, 0

blok_L_0	db 0, 0, 0, 0
			db 60, 0, 0, 0
			db 60, 0, 0, 0
			db 60, 60, 0, 0
			

blok_L_1	db 0, 0, 0, 0
			db 0, 0, 0, 0
			db 60, 60, 60, 0
			db 60, 0, 0, 0
			

blok_L_2	db 0, 0, 0, 0
			db 60, 60, 0, 0
			db 0, 60, 0, 0
			db 0, 60, 0, 0 
			

blok_L_3	db 0, 0, 0, 0
			db 0, 0, 0, 0
			db 0, 0, 60, 0
			db 60, 60, 60, 0
			

blok_S_0	db 0, 0, 0, 0
			db 0, 0, 0, 0
			db 0, 80, 80, 0
			db 80, 80, 0, 0
			

blok_S_1	db 0, 0, 0, 0
			db 80, 0, 0, 0
			db 80, 80, 0, 0
			db 0, 80, 0, 0
			

blok_Z_0	db  0, 0, 0,0
			db  0, 0, 0, 0 
			db  90, 90, 0, 0
			db  0, 90, 90, 0
			

blok_Z_1	db  0, 0, 0, 0
			db  0, 90, 0, 0
			db  90, 90, 0, 0
			db  90, 0, 0, 0
			

blok_T_0	db  0, 0, 0, 0
			db  0, 0, 0, 0
			db 	100, 100, 100, 0
			db 	0, 100, 0, 0 
			

blok_T_1	db 0, 0, 0, 0
			db 100, 0, 0, 0
			db 100, 100, 0, 0
			db 100, 0, 0, 0
			

blok_T_2	db 0, 0, 0, 0
			db 0, 0, 0, 0
			db 0, 100, 0, 0 
			db 100, 100, 100
			

blok_T_3	db 0, 0, 0, 0
			db 0, 100, 0, 0
			db 100, 100, 0, 0
			db 0, 100, 0, 0
			

			
blok_I      dd offset blok_I_0, offset blok_I_1, offset blok_I_0, offset blok_I_1
blok_Z 		dd offset blok_Z_0, offset blok_Z_1, offset blok_Z_0, offset blok_Z_1
blok_S 		dd offset blok_S_0, offset blok_S_1, offset blok_S_0, offset blok_S_1
blok_L 		dd offset blok_L_0, offset blok_L_1, offset blok_L_2, offset blok_L_3
blok_T 		dd offset blok_T_0, offset blok_T_1, offset blok_T_2, offset blok_T_3
blok_J 		dd offset blok_J_0, offset blok_J_1, offset blok_J_2, offset blok_J_3
blok_O		dd offset blok_O_0, offset blok_O_0, offset blok_O_0, offset blok_O_0

blokken		dd offset blok_I, offset blok_J, offset blok_L, offset blok_O, offset blok_S, offset blok_T, offset blok_Z

current_position dd 0
current_block 	dd ?
current_orientation	dd ?

rand_seed   dd ?
RAND_A = 1103515245
RAND_C = 12345

_screenBuffer db 64000 dup(?)

counter dd 0
;北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北?
; STACK
;北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北?
STACK 1000h

END start
