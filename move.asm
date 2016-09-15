P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

INCLUDE "move.inc"
INCLUDE "video.inc"
INCLUDE "main.inc"


;=============================================================================
; Uninitialized DATA
;=============================================================================
UDATASEG
    rand_seed   dd ?

;=============================================================================
; DATA
;=============================================================================
DATASEG

;=============================================================================
; CODE
;=============================================================================
CODESEG

PROC returnBlockOffset
	USES ebx
	
	mov ebx, [dword ptr current_block] ; contains a value in [0;6]
	shl ebx, 2
	add ebx, offset blokken

	mov eax, [dword ptr current_orientation] ; contains a value in [0;3]
	shl eax, 2
	add eax, [ebx]
	
	mov eax, [eax]
	
	ret
ENDP returnBlockOffset

			;mov al, [esi]  lodsb
			;inc esi
			;mov [edi],al	stosb
			;inc edi

PROC inserblockinarray
	 ARG bloksoort:dword, plaatsinarray:dword  
	 uses eax,ebx,ecx,esi,edi
 
	 mov edi, offset blockarray
	 mov esi, [bloksoort]
	 mov ebx, [plaatsinarray]
	 add edi, ebx	
	 ;voeg lijn toe
	 mov cl, 4
	 putlineblok:
		mov ch, 4
		putcolomblok:
			lodsb
			cmp al, 0
			jz dontinsert
			doinsert:
				stosb
				jmp inserdone
			dontinsert:
				add edi,1	
			inserdone:
				dec ch
				jnz putcolomblok
		add edi, 6
		dec cl
		jnz putlineblok
	 ret

ENDP inserblockinarray


PROC checkmove  ; return eax if 1 not fallin if 0 falling
	uses edi, esi, ecx
	ARG offsetposition: dword
	
		mov eax, [dword ptr current_position]		;(current postitie +10 doen)
		add eax, [offsetposition]
			
			
			
			mov edi, offset blockarray  ; blockarray laden   
			add edi, eax				;goeie positie in blockarray
			
			call returnBlockOffset   ;eax de goeie blok laden
			mov esi, eax 		; in esi de blok steken 
			
			mov ch, 4
			checkrow:
				mov cl, 4 
				checkpixel:
					mov al, [esi]   ;als block 0 is niks doen	
					cmp al, 0
					jz nextpixel			
					mov ah, [edi]    ; als array 0 is niks doen 
					cmp ah, 255		; becaus with 0 bug i think under the memory of the blockarray they are some zeros	
					je nextpixel
					
					mov eax, 1		; als blok en array niet nul zijn dan mag je niet vallen 
					ret
						
					nextpixel:
						inc edi
						inc esi
						dec cl
						jnz checkpixel
					
						add edi, 6
						dec ch
						jnz checkrow
			
	mov eax, 0		
	ret
ENDP checkmove


PROC fall
	call checkmove, 10
	
	cmp eax, 0 
	jz incpos
	mov eax, 1
	ret
	
	incpos:
	add [dword ptr current_position], 10
	
	ret
ENDP fall

PROC turnblock 
		;check in witch orientation we are 
	cmp [dword ptr current_orientation], 0 ;vgl in welk orientaie we zijn blokje 1 orientatie verhogen 
	je orientatie1
		
	cmp [dword ptr current_orientation], 1
	je orientatie2
		
	cmp [dword ptr current_orientation], 2
	je orientatie3
		
	cmp [dword ptr current_orientation], 3
	je orientatie4
	
	orientatie1: ;call the ofsset en change the orientation 
		call returnBlockOffset
		mov [dword ptr current_orientation], 1 ; om zeker te zijn dat er geen foute orientatie komt
		ret
	orientatie2:
		call returnBlockOffset
		mov [dword ptr current_orientation], 2
		ret
	orientatie3:
		call returnBlockOffset
		mov [dword ptr current_orientation], 3
		ret
	orientatie4:
		call returnBlockOffset		
		mov [dword ptr current_orientation], 0
		ret
ENDP turnblock

PROC checkmoveright

	uses edx, ebx, esi
	
	;mov ebx, [dword ptr current_position]
	mov edx, 0
	mov ebx, 0
	call returnBlockOffset
	mov esi, eax 
	add esi, 1 ; 2 pixel beginnen omdat alle blocken beginnen te tekenen in eerste kolom 
	
	mov ch, 4 
		checknextlineinblock:
			mov cl, 3 ;3 volgende pixels checken 
			checkpixelinblock:
				lodsb
				cmp al, 0 ;vergelijken met nul als ze nul zijn volgende pixel checken 
				
				je checknextpixel
				add ebx, 1 
				cmp ebx, edx
				jle checknextpixel
				mov edx, ebx 
				checknextpixel:
					dec cl
					jnz checkpixelinblock   ; men gaat twee waarden onthouden een dat de grootse waarde onthoud en 
			mov ebx, 0						;een ander die we incrementeren elke keer en vergelijken met de vorige waarde als deze kleiner is niks doen
											; als deze groter is dan de oude vervangen door de grootste
			cmp edx, 3
			je checktheoffset
			add esi, 1
			dec ch
			jnz	checknextlineinblock
			
	checktheoffset:
		mov eax, [dword ptr current_position]
		add eax, edx
		
		mov edx, 0
		mov ebx, 10
		idiv ebx
		cmp edx, 9
		je dontmoveright
		mov eax, 1
		ret
		dontmoveright:
			mov eax,0
			ret
	  
ENDP checkmoveright

PROC moveright ;blok 1 positie naar recht verschuiven
	
	call checkmoveright
	cmp eax, 1
	je checkrightblock
	ret
	checkrightblock:
		call checkmove, 1
		cmp eax, 0 
		jz incposR
		mov eax, 1
		ret
	
	incposR:
	; current position +1 doen 	
		inc [dword ptr current_position]
	
	ret
ENDP moveright

PROC checkmoveleft ; check if we the currunt position can divide by then if the rest is zero we can not move left

	uses edx, ebx
	
	mov eax, [dword ptr current_position]
	mov edx, 0
	mov ebx, 10
	idiv ebx
	cmp edx, 0
	je dontmoveleft
	mov eax, 1
	ret
	dontmoveleft:
		mov eax,0
		ret
	  
ENDP checkmoveleft

PROC moveleft ; blok 1 positie naar links verschuiven
	
	call checkmoveleft
	cmp eax, 1
	je checkleftblock
	ret
	checkleftblock:
		call checkmove, -1
		cmp eax, 0 
		jz decleft
		ret

		decleft:
			;current position -1 doen 
			dec [dword ptr current_position]

	ret	
ENDP moveleft

END