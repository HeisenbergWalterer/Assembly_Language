; ----------------------------------------------
; 游戏流程与地图模块
; 作用：初始化、开始游戏、主循环、暂停/结束判断与地图绘制
; 地图：由四条墙构成的矩形盒子（左/右/上/下）
; ----------------------------------------------
BOX_START_X equ 0
BOX_START_Y equ 0
BOX_WIDTH equ 51
BOX_HEIGH equ 25

section .text

Init:
    ; 初次进入程序的初始化：屏幕/菜单/地图/鼠标
    call ScreenInit
    call MenuInit
    call CreateMap
	call MouseInit
    ret

GameStart:
    ; 开始新游戏：清屏重画地图与蛇，并重置计时与状态
    push ax
    call ClearScreen
    call CreateMap
    call SnakeInit
	call TimerInit
	call SetSeed
    call StopPause
    call MenuInit
    call SetNewFood
    mov al,0
    mov byte [is_end],al
    mov byte [now_dir],al
    pop ax
    ret

MainController:
    ; 主循环：键盘/鼠标监听；未暂停/未结束时按节拍驱动移动
    MainController.loop:
    call GetKey
    call MouseListen
    call CheckPause
    cmp al,1
	jz MainController.loop
	call TimerCheck
	cmp al,0
	jz MainController.loop
    call RealMove
	jmp MainController.loop
    ret

    

StopPause:
    ; 退出暂停：清除暂停标记与方向缓存，并隐藏暂停元素
    push ax
    mov al,0
    mov byte [is_pause],al
    mov byte [now_dir],al
    call HidePauseItem
    pop ax
    ret 

Pause:
    ; 进入暂停：展示 Continue 与 Pausing! 项（若未结束）
    push ax
    cmp byte [is_end],1
    jz Pause.end
    mov al,1
    mov byte [is_pause],al
    call ContinueItemInit
    call PauseItemInit
    Pause.end:
    pop ax
    ret 

CheckPause:
    ; 返回 AL=1 表示处于暂停或已结束
    mov ax,0
    mov al,byte [is_pause]
    or al, byte [is_end]
    ret

GameOver:
    ; 游戏结束：置结束标记，退出暂停并显示 Game Over
    push ax
    mov al,1
    mov byte [is_end],al
    call StopPause
    call GameOverItemInit
    pop ax
    ret
CreateMap:
    ; 按 BOX_* 参数绘制四条边作为地图边界
    push bp
    mov bp,sp

    ;左
    push word BOX_START_X
    push word BOX_START_Y
    push word BOX_HEIGH
    call DrawVerticalWall
    mov sp,bp

    ;右
    push word BOX_START_X
    push word BOX_START_Y+BOX_WIDTH-1
    push word BOX_HEIGH
    call DrawVerticalWall
    mov sp,bp

    ;上
    push word BOX_START_X
    push word BOX_START_Y
    push word BOX_WIDTH
    call DrawHorizontalWall
    mov sp,bp

    ;下
    push word BOX_START_X+BOX_HEIGH-1
    push word BOX_START_Y
    push word BOX_WIDTH
    call DrawHorizontalWall
    mov sp,bp

    pop bp
    ret

section .data
is_pause db     1   ; 是否暂停（1=暂停）
is_end db   1       ; 是否结束（1=结束）
