; ----------------------------------------------
; 蛇体与移动逻辑模块
; 数据结构：将蛇拆为若干线段节点（队列）
;   节点布局：loc dw, dir db, len db  （共 4 字节）
; 仅操作队首（头）与队尾（尾）以完成移动与增长
; ----------------------------------------------
SNAKE_COLOR equ 0x3000          ; 蛇身颜色（可调整）
SNAKE_INIT_LEN equ 4            ; 初始长度（单位：字符列宽的一半）
SNAKE_INIT_LOC equ (10*80+24)*2 ; 初始显存位置
SNAKE_NODE_SIZE equ 4
MEM_SIZE equ 7500               ; 环形缓冲总字节数（存节点队列）
MAX_RATE equ 40                 ; 进度上限，到达则触发一次 move
SPEED_UP equ 10                 ; 未使用（保留）
ENLONGATE_NUM equ 3             ; 吃满 N 个食物后额外增长一格

section .text
SnakeInit:
    ; 初始化蛇体：清空队列、创建首节点为向上、并在屏幕画出初始竖线
    push ax
    push cx
    push bx
    mov ax, VIDEO_ADDRESS
    mov es, ax
    mov ax, SNAKE_INIT_LOC
    mov di,ax
    call DeleteAllPtr
    call CreateSnakePtr
    mov [header_str],ax
    mov bx,ax
    mov cx, SNAKE_INIT_LOC

    mov word [bx], cx
    mov cl,UP_KEY
    mov byte [bx+2], cl
    mov cl, SNAKE_INIT_LEN
    mov byte [bx+3], cl
    mov cx, SNAKE_INIT_LEN
    SnakeInit.loop0:
        push cx
        push di
        mov cx,2

        SnakeInit.loop1:
            mov ax,SNAKE_COLOR
            mov word [es:di],ax
            add di,2
        loop SnakeInit.loop1

        pop di
        pop cx
        add di,160
    loop SnakeInit.loop0
    pop bx
    pop cx
    pop ax
    ret

; 通过取余方式判断方向
CalDirection:
    ; 根据 now_dir（玩家输入）与当前方向，判断是否左/右转
    ; 方向编码顺序：左(1) 上(2) 右(3) 下(4)，顺时针取余
    push dx
    push bx
    push cx
    mov ax,0
    mov al,byte [now_dir]
    cmp al,0
    jz CalDirection.finish
    mov ch,4
    mov cl,al

    mov bx,word [header_str]
    mov ah,0
    mov al,byte [bx+2]
    div ch
    add ah,1

    cmp ah,cl
    jz CalDirection.right

    mov ah,0
    mov al,byte [bx+2]
    add al,4
    sub al,2
    div ch
    add ah,1
    cmp ah,cl
    jz CalDirection.left

    mov ax,0
    jmp CalDirection.finish

    CalDirection.right:
    mov ax,RIGHT_KEY
    jmp CalDirection.finish

    CalDirection.left:
    mov ax,LEFT_KEY
    jmp CalDirection.finish

    CalDirection.finish:
    mov cl,0
    mov byte [now_dir],cl
    pop cx
    pop bx
    pop dx
    ret


CheckDirection:
    ; 若需要转向：在头部前插一个新节点（len=0，dir=转后方向）
    push ax
    push bx
    push si
    push dx

    call CalDirection
    cmp ax, 0
    jz CheckDirection.finish

    push ax
    ; 创建新节点
    call CreateSnakePtr
    mov bx,ax
    ; si:原节点
    mov ax,word [header_str]
    mov si,ax

    mov [header_str], bx

    mov ax,word [si]
    mov word [bx],ax
    ; newNode->dir=newNode->next->dir
    mov al,byte [si+2]
    mov byte [bx+2],al
    ; newNode->len=0
    mov al,0
    mov byte [bx+3],al
    

    pop ax

    cmp ax,LEFT_KEY
    jz CheckDirection.change_l

    cmp ax,RIGHT_KEY
    jz CheckDirection.change_r

    jmp CheckDirection.finish

    CheckDirection.change_l:
    call TurnLeft
    jmp CheckDirection.finish
    CheckDirection.change_r:
    call TurnRight
    jmp CheckDirection.finish

    CheckDirection.finish:
    pop dx
    pop si
    pop bx
    pop ax
    ret

