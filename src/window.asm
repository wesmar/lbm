; ==============================================================================
; LBM - Win32 GUI Module with Mica, Per-Monitor V2 DPI & Trackbars (Pure x64 ASM)
;
; Purpose: Modern Windows 11 Mica GUI, real-time trackbar validation, DPI scaling
; Author: Marek Wesolowski - WESMAR, 2026
; Language: English Interface & Dialogs
; ==============================================================================

option casemap:none
include consts.inc

EXTRN CreateWindowExW:PROC
EXTRN RegisterClassW:PROC
EXTRN ShowWindow:PROC
EXTRN UpdateWindow:PROC
EXTRN GetMessageW:PROC
EXTRN TranslateMessage:PROC
EXTRN DispatchMessageW:PROC
EXTRN PostQuitMessage:PROC
EXTRN DefWindowProcW:PROC
EXTRN SendMessageW:PROC
EXTRN SetWindowTextW:PROC
EXTRN GetModuleHandleW:PROC
EXTRN LoadIconW:PROC
EXTRN LoadCursorW:PROC
EXTRN CreateFontW:PROC
EXTRN DeleteObject:PROC
EXTRN MessageBoxW:PROC
EXTRN InitCommonControlsEx:PROC
EXTRN DwmSetWindowAttribute:PROC
EXTRN SetWindowPos:PROC
EXTRN GetDpiForSystem:PROC
EXTRN GetDpiForWindow:PROC
EXTRN EnumChildWindows:PROC
EXTRN AdjustWindowRectExForDpi:PROC
EXTRN IsDialogMessageW:PROC

EXTRN Lbm_GetBatteryThresholds:PROC
EXTRN Lbm_SetBatteryThresholds:PROC
EXTRN Lbm_ApplyMicaAndDpi:PROC

.const
str_className      dw 'L','b','m','A','s','m','G','u','i',0
str_windowTitle    dw 'L','e','n','o','v','o',' ','B','a','t','t','e','r','y',' ','M','a','n','a','g','e','r',' ','(','M','i','c','a',' ','E','d','i','t','i','o','n',')',0

str_staticClass    dw 'S','T','A','T','I','C',0
str_buttonClass    dw 'B','U','T','T','O','N',0
str_trackbarClass  dw 'm','s','c','t','l','s','_','t','r','a','c','k','b','a','r','3','2',0
str_fontName       dw 'S','e','g','o','e',' ','U','I',' ','V','a','r','i','a','b','l','e',' ','D','i','s','p','l','a','y',0
str_fontFallback   dw 'S','e','g','o','e',' ','U','I',0

str_lblMainTitle   dw 'L','e','n','o','v','o',' ','B','a','t','t','e','r','y',' ','C','h','a','r','g','e',' ','C','o','n','t','r','o','l',0
str_lblStart       dw 'C','h','a','r','g','e',' ','S','t','a','r','t',' ','T','h','r','e','s','h','o','l','d',' ',':',0
str_lblStop        dw 'C','h','a','r','g','e',' ','S','t','o','p',' ','T','h','r','e','s','h','o','l','d',' ',':',0
str_chkText        dw 'E','n','a','b','l','e',' ','B','a','t','t','e','r','y',' ','C','h','a','r','g','e',' ','L','i','m','i','t','s',0
str_btnApplyText   dw 'A','p','p','l','y',' ','S','e','t','t','i','n','g','s',0
str_btnDefaultsText dw 'D','e','f','a','u','l','t','s',0
str_btnDisableText dw 'C','h','a','r','g','e',' ','t','o',' ','1','0','0','%',0
str_statusReady    dw 'C','o','m','p','a','t','i','b','l','e',' ','L','e','n','o','v','o',' ','b','a','t','t','e','r','y',' ','d','e','t','e','c','t','e','d','.',0
str_statusLimited  dw 'C','h','a','r','g','e',' ','l','i','m','i','t','s',' ','a','r','e',' ','a','c','t','i','v','e','.',0
str_statusFull     dw 'C','h','a','r','g','e',' ','l','i','m','i','t','s',' ','a','r','e',' ','o','f','f',' ','-',' ','c','h','a','r','g','i','n','g',' ','t','o',' ','1','0','0','%','.',0
str_statusMissing  dw 'N','o',' ','c','o','m','p','a','t','i','b','l','e',' ','L','e','n','o','v','o',' ','b','a','t','t','e','r','y',' ','w','a','s',' ','f','o','u','n','d','.',0

str_msgSuccess     dw 'B','a','t','t','e','r','y',' ','t','h','r','e','s','h','o','l','d','s',' ','h','a','v','e',' ','b','e','e','n',' '
                   dw 's','u','c','c','e','s','s','f','u','l','l','y',' ','a','p','p','l','i','e','d','!',0
str_msgDisabled    dw 'C','h','a','r','g','e',' ','l','i','m','i','t','s',' ','a','r','e',' ','d','i','s','a','b','l','e','d','.',' '
                   dw 'T','h','e',' ','b','a','t','t','e','r','y',' ','c','a','n',' ','n','o','w',' ','c','h','a','r','g','e',' ','t','o',' ','1','0','0','%', '.',0
str_titleSuccess   dw 'L','B','M',' ','-',' ','S','u','c','c','e','s','s',0

str_msgFail        dw 'F','a','i','l','e','d',' ','t','o',' ','s','a','v','e',' ','t','h','r','e','s','h','o','l','d','s','.',' '
                   dw 'A','d','m','i','n','i','s','t','r','a','t','o','r',' ','p','r','i','v','i','l','e','g','e','s',' ','r','e','q','u','i','r','e','d','.',0
str_titleFail      dw 'L','B','M',' ','-',' ','E','r','r','o','r',0

.data?
g_hInstance    dq ?
g_hSliderStart dq ?
g_hSliderStop  dq ?
g_hLblStartVal dq ?
g_hLblStopVal  dq ?
g_hLblStatus   dq ?
g_hChkEnable   dq ?
g_hLblTitle    dq ?
g_hFont        dq ?
g_hFontTitle   dq ?
g_uDpi         dd ?

