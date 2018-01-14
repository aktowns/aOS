; assemblyOS
; 64bit entry point
;
; asmsyntax=fasm

format elf64

use64

extrn itoa
extrn setup.idt

define DEBUG0 0x402       ; qemu debug console

include 'debug.inc'

section '.bss' writeable align 16
stack64_bottom:
  rb 16384
stack64_top:

section '.data' writable
hello db "Hello from 64bit! halting CPU", 0x0A, 0x0
msg.itoa db "Testing itoa works properly 1234567890 is.. ", 0x0
itoa_num dd 1234567890

section '.bss' writable
store.itoa: 
  rb 10

section '.text' executable
public long_mode_start
long_mode_start:
  ; load 0 into all data segment registers
  mov ax, 0
  mov ss, ax
  mov ds, ax
  mov es, ax
  mov fs, ax
  mov gs, ax
  mov esp, stack64_top


  dprint64 hello

  call setup.idt

  print "Hello %i or %i\n", 42, 1337

  ;dprint64 msg.itoa

  ;mov rdi, 1234567890 ; dword [itoa_num]
  ;call itoa
  ;push qword [rax]
  ;pop qword [store.itoa]
  ;mov [store.itoa], rax

  ; dprint64 store.itoa
   
  hlt
