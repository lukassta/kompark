.model small
.stack 100h

.data
    in_file_name db 13 dup(?)
    in_file_handle dw ?
    in_buff db 200h dup(?)
    load_size dw ?
    out_file_name db 13 dup(?)
    out_file_handle dw ?
    out_buff db 100 dup(" ")
    registers db "alcldlblahchdhbhaxcxdxbxspbpsidi"
    sregisters db "escsssds"

    ins_byte_num db ?
    instruction_byte_count dw 100h
    flags db 0; 0000 00s/dw

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
        MOV al, es:[si]

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

    DEC bx
    CALL get_instruction

    ; Closing output file
    MOV ah, 3Eh
    MOV dx, out_file_handle
    INT 21h

    ; Closing input file
    MOV ah, 3Eh
    MOV dx, in_file_handle
    INT 21h

    XOR bx, bx

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

new_byte:
    INC bx
    CALL load_buff
    CALL get_instruction_byte

    RET

load_buff:
    CMP bx, load_size
    JNE do_not_load

    CMP load_size, 200h
    JNE file_end

    ADD instruction_byte_count, bx

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
    ADD sp, 4
    RET

get_instruction:
    XOR di, di
    MOV ins_byte_num, 0

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

;=== START OF FIRST BYTE HIGHER =================================================
    CALL new_byte

    MOV ah, [in_buff + bx]
    AND ah, 11100110b

    CMP ah, 00000110b
    JNE skip000sr11x
    JMP f000sr11x
skip000sr11x:

    MOV ah, [in_buff + bx]
    AND ah, 11110000b

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

    CMP ah, 10110000b
    JNE skip1011
    JMP fh1011
skip1011:

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

    JMP write_line
;=== END OF FIRST BYTE HIGHER =================================================

;=== START OF FIRST 000sr11x =================================================
f000sr11x:
    CMP ah, 00000000b
    JNE not_PUSH3
    MOV [out_buff + di], "P"
    MOV [out_buff + di + 1], "U"
    MOV [out_buff + di + 2], "S"
    MOV [out_buff + di + 3], "H"
    MOV [out_buff + di + 4], " "
    ADD di, 5
not_PUSH3:

    CMP ah, 00000000b
    JNE not_POP3
    MOV [out_buff + di], "P"
    MOV [out_buff + di + 1], "O"
    MOV [out_buff + di + 2], "P"
    MOV [out_buff + di + 3], " "
    ADD di, 4
not_POP3:

    MOV ah, [in_buff + bx]
    AND ah, 00011000b
    SHR ah, 3

    CALL get_sreg

    INC di

    JMP write_line
;=== END OF FIRST 000sr11x =================================================

;=== START OF FIRST 0000xxxx =================================================
fh0000:
    MOV ah, [in_buff + bx]
    AND ah, 00001100b

    CMP ah, 00000000b
    JNE not_ADD1
    MOV [out_buff + di], "A"
    MOV [out_buff + di + 1], "D"
    MOV [out_buff + di + 2], "D"
    MOV [out_buff + di + 3], " "
    ADD di, 4

    MOV ah, [in_buff + bx]
    AND ah, 00000011b
    MOV flags, ah

    JMP get_rm
not_ADD1:

    CMP ah, 00000100b
    JNE not_ADD3
    MOV [out_buff + di], "A"
    MOV [out_buff + di + 1], "D"
    MOV [out_buff + di + 2], "D"
    MOV [out_buff + di + 3], " "
    ADD di, 4

    MOV ah, [in_buff + bx]
    AND ah, 00000001b
    MOV flags, ah

    CALL get_imed_op

    MOV [out_buff + di], "h"
    INC di

    JMP write_line
not_ADD3:

    CMP ah, 00001000b
    JNE not_OR1
    MOV [out_buff + di], "O"
    MOV [out_buff + di + 1], "R"
    MOV [out_buff + di + 2], " "
    ADD di, 3

    MOV ah, [in_buff + bx]
    AND ah, 00000011b
    MOV flags, ah

    JMP get_rm
not_OR1:

    CMP ah, 00001100b
    JNE not_OR3
    MOV [out_buff + di], "O"
    MOV [out_buff + di + 1], "R"
    MOV [out_buff + di + 2], " "
    ADD di, 3

    MOV ah, [in_buff + bx]
    AND ah, 00000001b
    MOV flags, ah

    CALL get_imed_op

    MOV [out_buff + di], "h"
    INC di

    JMP write_line
not_OR3:

    JMP write_line
;=== END OF FIRST 0000xxxx =================================================

