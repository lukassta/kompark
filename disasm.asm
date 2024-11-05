.model small
.stack 100h

.data
    buff db 200h dup(?)
    file_name db 13 dup(?)
    file_handle dw ?
    out_file_name db "out.txt",0
    out_file_handle dw ?
    letter_count dw 26 dup(0)
    total_count dw 0
    error_file db "No file with such name: $"
    error_arg db "No arguments were provided", 0Ah, 24h
    endl db 0Dh,0Ah, 24h

.code

start:
    MOV dx, @data
    MOV ds, dx

    MOV ah, 3Ch
    MOV cx, 0
    MOV dx, offset out_file_name
    INT 21h
    MOV out_file_handle, ax

    XOR cx, cx
    MOV cl, es:[80h]

    CMP cx, 0
    JZ err_arguments

    MOV si, 0082h
    XOR bx, bx

    args:
        mov al, es:[si]

        ;End of arg
        CMP al, " "
        JE open_in_file
        CMP cx, 1
        JE open_in_file

        ;Not end of arg
        mov ds:[file_name + bx], al
        INC bx
    continue:
        INC si
    LOOP args

    CALL exit

err_arguments:
    MOV ah, 09h
    MOV dx, offset error_arg
    INT 21h

    CALL exit

err_opening:
    MOV ah, 09h
    MOV dx, offset error_file
    INT 21h

    MOV ah, 40h
    mov cx, bx
    mov bx, 01h
    MOV dx, offset file_name
    INT 21h

    MOV ah, 09h
    MOV dx, offset endl
    INT 21h

    MOV ax, 4c00h
    INT 21h

    CALL exit

open_in_file:
    PUSH cx

    mov ds:[file_name + bx], 0

    ; Opening file
    mov ah, 3Dh
    mov al, 00
    mov dx, offset file_name
    int 21h
    JC err_opening
    MOV [file_handle], ax

    call process_file

    ; Closing file
    mov ah, 3Eh
    mov dx, [file_handle]
    int 21h

    POP cx
    MOV bx, 0

    JMP continue

process_file:
    RET

exit:
    MOV ax, 4c00h
    INT 21h
END start
