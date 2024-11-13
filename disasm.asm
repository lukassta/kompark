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

    CMP ah, 11000000b
    JNE skip1100
    JMP fh1100
skip1100:

    CMP ah, 11010000b
    JNE skip1101
    JMP fh1101
skip1101:

    CMP ah, 11110000b
    JNE skip1111
    JMP fh1111
skip1111:

unknown_instruction:
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
    JMP known_f000sr11x
not_PUSH3:

    CMP ah, 00000000b
    JNE not_POP3
    MOV [out_buff + di], "P"
    MOV [out_buff + di + 1], "O"
    MOV [out_buff + di + 2], "P"
    MOV [out_buff + di + 3], " "
    ADD di, 4
    JMP known_f000sr11x
not_POP3:

    JMP unknown_instruction
known_f000sr11x:

    MOV ah, [in_buff + bx]
    AND ah, 00011000b
    SHR ah, 3

    CALL get_sreg

    INC di

    JMP write_line
;=== END OF FIRST 000sr11x =================================================

;=== START OF FIRST 0000xxxx =================================================
fh0000:
    MOV al, [in_buff + bx]
    AND al, 00001100b

    CMP al, 00000000b
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

    CMP al, 00000100b
    JNE not_ADD3
    MOV [out_buff + di], "A"
    MOV [out_buff + di + 1], "D"
    MOV [out_buff + di + 2], "D"
    MOV [out_buff + di + 3], " "
    ADD di, 4

    MOV al, [in_buff + bx]
    AND al, 00000001b
    MOV flags, ah

    CALL get_imed_op

    JMP write_line
not_ADD3:

    CMP al, 00001000b
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

    CMP al, 00001100b
    JNE not_OR3
    MOV [out_buff + di], "O"
    MOV [out_buff + di + 1], "R"
    MOV [out_buff + di + 2], " "
    ADD di, 3

    MOV ah, [in_buff + bx]
    AND ah, 00000001b
    MOV flags, ah

    CALL get_imed_op

    JMP write_line
not_OR3:

    JMP unknown_instruction
;=== END OF FIRST 0000xxxx =================================================

;=== START OF FIRST 0001xxxx =================================================
fh0001:
    MOV al, [in_buff + bx]
    AND al, 00001100b

    CMP al, 00000000b
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

    CMP al, 00000100b
    JNE not_ADC3
    MOV [out_buff + di], "A"
    MOV [out_buff + di + 1], "D"
    MOV [out_buff + di + 2], "C"
    MOV [out_buff + di + 3], " "
    ADD di, 4

    MOV ah, [in_buff + bx]
    AND ah, 00000001b
    MOV flags, ah

    CALL get_acum

    MOV [out_buff + di + 2], ","
    MOV [out_buff + di + 3], " "
    ADD di, 2

    CALL get_imed_op

    JMP write_line
not_ADC3:

    CMP al, 00001000b
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

    CMP al, 00001100b
    JNE not_SBB3
    MOV [out_buff + di], "S"
    MOV [out_buff + di + 1], "B"
    MOV [out_buff + di + 2], "B"
    MOV [out_buff + di + 3], " "
    ADD di, 4

    MOV ah, [in_buff + bx]
    AND ah, 00000001b
    MOV flags, ah

    CALL get_acum

    MOV [out_buff + di + 2], ","
    MOV [out_buff + di + 3], " "
    ADD di, 2

    CALL get_imed_op

    JMP write_line
not_SBB3:

    JMP unknown_instruction
;=== END OF FIRST 0001xxxx =================================================

;=== START OF FIRST 0010xxxx =================================================
fh0010:
    MOV al, [in_buff + bx]
    AND al, 00001100b

    CMP al, 00000000b
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

    CMP al, 00001000b
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

    MOV al, [in_buff + bx]
    AND al, 00001110b

    CMP al, 00000100b
    JNE not_AND3
    MOV [out_buff + di], "A"
    MOV [out_buff + di + 1], "N"
    MOV [out_buff + di + 2], "D"
    MOV [out_buff + di + 3], " "
    ADD di, 4

    MOV ah, [in_buff + bx]
    AND ah, 00000001b
    MOV flags, ah

    CALL get_acum

    MOV [out_buff + di], ","
    INC di

    CALL get_imed_op

    JMP write_line
not_AND3:

    CMP al, 00000110b
    JNE not_DAA
    MOV [out_buff + di], "D"
    MOV [out_buff + di + 1], "A"
    MOV [out_buff + di + 2], "A"
    MOV [out_buff + di + 3], " "
    ADD di, 3

    JMP write_line
not_DAA:

    CMP al, 00001000b
    JNE not_SUB3
    MOV [out_buff + di], "S"
    MOV [out_buff + di + 1], "U"
    MOV [out_buff + di + 2], "B"
    MOV [out_buff + di + 3], " "
    ADD di, 4

    MOV ah, [in_buff + bx]
    AND ah, 00000001b
    MOV flags, ah

    CALL get_acum

    MOV [out_buff + di + 2], ","
    MOV [out_buff + di + 3], " "
    ADD di, 2

    CALL get_imed_op

    JMP write_line