;=== START OF FIRST 0001xxxx =================================================
fh0001:
    MOV ah, [in_buff + bx]
    AND ah, 00001100b

    CMP ah, 00000000b
    JNE not_ADC1
    MOV [out_buff + di], "A"
    MOV [out_buff + di + 1], "D"
    MOV [out_buff + di + 2], "C"
    MOV [out_buff + di + 3], " "
    ADD di, 4

    MOV ah, [in_buff + bx]
    AND ah, 00000011b
    MOV flags, ah

    JMP get_rm
not_ADC1:

    CMP ah, 00000100b
    JNE not_ADC3
    MOV [out_buff + di], "A"
    MOV [out_buff + di + 1], "D"
    MOV [out_buff + di + 2], "C"
    MOV [out_buff + di + 3], " "
    ADD di, 4

    MOV ah, [in_buff + bx]
    AND ah, 00000001b
    MOV flags, ah

    CALL get_imed_op

    MOV [out_buff + di], "h"
    INC di

    JMP write_line
not_ADC3:

    CMP ah, 00001000b
    JNE not_SBB1
    MOV [out_buff + di], "S"
    MOV [out_buff + di + 1], "B"
    MOV [out_buff + di + 2], "B"
    MOV [out_buff + di + 3], " "
    ADD di, 4

    MOV ah, [in_buff + bx]
    AND ah, 00000011b
    MOV flags, ah

    JMP get_rm
not_SBB1:

    CMP ah, 00001100b
    JNE not_SBB3
    MOV [out_buff + di], "S"
    MOV [out_buff + di + 1], "B"
    MOV [out_buff + di + 2], "B"
    MOV [out_buff + di + 3], " "
    ADD di, 4

    MOV ah, [in_buff + bx]
    AND ah, 00000001b
    MOV flags, ah

    CALL get_imed_op

    MOV [out_buff + di], "h"
    INC di

    JMP write_line
not_SBB3:

    JMP write_line
;=== END OF FIRST 0001xxxx =================================================

;=== START OF FIRST 0010xxxx =================================================
fh0010:
    MOV ah, [in_buff + bx]
    AND ah, 00001100b

    CMP ah, 00000000b
    JNE not_AND1
    MOV [out_buff + di], "A"
    MOV [out_buff + di + 1], "N"
    MOV [out_buff + di + 2], "D"
    MOV [out_buff + di + 3], " "
    ADD di, 4

    MOV ah, [in_buff + bx]
    AND ah, 00000011b
    MOV flags, ah

    JMP get_rm
not_AND1:

    CMP ah, 00001000b
    JNE not_SUB1
    MOV [out_buff + di], "S"
    MOV [out_buff + di + 1], "U"
    MOV [out_buff + di + 2], "B"
    MOV [out_buff + di + 3], " "
    ADD di, 4

    MOV ah, [in_buff + bx]
    AND ah, 00000011b
    MOV flags, ah

    JMP get_rm
not_SUB1:

    MOV ah, [in_buff + bx]
    AND ah, 00001110b

    CMP ah, 00000100b
    JNE not_AND3
    MOV [out_buff + di], "A"
    MOV [out_buff + di + 1], "N"
    MOV [out_buff + di + 2], "D"
    MOV [out_buff + di + 3], " "
    ADD di, 4

    MOV ah, [in_buff + bx]
    AND ah, 00000001b
    MOV flags, ah

    CALL get_imed_op

    MOV [out_buff + di], "h"
    INC di

    JMP write_line
not_AND3:

    CMP ah, 00000110b
    JNE not_DAA
    MOV [out_buff + di], "D"
    MOV [out_buff + di + 1], "A"
    MOV [out_buff + di + 2], "A"
    MOV [out_buff + di + 3], " "
    ADD di, 3
not_DAA:

    CMP ah, 00001000b
    JNE not_SUB3
    MOV [out_buff + di], "S"
    MOV [out_buff + di + 1], "U"
    MOV [out_buff + di + 2], "B"
    MOV [out_buff + di + 3], " "
    ADD di, 4

    MOV ah, [in_buff + bx]
    AND ah, 00000001b
    MOV flags, ah

    CALL get_imed_op

    MOV [out_buff + di], "h"
    INC di

    JMP write_line
not_SUB3:

    CMP ah, 00001110b
    JNE not_DAS
    MOV [out_buff + di], "D"
    MOV [out_buff + di + 1], "A"
    MOV [out_buff + di + 2], "S"
    MOV [out_buff + di + 3], " "
    ADD di, 3
not_DAS:

    JMP write_line
;=== END OF FIRST 0010xxxx =================================================

