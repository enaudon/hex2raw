;Library Name : h2rlib
;Version      : 1.0
;Created Date : 09/26/11
;Last Update  : 09/26/11
;Author       : Enrique Naudon
;Description  : Contains procedures used by modular versions of hex2raw
;               (v2.0+).

SECTION .data           ;initialized data

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
  inBuf: resb inLen     ;the input buffer itself

  outLen equ 512        ;length of the output buffer
  outBuf: resb outLen   ;the output buffer itself

SECTION .text           ;code

GLOBAL translate, sanitize, loadBuf, printBuf
GLOBAL inBuf, outBuf

;------------------------------------------------------------------------------
;       Name : translate
; Parameters : ESI - the address of the byte before inBuf ([inBuf-1])
;              EDI - the address of the byte before outBuf ([outBuf-1])
;              ECX - the number of bytes in inBuf
;    Returns : none
;   Modifies : outBuf
;      Calls : none
;Description : Translates the ASCII representation of each byte in inBuf into
;              the byte that it represnts using the translation table, raw.
;              The resultant bytes are written to outBuf.  All ASCII characters
;              which are not hexidecimal digits are translated to ':' (3Ah).

translate:

  ;save caller's state
  push ecx              ;store ECX
  push edx              ;store EDX

  .loop:
    ;grab low-order nybble (ie. hex digit)
    xor eax, eax        ;clear eax
    mov al, byte[esi+ecx*2]   ;load byte for translation
    mov al, byte[raw+eax]   ;translate current byte
    cmp al, 3Ah         ;compare current byte to ':' (error char)
    je  .error          ;return offset of invalid byte

    ;grab high-order nybble (ie. hex digit)
    xor edx, edx        ;clear edx
    mov dl, byte[esi+ecx*2-1]   ;load byte for translation
    mov dl, byte[raw+edx]   ;translate current byte
    cmp dl, 3Ah         ;compare current byte to ':' (error char)
    je  .error          ;return offset of invalid byte

    ;store raw byte
    mov ah, dl          ;load high-order nybble to AH
    shl ah, 4           ;shift high-order nybble
    or  al, ah          ;combine the two nybbles (in EAX)
    mov byte[edi+ecx], al   ;write combined byte to output buffer

    ;prepare to loop
    dec ecx             ;decrement raw byte count
    jnz .loop           ;loop if bytes remain
    xor eax, eax        ;error code 0 = no errors
    jmp .prologue       ;jump to return

  ;return an error code
  .error:
    mov eax, esi        ;load error code into EAX

  ;prepare to return
  .prologue:
  pop edx               ;restore EDX
  pop ecx               ;restore ECX
  ret                   ;return to caller


;------------------------------------------------------------------------------
;       Name : sanitize
; Parameters : ECX - number of bytes in inBuf
;    Returns : ECX - new byte count in inBuf
;   Modifies : ECX
;              inBuf
;      Calls : none
;Description : Removes all <space> (20h) and <EoL> (0Ah) from inBuf.  The new
;              byte count in inBuf is returned.

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
    mov al, byte[inBuf+esi]   ;load byte for sanitization
    cmp al, 20h         ;compare current byte to <space> char
    je  .next           ;ignore <space> chars
    cmp al, 0Ah         ;compare current byte to <EoL> char
    je  .next           ;ignore <EoL> chars
    mov byte[inBuf+edi], al   ;replace non-<space>/-<EoL> chars
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
;       Name : loadBuf
; Parameters : none
;    Returns : ECX - number of bytes read
;   Modifies : ECX
;              inBuf
;      Calls : none
;Description : Fills inBuf with input from stdin and returns the number of
;              bytes read into inBuf.

loadBuf:

  ;save caller's state
  push eax              ;store EAX
  push ebx              ;store EBX
  push edx              ;store EDX

  ;read input to input buffer
  mov eax, 3            ;code 3 = sys_read
  mov ebx, 0            ;file 0 = stdin
  mov ecx, inBuf        ;pass input buffer addr
  mov edx, inLen        ;pass num bytes to read
  int 80h               ;make kernel call

  ;prepare to return
  mov ecx, eax          ;store byte count
  pop edx               ;restore EAX
  pop ebx               ;restore EBX
  pop eax               ;restore EDX
  ret                   ;return to caller 


;------------------------------------------------------------------------------
;       Name : printBuf
; Parameters : EDX - number of bytes to write
;    Returns : none
;   Modifies : none
;      Calls : none
;Description : Prints EDX bytes from outBuf to stdout

printBuf:

  ;save caller's state
  pushad                ;save caller's registers

  ;write output from output buffer
  mov eax, 4            ;code 4 = sys_write
  mov ebx, 1            ;file 1 = stdout
  mov ecx, outBuf       ;pass output buffer addr
  int 80h               ;make kernel call

  ;prepare to return
  popad                 ;restore caller's registers
  ret                   ;return

