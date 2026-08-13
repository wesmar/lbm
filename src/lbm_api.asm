; ==============================================================================
; LBM (Lenovo Battery Manager) - Win32 Registry API Module (Pure x64 ASM)
;
; Purpose: Reads/Writes Lenovo Battery Charge Thresholds directly from
;          HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Lenovo\PWRMGRV\ConfKeys\Data\<BARCODE>
; Author: Marek Wesolowski - WESMAR, 2026
; ==============================================================================

option casemap:none
include consts.inc

EXTRN RegOpenKeyExW:PROC
EXTRN RegEnumKeyExW:PROC
EXTRN RegQueryValueExW:PROC
EXTRN RegSetValueExW:PROC
EXTRN RegCloseKey:PROC
EXTRN CreateFileW:PROC
EXTRN DeviceIoControl:PROC
EXTRN CloseHandle:PROC
EXTRN SendMessageTimeoutW:PROC
EXTRN DwmSetWindowAttribute:PROC

.const
str_baseKeyPath     dw 'S','O','F','T','W','A','R','E','\','W','O','W','6','4','3','2','N','o','d','e','\'
                    dw 'L','e','n','o','v','o','\','P','W','R','M','G','R','V','\','C','o','n','f','K','e','y','s','\','D','a','t','a',0
str_startPct        dw 'C','h','a','r','g','e','S','t','a','r','t','P','e','r','c','e','n','t','a','g','e',0
str_stopPct         dw 'C','h','a','r','g','e','S','t','o','p','P','e','r','c','e','n','t','a','g','e',0
str_startCtrl       dw 'C','h','a','r','g','e','S','t','a','r','t','C','o','n','t','r','o','l',0
str_stopCtrl        dw 'C','h','a','r','g','e','S','t','o','p','C','o','n','t','r','o','l',0
; MASM character constants are not C-style escaped strings. Emit each UTF-16
; backslash separately so CreateFileW receives the genuine \\.\IBMPmDrv path.
str_driverPath      dw '\','\','.','\','I','B','M','P','m','D','r','v',0
str_notifyPath      dw 'S','O','F','T','W','A','R','E','\','L','e','n','o','v','o','\','P','W','R','M','G','R','V',0

str_themesKey       dw 'S','o','f','t','w','a','r','e','\','M','i','c','r','o','s','o','f','t','\','W','i','n','d','o','w','s','\'
                    dw 'C','u','r','r','e','n','t','V','e','r','s','i','o','n','\','T','h','e','m','e','s','\','P','e','r','s','o','n','a','l','i','z','e',0
str_appsUseLight    dw 'A','p','p','s','U','s','e','L','i','g','h','t','T','h','e','m','e',0

.code

PUBLIC Lbm_GetBatteryThresholds
PUBLIC Lbm_SetBatteryThresholds
PUBLIC Lbm_NotifyDriver
PUBLIC Lbm_ApplyMicaAndDpi

; ------------------------------------------------------------------------------
; Lbm_GetBatteryThresholds
; RCX = pointer to an LBM_BATTERY_THRESHOLD result structure.
; Returns EAX = 1 on success, or zero when no compatible battery is found.
; ------------------------------------------------------------------------------
Lbm_GetBatteryThresholds proc
    push rbx
    push rsi
    push rdi
    sub rsp, 1152

    mov rsi, rcx

    test rsi, rsi
    jz gbt_fail

    ; Clear the complete result structure (four DWORDs plus WCHAR[64]).
    mov rdi, rsi
    mov ecx, LBM_BATTERY_THRESHOLD_SIZE
    xor eax, eax
    rep stosb

    ; Open the Lenovo Power Manager configuration root used by the C++ build.
    lea rax, [rsp+48]
    mov QWORD PTR [rsp+32], rax
    mov r9d, 20019h or 8         ; KEY_READ | KEY_ENUMERATE_SUBKEYS
    xor r8d, r8d
    lea rdx, str_baseKeyPath
    mov ecx, 80000002h           ; HKEY_LOCAL_MACHINE
    call RegOpenKeyExW
    test eax, eax
    jnz gbt_fail

    mov rbx, QWORD PTR [rsp+48]   ; RBX = hBaseKey

    ; Select the first subkey that actually exposes a charge threshold. This
    ; naturally skips Battery1 and other metadata-only configuration nodes.
    xor edi, edi

