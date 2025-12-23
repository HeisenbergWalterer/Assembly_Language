; ----------------------------------------------
; 菜单与分数显示模块
; 作用：绘制右侧面板、按钮、分数与提示文字；提供隐藏/显示逻辑
; 注意：文字输出直接向显存写入字符+颜色属性，不经 BIOS/DOS 输出
; ----------------------------------------------
SCORE_ITEM_START equ (((80*1)+58)*2)
SCORE_ITEM_END equ (SCORE_ITEM_START+7*2)

SCORE_START equ (SCORE_ITEM_END+1*2)

START_ITEM_START equ (((80*15)+60)*2)
START_ITEM_END equ (START_ITEM_START+10*2)

QUIT_ITEM_START equ (((80*19)+60)*2)
QUIT_ITEM_END equ (QUIT_ITEM_START+10*2)

RETURN_ITEM_START equ (((80*11)+60)*2)
RETURN_ITEM_END equ (RETURN_ITEM_START+10*2)

PAUSE_ITEM_START equ (((80*7)+60)*2)
PAUSE_ITEM_END equ (PAUSE_ITEM_START+10*2)

OVER_ITEM_START equ (((80*7)+60)*2)
OVER_ITEM_END equ (PAUSE_ITEM_START+10*2)

EASY_ITEM_START equ (((80*13)+60)*2)
EASY_ITEM_END equ (EASY_ITEM_START+10*2)

MID_ITEM_START equ (((80*15)+60)*2)
MID_ITEM_END equ (MID_ITEM_START+10*2)

HARD_ITEM_START equ (((80*17)+60)*2)
HARD_ITEM_END equ (HARD_ITEM_START+10*2)

BACK_ITEM_START equ (((80*19)+60)*2)
BACK_ITEM_END equ (BACK_ITEM_START+10*2)

; 侧边面板区域（用于菜单与分数），刻意调整外观
PANEL_START_ROW equ 0
PANEL_START_COL equ 54
PANEL_WIDTH equ 26
PANEL_HEIGHT equ 23
PANEL_BOTTOM_ROW equ (PANEL_START_ROW+PANEL_HEIGHT-1)
PANEL_RIGHT_COL equ (PANEL_START_COL+PANEL_WIDTH-1)

PANEL_BG_CHAR equ 0x1F20        ; 蓝底、亮白字的空格（作为背景填充）
PANEL_BORDER_H_CHAR equ 0x3E2D  ; 青底、黄字 '-'（上/下边框）
PANEL_BORDER_V_CHAR equ 0x3E7C  ; 青底、黄字 '|'（左/右边框）

BUTTON_COLOR equ 0x2e00         ; 按钮：绿底黄字（与原版不同）
PAUSE_COLOR equ 0x9c00          ; 暂停/结束：深红底亮黄字

EASY_SPEED equ (MAX_RATE/10)
MID_SPEED equ (MAX_RATE/4)
HARD_SPEED equ MAX_RATE

section .text

MenuInit:
    ; 初始化侧边面板与静态区域，然后绘制分数与主菜单
    call MenuPanelInit
    call ScoreItemInit
    call MainItemInit
    ;call ContinueItemInit
    ;call PauseItemInit
    ret



MenuPanelInit:
    ; 绘制侧边蓝底面板 + 边框
    push bp
    mov bp,sp

    ; 填充侧边面板背景
    push word PANEL_START_ROW
    push word PANEL_START_COL
    push word PANEL_WIDTH
    push word PANEL_HEIGHT
    push word PANEL_BG_CHAR
    call DrawLine

    ; 上边框
    push word PANEL_START_ROW
    push word PANEL_START_COL
    push word PANEL_WIDTH
    push word 1
    push word PANEL_BORDER_H_CHAR
    call DrawLine

    ; 下边框
    push word PANEL_BOTTOM_ROW
    push word PANEL_START_COL
    push word PANEL_WIDTH
    push word 1
    push word PANEL_BORDER_H_CHAR
    call DrawLine

    ; 左边框
    push word PANEL_START_ROW
    push word PANEL_START_COL
    push word PANEL_HEIGHT
    push word 1
    push word PANEL_BORDER_V_CHAR
    call DrawLine

    ; 右边框
    push word PANEL_START_ROW
    push word PANEL_RIGHT_COL
    push word PANEL_HEIGHT
    push word 1
    push word PANEL_BORDER_V_CHAR
    call DrawLine

    mov sp,bp
    pop bp
    ret