; Convert a 96-DPI logical value to a native pixel argument on the stack.
; This keeps the entire layout proportional instead of merely declaring PMv2.
SCALE_ARG MACRO stackOffset:req, logicalValue:req
    mov eax, logicalValue
    imul eax, dword ptr [g_uDpi]
    cdq
    mov ecx, 96
    idiv ecx
    movsxd rax, eax
    mov qword ptr [rsp+stackOffset], rax
ENDM

; Same conversion, stored as a DWORD for RECT members.
SCALE_D MACRO stackOffset:req, logicalValue:req
    mov eax, logicalValue
    imul eax, dword ptr [g_uDpi]
    cdq
    mov ecx, 96
    idiv ecx
    mov dword ptr [rsp+stackOffset], eax
ENDM

.code

; Apply the current DPI fonts to every child.  PMv2 scales window geometry, but
; application-created HFONT objects must be recreated by the application.
SetChildDpiFont proc
    sub rsp, 40
    mov r8, g_hFont
    cmp rcx, g_hLblTitle
    jne scdf_send
    mov r8, g_hFontTitle
scdf_send:
    mov r9d, 1
    mov edx, 30h               ; WM_SETFONT
    call SendMessageW
    mov eax, 1                 ; continue EnumChildWindows
    add rsp, 40
    ret
SetChildDpiFont endp

CreateDpiFonts proc
    sub rsp, 120

    lea rax, str_fontName
    mov qword ptr [rsp+104], rax
    mov dword ptr [rsp+96], 0
    mov dword ptr [rsp+88], 5
    mov dword ptr [rsp+80], 0
    mov dword ptr [rsp+72], 0
    mov dword ptr [rsp+64], 1
    mov dword ptr [rsp+56], 0
    mov dword ptr [rsp+48], 0
    mov dword ptr [rsp+40], 0
    mov dword ptr [rsp+32], 600
    xor r9d, r9d
    xor r8d, r8d
    xor edx, edx
    mov eax, -18
    imul eax, dword ptr [g_uDpi]
    cdq
    mov ecx, 96
    idiv ecx
    mov ecx, eax
    xor edx, edx               ; nWidth = 0 (idiv leaves its remainder in EDX)
    call CreateFontW
    mov g_hFontTitle, rax

    lea rax, str_fontFallback
    mov qword ptr [rsp+104], rax
    mov dword ptr [rsp+32], 400
    xor r9d, r9d
    xor r8d, r8d
    xor edx, edx
    mov eax, -14
    imul eax, dword ptr [g_uDpi]
    cdq
    mov ecx, 96
    idiv ecx
    mov ecx, eax
    xor edx, edx               ; nWidth = 0
    call CreateFontW
    mov g_hFont, rax

    add rsp, 120
    ret
CreateDpiFonts endp

PUBLIC RunGuiAsm

FormatPctStr proc
    push rbx
    sub rsp, 40

    mov eax, ecx
    mov rbx, rdx
    mov r8, rbx
    cmp eax, 100
    jb fp_under_100
    mov word ptr [r8], '1'
    mov word ptr [r8+2], '0'
    mov word ptr [r8+4], '0'
    add r8, 6
    jmp fp_suffix

fp_under_100:
    xor edx, edx
    mov ecx, 10
    div ecx
    test eax, eax
    jz fp_ones
    add eax, '0'
    mov word ptr [r8], ax
    add r8, 2
fp_ones:
    add edx, '0'
    mov word ptr [r8], dx
    add r8, 2
fp_suffix:
    mov word ptr [r8], '%'
    mov word ptr [r8+2], 0

    add rsp, 40
    pop rbx
    ret
FormatPctStr endp

; RCX = trackbar handle. Draws a tick for every step and makes the keyboard and
; the page area move by one step, so no input path can leave the grid.
ApplyStepMetrics proc
    push rbx
    sub rsp, 32

    mov rbx, rcx

    mov r9d, 0
    mov r8d, LBM_STEP
    mov edx, TBM_SETTICFREQ
    mov rcx, rbx
    call SendMessageW

    mov r9d, LBM_STEP
    xor r8d, r8d
    mov edx, TBM_SETPAGESIZE
    mov rcx, rbx
    call SendMessageW

    mov r9d, LBM_STEP
    xor r8d, r8d
    mov edx, TBM_SETLINESIZE
    mov rcx, rbx
    call SendMessageW

    add rsp, 32
    pop rbx
    ret
ApplyStepMetrics endp

; ECX = raw percentage, EAX = the same value pulled onto the five-percent grid.
; Leaf routine: it touches only volatile registers and makes no calls.
SnapToStep proc
    mov eax, ecx
    add eax, LBM_STEP / 2       ; Round half up instead of truncating down.
    xor edx, edx
    mov ecx, LBM_STEP
    div ecx
    imul eax, eax, LBM_STEP
    ret
SnapToStep endp

; EAX = value, ECX = minimum, EDX = maximum. Returns the clamped value in EAX.
ClampRange proc
    cmp eax, ecx
    jae cr_check_max
    mov eax, ecx
    ret
cr_check_max:
    cmp eax, edx
    jbe cr_done
    mov eax, edx
cr_done:
    ret
ClampRange endp

UpdateUIState proc
    sub rsp, 328

    lea rcx, [rsp+40]
    call Lbm_GetBatteryThresholds
    test eax, eax
    jnz uis_found

    lea rdx, str_statusMissing
    mov rcx, g_hLblStatus
    call SetWindowTextW

    ; Keep the GUI usable with conservative defaults when discovery fails.
    mov dword ptr [rsp+40 + LBM_BATTERY_THRESHOLD.startPercentage], LBM_DEFAULT_START
    mov dword ptr [rsp+40 + LBM_BATTERY_THRESHOLD.stopPercentage], LBM_DEFAULT_STOP
    mov dword ptr [rsp+40 + LBM_BATTERY_THRESHOLD.startEnabled], 0
    mov dword ptr [rsp+40 + LBM_BATTERY_THRESHOLD.stopEnabled], 0
    jmp uis_set_positions       ; Already on the grid and inside both ranges.