enum_next:
    mov dword ptr [rsp+96], 64
    mov QWORD PTR [rsp+32], 0
    mov QWORD PTR [rsp+40], 0
    mov QWORD PTR [rsp+48], 0
    mov QWORD PTR [rsp+56], 0
    lea r9, [rsp+96]
    lea r8, [rsi + LBM_BATTERY_THRESHOLD.barcode]
    mov edx, edi
    mov rcx, rbx
    call RegEnumKeyExW
    test eax, eax
    jnz enum_failed

    ; Build the complete path to the candidate battery subkey.
    lea r8, [rsp+200]
    lea r9, str_baseKeyPath
copy_b:
    mov ax, word ptr [r9]
    mov word ptr [r8], ax
    test ax, ax
    jz done_b
    add r9, 2
    add r8, 2
    jmp copy_b

done_b:
    mov word ptr [r8], '\'
    add r8, 2
    lea r9, [rsi + LBM_BATTERY_THRESHOLD.barcode]
copy_bar:
    mov ax, word ptr [r9]
    mov word ptr [r8], ax
    test ax, ax
    jz done_bar
    add r9, 2
    add r8, 2
    jmp copy_bar

done_bar:
    lea rax, [rsp+48]
    mov QWORD PTR [rsp+32], rax
    mov r9d, 20019h              ; KEY_READ
    xor r8d, r8d
    lea rdx, [rsp+200]
    mov ecx, 80000002h           ; HKEY_LOCAL_MACHINE
    call RegOpenKeyExW
    test eax, eax
    jnz enum_continue

    mov rax, QWORD PTR [rsp+48]
    mov QWORD PTR [rsp+112], rax  ; Candidate battery key handle.

    ; A candidate represents a battery only when the threshold value exists.
    mov dword ptr [rsp+96], 4
    lea rax, [rsp+96]
    mov QWORD PTR [rsp+40], rax
    lea rax, [rsi + LBM_BATTERY_THRESHOLD.startPercentage]
    mov QWORD PTR [rsp+32], rax
    lea r9, [rsp+100]
    xor r8d, r8d
    lea rdx, str_startPct
    mov rcx, QWORD PTR [rsp+112]
    call RegQueryValueExW
    test eax, eax
    jz candidate_found

    mov rcx, QWORD PTR [rsp+112]
    call RegCloseKey

enum_continue:
    inc edi
    jmp enum_next

enum_failed:
    mov rcx, rbx
    call RegCloseKey
    jmp gbt_fail

candidate_found:
    mov rdi, QWORD PTR [rsp+112] ; Preserve the selected battery key handle.
    mov rcx, rbx
    call RegCloseKey
    mov rbx, rdi

    ; Read the remaining values; the start value was read during validation.
    mov dword ptr [rsp+96], 4
    lea rax, [rsp+96]
    mov QWORD PTR [rsp+40], rax
    lea rax, [rsi + LBM_BATTERY_THRESHOLD.stopPercentage]
    mov QWORD PTR [rsp+32], rax
    lea r9, [rsp+100]
    xor r8d, r8d
    lea rdx, str_stopPct
    mov rcx, rbx
    call RegQueryValueExW

    ; Read ChargeStartControl.
    mov dword ptr [rsp+96], 4
    lea rax, [rsp+96]
    mov QWORD PTR [rsp+40], rax
    lea rax, [rsi + LBM_BATTERY_THRESHOLD.startEnabled]
    mov QWORD PTR [rsp+32], rax
    lea r9, [rsp+100]
    xor r8d, r8d
    lea rdx, str_startCtrl
    mov rcx, rbx
    call RegQueryValueExW

    ; Read ChargeStopControl.
    mov dword ptr [rsp+96], 4
    lea rax, [rsp+96]
    mov QWORD PTR [rsp+40], rax
    lea rax, [rsi + LBM_BATTERY_THRESHOLD.stopEnabled]
    mov QWORD PTR [rsp+32], rax
    lea r9, [rsp+100]
    xor r8d, r8d
    lea rdx, str_stopCtrl
    mov rcx, rbx
    call RegQueryValueExW

    mov rcx, rbx
    call RegCloseKey

    mov eax, 1
    jmp gbt_exit

