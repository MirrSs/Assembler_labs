;1)ed  file s   ? 
;               1..N - number of file's string to cout
;               % - all file
;2)ed  file e   ?
;               1..N - number of file's string to change
LOCALS
.model small
.stack 100h
.data

    argc        dw  0
    
    par3        db  0, 7 dup(0)      ;-32768..32767
    num         dw  0
    par2        db  0


    filename    db  128 dup("$")
    filename_2  db  "temp.txt",0,"$"

    file_handle  dw  0
    file_handle2 dw  0
    buffer_0     db  0

    RequestString   db "Enter string :",0Dh,0Ah,'$'
    MaxSize         equ 200
    String          db MaxSize dup('$')
    BufferSize      dw 0
    sizeOfString    dw 0

    buf         db  0
    c_dx        dw  0
    c_cx        dw  0
    c_str       dw  0

    err_com     db  "Incorrect commands!$"
    ErrOverflow db  0Dh,0Ah,"Overflow!",0Dh,0Ah,'$'
    ErrInput    db  0Dh,0Ah,"Incorrect input!",0Dh,0Ah,'$'
    err_exist   db  0Dh,0Ah,"String with this number doesn't exist!",0Dh,0Ah,'$'
    
    end_str     db  3,"$"
    success     db  "File was changed!$"
    opened      db  "File has been opened$"
    temp        db  0,"$" 
    start_str   db  4,"$"
    endl        db  10,13,"$"
    len_0       db  0                                    
    symbol      db  1 dup("$")
    not_found   db  "File not found!$"    
    buffer_1    db  129
    len_1       db  0
    
.code
;-------------------
clear proc near
    mov ah,0
    mov al,3
    int 10h                                     ;clear screen
    mov ah,02                                   ;set cursor to left corner of screen
    mov dh,0
    mov dl,0
    int 10h
    ret
clear endp
;-------------------
cout macro str
    mov ah,09h
    lea dx,str
    int 21h       
endm
;-------------------
; преобразования строки в знаковое число
; на входе:
; ds:[si] - строка с числом
; ds:[di] - адрес числа
; на выходе
; ds:[di] - число
; CY - флаг переноса (при ошибке - установлен, иначе - сброшен)
StrToNum proc
    push    ax
    push    bx
    push    cx
    push    dx
    push    ds
    push    es
    push    si

    push    ds                  ; копирую ds в es для операций сравнения
    pop     es                  ; так как DS:SI , а ES:DI

    mov     cl, ds:[si]         ; копирую в CL кол-во символов в строке - цифр (и минус) в числе
    xor     ch, ch              ; обнуляю CH, получаю в CX длину строки

    inc     si                  ; перехожу к первому символу

    cmp     [si], byte ptr '-'  ; отрицательное ли число?
    jne     @@IsPositive        ; если нет, переходим к метке
    inc     si                  ; если да, переходим к первой цифре
    dec     cx                  ; уменьшаем счетчик символов строки

    @@IsPositive:
	jcxz    @@Error         ; переход, если CX=0, т.е. наша строка состоит из одного символа "-"

	mov     bx, 10          ; для определения разряда цифр
	xor     ax, ax          ; обнуляем AX - наше число

    @@Loop:
	mul     bx              ; умножаем AX на 10 ( dx:ax=ax*bx )
	mov     [di], ax        ; сохраняем младшие разряды
	cmp     dx, 0           ; проверяем, результат на переполнение
	jnz     @@ErrorOfw      ; если не нуль

	mov     al, [si]        ; Преобразуем следующий символ в число
	cmp     al, '0'
	jb      @@Error
	cmp     al, '9'
	ja      @@Error         ; если символ не цифра (al<0 && al>9)
	sub     al, '0'         ; преобразуем символ к цифре
	xor     ah, ah          ; избавляемся от лишнего мусора
	add     ax, [di]        ; прибавляем младшие разряды
	cmp 	ax, 32768
	jne	@@Notover
	dec	cx
	cmp	cx,0
	jne	@@Loop
	jmp	@@Con
	@@Notover:
	or 	ax, ax
	jc      @@ErrorOfw      ; если сумма больше 65535, то произошло переполнение
	inc     si              ; переходим к следующему символу
    loop    @@Loop
    @@Con:

	pop     si
	push    si
	cmp 	ax, 32768
	je	@@Notover2
	or      ax, ax
	js      @@ErrorOfw      ; если установлен флаг знака
	@@Notover2:
	cmp     [si+1], byte ptr '-'
	jne     @@Positive      ; если число положительное, то идем к метке
	neg     ax              ; иначе меняем знак
	or      ax, ax          ; устанавливаются необходимые флаги
	jns     @@ErrorOfw      ; если не установлен флаг знака, значит возникла какая-то ошибка
	jmp 	@@Positive2
    @@Positive:
	cmp 	ax, 32768
	je 	@@ErrorOfw
    @@Positive2:
	mov     [di], ax
	clc
	pop     si
        pop     es
        pop     ds
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret

    @@ErrorOfw:
        cout    ErrOverflow
        jmp @@Cont
    @@Error:
        cout    ErrInput
        
    @@Cont:
        xor     ax, ax
        mov     [di], ax
        stc
        pop     si
        pop     es
        pop     ds
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret    
StrToNum endp
;--------------------------
enterSrtring proc
    mov cx,1
    mov BufferSize,0
    xor si,si