ScoreItemInit:
    ; 分数标题与当前分数清零显示
    push ax
    mov ax,0
    mov word [score],ax
    push word score_item
    push word SCORE_ITEM_START
    call PrintStr
    call ShowScore
    pop ax
    pop ax
    pop ax
    ret

MainItemInit:
    ; 主菜单：New Game / Quit（隐藏难度项）
    push ax
    mov al,0
    mov byte [wait_select],al
    call HideLevelItem
    call StartItemInit
    call QuitItemInit
    pop ax
    ret

StartItemInit:
    ; 绘制 “New Game” 按钮（有色）
    push bp
    mov bp,sp

    push word start_item
    push word START_ITEM_START
    push word BUTTON_COLOR
    call PrintStrColor
    
    mov sp,bp
    pop bp
    ret

QuitItemInit:
    ; 绘制 “Quit” 按钮（有色）
    push bp
    mov bp,sp

    push word quit_item
    push word QUIT_ITEM_START
    push word BUTTON_COLOR
    call PrintStrColor
    
    mov sp,bp
    pop bp
    ret

ContinueItemInit:
    ; 绘制 “Continue” 按钮（暂停时出现）
    push bp
    mov bp,sp

    push word return_item
    push word RETURN_ITEM_START
    push word BUTTON_COLOR
    call PrintStrColor
    call ShowMouse
    mov sp,bp
    pop bp
    ret

PauseItemInit:
    ; 绘制 “Pausing!” 提示（红底黄字）
    push bp
    mov bp,sp

    push word pause_item
    push word PAUSE_ITEM_START
    push word PAUSE_COLOR
    call PrintStrColor
    
    mov sp,bp
    pop bp
    ret

HidePauseItem:
    ; 隐藏暂停提示与继续按钮（用面板底色覆盖）
    push bp
    mov bp,sp

    push word (PAUSE_ITEM_END - PAUSE_ITEM_START)/2
    push word PAUSE_ITEM_START
    call PrintBlankStr
    
    push word (RETURN_ITEM_END - RETURN_ITEM_START)/2
    push word RETURN_ITEM_START
    call PrintBlankStr
    mov sp,bp
    pop bp
    ret

LevelItemInit:
    ; 显示难度选择按钮（Easy/Medium/Hard/Back）
    push bp
    mov bp,sp
    push ax

    mov al,1
    mov byte [wait_select],al

    push word easy_item
    push word EASY_ITEM_START
    push word BUTTON_COLOR
    call PrintStrColor

    push word mid_item
    push word MID_ITEM_START
    push word BUTTON_COLOR
    call PrintStrColor

    push word hard_item
    push word HARD_ITEM_START
    push word BUTTON_COLOR
    call PrintStrColor

    push word back_item
    push word BACK_ITEM_START
    push word BUTTON_COLOR
    call PrintStrColor

    pop ax
    mov sp,bp
    pop bp
    ret

HideLevelItem:
    ; 隐藏难度选择按钮（用面板底色覆盖）
    push bp
    mov bp,sp

    push word (HARD_ITEM_END - HARD_ITEM_START)/2
    push word HARD_ITEM_START
    call PrintBlankStr
    
    push word (MID_ITEM_END - MID_ITEM_START)/2
    push word MID_ITEM_START
    call PrintBlankStr

    push word (EASY_ITEM_END - EASY_ITEM_START)/2
    push word EASY_ITEM_START
    call PrintBlankStr

    push word (BACK_ITEM_END - BACK_ITEM_START)/2
    push word BACK_ITEM_START
    call PrintBlankStr

    mov sp,bp
    pop bp
    ret

