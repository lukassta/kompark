.model small
.stack 100h

.data
    in_buff db 200h dup(?)
    out_buff db 100 dup(" ")
    load_size dw ?
    in_file_name db 13 dup(?)
    in_file_handle dw ?
    out_file_name db 13 dup(?)
    out_file_handle dw ?
    registers db "alcldlblahchdhbhaxcxdxbxspbpsidi"
    error_file db "No file with such name: $"
    error_arg db "No arguments were provided", 0Ah, 24h
    endl db 0Dh,0Ah, 24h
    ins_byte_num db ? 

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
    MOV bx, in_file_handle
    LEA dx, in_buff
    MOV cx, 200h
    INT 21H
    MOV load_size, ax

    XOR bx, bx
    XOR si, si

    CALL get_instruction

    ; Closing output file
    MOV ah, 3Eh
    MOV dx, out_file_handle
    INT 21h

    ; Closing input file
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
    MOV ins_byte_num, 0

    CALL load_buff
    CALL get_line_num

    MOV [out_buff + di], ":"
    INC di

    PUSH cx
    MOV cx, 20
    get_space:
        MOV [out_buff + di], " "
        INC di
    LOOP get_space
    POP cx

    CALL get_instruction_byte

    MOV ah, [in_buff + bx]
    AND ah, 11110000b

;=== START OF FIRST BYTE HIGHER =================================================
    CMP ah, 00000000b
    JNE skip0000
    JMP fh0000
skip0000:

    CMP ah, 00010000b
    JNE skip0001
    JMP fh0001
skip0001:

    CMP ah, 00100000b
    JNE skip0010
    JMP fh0010
skip0010:

    CMP ah, 00110000b
    JNE skip0011
    JMP fh0011
skip0011:

    CMP ah, 01000000b
    JNE skip0100
    JMP fh0100
skip0100:

    CMP ah, 01010000b
    JNE skip0101
    JMP fh0101
skip0101:

    CMP ah, 01110000b
    JNE skip0111
    JMP fh0111
skip0111:

    CMP ah, 10000000b
    JNE skip1000
    JMP fh1000
skip1000:

    CMP ah, 10010000b
    JNE skip1001
    JMP fh1001
skip1001:

    CMP ah, 10100000b
    JNE skip1010
    JMP fh1010
skip1010:

    CMP ah, 11010000b
    JNE skip1101
    JMP fh1101
skip1101:

    CMP ah, 11110000b
    JNE skip1111
    JMP fh1111
skip1111:

    ; Instruction not fuond
    MOV [out_buff + di], "N"
    MOV [out_buff + di + 1], "o"
    MOV [out_buff + di + 2], "n"
    ADD di, 3

    INC SI
    inc BX
    JMP print_line
;=== END OF FIRST BYTE HIGHER =================================================

;=== START OF FIRST 0000xxxx =================================================
fh0000:
    MOV [out_buff + di], "0"
    INC di

    INC SI
    inc BX
    JMP print_line
;=== END OF FIRST 0000xxxx =================================================

;=== START OF FIRST 0001xxxx =================================================
fh0001:
    MOV [out_buff + di], "1"
    INC di

    INC SI
    inc BX
    JMP print_line
;=== END OF FIRST 0001xxxx =================================================

;=== START OF FIRST 0010xxxx =================================================
fh0010:
    MOV [out_buff + di], "2"
    INC di

    INC SI
    inc BX
    JMP print_line
;=== END OF FIRST 0010xxxx =================================================

;=== START OF FIRST 0011xxxx =================================================
fh0011:
    MOV [out_buff + di], "3"
    INC di

    INC SI
    inc BX
    JMP print_line
;=== END OF FIRST 0011xxxx =================================================

;=== START OF FIRST 0100xxxx =================================================
fh0100:
    MOV ah, [in_buff + bx]
    AND ah, 00001000b

    CMP ah, 00000000b
    JNE not_INC2
    MOV [out_buff + di], "I"
    MOV [out_buff + di + 1], "N"
    MOV [out_buff + di + 2], "C"
    ADD di, 3
not_INC2:

    CMP ah, 00001000b
    JNE not_DEC2
    MOV [out_buff + di], "D"
    MOV [out_buff + di + 1], "E"
    MOV [out_buff + di + 2], "C"
    ADD di, 3
