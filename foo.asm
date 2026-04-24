section .data
    usage     db "Usage: ./main <filename>", 0xA
    usage_len equ $ - usage
    tab       db 9                      ; tab character after the line number

section .bss
    line_count resq 1                   ; current line number
    buffer     resb 4096                ; read buffer
    num_buf    resb 32                  ; buffer for number → text conversion

section .text
    global _start
    default rel

_start:
    ; === Check argc (must have exactly 1 argument = filename) ===
    mov rax, [rsp]
    cmp rax, 2
    jne .error

    ; === Open the file (argv[1]) ===
    mov rdi, [rsp + 16]                 ; filename
    mov rax, 2                          ; sys_open
    xor rsi, rsi                        ; O_RDONLY
    syscall
    test rax, rax
    js .error
    mov r12, rax                        ; save file descriptor

    ; === Init ===
    mov qword [line_count], 1
    mov r15, 1                          ; r15 = "is start of line" flag (1 = yes)

.read_loop:
    ; Read up to 4096 bytes
    mov rax, 0                          ; sys_read
    mov rdi, r12
    lea rsi, [buffer]
    mov rdx, 4096
    syscall

    test rax, rax
    jz .close                           ; EOF
    js .error                           ; read error

    mov r13, rax                        ; r13 = bytes read
    xor r14, r14                        ; r14 = current offset in buffer

.process_byte:
    cmp r14, r13
    jae .read_loop                      ; chunk finished → read next

    ; === If this is the start of a new line, print the line number + tab ===
    test r15, r15
    jz .print_byte

    mov rax, [line_count]
    call print_number

    mov rax, 1                          ; sys_write
    mov rdi, 1
    lea rsi, [tab]
    mov rdx, 1
    syscall

    xor r15, r15                        ; clear start-of-line flag

.print_byte:
    ; Print the current character from the file
    mov rax, 1
    mov rdi, 1
    lea rsi, [buffer + r14]
    mov rdx, 1
    syscall

    ; === If we just printed a newline, prepare for next line ===
    cmp byte [buffer + r14], 0xA
    jne .next_byte

    inc qword [line_count]
    mov r15, 1                          ; next byte will be start of a new line

.next_byte:
    inc r14
    jmp .process_byte

.close:
    mov rax, 3                          ; sys_close
    mov rdi, r12
    syscall

    ; Exit success
    mov rax, 60
    xor rdi, rdi
    syscall

.error:
    mov rax, 1
    mov rdi, 1
    lea rsi, [usage]
    mov rdx, usage_len
    syscall
    mov rax, 60
    mov rdi, 1
    syscall

; =============================================
; print_number: rax = number → prints it to stdout
; =============================================
print_number:
    test rax, rax
    jnz .convert

    ; Special case: 0
    mov byte [num_buf], '0'
    lea rsi, [num_buf]
    mov rdx, 1
    jmp .write

.convert:
    lea r8, [num_buf + 31]              ; start at the end of the buffer
    mov r9, 10

.convert_loop:
    dec r8
    xor rdx, rdx
    div r9
    add dl, '0'
    mov [r8], dl
    test rax, rax
    jnz .convert_loop

    mov rsi, r8
    lea rdx, [num_buf + 32]
    sub rdx, r8                         ; rdx = length

.write:
    mov rax, 1
    mov rdi, 1
    syscall
    ret