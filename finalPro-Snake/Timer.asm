; ----------------------------------------------
; 计时器模块
; 作用：基于 DOS 时间（int 21h, AH=2Ch）产生刷新节拍
; 约定：UNIT_TIME 表示 0.01s 的倍数；3 即约 30ms 一次
; ----------------------------------------------
UNIT_TIME equ 3

section .text
; 初始化计时器
; 记录当前时间（以 0.01s 的个位：DL）到 last_time
TimerInit:
    push dx
    push cx
	mov ah,2ch
	int 21h
	mov [last_time], dl
    pop cx
    pop dx
	ret

; 检查是否到达刷新时间点
; 返回：AL=0 不刷新；AL=1 需要刷新
; 处理跨秒：若当前 DL < 上次 DL，等价于 +100 再比较
TimerCheck:
    push dx
    push cx
	mov ah,2ch
	int 21h
    pop cx
    mov dh,dl
	cmp dl, [last_time]
	jns TimerCheck.next
	add dl, 100
	TimerCheck.next:
	sub dl, [last_time]
	cmp dl, UNIT_TIME
	jns TimerCheck.check_success

	TimerCheck.check_failed:
    pop dx
	mov al,0
	ret
	TimerCheck.check_success:
	mov al,1
	mov [last_time], dh
    pop dx
	ret

section .data
	last_time db 0    ; 上一次取样的 0.01s 值（0..99）