uis_found:
    ; Report the live threshold state; a generic "battery detected" line hides
    ; whether the limit is currently holding the pack back.
    lea rdx, str_statusLimited
    cmp dword ptr [rsp+40 + LBM_BATTERY_THRESHOLD.startEnabled], 0
    jne uis_status_ready
    cmp dword ptr [rsp+40 + LBM_BATTERY_THRESHOLD.stopEnabled], 0
    jne uis_status_ready
    lea rdx, str_statusFull

uis_status_ready:
    mov rcx, g_hLblStatus
    call SetWindowTextW

uis_load_data:
    ; A disabled configuration can hold percentages outside the slider ranges
    ; (or an inverted pair). Fall back to a valid pair before driving controls,
    ; otherwise the labels and the thumbs disagree.
    mov eax, dword ptr [rsp+40 + LBM_BATTERY_THRESHOLD.startPercentage]
    mov ecx, dword ptr [rsp+40 + LBM_BATTERY_THRESHOLD.stopPercentage]
    cmp eax, LBM_SLIDER_START_MIN
    jb uis_use_defaults
    cmp ecx, LBM_SLIDER_STOP_MAX
    ja uis_use_defaults
    cmp eax, ecx
    jb uis_snap

uis_use_defaults:
    mov dword ptr [rsp+40 + LBM_BATTERY_THRESHOLD.startPercentage], LBM_DEFAULT_START
    mov dword ptr [rsp+40 + LBM_BATTERY_THRESHOLD.stopPercentage], LBM_DEFAULT_STOP

uis_snap:
    ; The CLI and other tools can store any percentage, but a thumb only
    ; represents a grid position. Align first so the thumbs, the tick marks and
    ; the labels cannot disagree.
    mov ecx, dword ptr [rsp+40 + LBM_BATTERY_THRESHOLD.startPercentage]
    call SnapToStep
    mov ecx, LBM_SLIDER_START_MIN
    mov edx, LBM_SLIDER_START_MAX
    call ClampRange
    mov dword ptr [rsp+40 + LBM_BATTERY_THRESHOLD.startPercentage], eax

    mov ecx, dword ptr [rsp+40 + LBM_BATTERY_THRESHOLD.stopPercentage]
    call SnapToStep
    mov ecx, LBM_SLIDER_STOP_MIN
    mov edx, LBM_SLIDER_STOP_MAX
    call ClampRange
    mov dword ptr [rsp+40 + LBM_BATTERY_THRESHOLD.stopPercentage], eax

    ; A released limit parks both thumbs at the right end, the same position the
    ; sliders themselves use for "no limit". The stored pair stays untouched in
    ; the registry, so Defaults and --status still recover it.
    cmp dword ptr [rsp+40 + LBM_BATTERY_THRESHOLD.startEnabled], 0
    jne uis_limit
    cmp dword ptr [rsp+40 + LBM_BATTERY_THRESHOLD.stopEnabled], 0
    jne uis_limit
    mov dword ptr [rsp+40 + LBM_BATTERY_THRESHOLD.startPercentage], LBM_SLIDER_START_MAX
    mov dword ptr [rsp+40 + LBM_BATTERY_THRESHOLD.stopPercentage], LBM_SLIDER_STOP_MAX
    jmp uis_set_positions

uis_limit:
    ; An active limit has to leave room above its stop threshold.
    mov eax, dword ptr [rsp+40 + LBM_BATTERY_THRESHOLD.stopPercentage]
    cmp eax, LBM_LIMIT_STOP_MAX
    jbe uis_order
    mov dword ptr [rsp+40 + LBM_BATTERY_THRESHOLD.stopPercentage], LBM_LIMIT_STOP_MAX

uis_order:
    ; Snapping can collapse a close pair: 79/81 both land on 80.
    mov eax, dword ptr [rsp+40 + LBM_BATTERY_THRESHOLD.stopPercentage]
    sub eax, LBM_STEP
    cmp dword ptr [rsp+40 + LBM_BATTERY_THRESHOLD.startPercentage], eax
    jbe uis_set_positions
    mov dword ptr [rsp+40 + LBM_BATTERY_THRESHOLD.startPercentage], eax

uis_set_positions:
    mov r9d, dword ptr [rsp+40 + LBM_BATTERY_THRESHOLD.startPercentage]
    mov r8d, 1
    mov edx, TBM_SETPOS
    mov rcx, g_hSliderStart
    call SendMessageW

    mov r9d, dword ptr [rsp+40 + LBM_BATTERY_THRESHOLD.stopPercentage]
    mov r8d, 1
    mov edx, TBM_SETPOS
    mov rcx, g_hSliderStop
    call SendMessageW

    mov ecx, dword ptr [rsp+40 + LBM_BATTERY_THRESHOLD.startPercentage]
    lea rdx, [rsp+200]
    call FormatPctStr
    lea rdx, [rsp+200]
    mov rcx, g_hLblStartVal
    call SetWindowTextW

    mov ecx, dword ptr [rsp+40 + LBM_BATTERY_THRESHOLD.stopPercentage]
    lea rdx, [rsp+200]
    call FormatPctStr
    lea rdx, [rsp+200]
    mov rcx, g_hLblStopVal
    call SetWindowTextW

    mov r8d, BST_UNCHECKED
    cmp dword ptr [rsp+40 + LBM_BATTERY_THRESHOLD.startEnabled], 0
    je chk_off
    cmp dword ptr [rsp+40 + LBM_BATTERY_THRESHOLD.stopEnabled], 0
    je chk_off
    mov r8d, BST_CHECKED

chk_off:
    xor r9d, r9d                ; BM_SETCHECK ignores lParam; keep it zero.
    mov edx, BM_SETCHECK
    mov rcx, g_hChkEnable
    call SendMessageW

uis_done:
    add rsp, 328
    ret
UpdateUIState endp