;=== START OF FIRST 0011xxxx =================================================
fh0011:
    MOV ah, [in_buff + bx]
    AND ah, 00001100b

    CMP ah, 00000000b
    JNE not_XOR1
    MOV [out_buff + di], "X"
    MOV [out_buff + di + 1], "O"
    MOV [out_buff + di + 2], "R"
    MOV [out_buff + di + 3], " "
    ADD di, 4

    MOV ah, [in_buff + bx]
    AND ah, 00000011b
    MOV flags, ah

    JMP get_rm
not_XOR1:

    CMP ah, 00001000b
    JNE not_CMP1
    MOV [out_buff + di], "C"
    MOV [out_buff + di + 1], "M"
    MOV [out_buff + di + 2], "P"
    MOV [out_buff + di + 3], " "
    ADD di, 4

    MOV ah, [in_buff + bx]
    AND ah, 00000011b
    MOV flags, ah

    JMP get_rm
not_CMP1:

    MOV ah, [in_buff + bx]
    AND ah, 00001110b

    CMP ah, 00000100b
    JNE not_XOR3
    MOV [out_buff + di], "X"
    MOV [out_buff + di + 1], "O"
    MOV [out_buff + di + 2], "R"
    MOV [out_buff + di + 3], " "
    ADD di, 4

    MOV ah, [in_buff + bx]
    AND ah, 00000001b
    MOV flags, ah

    CALL get_imed_op

    MOV [out_buff + di], "h"
    INC di

    JMP write_line
not_XOR3:

    CMP ah, 00000110b
    JNE not_AAA
    MOV [out_buff + di], "A"
    MOV [out_buff + di + 1], "A"
    MOV [out_buff + di + 2], "A"
    MOV [out_buff + di + 3], " "
    ADD di, 3
not_AAA:

    CMP ah, 00001100b
    JNE not_CMP3
    MOV [out_buff + di], "C"
    MOV [out_buff + di + 1], "M"
    MOV [out_buff + di + 2], "P"
    MOV [out_buff + di + 3], " "
    ADD di, 4

    MOV ah, [in_buff + bx]
    AND ah, 00000001b
    MOV flags, ah

    CALL get_imed_op

    MOV [out_buff + di], "h"
    INC di

    JMP write_line
not_CMP3:

    CMP ah, 00001110b
    JNE not_AAS
    MOV [out_buff + di], "A"
    MOV [out_buff + di + 1], "A"
    MOV [out_buff + di + 2], "S"
    MOV [out_buff + di + 3], " "
    ADD di, 3
not_AAS:

    JMP write_line
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
    MOV flags, 00000001b

    CALL get_reg

    JMP write_line
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
    MOV flags, 00000001b

    CALL get_reg

    JMP write_line
;=== END OF FIRST 0101xxxx =================================================

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

    CALL get_jump_displacement

    JMP write_line
;=== END OF FIRST 0111xxxx =================================================

;=== START OF FIRST 1000xxxx =================================================
fh1000:
    MOV ah, [in_buff + bx]
    AND ah, 00001100b

    CMP ah, 00000000b
    JNE not_100000sw
    JMP f100000sw
not_100000sw:

    CMP ah, 00001000b
    JNE not_MOV1
    MOV [out_buff + di], "M"
    MOV [out_buff + di + 1], "O"
    MOV [out_buff + di + 2], "V"
    MOV [out_buff + di + 3], " "
    ADD di, 4

    MOV ah, [in_buff + bx]
    AND ah, 00000011b
    MOV flags, ah

    JMP get_rm
not_MOV1:

    MOV ah, [in_buff + bx]
    AND ah, 00001110b

    CMP ah, 00000100b
    JNE not_TEST1
    MOV [out_buff + di], "T"
    MOV [out_buff + di + 1], "E"
    MOV [out_buff + di + 2], "S"
    MOV [out_buff + di + 3], "T"
    MOV [out_buff + di + 4], " "
    ADD di, 5

    MOV ah, [in_buff + bx]
    AND ah, 00000001b
    MOV flags, ah

    JMP get_rm
not_TEST1:

    CMP ah, 00000110b
    JNE not_XCHG1
    MOV [out_buff + di], "X"
    MOV [out_buff + di + 1], "C"
    MOV [out_buff + di + 2], "H"
    MOV [out_buff + di + 3], "G"
    MOV [out_buff + di + 4], " "
    ADD di, 5

    MOV ah, [in_buff + bx]
    AND ah, 00000001b
    MOV flags, ah

    JMP get_rm
not_XCHG1:

    MOV ah, [in_buff + bx]
    AND ah, 00001101b

    CMP ah, 00001100b
    JNE not_MOV1
    MOV [out_buff + di], "M"
    MOV [out_buff + di + 1], "O"
    MOV [out_buff + di + 2], "V"
    MOV [out_buff + di + 3], " "
    ADD di, 4
