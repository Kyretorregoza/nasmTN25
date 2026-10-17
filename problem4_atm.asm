bits 32

section .data
    name_prompt       db "Enter account name: ", 0
    pin_prompt        db "Enter PIN: ", 0
    amount_prompt     db "Enter withdrawal amount: ", 0
    granted_text      db "ACCESS GRANTED", 10, 0
    denied_text       db "ACCESS DENIED", 10, 0
    balance_label     db "Current Balance: PHP ", 0
    invalid_amount    db "INVALID AMOUNT", 10, 0
    insufficient_text db "INSUFFICIENT FUNDS", 10, 0
    multiple_text     db "AMOUNT MUST BE A MULTIPLE OF 100", 10, 0
    success_text      db "WITHDRAWAL SUCCESSFUL", 10, 0
    withdrawn_label   db "Amount Withdrawn: PHP ", 0
    remaining_label   db "Remaining Balance: PHP ", 0
    invalid_name      db "INVALID NAME", 10, 0
    newline           db 10, 0
    balance           dd 10000

section .bss
    account_name resb 128
    pin_input    resb 32
    amount_input resb 32
    withdrawal   resd 1
    input_char   resb 1
    input_bad    resb 1
    number_text  resb 11

section .text
    global _start

_start:
    mov ecx, name_prompt
    call print_string
    mov ecx, account_name
    mov edx, 128
    call read_line
    jc .bad_name
    test eax, eax
    jz .bad_name

    mov ecx, pin_prompt
    call print_string
    mov ecx, pin_input
    mov edx, 32
    call read_line
    jc .denied

    call verify_pin
    jc .denied

    mov ecx, granted_text
    call print_string
    mov ecx, balance_label
    call print_string
    mov eax, [balance]
    call print_uint
    mov ecx, newline
    call print_string

    mov ecx, amount_prompt
    call print_string
    mov ecx, amount_input
    mov edx, 32
    call read_line
    jc .invalid
    call parse_uint
    jc .invalid

    ; Check 1: amount must be positive.
    test eax, eax
    jz .invalid

    ; Check 2: amount must not exceed the balance.
    cmp eax, [balance]
    ja .insufficient
    mov [withdrawal], eax

    ; Check 3: amount must be a multiple of 100.
    xor edx, edx
    mov ebx, 100
    div ebx
    test edx, edx
    jnz .not_multiple

    ; Deduct only after every check passes.
    mov eax, [withdrawal]
    sub [balance], eax

    mov ecx, success_text
    call print_string
    mov ecx, withdrawn_label
    call print_string
    call print_uint
    mov ecx, newline
    call print_string

    mov ecx, remaining_label
    call print_string
    mov eax, [balance]
    call print_uint
    mov ecx, newline
    jmp .display

.denied:
    mov ecx, denied_text
    jmp .display

.invalid:
    mov ecx, invalid_amount
    jmp .display

.insufficient:
    mov ecx, insufficient_text
    jmp .display

.not_multiple:
    mov ecx, multiple_text
    jmp .display

.bad_name:
    mov ecx, invalid_name

.display:
    call print_string
    jmp exit_program

; Require exactly the four characters 1234.
verify_pin:
    cmp byte [pin_input], '1'
    jne .wrong
    cmp byte [pin_input + 1], '2'
    jne .wrong
    cmp byte [pin_input + 2], '3'
    jne .wrong
    cmp byte [pin_input + 3], '4'
    jne .wrong
    cmp byte [pin_input + 4], 0
    jne .wrong
    clc
    ret

.wrong:
    stc
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