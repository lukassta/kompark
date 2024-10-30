.model small
.stack 100h

.data
    GRAPH_SIZE dw 50
    buff db 255 dup(?)
    file_name db 255 dup(?)
    file_handle dw ?
    letter_count dw 26 dup(0)
    total_count dw 0
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
        JE open_file
        CMP cx, 1
        JE open_file

        ;Not end of arg
        mov ds:[file_name + bx], al
        INC bx
    continue:
        INC si
    LOOP args

    CALL print_statistics

    MOV ax, 4c00h
    INT 21h

err_arguments:
    MOV ah, 09h
    MOV dx, offset error_arg
    INT 21h

    MOV ax, 4c00h
    INT 21h

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

open_file:
    PUSH cx

    mov ds:[file_name + bx], 0

    ; Opening file
    mov ah, 3Dh
    mov al, 00
    mov dx, offset file_name
    int 21h
    JC err_opening
    MOV [file_handle], ax

    call count_letters

    ; Closing file
    mov ah, 3Eh
    mov dx, [file_handle]
    int 21h

    POP cx
    MOV bx, 0

    JMP continue

count_letters:
    PUSH si
    PUSH bx
    PUSH cx

    load_buff:
        MOV ah, 3Fh
        MOV bx, [file_handle]
        MOV dx, offset buff
        MOV cx, 255
        INT 21H

        PUSH ax

        MOV cx, ax
        XOR si, si
        for_character:
            XOR bx, bx
            MOV bl, [buff+si]
            AND bl, 11011111b; lowercase to uppercase

            CMP bl, "A"
            JB skip
            CMP bl, "Z"
            JA skip

            SUB bx, "A"
            ADD bx, bx
            ADD bx, offset letter_count

            MOV ax, [bx]
            INC ax
            MOV [bx], ax

            MOV bx, offset total_count
            MOV ax, [bx]
            INC ax
            MOV [bx], ax

            skip:
            INC si
            CMP si, cx
        JB for_character

        POP ax

        CMP al, 255
        JE load_buff

    POP cx
    POP bx
    POP si

    RET

print_statistics:
    MOV bx, offset total_count
    CALL print_num

    MOV ah, 09h
    MOV dx, offset endl
    INT 21h

    xor cx, cx
    MOV cl, 26
    letter:
        MOV ah, 02h
        MOV dl, "z"+1
        SUB dl, cl
        INT 21h

        MOV bx, offset letter_count
        ADD bx, 52
        SUB bx, cx
        SUB bx, cx

        MOV ah, 02h
        MOV dx, " "
        INT 21h
        PUSH cx
        CALL print_num
        CALL print_col
        POP cx

        MOV ah, 09h
        MOV dx, offset endl
        INT 21h
    LOOP letter
    RET

print_num:
    PUSH bx

    XOR dx, dx
    XOR cx, cx
    MOV si, 5
    ; dx:ax
    MOV ax, [bx]
    MOV bx, 10
get_dig:
    INC cx
    MOV dx, 0
    DIV bx

    PUSH dx

    CMP ax, 0
    JNE get_dig

    MOV ah, 02h
    print_dig:
        POP dx
        ADD dx, "0"
        INT 21h
        DEC si
    LOOP print_dig

    MOV cx, si
    print_fill:
        MOV dx, " "
        INT 21h
    LOOP print_fill

    POP bx
    RET

print_col:
    XOR dx, dx
    MOV ax, [bx]
    MOV bx, GRAPH_SIZE
    MUL bx

    DIV total_count
    MOV cx, ax
    PUSH ax
    MOV bx, ax

    CMP cx, 0
    JE skip_col_fill

    col_fill:
        MOV ah, 02h
        MOV dl, 219
        INT 21h
    LOOP col_fill
skip_col_fill:

    POP ax
    MOV cx, GRAPH_SIZE
    SUB cx, ax

    CMP cx, 0
    JE skip_col_empty

    col_empty:
        MOV ah, 02h
        MOV dl, 176 
        INT 21h
    LOOP col_empty
skip_col_empty:

    RET

END start

