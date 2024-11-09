.model small
.stack 100h

.data
    in_buff db 200h dup(?)
    out_buff db 100 dup(?)
    load_size dw ?
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
    PUSH si
    PUSH cx

    MOV [out_file_name + bx - 4], "."
    MOV [out_file_name + bx - 3], "t"
    MOV [out_file_name + bx - 2], "x"
    MOV [out_file_name + bx - 1], "t"

    ; Opening in file
    MOV ax, 3d00h
    LEA dx, in_file_name
    INT 21h
    JC err_opening
    MOV in_file_handle, ax

    ; Opening out file
    MOV ah, 3Ch
    MOV cx, 0
    LEA dx, out_file_name
    INT 21h
    MOV out_file_handle, ax

    ; First read of in file
    MOV ah, 3Fh
    MOV bx, [in_file_handle]
    LEA dx, in_buff
    MOV cx, 200h
    INT 21H
    MOV load_size, ax

    XOR bx, bx

    CALL get_instruction

    ; Closing file
    MOV ah, 3Eh
    MOV dx, out_file_handle
    INT 21h

    ; Closing file
    MOV ah, 3Eh
    MOV dx, in_file_handle
    INT 21h

    MOV bx, 0

    POP cx
    POP si

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

load_buff:
    CMP bx, load_size
    JNE do_not_load

    CMP load_size, 200h
    JNE file_end

    MOV ah, 3Fh
    MOV bx, [in_file_handle]
    LEA dx, in_buff
    MOV cx, 200h
    INT 21H
    MOV load_size, ax

    XOR bx, bx

do_not_load:
    RET
file_end:
    POP ax
    RET

get_instruction:
    XOR di, di

    CALL load_buff
    CALL get_num
    MOV ah, [in_buff + bx]
    AND ah, 11110000b

    CMP ah, 00000000b
    JNE skip0000
    JMP hb0000
skip0000:

    CMP ah, 00010000b
    JNE skip0001
    JMP hb0001
skip0001:

    CMP ah, 00100000b
    JNE skip0010
    JMP hb0010
skip0010:

    CMP ah, 00110000b
    JNE skip0011
    JMP hb0011
skip0011:

    CMP ah, 01000000b
    JNE skip0100
    JMP hb0100
skip0100:

    CMP ah, 01010000b
    JNE skip0101
    JMP hb0101
skip0101:

    CMP ah, 01110000b
    JNE skip0111
    JMP hb0111
skip0111:

    CMP ah, 10000000b
    JNE skip1000
    JMP hb1000
skip1000:

    CMP ah, 10010000b
    JNE skip1001
    JMP hb1001
skip1001:

    CMP ah, 10100000b
    JNE skip1010
    JMP hb1010
skip1010:

    CMP ah, 11010000b
    JNE skip1101
    JMP hb1101
skip1101:

    CMP ah, 11110000b
    JNE skip1111
    JMP hb1111
skip1111:

    MOV [out_buff + di], "N"
    MOV [out_buff + di + 1], "o"
    MOV [out_buff + di + 2], "n"
    ADD di, 3
    inc BX
    JMP print_line

hb0000:
    MOV [out_buff + di], "0"
    INC di

    inc BX
    JMP print_line

hb0001:
    MOV [out_buff + di], "1"
    INC di

    inc BX
    JMP print_line

hb0010:
    MOV [out_buff + di], "2"
    INC di

    inc BX
    JMP print_line

hb0011:
    MOV [out_buff + di], "3"
    INC di

    inc BX
    JMP print_line

hb0100:
    MOV [out_buff + di], "4"
    INC di

    inc BX
    JMP print_line

hb0101:
    MOV [out_buff + di], "5"
    INC di

    inc BX
    JMP print_line

hb0110:
    MOV [out_buff + di], "6"
    INC di

    inc BX
    JMP print_line

hb0111:
    MOV ah, [in_buff + bx]
    AND ah, 00001111b

    CMP ah, 00000000b
    JNE not_JO
    MOV [out_buff + di], "J"
    MOV [out_buff + di + 1], "O"
    ADD di, 2
not_JO:

    CMP ah, 00000001b
    JNE not_JNO
    MOV [out_buff + di], "J"
    MOV [out_buff + di + 1], "N"
    MOV [out_buff + di + 2], "O"
    ADD di, 3
not_JNO:

    CMP ah, 00000010b
    JNE not_JB
    MOV [out_buff + di], "J"
    MOV [out_buff + di + 1], "B"
    ADD di, 2
not_JB:

    CMP ah, 00000011b
    JNE not_JAE
    MOV [out_buff + di], "J"
    MOV [out_buff + di + 1], "A"
    MOV [out_buff + di + 2], "E"
    ADD di, 3
