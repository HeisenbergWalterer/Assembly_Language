; ----------------------------------------------
; 食物与随机数模块
; 作用：随机空位放置食物、加分与蛇体增长计数
; 随机算法：LCG X_{n+1} = (91*X_n + 7) mod (2^16-1)
; ----------------------------------------------
FOOD_CHAR equ 0x0703    ; 食物字符与颜色（小心心/小方块）
LAMDA equ 91
MOD equ 0xffff          ; 2^16-1
FOOD_SCORE equ 10       ; 每个食物加 10 分
section .text
    
CheckFood:
    ; 若当前无食物则生成新食物并更新分数与计数
    push ax
    call CheckFoodExist
    cmp ax, 1
    jz CheckFood.finish
    call SetNewFood
    add byte [food_num],1
    mov ax,FOOD_SCORE
    add word [score],ax
    call ShowScore
    CheckFood.finish:
    pop ax
    ret

SetNewFood:
    ; 不断生成随机 (y, x)，映射到显存偏移，验证空位后写入
    ; 设定了尝试次数上限，避免极端情况下的死循环
    push bp
    mov bp,sp

    push ax
    push dx
    push cx
    push bx

    mov cx,150
    SetNewFood.loop:
    push cx
    call Rand
    mov dx,0
    mov bx,BOX_HEIGH
    div bx
    mov ax,dx
    push ax

    mov cx,250
    SetNewFood.loop_y:
    call Rand
    mov dx,0
    mov bx,BOX_WIDTH-1
    div bx
    mov ax,dx
    push ax

    call GetLocValue
    mov word [food_loc],ax
    pop ax
    
    call CheckBlank
    cmp ax, 1
    jz SetNewFood.success
    loop SetNewFood.loop_y
    pop ax
    pop cx
    loop SetNewFood.loop

    jmp SetNewFood.fail

    SetNewFood.success:
    
    call SetFoodValue
    SetNewFood.fail:
    pop ax
    pop cx

    pop bx
    pop cx
    pop dx
    pop ax

    mov sp,bp
    pop bp
    ret


SetFoodValue:
    ; 将 FOOD_CHAR 写入 food_loc 处
    push ax
    mov ax, VIDEO_ADDRESS
    mov es,ax
    mov ax, word [food_loc]
    mov di, ax
    mov ax,FOOD_CHAR
    mov [es:di],ax
    pop ax
    ret

GetFoodValue:
    ; 读取 food_loc 处的显存内容
    mov ax, VIDEO_ADDRESS
    mov es,ax
    mov ax, word [food_loc]
    mov di, ax
    mov ax, [es:di]
    ret

CheckBlank:
    ; 判断当前位置是否为空白（背景字符）
    call GetFoodValue
    cmp ax, BLANK
    jz CheckBlank.blank
    mov ax, 0
    ret
    CheckBlank.blank:
    mov ax,1
    ret

CheckFoodExist:
    ; 判断当前位置是否为食物
    call GetFoodValue
    cmp ax, FOOD_CHAR
    jz CheckFoodExist.exist
    mov ax, 0
    ret
    CheckFoodExist.exist:
    mov ax,1
    ret

SetSeed:
    ; 使用系统时间初始化随机种子
    push dx
    push cx
    push ax
	mov ah,2ch
	int 21h
    mov ax,dx
    mov dx,0
    mov cx, LAMDA
    div cx
	mov word [seed], dx
    pop ax
    pop cx
    pop dx
	ret


Rand:
    ; LCG 产生新随机数并更新 seed
    push dx
    push cx
    mov ax, word [seed]
    mov dx, LAMDA
    mul dx
    add ax,7
    mov cx, MOD
    div cx
    mov ax,dx
    mov word [seed], dx
    pop cx
    pop dx
    ret

section .data
food_loc dw 0   ; 当前食物的显存偏移
seed dw 0       ; 随机种子