gbt_fail:
    xor eax, eax

gbt_exit:
    add rsp, 1152
    pop rdi
    pop rsi
    pop rbx
    ret
Lbm_GetBatteryThresholds endp

; ------------------------------------------------------------------------------
; Lbm_SetBatteryThresholds
; ------------------------------------------------------------------------------
Lbm_SetBatteryThresholds proc
    push rbx
    push rsi
    push rdi
    sub rsp, 640

    mov esi, ecx
    mov edi, edx
    mov dword ptr [rsp+56], r8d

    ; The driver validates thresholds as 0..99.  A stop request of 100 is not a
    ; limit at all, so it has to become a release here; otherwise the registry
    ; is updated and the IOCTL that follows is rejected.
    cmp dword ptr [rsp+56], 0
    je sbt_args_ready
    cmp edi, LBM_MAX_THRESHOLD
    ja sbt_release_instead
    cmp esi, edi
    jb sbt_args_ready
    lea esi, [edi-1]             ; Keep the pair ordered for the controller.
    jmp sbt_args_ready

sbt_release_instead:
    mov dword ptr [rsp+56], 0

sbt_args_ready:
    lea rcx, [rsp+64]
    call Lbm_GetBatteryThresholds
    test eax, eax
    jz sbt_fail

    ; Releasing the limit must not destroy the user's percentages: Lenovo keeps
    ; them so the next enable restores the previous pair.  Only the control
    ; flags describe whether the thresholds are active.
    cmp dword ptr [rsp+56], 0
    jne sbt_values_ready
    mov esi, dword ptr [rsp+64 + LBM_BATTERY_THRESHOLD.startPercentage]
    mov edi, dword ptr [rsp+64 + LBM_BATTERY_THRESHOLD.stopPercentage]
    cmp esi, 40
    jb sbt_use_defaults
    cmp edi, 100
    ja sbt_use_defaults
    cmp esi, edi
    jb sbt_values_ready
sbt_use_defaults:
    mov esi, LBM_DEFAULT_START
    mov edi, LBM_DEFAULT_STOP

sbt_values_ready:
    lea r8, [rsp+224]
    lea r9, str_baseKeyPath
copy_b2:
    mov ax, word ptr [r9]
    mov word ptr [r8], ax
    test ax, ax
    jz done_b2
    add r9, 2
    add r8, 2
    jmp copy_b2

done_b2:
    mov word ptr [r8], '\'
    add r8, 2
    lea r9, [rsp+64 + LBM_BATTERY_THRESHOLD.barcode]
copy_bar2:
    mov ax, word ptr [r9]
    mov word ptr [r8], ax
    test ax, ax
    jz done_bar2
    add r9, 2
    add r8, 2
    jmp copy_bar2

done_bar2:
    lea rax, [rsp+48]
    mov QWORD PTR [rsp+32], rax
    mov r9d, KEY_SET_VALUE       ; Request only the access used by the C++ build.
    xor r8d, r8d
    lea rdx, [rsp+224]
    mov ecx, 80000002h           ; HKEY_LOCAL_MACHINE
    call RegOpenKeyExW
    test eax, eax
    jnz sbt_fail

    mov rbx, QWORD PTR [rsp+48]   ; RBX = writable battery key.

    mov dword ptr [rsp+48], esi
    lea rax, [rsp+48]
    mov QWORD PTR [rsp+32], rax ; lpData
    mov QWORD PTR [rsp+40], 4   ; cbData
    mov r9d, REG_DWORD
    xor r8d, r8d                ; Reserved
    lea rdx, str_startPct
    mov rcx, rbx
    call RegSetValueExW
    test eax, eax
    jnz sbt_close_fail

    mov dword ptr [rsp+48], edi
    lea rax, [rsp+48]
    mov QWORD PTR [rsp+32], rax
    mov QWORD PTR [rsp+40], 4
    mov r9d, REG_DWORD
    xor r8d, r8d
    lea rdx, str_stopPct
    mov rcx, rbx
    call RegSetValueExW
    test eax, eax
    jnz sbt_close_fail

    mov eax, dword ptr [rsp+56]
    mov dword ptr [rsp+48], eax
    lea rax, [rsp+48]
    mov QWORD PTR [rsp+32], rax
    mov QWORD PTR [rsp+40], 4
    mov r9d, REG_DWORD
    xor r8d, r8d
    lea rdx, str_startCtrl
    mov rcx, rbx
    call RegSetValueExW
    test eax, eax
    jnz sbt_close_fail

    mov eax, dword ptr [rsp+56]
    mov dword ptr [rsp+48], eax
    lea rax, [rsp+48]
    mov QWORD PTR [rsp+32], rax
    mov QWORD PTR [rsp+40], 4
    mov r9d, REG_DWORD
    xor r8d, r8d
    lea rdx, str_stopCtrl
    mov rcx, rbx
    call RegSetValueExW
    test eax, eax
    jnz sbt_close_fail

    mov rcx, rbx
    call RegCloseKey

    mov r8d, dword ptr [rsp+56]
    mov edx, edi
    mov ecx, esi
    call Lbm_NotifyDriver
    test eax, eax
    jz sbt_fail

    mov eax, 1
    jmp sbt_exit

