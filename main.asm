; main.asm - asmcat: print lines with line numbers
; Usage: ./numblines [-h] <file1> [file2] ...
;
; Part 2 bonuses: +1 files>64KB  +2 multiple files  +1 string instr  +2 external proc
; OS calls: sys_open(2) sys_write(1) sys_close(3) sys_exit(60) sys_ioctl(16)
; ANSI: ESC[2J clear screen, ESC[H cursor home  (only when stdout is a tty)

%include "macros.mac"

        extern  process_file
        default rel

section .data

ansi_cls:   db  0x1B, '[', '2', 'J'        ; clear screen
ansi_home:  db  0x1B, '[', 'H'             ; cursor to row 1, col 1

help_msg:
        db  "numblines - print every line of a file with its line number", 0xA
        db  0xA
        db  "Usage:  ./numblines [-h] <file1> [file2] ...", 0xA
        db  0xA
        db  "  -h   show this help and exit", 0xA
        db  0xA
        db  "Line numbering is continuous across all input files.", 0xA
        db  "Files larger than 64 KB are supported.", 0xA, 0xA
help_len    equ $ - help_msg

err_noargs: db  "Error: no input file. Use -h for help.", 0xA
err_noargs_len equ $ - err_noargs

err_open:   db  "Error: cannot open: "
err_open_len equ $ - err_open

newline:    db  0xA

section .bss
line_count  resq 1          ; shared line counter across all files

section .text
        global _start

_start:
        mov     r13, [rsp]          ; argc
        lea     r12, [rsp + 8]      ; argv

        cmp     r13, 2
        jl      .no_args

        mov     rdi, [r12 + 8]      ; argv[1]
        cmp     byte [rdi],     '-'
        jne     .start_files
        cmp     byte [rdi + 1], 'h'
        jne     .start_files
        cmp     byte [rdi + 2], 0
        jne     .start_files
        jmp     .show_help

.start_files:
        mov     qword [rel line_count], 1
        mov     r14, 1              ; argv index

.file_loop:
        cmp     r14, r13
        jge     .exit_ok

        mov     r15, [r12 + r14*8] ; filename

        mov     rdi, r15
        mov     rax, 2             ; sys_open O_RDONLY
        xor     rsi, rsi
        xor     rdx, rdx
        syscall
        test    rax, rax
        js      .open_error

        mov     rbx, rax           ; fd

        mov     rdi, rbx
        lea     rsi, [rel line_count]
        call    process_file       ; external proc in proc.asm

        mov     rax, 3             ; sys_close
        mov     rdi, rbx
        syscall

        inc     r14
        jmp     .file_loop

.exit_ok:
        sys_exit 0

.show_help:
        ; ioctl(1, TIOCGWINSZ) — succeeds only when stdout is a tty
        sub     rsp, 8
        mov     rax, 16
        mov     rdi, 1
        mov     rsi, 0x5413
        mov     rdx, rsp
        syscall
        add     rsp, 8
        test    rax, rax
        js      .help_text          ; not a tty — skip ANSI

        mov     rax, 1              ; ESC[2J
        mov     rdi, 1
        lea     rsi, [rel ansi_cls]
        mov     rdx, 4
        syscall
        mov     rax, 1              ; ESC[H
        mov     rdi, 1
        lea     rsi, [rel ansi_home]
        mov     rdx, 3
        syscall

.help_text:
        lea     rsi, [rel help_msg]
        print_str rsi, help_len
        sys_exit 0

.no_args:
        lea     rsi, [rel err_noargs]
        print_err rsi, err_noargs_len
        sys_exit 1

.open_error:
        lea     rsi, [rel err_open]
        print_err rsi, err_open_len
        mov     rdi, r15
        call    strlen
        mov     rdx, rax
        mov     rsi, r15
        sys_write 2, rsi, rdx
        lea     rsi, [rel newline]
        sys_write 2, rsi, 1
        inc     r14
        jmp     .file_loop

; strlen — scan for null byte using SCASB (string instr, bonus task 11)
; in: rdi = string pointer   out: rax = length
strlen:
        push    rsi
        mov     rsi, rdi
        xor     al, al
        mov     rcx, 4096
        cld
        repne   scasb
        lea     rax, [rdi - 1]
        sub     rax, rsi
        pop     rsi
        ret