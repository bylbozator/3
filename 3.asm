.model small
.stack 100h
.data
.386
    ; Сообщения
    msgStart db "Program started. Enter an expression:$"
    msgResult db 0Dh, 0Ah, "Result: $"
    msgError db 0Dh, 0Ah, "Error: Invalid input or operation.$"
    debugStep db 0Dh, 0Ah, "Debug: Step - $"
    buffer db 200 dup(0) ; Буфер для ввода строки
    bufferMaxLen db 199  ; Максимальная длина строки (199 символов)
    result dw 0          ; Переменная для хранения результата
    operations db "+", "-", "*", "/", 0 ; Поддерживаемые операции
.code
start:
    ; Инициализация сегментов
    mov ax, @data
    mov ds, ax
    mov es, ax

    ; Инициализация буфера для чтения строки
    mov byte ptr [buffer], 199 ; Максимальная длина строки (199 символов)

    ; Вывод стартового сообщения
    lea dx, msgStart
    mov ah, 9
    int 21h

    ; Чтение строки из консоли
    lea dx, buffer
    mov ah, 0Ah
    int 21h

    ; Проверка на пустой ввод
    mov al, [buffer+1] ; Количество введённых символов
    cmp al, 0
    je handle_empty_input ; Если ничего не введено

    ; Переход к обработке строки
    lea si, buffer+2 ; Пропуск байтов с длиной строки и символом завершения ввода
    call ParseAndCalculate

    ; Проверка результата обработки
    cmp al, 0
    je continue_program

handle_error:
    ; Вывод сообщения об ошибке
    lea dx, msgError
    mov ah, 9
    int 21h
    jmp program_end

handle_empty_input:
    ; Обработка пустого ввода
    lea dx, msgError
    mov ah, 9
    int 21h
    jmp program_end

continue_program:
    ; Вывод результата
    lea dx, msgResult
    mov ah, 9
    int 21h
    mov ax, result
    call PrintNumber

program_end:
    ; Завершение программы
    mov ah, 4Ch
    int 21h
    

;----------------------------------------------------------
; Функция парсинга и вычислений
;----------------------------------------------------------
ParseAndCalculate proc
    mov ax, 0
    mov result, ax ; Обнуляем результат
    mov bl, 0      ; Флаг ошибки

    ; Чтение первого числа
    call ReadNumber
    jc parse_error ; Если ошибка чтения

    mov result, ax ; Сохраняем первое число

next_operation:
    ; Пропуск пробелов
    call SkipSpaces

    ; Проверка на конец строки
    mov al, [si]
    cmp al, 0
    je parse_done

    ; Определение операции
    lea di, operations
    mov cx, 4 ; Число операций
find_operation:
    lodsb
    cmp al, [si]
    je operation_found
    loop find_operation
    jc parse_error ; Если операция не найдена

operation_found:
    inc si ; Пропуск операции

    ; Чтение следующего числа
    call ReadNumber
    jc parse_error ; Если ошибка чтения

    ; Выполнение операции
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
    mov bl, 1 ; Установка флага ошибки
parse_done:
    mov al, bl ; Возврат флага ошибки
    ret
ParseAndCalculate endp

;----------------------------------------------------------
; Оверлейные функции
;----------------------------------------------------------

; Функция сложения
AddOverlay proc
    mov ax, result
    add ax, bx
    mov result, ax
    ret
AddOverlay endp

; Функция вычитания
SubOverlay proc
    mov ax, result
    sub ax, bx
    mov result, ax
    ret
SubOverlay endp

; Функция умножения
MulOverlay proc
    mov ax, result
    imul bx
    mov result, ax
    ret
MulOverlay endp

; Функция деления
DivOverlay proc
    mov ax, result
    cwd
    idiv bx
    mov result, ax
    ret
DivOverlay endp

;----------------------------------------------------------
; Вспомогательные функции
;----------------------------------------------------------

; Чтение числа
ReadNumber proc
    mov ax, 0
    xor bx, bx ; Сбрасываем регистр для результата
    call SkipSpaces

    ; Проверка на отрицательное число
    mov al, [si]
    cmp al, '-'
    jne check_digit
    inc si
    mov bl, 1 ; Отрицательное число

check_digit:
read_loop:
    mov al, [si]
    cmp al, '0'
    jb read_done ; Если не число
    cmp al, '9'
    ja read_done ; Если не число
    sub al, '0'
    mov ah, 0
    imul bx, bx, 10
    add bx, ax
    inc si
    jmp read_loop
read_done:
    ; Установка знака
    cmp bl, 1
    jne number_done
    neg bx

number_done:
    mov ax, bx ; Результат в ax
    ret
ReadNumber endp

; Пропуск пробелов
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

; Печать числа
PrintNumber proc
    cmp ax, 0
    jge print_positive
    ; Вывод знака для отрицательных чисел
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