WndProc proc
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push rbp
    sub rsp, 168

    mov rbx, rcx                ; rbx = hWnd
    mov r12d, edx               ; r12d = uMsg
    mov rsi, r8                 ; Preserve wParam across all nested API calls.
    mov r13, r9                 ; Preserve lParam across all nested API calls.

    cmp r12d, 1                 ; WM_CREATE
    je wm_create
    cmp r12d, 114h              ; WM_HSCROLL
    je wm_hscroll
    cmp r12d, 111h              ; WM_COMMAND
    je wm_command
    cmp r12d, 001Ah             ; WM_SETTINGCHANGE
    je wm_settingchange
    cmp r12d, 02E0h             ; WM_DPICHANGED
    je wm_dpichanged
    cmp r12d, 2                 ; WM_DESTROY
    je wm_destroy
    cmp r12d, DM_GETDEFID
    je wm_getdefid

    mov r9, r13                 ; Restore the original lParam.
    mov r8, rsi                 ; Restore the original wParam.
    mov edx, r12d               ; edx = uMsg
    mov rcx, rbx                ; rcx = hWnd
    call DefWindowProcW
    jmp wp_exit

wm_create:
    ; GetDpiForSystem is not the DPI of a window placed on another monitor.
    mov rcx, rbx
    call GetDpiForWindow
    test eax, eax
    jz wm_create_dpi_ready
    mov dword ptr [g_uDpi], eax
