.model small
.stack 100h

.data
    buff db 200h dup(?)
    in_file_name db 13 dup(?)
    in_file_handle dw ?
    out_file_name db 13 dup(?)
    out_file_handle dw ?
    error_file db "No file with such name: $"
    error_arg db "No arguments were provided", 0Ah, 24h
    endl db 0Dh,0Ah, 24h

.code

start:
    MOV dx, @data
    MOV ds, dx

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
        JE open_files
        CMP cx, 1
        JE open_files

        ;Not end of arg
        MOV [in_file_name + bx], al
        MOV [out_file_name + bx], al

        INC bx
    continue:
        INC si
    LOOP args

    JMP exit

err_arguments:
    MOV ah, 09h
    LEA dx, error_arg
    INT 21h

    JMP exit

open_files:
    PUSH cx

    MOV [out_file_name + bx - 4], "."
    MOV [out_file_name + bx - 3], "a"
    MOV [out_file_name + bx - 2], "s"
    MOV [out_file_name + bx - 1], "m"

    ; Opening in file
    MOV ax, 3d00h
    LEA dx, in_file_name
    INT 21h
    JC err_opening
    MOV [in_file_handle], ax

    ; Opening out file
    MOV ah, 3Ch
    MOV cx, 0
    LEA dx, out_file_name
    INT 21h
    MOV out_file_handle, ax

    CALL process_file

    ; Closing file
    MOV ah, 3Eh
    MOV dx, out_file_handle
    INT 21h

    ; Closing file
    MOV ah, 3Eh
    MOV dx, in_file_handle
    INT 21h

    POP cx
    MOV bx, 0

    JMP continue

err_opening:
    MOV ah, 09h
    LEA dx, error_file
    INT 21h

    MOV ah, 40h
    MOV cx, bx
    MOV bx, 01h
    LEA dx, in_file_name
    INT 21h

    MOV ah, 09h
    LEA dx, endl
    INT 21h

    MOV ax, 4c00h
    INT 21h

    JMP exit

process_file:
    RET

exit:
    MOV ax, 4c00h
    INT 21h
END start
