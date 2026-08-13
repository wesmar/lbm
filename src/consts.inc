; ==============================================================================
; LBM (Lenovo Battery Manager) - Pure x64 Assembly Edition
; Master Constant definitions & Win32 API Equates
;
; Author: Marek Wesolowski - WESMAR, 2026
; ==============================================================================

; --- Windows Constants ---
STD_INPUT_HANDLE        equ -10
STD_OUTPUT_HANDLE       equ -11
STD_ERROR_HANDLE        equ -12
ATTACH_PARENT_PROCESS   equ -1

FILE_TYPE_CHAR          equ 2
INVALID_HANDLE_VALUE    equ -1

KEY_READ                equ 20019h
KEY_SET_VALUE           equ 00002h
REG_SZ                  equ 1
REG_DWORD               equ 4
ERROR_SUCCESS           equ 0
ERROR_NO_MORE_ITEMS     equ 259

HWND_BROADCAST          equ 0FFFFh
WM_SETTINGCHANGE        equ 001Ah
SMTO_ABORTIFHUNG        equ 00002h

GENERIC_READ            equ 80000000h
GENERIC_WRITE           equ 40000000h
FILE_SHARE_READ         equ 00000001h
FILE_SHARE_WRITE        equ 00000002h
OPEN_EXISTING           equ 3

; --- Lenovo PM driver protocol (\\.\IBMPmDrv) ---
; Payloads encode the primary battery in bits 8..9 and the percentage in
; bits 0..7.  Charge mode 0 is automatic (charge to 100%); 101h selects
; explicit thresholds for battery 1.
IOCTL_LBM_SET_CHARGE_MODE equ 0022261Ch
IOCTL_LBM_SET_START       equ 00222630h
IOCTL_LBM_SET_STOP        equ 00222638h
LBM_PRIMARY_BATTERY       equ 00000100h
LBM_THRESHOLD_MODE        equ 00000101h
LBM_AUTO_MODE             equ 00000000h

; The driver validates thresholds as 0..99 and answers 100 with result bit 31
; set, so the neutral "no threshold" value pushed on release is zero.
LBM_MAX_THRESHOLD         equ 99
LBM_RELEASE_THRESHOLD     equ 0

; --- DWM, Mica & Rounded Corners Constants ---
DWMWA_USE_IMMERSIVE_DARK_MODE equ 20
DWMWA_WINDOW_CORNER_PREFERENCE equ 33
DWMWA_SYSTEMBACKDROP_TYPE     equ 38

DWMWCP_ROUND                  equ 2
DWMSBT_MAINWINDOW             equ 2

; --- Shell & UAC Constants ---
SEE_MASK_NOCLOSEPROCESS equ 00000040h

; --- GUI Control IDs ---
ID_SLIDER_START         equ 101
ID_SLIDER_STOP          equ 102
ID_BTN_APPLY            equ 103
ID_BTN_DISABLE          equ 104
ID_LBL_START_VAL        equ 105
ID_LBL_STOP_VAL         equ 106
ID_LBL_STATUS           equ 107
ID_CHK_ENABLE           equ 108
ID_BTN_DEFAULTS         equ 109

; --- Window layout (logical units at 96 DPI, scaled by SCALE_ARG/SCALE_D) ---
; Every row starts at LBM_MARGIN and ends at LBM_MARGIN + LBM_CONTENT_W, so the
; frame is sized from the client area rather than the other way round.
LBM_CLIENT_W            equ 400
LBM_CLIENT_H            equ 330
LBM_MARGIN              equ 20
LBM_CONTENT_W           equ 360
LBM_LBL_W               equ 240
LBM_VAL_X               equ 260
LBM_VAL_W               equ 120
LBM_BTN_W               equ 112
LBM_BTN_X1              equ 20
LBM_BTN_X2              equ 144
LBM_BTN_X3              equ 268

; --- Window styles ---
WS_CHILD_VISIBLE        equ 50000000h
WS_TABSTOP              equ 00010000h
SS_RIGHT                equ 00000002h
BS_DEFPUSHBUTTON        equ 00000001h
BS_AUTOCHECKBOX         equ 00000003h
TBS_AUTOTICKS           equ 00000001h

DM_GETDEFID             equ 00400h
DC_HASDEFID             equ 0554Ch

TBM_SETRANGE            equ 00401h
TBM_SETPOS              equ 00405h
TBM_GETPOS              equ 00400h
TBM_SETTICFREQ          equ 00414h
TBM_SETPAGESIZE         equ 00415h
TBM_SETLINESIZE         equ 00417h

; --- Threshold slider model ---
; Lenovo Vantage presents whole five-percent steps, and the sliders snap to the
; same grid so the tick marks, the labels and the applied value always agree.
LBM_STEP                equ 5
LBM_DEFAULT_START       equ 80
LBM_DEFAULT_STOP        equ 85
; Both thumbs reach 100. Parking the pair at the top is how the UI spells "no
; limit", so the released state puts both thumbs at the right end. A real limit
; therefore always has a stop of LBM_LIMIT_STOP_MAX or less, which also keeps
; the driver happy: it rejects a threshold of 100.
LBM_SLIDER_START_MIN    equ 40
LBM_SLIDER_START_MAX    equ 100
LBM_SLIDER_STOP_MIN     equ 45
LBM_SLIDER_STOP_MAX     equ 100
LBM_LIMIT_STOP_MAX      equ 95

BM_GETCHECK             equ 00F0h
BM_SETCHECK             equ 00F1h
BST_CHECKED             equ 1
BST_UNCHECKED           equ 0

DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2 equ -4

; --- Structure Definitions ---
LBM_BATTERY_THRESHOLD struct
    startPercentage     dd ?
    stopPercentage      dd ?
    startEnabled        dd ?
    stopEnabled         dd ?
    barcode             dw 64 dup(?)
LBM_BATTERY_THRESHOLD ends
LBM_BATTERY_THRESHOLD_SIZE equ 144

SHELLEXECUTEINFOW struct
    cbSize          dd ?
    fMask           dd ?
    hwnd            dq ?
    lpVerb          dq ?
    lpFile          dq ?
    lpParameters    dq ?
    lpDirectory     dq ?
    nShow           dd ?
    _pad0           dd ?
    hInstApp        dq ?
    lpIDList        dq ?
    lpClass         dq ?
    hkeyClass       dq ?
    dwHotKey        dd ?
    _pad1           dd ?
    hIcon           dq ?
    hProcess        dq ?
SHELLEXECUTEINFOW ends