not_MOV6:

    MOV ah, [in_buff + bx]
    AND ah, 00001111b

    CMP ah, 00001101b
    JNE not_LEA
    MOV [out_buff + di], "L"
    MOV [out_buff + di + 1], "E"
    MOV [out_buff + di + 2], "A"
    MOV [out_buff + di + 3], " "
    ADD di, 4

    MOV ah, 00000011b
    MOV flags, ah

    JMP get_rm
not_LEA:

    CMP ah, 00001111b
    JNE not_POP1
    MOV [out_buff + di], "P"
    MOV [out_buff + di + 1], "O"
    MOV [out_buff + di + 2], "P"
    MOV [out_buff + di + 3], " "
    ADD di, 4

    MOV flags, 00000001b
    CALL get_single_rm
not_POP1:

    JMP write_line

f100000sw:
    MOV ah, [in_buff + bx]
    AND ah, 00000011b
    MOV flags, ah

    CALL new_byte

    MOV ah, [in_buff + bx]
    AND ah, 00111000b

    CMP ah, 00000000b
    JNE not_ADD2
    MOV [out_buff + di], "A"
    MOV [out_buff + di + 1], "D"
    MOV [out_buff + di + 2], "D"
    MOV [out_buff + di + 3], " "
    ADD di, 4
not_ADD2:

    CMP ah, 00001000b
    JNE not_OR2
    MOV [out_buff + di], "O"
    MOV [out_buff + di + 1], "R"
    MOV [out_buff + di + 2], " "
    ADD di, 3
not_OR2:

    CMP ah, 00010000b
    JNE not_ADC2
    MOV [out_buff + di], "A"
    MOV [out_buff + di + 1], "D"
    MOV [out_buff + di + 2], "C"
    MOV [out_buff + di + 3], " "
    ADD di, 4
not_ADC2:

    CMP ah, 00011000b
    JNE not_SBB2
    MOV [out_buff + di], "S"
    MOV [out_buff + di + 1], "B"
    MOV [out_buff + di + 2], "B"
    MOV [out_buff + di + 3], " "
    ADD di, 4
not_SBB2:

    CMP ah, 00100000b
    JNE not_AND2
    MOV [out_buff + di], "A"
    MOV [out_buff + di + 1], "N"
    MOV [out_buff + di + 2], "D"
    MOV [out_buff + di + 3], " "
    ADD di, 4
not_AND2:

    CMP ah, 00101000b
    JNE not_SUB2
    MOV [out_buff + di], "S"
    MOV [out_buff + di + 1], "U"
    MOV [out_buff + di + 2], "B"
    MOV [out_buff + di + 3], " "
    ADD di, 4
not_SUB2:

    CMP ah, 00110000b
    JNE not_XOR2
    MOV [out_buff + di], "X"
    MOV [out_buff + di + 1], "O"
    MOV [out_buff + di + 2], "R"
    MOV [out_buff + di + 3], " "
    ADD di, 4
not_XOR2:

    CMP ah, 00111000b
    JNE not_CMP2
    MOV [out_buff + di], "C"
    MOV [out_buff + di + 1], "M"
    MOV [out_buff + di + 2], "P"
    MOV [out_buff + di + 3], " "
    ADD di, 4
not_CMP2:

    CALL get_single_rm

    MOV [out_buff + di], ","
    MOV [out_buff + di + 1], " "
    ADD di, 2

    CALL get_imed_op
    JMP write_line
;=== END OF FIRST 1000xxxx =================================================

;=== START OF FIRST 1001xxxx =================================================
fh1001:
    MOV ah, [in_buff + bx]
    AND ah, 00001000b

    CMP ah, 00000000b
    JNE not_XCHG2
    MOV [out_buff + di], "X"
    MOV [out_buff + di + 1], "C"
    MOV [out_buff + di + 2], "H"
    MOV [out_buff + di + 3], "G"
    MOV [out_buff + di + 4], " "
    MOV [out_buff + di + 5], "A"
    MOV [out_buff + di + 6], "X"
    MOV [out_buff + di + 7], ","
    ADD di, 8

    MOV ah, [in_buff + bx]
    AND ah, 00000001b
    MOV flags, ah

    MOV al, [in_buff + bx]
    AND al, 00000111b
    JMP get_reg
not_XCHG2:

    MOV ah, [in_buff + bx]
    AND ah, 00001111b

    CMP ah, 00001000b
    JNE not_CBW
    MOV [out_buff + di], "C"
    MOV [out_buff + di + 1], "B"
    MOV [out_buff + di + 2], "W"
    ADD di, 3