not_DEC2:

    MOV [out_buff + di], " "
    INC di

    MOV al, [in_buff + bx]
    AND al, 00000111b
    OR al, 00001000b

    CALL get_register

    INC SI
    inc BX
    JMP print_line
;=== END OF FIRST 0100xxxx =================================================

;=== START OF FIRST 0101xxxx =================================================
fh0101:
    MOV ah, [in_buff + bx]
    AND ah, 00001000b

    CMP ah, 00000000b
    JNE not_PUSH2
    MOV [out_buff + di], "P"
    MOV [out_buff + di + 1], "U"
    MOV [out_buff + di + 2], "S"
    MOV [out_buff + di + 3], "H"
    ADD di, 4
not_PUSH2:

    CMP ah, 00001000b
    JNE not_POP2
    MOV [out_buff + di], "P"
    MOV [out_buff + di + 1], "O"
    MOV [out_buff + di + 2], "P"
    ADD di, 3
not_POP2:

    MOV [out_buff + di], " "
    INC di

    MOV al, [in_buff + bx]
    AND al, 00000111b
    OR al, 00001000b

    CALL get_register

    INC SI
    inc BX
    JMP print_line
;=== END OF FIRST 0101xxxx =================================================

;=== START OF FIRST 0110xxxx =================================================
fh0110:
    MOV [out_buff + di], "6"
    INC di

    INC SI
    inc BX
    JMP print_line
;=== END OF FIRST 0110xxxx =================================================

;=== START OF FIRST 0111xxxx =================================================
fh0111:
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

    INC si
    INC bx

    CALL get_instruction_byte
    CALL get_displacement

    JMP print_line
;=== END OF FIRST 0111xxxx =================================================

;=== START OF FIRST 1000xxxx =================================================
fh1000:
    MOV [out_buff + di], "9"
    INC di

    INC SI
    INC BX
    JMP print_line
;=== END OF FIRST 1000xxxx =================================================

;=== START OF FIRST 1001xxxx =================================================
fh1001:
    MOV [out_buff + di], "A"
    INC di

    INC SI
    inc BX
    JMP print_line
;=== END OF FIRST 1001xxxx =================================================

;=== START OF FIRST 1010xxxx =================================================
fh1010:
    MOV [out_buff + di], "B"
    INC di

    INC SI
    inc BX
    JMP print_line
;=== END OF FIRST 1010xxxx =================================================

;=== START OF FIRST 1011xxxx =================================================
fh1011:
    MOV [out_buff + di], "C"
    INC di

    INC SI
    inc BX
    JMP print_line
;=== END OF FIRST 1011xxxx =================================================

;=== START OF FIRST 1100xxxx =================================================
fh1100:
    MOV [out_buff + di], "D"
    INC di

    INC SI
    inc BX
    JMP print_line
;=== END OF FIRST 1100xxxx =================================================

;=== START OF FIRST 1101xxxx =================================================
fh1101:
    MOV [out_buff + di], "E"
    INC di

    INC SI
    inc BX
    JMP print_line
;=== END OF FIRST 1101xxxx =================================================

;=== START OF FIRST 1110xxxx =================================================
fh1110:
    MOV [out_buff + di], "F"
    INC di

    INC SI
    inc BX
    JMP print_line
;=== END OF FIRST 1110xxxx =================================================

;=== START OF FIRST 1111xxxx =================================================
fh1111:
    CMP ah, 00000000b
    JNE not_LOCK
    MOV [out_buff + di], "L"
    MOV [out_buff + di + 1], "O"
    MOV [out_buff + di + 2], "C"
    MOV [out_buff + di + 3], "K"
    ADD di, 4
not_LOCK:

    CMP ah, 00000010b
    JNE not_REPNZ
    MOV [out_buff + di], "R"
    MOV [out_buff + di + 1], "E"
    MOV [out_buff + di + 2], "P"
    MOV [out_buff + di + 3], "N"
    MOV [out_buff + di + 4], "Z"
    ADD di, 5
not_REPNZ:

    CMP ah, 00000011b
    JNE not_REP
    MOV [out_buff + di], "R"
    MOV [out_buff + di + 1], "E"
    MOV [out_buff + di + 2], "P"
    ADD di, 3
