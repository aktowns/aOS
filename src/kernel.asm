; assemblyOS
; 32bit initialisation
;
; asmsyntax=fasm

format elf64

include 'multiboot.inc'
include 'struct.inc'
include 'debug.inc'

extrn long_mode_start

define FRAMEBUFFER_WIDTH  1024
define FRAMEBUFFER_HEIGHT 768
define FRAMEBUFFER_BPP    32

section '.multiboot' align 4
.header_start:
  dd MULTIBOOT2_HEADER_MAGIC     ; magic number (multiboot 2)
  dd MULTIBOOT_ARCHITECTURE_I386 ; architecture 0 (protected mode i386)
  dd .header_end - .header_start ; header length
  dd -(MULTIBOOT2_HEADER_MAGIC + MULTIBOOT_ARCHITECTURE_I386 + (.header_end - .header_start)) ; checksum
.information_request_tag_start:
  dw MULTIBOOT_HEADER_TAG_INFORMATION_REQUEST
  dw 0
  dd .information_request_tag_end - .information_request_tag_start
  dd MULTIBOOT_TAG_TYPE_CMDLINE
  dd MULTIBOOT_TAG_TYPE_MODULE
  dd MULTIBOOT_TAG_TYPE_BASIC_MEMINFO
  dd MULTIBOOT_TAG_TYPE_MMAP
  dd MULTIBOOT_TAG_TYPE_VBE
  dd MULTIBOOT_TAG_TYPE_FRAMEBUFFER
  dd MULTIBOOT_TAG_TYPE_ELF_SECTIONS
  dd MULTIBOOT_TAG_TYPE_APM
  dd MULTIBOOT_TAG_TYPE_ACPI_NEW
  dd MULTIBOOT_TAG_TYPE_END
.information_request_tag_end:
.framebuffer_tag_start:
  dw MULTIBOOT_HEADER_TAG_FRAMEBUFFER
  dw 0
  dd .framebuffer_tag_end - .framebuffer_tag_start
  dd FRAMEBUFFER_WIDTH
  dd FRAMEBUFFER_HEIGHT
  dd FRAMEBUFFER_BPP
.framebuffer_tag_end:
.header_end:

section '.bss' writeable align 16
p4_table:
  rb 4096
p3_table:
  rb 4096
p2_table:
  rb 4096
stack_bottom:
  rb 16384
stack_top:

section '.rodata' executable
use32
gdt64:                                     ; 64bit Global Descriptor Table
.null:                                     ; null descriptor
  dw 0                                     ; limit (low)
  dw 0                                     ; base (low)
  db 0                                     ; base (mid)
  db 0                                     ; access 
  db 0                                     ; granularity
  db 0                                     ; base (high)
.code = $ - gdt64 
  dq (1 shl 43) or (1 shl 44) or (1 shl 47) or (1 shl 53)
;.code = $ - gdt64                          ; code descriptor
;  dw 0                                     ; limit (low)
;  dw 0                                     ; base (low)
;  db 0                                     ; base (mid)
;  db 10011010b                             ; access 
;  db 00100000b                             ; granularity
;  db 0                                     ; base (high)
;.data = $ - gdt64                          ; data descriptor
;  dw 0                                     ; limit (low)
;  dw 0                                     ; base (low)
;  db 0                                     ; base (mid)
;  db 10010010b                             ; access 
;  db 00000000b                             ; granularity
;  db 0                                     ; base (high)
.pointer:
  dw $ - gdt64 - 1
  dq gdt64

section '.data' writable
use32
msg.early_boot   db "AOS Kernel early boot initialized", 0x0A, 0x0
msg.halting      db "Kernel halting..", 0x0A, 0x0
; check_multiboot 
msg.multiboot    db "Checking multiboot signature", 0x0A, 0x0
msg.multiboot_ok db "Multiboot signature ok", 0x0A, 0x0
err.multiboot    db "Multiboot signature verification failed", 0x0A, 0x0
; check_cpuid
msg.cpuid        db "Checking CPUID instruction is supported", 0x0A, 0x0
msg.cpuid_ok     db "CPUID instruction is supported", 0x0A, 0x0
err.cpuid        db "CPUID instruction is not supported", 0x0A, 0x0
; check_longmode
msg.longmode     db "Checking for 64bit support", 0x0A, 0x0
msg.longmode_ok  db "CPU has 64bit support", 0x0A, 0x0
err.longmode     db "CPU does not support 64bit (longmode)", 0x0A, 0x0
; set_up_page_tables 
msg.pagetables   db "Setting up page tables", 0x0A, 0x0
; enable_paging 
msg.paging       db "Enabling paging", 0x0A, 0x0
; jumping 
msg.jump         db "Jumping into 64bit mode", 0x0A, 0x0

