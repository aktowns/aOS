; assemblyOS
; Debug printing utilities
;
; asmsyntax=fasm

define QEMU_DEBUG 0x402       ; qemu debug console
define BOCHS_DEBUG 0xe9       ; bochs output char
define DEBUG0 0xe9

macro dprint32 value* {
  push eax
  push ebx
  lea ebx, [value]
  mov dx, DEBUG0
@@:
  cmp [ebx], byte 0x0     ; are we null terminated?
  je @f
  mov eax, [ebx]          ; eax=*ebx                          
  out dx, eax             ; write out eax to qemu debug port 
  add ebx, dword 1        ; ebx=ebx+1
  jmp @b
@@:
  pop ebx 
  pop eax
}

macro dprint64 value* {
  push rax
  push rbx
  lea rbx, [value]
  mov dx, DEBUG0
@@:
  cmp [rbx], byte 0x0     ; are we null terminated?
  je @f
  mov eax, [rbx]          ; eax=*ebx                          
  out dx, eax             ; write out eax to qemu debug port 
  add rbx, 1              ; ebx=ebx+1
  jmp @b
@@:
  pop rbx 
  pop rax
}