Move:
    ; 一次完整移动：
    ; 1) 检查转向  2) 判断是否增长  3) 尾段收缩/删除  4) 头部前进
    ; 5) 检查食物（吃掉则加分并可能刷新食物）
    push ax
    push bx
    push cx
    call CheckDirection
    call Enlongate

    mov cx,[header_str]
    mov ax,cx
    mov bx,[queue_start]
    add bx,mem

    call SnakeEndMove
    mov cl, [bx+3]
    cmp cl, 0
    jnz Move.continue
    call DeleteSnakePtr

    Move.continue:

    call SnakeHeaderMove

    call CheckFood

    pop cx
    pop bx
    pop ax
    ret
CreateSnakePtr:
    ; 在环形缓冲中“申请”一个节点指针（移动 queue_end）
    push bx
    push cx
    push dx
    mov bx,word [queue_end]
    add bx, mem

    mov dx,0
    mov ax, SNAKE_NODE_SIZE
    add ax, word [queue_end]
    mov cx, MEM_SIZE
    div cx

    mov word [queue_end],dx
    mov ax,bx

    pop dx
    pop cx
    pop bx
    ret

DeleteSnakePtr:
    ; 释放队首节点（移动 queue_start）
    push ax
    push dx
    push cx
    mov dx,0
    mov ax,SNAKE_NODE_SIZE
    add ax, word [queue_start]
    mov cx,MEM_SIZE
    div cx
    mov word [queue_start],dx
    pop cx
    pop dx
    pop ax

    ret

DeleteAllPtr:
    ; 清空队列（start=end=0）
    push ax
    mov ax,0
    mov word [queue_end],ax
    mov word [queue_start],ax
    pop ax
    ret
SnakeHeaderMove:
    ; 头部节点向当前方向前进 1 格，并绘制蛇身方块
    ; 同时检测撞墙/撞身（读取下一格的显存字符比较）
    push bp
    mov bp,sp

    push ax
    push bx
    push cx

    mov bx,word [header_str]
    mov al, byte [bx+3]
    add al,1
    mov byte [bx+3],al

    mov al,byte [bx+2]

    cmp al,UP_KEY
    jz SnakeHeaderMove.up
    cmp al,DOWN_KEY
    jz SnakeHeaderMove.down
    cmp al,RIGHT_KEY
    jz SnakeHeaderMove.right
    cmp al,LEFT_KEY
    jz SnakeHeaderMove.left
    jmp SnakeHeaderMove.finish

    SnakeHeaderMove.up:
    mov ax,160
    mov cx,[bx]
    sub cx,ax
    mov ax,cx
    jmp SnakeHeaderMove.draw_square

    SnakeHeaderMove.down:
    mov ax,160
    add ax,[bx]
    jmp SnakeHeaderMove.draw_square

    SnakeHeaderMove.right:
    mov ax,4
    add ax,[bx]
    jmp SnakeHeaderMove.draw_square

    SnakeHeaderMove.left:
    mov ax,4
    mov cx,[bx]
    sub cx,ax
    mov ax,cx
    jmp SnakeHeaderMove.draw_square

    SnakeHeaderMove.draw_square:
    mov word [bx], ax

    push ax
    call CheckWall
    cmp ax,1
    jnz SnakeHeaderMove.no_hit
    call GameOver
    pop ax
    jmp SnakeHeaderMove.finish
    SnakeHeaderMove.no_hit:
    pop ax
    
    push ax
    push word SNAKE_COLOR
    call DrawSquare
    pop ax
    pop ax
    SnakeHeaderMove.finish:
    pop cx
    pop bx
    pop ax

    mov sp,bp
    pop bp
    ret