not_SUB3:

    CMP al, 00001110b
    JNE not_DAS
    MOV [out_buff + di], "D"
    MOV [out_buff + di + 1], "A"
    MOV [out_buff + di + 2], "S"
    MOV [out_buff + di + 3], " "
    ADD di, 3

    JMP write_line
not_DAS:

    JMP unknown_instruction
;=== END OF FIRST 0010xxxx =================================================

;=== START OF FIRST 0011xxxx =================================================
fh0011:
    MOV al, [in_buff + bx]
    AND al, 00001100b

    CMP al, 00000000b
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

    CMP al, 00001000b
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

    MOV al, [in_buff + bx]
    AND al, 00001110b

    CMP al, 00000100b
    JNE not_XOR3
    MOV [out_buff + di], "X"
    MOV [out_buff + di + 1], "O"
    MOV [out_buff + di + 2], "R"
    MOV [out_buff + di + 3], " "
    ADD di, 4

    MOV ah, [in_buff + bx]
    AND ah, 00000001b
    MOV flags, ah

    CALL get_acum

    MOV [out_buff + di + 2], ","
    MOV [out_buff + di + 3], " "
    ADD di, 2

    CALL get_imed_op

    JMP write_line
not_XOR3:

    CMP al, 00000110b
    JNE not_AAA
    MOV [out_buff + di], "A"
    MOV [out_buff + di + 1], "A"
    MOV [out_buff + di + 2], "A"
    ADD di, 3

    JMP write_line
not_AAA:

    CMP al, 00001100b
    JNE not_CMP3
    MOV [out_buff + di], "C"
    MOV [out_buff + di + 1], "M"
    MOV [out_buff + di + 2], "P"
    MOV [out_buff + di + 3], " "
    ADD di, 4

    MOV ah, [in_buff + bx]
    AND ah, 00000001b
    MOV flags, ah

    CALL get_acum

    MOV [out_buff + di + 2], ","
    MOV [out_buff + di + 3], " "
    ADD di, 2

    CALL get_imed_op

    JMP write_line
not_CMP3:

    CMP al, 00001110b
    JNE not_AAS
    MOV [out_buff + di], "A"
    MOV [out_buff + di + 1], "A"
    MOV [out_buff + di + 2], "S"
    ADD di, 3

    JMP write_line
not_AAS:

    JMP unknown_instruction
;=== END OF FIRST 0011xxxx =================================================

;=== START OF FIRST 0100xxxx =================================================
fh0100:
    MOV al, [in_buff + bx]
    AND al, 00001000b

    CMP al, 00000000b
    JNE not_INC2
    MOV [out_buff + di], "I"
    MOV [out_buff + di + 1], "N"
    MOV [out_buff + di + 2], "C"
    ADD di, 3

    JMP known_fh0100
not_INC2:

    CMP al, 00001000b
    JNE not_DEC2
    MOV [out_buff + di], "D"
    MOV [out_buff + di + 1], "E"
    MOV [out_buff + di + 2], "C"
    ADD di, 3

    JMP known_fh0100
not_DEC2:

    JMP unknown_instruction

known_fh0100:
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
    MOV al, [in_buff + bx]
    AND al, 00001000b

    CMP al, 00000000b
    JNE not_PUSH2
    MOV [out_buff + di], "P"
    MOV [out_buff + di + 1], "U"
    MOV [out_buff + di + 2], "S"
    MOV [out_buff + di + 3], "H"
    ADD di, 4

    JMP known_fh0101
not_PUSH2:

    CMP al, 00001000b
    JNE not_POP2
    MOV [out_buff + di], "P"
    MOV [out_buff + di + 1], "O"
    MOV [out_buff + di + 2], "P"
    ADD di, 3
    JMP known_fh0101
not_POP2:

    JMP unknown_instruction

known_fh0101:
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
    MOV al, [in_buff + bx]
    AND al, 00001111b

    CMP al, 00000000b
    JNE not_JO
    MOV [out_buff + di], "J"
    MOV [out_buff + di + 1], "O"
    ADD di, 2

    JMP known_fh0111
not_JO:

    CMP al, 00000001b
    JNE not_JNO
    MOV [out_buff + di], "J"
    MOV [out_buff + di + 1], "N"
    MOV [out_buff + di + 2], "O"
    ADD di, 3

    JMP known_fh0111
not_JNO:

    CMP al, 00000010b
    JNE not_JB
    MOV [out_buff + di], "J"
    MOV [out_buff + di + 1], "B"
    ADD di, 2

    JMP known_fh0111
not_JB:

    CMP al, 00000011b
    JNE not_JAE
    MOV [out_buff + di], "J"
    MOV [out_buff + di + 1], "A"
    MOV [out_buff + di + 2], "E"
    ADD di, 3

    JMP known_fh0111
