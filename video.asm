P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

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

PROC setVideoMode
    ARG mode RETURNS eax
    mov     eax, [mode]
    int     10h

    ret
ENDP setVideoMode

PROC drawcolor
	USES eax, ecx, edx, esi	

	mov     esi, offset pal     ; set the palette (DAC) address
	mov     ecx, 2 * 3          ; set color 0 and 1 (2 indexes in total, 2 * 3 bytes)
	mov     dx, 03c8h           ; VGA DAC set port
	mov     al, 0               ; set start color index
	out     dx, al 
	inc     dx
	rep     outsb
	ret

ENDP drawcolor



PROC drawarray
	USES eax, ebx, ecx, edx, esi, edi
	
	mov  edi, offset _screenBuffer
	add  edi, 320*20 + 120 ; plaats van de array 
	mov  esi, offset blockarray
	
	mov cl, 20
	drawline:
		mov dl, 8
		drawline8times:
			mov ch,10
			drawcolum:
				lodsb
				;mov al,  [esi]
				;inc esi
				mov ah, al
				movzx ebx, ax
				shl ebx, 16
				mov bx, ax
				mov eax, ebx
				;mov  [edi], eax
				;add edi, 4
				stosd
				stosd
				; zie movsb ;rep doe mov 
				dec ch				
				jnz drawcolum
			add edi, 320-80 ; volgende lijn terug in begin beginnen 
			sub esi, 10
			dec dl
			jnz drawline8times
		add esi, 10
		dec cl
		jnz drawline
			
	ret
ENDP drawarray

PROC drawblock
	ARG block:dword, position:dword
	USES eax, ebx, ecx, edx, esi, edi
	
	mov edi, offset _screenBuffer
	add edi, 320*20 + 120;positie 0
	mov eax, [position] ;men krijgt de positie van de dup 200 array mee
	;positie berekenen in offset screenbuffer
	mov edx, 0     ; goede offset instellen door current pos /10 edx is potitie eax rij
	mov ebx, 10
	idiv ebx  ;edx = row, eax = column
	
	; increment screenposition by converted block position
	shl edx, 3  ;positie *8 doen 
	add edi, edx
	
	
	shl eax, 3
	imul eax, 320
	add edi, eax	;toevoegne aan edi
	
	mov esi, [block]
	mov cl,4 ;hoogte 4
	drawlineblock:
		mov dl,8
		drawblock8:  ;blok 8 keren groter maken
			mov ch,4 ;breedte 4
			drawcolomblock:
				lodsb
				cmp al, 0
				jz dontdraw
				dodraw:
					mov ah, al
					movzx ebx, ax
					shl ebx, 16
					mov bx, ax
					mov eax, ebx		
					stosd ;important stosd and not stosb 
					stosd
					jmp drawdone
				dontdraw:
				add edi, 8 
				drawdone:
				dec ch
				jnz drawcolomblock
			add edi, 320-4*8
			sub esi, 4
			dec dl
			jnz drawblock8
		add esi, 4
		dec cl	
		jnz drawlineblock 
	ret
ENDP drawblock

PROC drawRect
    ARG w:dword, h:dword
    USES eax, ebx, ecx, edx, esi, edi

    ; Calculate posX
    mov     eax, [w]
    neg     eax
    add     eax, 320
    shr     eax, 1
    mov     ebx, eax    ; posX is in EBX now

    ; Calculate posY
    mov     eax, [h]
    neg     eax
    add     eax, 200
    shr     eax, 1      ; and posY is in EAX
    
    ; Calculate offset of top-left corner
    mov     edx, 320
    mul     edx         ; EAX = posY * SCREENW
    add     eax, ebx    ; EAX now conatins start offset of rectangle
    add     eax, offset _screenBuffer
    push    eax         ; store for left vertical line drawing
    
    ; Draw upper horizontal line
    mov     edi, eax
    mov     ecx, [w]    ; rect W
    mov     al, 1       ; color
    rep     stosb       ; draw
    
    dec     edi
    mov     ebx, edi    ; EBX now contains the start of the right vertical line
    
    ; Draw left vertical line
    pop     edi
    push    ebx         ; store EBX for drawing the right vertical line  
    mov     ecx, [h]    ; rect H
@@loopLeftLine:
    mov     [edi], al   ; set pixel
    add     edi, 320    ; jump to next pixel (on next line)
    dec     ecx
    jnz     @@loopLeftLine
    
    sub     edi, 320
    mov     ebx, edi    ; EBX now conatins the start of the bottom horizontal line
    
    ; Draw right vertical line
    pop     edi
    push    ebx         ; store EBX for drawing bottom horizontal line
    mov     ecx, [h]    ; rect H
@@loopRightLine:
    mov     [edi], al   ; set pixel
    add     edi, 320    ; jump to next pixel (on next line)
    dec     ecx
    jnz     @@loopRightLine
    
    ; Draw bottom horizontal line
    pop     edi
    mov     ecx, [w]    ; rect W
    rep     stosb       ; draw
    
    ; done
    ret
ENDP drawRect

PROC copyScreen
    USES edi, edx, ecx, eax 
    mov dx, 03dah                           ;VGA status port
@@waitVBlank_wait1:                         ;
    in      al,     dx                      ;read status
    and     al,     8                       ;compare if 3rd bit = 1
    jnz @@waitVBlank_wait1                  ;busy wait if in vb
@@waitVBlank_wait2 :                        ;wait until begin of a new VB
    in      al,     dx                      ;read status
    and     al,     8                       ;test bit 3
    jz @@waitVBlank_wait2                   ;busy wait if NOT in VB

    cld
    mov     esi,    offset _screenBuffer   ;load offset into edi
    mov     edi,    0a0000h               ;video memory address
    mov     ecx,    64000 / 4             ;320 * 200, copy groups four bytes
    rep     movsd                         ;moves a dword and updates ecx, esi and edi

    ret
ENDP copyScreen

END