; ----------------------------------------------
; 主入口文件（COM 程序）
; 作用：设置入口，初始化 -> 主控制器 -> 退出还原
; 说明：本项目在 80x25 彩色文本模式下直接写显存 0xB800
; ----------------------------------------------
org 100h


section .text
; 程序入口
start:
	; 初始化（清屏/菜单/地图/鼠标）
	call Init
	; 游戏主循环（键鼠监听 + 计时器节拍驱动）
	call MainController
	; 退出时还原屏幕/光标/鼠标区域
	call Quit

; 各模块按功能划分
%include './Timer.asm'      ; 计时器（基于 int 21h/2Ch）
%include './Drawer.asm'     ; 屏幕与绘制相关（显存操作/光标）
%include './Menu.asm'	     ; 菜单与分数显示
%include './Game.asm'       ; 游戏流程控制与地图
%include './Food.asm'       ; 食物与随机数
%include './Keyboard.asm'   ; 键盘输入
%include './Snake.asm'      ; 蛇体数据结构与移动
%include './Mouse.asm'      ; 鼠标输入与按钮区域判断