not_JAE:

    CMP al, 00000100b
    JNE not_JE
    MOV [out_buff + di], "J"
    MOV [out_buff + di + 1], "E"
    ADD di, 2

    JMP known_fh0111
not_JE:

    CMP al, 00000101b
    JNE not_JNE
    MOV [out_buff + di], "J"
    MOV [out_buff + di + 1], "N"
    MOV [out_buff + di + 2], "E"
    ADD di, 3

    JMP known_fh0111
not_JNE:

    CMP al, 00000110b
    JNE not_JBE
    MOV [out_buff + di], "J"
    MOV [out_buff + di + 1], "B"
    MOV [out_buff + di + 2], "E"
    ADD di, 3

    JMP known_fh0111
not_JBE:

    CMP al, 00000111b
    JNE not_JS
    MOV [out_buff + di], "J"
    MOV [out_buff + di + 1], "S"
    ADD di, 2

    JMP known_fh0111
not_JS:

    CMP al, 00001000b
    JNE not_JA
    MOV [out_buff + di], "J"
    MOV [out_buff + di + 1], "A"
    ADD di, 2

    JMP known_fh0111
not_JA:

    CMP al, 00001001b
    JNE not_JNS
    MOV [out_buff + di], "J"
    MOV [out_buff + di + 1], "N"
    MOV [out_buff + di + 2], "S"
    ADD di, 3

    JMP known_fh0111
not_JNS:

    CMP al, 00001010b
    JNE not_JP
    MOV [out_buff + di], "J"
    MOV [out_buff + di + 1], "P"
    ADD di, 2

    JMP known_fh0111
not_JP:

    CMP al, 00001011b
    JNE not_JNP
    MOV [out_buff + di], "J"
    MOV [out_buff + di + 1], "N"
    MOV [out_buff + di + 2], "P"
    ADD di, 3

    JMP known_fh0111
not_JNP:

    CMP al, 00001100b
    JNE not_JL
    MOV [out_buff + di], "J"
    MOV [out_buff + di + 1], "L"
    ADD di, 2

    JMP known_fh0111
not_JL:

    CMP al, 00001101b
    JNE not_JGE
    MOV [out_buff + di], "J"
    MOV [out_buff + di + 1], "G"
    MOV [out_buff + di + 2], "E"
    ADD di, 3

    JMP known_fh0111
not_JGE:

    CMP al, 00001110b
    JNE not_JLE
    MOV [out_buff + di], "J"
    MOV [out_buff + di + 1], "L"
    MOV [out_buff + di + 2], "E"
    ADD di, 3

    JMP known_fh0111
not_JLE:

    CMP al, 00001111b
    JNE not_JG
    MOV [out_buff + di], "J"
    MOV [out_buff + di + 1], "G"
    ADD di, 2

    JMP known_fh0111
not_JG:

    JMP unknown_instruction

known_fh0111:
    MOV [out_buff + di], " "
    INC di

    CALL get_jump_displacement

    JMP write_line
;=== END OF FIRST 0111xxxx =================================================

;=== START OF FIRST 1000xxxx =================================================
fh1000:
    MOV al, [in_buff + bx]
    AND al, 00001100b

    CMP al, 00000000b
    JNE not_100000sw
    JMP f100000sw
not_100000sw:

    CMP al, 00001000b
    JNE not_MOV1
    MOV [out_buff + di], "M"
    MOV [out_buff + di + 1], "O"
    MOV [out_buff + di + 2], "V"
    MOV [out_buff + di + 3], " "
    ADD di, 4

    MOV al, [in_buff + bx]
    AND al, 00000011b
    MOV flags, al

    JMP get_rm
not_MOV1:

    MOV al, [in_buff + bx]
    AND al, 00001110b

    CMP al, 00000100b
    JNE not_TEST1
    MOV [out_buff + di], "T"
    MOV [out_buff + di + 1], "E"
    MOV [out_buff + di + 2], "S"
    MOV [out_buff + di + 3], "T"
    MOV [out_buff + di + 4], " "
    ADD di, 5

    MOV al, [in_buff + bx]
    AND al, 00000001b
    MOV flags, al

    JMP get_rm
not_TEST1:

    CMP al, 00000110b
    JNE not_XCHG1
    MOV [out_buff + di], "X"
    MOV [out_buff + di + 1], "C"
    MOV [out_buff + di + 2], "H"
    MOV [out_buff + di + 3], "G"
    MOV [out_buff + di + 4], " "
    ADD di, 5

    MOV al, [in_buff + bx]
    AND al, 00000001b
    MOV flags, al

    JMP get_rm
not_XCHG1:

    MOV al, [in_buff + bx]
    AND al, 00001101b

    CMP al, 00001100b
    JNE not_MOV1
    MOV [out_buff + di], "M"
    MOV [out_buff + di + 1], "O"
    MOV [out_buff + di + 2], "V"
    MOV [out_buff + di + 3], " "
    ADD di, 4

    JMP write_line
