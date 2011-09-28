;Executable Name: hex2raw
;Version        : 3.0
;Created Date   : 09/03/11
;Last Update    : 09/26/11
;Author         : Enrique Naudon
;Description    : This is a translator program written for Linux, using NASM
;                 2.09.04.  hex2raw takes ascii-encoded hex-digits as input and
;                 translates them to their raw hexidecimal values.  For
;                 example, '0' (30h in ascii) becomes 0000b (00h), and 'a' (61h
;                 in ascii) becomes 1010b (0Ah).  hex2raw does allow the user
;                 to use <space> and <EoL> characters for organizational
;                 purposes, but these characters are sanitized; all other
;                 characters will cause an error.  Similarly, an odd number of
;                 hex characters will cause an error.  
;
;Run it this way:
;   hex2raw < [input file] > [output file]
;
;Build using these commands:
;   nasm -f elf -g -F stabs h2rlib.asm
;   nasm -f elf -g -F stabs hex2raw.asm
;   ld -o hex2raw hex2raw.o h2rlib.o

SECTION .data           ;initialized data

;error messages
  parityErrMsg: db "Error: Incomplete byte!", 10  ;parity error message
  parityErrLen: equ $-parityErrMsg  ;parity error message length

  inputErrMsg: db "Error: Invalid character!", 10 ;invalid char error message
  inputErrLen:  equ $-inputErrMsg   ;invalid char error message length

SECTION .bss            ;uninitialized data

SECTION .text           ;code

;------------------------------------------------------------------------------
; * * * * * * * * * * * * * * {MAIN PROGRAM BODY} * * * * * * * * * * * * * * *
;------------------------------------------------------------------------------

GLOBAL _start           ;for the linker
EXTERN sanitize, translate, loadBuf, printBuf
EXTERN inBuf, outBuf

_start:
  nop                   ;for gdb

;read input to input buffer
  call loadBuf          ;call buffer-reading procedure

;exit when done reading
  cmp ecx, 0            ;check if bytes remain
  je  exit              ;terminate if no bytes remain

;sanitize input
  call sanitize         ;call sanitization procedure

;check input for incomplete bytes (ie. odd number of ascii chars)
  mov eax, ecx          ;copy byte count
  and eax, 1b           ;isolate lowest-order (units) bit on EDI
  test eax, 1b          ;test byte count parity
  jnz parityErr         ;print error if ascii byte count is odd

;prepare registers for translation
  lea esi, [inBuf-1]    ;load addr of byte before input buffer to ESI
  lea edi, [outBuf-1]   ;load addr of byte before output buffer to EDI
  shr ecx, 1            ;adjust (div by 2) ascii byte count to raw byte count
  call translate        ;translate hex to raw binary

;check error codes
  cmp eax, 0            ;check if all bytes were valid
  jne inputErr          ;print error if invalid byte was detected

;print translated bytes
  mov edx, ecx          ;pass num bytes to read (byte count)
  call printBuf         ;print outBuf
  jmp _start            ;jump up to the beginning to read more

;print error message
inputErr:
  mov eax, 4            ;code 4 = sys_write
  mov ebx, 2            ;file 2 = stderr
  mov ecx, inputErrMsg  ;pass error message addr
  mov edx, inputErrLen  ;pass error message length
  int 80h               ;make kernel call
  jmp exit              ;terminate after printing error message

;print error message
parityErr:
  mov eax, 4            ;code 4 = sys_write
  mov ebx, 2            ;file 2 = stderr
  mov ecx, parityErrMsg ;pass error message addr
  mov edx, parityErrLen ;pass error message length
  int 80h               ;make kernel call

;exit program
exit:
  mov eax, 1            ;code 1 = sys_exit
  mov ebx, 0            ;ret 0 = normal
  int 80h               ;make kernel call

