;Lab1_3
;выводит две строки символов
.model  tiny          ; модель памяти для СОМ
.code                 ; начало сегмента кода
org 100h              ; начальное значение IP = 100h
start:
    mov ah,9              ; номер функции DOS - в АН
    mov dx,offset message ; адрес строки - в DX
    int 21h               ; вызов системной функции DOS
    mov dx,offset second_message
    int 21h
    ret                   ; завершение СОМ-программы

message db "Hello World!",0Dh,0Ah,'$' ; строка для вывода
second_message db "Second string",0Dh,0Ah,'$'
end start
