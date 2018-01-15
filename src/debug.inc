; assemblyOS
; Debug printing utilities
;
; asmsyntax=fasm

define QEMU_DEBUG 0x402       ; qemu debug console
define BOCHS_DEBUG 0xe9       ; bochs output char
define DEBUG0 0xe9

macro pushaq {
    push rax
    push rcx
    push rdx
    push rbx
    push rbp
    push rsi
    push rdi
    push r8
    push r9
    push r10
    push r11
    push r12
    push r13
    push r14
    push r15
}

macro popaq {
    pop r15 
    pop r14 
    pop r13
    pop r12
    pop r11
    pop r10
    pop r9
    pop r8
    pop rdi    
    pop rsi    
    pop rbp    
    pop rbx    
    pop rdx    
    pop rcx
    pop rax
}

macro breakpoint {
  xchg bx, bx
}

macro print.signed_int num* {
  local .loop, .done, .print
  pushaq

  mov rax, num 
  mov r11, num

  mov r10, 0
.loop:
  cmp rax, 0 
  je .negcheck

  mov r8, 10
  cqo
  idiv r8

  not rdx
  add rdx, 49

  push rdx
  inc r10

  jmp .loop 
.negcheck:
  test r11, r11 
  jns .print
  push '-'
  inc r10
.print:
  cmp r10, 0
  je .done

  pop rax
  mov dx, DEBUG0
  out dx, ax

  dec r10
  jmp .print
.done:
  popaq
}

macro print.unsigned_int num* {
  local .loop, .done, .print
  pushaq

  mov rax, num 
  mov r10, 0
.loop:
  cmp rax, 0 
  je .print

  mov r8, 10
  xor rdx, rdx
  div r8

  add rdx, 48
  push rdx
  inc r10

  jmp .loop 
.print:
  cmp r10, 0
  je .done

  pop rax
  mov dx, DEBUG0
  out dx, ax

  dec r10
  jmp .print
.done:
  popaq
}



; print 
;;;;;;;;;;
; Writes the C string pointed by format to DEBUG0. If format includes format specifiers 
; (subsequences beginning with %), the additional arguments following format are ;
; formatted and inserted in the resulting string replacing their respective specifiers.
;
; fmt*    : format string, eg. "The number is %i" 
; [args*] : arguments to the format string, eg 42
macro print fmt*, [args*] {
  pushaq
  reverse push args
  common
  local .loop, .buf, .done, .newline, .char, .numb, .rep

  mov dx, DEBUG0
  lea r8, [.buf]
  .loop:
    cmp byte [r8], 0x0  ; null 
    je .done
    cmp word [r8], '\n' ; newline
    je .newline
    cmp word [r8], '%c' ; char
    je .char
    cmp word [r8], '%i' ; signed int
    je .sint
    cmp word [r8], '%u' ; unsigned int
    je .uint
    cmp word [r8], '%x' ; hexadecimal
    je .hex

    mov ax, [r8]
    out dx, ax 
    add r8, 1
    jmp .loop
  .newline:
    mov ax, 0x0A 
    out dx, ax
    jmp .rep
  .char:
    pop ax 
    out dx, ax
    jmp .rep
  .hex:
  .uint:
    pop r9 
    print.unsigned_int r9
    jmp .rep
  .sint: 
    pop r9 
    print.signed_int r9
    jmp .rep
  .rep:
    add r8, 2
    jmp .loop
    .buf db fmt, 0
  .done:
    popaq
}

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
  pushaq
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
  popaq
}

