; proc.asm - asmcat: external procedure process_file
;
; void process_file(int64_t fd, int64_t *line_count)
;   rdi = open file descriptor
;   rsi = pointer to shared line counter (continuous across files)
;
; Bonus task 7:  64 KB buffer + read loop handles files > 64 KB
; Bonus task 11: STOSB (digit write) and SCASB (newline scan) string instructions

%include "macros.mac"

        global  process_file
        default rel

section .data
pf_tab  db  9               ; TAB after line number

section .bss
pf_buf  resb 65536           ; 64 KB read buffer
pf_num  resb 21              ; decimal conversion workspace

section .text

; pf_print_num — print rax (uint64) to stdout
; Uses STOSB (DF=1) to fill pf_num right-to-left (no reversal needed).
; Key: quotient saved in r11 before "mov al, dl" to avoid clobbering rax.
; Clobbers: rax, rdx, rdi, rsi, r10, r11
pf_print_num:
        push    rbx
        lea     rdi, [rel pf_num + 20]
        xor     rbx, rbx            ; digit count
        mov     r10, 10
        std                         ; DF=1: STOSB decrements rdi

        test    rax, rax
        jnz     .loop
        mov     al, '0'             ; special case: zero
        stosb
        inc     rbx
        jmp     .write

.loop:
        test    rax, rax
        jz      .write
        xor     rdx, rdx
        div     r10                 ; rax=quotient  rdx=remainder
        mov     r11, rax            ; save quotient before al is clobbered
        add     dl, '0'
        mov     al, dl
        stosb
        inc     rbx
        mov     rax, r11
        jmp     .loop

.write:
        cld                         ; restore DF=0
        inc     rdi                 ; rdi was left one byte before first digit
        print_str rdi, rbx
        pop     rbx
        ret


; process_file — register map:
;   rbx=fd  rbp=line_count*  r13=bytes_read  r14=buf_offset
;   r15=sol_flag (1=start of line)  r12=segment_start
process_file:
        push    rbx
        push    r12
        push    r13
        push    r14
        push    r15
        push    rbp
        sub     rsp, 8              ; 16-byte stack alignment

        mov     rbx, rdi
        mov     rbp, rsi
        mov     r15, 1              ; beginning of file = start of first line

.read_loop:
        mov     rax, 0              ; sys_read
        mov     rdi, rbx
        lea     rsi, [rel pf_buf]
        mov     rdx, 65536
        syscall
        test    rax, rax
        jle     .done               ; 0=EOF  negative=error
        mov     r13, rax
        xor     r14, r14

.segment:
        mov     rcx, r13
        sub     rcx, r14
        jz      .read_loop

        test    r15, r15            ; start of line?
        jz      .no_prefix
        mov     rax, [rbp]
        call    pf_print_num
        lea     rsi, [rel pf_tab]
        print_str rsi, 1
        xor     r15, r15

.no_prefix:
        ; SCASB: scan buffer forward for newline 0x0A (bonus task 11)
        mov     rcx, r13
        sub     rcx, r14
        lea     rdi, [rel pf_buf]
        add     rdi, r14
        mov     r12, rdi            ; segment start
        mov     al, 0x0A
        cld
        repne   scasb               ; ZF=1 if newline found
        sete    r8b

        mov     rdx, rdi
        sub     rdx, r12            ; segment length (includes newline if found)
        add     r14, rdx
        print_str r12, rdx

        test    r8b, r8b
        jz      .read_loop          ; no newline — fetch more data

        inc     qword [rbp]         ; next line
        mov     r15, 1
        jmp     .segment

.done:
        add     rsp, 8
        pop     rbp
        pop     r15
        pop     r14
        pop     r13
        pop     r12
        pop     rbx
        ret