wm_create_dpi_ready:
    ; CreateWindowEx had to choose a size before the target monitor DPI was
    ; known.  Derive the frame from the client area the layout was designed
    ; against: guessing the outer size leaves a right margin that does not match
    ; the left one, and the error changes with DPI and theme.
    mov dword ptr [rsp+56], 0   ; rc.left
    mov dword ptr [rsp+60], 0   ; rc.top
    SCALE_D 64, LBM_CLIENT_W    ; rc.right
    SCALE_D 68, LBM_CLIENT_H    ; rc.bottom

    mov eax, dword ptr [g_uDpi]
    mov dword ptr [rsp+32], eax
    xor r9d, r9d                ; dwExStyle = 0
    xor r8d, r8d                ; bMenu = FALSE
    mov edx, 00CF0000h          ; WS_OVERLAPPEDWINDOW
    lea rcx, [rsp+56]
    call AdjustWindowRectExForDpi

    mov eax, dword ptr [rsp+64]
    sub eax, dword ptr [rsp+56]
    movsxd rax, eax
    mov qword ptr [rsp+32], rax ; cx
    mov eax, dword ptr [rsp+68]
    sub eax, dword ptr [rsp+60]
    movsxd rax, eax
    mov qword ptr [rsp+40], rax ; cy
    mov dword ptr [rsp+48], 16h ; SWP_NOMOVE | SWP_NOZORDER | SWP_NOACTIVATE
    xor r9d, r9d
    xor r8d, r8d
    xor edx, edx
    mov rcx, rbx
    call SetWindowPos

    mov rcx, rbx
    call Lbm_ApplyMicaAndDpi

    ; DWMWA_WINDOW_CORNER_PREFERENCE = 33, DWMWCP_ROUND = 2
    mov dword ptr [rsp+48], DWMWCP_ROUND
    mov r9d, 4
    lea r8, [rsp+48]
    mov edx, DWMWA_WINDOW_CORNER_PREFERENCE
    mov rcx, rbx
    call DwmSetWindowAttribute

    ; Force DWM to recalculate the non-client frame after backdrop changes.
    mov dword ptr [rsp+48], 39  ; SWP_FRAMECHANGED | SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER
    mov QWORD PTR [rsp+32], 0
    mov QWORD PTR [rsp+40], 0
    xor r9d, r9d
    xor r8d, r8d
    xor edx, edx
    mov rcx, rbx
    call SetWindowPos

    ; Create the semibold title font using the complete x64 CreateFontW ABI.
    lea rax, str_fontName
    mov QWORD PTR [rsp+104], rax
    mov dword ptr [rsp+96], 0   ; DEFAULT_PITCH
    mov dword ptr [rsp+88], 5   ; CLEARTYPE_QUALITY
    mov dword ptr [rsp+80], 0   ; CLIP_DEFAULT_PRECIS
    mov dword ptr [rsp+72], 0   ; OUT_DEFAULT_PRECIS
    mov dword ptr [rsp+64], 1   ; DEFAULT_CHARSET
    mov dword ptr [rsp+56], 0   ; strikeout
    mov dword ptr [rsp+48], 0   ; underline
    mov dword ptr [rsp+40], 0   ; italic
    mov dword ptr [rsp+32], 600 ; FW_SEMIBOLD
    mov r9d, 0
    mov r8d, 0
    mov edx, 0
    mov eax, -18
    imul eax, dword ptr [g_uDpi]
    cdq
    mov ecx, 96
    idiv ecx
    mov ecx, eax
    xor edx, edx               ; nWidth = 0 (idiv leaves its remainder in EDX)
    call CreateFontW
    mov g_hFontTitle, rax

    ; Create the regular UI font with the same fully initialized argument set.
    lea rax, str_fontFallback
    mov QWORD PTR [rsp+104], rax
    mov dword ptr [rsp+96], 0
    mov dword ptr [rsp+88], 5
    mov dword ptr [rsp+80], 0
    mov dword ptr [rsp+72], 0
    mov dword ptr [rsp+64], 1
    mov dword ptr [rsp+56], 0
    mov dword ptr [rsp+48], 0
    mov dword ptr [rsp+40], 0
    mov dword ptr [rsp+32], 400 ; FW_NORMAL
    mov r9d, 0
    mov r8d, 0
    mov edx, 0
    mov eax, -14
    imul eax, dword ptr [g_uDpi]
    cdq
    mov ecx, 96
    idiv ecx
    mov ecx, eax
    xor edx, edx               ; nWidth = 0
    call CreateFontW
    mov g_hFont, rax

    ; Title STATIC
    mov QWORD PTR [rsp+88], 0
    mov rax, g_hInstance
    mov QWORD PTR [rsp+80], rax
    mov QWORD PTR [rsp+72], 0
    mov QWORD PTR [rsp+64], rbx ; hWndParent = rbx
    SCALE_ARG 56, 26
    SCALE_ARG 48, LBM_CONTENT_W
    SCALE_ARG 40, 15
    SCALE_ARG 32, LBM_MARGIN
    mov r9d, WS_CHILD_VISIBLE
    lea r8, str_lblMainTitle
    lea rdx, str_staticClass
    xor ecx, ecx                ; dwExStyle = 0
    call CreateWindowExW
    mov g_hLblTitle, rax
    mov r8, g_hFontTitle
    mov edx, 30h
    mov rcx, rax
    call SendMessageW

    ; Start Lbl
    mov QWORD PTR [rsp+88], 0
    mov rax, g_hInstance
    mov QWORD PTR [rsp+80], rax
    mov QWORD PTR [rsp+72], 0
    mov QWORD PTR [rsp+64], rbx
    SCALE_ARG 56, 20
    SCALE_ARG 48, LBM_LBL_W
    SCALE_ARG 40, 55
    SCALE_ARG 32, LBM_MARGIN
    mov r9d, WS_CHILD_VISIBLE
    lea r8, str_lblStart
    lea rdx, str_staticClass
    xor ecx, ecx
    call CreateWindowExW
    mov r8, g_hFont
    mov edx, 30h
    mov rcx, rax
    call SendMessageW

    ; Start Val Lbl
    mov QWORD PTR [rsp+88], 0
    mov rax, g_hInstance
    mov QWORD PTR [rsp+80], rax
    mov QWORD PTR [rsp+72], ID_LBL_START_VAL
    mov QWORD PTR [rsp+64], rbx
    SCALE_ARG 56, 20
    SCALE_ARG 48, LBM_VAL_W
    SCALE_ARG 40, 55
    SCALE_ARG 32, LBM_VAL_X
    mov r9d, WS_CHILD_VISIBLE or SS_RIGHT
    lea r8, str_lblStart
    lea rdx, str_staticClass
    xor ecx, ecx
    call CreateWindowExW
    mov g_hLblStartVal, rax
    mov r8, g_hFont
    mov edx, 30h
    mov rcx, rax
    call SendMessageW

    ; Start Slider
    mov QWORD PTR [rsp+88], 0
    mov rax, g_hInstance
    mov QWORD PTR [rsp+80], rax
    mov QWORD PTR [rsp+72], ID_SLIDER_START
    mov QWORD PTR [rsp+64], rbx
    SCALE_ARG 56, 32
    SCALE_ARG 48, LBM_CONTENT_W
    SCALE_ARG 40, 80
    SCALE_ARG 32, LBM_MARGIN
    mov r9d, WS_CHILD_VISIBLE or WS_TABSTOP or TBS_AUTOTICKS
    xor r8, r8
    lea rdx, str_trackbarClass
    xor ecx, ecx
    call CreateWindowExW
    mov g_hSliderStart, rax
    mov r9d, LBM_SLIDER_START_MIN or (LBM_SLIDER_START_MAX shl 16)
    mov r8d, 1
    mov edx, TBM_SETRANGE
    mov rcx, rax
    call SendMessageW
    mov rcx, g_hSliderStart
    call ApplyStepMetrics

    ; Stop Lbl
    mov QWORD PTR [rsp+88], 0
    mov rax, g_hInstance
    mov QWORD PTR [rsp+80], rax
    mov QWORD PTR [rsp+72], 0
    mov QWORD PTR [rsp+64], rbx
    SCALE_ARG 56, 20
    SCALE_ARG 48, LBM_LBL_W
    SCALE_ARG 40, 125
    SCALE_ARG 32, LBM_MARGIN
    mov r9d, WS_CHILD_VISIBLE
    lea r8, str_lblStop
    lea rdx, str_staticClass
    xor ecx, ecx
    call CreateWindowExW
    mov r8, g_hFont
    mov edx, 30h
    mov rcx, rax
    call SendMessageW

    ; Stop Val Lbl
    mov QWORD PTR [rsp+88], 0
    mov rax, g_hInstance
    mov QWORD PTR [rsp+80], rax
    mov QWORD PTR [rsp+72], ID_LBL_STOP_VAL
    mov QWORD PTR [rsp+64], rbx
    SCALE_ARG 56, 20
    SCALE_ARG 48, LBM_VAL_W
    SCALE_ARG 40, 125
    SCALE_ARG 32, LBM_VAL_X
    mov r9d, WS_CHILD_VISIBLE or SS_RIGHT
    lea r8, str_lblStop
    lea rdx, str_staticClass
    xor ecx, ecx
    call CreateWindowExW
    mov g_hLblStopVal, rax
    mov r8, g_hFont
    mov edx, 30h
    mov rcx, rax
    call SendMessageW

    ; Stop Slider
    mov QWORD PTR [rsp+88], 0
    mov rax, g_hInstance
    mov QWORD PTR [rsp+80], rax
    mov QWORD PTR [rsp+72], ID_SLIDER_STOP
    mov QWORD PTR [rsp+64], rbx
    SCALE_ARG 56, 32
    SCALE_ARG 48, LBM_CONTENT_W
    SCALE_ARG 40, 150
    SCALE_ARG 32, LBM_MARGIN
    mov r9d, WS_CHILD_VISIBLE or WS_TABSTOP or TBS_AUTOTICKS
    xor r8, r8
    lea rdx, str_trackbarClass
    xor ecx, ecx
    call CreateWindowExW
    mov g_hSliderStop, rax
    mov r9d, LBM_SLIDER_STOP_MIN or (LBM_SLIDER_STOP_MAX shl 16)
    mov r8d, 1
    mov edx, TBM_SETRANGE
    mov rcx, rax
    call SendMessageW
    mov rcx, g_hSliderStop
    call ApplyStepMetrics

    ; Checkbox Enable
    mov QWORD PTR [rsp+88], 0
    mov rax, g_hInstance
    mov QWORD PTR [rsp+80], rax
    mov QWORD PTR [rsp+72], ID_CHK_ENABLE
    mov QWORD PTR [rsp+64], rbx
    SCALE_ARG 56, 24
    SCALE_ARG 48, LBM_CONTENT_W ; Full content width, like every other row.
    SCALE_ARG 40, 195
    SCALE_ARG 32, LBM_MARGIN
    mov r9d, WS_CHILD_VISIBLE or WS_TABSTOP or BS_AUTOCHECKBOX
    lea r8, str_chkText
    lea rdx, str_buttonClass
    xor ecx, ecx
    call CreateWindowExW
    mov g_hChkEnable, rax
    mov r8, g_hFont
    mov edx, 30h
    mov rcx, rax
    call SendMessageW

    ; Button Apply
    mov QWORD PTR [rsp+88], 0
    mov rax, g_hInstance
    mov QWORD PTR [rsp+80], rax
    mov QWORD PTR [rsp+72], ID_BTN_APPLY
    mov QWORD PTR [rsp+64], rbx
    SCALE_ARG 56, 34
    SCALE_ARG 48, LBM_BTN_W
    SCALE_ARG 40, 235
    SCALE_ARG 32, LBM_BTN_X1
    mov r9d, WS_CHILD_VISIBLE or WS_TABSTOP or BS_DEFPUSHBUTTON
    lea r8, str_btnApplyText
    lea rdx, str_buttonClass
    xor ecx, ecx
    call CreateWindowExW
    mov r8, g_hFont
    mov edx, 30h
    mov rcx, rax
    call SendMessageW

    ; Button Defaults
    mov QWORD PTR [rsp+88], 0
    mov rax, g_hInstance
    mov QWORD PTR [rsp+80], rax
    mov QWORD PTR [rsp+72], ID_BTN_DEFAULTS
    mov QWORD PTR [rsp+64], rbx
    SCALE_ARG 56, 34
    SCALE_ARG 48, LBM_BTN_W
    SCALE_ARG 40, 235
    SCALE_ARG 32, LBM_BTN_X2
    mov r9d, WS_CHILD_VISIBLE or WS_TABSTOP
    lea r8, str_btnDefaultsText
    lea rdx, str_buttonClass
    xor ecx, ecx
    call CreateWindowExW
    mov r8, g_hFont
    mov edx, 30h
    mov rcx, rax
    call SendMessageW

    ; Button Disable
    mov QWORD PTR [rsp+88], 0
    mov rax, g_hInstance
    mov QWORD PTR [rsp+80], rax
    mov QWORD PTR [rsp+72], ID_BTN_DISABLE
    mov QWORD PTR [rsp+64], rbx
    SCALE_ARG 56, 34
    SCALE_ARG 48, LBM_BTN_W
    SCALE_ARG 40, 235
    SCALE_ARG 32, LBM_BTN_X3
    mov r9d, WS_CHILD_VISIBLE or WS_TABSTOP
    lea r8, str_btnDisableText
    lea rdx, str_buttonClass
    xor ecx, ecx
    call CreateWindowExW
    mov r8, g_hFont
    mov edx, 30h
    mov rcx, rax
    call SendMessageW

    ; Status line
    mov QWORD PTR [rsp+88], 0
    mov rax, g_hInstance
    mov QWORD PTR [rsp+80], rax
    mov QWORD PTR [rsp+72], ID_LBL_STATUS
    mov QWORD PTR [rsp+64], rbx
    SCALE_ARG 56, 20
    SCALE_ARG 48, LBM_CONTENT_W
    SCALE_ARG 40, 285
    SCALE_ARG 32, LBM_MARGIN
    mov r9d, WS_CHILD_VISIBLE
    lea r8, str_statusMissing
    lea rdx, str_staticClass
    xor ecx, ecx
    call CreateWindowExW
    mov g_hLblStatus, rax
    mov r8, g_hFont
    mov edx, 30h
    mov rcx, rax
    call SendMessageW

    call UpdateUIState
    xor eax, eax
    jmp wp_exit

