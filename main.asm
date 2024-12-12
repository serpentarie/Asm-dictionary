%include "dict.inc"
%include "lib.inc"
%include "colon.inc"

section .data
%include "words.inc"
message_long db "Input is too long", 0
message_not_found db "Key not found", 0

section .text
global _start
_start:
    push r12
    sub rsp, 256
    mov rdi, 256
    mov rsi, rsp
    call read_string
    test rax, rax
    jz .error_long
    mov r12, rax
    mov rsi, last
    mov rdi, rsp
    call find_word
    test rax, rax
    jz .error_not_found
    lea rdi, [r12 + rax + 8]
    call print_string
    jmp .end
    .error_long:
        mov rdi, message_long
        call print_string_error
        mov rdi, 1
        jmp .end
    .error_not_found:
        mov rdi, message_not_found
        call print_string_error
        mov rdi, 1
    .end:
        add rsp, 256
        pop r12
        call print_newline
        call exit