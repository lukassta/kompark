.model small
.stack 100h

.data
    endl db 0Dh,0Ah, 24h
    buff db 255 dup(?)

.code

start:
    mov dx,@data
    mov ds,dx

    xor cx,cx
    mov cl,es:[80h]

    cmp cx,0
    jz exit

    mov si,0081h

    xor bx,bx
l1:

    mov al,es:[si + bx]
    mov ds:[buff + bx],al

    inc bx
    loop l1


    mov ax,4000h
    mov bx,0001h
    xor cx,cx
    mov cl,es:[80h]
    mov dx,offset buff
    int 21h

exit:
    mov dx, offset endl
    mov ah, 09h
    int 21h


    mov ah, 4ch
    mov al, 0
    int 21h

end start