sbt_close_fail:
    mov rcx, rbx
    call RegCloseKey

sbt_fail:
    xor eax, eax

sbt_exit:
    add rsp, 640
    pop rdi
    pop rsi
    pop rbx
    ret
Lbm_SetBatteryThresholds endp

; ------------------------------------------------------------------------------
; Lbm_NotifyDriver
; RCX = start percentage, EDX = stop percentage, R8D = enabled (0/1).
; Programs the Lenovo PM driver immediately, then broadcasts the legacy
; settings notification for PowerMgr.exe and other Lenovo components.
; ------------------------------------------------------------------------------
Lbm_SendBatteryIoctl proc
    ; RCX = device handle, EDX = IOCTL, R8D = DWORD payload.
    sub rsp, 88

    mov dword ptr [rsp+64], r8d
    mov dword ptr [rsp+68], 0
    mov dword ptr [rsp+72], 0

    mov QWORD PTR [rsp+56], 0
    lea rax, [rsp+72]
    mov QWORD PTR [rsp+48], rax
    mov QWORD PTR [rsp+40], 4
    lea rax, [rsp+68]
    mov QWORD PTR [rsp+32], rax
    mov r9d, 4
    lea r8, [rsp+64]
    call DeviceIoControl
    test eax, eax
    jz lbi_fail
    cmp dword ptr [rsp+72], 4
    jne lbi_fail
    test dword ptr [rsp+68], 80000000h
    jnz lbi_fail

    mov eax, 1
    jmp lbi_exit

lbi_fail:
    xor eax, eax

lbi_exit:
    add rsp, 88
    ret
Lbm_SendBatteryIoctl endp

Lbm_NotifyDriver proc
    push rbx
    push rsi
    push rdi
    push r12
    sub rsp, 72

    mov esi, ecx
    mov edi, edx
    mov r12d, r8d

    mov QWORD PTR [rsp+48], 0
    mov QWORD PTR [rsp+40], 0
    mov QWORD PTR [rsp+32], OPEN_EXISTING
    xor r9d, r9d
    mov r8d, FILE_SHARE_READ
    mov edx, GENERIC_READ
    lea rcx, str_driverPath
    call CreateFileW

    cmp rax, -1
    je nd_fail
    test rax, rax
    jz nd_fail
    mov rbx, rax

    test r12d, r12d
    jz nd_auto_mode

    ; Select explicit threshold mode for the primary battery.
    mov r8d, LBM_THRESHOLD_MODE
    mov edx, IOCTL_LBM_SET_CHARGE_MODE
    mov rcx, rbx
    call Lbm_SendBatteryIoctl
    test eax, eax
    jz nd_close_fail

    ; Lenovo applies the upper threshold first, then the lower threshold.
    mov r8d, edi
    or r8d, LBM_PRIMARY_BATTERY
    mov edx, IOCTL_LBM_SET_STOP
    mov rcx, rbx
    call Lbm_SendBatteryIoctl
    test eax, eax
    jz nd_close_fail

    mov r8d, esi
    or r8d, LBM_PRIMARY_BATTERY
    mov edx, IOCTL_LBM_SET_START
    mov rcx, rbx
    call Lbm_SendBatteryIoctl
    test eax, eax
    jz nd_close_fail
    jmp nd_close_success