entering:
    mov ah,01h
    int 21h
    cmp al,0Dh
    je endEnteringString
    mov bx[si],al
    inc si
    cmp si,(MaxSize-1)
    je endEnteringString
    inc cx
    inc BufferSize
    loop entering
    endEnteringString:
	ret
enterSrtring endp
;---------------------------------------------------------------------------------------------------------------------
start:   
    mov ax,@data
    mov ds,ax
    call clear    
    
    ;cout opened
    ;cout endl

    mov di,80h
    mov cl,byte ptr[es:di]
    cmp cl,1
    jg  @@next
    jmp exit
@@next:

    mov cx,-1
    mov di,81h
    

find_param:
    mov     al,' '
    repz    scasb
    dec     di
    push    di
    inc     word ptr[argc]
    mov     si,di

scan_params:
    mov     al, [es:di]
    cmp     al, 0Dh
    je      params_ended
    cmp     al, 20h
    je      @@next
    inc	    di
    jmp	    scan_params
@@next:
    ;dec     di
    mov     byte ptr[es:di],0
    ;mov     di, si
    inc     di
    jmp     find_param

params_ended:
    ;dec di

    mov byte ptr[es:di], 0

    cmp     word ptr[argc], 3
    jle     @@next
    cout    err_com
    jmp     exit
@@next:

    xor     cx, cx
    pop     si
    mov     di, offset par3+1
scan_3param:
    mov	    al,byte ptr[es:si]
    cmp     al, 0
    je      param_ended3
    mov     [di],al
    inc     si
    inc     di
    inc     ch
    jmp     scan_3param
param_ended3:
    mov     byte ptr[par3], ch

    pop     si
    mov     di, offset par2
scan_2param:
    mov	    al,byte ptr[es:si]

    cmp     al, 0
    je      param_ended2
    mov     [di],al
    inc     si
    inc     di
    jmp     scan_2param  
param_ended2:

    pop     si
    mov     di, offset filename
scan_param1:
    mov	    al,byte ptr[es:si]
    cmp     al, 0
    je      param_ended1
    mov     [di],al
    inc     si
    inc     di
    jmp     scan_param1
param_ended1:
    mov     byte ptr[di],0
    
    
    ;ПРОВЕРКА ТА ЛИ КОМАНДА+
    mov     ah, byte ptr[par2]
    cmp     ah, 's'
    je      @@SCAN
    cmp     ah, 'e'
    je      @@EDIT
    cout    err_com
    jmp     exit
@@EDIT: 
    jmp     EDIT

;sssssssssssssssssssssssssssssssssssssss    START    sssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssss
@@SCAN:  

    mov     si, offset par3
    mov     al, [si+1]
    cmp     al,   '%'
    je      @@allFile
    mov     di, offset num
    call    StrToNum
    ;ПРОВЕРКА ЧИСЛА, НА КОРРЕКТНОСТЬ+ 
    ;ДОБАВИТЬ В STR_TO_NUM +

    ; проверка на ошибку
    jnc     coutString
    ; если есть ошибка ввода - повторить ввод
    jmp     exit



