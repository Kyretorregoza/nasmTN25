bits 32

section .data
    name_prompt    db "What is your name? ", 0
    age_prompt     db "How old are you? ", 0
    year_prompt    db "What is your year level? ", 0
    hello_text     db "Hello ", 0
    age_prefix     db "You are ", 0
    age_suffix     db " years old", 10, 0
    freshman_text  db "Freshman", 10, 0
    sophomore_text db "Sophomore", 10, 0
    junior_text    db "Junior", 10, 0
    senior_text    db "Senior", 10, 0
    invalid_year   db "INVALID YEAR LEVEL", 10, 0
    invalid_name   db "INVALID NAME", 10, 0
    invalid_age    db "INVALID AGE", 10, 0
    newline        db 10, 0

section .bss
    full_name   resb 128
    age_input   resb 32
    year_input  resb 32
    age_value   resd 1
    year_bad    resb 1
    input_char  resb 1
    input_bad   resb 1
    number_text resb 11

section .text
    global _start

_start:
    mov ecx, name_prompt
    call print_string
    mov ecx, full_name
    mov edx, 128
    call read_line
    jc .bad_name
    test eax, eax
    jz .bad_name

    mov ecx, age_prompt
    call print_string
    mov ecx, age_input
    mov edx, 32
    call read_line
    jc .bad_age
    call parse_uint
    jc .bad_age
    mov [age_value], eax

    mov ecx, year_prompt
    call print_string
    mov ecx, year_input
    mov edx, 32
    call read_line
    setc byte [year_bad]

    call show_greeting

    cmp byte [year_bad], 0
    jne .invalid
    mov ecx, year_input
    call parse_uint
    jc .invalid

    cmp eax, 1
    je .freshman
    cmp eax, 2
    je .sophomore
    cmp eax, 3
    je .junior
    cmp eax, 4
    je .senior
    jmp .invalid

.freshman:
    mov ecx, freshman_text
    jmp .display

.sophomore:
    mov ecx, sophomore_text
    jmp .display

.junior:
    mov ecx, junior_text
    jmp .display

.senior:
    mov ecx, senior_text
    jmp .display

.invalid:
    mov ecx, invalid_year
    jmp .display

.bad_name:
    mov ecx, invalid_name
    jmp .display

.bad_age:
    mov ecx, invalid_age

.display:
    call print_string
    jmp exit_program

show_greeting:
    mov ecx, hello_text
    call print_string
    mov ecx, full_name
    call print_string
    mov ecx, newline
    call print_string

    mov ecx, age_prefix
    call print_string
    mov eax, [age_value]
    call print_uint
    mov ecx, age_suffix
    call print_string
    ret

; Print the zero-terminated string at ECX.
print_string:
    pushad
    xor edx, edx

.length:
    cmp byte [ecx + edx], 0
    je .write
    inc edx
    jmp .length

.write:
    mov eax, 4
    mov ebx, 1
    int 0x80
    popad
    ret

; Read a line into ECX, with capacity EDX.
; EAX returns its length. Carry indicates invalid input.
read_line:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp

    mov edi, ecx
    mov esi, edx
    dec esi
    xor ebp, ebp
    mov byte [input_bad], 0

.read:
    mov eax, 3
    xor ebx, ebx
    mov ecx, input_char
    mov edx, 1
    int 0x80

    cmp eax, 1
    je .character
    test eax, eax
    jz .eof
    cmp eax, -4
    je .read
    mov byte [input_bad], 1
    jmp .finish

.eof:
    test ebp, ebp
    jnz .finish
    mov byte [input_bad], 1
    jmp .finish

.character:
    mov al, [input_char]
    cmp al, 10
    je .finish
    test al, al
    jz .bad_character
    cmp ebp, esi
    jae .bad_character

    mov [edi + ebp], al
    inc ebp
    jmp .read

.bad_character:
    mov byte [input_bad], 1
    jmp .read

.finish:
    test ebp, ebp
    jz .terminate
    cmp byte [edi + ebp - 1], 13
    jne .terminate
    dec ebp

.terminate:
    mov byte [edi + ebp], 0
    mov eax, ebp
    cmp byte [input_bad], 0
    jne .failure
    clc
    jmp .restore

.failure:
    stc

.restore:
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret

; Convert ASCII digits at ECX to an unsigned integer in EAX.
; Carry indicates invalid input or overflow.
parse_uint:
    push ebx
    push edx
    push esi

    mov esi, ecx
    xor eax, eax
    cmp byte [esi], 0
    je .invalid

.digit:
    movzx ebx, byte [esi]
    test ebx, ebx
    jz .valid

    sub ebx, '0'
    cmp ebx, 9
    ja .invalid

    mov edx, 10
    mul edx
    test edx, edx
    jnz .invalid

    add eax, ebx
    jc .invalid
    inc esi
    jmp .digit

.valid:
    clc
    jmp .restore

.invalid:
    stc

.restore:
    pop esi
    pop edx
    pop ebx
    ret

; Display the unsigned integer in EAX.
print_uint:
    pushad
    mov edi, number_text + 10
    mov byte [edi], 0
    mov ebx, 10

.digit:
    xor edx, edx
    div ebx
    add dl, '0'
    dec edi
    mov [edi], dl
    test eax, eax
    jnz .digit

    mov ecx, edi
    call print_string
    popad
    ret

exit_program:
    mov eax, 1
    xor ebx, ebx
    int 0x80