not_CBW:

    CMP ah, 00001001b
    JNE not_CWD
    MOV [out_buff + di], "C"
    MOV [out_buff + di + 1], "W"
    MOV [out_buff + di + 2], "D"
    ADD di, 3
not_CWD:

    CMP ah, 00001010b
    JNE not_CALL3
    MOV [out_buff + di], "C"
    MOV [out_buff + di + 1], "A"
    MOV [out_buff + di + 2], "L"
    MOV [out_buff + di + 3], "L"
    MOV [out_buff + di + 4], " "
    ADD di, 5

    MOV flags, 00000001b
    CALL get_imed_op
    CALL get_imed_op
    JMP write_line
not_CALL3:

    CMP ah, 00001011b
    JNE not_WAIT
    MOV [out_buff + di], "W"
    MOV [out_buff + di + 1], "A"
    MOV [out_buff + di + 2], "I"
    MOV [out_buff + di + 3], "T"
    ADD di, 4
not_WAIT:

    CMP ah, 00001100b
    JNE not_PUSHF
    MOV [out_buff + di], "P"
    MOV [out_buff + di + 1], "U"
    MOV [out_buff + di + 2], "S"
    MOV [out_buff + di + 3], "H"
    MOV [out_buff + di + 3], "F"
    ADD di, 5
not_PUSHF:

    CMP ah, 00001101b
    JNE not_POPF
    MOV [out_buff + di], "P"
    MOV [out_buff + di + 1], "O"
    MOV [out_buff + di + 2], "P"
    MOV [out_buff + di + 3], "F"
    ADD di, 4
not_POPF:

    CMP ah, 00001110b
    JNE not_SAHF
    MOV [out_buff + di], "S"
    MOV [out_buff + di + 1], "A"
    MOV [out_buff + di + 2], "H"
    MOV [out_buff + di + 3], "F"
    ADD di, 4
not_SAHF:

    CMP ah, 00001111b
    JNE not_LAHF
    MOV [out_buff + di], "L"
    MOV [out_buff + di + 1], "A"
    MOV [out_buff + di + 2], "H"
    MOV [out_buff + di + 3], "F"
    ADD di, 4
not_LAHF:

    JMP write_line
;=== END OF FIRST 1001xxxx =================================================

;=== START OF FIRST 1010xxxx =================================================
fh1010:
    MOV ah, [in_buff + bx]
    AND ah, 00001110b

    CMP ah, 00000000b
    JNE not_MOV4
    MOV [out_buff + di], "M"
    MOV [out_buff + di + 1], "O"
    MOV [out_buff + di + 2], "V"
    MOV [out_buff + di + 3], " "
    ADD di, 4

    MOV ah, [in_buff + bx]
    AND ah, 00000001b
    MOV flags, ah

    CALL get_acum

    MOV [out_buff + di], ","
    MOV [out_buff + di + 1], " "
    MOV [out_buff + di + 2], "["
    ADD di, 2

    CALL get_imed_op

    MOV [out_buff + di], "]"
    INC di

    JMP write_line
not_MOV4:

    CMP ah, 00000010b
    JNE not_MOV5
    MOV [out_buff + di], "M"
    MOV [out_buff + di + 1], "O"
    MOV [out_buff + di + 2], "V"
    MOV [out_buff + di + 3], " "
    ADD di, 4

    MOV ah, [in_buff + bx]
    AND ah, 00000001b
    MOV flags, ah

    MOV [out_buff + di], "["
    INC di

    CALL get_imed_op

    MOV [out_buff + di], "]"
    MOV [out_buff + di + 1], ","
    MOV [out_buff + di + 2], " "
    ADD di, 2

    CALL get_acum

    JMP write_line
not_MOV5:

    CMP ah, 00000100b
    JNE not_MOVS
    MOV [out_buff + di], "M"
    MOV [out_buff + di + 1], "O"
    MOV [out_buff + di + 2], "V"
    MOV [out_buff + di + 3], "S"
    ADD di, 4
not_MOVS:

    CMP ah, 00000110b
    JNE not_CMPS
    MOV [out_buff + di], "C"
    MOV [out_buff + di + 1], "M"
    MOV [out_buff + di + 2], "P"
    MOV [out_buff + di + 3], "S"
    ADD di, 4
not_CMPS:

    CMP ah, 00001000b
    JNE not_TEST3
    MOV [out_buff + di], "T"
    MOV [out_buff + di + 1], "E"
    MOV [out_buff + di + 2], "S"
    MOV [out_buff + di + 3], "T"
    MOV [out_buff + di + 4], " "
    ADD di, 5

    MOV ah, [in_buff + bx]
    AND ah, 00000001b
    MOV flags, ah

    CALL get_imed_op

    MOV [out_buff + di], "h"
    INC di

    JMP write_line
