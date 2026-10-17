bits 32

section .data
    name_prompt    db "Enter student name: ", 0
    id_prompt      db "Enter student ID: ", 0
    grade_prompt   db "Enter grade: ", 0
    name_label     db "Student Name: ", 0
    id_label       db "Student ID: ", 0
    grade_label    db "Grade: ", 0
    class_label    db "Classification: ", 0
    excellent_text db "Excellent", 10, 0
    very_good_text db "Very Good", 10, 0
    good_text      db "Good", 10, 0
    passed_text    db "Passed", 10, 0
    failed_text    db "Failed", 10, 0
    invalid_grade  db "INVALID GRADE", 10, 0
    invalid_name   db "INVALID NAME", 10, 0
    invalid_id     db "INVALID STUDENT ID", 10, 0
    newline        db 10, 0

section .bss
    full_name   resb 128
    student_id  resb 64
    grade_input resb 32
    grade_bad   resb 1
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

    mov ecx, id_prompt
    call print_string
    mov ecx, student_id
    mov edx, 64
    call read_line
    jc .bad_id
    test eax, eax
    jz .bad_id

    ; Keep the ID as text to preserve leading zeros.
    mov ecx, grade_prompt
    call print_string
    mov ecx, grade_input
    mov edx, 32
    call read_line
    setc byte [grade_bad]

    call show_details

    cmp byte [grade_bad], 0
    jne .invalid
    mov ecx, grade_input
    call parse_uint
    jc .invalid

    cmp eax, 100
    ja .invalid

    ; Check grade boundaries from highest to lowest.
    cmp eax, 90
    jae .excellent
    cmp eax, 85
    jae .very_good
    cmp eax, 80
    jae .good
    cmp eax, 75
    jae .passed

    mov ecx, failed_text
    jmp .display

.excellent:
    mov ecx, excellent_text
    jmp .display

.very_good:
    mov ecx, very_good_text
    jmp .display

.good:
    mov ecx, good_text
    jmp .display

.passed:
    mov ecx, passed_text
    jmp .display

.invalid:
    mov ecx, invalid_grade
    jmp .display

.bad_name:
    mov ecx, invalid_name
    jmp .display

.bad_id:
    mov ecx, invalid_id

.display:
    call print_string
    jmp exit_program

show_details:
    mov ecx, name_label
    call print_string
    mov ecx, full_name
    call print_string
    mov ecx, newline
    call print_string

    mov ecx, id_label
    call print_string
    mov ecx, student_id
    call print_string
    mov ecx, newline
    call print_string

    mov ecx, grade_label
    call print_string
    mov ecx, grade_input
    call print_string
    mov ecx, newline
    call print_string

    mov ecx, class_label
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