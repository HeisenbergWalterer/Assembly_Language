.MODEL SMALL
.STACK 100h

.DATA
    header  DB 'The 9x9 table:',0Dh,0Ah,'$'
    newline DB 0Dh,0Ah,'$'

.CODE
START:
    MOV AX, @DATA
    MOV DS, AX

    ; 打印标题
    MOV AH, 09h
    LEA DX, header
    INT 21h

    MOV CL, 1              ; i = 1..9 (保存在 CL)

OUTER_LOOP:
    CMP CL, 10
    JGE DONE

    MOV CH, 1              ; j = 1..i (保存在 CH)
INNER_LOOP:
    CMP CH, CL
    JG  END_ROW

    ; 计算 CH x CL
    MOV DL, CH             ; j
    MOV BL, CL             ; i
    MOV AL, DL
    MUL BL                 ; AX = j * i
    CALL PRINT_ITEM

    INC CH
    JMP INNER_LOOP

END_ROW:
    MOV AH, 09h
    LEA DX, newline
    INT 21h
    INC CL
    JMP OUTER_LOOP

DONE:
    MOV AX, 4C00h
    INT 21h

; 输入：BL = i，DL = j，AX = 乘积
PRINT_ITEM PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX

    ; 打印 j
    MOV AH, 02h
    MOV AL, DL         ; j
    ADD AL, '0'
    MOV DL, AL
    INT 21h

    ; 打印 'x'
    MOV DL, 'x'
    INT 21h

    ; 打印 i
    MOV AL, BL
    ADD AL, '0'
    MOV DL, AL
    INT 21h

    ; 打印 '='
    MOV DL, '='
    INT 21h

    ; 重新计算乘积到 BX
    MOV BX, AX             ; BX = product (<= 81)

    ; 打印两位宽度
    MOV AX, BX
    MOV CL, 10
    XOR DX, DX
    DIV CL                 ; AL = 十位, AH = 个位
    CMP AL, 0
    JNE PRINT_TENS
    MOV DL, ' '
    INT 21h
    JMP PRINT_ONES

PRINT_TENS:
    ADD AL, '0'
    MOV DL, AL
    INT 21h

PRINT_ONES:
    ADD AH, '0'
    MOV DL, AH
    INT 21h

    ; ????
    MOV DL, ' '
    INT 21h
    MOV DL, ' '
    INT 21h

    POP DX
    POP CX
    POP BX
    POP AX
    RET
PRINT_ITEM ENDP

END START