not_TEST3:

    CMP ah, 00001010b
    JNE not_STOS
    MOV [out_buff + di], "S"
    MOV [out_buff + di + 1], "T"
    MOV [out_buff + di + 2], "O"
    MOV [out_buff + di + 3], "S"
    ADD di, 4
not_STOS:

    CMP ah, 00001100b
    JNE not_LODS
    MOV [out_buff + di], "L"
    MOV [out_buff + di + 1], "O"
    MOV [out_buff + di + 2], "D"
    MOV [out_buff + di + 3], "S"
    ADD di, 4
not_LODS:

    CMP ah, 00001110b
    JNE not_SCAS
    MOV [out_buff + di], "S"
    MOV [out_buff + di + 1], "C"
    MOV [out_buff + di + 2], "A"
    MOV [out_buff + di + 3], "S"
    ADD di, 4
not_SCAS:

    JMP write_line
;=== END OF FIRST 1010xxxx =================================================

;=== START OF FIRST 1011xxxx =================================================
fh1011:
    ;MOV3
    MOV [out_buff + di], "M"
    MOV [out_buff + di + 1], "O"
    MOV [out_buff + di + 2], "V"
    MOV [out_buff + di + 3], " "
    ADD di, 4

    MOV ah, [in_buff + bx]
    AND ah, 00001000b
    SHR ah, 3
    MOV flags, ah

    MOV al, [in_buff + bx]
    AND al, 00000111b
    CALL get_reg

    MOV [out_buff + di], ","
    MOV [out_buff + di + 1], " "
    ADD di, 2

    CALL get_imed_op

    JMP write_line
;=== END OF FIRST 1011xxxx =================================================

;=== START OF FIRST 1100xxxx =================================================
fh1100:
    MOV ah, [in_buff + bx]
    AND ah, 00001110b

    CMP ah, 00000110b
    JNE not_MOV2
    MOV [out_buff + di], "M"
    MOV [out_buff + di + 1], "O"
    MOV [out_buff + di + 2], "V"
    MOV [out_buff + di + 3], " "
    ADD di, 4

    CALL get_single_rm

    MOV [out_buff + di], ","
    MOV [out_buff + di + 1], " "
    ADD di, 2

    CALL get_imed_op
    JMP write_line
not_MOV2:

    MOV ah, [in_buff + bx]
    AND ah, 00001111b

    CMP ah, 00000010b
    JNE not_RET2
    MOV [out_buff + di], "R"
    MOV [out_buff + di + 1], "E"
    MOV [out_buff + di + 2], "T"
    MOV [out_buff + di + 3], " "
    ADD di, 4

    MOV ah, [in_buff + bx]
    AND ah, 00000001b
    MOV flags, ah

    CALL get_imed_op

    MOV [out_buff + di], "h"
    INC di

    JMP write_line
not_RET2:

    CMP ah, 00000011b
    JNE not_RET1
    MOV [out_buff + di], "R"
    MOV [out_buff + di + 1], "E"
    MOV [out_buff + di + 2], "T"
    MOV [out_buff + di + 3], " "
    ADD di, 4
    JMP write_line
not_RET1:

    CMP ah, 00000100b
    JNE not_LES
    MOV [out_buff + di], "L"
    MOV [out_buff + di + 1], "E"
    MOV [out_buff + di + 2], "S"
    MOV [out_buff + di + 3], " "
    ADD di, 4

    MOV ah, 00000001b
    MOV flags, ah

    JMP get_rm
not_LES:

    CMP ah, 00000101b
    JNE not_LDS
    MOV [out_buff + di], "L"
    MOV [out_buff + di + 1], "D"
    MOV [out_buff + di + 2], "S"
    MOV [out_buff + di + 3], " "
    ADD di, 4

    MOV ah, 00000001b
    MOV flags, ah

    JMP get_rm
not_LDS:

    CMP ah, 00001010b
    JNE not_RET4
    MOV [out_buff + di], "R"
    MOV [out_buff + di + 1], "E"
    MOV [out_buff + di + 2], "T"
    MOV [out_buff + di + 3], " "
    ADD di, 4

    MOV ah, [in_buff + bx]
    AND ah, 00000001b
    MOV flags, ah

    CALL get_imed_op

    MOV [out_buff + di], "h"
    INC di

    JMP write_line
not_RET4:

    CMP ah, 00001011b
    JNE not_RET3
    MOV [out_buff + di], "R"
    MOV [out_buff + di + 1], "E"
    MOV [out_buff + di + 2], "T"
    MOV [out_buff + di + 3], " "
    ADD di, 4
    JMP write_line
not_RET3:

    JMP write_line