wm_hscroll:
    xor r9d, r9d
    xor r8d, r8d
    mov edx, TBM_GETPOS
    mov rcx, g_hSliderStart
    call SendMessageW
    mov edi, eax

    xor r9d, r9d
    xor r8d, r8d
    mov edx, TBM_GETPOS
    mov rcx, g_hSliderStop
    call SendMessageW
    mov ebp, eax

    ; Pull the dragged value onto the grid before anything else looks at it.
    ; The thumb is written back below, so the control follows the magnet.
    mov ecx, edi
    call SnapToStep
    mov ecx, LBM_SLIDER_START_MIN
    mov edx, LBM_SLIDER_START_MAX
    call ClampRange
    mov edi, eax

    mov ecx, ebp
    call SnapToStep
    mov ecx, LBM_SLIDER_STOP_MIN
    mov edx, LBM_SLIDER_STOP_MAX
    call ClampRange
    mov ebp, eax

    ; The pair has exactly two shapes: both thumbs at the top, which is the
    ; released state, or a real limit whose stop sits below the top with a full
    ; step of room under it. Dragging a thumb off the top turns the limit on,
    ; dragging one onto the top turns it off, and the thumbs travel together.
    mov rax, g_hSliderStart
    cmp r13, rax
    je hs_start_dragged

    cmp ebp, LBM_SLIDER_STOP_MAX
    jne hs_limit_on
    mov edi, LBM_SLIDER_START_MAX   ; Stop parked at the top: release the pair.
    jmp write_back_positions

hs_start_dragged:
    cmp edi, LBM_SLIDER_START_MAX
    jne hs_start_below_top
    mov ebp, LBM_SLIDER_STOP_MAX    ; Start parked at the top: release the pair.
    jmp write_back_positions

hs_start_below_top:
    cmp ebp, LBM_SLIDER_STOP_MAX
    jne hs_limit_on
    lea ebp, [edi + LBM_STEP]       ; Leaving the top arms the limit.