not_MOV6:

    MOV al, [in_buff + bx]
    AND al, 00001111b

    CMP ah, 00001101b
    JNE not_LEA
    MOV [out_buff + di], "L"
    MOV [out_buff + di + 1], "E"
    MOV [out_buff + di + 2], "A"
    MOV [out_buff + di + 3], " "
    ADD di, 4

    MOV flags, 00000011b

    JMP get_rm
not_LEA:

    CMP al, 00001111b
    JNE not_POP1
    MOV [out_buff + di], "P"
    MOV [out_buff + di + 1], "O"
    MOV [out_buff + di + 2], "P"
    MOV [out_buff + di + 3], " "
    ADD di, 4

    MOV flags, 00000001b
    CALL get_single_rm

    JMP write_line
not_POP1:

    JMP unknown_instruction

f100000sw:
    MOV al, [in_buff + bx]
    AND al, 00000011b
    MOV flags, al

    CALL new_byte

    MOV al, [in_buff + bx]
    AND al, 00111000b

    CMP al, 00000000b
    JNE not_ADD2
    MOV [out_buff + di], "A"
    MOV [out_buff + di + 1], "D"
    MOV [out_buff + di + 2], "D"
    MOV [out_buff + di + 3], " "
    ADD di, 4

    JMP known_f100000sw
not_ADD2:

    CMP al, 00001000b
    JNE not_OR2
    MOV [out_buff + di], "O"
    MOV [out_buff + di + 1], "R"
    MOV [out_buff + di + 2], " "
    ADD di, 3

    JMP known_f100000sw
not_OR2:

    CMP al, 00010000b
    JNE not_ADC2
    MOV [out_buff + di], "A"
    MOV [out_buff + di + 1], "D"
    MOV [out_buff + di + 2], "C"
    MOV [out_buff + di + 3], " "
    ADD di, 4

    JMP known_f100000sw
not_ADC2:

    CMP al, 00011000b
    JNE not_SBB2
    MOV [out_buff + di], "S"
    MOV [out_buff + di + 1], "B"
    MOV [out_buff + di + 2], "B"
    MOV [out_buff + di + 3], " "
    ADD di, 4

    JMP known_f100000sw
not_SBB2:

    CMP al, 00100000b
    JNE not_AND2
    MOV [out_buff + di], "A"
    MOV [out_buff + di + 1], "N"
    MOV [out_buff + di + 2], "D"
    MOV [out_buff + di + 3], " "
    ADD di, 4

    JMP known_f100000sw
not_AND2:

    CMP al, 00101000b
    JNE not_SUB2
    MOV [out_buff + di], "S"
    MOV [out_buff + di + 1], "U"
    MOV [out_buff + di + 2], "B"
    MOV [out_buff + di + 3], " "
    ADD di, 4

    JMP known_f100000sw
not_SUB2:

    CMP al, 00110000b
    JNE not_XOR2
    MOV [out_buff + di], "X"
    MOV [out_buff + di + 1], "O"
    MOV [out_buff + di + 2], "R"
    MOV [out_buff + di + 3], " "
    ADD di, 4

    JMP known_f100000sw
not_XOR2:

    CMP al, 00111000b
    JNE not_CMP2
    MOV [out_buff + di], "C"
    MOV [out_buff + di + 1], "M"
    MOV [out_buff + di + 2], "P"
    MOV [out_buff + di + 3], " "
    ADD di, 4

    JMP known_f100000sw
not_CMP2:

    JMP unknown_instruction

known_f100000sw:
    CALL get_single_rm

    MOV [out_buff + di], ","
    MOV [out_buff + di + 1], " "
    ADD di, 2

    CALL get_imed_op
    JMP write_line
;=== END OF FIRST 1000xxxx =================================================

;=== START OF FIRST 1001xxxx =================================================
fh1001:
    MOV al, [in_buff + bx]
    AND al, 00001000b

    CMP al, 00000000b
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

    MOV al, [in_buff + bx]
    AND al, 00000001b
    MOV flags, al

    MOV al, [in_buff + bx]
    AND al, 00000111b

    JMP get_reg
not_XCHG2:

    MOV al, [in_buff + bx]
    AND al, 00001111b

    CMP al, 00001000b
    JNE not_CBW
    MOV [out_buff + di], "C"
    MOV [out_buff + di + 1], "B"
    MOV [out_buff + di + 2], "W"
    ADD di, 3
not_CBW:

    CMP al, 00001001b
    JNE not_CWD
    MOV [out_buff + di], "C"
    MOV [out_buff + di + 1], "W"
    MOV [out_buff + di + 2], "D"
    ADD di, 3
not_CWD:

    CMP al, 00001010b
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

    CMP al, 00001011b
    JNE not_WAIT
    MOV [out_buff + di], "W"
    MOV [out_buff + di + 1], "A"
    MOV [out_buff + di + 2], "I"
    MOV [out_buff + di + 3], "T"
    ADD di, 4
