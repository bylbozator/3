.model small
.stack 100h
.data
.386
    ; ?????????
    msgStart db "Program started. Enter an expression:$"
    msgResult db 0Dh, 0Ah, "Result: $"
    msgError db 0Dh, 0Ah, "Error: Invalid input or operation.$"
    debugStep db 0Dh, 0Ah, "Debug: Step - $"
    buffer db 200 dup(0) ; ????? ??? ????? ??????
    bufferMaxLen db 199  ; ???????????? ????? ?????? (199 ????????)
    result dw 0          ; ?????????? ??? ???????? ??????????
    operations db "+", "-", "*", "/", 0 ; ?????????????? ????????
.code
start:
    ; ????????????? ?????????
    mov ax, @data
    mov ds, ax
    mov es, ax

    ; ????????????? ?????? ??? ?????? ??????
    mov byte ptr [buffer], 199 ; ???????????? ????? ?????? (199 ????????)

    ; ????? ?????????? ?????????
    lea dx, msgStart
    mov ah, 9
    int 21h

    ; ?????? ?????? ?? ???????
    lea dx, buffer
    mov ah, 0Ah
    int 21h

    ; ???????? ?? ?????? ????
    mov al, [buffer+1] ; ?????????? ????????? ????????
    cmp al, 0
    je handle_empty_input ; ???? ?????? ?? ???????

    ; ??????? ? ????????? ??????
    lea si, buffer+2 ; ??????? ?????? ? ?????? ?????? ? ???????? ?????????? ?????
    call ParseAndCalculate

    ; ???????? ?????????? ?????????
    cmp al, 0
    je continue_program

handle_error:
    ; ????? ????????? ?? ??????
    lea dx, msgError
    mov ah, 9
    int 21h
    jmp program_end

handle_empty_input:
    ; ????????? ??????? ?????
    lea dx, msgError
    mov ah, 9
    int 21h
    jmp program_end

continue_program:
    ; ????? ??????????
    lea dx, msgResult
    mov ah, 9
    int 21h
    mov ax, result
    call PrintNumber

program_end:
    ; ?????????? ?????????
    mov ah, 4Ch
    int 21h
    

;----------------------------------------------------------
; ??????? ???????? ? ??????????
;----------------------------------------------------------
ParseAndCalculate proc
    mov ax, 0
    mov result, ax ; ???????? ?????????
    mov bl, 0      ; ???? ??????

    ; ?????? ??????? ?????
    call ReadNumber
    jc parse_error ; ???? ?????? ??????

    mov result, ax ; ????????? ?????? ?????

next_operation:
    ; ??????? ????????
    call SkipSpaces

    ; ???????? ?? ????? ??????
    mov al, [si]
    cmp al, 0
    je parse_done

    ; ??????????? ????????
    lea di, operations
    mov cx, 4 ; ????? ????????
find_operation:
    lodsb
    cmp al, [si]
    je operation_found
    loop find_operation
    jc parse_error ; ???? ???????? ?? ???????

operation_found:
    inc si ; ??????? ????????

    ; ?????? ?????????? ?????
    call ReadNumber
    jc parse_error ; ???? ?????? ??????

    ; ?????????? ????????
    cmp al, '+'
    je AddOverlay
    cmp al, '-'
    je SubOverlay
    cmp al, '*'
    je MulOverlay
    cmp al, '/'
    je DivOverlay

    jmp next_operation

parse_error:
    mov bl, 1 ; ????????? ????? ??????
parse_done:
    mov al, bl ; ??????? ????? ??????
    ret
ParseAndCalculate endp

;----------------------------------------------------------
; ?????????? ???????
;----------------------------------------------------------

; ??????? ????????
AddOverlay proc
    mov ax, result
    add ax, bx
    mov result, ax
    ret
AddOverlay endp

; ??????? ?????????
SubOverlay proc
    mov ax, result
    sub ax, bx
    mov result, ax
    ret
SubOverlay endp

; ??????? ?????????
MulOverlay proc
    mov ax, result
    imul bx
    mov result, ax
    ret
MulOverlay endp

; ??????? ???????
DivOverlay proc
    mov ax, result
    cwd
    idiv bx
    mov result, ax
    ret
DivOverlay endp

;----------------------------------------------------------
; ??????????????? ???????
;----------------------------------------------------------

; ?????? ?????
ReadNumber proc
    mov ax, 0
    xor bx, bx ; ?????????? ??????? ??? ??????????
    call SkipSpaces

    ; ???????? ?? ????????????? ?????
    mov al, [si]
    cmp al, '-'
    jne check_digit
    inc si
    mov bl, 1 ; ????????????? ?????

check_digit:
read_loop:
    mov al, [si]
    cmp al, '0'
    jb read_done ; ???? ?? ?????
    cmp al, '9'
    ja read_done ; ???? ?? ?????
    sub al, '0'
    mov ah, 0
    imul bx, bx, 10
    add bx, ax
    inc si
    jmp read_loop
read_done:
    ; ????????? ?????
    cmp bl, 1
    jne number_done
    neg bx

number_done:
    mov ax, bx ; ????????? ? ax
    ret
ReadNumber endp

; ??????? ????????
SkipSpaces proc
    skip_loop:
        mov al, [si]
        cmp al, ' '
        jne skip_done
        inc si
        jmp skip_loop
    skip_done:
    ret
SkipSpaces endp

; ?????? ?????
PrintNumber proc
    cmp ax, 0
    jge print_positive
    ; ????? ????? ??? ????????????? ?????
    mov dl, '-'
    mov ah, 2
    int 21h
    neg ax

print_positive:
    mov bx, 10
    xor cx, cx
print_loop:
    xor dx, dx
    div bx
    push dx
    inc cx
    test ax, ax
    jnz print_loop
print_done:
    mov ah, 2
print_digit:
    pop dx
    add dl, '0'
    int 21h
    loop print_digit
    ret
PrintNumber endp

end start
