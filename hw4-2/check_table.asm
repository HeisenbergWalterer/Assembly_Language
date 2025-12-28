.MODEL SMALL
.STACK 100h

.DATA
    header      DB 'The 9x9 table check:',0Dh,0Ah,'$'
    ok_msg      DB 0Dh,0Ah,'accomplish!',0Dh,0Ah,'$'
    newline     DB 0Dh,0Ah,'$'
    err_prefix  DB 0Dh,0Ah,'r=','$'
    mid_c       DB ' c=','$'
    mid_v       DB ' v=','$'
    mid_exp     DB ' exp=','$'

    ; 带错误的 9x9 数据表（逐行 9 个字节，共 81 个）
table DB 7,2,3,4,5,6,7,8,9
      DB 4,7,8,10,12,14,16,18,0
      DB 3,6,9,12,15,18,21,24,27
      DB 4,8,12,16,7,24,28,32,36
      DB 10,15,20,25,30,35,40,45,0
      DB 6,12,18,24,30,7,42,48,54
      DB 7,14,21,28,35,42,49,56,63
      DB 8,16,24,32,40,36,7,72,0
      DB 9,18,27,36,45,54,63,72,81

.CODE
START:
    MOV AX, @DATA
    MOV DS, AX

    ; 打印标题
    MOV AH, 09h
    LEA DX, header
    INT 21h

    ; i 用 CL，1..9；table 指针 SI
    LEA SI, table
    MOV CL, 1

ROW_LOOP:
    CMP CL, 10
    JGE DONE

    MOV BL, 1          ; 列 j
    MOV CH, 9          ; 每行 9 列计数

COL_LOOP:
    MOV DL, [SI]       ; 实际值

    ; 期望值 = i*j
    MOV AL, CL
    MUL BL             ; AX = i * j
    MOV DH, AL         ; 保存期望值
    CMP DL, DH
    JE  NEXT_COL

    ; 记录错误
    CALL PRINT_ERROR

NEXT_COL:
    INC SI
    INC BL
    DEC CH
    JNZ COL_LOOP

    INC CL
    JMP ROW_LOOP

DONE:
    MOV AH, 09h
    LEA DX, ok_msg
    INT 21h

    MOV AX, 4C00h
    INT 21h

; PRINT_ERROR: 使用 CL=i, BL=j, DL=actual, DH=expected
PRINT_ERROR PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX

    ; 换行 + "r=" + i
    MOV AH, 09h
    LEA DX, err_prefix
    INT 21h
    MOV AL, CL
    CALL PRINT_BYTE_DEC

    ; " c=" + j
    MOV AH, 09h
    LEA DX, mid_c
    INT 21h
    MOV AL, BL
    CALL PRINT_BYTE_DEC

    ; " v=" + actual
    MOV AH, 09h
    LEA DX, mid_v
    INT 21h
    MOV AL, DL
    CALL PRINT_BYTE_DEC

    ; " exp=" + expected
    MOV AH, 09h
    LEA DX, mid_exp
    INT 21h
    MOV AL, DH
    CALL PRINT_BYTE_DEC

    POP DX
    POP CX
    POP BX
    POP AX
    RET
PRINT_ERROR ENDP

; 输入 AL=数值(0..99)，输出两位(十位为0则空格)
PRINT_BYTE_DEC PROC
    PUSH AX
    PUSH BX
    PUSH DX
    MOV AH, 0
    MOV BL, 10
    DIV BL             ; AL=十位，AH=个位
    MOV DL, AL
    ADD DL, '0'
    CMP DL, '0'
    JNE PRINT_TENS
    MOV DL, ' '        ; 十位为 0 时输出空格
PRINT_TENS:
    MOV AH, 02h
    INT 21h
    MOV DL, AH
    ADD DL, '0'
    INT 21h
    POP DX
    POP BX
    POP AX
    RET
PRINT_BYTE_DEC ENDP

END START