not_WAIT:

    CMP al, 00001100b
    JNE not_PUSHF
    MOV [out_buff + di], "P"
    MOV [out_buff + di + 1], "U"
    MOV [out_buff + di + 2], "S"
    MOV [out_buff + di + 3], "H"
    MOV [out_buff + di + 3], "F"
    ADD di, 5
not_PUSHF:

    CMP al, 00001101b
    JNE not_POPF
    MOV [out_buff + di], "P"
    MOV [out_buff + di + 1], "O"
    MOV [out_buff + di + 2], "P"
    MOV [out_buff + di + 3], "F"
    ADD di, 4
not_POPF:

    CMP al, 00001110b
    JNE not_SAHF
    MOV [out_buff + di], "S"
    MOV [out_buff + di + 1], "A"
    MOV [out_buff + di + 2], "H"
    MOV [out_buff + di + 3], "F"
    ADD di, 4
not_SAHF:

    CMP al, 00001111b
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
    MOV al, [in_buff + bx]
    AND al, 00001110b

    CMP al, 00000000b
    JNE not_MOV4
    MOV [out_buff + di], "M"
    MOV [out_buff + di + 1], "O"
    MOV [out_buff + di + 2], "V"
    MOV [out_buff + di + 3], " "
    ADD di, 4

    MOV al, [in_buff + bx]
    AND al, 00000001b
    MOV flags, al

    CALL get_acum

    MOV [out_buff + di], ","
    MOV [out_buff + di + 1], " "
    MOV [out_buff + di + 2], "["
    ADD di, 3

    CALL get_imed_op

    MOV [out_buff + di], "]"
    INC di

    JMP write_line
not_MOV4:

    CMP al, 00000010b
    JNE not_MOV5
    MOV [out_buff + di], "M"
    MOV [out_buff + di + 1], "O"
    MOV [out_buff + di + 2], "V"
    MOV [out_buff + di + 3], " "
    ADD di, 4

    MOV al, [in_buff + bx]
    AND al, 00000001b
    MOV flags, al

    MOV [out_buff + di], "["
    INC di

    CALL get_imed_op

    MOV [out_buff + di], "]"
    MOV [out_buff + di + 1], ","
    MOV [out_buff + di + 2], " "
    ADD di, 3

    CALL get_acum

    JMP write_line
not_MOV5:

    CMP al, 00000100b
    JNE not_MOVS
    MOV [out_buff + di], "M"
    MOV [out_buff + di + 1], "O"
    MOV [out_buff + di + 2], "V"
    MOV [out_buff + di + 3], "S"
    ADD di, 4
not_MOVS:

    CMP al, 00000110b
    JNE not_CMPS
    MOV [out_buff + di], "C"
    MOV [out_buff + di + 1], "M"
    MOV [out_buff + di + 2], "P"
    MOV [out_buff + di + 3], "S"
    ADD di, 4
not_CMPS:

    CMP al, 00001000b
    JNE not_TEST3
    MOV [out_buff + di], "T"
    MOV [out_buff + di + 1], "E"
    MOV [out_buff + di + 2], "S"
    MOV [out_buff + di + 3], "T"
    MOV [out_buff + di + 4], " "
    ADD di, 5

    MOV al, [in_buff + bx]
    AND al, 00000001b
    MOV flags, al

    CALL get_acum

    MOV [out_buff + di + 2], ","
    MOV [out_buff + di + 3], " "
    ADD di, 2

    CALL get_imed_op

    JMP write_line
not_TEST3:

    CMP al, 00001010b
    JNE not_STOS
    MOV [out_buff + di], "S"
    MOV [out_buff + di + 1], "T"
    MOV [out_buff + di + 2], "O"
    MOV [out_buff + di + 3], "S"
    ADD di, 4
not_STOS:

    CMP al, 00001100b
    JNE not_LODS
    MOV [out_buff + di], "L"
    MOV [out_buff + di + 1], "O"
    MOV [out_buff + di + 2], "D"
    MOV [out_buff + di + 3], "S"
    ADD di, 4
not_LODS:

    CMP al, 00001110b
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

    MOV al, [in_buff + bx]
    AND al, 00001000b
    SHR ah, 3
    MOV flags, al

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
    MOV al, [in_buff + bx]
    AND al, 00001110b

    CMP al, 00000110b
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

    MOV al, [in_buff + bx]
    AND al, 00001111b

    CMP al, 00000010b
    JNE not_RET2
    MOV [out_buff + di], "R"
    MOV [out_buff + di + 1], "E"
    MOV [out_buff + di + 2], "T"
    MOV [out_buff + di + 3], " "
    ADD di, 4

    MOV al, [in_buff + bx]
    AND al, 00000001b
    MOV flags, al

    CALL get_imed_op

    JMP write_line
not_RET2:

    CMP al, 00000011b
    JNE not_RET1
    MOV [out_buff + di], "R"
    MOV [out_buff + di + 1], "E"
    MOV [out_buff + di + 2], "T"
    MOV [out_buff + di + 3], " "
    ADD di, 4
    JMP write_line