nd_auto_mode:
    ; Clear the latched pair before releasing the mode, so the embedded
    ; controller re-evaluates instead of holding the previous stop threshold.
    ; The driver rejects a threshold of 100 (result bit 31 set); zero is the
    ; neutral value that means "no threshold".
    mov r8d, LBM_RELEASE_THRESHOLD
    or  r8d, LBM_PRIMARY_BATTERY
    mov edx, IOCTL_LBM_SET_STOP
    mov rcx, rbx
    call Lbm_SendBatteryIoctl

    mov r8d, LBM_RELEASE_THRESHOLD
    or  r8d, LBM_PRIMARY_BATTERY
    mov edx, IOCTL_LBM_SET_START
    mov rcx, rbx
    call Lbm_SendBatteryIoctl

    ; Automatic charge mode. This command takes a bare mode value: the battery
    ; selector carried by the threshold commands is not part of its payload,
    ; and 0x100 here leaves the pack inhibited instead of releasing it.
    mov r8d, LBM_AUTO_MODE
    mov edx, IOCTL_LBM_SET_CHARGE_MODE
    mov rcx, rbx
    call Lbm_SendBatteryIoctl
    test eax, eax
    jz nd_close_fail

nd_close_success:
    mov rcx, rbx
    call CloseHandle

    ; Keep Lenovo's user-mode components synchronized with the driver state.
    mov QWORD PTR [rsp+64], 0
    lea rax, [rsp+64]
    mov QWORD PTR [rsp+48], rax
    mov QWORD PTR [rsp+40], 1000
    mov QWORD PTR [rsp+32], SMTO_ABORTIFHUNG
    lea r9, str_notifyPath
    xor r8d, r8d
    mov edx, WM_SETTINGCHANGE
    mov ecx, HWND_BROADCAST
    call SendMessageTimeoutW

    mov eax, 1
    jmp nd_exit

nd_close_fail:
    mov rcx, rbx
    call CloseHandle

nd_fail:
    xor eax, eax

nd_exit:
    add rsp, 72
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret
Lbm_NotifyDriver endp

; ------------------------------------------------------------------------------
; Lbm_ApplyMicaAndDpi
; ------------------------------------------------------------------------------
Lbm_ApplyMicaAndDpi proc
    push rbx
    push rsi
    sub rsp, 168

    mov rbx, rcx
    mov dword ptr [rsp+48], 0

    lea rax, [rsp+40]
    mov QWORD PTR [rsp+32], rax
    mov r9d, 20019h              ; KEY_READ
    xor r8d, r8d
    lea rdx, str_themesKey
    mov ecx, 80000001h           ; HKEY_CURRENT_USER
    call RegOpenKeyExW
    test eax, eax
    jnz apply_dwm

    mov rsi, QWORD PTR [rsp+40]

    mov dword ptr [rsp+52], 4
    lea rax, [rsp+52]
    mov QWORD PTR [rsp+40], rax
    lea rax, [rsp+56]
    mov QWORD PTR [rsp+32], rax
    lea r9, [rsp+120]
    xor r8d, r8d
    lea rdx, str_appsUseLight
    mov rcx, rsi
    call RegQueryValueExW

    test eax, eax
    jnz close_thm

    cmp dword ptr [rsp+56], 0
    jne close_thm
    mov dword ptr [rsp+48], 1

close_thm:
    mov rcx, rsi
    call RegCloseKey

apply_dwm:
    mov r9d, 4
    lea r8, [rsp+48]
    mov edx, DWMWA_USE_IMMERSIVE_DARK_MODE
    mov rcx, rbx
    call DwmSetWindowAttribute

    mov dword ptr [rsp+60], DWMSBT_MAINWINDOW
    mov r9d, 4
    lea r8, [rsp+60]
    mov edx, DWMWA_SYSTEMBACKDROP_TYPE
    mov rcx, rbx
    call DwmSetWindowAttribute

    add rsp, 168
    pop rsi
    pop rbx
    ret
Lbm_ApplyMicaAndDpi endp

end
