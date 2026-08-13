; ==============================================================================
; LBM (Lenovo Battery Manager) - Main Entry Point Module (Pure x64 ASM)
;
; Purpose: Zero-CRT entry point, English CLI dispatch, UAC check & Nudge prompt
; Author: Marek Wesolowski - WESMAR, 2026
; Language: English Output & Dialogs
; ==============================================================================

option casemap:none
include consts.inc

EXTRN GetCommandLineW:PROC
EXTRN CommandLineToArgvW:PROC
EXTRN LocalFree:PROC
EXTRN GetStdHandle:PROC
EXTRN CreateFileA:PROC
EXTRN CloseHandle:PROC
EXTRN WriteFile:PROC
EXTRN ExitProcess:PROC
EXTRN GetProcAddress:PROC
EXTRN GetModuleHandleW:PROC
EXTRN AttachConsole:PROC
EXTRN GetConsoleProcessList:PROC
EXTRN GetConsoleWindow:PROC
EXTRN ShowWindow:PROC

EXTRN EnsureAdminPrivileges:PROC
EXTRN NudgeConsolePrompt:PROC
EXTRN Lbm_GetBatteryThresholds:PROC
EXTRN Lbm_SetBatteryThresholds:PROC
EXTRN RunGuiAsm:PROC

.const
str_user32Dll      dw 'u','s','e','r','3','2','.','d','l','l',0
str_setDpiProc     db 'SetProcessDpiAwarenessContext',0
str_conoutA        db 'CONOUT$',0

str_swStatus       dw '-','-','s','t','a','t','u','s',0
str_swStatusS      dw '-','s',0
str_swSet          dw '-','-','s','e','t',0
str_swDisable      dw '-','-','d','i','s','a','b','l','e',0
str_swGui          dw '-','-','g','u','i',0
str_swGuiShort     dw '-','g',0
str_swHelp         dw '-','-','h','e','l','p',0
str_swHelpShort    dw '-','h',0

str_cliHeader      db 0Dh,0Ah,"[+] Lenovo Battery Manager (LBM) [Pure x64 Assembly Edition]",0Dh,0Ah,0
str_cliUsage       db "Usage: lbm.exe [option]",0Dh,0Ah
                   db "  lbm.exe                          Display current charge thresholds",0Dh,0Ah
                   db "  lbm.exe --status                 Display current charge thresholds",0Dh,0Ah
                   db "  lbm.exe --set <start> <stop>     Enable and set thresholds (example: 80 85)",0Dh,0Ah
                   db "  lbm.exe --disable                Disable thresholds and charge to 100%",0Dh,0Ah
                   db "  lbm.exe --gui                    Launch the Mica GUI",0Dh,0Ah
                   db "  lbm.exe --help                   Display this help",0Dh,0Ah
                   db 0Dh,0Ah,"Notes:",0Dh,0Ah
                   db "  --set and --disable elevate through UAC when required.",0Dh,0Ah
                   db "  Valid percentages are 0..100 and start must be lower than stop.",0Dh,0Ah,0

str_cliBarcode     db "[+] Battery Barcode  : ",0
str_cliStatusOn    db "[+] Threshold Status : ENABLED",0Dh,0Ah,0
str_cliStatusOff   db "[+] Threshold Status : DISABLED",0Dh,0Ah,0
str_cliStartVal    db "[+] Start Threshold  : ",0
str_cliStopVal     db "[+] Stop Threshold   : ",0
str_cliSuccess     db "[+] Success! Battery thresholds updated successfully.",0Dh,0Ah,0
str_cliFail        db "[-] Error! Administrator privileges required to change thresholds.",0Dh,0Ah,0
str_cliReadFail    db "[-] No compatible Lenovo battery threshold configuration was found.",0Dh,0Ah,0
str_cliInputFail   db "[-] Invalid thresholds. Use 0..100 and keep start lower than stop.",0Dh,0Ah,0
str_newline        db 0Dh,0Ah,0

.data?
g_hStdOut dq ?

.code

PUBLIC mainCRTStartup

AsmStrLenA proc
    xor eax, eax
len_loop:
    cmp byte ptr [rcx + rax], 0
    je len_done
    inc eax
    jmp len_loop
len_done:
    ret
AsmStrLenA endp

PrintAStr proc
    push rbx
    sub rsp, 48

    mov rbx, rcx
    test rbx, rbx
    jz pws_done

    mov rcx, rbx
    call AsmStrLenA
    mov r8d, eax

    mov QWORD PTR [rsp+32], 0
    lea r9, [rsp+40]
    mov rdx, rbx
    mov rcx, g_hStdOut
    call WriteFile