not_RET1:

    CMP al, 00000100b
    JNE not_LES
    MOV [out_buff + di], "L"
    MOV [out_buff + di + 1], "E"
    MOV [out_buff + di + 2], "S"
    MOV [out_buff + di + 3], " "
    ADD di, 4

    MOV flags, 00000001b

    JMP get_rm
not_LES:

    CMP al, 00000101b
    JNE not_LDS
    MOV [out_buff + di], "L"
    MOV [out_buff + di + 1], "D"
    MOV [out_buff + di + 2], "S"
    MOV [out_buff + di + 3], " "
    ADD di, 4

    MOV flags, 00000001b

    JMP get_rm
not_LDS:

    CMP al, 00001010b
    JNE not_RET4
    MOV [out_buff + di], "R"
    MOV [out_buff + di + 1], "E"
    MOV [out_buff + di + 2], "T"
    MOV [out_buff + di + 3], " "
    ADD di, 4

    MOV al, [in_buff + bx]
    AND al, 00000001b
    MOV flags, al

    CALL get_imed_op

    JMP write_line
not_RET4:

    CMP al, 00001011b
    JNE not_RET3
    MOV [out_buff + di], "R"
    MOV [out_buff + di + 1], "E"
    MOV [out_buff + di + 2], "T"
    ADD di, 3
    JMP write_line
not_RET3:

    CMP al, 00001101b
    JNE not_INT
    MOV [out_buff + di], "I"
    MOV [out_buff + di + 1], "N"
    MOV [out_buff + di + 2], "T"
    MOV [out_buff + di + 3], " "
    ADD di, 4

    MOV flags, 00000000b
    CALL get_imed_op

    JMP write_line
not_INT:

    CMP al, 00001111b
    JNE not_IRET
    MOV [out_buff + di], "I"
    MOV [out_buff + di + 1], "R"
    MOV [out_buff + di + 2], "E"
    MOV [out_buff + di + 3], "T"
    ADD di, 4

    JMP write_line
not_IRET:

    JMP unknown_instruction
;=== END OF FIRST 1100xxxx =================================================

;=== START OF FIRST 1101xxxx =================================================
fh1101:
    MOV al, [in_buff + bx]
    AND al, 00001000b

    CMP al, 00001000b
    JNE not_ESC
    MOV [out_buff + di], "E"
    MOV [out_buff + di + 1], "S"
    MOV [out_buff + di + 2], "C"
    MOV [out_buff + di + 3], " "
    ADD di, 4

    MOV al, [in_buff + bx]
    AND al, 00000111b

    CALL get_displacement_byte

    CALL new_byte

    MOV al, [in_buff + bx]
    AND al, 00111000b
    SHR al, 3

    CALL get_displacement_byte

    MOV [out_buff + di], "h"
    MOV [out_buff + di + 1], ","
    MOV [out_buff + di + 2], " "
    ADD di, 3

    CALL get_single_rm

    JMP write_line
not_ESC:

    MOV al, [in_buff + bx]
    AND al, 00001111b

    CMP al, 00000100b
    JNE not_AAM
    MOV [out_buff + di], "A"
    MOV [out_buff + di + 1], "A"
    MOV [out_buff + di + 2], "M"
    ADD di, 3

    CALL new_byte

    JMP write_line
not_AAM:

    CMP al, 00000101b
    JNE not_AAD
    MOV [out_buff + di], "A"
    MOV [out_buff + di + 1], "A"
    MOV [out_buff + di + 2], "D"
    ADD di, 3

    CALL new_byte

    JMP write_line
not_AAD:

    CMP al, 00000111b
    JNE not_XLAT
    MOV [out_buff + di], "X"
    MOV [out_buff + di + 1], "L"
    MOV [out_buff + di + 2], "A"
    MOV [out_buff + di + 3], "T"
    ADD di, 4

    JMP write_line
not_XLAT:

    JMP unknown_instruction
;=== END OF FIRST 1101xxxx =================================================

;=== START OF FIRST 1110xxxx =================================================
fh1110:
    MOV al, [in_buff + bx]
    AND al, 00001110b

    CMP al, 00000100b
    JNE not_IN1
    MOV [out_buff + di], "I"
    MOV [out_buff + di + 1], "N"
    MOV [out_buff + di + 2], " "
    ADD di, 3

    MOV al, [in_buff + bx]
    AND al, 00000001b
    MOV flags, al

    CALL get_imed_op

    MOV [out_buff + di], ","
    INC di

    CALL get_acum

    JMP write_line
not_IN1:

    CMP al, 00000110b
    JNE not_OUT1
    MOV [out_buff + di], "O"
    MOV [out_buff + di + 1], "U"
    MOV [out_buff + di + 2], "T"
    MOV [out_buff + di + 2], " "
    ADD di, 4

    MOV al, [in_buff + bx]
    AND al, 00000001b
    MOV flags, al

    CALL get_imed_op

    MOV [out_buff + di], ","
    INC di

    CALL get_acum

    JMP write_line
