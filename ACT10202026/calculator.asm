; NASM 32-bit Linux Calculator
; Accepts numbers from 0 to 99

BITS 32
global _start

section .data
    clearCode db 27, "[2J", 27, "[H", 0

    menu db "----------------------------------", 10
         db "MENU", 10
         db "[A]dd", 10
         db "[S]ubtract", 10
         db "[M]ultiply", 10
         db "[D]ivide", 10
         db "----------------------------------", 10
         db "Enter your choice: ", 0

    firstPrompt db "Enter first number: ", 0
    secondPrompt db "Enter second number: ", 0

    sumMessage db "The sum is ", 0
    differenceMessage db "The difference is ", 0
    productMessage db "The product is ", 0
    quotientMessage db "The quotient is ", 0
    remainderMessage db " with remainder ", 0

    retryPrompt db 10, "Do you want to try again (Y/N): ", 0

    invalidChoice db "Invalid choice. Enter A, S, M, or D.", 10, 0
    invalidNumber db "Enter a valid number from 0 to 99.", 10, 0
    invalidRetry db "Please enter Y or N.", 10, 0
    zeroMessage db "Cannot divide by zero.", 0
    goodbye db "Program terminated.", 10, 0
    minusSign db "-", 0

section .bss
    buffer resb 16
    character resb 1
    outputBuffer resb 12

    choice resb 1
    firstNumber resd 1
    secondNumber resd 1
    remainder resd 1

section .text

_start:
    call clear_screen

show_menu:
    mov ecx, menu
    call print_string
    call read_line

    cmp eax, 1
    jne bad_choice

    mov al, [buffer]
    and al, 0DFh

    cmp al, 'A'
    je valid_choice

    cmp al, 'S'
    je valid_choice

    cmp al, 'M'
    je valid_choice

    cmp al, 'D'
    je valid_choice

bad_choice:
    mov ecx, invalidChoice
    call print_string
    jmp show_menu

valid_choice:
    mov [choice], al

    mov ecx, firstPrompt
    call read_number
    mov [firstNumber], eax

    mov ecx, secondPrompt
    call read_number
    mov [secondNumber], eax

    cmp byte [choice], 'A'
    je perform_add

    cmp byte [choice], 'S'
    je perform_subtract

    cmp byte [choice], 'M'
    je perform_multiply

    call divide_numbers
    jmp ask_again

perform_add:
    call add_numbers
    jmp ask_again

perform_subtract:
    call subtract_numbers
    jmp ask_again

perform_multiply:
    call multiply_numbers

ask_again:
    mov ecx, retryPrompt
    call print_string
    call read_line

    cmp eax, 1
    jne bad_retry

    mov al, [buffer]
    and al, 0DFh

    cmp al, 'Y'
    je restart

    cmp al, 'N'
    je exit_program

bad_retry:
    mov ecx, invalidRetry
    call print_string
    jmp ask_again

restart:
    call clear_screen
    jmp show_menu

; ----------------------------------
; Addition procedure
; ----------------------------------
add_numbers:
    mov ecx, sumMessage
    call print_string

    mov eax, [firstNumber]
    add eax, [secondNumber]

    call print_integer
    ret

; ----------------------------------
; Subtraction procedure
; ----------------------------------
subtract_numbers:
    mov ecx, differenceMessage
    call print_string

    mov eax, [firstNumber]
    sub eax, [secondNumber]

    call print_integer
    ret

; ----------------------------------
; Multiplication procedure
; ----------------------------------
multiply_numbers:
    mov ecx, productMessage
    call print_string

    mov eax, [firstNumber]
    imul eax, [secondNumber]

    call print_integer
    ret

; ----------------------------------
; Division procedure
; ----------------------------------
divide_numbers:
    cmp dword [secondNumber], 0
    je .division_by_zero

    mov ecx, quotientMessage
    call print_string

    mov eax, [firstNumber]
    xor edx, edx
    div dword [secondNumber]

    mov [remainder], edx
    call print_integer

    mov ecx, remainderMessage
    call print_string

    mov eax, [remainder]
    call print_integer
    ret

.division_by_zero:
    mov ecx, zeroMessage
    call print_string
    ret

; ----------------------------------
; Clear the screen
; ----------------------------------
clear_screen:
    mov ecx, clearCode
    call print_string
    ret

; ----------------------------------
; Print a null-terminated string
; Input: ECX = string address
; ----------------------------------
print_string:
    pushad
    xor edx, edx

.count:
    cmp byte [ecx + edx], 0
    je .display

    inc edx
    jmp .count

.display:
    mov eax, 4
    mov ebx, 1
    int 80h

    popad
    ret

; ----------------------------------
; Read a complete line
; Output: EAX = length
; Oversized lines return length 16.
; ----------------------------------
read_line:
    push ebx
    push ecx
    push edx
    push esi
    push edi

    xor esi, esi
    xor edi, edi

.read:
    mov eax, 3
    xor ebx, ebx
    mov ecx, character
    mov edx, 1
    int 80h

    test eax, eax
    jle exit_program

    mov al, [character]

    cmp al, 10
    je .done

    cmp al, 13
    je .read

    cmp esi, 15
    jae .too_long

    mov [buffer + esi], al
    inc esi
    jmp .read

.too_long:
    mov edi, 1
    jmp .read

.done:
    mov byte [buffer + esi], 0
    mov eax, esi

    test edi, edi
    jz .return

    mov eax, 16

.return:
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret

; ----------------------------------
; Read and validate a number: 0-99
; Input: ECX = prompt address
; Output: EAX = number
; ----------------------------------
read_number:
    push ebx
    push esi
    push edi

    mov edi, ecx

.retry:
    mov ecx, edi
    call print_string
    call read_line

    cmp eax, 1
    jb .invalid

    cmp eax, 2
    ja .invalid

    mov ebx, eax
    xor eax, eax
    xor esi, esi

.convert:
    movzx edx, byte [buffer + esi]

    cmp edx, '0'
    jb .invalid

    cmp edx, '9'
    ja .invalid

    sub edx, '0'
    imul eax, eax, 10
    add eax, edx

    inc esi
    cmp esi, ebx
    jb .convert

    pop edi
    pop esi
    pop ebx
    ret

.invalid:
    mov ecx, invalidNumber
    call print_string
    jmp .retry

; ----------------------------------
; Print signed integer in EAX
; ----------------------------------
print_integer:
    pushad

    test eax, eax
    jns .positive

    mov ecx, minusSign
    call print_string
    neg eax

.positive:
    mov edi, outputBuffer + 11
    mov byte [edi], 0
    mov ebx, 10

.convert:
    xor edx, edx
    div ebx

    add dl, '0'
    dec edi
    mov [edi], dl

    test eax, eax
    jnz .convert

    mov ecx, edi
    call print_string

    popad
    ret

exit_program:
    mov ecx, goodbye
    call print_string

    mov eax, 1
    xor ebx, ebx
    int 80h

section .note.GNU-stack noalloc noexec nowrite progbits