pws_done:
    add rsp, 48
    pop rbx
    ret
PrintAStr endp

PrintWStrAsA proc
    push rbx
    sub rsp, 208

    mov rbx, rcx
    lea r10, [rsp+32]

copy_loop:
    mov ax, word ptr [rbx]
    mov byte ptr [r10], al
    test ax, ax
    jz done_copy
    add rbx, 2
    inc r10
    jmp copy_loop

done_copy:
    lea rcx, [rsp+32]
    call PrintAStr

    add rsp, 208
    pop rbx
    ret
PrintWStrAsA endp

WStrCmpI proc
    push rbx
    push rsi
    sub rsp, 32

    mov rbx, rcx
    mov rsi, rdx

wsci_loop:
    mov ax, word ptr [rbx]
    mov cx, word ptr [rsi]
    test ax, ax
    jz wsci_check_end

    cmp ax, 'A'
    jb no_low1
    cmp ax, 'Z'
    ja no_low1
    add ax, 32
no_low1:
    cmp cx, 'A'
    jb no_low2
    cmp cx, 'Z'
    ja no_low2
    add cx, 32
no_low2:
    cmp ax, cx
    jne wsci_diff
    add rbx, 2
    add rsi, 2
    jmp wsci_loop

wsci_check_end:
    test cx, cx
    jnz wsci_diff
    mov eax, 1
    jmp wsci_exit

wsci_diff:
    xor eax, eax

wsci_exit:
    add rsp, 32
    pop rsi
    pop rbx
    ret
WStrCmpI endp

PrintNum proc
    sub rsp, 72
    mov eax, ecx
    lea r8, [rsp+63]
    mov byte ptr [r8], 0
    dec r8
    mov byte ptr [r8], 0Ah
    dec r8
    mov byte ptr [r8], 0Dh
    dec r8
    mov byte ptr [r8], '%'

pn_digit:
    dec r8
    xor edx, edx
    mov ecx, 10
    div ecx
    add dl, '0'
    mov byte ptr [r8], dl
    test eax, eax
    jnz pn_digit

    mov rcx, r8
    call PrintAStr

    add rsp, 72
    ret
PrintNum endp

; RCX = NUL-terminated decimal WCHAR string. EAX = 0..100 or -1 on error.
ParsePercent proc
    xor eax, eax
    xor r9d, r9d
pp_loop:
    movzx edx, word ptr [rcx]
    test edx, edx
    jz pp_done
    cmp edx, '0'
    jb pp_bad
    cmp edx, '9'
    ja pp_bad
    imul eax, eax, 10
    sub edx, '0'
    add eax, edx
    cmp eax, 100
    ja pp_bad
    inc r9d
    add rcx, 2
    jmp pp_loop
pp_done:
    test r9d, r9d
    jz pp_bad
    ret
pp_bad:
    mov eax, -1
    ret
ParsePercent endp

; Hide only a console allocated exclusively for GUI mode. A console shared
; with cmd.exe, PowerShell, or Windows Terminal is deliberately left alone.
HidePrivateConsoleForGui proc
    sub rsp, 40
    lea rcx, [rsp+32]
    mov edx, 1
    call GetConsoleProcessList
    cmp eax, 1
    jne hpc_done
    call GetConsoleWindow
    test rax, rax
    jz hpc_done
    mov rcx, rax
    xor edx, edx                ; SW_HIDE
    call ShowWindow
hpc_done:
    add rsp, 40
    ret
HidePrivateConsoleForGui endp

mainCRTStartup proc
    push rbx
    push rsi
    push rdi
    sub rsp, 400

    lea rcx, str_user32Dll
    call GetModuleHandleW
    test rax, rax
    jz dpi_done

    lea rdx, str_setDpiProc
    mov rcx, rax
    call GetProcAddress
    test rax, rax
    jz dpi_done

    mov rcx, DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2
    call rax

dpi_done:
    call GetCommandLineW
    mov rbx, rax

    lea rdx, [rsp+128]
    mov rcx, rbx
    call CommandLineToArgvW
    mov rsi, rax
    xor edi, edi
    test rsi, rsi
    jz argv_ready
    mov edi, dword ptr [rsp+128]

argv_ready:

    mov ecx, ATTACH_PARENT_PROCESS
    call AttachConsole
    mov ecx, STD_OUTPUT_HANDLE
    call GetStdHandle
    mov g_hStdOut, rax

    ; Route GUI mode before writing anything so a private console never flashes.
    cmp edi, 1
    jle run_gui_mode
    mov rdx, qword ptr [rsi + 8]
    lea rcx, str_swGui
    call WStrCmpI
    test eax, eax
    jnz run_gui_mode
    mov rdx, qword ptr [rsi + 8]
    lea rcx, str_swGuiShort
    call WStrCmpI
    test eax, eax
    jnz run_gui_mode

