section .data

    ; ASCII artwork using decimal ASCII values
    missile db 32,32,47,92,32,32,32,32,32,124,92,42,42,47,124,10
            db 32,47,32,32,92,32,32,32,32,92,32,61,61,32,47,10
            db 32,124,32,32,124,32,32,32,32,32,124,32,32,124,10
            db 32,124,32,32,124,32,32,32,32,32,124,32,32,124,10
            db 47,32,61,61,32,92,32,32,32,32,92,32,32,47,10
            db 124,47,42,42,92,124,32,32,32,32,32,92,47,10

    missileLength equ $ - missile

    dash db 45
    newLine db 10

section .text
    global _start

_start:

    ; Print the first missile
    mov ecx, missile
    mov edx, missileLength
    call print_string

    ; Print repeated dash characters
    call print_separator

    ; Print the second missile
    mov ecx, missile
    mov edx, missileLength
    call print_string

    ; Exit the program
    mov eax, 1
    xor ebx, ebx
    int 0x80


; Prints the ASCII artwork
print_string:
    mov eax, 4
    mov ebx, 1
    int 0x80
    ret


; Uses a loop to print 20 dash characters
print_separator:
    mov esi, 20

repeat_dash:
    mov eax, 4
    mov ebx, 1
    mov ecx, dash
    mov edx, 1
    int 0x80

    dec esi
    jnz repeat_dash

    ; Print a new line
    mov eax, 4
    mov ebx, 1
    mov ecx, newLine
    mov edx, 1
    int 0x80

    ret