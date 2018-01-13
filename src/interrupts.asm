; assemblyOS
; Sets up interrupt handlers
;
; asmsyntax=fasm

include 'debug.inc'

format elf64

use64

section '.data'
exception.0  db "Fault: Divide Error (#DE)",                  0x0A, 0x0
exception.1  db "Fault: Debug Exception (#DB)",               0x0A, 0x0
exception.2  db "Interrupt: NMI",                             0x0A, 0x0
exception.3  db "Trap: Breakpoint (#BP)",                     0x0A, 0x0 
exception.4  db "Trap: Overflow (#OF)",                       0x0A, 0x0 
exception.5  db "Fault: BOUND range exceeded (#BR)",          0x0A, 0x0
exception.6  db "Fault: Invalid Opcode (#UD)",                0x0A, 0x0
exception.7  db "Fault: Device Not Available (#NM)",          0x0A, 0x0
exception.8  db "Abort: Double Fault (#DF)",                  0x0A, 0x0
exception.9  db "Fault: Coprocessor Segment Overrun",         0x0A, 0x0
exception.10 db "Fault: Invalid TSS (#TS)"         ,          0x0A, 0x0
exception.11 db "Fault: Segment Not Present (#NP)",           0x0A, 0x0
exception.12 db "Fault: Stack-Segment Fault (#SS)",           0x0A, 0x0
exception.13 db "Fault: General Protection (#GP)",            0x0A, 0x0
exception.14 db "Fault: Page Fault (#PF)",                    0x0A, 0x0
exception.15 db "Intel Reserved",                             0x0A, 0x0
exception.16 db "Fault: x87 FPU Floating-Point Error (#MF)",  0x0A, 0x0
exception.17 db "Fault: Alignment Check (#AC)",               0x0A, 0x0
exception.18 db "Abort: Machine Check (#MC)",                 0x0A, 0x0
exception.19 db "Fault: SIMD Floating-Point Exception (#XM)", 0x0A, 0x0
exception.20 db "Fault: Virtualisation Exception (#VE)",      0x0A, 0x0

idt:
  repeat 256
  dw 0x00  ; offset bits 0..15
  dw 0x00  ; code segment selector in GDT or LDT         
  db 0x00  ; bits 0..2 holds interupt stack table offset
  db 0x00  ; type and attributes
  dw 0x00  ; offset bits 16..31 
  dd 0x00  ; offset bits 32..63 
  dd 0x00  ; reserved
  end repeat
idt_init:
  dw idt_init - idt - 1 ; limit
  dq idt                ; base

define IDT_ENTRY_SZ 16

section '.text' writable
; Generate handlers for the intel interrupts
rept 21 num:0 {
  isr # num: 
    dprint64 exception. # num
    hlt
}
public setup.idt
setup.idt:
  rept 21 num:0 {
    mov rax, isr # num
    mov word [idt+num*IDT_ENTRY_SZ], ax
    mov word [idt+num*IDT_ENTRY_SZ+2], 0x8
    mov word [idt+num*IDT_ENTRY_SZ+4], 0x8E00
    shr rax, 16
    mov dword [idt+num*IDT_ENTRY_SZ+6], eax
    shr rax, 32
    mov word [idt+num*IDT_ENTRY_SZ+10], ax
  }

  

  lidt [idt_init]

  ret