not_OUT1:

    CMP al, 00001100b
    JNE not_IN2
    MOV [out_buff + di], "I"
    MOV [out_buff + di + 1], "N"
    MOV [out_buff + di + 2], " "
    MOV [out_buff + di + 3], "d"
    MOV [out_buff + di + 4], "x"
    MOV [out_buff + di + 5], ","
    ADD di, 6

    CALL get_acum

    JMP write_line
not_IN2:

    CMP al, 00001110b
    JNE not_OUT2
    MOV [out_buff + di], "O"
    MOV [out_buff + di + 1], "U"
    MOV [out_buff + di + 2], "T"
    MOV [out_buff + di + 3], " "
    MOV [out_buff + di + 4], "d"
    MOV [out_buff + di + 5], "x"
    MOV [out_buff + di + 6], ","
    ADD di, 7

    CALL get_acum

    JMP write_line
not_OUT2:

    MOV al, [in_buff + bx]
    AND al, 00001111b

    CMP al, 00000000b
    JNE not_LOOP
    MOV [out_buff + di], "L"
    MOV [out_buff + di + 1], "O"
    MOV [out_buff + di + 2], "O"
    MOV [out_buff + di + 3], "P"
    MOV [out_buff + di + 4], " "
    ADD di, 5

    CALL get_jump_displacement

    JMP write_line
not_LOOP:

    CMP al, 00000001b
    JNE not_LOOPE
    MOV [out_buff + di], "L"
    MOV [out_buff + di + 1], "O"
    MOV [out_buff + di + 2], "O"
    MOV [out_buff + di + 3], "P"
    MOV [out_buff + di + 4], "E"
    MOV [out_buff + di + 5], " "
    ADD di, 6

    CALL get_jump_displacement

    JMP write_line
not_LOOPE:

    CMP al, 00000010b
    JNE not_LOOPNE
    MOV [out_buff + di], "L"
    MOV [out_buff + di + 1], "O"
    MOV [out_buff + di + 2], "O"
    MOV [out_buff + di + 3], "P"
    MOV [out_buff + di + 4], "N"
    MOV [out_buff + di + 5], "E"
    MOV [out_buff + di + 6], " "
    ADD di, 7

    CALL get_jump_displacement

    JMP write_line
not_LOOPNE:

    CMP al, 00000011b
    JNE not_JCXZ
    MOV [out_buff + di], "J"
    MOV [out_buff + di + 1], "C"
    MOV [out_buff + di + 2], "X"
    MOV [out_buff + di + 3], "Z"
    MOV [out_buff + di + 4], " "
    ADD di, 5

    CALL get_jump_displacement

    JMP write_line
not_JCXZ:

    CMP al, 00001000b
    JNE not_CALL1
    MOV [out_buff + di], "C"
    MOV [out_buff + di + 1], "A"
    MOV [out_buff + di + 2], "L"
    MOV [out_buff + di + 3], "L"
    MOV [out_buff + di + 4], " "
    ADD di, 5

    MOV al, [in_buff + bx]
    CALL new_byte
    MOV ah, [in_buff + bx]

    CALL get_ax

    JMP write_line
not_CALL1:

    CMP al, 00001001b
    JNE not_JMP2
    MOV [out_buff + di], "J"
    MOV [out_buff + di + 1], "M"
    MOV [out_buff + di + 2], "P"
    MOV [out_buff + di + 3], " "
    ADD di, 4

    CALL get_jump_displacement

    JMP write_line
not_JMP2:

    CMP al, 00001010b
    JNE not_JMP4
    MOV [out_buff + di], "J"
    MOV [out_buff + di + 1], "M"
    MOV [out_buff + di + 2], "P"
    MOV [out_buff + di + 3], " "
    ADD di, 4

    CALL get_word
    CALL get_word

    JMP write_line
not_JMP4:

    CMP al, 00001011b
    JNE not_JMP1
    MOV [out_buff + di], "J"
    MOV [out_buff + di + 1], "M"
    MOV [out_buff + di + 2], "P"
    MOV [out_buff + di + 3], " "
    ADD di, 4

    CALL get_jump_displacement

    JMP write_line
not_JMP1:

    JMP unknown_instruction
;=== END OF FIRST 1110xxxx =================================================

;=== START OF FIRST 1111xxxx =================================================
fh1111:
    MOV al, [in_buff + bx]
    AND al, 00001110b

    PUSH bx
    INC bx
    MOV ah, [in_buff + bx]
    AND ah, 00111000b
    POP bx

    CMP al, 00000110b
    JNE not_1111011w
    JMP f1111011w
not_1111011w:

    CMP al, 00001110b
    JNE not_INC1
    CMP ah, 00000000b
    JNE not_INC1

    MOV [out_buff + di], "I"
    MOV [out_buff + di + 1], "N"
    MOV [out_buff + di + 2], "C"
    MOV [out_buff + di + 3], " "
    ADD di, 4

    MOV ah, [in_buff + bx]
    AND ah, 00000001b
    MOV flags, ah

    CALL new_byte
    CALL get_single_rm

    JMP write_line