section '.text' executable
use32
public start
start:
  mov esp, stack_top
  mov edi, ebx          ; move multiboot pointer to edi 

  dprint32 msg.early_boot

  call check_multiboot
  call check_cpuid
  call check_longmode
  
  call set_up_page_tables
  call enable_paging

  dprint32 msg.jump

  ; load the 64-bit GDT
  lgdt [gdt64.pointer]
  
  jmp gdt64.code:long_mode_start

  dprint32 msg.halting

  hlt

check_multiboot:
  dprint32 msg.multiboot

  cmp eax, MULTIBOOT2_BOOTLOADER_MAGIC 
  jne .no_multiboot 

  dprint32 msg.multiboot_ok
  ret
.no_multiboot:
  dprint32 err.multiboot
  hlt

check_cpuid:
  dprint32 msg.cpuid
  ; Check if CPUID is supported by attempting to flip the ID bit (bit 21)
  ; in the FLAGS register. If we can flip it, CPUID is available.

  ; Copy FLAGS in to EAX via stack
  pushfd
  pop eax

  ; Copy to ECX as well for comparing later on
  mov ecx, eax

  ; turn bit 21 on
  xor eax, 0x00200000

  ; Copy EAX to FLAGS via the stack
  push eax
  popfd

  ; Copy FLAGS back to EAX (with the flipped bit if CPUID is supported)
  pushfd 
  pop eax

  ; Restore FLAGS from the old version stored in ECX (i.e. flipping the
  ; ID bit back if it was ever flipped).
  push ecx
  popfd 
 
  ; Compare EAX and ECX. If they are equal then that means the bit
  ; wasn't flipped, and CPUID isn't supported.
  cmp eax, ecx
  je .no_cpuid
  dprint32 msg.cpuid_ok
  ret 
.no_cpuid:
  dprint32 err.cpuid
  hlt

check_longmode:
  dprint32 msg.longmode
  ; test if extended processor info in available
  mov eax, 0x80000000    ; implicit argument for cpuid
  cpuid                  ; get highest supported argument
  cmp eax, 0x80000001    ; it needs to be at least 0x80000001
  jb .no_long_mode       ; if it's less, the CPU is too old for long mode

  ; use extended info to test if long mode is available
  mov eax, 0x80000001    ; argument for extended processor info
  cpuid                  ; returns various feature bits in ecx and edx
  test edx, 0x20000000   ; test if the LM-bit is set in the D-register
  jz .no_long_mode       ; If it's not set, there is no long mode

  dprint32 msg.longmode_ok
  ret
.no_long_mode:
  dprint32 err.longmode
  hlt

set_up_page_tables:
  dprint32 msg.pagetables

  ; map P4 table recursively
  mov eax, p4_table
  or eax, 11b ; present + writable
  mov [p4_table + 511 * 8], eax

  ; map first P4 entry to P3 table
  mov eax, p3_table
  or eax, 11b ; present + writable
  mov [p4_table], eax

  ; map first P3 entry to P2 table
  mov eax, p2_table
  or eax, 11b ; present + writable
  mov [p3_table], eax

  ; map each P2 entry to a huge 2MiB page
  mov ecx, 0         ; counter variable

.map_p2_table:
    ; map ecx-th P2 entry to a huge page that starts at address 2MiB*ecx
    mov eax, 0x200000  ; 2MiB
    mul ecx            ; start address of ecx-th page
    or eax, 10000011b  ; present + writable + huge
    mov [p2_table + ecx * 8], eax ; map ecx-th entry

    inc ecx            ; increase counter
    cmp ecx, 512       ; if counter == 512, the whole P2 table is mapped
    jne .map_p2_table  ; else map the next entry

    ret

enable_paging:
    dprint32 msg.paging

    ; load P4 to cr3 register (cpu uses this to access the P4 table)
    mov eax, p4_table
    mov cr3, eax

    ; enable PAE-flag in cr4 (Physical Address Extension)
    mov eax, cr4
    or eax, 0x00000020
    mov cr4, eax

    ; set the long mode bit in the EFER MSR (model specific register)
    mov ecx, 0xC0000080
    rdmsr
    or eax, 0x00000100
    wrmsr

    ; enable paging in the cr0 register
    mov eax, cr0
    or eax, 0x80000000
    mov cr0, eax

    ret

