section .text
%define SYS_READ 0
%define SYS_WRITE 1
%define SYS_EXIT 60
%define STDIN 0
%define STDOUT 1
%define STDERR 2
global exit
global string_length
global print_string
global print_string_error
global print_char
global print_newline
global print_uint
global print_int
global string_equals
global read_char
global read_word
global read_string
global parse_uint
global parse_int
global string_copy

; Принимает код возврата и завершает текущий процесс
exit: 
    mov rax, SYS_EXIT
    syscall

; Принимает указатель на нуль-терминированную строку, возвращает её длину
string_length:
    xor rax, rax
    .loop:
        cmp byte [rdi + rax], 0
        je .end
        inc rax
        jmp .loop
    .end:
        ret

; Принимает указатель на нуль-терминированную строку, выводит её в stdout
print_string:
    push rdi
    call string_length
    pop rdi
    mov rdx, rax
    mov rsi, rdi
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    syscall
    ret

; Принимает указатель на нуль-терминированную строку, выводит её в stderr
print_string_error:
    push rdi
    call string_length
    pop rdi
    mov rdx, rax
    mov rsi, rdi
    mov rax, SYS_WRITE
    mov rdi, STDERR
    syscall
    ret

; Принимает код символа и выводит его в stdout
print_char:
    sub rsp, 8
    mov [rsp], dil
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rsi, rsp
    mov rdx, 1
    syscall
    add rsp,8
    ret

; Переводит строку (выводит символ с кодом 0xA)
print_newline:
    sub rsp, 1
    mov byte [rsp], `\n`
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rsi, rsp
    mov rdx, 1
    syscall
    add rsp, 1
    ret

; Выводит беззнаковое 8-байтовое число в десятичном формате
print_uint:
    xor rax, rax
    push rbp
    mov rax, rdi
    mov rbp, rsp
    sub rsp, 32
    mov r10, 10
    dec rbp
    mov byte [rbp], 0
    .convert:
        xor rdx, rdx
        div r10
        add dl, '0'
        dec rbp
        mov byte [rbp], dl
        test rax, rax
        jz .end
        jmp .convert
    .end:
        mov rdi, rbp
        call print_string
        add rsp, 32
        pop rbp
        ret

; Выводит знаковое 8-байтовое число в десятичном формате 
print_int:
    xor rax, rax
    test rdi, rdi
    jge print_uint
    neg rdi
    push rdi
    mov rdi, '-'
    call print_char
    pop rdi
    jmp print_uint
    ret

; Принимает два указателя на нуль-терминированные строки, возвращает 1 если они равны, 0 иначе
string_equals:
    xor rax, rax
    .loop:
        mov bl, byte [rdi]
        cmp bl, byte [rsi]
        jne .end
        test bl, bl
        jz .equal
        inc rsi
        inc rdi
        jmp .loop
    .equal:
        inc rax
    .end:
        ret

; Читает один символ из stdin и возвращает его. Возвращает 0 если достигнут конец потока
read_char:
    xor rax, rax
    mov rax, SYS_READ
    mov rdi, STDIN
    push 0
    mov rsi, rsp
    mov rdx, 1
    syscall
    pop rax
    ret

; Принимает: адрес начала буфера, размер буфера
; Читает в буфер слово из stdin, пропуская пробельные символы в начале.
; Останавливается и возвращает 0 если слово слишком большое для буфера
; При успехе возвращает адрес буфера в rax, длину слова в rdx.
; При неудаче возвращает 0 в rax
; Эта функция дописывает к слову нуль-терминатор
read_word:
    xor rax, rax
    .start:
        mov rcx, rdi
        push rdi
        push rsi
        push rcx
        call read_char
        pop rcx
        pop rsi
        pop rdi
        cmp al, ` `
        jz .start
        cmp al, `\t`
        jz .start
        cmp al, `\n`
        jz .start
        cmp al, 0
        jz .good_word
        mov [rdi], al
        inc rdi
        dec rsi
    .read:
        push rdi
        push rsi
        push rcx
        call read_char
        pop rcx
        pop rsi
        pop rdi
        cmp al, ` `
        jz .good_word
        cmp al, `\t`
        jz .good_word
        cmp al, `\n`
        jz .good_word
        test al, al
        jz .good_word
        cmp rsi, 1
        jz .big_word
        mov [rdi], al
        inc rdi
        dec rsi
        jmp .read
    .big_word:
        xor rax, rax
        jmp .end
    .good_word:
        mov byte[rdi], 0
        dec rsi
        mov rax, rcx
        sub rdi, rcx
        mov rdx, rdi
    .end:
        ret

read_string:
    mov rax, SYS_READ
    mov rdx, rdi
    mov rdi, STDIN
    syscall
    mov byte [rsp + rax + 7], 0
    ret

; Принимает указатель на строку, пытается
; прочитать из её начала беззнаковое число.
; Возвращает в rax: число, rdx : его длину в символах
; rdx = 0 если число прочитать не удалось
parse_uint:
    xor rax, rax
    xor rdx, rdx
    .loop:
        mov cl, byte [rdi + rdx]
        sub cl, '0'
        jl .end
        cmp cl, 9
        jg .end
        inc rdx
        imul rax, 10
        add rax, rcx
        jmp .loop
    .end:
        ret

; Принимает указатель на строку, пытается
; прочитать из её начала знаковое число.
; Если есть знак, пробелы между ним и числом не разрешены.
; Возвращает в rax: число, rdx : его длину в символах (включая знак, если он был) 
; rdx = 0 если число прочитать не удалось
parse_int:
    xor rax, rax
    cmp byte [rdi], '-'
    jne parse_uint
    push rdi
    inc rdi
    call parse_uint
    inc rdx
    pop rdi
    neg rax
    ret

; Принимает указатель на строку, указатель на буфер и длину буфера
; Копирует строку в буфер
; Возвращает длину строки если она умещается в буфер, иначе 0
string_copy:
    push rdi
    push rsi
    push rdx
    call string_length
    pop rdx
    pop rsi
    pop rdi
    cmp rax, rdx
    ja .bad_end
    .loop:
        movzx rcx, byte [rdi]
        mov [rsi], rcx
        test rcx, rcx
        jz .end
        inc rdi
        inc rsi
        jmp .loop
    .bad_end:
        xor rax, rax
    .end:
        ret