SnakeEndMove:
    ; 尾部节点长度减 1，并在正确位置绘制空白方块实现“擦除”
    push bp
    mov bp,sp

    push ax
    push bx
    push cx

    mov bx, [queue_start]
    add bx, mem
    ; 减去该段长度
    mov al, byte [bx+3]
    sub al, 1
    mov byte [bx+3],al

    mov al,byte [bx+2]
    cmp al,UP_KEY
    jz SnakeEndMove.up
    cmp al,DOWN_KEY
    jz SnakeEndMove.down
    cmp al,RIGHT_KEY
    jz SnakeEndMove.right
    cmp al,LEFT_KEY
    jz SnakeEndMove.left
    jmp SnakeEndMove.finish

    SnakeEndMove.up:
    mov al,160
    mul byte [bx+3]
    add ax,[bx]
    jmp SnakeEndMove.draw_blank

    SnakeEndMove.down:
    mov al,160
    mul byte [bx+3]
    mov cx,[bx]
    sub cx,ax
    mov ax,cx
    jmp SnakeEndMove.draw_blank

    SnakeEndMove.right:
    mov al,4
    mul byte [bx+3]
    mov cx,[bx]
    sub cx,ax
    mov ax,cx
    jmp SnakeEndMove.draw_blank

    SnakeEndMove.left:
    mov al,4
    mul byte [bx+3]
    add ax, [bx]
    jmp SnakeEndMove.draw_blank

    SnakeEndMove.draw_blank:
    push ax
    push word BLANK
    call DrawSquare
    pop ax
    pop ax
    SnakeEndMove.finish:
    pop cx
    pop bx
    pop ax

    mov sp,bp
    pop bp
    ret
TurnLeft:   
    ; dir = (dir-1-1) mod 4 + 1
    push ax
    push bx
    push cx

    
    mov bx,word [header_str]
    mov al,byte [bx+2]
    sub al,1
    mov ah,0
    add ax,4
    sub ax,1
    mov cl,4
    div cl
    add ah,1
    mov byte [bx+2],ah
    pop cx
    pop bx
    pop ax
    ret

TurnRight:
    ; dir = (dir-1+1) mod 4 + 1
    push ax
    push bx
    push cx
    mov bx,word [header_str]
    mov al,byte [bx+2]
    sub al,1
    mov ah,0
    add ax,1
    mov cl,4
    div cl
    add ah,1
    mov byte [bx+2],ah
    pop cx
    pop bx
    pop ax
    ret

CheckWall:
    ; 读取头部位置的显存字符，若为墙或蛇身则判定撞击
    push bx
    mov bx,word [header_str]
    mov di,word [bx]
    pop bx
    mov ax,VIDEO_ADDRESS
    mov es,ax
    mov ax,word [es:di]
    cmp ax,WALL_COLOR
    jz CheckWall.hit_wall
    cmp ax,SNAKE_COLOR
    jz CheckWall.hit_wall
    mov ax,0
    ret
    CheckWall.hit_wall:
    call GameOver
    mov ax,1
    ret
Enlongate:
    ; 每吃满 ENLONGATE_NUM 次，在本轮额外前进一步（实现增长）
    cmp word[food_num],ENLONGATE_NUM
    jb Enlongate.finish
    call SnakeHeaderMove
    mov word[food_num],0
    Enlongate.finish:
    ret

RealMove:
    ; 速率控制：rate += init_v + score/50，达到上限触发 Move
    push ax
    push dx
    push cx
    mov dx,0
    mov ax,word [score]
    mov cx,50
    div cx
    add ax,word [rate]
    add ax,word [init_v]
    mov word [rate],ax
    cmp ax, MAX_RATE
    jb RealMove.finish
    mov word[rate],0
    call Move
    RealMove.finish:
    pop cx
    pop dx
    pop ax
    ret


section .data
; Snake struct{
; loc dw
; dir db
; len db
;}
header_str dw 0   ; 队首节点地址（mem 内偏移）
now_dir db 0      ; 最近方向输入（0 表示无）
queue_start dw 0  ; 队列头指针（以字节偏移计）
queue_end dw 0    ; 队列尾指针

init_v dw 0       ; 初速度（由难度设定）
food_num dw 0     ; 吃到的食物计数（用于增长门槛）
rate dw 0         ; 速率累计进度
mem: times MEM_SIZE db 0  ; 环形缓冲区（存放节点数据）