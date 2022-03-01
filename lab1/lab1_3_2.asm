; lab1_3exe.asm
.model small
.stack 100h
.code
start:
  mov ax,DGROUP    ;сегментный адрес строки message
  mov ds,ax
  mov dx,offset message
  mov ah,9
  int 21h
  mov dx,offset second_message
  int 21h
  mov ax,4C00h   ;системный вызов завершения программы для .exe
  int 21h
.data
message db "Hello World!",0Dh,0Ah,'$'
second_message db "Second line",0Dh,0Ah,'$'
end start