EasyMode:
    ; 设置初速度为 EASY，对应最大进度的 1/10
    mov byte [init_v],EASY_SPEED
    call GameStart
    ret

MidMode:
    ; 设置初速度为 MID
    mov byte [init_v],MID_SPEED
    call GameStart
    ret
HardMode:
    ; 设置初速度为 HARD
    mov byte [init_v],HARD_SPEED
    call GameStart
    ret
GameOverItemInit:
    ; “Game Over” 提示（红底）
    push bp
    mov bp,sp

    push word over_item
    push word OVER_ITEM_START
    push word PAUSE_COLOR
    call PrintStrColor
    
    mov sp,bp
    pop bp
    ret

ShowScore:
    ; 将 score 的数值转换为 5 位十进制字符串并显示
    push dx
    push cx
    push bx
    push ax
    push si
    mov si,word score_str
    mov cx,5
    ShowScore.init:
        mov al,'0'
        mov byte [si],al
        inc si
    loop ShowScore.init
    dec si
    
    
    mov bx,word score
    mov ax,[bx]
    mov bx,10
    ShowScore.loop:
        cmp ax,0
        jz ShowScore.finish
        mov dx,0
        div bx
        add [si],dl
        dec si
    jmp ShowScore.loop
    ShowScore.finish:
    push word score_str
    push word SCORE_START
    call PrintStr
    pop ax
    pop ax

    pop si
    pop ax
    pop bx
    pop cx
    pop dx
    ret 
; void PrintStr(u8* str,u16 loc)
PrintStr:
    ; 使用默认颜色（BLANK 的颜色部分）打印字符串
    push bp
    mov bp,sp
    push word [bp+6]
    push word [bp+4]
    push word BLANK
    call PrintStrColor
    mov sp,bp
    pop bp
    ret

; void PrintStrColor(u8* str,u16 loc,u16 color)
PrintStrColor:
    ; 指定颜色打印字符串（不会移动光标，直接写显存）
    push bp
    mov bp,sp

    call HideMouse

    push ax
    push bx
    mov ax,VIDEO_ADDRESS
    mov es,ax
    mov di,word [bp+6]
    mov bx, word [bp+8]
    mov ax, [bp+4]
    PrintStr.loop:
    mov al, byte [bx]
    cmp al,0
    jz  PrintStr.finish
    mov word [es:di],ax
    add di,2
    inc bx
    jmp PrintStr.loop

    PrintStr.finish:
    pop bx
    pop ax

    call ShowMouse

    mov sp,bp
    pop bp
    ret

PrintBlankStr:
    ; 从 loc 起覆盖 count 个字符，用面板背景色填充
    push bp
    mov bp,sp

    call HideMouse

    push ax
    push cx
    mov di,word [bp+4]
    mov cx,word [bp+6]
    mov ax,VIDEO_ADDRESS
    mov es,ax
    PrintBlankStr.loop:
        ; 使用面板背景色填充，避免留下黑色条块
        mov ax, PANEL_BG_CHAR
        mov word [es:di],ax
        add di,2
    loop PrintBlankStr.loop
    pop cx
    pop ax

    call ShowMouse

    mov sp,bp
    pop bp
    ret

section .data

score_item db   " Score:",0
return_item db  " Continue ",0
start_item db   " New Game ",0
quit_item db    "   Quit   ",0
pause_item db   " Pausing! ",0
over_item db    "Game Over!",0
easy_item db    "   Easy   ",0
mid_item db     "  Medium  ",0
hard_item db    "   Hard   ",0
back_item db    "   Back   ",0

score dw    0
score_str db    0,0,0,0,0,0
hide_str db "          ",0
wait_select db 0