;ВЫВОД ВСЕГО ФАЙЛА НА ЭКРАН+
@@allFile:

    ;-------------------------------------opening file-----------------------------
    mov     dx, offset filename
    mov     ah, 3dh                                  ;open existing file
    mov     al, 00000010b                            ;writing parameter
    int     21h
    jc      @@er1
    jmp     @@not_err
    @@er1:
    jmp     err_exit
@@not_err:
    mov     bx, ax
    ;-------------------------------------opening file-----------------------------
@@output_file:
    mov     ah, 3fh         ; будем читать из файла
    mov     cx, 1           ; 1 байт
    mov     dx, offset buf         ; в память buf
    int     21h         
    cmp     ax, cx          ; если достигнуть EoF или ошибка чтения
    jnz     @@close         ; то закрываем файл закрываем файл
    mov     dl, buf
    mov     ah, 2           ; выводим символ в dl
    int     21h             ; на стандартное устройство вывода
    jmp     @@output_file
@@close:                    ; закрываем файл, после чтения
    mov     ah, 3Eh
    int     21h
    jmp     exit

;ВЫВОД СТРОКИ НА ЭКРАН+
coutString:

    ;-------------------------------------opening file-----------------------------
    mov     dx, offset filename
    mov     ah, 3dh                                  ;open existing file
    mov     al, 00000010b                            ;writing parameter
    int     21h
    jc      @@er1
    jmp     @@not_err
    @@er1:
    jmp     err_exit
@@not_err:
    mov     bx, ax
    ;-------------------------------------opening file-----------------------------

@@new_line:

    mov     ah, 42h
    xor     cx, cx
    xor     dx, dx
    mov     al, 1
    int     21h
    mov     word ptr[c_dx], dx
    mov     word ptr[c_cx], ax

    mov     ax, word ptr[c_str]
    inc     ax
    mov     word ptr[c_str], ax
    cmp     ax, word ptr[num]
    je      @@output_line

@@read_line:
    mov     ah, 3fh             ; будем читать из файла
    mov     cx, 1               ; 1 байт
    mov     dx, offset buf      ; в память buf
    int     21h
    cmp     ax, cx              ; если достигнуть EoF или ошибка чтения
    jnz     @@not_exist         ; то закрываем файл закрываем файл
    mov     dl, buf
    cmp     dl, 0Ah
    jne     @@read_line
    jmp     @@new_line
@@not_exist:                    ; закрываем файл, после чтения


    ;СООБЩЕНИЕ О НЕСУЩЕСТВУЮЩЕЙ СТРОКЕ+
    cout    err_exist
    mov     ah, 3Eh
    int     21h
    jmp     exit

@@output_line:

    mov     ah, 42h
    mov     cx, word ptr[c_dx]
    mov     dx, word ptr[c_cx]
    xor     al, al
    int     21h


@@FOR:
    mov     ah, 3fh         ; будем читать из файла
    mov     cx, 1           ; 1 байт
    mov     dx, offset buf         ; в память buf
    int     21h         
    cmp     ax, cx          ; если достигнуть EoF или ошибка чтения
    jnz     @@close         ; то закрываем файл закрываем файл
    mov     dl, buf
    cmp     dl, 0Ah
    je      @@close
    mov     ah, 2           ; выводим символ в dl
    int     21h             ; на стандартное устройство вывода
    jmp     @@FOR
@@close:                    ; закрываем файл, после чтения
    mov     ah, 3Eh
    int     21h
    jmp     exit
;sssssssssssssssssssssssssssssssssssssss    END    sssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssss

;eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee    START    eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
EDIT:
    mov     si, offset par3
    mov     di, offset num
    call    StrToNum

    ; проверка на ошибку
    jnc     @@next
    jmp     exit
@@next:
;-------------------------------------opening file-----------------------------
    mov     dx, offset filename
    mov     ah, 3dh                                  ;open existing file
    mov     al, 00000010b                            ;writing parameter
    int     21h
    jc      @@er
    jmp     @@not_err2
    @@er:
    jmp     err_exit
@@not_err2:
    mov     word ptr[file_handle], ax
;-------------------------------------opening file------------------------------

;-------------------------------------creating file-----------------------------
    mov     dx, offset filename_2
    mov     ah, 5bh
    xor     cx, cx
    int     21h
    jc      @@er1
    jmp     @@not_err
    @@er1:
    jmp     err_exit
@@not_err:
    mov     word ptr[file_handle2], ax
;-------------------------------------creating file-----------------------------

   

