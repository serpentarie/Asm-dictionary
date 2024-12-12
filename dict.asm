%include "lib.inc"
section .text
global find_word

find_word:
    .loop:
        test rsi, rsi
        je .end
        push rsi
        lea rsi, [rsi + 8]
        push rdi
        call string_equals
        pop rdi
        pop rsi
        test rax, rax
        jnz .equal
        mov rsi, [rsi]
        jmp .loop
    .equal:
        mov rax, rsi
        ret
    .end:
        xor rax, rax
        ret