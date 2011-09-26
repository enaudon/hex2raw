;Library Name : h2rlib
;Version      : 1.0
;Created Date : 09/26/11
;Last Update  : 09/26/11
;Author       : Enrique Naudon
;Description  : Contains procedures used by modular versions of hex2raw
;               (v2.0+).

SECTION .data           ;initialized data

;error messages
  parityErrMsg: db "Error: Incomplete byte!", 10  ;parity error message
  parityErrLen: equ $-parityErrMsg  ;parity error message length

  inputErrMsg: db "Error: Invalid character!", 10 ;invalid char error message
  inputErrLen:  equ $-inputErrMsg   ;invalid char error message length

;the following translation table translates the ascii representations of all
;hex-legal chars ('0'-'9', 'a'-'f' and 'A'-'F') to their hexidecimal values.
;all non-hex-legal characters are translated to ':' (3Ah).
  raw:
    db  3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,0Ah,3Ah,3Ah,3Ah,3Ah,3Ah
    db  3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah
    db  20h,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah
    db  00h,01h,02h,03h,04h,05h,06h,07h,08h,09h,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah
    db  3Ah,0Ah,0Bh,0Ch,0Dh,0Eh,0Fh,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah
    db  3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah
    db  3Ah,0Ah,0Bh,0Ch,0Dh,0Eh,0Fh,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah
    db  3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah
    db  3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah
    db  3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah
    db  3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah
    db  3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah
    db  3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah
    db  3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah
    db  3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah
    db  3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah,3Ah

SECTION .bss            ;uninitialized data

  inLen equ 1024        ;length of the input buffer
  inBuff: resb inLen    ;the input buffer itself

  outLen equ 512        ;length of the output buffer
  outBuff: resb outLen  ;the output buffer itself

SECTION .text           ;code


;------------------------------------------------------------------------------
;       Name : translate
; Parameters : ESI - the address of the byte before inBuff ([inBuff-1])
;              EDI - the address of the byte before outBuff ([outBuff-1])
;              ECX - the number of bytes in inBuff
;    Returns : none
;   Modifies : outBuff
;      Calls : none
;Description : Translates the ASCII representation of each byte in inBuff into
;              the byte that it represnts using the translation table, raw.
;              The resultant bytes are written to outBuff.  All ASCII
;              characters which are not hexidecimal digits are translated to
;              ':' (3Ah).  

translate:

  ;save caller's state
  pushad                ;store registers

  .loop:
    ;grab low-order nybble (ie. hex digit)
    xor eax, eax        ;clear eax
    mov al, byte[esi+ecx*2]   ;load byte for translation
    mov al, byte[raw+eax]   ;translate current byte
    cmp al, 3Ah         ;compare current byte to ':' (error char)
    je  inputErr        ;print error  if invalid char is detected

    ;grab high-order nybble (ie. hex digit)
    xor edx, edx        ;clear edx
    mov dl, byte[esi+ecx*2-1]   ;load byte for translation
    mov dl, byte[raw+edx]   ;translate current byte
    cmp dl, 3Ah         ;compare current byte to ':' (error char)
    je  inputErr        ;print error  if invalid char is detected

    ;store raw byte
    mov ah, dl          ;load high-order nybble to AH
    shl ah, 4           ;shift high-order nybble
    or  al, ah          ;combine the two nybbles (in EAX)
    mov byte[edi+ecx], al   ;write combined byte to output buffer

    ;prepare to loop
    dec ecx             ;decrement raw byte count
    jnz .loop           ;loop  if bytes remain

  ;prepare to return
  popad                 ;restore registers
  ret                   ;return to caller


;------------------------------------------------------------------------------
;       Name : sanitize
; Parameters : ECX - number of bytes in inBuff
;    Returns : ECX - new byte count in inBuff
;   Modifies : ECX
;              inBuff
;      Calls : none
;Description : Removes all <space> (20h) and <EoL> (0Ah) from inBuff.  The new
;              byte count in inBuff is returned.

sanitize:

  ;save caller's state
  push eax              ;store EAX
  push esi              ;store ESI
  push edi              ;store EDI

  ;prepare registers for "sanitization"
  xor esi, esi          ;clear ESI
  xor edi, edi          ;clear EDI

  ;sanitize input buffer
  .loop:
    mov al, byte[inBuff+esi]    ;load byte for sanitization
    cmp al, 20h         ;compare current byte to <space> char
    je  .next           ;ignore <space> chars
    cmp al, 0Ah         ;compare current byte to <EoL> char
    je  .next           ;ignore <EoL> chars
    mov byte[inBuff+edi], al    ;replace non-<space>/-<EoL> chars
    inc edi             ;increment destination index

    ;prepare to loop
    .next:
      inc esi           ;increment source index
      cmp esi, ecx      ;compare source index to byte count
      jb  .loop         ;loop if bytes remain

  ;prepare to return
  mov ecx, edi          ;store return value (new byte count)
  pop edi               ;restore EDI
  pop esi               ;restore ESI
  pop eax               ;restore EAX
  ret                   ;return to caller


;------------------------------------------------------------------------------
;       Name : loadBuff
; Parameters : none
;    Returns : ECX - number of bytes read
;   Modifies : ECX
;              inBuff
;      Calls : none
;Description : Fills inBuff with input from stdin and returns the number of
;              bytes read into inBuff.

loadBuff:

  ;save caller's state
  push eax              ;store EAX
  push ebx              ;store EBX
  push edx              ;store EDX

  ;read input to input buffer
  mov eax, 3            ;code 3 = sys_read
  mov ebx, 0            ;file 0 = stdin
  mov ecx, inBuff       ;pass input buffer addr
  mov edx, inLen        ;pass num bytes to read
  int 80h               ;make kernel call

  ;prepare to return
  mov ecx, eax          ;store byte count
  pop edx               ;restore EAX
  pop ebx               ;restore EBX
  pop eax               ;restore EDX
  ret                   ;return to caller 


;------------------------------------------------------------------------------
;       Name : printBuff
; Parameters : EDX - number of bytes to write
;    Returns : none
;   Modifies : none
;      Calls : none
;Description : Prints EDX bytes from outBuff to stdout

printBuff:

  ;save caller's state
  pushad                ;save caller's registers

  ;write output from output buffer
  mov eax, 4            ;code 4 = sys_write
  mov ebx, 1            ;file 1 = stdout
  mov ecx, outBuff      ;pass output buffer addr
  int 80h               ;make kernel call

  ;prepare to return
  popad                 ;restore caller's registers
  ret                   ;return