not_REP:

    CMP ah, 00000100b
    JNE not_HLT
    MOV [out_buff + di], "H"
    MOV [out_buff + di + 1], "L"
    MOV [out_buff + di + 2], "T"
    ADD di, 3
not_HLT:

    CMP ah, 00000101b
    JNE not_CMC
    MOV [out_buff + di], "C"
    MOV [out_buff + di + 1], "M"
    MOV [out_buff + di + 2], "C"
    ADD di, 3
not_CMC:

    CMP ah, 00001000b
    JNE not_CLC
    MOV [out_buff + di], "C"
    MOV [out_buff + di + 1], "L"
    MOV [out_buff + di + 2], "C"
    ADD di, 3
not_CLC:

    CMP ah, 00001001b
    JNE not_STC
    MOV [out_buff + di], "S"
    MOV [out_buff + di + 1], "T"
    MOV [out_buff + di + 2], "C"
    ADD di, 3
not_STC:

    CMP ah, 00001010b
    JNE not_CLI
    MOV [out_buff + di], "C"
    MOV [out_buff + di + 1], "L"
    MOV [out_buff + di + 2], "I"
    ADD di, 3
not_CLI:

    CMP ah, 00001011b
    JNE not_STI
    MOV [out_buff + di], "S"
    MOV [out_buff + di + 1], "T"
    MOV [out_buff + di + 2], "I"
    ADD di, 3
not_STI:

    CMP ah, 00001100b
    JNE not_CLD
    MOV [out_buff + di], "C"
    MOV [out_buff + di + 1], "L"
    MOV [out_buff + di + 2], "D"
    ADD di, 3
not_CLD:

    CMP ah, 00001101b
    JNE not_STD
    MOV [out_buff + di], "S"
    MOV [out_buff + di + 1], "T"
    MOV [out_buff + di + 2], "D"
    ADD di, 3
not_STD:

    CMP ah, 00001111b
    JNE not_11111111
    CALL b11111111
not_11111111:

    INC SI
    inc BX
    JMP print_line
;=== END OF FIRST 1111xxxx =================================================

b11111111:
    INC SI
    inc BX

    MOV ah, [in_buff + bx]
    AND ah, 00111000b

    RET

get_register:
    PUSH bx
    PUSH si

    XOR ah, ah
    SHL ax, 1
    MOV si, ax
    MOV bx, offset registers
    MOV al, [bx + si]
    MOV [out_buff + di], al
    MOV al, [bx + si + 1]
    MOV [out_buff + di + 1], al
    ADD di, 2

    POP si
    POP bx

    RET

get_displacement:
    MOV ah, [in_buff + bx]
    SHR ah, 4
    CALL get_hexadecimal

    MOV ah, [in_buff + bx]
    AND ah, 00001111b
    CALL get_hexadecimal

    INC si
    INC bx
    RET

get_instruction_byte:
    MOV al, [in_buff + bx]
    SHR al, 4
    CALL get_instruction_hexadecimal

    MOV al, [in_buff + bx]
    AND al, 0Fh
    CALL get_instruction_hexadecimal

    RET

get_instruction_hexadecimal:
    PUSH bx
    XOR bx, bx
    MOV bl, ins_byte_num

    CMP al, 10
    JB is_ins_byte_num

    ADD al, 55; 'A' - 10
    MOV [out_buff + bx + 7], al
    JMP return_ins_byte

is_ins_byte_num:
    ADD al, "0"
    MOV [out_buff + bx + 7], al

return_ins_byte:
    INC bx
    MOV ins_byte_num, bl

    POP bx

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

get_line_num:
    PUSH bx
    MOV bx, si

    MOV ah, bh
    SHR ah, 4
    CALL get_hexadecimal

    MOV ah, bh
    AND ah, 0Fh
    CALL get_hexadecimal

    MOV ah, bl
    SHR ah, 4
    CALL get_hexadecimal

    MOV ah, bl
    AND ah, 0Fh
    CALL get_hexadecimal

    POP bx
    RET

get_num:
    PUSH bx

    XOR dx, dx
    XOR cx, cx
    MOV si, 20
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