not_JAE:

    CMP ah, 00000100b
    JNE not_JE
    MOV [out_buff + di], "J"
    MOV [out_buff + di + 1], "E"
    ADD di, 2
not_JE:

    CMP ah, 00000101b
    JNE not_JNE
    MOV [out_buff + di], "J"
    MOV [out_buff + di + 1], "N"
    MOV [out_buff + di + 2], "E"
    ADD di, 3
not_JNE:

    CMP ah, 00000110b
    JNE not_JBE
    MOV [out_buff + di], "J"
    MOV [out_buff + di + 1], "B"
    MOV [out_buff + di + 2], "E"
    ADD di, 2
not_JBE:

    CMP ah, 00000111b
    JNE not_JS
    MOV [out_buff + di], "J"
    MOV [out_buff + di + 1], "S"
    ADD di, 2
not_JS:

    CMP ah, 00001000b
    JNE not_JA
    MOV [out_buff + di], "J"
    MOV [out_buff + di + 1], "A"
    ADD di, 2
not_JA:

    CMP ah, 00001001b
    JNE not_JNS
    MOV [out_buff + di], "J"
    MOV [out_buff + di + 1], "N"
    MOV [out_buff + di + 2], "S"
    ADD di, 3
not_JNS:

    CMP ah, 00001010b
    JNE not_JP
    MOV [out_buff + di], "J"
    MOV [out_buff + di + 1], "P"
    ADD di, 2
not_JP:

    CMP ah, 00001011b
    JNE not_JNP
    MOV [out_buff + di], "J"
    MOV [out_buff + di + 1], "N"
    MOV [out_buff + di + 2], "P"
    ADD di, 3
not_JNP:

    CMP ah, 00001100b
    JNE not_JL
    MOV [out_buff + di], "J"
    MOV [out_buff + di + 1], "L"
    ADD di, 2
not_JL:

    CMP ah, 00001101b
    JNE not_JGE
    MOV [out_buff + di], "J"
    MOV [out_buff + di + 1], "G"
    MOV [out_buff + di + 2], "E"
    ADD di, 2
not_JGE:

    CMP ah, 00001110b
    JNE not_JLE
    MOV [out_buff + di], "J"
    MOV [out_buff + di + 1], "L"
    MOV [out_buff + di + 2], "E"
    ADD di, 2
not_JLE:

    CMP ah, 00001111b
    JNE not_JG
    MOV [out_buff + di], "J"
    MOV [out_buff + di + 1], "G"
    ADD di, 2
not_JG:

    MOV [out_buff + di], " "
    INC di

    INC bx

    CALL get_displacement

    JMP print_line

hb1000:
    MOV [out_buff + di], "9"
    INC di

    inc BX
    JMP print_line

hb1001:
    MOV [out_buff + di], "A"
    INC di

    inc BX
    JMP print_line

hb1010:
    MOV [out_buff + di], "B"
    INC di

    inc BX
    JMP print_line

hb1011:
    MOV [out_buff + di], "C"
    INC di

    inc BX
    JMP print_line

hb1100:
    MOV [out_buff + di], "D"
    INC di

    inc BX
    JMP print_line

hb1101:
    MOV [out_buff + di], "E"
    INC di

    inc BX
    JMP print_line

hb1110:
    MOV [out_buff + di], "F"
    INC di

    inc BX
    JMP print_line

hb1111:
    MOV [out_buff + di], "G"
    INC di

    inc BX
    JMP print_line

get_displacement:
    MOV ah, [in_buff + bx]
    SHR ah, 4
    CALL get_hexadecimal

    MOV ah, [in_buff + bx]
    AND ah, 00001111b
    CALL get_hexadecimal

    INC bx
    RET

get_hexadecimal:
    CMP ah, 10
    JB is_num

    ADD ah, 55; 'A' - 10
    MOV [out_buff + di], ah
    JMP return

is_num:
    ADD ah, "0"
    MOV [out_buff + di], ah

return:
    INC di

    RET

get_num:
    PUSH bx

    XOR dx, dx
    XOR cx, cx
    MOV si, 5
    ; dx:ax
    MOV ax, bx
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
        DEC si

        MOV [out_buff + di], dl
        INC di
    LOOP print_dig

    MOV cx, si
    print_fill:
        MOV [out_buff + di], " "
        INC di
    LOOP print_fill

    POP bx
    RET

print_line:
    PUSH bx

    MOV [out_buff + di], 0Ah
    INC di

    MOV ah, 40h
    MOV bx, out_file_handle
    LEA dx, out_buff
    MOV cx, di
    INT 21h

    POP bx

    JMP get_instruction

exit:
    MOV ax, 4c00h
    INT 21h
END start
