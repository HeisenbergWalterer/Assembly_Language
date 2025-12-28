.MODEL SMALL
.STACK 100h

.DATA
    sum     DW 0
    newline DB 0Dh, 0Ah, '$'

.CODE
START:
    MOV AX, @DATA
    MOV DS, AX

    XOR AX, AX          ; ???
    MOV CX, 100         ; ?? 1..100
    MOV BX, 1

sum_loop:
    ADD AX, BX
    INC BX
    LOOP sum_loop

    MOV sum, AX         ; ?? 5050
    CALL PRINT_WORD

    MOV AX, 4C00h
    INT 21h

PRINT_WORD PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX

    MOV AX, sum
    MOV BX, 10
    XOR CX, CX          ; ??????

convert_loop:
    XOR DX, DX
    DIV BX              ; AX/BX -> ?? AX???? DX
    PUSH DX             ; ???????????
    INC CX
    CMP AX, 0
    JNE convert_loop

print_loop:
    POP DX
    ADD DL, '0'
    MOV AH, 02h
    INT 21h
    LOOP print_loop

    ; ??
    MOV AH, 09h
    LEA DX, newline
    INT 21h

    POP DX
    POP CX
    POP BX
    POP AX
    RET
PRINT_WORD ENDP

END START