not_INC1:

    CMP al, 00001110b
    JNE not_DEC1
    CMP ah, 00001000b
    JNE not_DEC1

    MOV [out_buff + di], "D"
    MOV [out_buff + di + 1], "E"
    MOV [out_buff + di + 2], "C"
    MOV [out_buff + di + 3], " "
    ADD di, 4

    MOV ah, [in_buff + bx]
    AND ah, 00000001b
    MOV flags, ah

    CALL new_byte
    CALL get_single_rm

    JMP write_line
not_DEC1:

    MOV al, [in_buff + bx]
    AND al, 00001111b

    CMP al, 00000000b
    JNE not_LOCK
    MOV [out_buff + di], "L"
    MOV [out_buff + di + 1], "O"
    MOV [out_buff + di + 2], "C"
    MOV [out_buff + di + 3], "K"
    ADD di, 4
not_LOCK:

    CMP al, 00000010b
    JNE not_REPNZ
    MOV [out_buff + di], "R"
    MOV [out_buff + di + 1], "E"
    MOV [out_buff + di + 2], "P"
    MOV [out_buff + di + 3], "N"
    MOV [out_buff + di + 4], "Z"
    ADD di, 5
not_REPNZ:

    CMP al, 00000011b
    JNE not_REP
    MOV [out_buff + di], "R"
    MOV [out_buff + di + 1], "E"
    MOV [out_buff + di + 2], "P"
    ADD di, 3
not_REP:

    CMP al, 00000100b
    JNE not_HLT
    MOV [out_buff + di], "H"
    MOV [out_buff + di + 1], "L"
    MOV [out_buff + di + 2], "T"
    ADD di, 3
not_HLT:

    CMP al, 00000101b
    JNE not_CMC
    MOV [out_buff + di], "C"
    MOV [out_buff + di + 1], "M"
    MOV [out_buff + di + 2], "C"
    ADD di, 3
not_CMC:

    CMP al, 00001000b
    JNE not_CLC
    MOV [out_buff + di], "C"
    MOV [out_buff + di + 1], "L"
    MOV [out_buff + di + 2], "C"
    ADD di, 3
not_CLC:

    CMP al, 00001001b
    JNE not_STC
    MOV [out_buff + di], "S"
    MOV [out_buff + di + 1], "T"
    MOV [out_buff + di + 2], "C"
    ADD di, 3
not_STC:

    CMP al, 00001010b
    JNE not_CLI
    MOV [out_buff + di], "C"
    MOV [out_buff + di + 1], "L"
    MOV [out_buff + di + 2], "I"
    ADD di, 3
not_CLI:

    CMP al, 00001011b
    JNE not_STI
    MOV [out_buff + di], "S"
    MOV [out_buff + di + 1], "T"
    MOV [out_buff + di + 2], "I"
    ADD di, 3
not_STI:

    CMP al, 00001100b
    JNE not_CLD
    MOV [out_buff + di], "C"
    MOV [out_buff + di + 1], "L"
    MOV [out_buff + di + 2], "D"
    ADD di, 3
not_CLD:

    CMP al, 00001101b
    JNE not_STD
    MOV [out_buff + di], "S"
    MOV [out_buff + di + 1], "T"
    MOV [out_buff + di + 2], "D"
    ADD di, 3
not_STD:

    CMP al, 00001111b
    JNE not_11111111
    CALL b11111111
not_11111111:

    JMP write_line

f1111011w:
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
    CALL get_word

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
    MOV [out_buff + di], "a"
    MOV [out_buff + di + 1], "l"
    ADD di, 2
not_acum_byte:

    CMP ah, 00000001b
    JNE not_acum_word
    MOV [out_buff + di], "a"
    MOV [out_buff + di + 1], "x"
    ADD di, 2
not_acum_word:

    RET

get_imed_op:
    CALL new_byte

    MOV ah, flags
    AND ah, 00000001b

    CMP ah, 00000001b
    JNE not_imed_op_word

    MOV ah, flags
    AND ah, 00000010b
    CMP ah, 00000010b
    JE imed_op_is_byte

    MOV al, [in_buff + bx]

    CALL new_byte

    MOV ah, [in_buff + bx]

    CALL get_ax
not_imed_op_word:

    CMP ah, 00000000b
    JNE not_imed_op_byte
imed_op_is_byte:
    MOV al, [in_buff + bx]

    CALL get_al
not_imed_op_byte:


    MOV [out_buff + di], "h"
    INC di

    RET

get_word:
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
    MOV cx, ax
    MOV al, [in_buff + bx]
    CBW
    ADD ax, cx
    POP cx

    CALL get_ax

    RET

get_jump_displacement_word:
    CALL new_byte

    MOV ax, instruction_byte_count
    ADD ax, bx
    INC ax

    PUSH cx
    XOR cx, cx
    MOV cl, [in_buff + bx]
    ADD ax, cx

    CALL new_byte

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