;=== END OF FIRST 1100xxxx =================================================

;=== START OF FIRST 1101xxxx =================================================
fh1101:
    MOV ah, [in_buff + bx]
    AND ah, 00001000b

    MOV [out_buff + di], "E"
    INC di

    JMP write_line
;=== END OF FIRST 1101xxxx =================================================

;=== START OF FIRST 1110xxxx =================================================
fh1110:
    MOV ah, [in_buff + bx]
    AND ah, 00001000b

    MOV [out_buff + di], "F"
    INC di

    JMP write_line
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

    JMP write_line
;=== END OF FIRST 1111xxxx =================================================

b11111111:
    CALL new_byte

    MOV ah, [in_buff + bx]
    AND ah, 00111000b

    RET

get_sreg:
    PUSH bx
    PUSH si

    AND al, 00000011b

    XOR ah, ah

    SHL al, 1

    MOV si, ax
    MOV bx, offset sregisters
    MOV al, [bx + si]
    MOV [out_buff + di], al
    MOV al, [bx + si + 1]
    MOV [out_buff + di + 1], al
    ADD di, 2

    POP si
    POP bx

    RET

get_reg:
    PUSH bx
    PUSH si

    AND al, 00000111b

    MOV ah, flags
    AND ah, 00000001b
    SHL ah, 3

    ADD al, ah

    XOR ah, ah

    SHL al, 1
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

get_single_rm:
    CALL get_rm_middle

    RET

get_rm:
    CALL new_byte

    MOV ah, flags
    AND ah, 00000010b; d flag
    MOV al, [in_buff + bx]

    PUSH ax
    CMP ah, 00000010b
    JNE not_rm_d1

    SHR al, 3
    AND al, 00000111b
    CALL get_reg

    MOV [out_buff + di], ","
    MOV [out_buff + di + 1], " "
    ADD di, 2
not_rm_d1:

    CALL get_rm_middle

    POP ax

    CMP ah, 00000000b
    JNE not_rm_d0

    MOV [out_buff + di], ","
    MOV [out_buff + di + 1], " "
    ADD di, 2

    SHR al, 3
    AND al, 00000111b
    CALL get_reg

not_rm_d0:

    JMP write_line

get_rm_middle:
    MOV ah, [in_buff + bx]
    AND ah, 11000000b

    MOV al, [in_buff + bx]
    AND al, 00000111b

    CMP ah, 11000000b
    JNE not_mod11
    CALL get_reg

    RET
not_mod11:

    MOV [out_buff + di], "["
    INC di

    CMP ah, 00000000b
    JNE not_address
    CMP al, 00000110b
    JNE not_address
    CALL get_imed_op_word

    MOV [out_buff + di], "]"
    INC di
    RET
not_address:

    CMP al, 00000000b
    JNE not_rm000
    MOV [out_buff + di], "B"
    MOV [out_buff + di + 1], "X"
    MOV [out_buff + di + 2], "+"
    MOV [out_buff + di + 3], "S"
    MOV [out_buff + di + 4], "I"
    ADD di, 5
not_rm000:

    CMP al, 00000001b
    JNE not_rm001
    MOV [out_buff + di], "B"
    MOV [out_buff + di + 1], "X"
    MOV [out_buff + di + 2], "+"
    MOV [out_buff + di + 3], "D"
    MOV [out_buff + di + 4], "I"
    ADD di, 5
not_rm001:

    CMP al, 00000010b
    JNE not_rm010
    MOV [out_buff + di], "B"
    MOV [out_buff + di + 1], "P"
    MOV [out_buff + di + 2], "+"
    MOV [out_buff + di + 3], "S"
    MOV [out_buff + di + 4], "I"
    ADD di, 5
not_rm010:

    CMP al, 00000011b
    JNE not_rm011
    MOV [out_buff + di], "B"
    MOV [out_buff + di + 1], "P"
    MOV [out_buff + di + 2], "+"
    MOV [out_buff + di + 3], "D"
    MOV [out_buff + di + 4], "I"
    ADD di, 5
not_rm011:


    CMP al, 00000100b
    JNE not_rm100
    MOV [out_buff + di], "S"
    MOV [out_buff + di + 1], "I"
    ADD di, 2
not_rm100:

    CMP al, 00000101b
    JNE not_rm101
    MOV [out_buff + di], "D"
    MOV [out_buff + di + 1], "I"
    ADD di, 2
not_rm101:

    CMP al, 00000110b
    JNE not_rm110
    MOV [out_buff + di], "B"
    MOV [out_buff + di + 1], "P"
    ADD di, 2