@@new_line:
    mov     ax, word ptr[c_str]
    inc     ax
    mov     word ptr[c_str], ax
    cmp     ax, word ptr[num]
    je      @@read_line

@@read_and_write_line:
    mov     bx, word ptr[file_handle]
    mov     ah, 3fh             ; будем читать из файла
    mov     cx, 1               ; 1 байт
    mov     dx, offset buf      ; в память buf
    int     21h
    cmp     ax, cx              ; если достигнуть EoF или ошибка чтения
    jz      @@OK         ; то закрываем файл закрываем файл
    jmp     nfound
@@OK:

    mov     bx, word ptr[file_handle2]
    mov     ah, 40h             ; будем читать из файла
    mov     cx, 1               ; 1 байт
    mov     dx, offset buf      ; в память buf
    int     21h

    mov     dl, buf
    cmp     dl, 0Ah
    jne     @@read_and_write_line
    jmp     @@new_line

@@read_line:
    mov     bx, word ptr[file_handle]
    mov     ah, 3fh             ; будем читать из файла
    mov     cx, 1               ; 1 байт
    mov     dx, offset buf      ; в память buf
    int     21h
    cmp     ax, cx              ; если достигнуть EoF или ошибка чтения
    jnz     @@not_exist         ; то закрываем файл закрываем файл
    mov     dl, buf
    cmp     dl, 0Ah
    jne     @@read_line

@@not_exist:
    mov     ah, 42h
    xor     cx, cx
    xor     dx, dx
    mov     al, 1
    int     21h
    mov     word ptr[c_dx], dx
    mov     word ptr[c_cx], ax

@@enter_str:
    cout    RequestString
    lea     bx,    string
    call    enterSrtring
    ;cmp     BufferSize,0
    ;jne     stringExist
    ;cout    ErrorEmptyString
    ;jmp     @@enter_str
    ;stringExist:
    mov     ax, BufferSize
    mov     sizeOfString,   ax

    mov     di, offset  string
    mov     bx, word ptr[file_handle2]
    dec	    di
@@print_str:
    inc     di
    cmp     byte ptr[di],'$'
    je      @@print_end
    mov     ah, 40h
    mov     cx, 1
    mov     dx, di
    int     21h
    jmp     @@print_str

@@print_end:
    mov     byte ptr[buf], 0Dh
    mov     dx, offset buf
    mov     ah, 40h
    mov     cx, 1
    int     21h
    
    mov     byte ptr[buf], 0Ah
    mov     dx, offset buf
    mov     ah, 40h
    mov     cx, 1
    int     21h



    mov     bx, word ptr[file_handle]
    mov     ah, 42h
    mov     cx, word ptr[c_dx]
    mov     dx, word ptr[c_cx]
    mov     al, 0
    int     21h


@@read_and_write_line2:
    mov     bx, word ptr[file_handle]
    mov     ah, 3fh             ; будем читать из файла
    mov     cx, 1               ; 1 байт
    mov     dx, offset buf      ; в память buf
    int     21h
    cmp     ax, cx              ; если достигнуть EoF или ошибка чтения
    jnz     @@eofile         ; то закрываем файл закрываем файл
    mov     dl, buf

    mov     bx, word ptr[file_handle2]
    mov     ah, 40h             ; будем читать из файла
    mov     cx, 1               ; 1 байт
    mov     dx, offset buf      ; в память buf
    int     21h

    jmp     @@read_and_write_line2

@@eofile:                    
    cout    endl
    cout    success
    
    mov     bx, word ptr[file_handle]
    mov     ah, 3Eh
    int     21h
    mov     bx, word ptr[file_handle2]
    mov     ah, 3Eh
    int     21h

    mov     ah, 41h
    mov     dx, offset filename
    int     21h

    push    ds
    pop     es

    mov     ah, 56h
    lea     dx, filename_2
    lea     di, filename
    int     21h
    
    jmp     exit

nfound:
    cout    err_exist
    mov     bx, word ptr[file_handle2]
    mov     ah, 3Eh
    int     21h
    mov     ah, 41h
    mov     dx, offset filename_2
    int     21h
    jmp     exit
;eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee    END    eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee

err_exit:
    call    clear
    cout    endl
    cout    not_found 
       
exit:
    mov     ax, 4c00h
    int     21h

end start