hs_limit_on:
    ; A limit that stops at 100% is not a limit, and the driver rejects it.
    cmp ebp, LBM_LIMIT_STOP_MAX
    jbe hs_order
    mov ebp, LBM_LIMIT_STOP_MAX

hs_order:
    mov eax, ebp
    sub eax, LBM_STEP
    cmp edi, eax
    jbe write_back_positions
    mov rax, g_hSliderStart
    cmp r13, rax
    jne adjust_start_slider

    ; Dragging start pushes stop up while there is room above it.
    lea ebp, [edi + LBM_STEP]
    cmp ebp, LBM_LIMIT_STOP_MAX
    jbe write_back_positions
    mov ebp, LBM_LIMIT_STOP_MAX

adjust_start_slider:
    mov edi, ebp
    sub edi, LBM_STEP

write_back_positions:
    mov r9d, edi
    mov r8d, 1
    mov edx, TBM_SETPOS
    mov rcx, g_hSliderStart
    call SendMessageW

    mov r9d, ebp
    mov r8d, 1
    mov edx, TBM_SETPOS
    mov rcx, g_hSliderStop
    call SendMessageW

sync_labels:
    mov ecx, edi
    lea rdx, [rsp+64]
    call FormatPctStr
    lea rdx, [rsp+64]
    mov rcx, g_hLblStartVal
    call SetWindowTextW

    mov ecx, ebp
    lea rdx, [rsp+64]
    call FormatPctStr
    lea rdx, [rsp+64]
    mov rcx, g_hLblStopVal
    call SetWindowTextW

    ; The thumbs are the switch, so the box always shows what Apply will do:
    ; ticked whenever a real limit is set, cleared at the released position.
    mov r8d, BST_CHECKED
    cmp ebp, LBM_SLIDER_STOP_MAX
    jne hs_write_check
    mov r8d, BST_UNCHECKED

hs_write_check:
    xor r9d, r9d
    mov edx, BM_SETCHECK
    mov rcx, g_hChkEnable
    call SendMessageW

hscroll_done:
    xor eax, eax
    jmp wp_exit

wm_getdefid:
    ; IsDialogMessageW asks the frame which control Enter should press. Without
    ; an answer it falls back to IDOK, which this window does not own.
    mov eax, (DC_HASDEFID shl 16) or ID_BTN_APPLY
    jmp wp_exit

wm_settingchange:
    mov rcx, rbx
    call Lbm_ApplyMicaAndDpi
    xor eax, eax
    jmp wp_exit

wm_dpichanged:
    ; LOWORD(wParam) is the new X DPI. Rebuild custom fonts before repainting;
    ; retaining an HFONT from the previous monitor causes stretched text.
    mov eax, esi
    and eax, 0FFFFh
    test eax, eax
    jz dpi_fonts_done
    cmp eax, dword ptr [g_uDpi]
    je dpi_fonts_done
    mov dword ptr [g_uDpi], eax
    mov rdi, g_hFontTitle
    mov rbp, g_hFont
    call CreateDpiFonts
    xor r8d, r8d
    lea rdx, SetChildDpiFont
    mov rcx, rbx
    call EnumChildWindows
    test rdi, rdi
    jz dpi_delete_regular
    mov rcx, rdi
    call DeleteObject
dpi_delete_regular:
    test rbp, rbp
    jz dpi_fonts_done
    mov rcx, rbp
    call DeleteObject
dpi_fonts_done:
    ; Apply the operating system's recommended rectangle on monitor changes.
    mov r8d, dword ptr [r13]
    mov r9d, dword ptr [r13+4]
    mov eax, dword ptr [r13+8]
    sub eax, r8d
    mov dword ptr [rsp+32], eax
    mov eax, dword ptr [r13+12]
    sub eax, r9d
    mov dword ptr [rsp+40], eax
    mov dword ptr [rsp+48], 14h ; SWP_NOZORDER | SWP_NOACTIVATE
    xor edx, edx
    mov rcx, rbx
    call SetWindowPos
    xor eax, eax
    jmp wp_exit

wm_command:
    mov eax, esi                ; Recover the preserved wParam value.
    and eax, 0FFFFh
    cmp eax, ID_BTN_APPLY
    je btn_apply
    cmp eax, ID_BTN_DISABLE
    je btn_disable
    cmp eax, ID_BTN_DEFAULTS
    je btn_defaults
    xor eax, eax                ; Handled: notifications we ignore return zero.
    jmp wp_exit

btn_defaults:
    ; Load the Lenovo Vantage pair into the controls only. Nothing reaches the
    ; driver until Apply, so this stays an undoable preview.
    mov r9d, LBM_DEFAULT_START
    mov r8d, 1
    mov edx, TBM_SETPOS
    mov rcx, g_hSliderStart
    call SendMessageW

    mov r9d, LBM_DEFAULT_STOP
    mov r8d, 1
    mov edx, TBM_SETPOS
    mov rcx, g_hSliderStop
    call SendMessageW

    mov edi, LBM_DEFAULT_START
    mov ebp, LBM_DEFAULT_STOP
    jmp sync_labels             ; Ticks the box: the pair is a real limit.

btn_apply:
    xor r9d, r9d
    xor r8d, r8d
    mov edx, TBM_GETPOS
    mov rcx, g_hSliderStart
    call SendMessageW
    mov edi, eax

    xor r9d, r9d
    xor r8d, r8d
    mov edx, TBM_GETPOS
    mov rcx, g_hSliderStop
    call SendMessageW
    mov ebp, eax

    xor r12d, r12d              ; Success message selector: thresholds enabled.
    cmp ebp, 100
    jne read_enable_checkbox

    ; A 100% upper limit means "no limit", matching Lenovo Vantage behavior.
    ; The start percentage is kept as-is so re-enabling restores the pair.
    mov r8d, 0
    mov r12d, 1
    jmp do_set

read_enable_checkbox:
    xor r9d, r9d
    xor r8d, r8d
    mov edx, BM_GETCHECK
    mov rcx, g_hChkEnable
    call SendMessageW
    mov r8d, 0
    mov r12d, 1                 ; Unticked box disables: report that, not "applied".
    cmp eax, BST_CHECKED
    jne do_set
    mov r8d, 1
    xor r12d, r12d