not_rm110:

    CMP al, 00000111b
    JNE not_rm111
    MOV [out_buff + di], "B"
    MOV [out_buff + di + 1], "X"
    ADD di, 2
not_rm111:

    CMP ah, 01000000b
    JNE not_mod01
    MOV al, [in_buff + bx]
    ;AND al, 00000111b
    ;CALL get_reg

    MOV [out_buff + di], "+"
    INC di

    CALL get_displacement_byte
not_mod01:

    CMP ah, 10000000b
    JNE not_mod10
    MOV al, [in_buff + bx]

    MOV [out_buff + di], "+"
    INC di

    CALL get_displacement_word
not_mod10:

    MOV [out_buff + di], "]"
    INC di
    RET

get_line_num:
    PUSH bx
    ADD bx, instruction_byte_count
    INC bx

    MOV al, bh
    SHR al, 4
    CALL get_hexadecimal

    MOV al, bh
    AND al, 0Fh
    CALL get_hexadecimal

    MOV al, bl
    SHR al, 4
    CALL get_hexadecimal

    MOV al, bl
    AND al, 0Fh
    CALL get_hexadecimal

    POP bx
    RET

get_acum:
    MOV ah, flags
    AND ah, 00000001b

    CMP ah, 00000000b
    JNE not_acum_byte
    MOV [out_buff + di], "A"
    MOV [out_buff + di + 1], "H"
    MOV [out_buff + di + 2], ","
    MOV [out_buff + di + 3], " "
    ADD di, 4
not_acum_byte:

    CMP ah, 00000001b
    JNE not_acum_word
    MOV [out_buff + di], "A"
    MOV [out_buff + di + 1], "X"
    MOV [out_buff + di + 2], ","
    MOV [out_buff + di + 3], " "
    ADD di, 4
not_acum_word:

    RET

get_imed_op:
    CALL new_byte

    MOV ah, flags
    AND ah, 00000001b

    CMP ah, 00000000b
    JNE not_imed_op_byte
    MOV al, [in_buff + bx]

    CALL get_al
not_imed_op_byte:

    CMP ah, 00000001b
    JNE not_imed_op_word
    MOV al, [in_buff + bx]

    CALL new_byte

    MOV ah, [in_buff + bx]

    CALL get_ax
not_imed_op_word:
    RET

get_imed_op_word:
    CALL new_byte

    MOV al, [in_buff + bx]

    CALL new_byte

    MOV ah, [in_buff + bx]

    CALL get_ax
    RET

get_displacement_byte:
    CALL new_byte

    MOV al, [in_buff + bx]

    CALL get_al

    RET

get_displacement_word:
    CALL new_byte

    MOV al, [in_buff + bx]

    CALL new_byte

    MOV ah, [in_buff + bx]

    CALL get_ax

    RET

get_jump_displacement:
    CALL new_byte

    MOV ax, instruction_byte_count
    ADD ax, bx
    INC ax

    PUSH cx
    XOR cx, cx
    MOV cl, [in_buff + bx]
    ADD ax, cx
    POP cx

    CALL get_ax

    RET

get_al:
    PUSH ax

    SHR al, 4
    CALL get_hexadecimal

    POP ax
    AND al, 00001111b
    CALL get_hexadecimal

    RET

get_ax:
    PUSH ax
    PUSH ax
    PUSH ax

    SHR ah, 4
    MOV al, ah
    CALL get_hexadecimal

    POP ax
    AND ah, 00001111b
    MOV al, ah
    CALL get_hexadecimal

    POP ax
    SHR al, 4
    CALL get_hexadecimal

    POP ax
    AND al, 00001111b
    CALL get_hexadecimal

    RET

get_hexadecimal:
    CMP al, 10
    JB is_num

    ADD al, 55; 'A' - 10
    MOV [out_buff + di], al
    JMP hexadecimal_return
is_num:
    ADD al, "0"
    MOV [out_buff + di], al

hexadecimal_return:
    INC di

    RET

get_instruction_byte:
    PUSH ax

    MOV al, [in_buff + bx]
    SHR al, 4
    CALL get_instruction_hexadecimal

    MOV al, [in_buff + bx]
    AND al, 0Fh
    CALL get_instruction_hexadecimal

    POP ax
    RET

get_instruction_hexadecimal:
    PUSH bx
    XOR bx, bx
    MOV bl, ins_byte_num

    CMP al, 10
    JB not_ins_byte_letter

    ADD al, 55; 'A' - 10
    MOV [out_buff + bx + 7], al
    JMP return_ins_byte
not_ins_byte_letter:

    ADD al, "0"
    MOV [out_buff + bx + 7], al

return_ins_byte:
    INC bx
    MOV ins_byte_num, bl

    POP bx

    RET

write_line:
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