cli_begin:
    lea rcx, str_cliHeader
    call PrintAStr

    cmp edi, 1
    jle do_status

    mov rdx, qword ptr [rsi + 8]

    lea rcx, str_swStatus
    call WStrCmpI
    test eax, eax
    jnz do_status

    mov rdx, qword ptr [rsi + 8]
    lea rcx, str_swStatusS
    call WStrCmpI
    test eax, eax
    jnz do_status

    mov rdx, qword ptr [rsi + 8]
    lea rcx, str_swSet
    call WStrCmpI
    test eax, eax
    jnz do_set_cli

    mov rdx, qword ptr [rsi + 8]
    lea rcx, str_swDisable
    call WStrCmpI
    test eax, eax
    jnz do_disable_cli

    mov rdx, qword ptr [rsi + 8]
    lea rcx, str_swHelp
    call WStrCmpI
    test eax, eax
    jnz show_help

    mov rdx, qword ptr [rsi + 8]
    lea rcx, str_swHelpShort
    call WStrCmpI
    test eax, eax
    jnz show_help

show_help:
    lea rcx, str_cliUsage
    call PrintAStr
    jmp finish_cli

do_status:
    lea rcx, [rsp+160]
    call Lbm_GetBatteryThresholds
    test eax, eax
    jz status_err

    lea rcx, str_cliBarcode
    call PrintAStr
    lea rcx, [rsp+160 + LBM_BATTERY_THRESHOLD.barcode]
    call PrintWStrAsA
    lea rcx, str_newline
    call PrintAStr

    cmp dword ptr [rsp+160 + LBM_BATTERY_THRESHOLD.startEnabled], 0
    je stat_off
    cmp dword ptr [rsp+160 + LBM_BATTERY_THRESHOLD.stopEnabled], 0
    je stat_off
    lea rcx, str_cliStatusOn
    call PrintAStr
    jmp print_vals

stat_off:
    lea rcx, str_cliStatusOff
    call PrintAStr

print_vals:
    lea rcx, str_cliStartVal
    call PrintAStr
    mov ecx, dword ptr [rsp+160 + LBM_BATTERY_THRESHOLD.startPercentage]
    call PrintNum

    lea rcx, str_cliStopVal
    call PrintAStr
    mov ecx, dword ptr [rsp+160 + LBM_BATTERY_THRESHOLD.stopPercentage]
    call PrintNum
    jmp finish_cli

status_err:
    lea rcx, str_cliReadFail
    call PrintAStr
    jmp finish_cli

do_set_cli:
    cmp edi, 4
    jl input_err

    mov rbx, qword ptr [rsi + 16]
    mov rax, qword ptr [rsi + 24]
    mov qword ptr [rsp+120], rax

    mov rcx, rbx
    call ParsePercent
    cmp eax, -1
    je input_err
    mov ebx, eax

    mov rcx, qword ptr [rsp+120]
    call ParsePercent
    cmp eax, -1
    je input_err
    cmp ebx, eax
    jae input_err
    mov dword ptr [rsp+116], eax

    call EnsureAdminPrivileges
    test eax, eax
    jz set_err

    mov r8d, 1
    mov edx, dword ptr [rsp+116]
    mov ecx, ebx
    call Lbm_SetBatteryThresholds
    test eax, eax
    jz set_err

    lea rcx, str_cliSuccess
    call PrintAStr
    jmp finish_cli

set_err:
    lea rcx, str_cliFail
    call PrintAStr
    jmp finish_cli

input_err:
    lea rcx, str_cliInputFail
    call PrintAStr
    jmp finish_cli

do_disable_cli:
    call EnsureAdminPrivileges
    test eax, eax
    jz set_err

    mov r8d, 0
    mov edx, 100
    mov ecx, 100
    call Lbm_SetBatteryThresholds
    test eax, eax
    jz set_err
    lea rcx, str_cliSuccess
    call PrintAStr

finish_cli:
    mov rcx, rsi
    call LocalFree

    call NudgeConsolePrompt

    xor ecx, ecx
    call ExitProcess

run_gui_mode:
    mov rcx, rsi
    call LocalFree

    call HidePrivateConsoleForGui
    call EnsureAdminPrivileges
    test eax, eax
    jz gui_exit
    call RunGuiAsm

gui_exit:
    xor ecx, ecx
    call ExitProcess
mainCRTStartup endp

end