do_set:
    mov edx, ebp
    mov ecx, edi
    call Lbm_SetBatteryThresholds
    test eax, eax
    jz apply_fail

    mov r9d, 40h
    lea r8, str_titleSuccess
    lea rdx, str_msgSuccess
    test r12d, r12d
    jz show_apply_success
    lea rdx, str_msgDisabled

show_apply_success:
    mov rcx, rbx
    call MessageBoxW
    call UpdateUIState
    xor eax, eax
    jmp wp_exit

apply_fail:
    mov r9d, 10h
    lea r8, str_titleFail
    lea rdx, str_msgFail
    mov rcx, rbx
    call MessageBoxW
    xor eax, eax
    jmp wp_exit

btn_disable:
    mov r8d, 0
    mov edx, 100
    mov ecx, 100
    call Lbm_SetBatteryThresholds
    test eax, eax
    jz apply_fail
    call UpdateUIState
    mov r9d, 40h
    lea r8, str_titleSuccess
    lea rdx, str_msgDisabled
    mov rcx, rbx
    call MessageBoxW
    xor eax, eax
    jmp wp_exit

wm_destroy:
    mov rcx, g_hFontTitle
    test rcx, rcx
    jz check_font
    call DeleteObject

check_font:
    mov rcx, g_hFont
    test rcx, rcx
    jz no_font
    call DeleteObject

no_font:
    xor ecx, ecx
    call PostQuitMessage
    xor eax, eax

wp_exit:
    add rsp, 168
    pop rbp
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret
WndProc endp

RunGuiAsm proc
    push rbx
    push rsi
    push rdi
    push rbp
    sub rsp, 216

    ; 1. InitCommonControlsEx(dwSize=8, dwICC=0x000000FF)
    mov dword ptr [rsp+40], 8
    mov dword ptr [rsp+44], 000000FFh ; ICC_WIN95_CLASSES
    lea rcx, [rsp+40]
    call InitCommonControlsEx

    call GetDpiForSystem
    test eax, eax
    jnz dpi_initialized
    mov eax, 96
dpi_initialized:
    mov dword ptr [g_uDpi], eax

    xor ecx, ecx
    call GetModuleHandleW
    mov g_hInstance, rax
    mov rbx, rax                ; RBX = hInstance

    ; 2. Load embedded application icon (ID 101) and arrow cursor.
    mov edx, 101                ; Resource ID 101
    mov rcx, rbx                ; rcx = hInstance
    call LoadIconW
    test rax, rax
    jnz icon_loaded
    mov edx, 32512              ; Fallback: IDI_APPLICATION
    xor ecx, ecx
    call LoadIconW
icon_loaded:
    mov rsi, rax                ; RSI = hIcon

    mov edx, 32512              ; IDC_ARROW
    xor ecx, ecx
    call LoadCursorW
    mov rbp, rax                ; RBP = hCursor

    ; 3. Initialize the complete WNDCLASSW storage on the local stack.
    lea rdi, [rsp+40]
    mov ecx, 40
    xor eax, eax
    rep stosb

    ; 4. Populate WNDCLASSW using the same native layout as CMDT.
    mov dword ptr [rsp+40], 3   ; CS_HREDRAW | CS_VREDRAW
    lea rax, WndProc
    mov qword ptr [rsp+48], rax ; lpfnWndProc
    mov qword ptr [rsp+64], rbx ; hInstance
    mov qword ptr [rsp+72], rsi ; hIcon
    mov qword ptr [rsp+80], rbp ; hCursor
    mov qword ptr [rsp+88], 0   ; hbrBackground = NULL (Mica backdrop)
    mov qword ptr [rsp+96], 0   ; lpszMenuName = NULL
    lea rax, str_className
    mov qword ptr [rsp+104], rax; lpszClassName

    lea rcx, [rsp+40]           ; Register the native Unicode window class.
    call RegisterClassW
    test ax, ax
    jz gui_fail

    ; 5. CreateWindowExW z poprawnym x64 ABI stack layout:
    mov qword ptr [rsp+88], 0   ; lpParam = NULL
    mov qword ptr [rsp+80], rbx ; hInstance = rbx
    mov qword ptr [rsp+72], 0   ; hMenu = NULL
    mov qword ptr [rsp+64], 0   ; hWndParent = NULL
    SCALE_ARG 56, 365         ; DPI-scaled outer window height.
    SCALE_ARG 48, 420         ; DPI-scaled outer window width.
    mov qword ptr [rsp+40], 80000000h ; CW_USEDEFAULT
    mov qword ptr [rsp+32], 80000000h ; CW_USEDEFAULT
    mov r9d, 00CF0000h          ; WS_OVERLAPPEDWINDOW
    lea r8, str_windowTitle
    lea rdx, str_className
    xor ecx, ecx                ; dwExStyle = 0
    call CreateWindowExW
    mov rbx, rax

    test rbx, rbx
    jz gui_fail

    mov edx, 5                  ; SW_SHOW
    mov rcx, rbx
    call ShowWindow

    mov rcx, rbx
    call UpdateWindow

msg_loop:
    xor r9d, r9d
    xor r8d, r8d
    xor edx, edx
    lea rcx, [rsp+40]
    call GetMessageW
    test eax, eax
    jle gui_fail

    ; Give the frame dialog keyboard behaviour: Tab walks the controls and
    ; Enter presses the default button. Neither works from a bare message loop.
    lea rdx, [rsp+40]
    mov rcx, rbx
    call IsDialogMessageW
    test eax, eax
    jnz msg_loop

    lea rcx, [rsp+40]
    call TranslateMessage
    lea rcx, [rsp+40]
    call DispatchMessageW
    jmp msg_loop

gui_fail:
    add rsp, 216
    pop rbp
    pop rdi
    pop rsi
    pop rbx
    ret
RunGuiAsm endp

end
