;=====================================================================================
; x64dbg plugin SDK for Masm - fearless 2016 - www.LetTheLight.in
;
; StepInt3.asm
;
;-------------------------------------------------------------------------------------

.686
.MMX
.XMM
.model flat,stdcall
option casemap:none

;DEBUG32 EQU 1

IFDEF DEBUG32
    PRESERVEXMMREGS equ 1
    includelib M:\Masm32\lib\Debug32.lib
    DBG32LIB equ 1
    DEBUGEXE textequ <'M:\Masm32\DbgWin.exe'>
    include M:\Masm32\include\debug32.inc
ENDIF

Include x64dbgpluginsdk.inc               ; Main x64dbg Plugin SDK for your program, and prototypes for the main exports 

Include StepInt3.inc ; plugin's include file

pluginit	        PROTO C :DWORD        ; Required prototype and export for x64dbg plugin SDK
plugstop            PROTO C               ; Required prototype and export for x64dbg plugin SDK
plugsetup           PROTO C :DWORD        ; Required prototype and export for x64dbg plugin SDK
;=====================================================================================


.CONST
PLUGIN_VERSION      EQU 1

.DATA
PLUGIN_NAME         DB "StepInt3",0

.DATA?
;-------------------------------------------------------------------------------------
; GLOBAL Plugin SDK variables
;-------------------------------------------------------------------------------------
PUBLIC              pluginHandle
PUBLIC              hwndDlg
PUBLIC              hMenu
PUBLIC              hMenuDisasm
PUBLIC              hMenuDump
PUBLIC              hMenuStack

pluginHandle        DD ?
hwndDlg             DD ?
hMenu               DD ?
hMenuDisasm         DD ?
hMenuDump           DD ?
hMenuStack          DD ?
;-------------------------------------------------------------------------------------


.CODE

;=====================================================================================
; Main entry function for a DLL file  - required.
;-------------------------------------------------------------------------------------
DllEntry PROC hInst:HINSTANCE, reason:DWORD, reserved:DWORD
    .IF reason == DLL_PROCESS_ATTACH
        mov eax, hInst
        mov hInstance, eax
    .ENDIF
    mov eax,TRUE
    ret
DllEntry Endp


;=====================================================================================
; pluginit - Called by debugger when plugin.dp32 is loaded - needs to be EXPORTED
; 
; Arguments: initStruct - a pointer to a PLUG_INITSTRUCT structure
;
; Notes:     you must fill in the pluginVersion, sdkVersion and pluginName members. 
;            The pluginHandle is obtained from the same structure - it may be needed in
;            other function calls.
;
;            you can call your own setup routine from within this function to setup 
;            menus and commands, and pass the initStruct parameter to this function.
;
;-------------------------------------------------------------------------------------
pluginit PROC C PUBLIC USES EBX initStruct:DWORD
    mov ebx, initStruct

    ; Fill in required information of initStruct, which is a pointer to a PLUG_INITSTRUCT structure
    mov eax, PLUGIN_VERSION
    mov [ebx].PLUG_INITSTRUCT.pluginVersion, eax
    mov eax, PLUG_SDKVERSION
    mov [ebx].PLUG_INITSTRUCT.sdkVersion, eax
    Invoke lstrcpy, Addr [ebx].PLUG_INITSTRUCT.pluginName, Addr PLUGIN_NAME
    
    mov ebx, initStruct
    mov eax, [ebx].PLUG_INITSTRUCT.pluginHandle
    mov pluginHandle, eax
    
    ; Do any other initialization here
    ; Construct plugin's .ini file from module filename
    Invoke GetModuleFileName, hInstance, Addr StepInt3Ini, SIZEOF StepInt3Ini
    Invoke lstrlen, Addr StepInt3Ini
    lea ebx, StepInt3Ini
    add ebx, eax
    sub ebx, 4 ; move back past 'dp32' extention
    mov byte ptr [ebx], 0 ; null so we can use lstrcat
    Invoke lstrcat, ebx, Addr szIni ; add 'ini' to end of string instead    
    
	mov eax, TRUE
	ret
pluginit endp


;=====================================================================================
; plugstop - Called by debugger when the plugin.dp32 is unloaded - needs to be EXPORTED
;
; Arguments: none
; 
; Notes:     perform cleanup operations here, clearing menus and other housekeeping
;
;-------------------------------------------------------------------------------------
plugstop PROC C PUBLIC 
    
    ; remove any menus, unregister any callbacks etc
    Invoke _plugin_menuclear, hMenu
    Invoke GuiAddLogMessage, Addr szPluginUnloaded
    
    mov eax, TRUE
    ret
plugstop endp


;=====================================================================================
; plugsetup - Called by debugger to initialize your plugins setup - needs to be EXPORTED
;
; Arguments: setupStruct - a pointer to a PLUG_SETUPSTRUCT structure
; 
; Notes:     setupStruct contains useful handles for use within x64_dbg, mainly Qt 
;            menu handles (which are not supported with win32 api) and the main window
;            handle with this information you can add your own menus and menu items 
;            to an existing menu, or one of the predefined supported right click 
;            context menus: hMenuDisam, hMenuDump & hMenuStack
;            
;            plugsetup is called after pluginit. 
;-------------------------------------------------------------------------------------
plugsetup PROC C PUBLIC USES EBX setupStruct:DWORD
    LOCAL hIconData:ICONDATA
    
    mov ebx, setupStruct

    ; Extract handles from setupStruct which is a pointer to a PLUG_SETUPSTRUCT structure  
    mov eax, [ebx].PLUG_SETUPSTRUCT.hwndDlg
    mov hwndDlg, eax
    mov eax, [ebx].PLUG_SETUPSTRUCT.hMenu
    mov hMenu, eax
    mov eax, [ebx].PLUG_SETUPSTRUCT.hMenuDisasm
    mov hMenuDisasm, eax
    mov eax, [ebx].PLUG_SETUPSTRUCT.hMenuDump
    mov hMenuDump, eax
    mov eax, [ebx].PLUG_SETUPSTRUCT.hMenuStack
    mov hMenuStack, eax

    ; Do any setup here: add menus, menu items, callback and commands etc
    Invoke GuiAddLogMessage, Addr szStepInt3Info
    Invoke _plugin_menuaddentry, hMenu, MENU_STEPINT3, Addr szStepInt3

    Invoke StepInt3LoadMenuIcon, IMG_STEPINT3, Addr hIconData
    .IF eax == TRUE
        Invoke _plugin_menuseticon, hMenu, Addr hIconData
    .ENDIF    

    Invoke StepInt3LoadMenuIcon, IMG_MENU_CHECK, Addr hImgCheck
    Invoke StepInt3LoadMenuIcon, IMG_MENU_NOCHECK, Addr hImgNoCheck
    
    Invoke IniGetStepInt3Enabled
    mov g_StepInt3Enabled, eax
    .IF eax == 1
        Invoke _plugin_menuentryseticon, pluginHandle, MENU_STEPINT3, Addr hImgCheck
        Invoke GuiAddLogMessage, Addr szLogStepInt3Enabled
    .ELSE
        Invoke _plugin_menuentryseticon, pluginHandle, MENU_STEPINT3, Addr hImgNoCheck
        Invoke GuiAddLogMessage, Addr szLogStepInt3Disabled
    .ENDIF
    
    mov eax, TRUE
    ret
plugsetup endp


;=====================================================================================
; CBMENUENTRY - Called by debugger when a menu item is clicked - needs to be EXPORTED
;
; Arguments: cbType
;            cbInfo - a pointer to a PLUG_CB_MENUENTRY structure. The hEntry contains 
;            the resource id of menu item identifiers
;  
; Notes:     hEntry can be used to determine if the user has clicked on your plugins
;            menu item(s) and to do something in response to it.
;            Needs to be PROC C type procedure call to be compatible with debugger
;-------------------------------------------------------------------------------------
CBMENUENTRY PROC C PUBLIC USES EBX cbType:DWORD, cbInfo:DWORD
    mov ebx, cbInfo
    mov eax, [ebx].PLUG_CB_MENUENTRY.hEntry
    
    .IF eax == MENU_STEPINT3
        Invoke IniGetStepInt3Enabled
        .IF eax == 1
            mov g_StepInt3Enabled, 0
            Invoke IniSetStepInt3Enabled, 0
            Invoke _plugin_menuentryseticon, pluginHandle, MENU_STEPINT3, Addr hImgNoCheck
            Invoke GuiAddLogMessage, Addr szLogStepInt3Disabled
        .ELSE
            mov g_StepInt3Enabled, 1
            Invoke IniSetStepInt3Enabled, 1
            Invoke _plugin_menuentryseticon, pluginHandle, MENU_STEPINT3, Addr hImgCheck
            Invoke GuiAddLogMessage, Addr szLogStepInt3Enabled
        .ENDIF
    .ENDIF
    mov eax, TRUE
    ret
CBMENUENTRY endp


;=====================================================================================
; CBINITDEBUG - Called by debugger when a program is debugged - needs to be EXPORTED
;
; Arguments: cbType
;            cbInfo - a pointer to a PLUG_CB_INITDEBUG structure. 
;            The szFileName item contains name of file being debugged. 
;  
; Notes:     
;            
;            Needs to be PROC C type procedure call to be compatible with debugger
;-------------------------------------------------------------------------------------
CBINITDEBUG PROC C PUBLIC USES EBX cbType:DWORD, cbInfo:DWORD
    mov ebx, cbInfo
    mov eax, [ebx]
    mov DebugFilename, eax
    mov eax, TRUE
    ret
CBINITDEBUG endp


;-------------------------------------------------------------------------------------
; CBEXCEPTION
;-------------------------------------------------------------------------------------
CBEXCEPTION PROC C PUBLIC USES EBX cbType:DWORD, cbInfo:DWORD
    LOCAL dwException:DWORD
    LOCAL bii:BASIC_INSTRUCTION_INFO ; basic 
    
    .IF g_StepInt3Enabled == 0 ; is it disabled?
        mov eax, TRUE
        ret
    .ENDIF
    
    mov ebx, cbInfo
    mov ebx, [ebx].PLUG_CB_EXCEPTION.Exception ; rbx is pointer to EXCEPTION_DEBUG_INFO
    mov eax, [ebx] ; exception code in eax
    mov dwException, eax

    .IF dwException == EXCEPTION_BREAKPOINT ; 80000003h
        IFDEF DEBUG32
        PrintText 'EXCEPTION_BREAKPOINT'
        ENDIF
        ; Get current address and then module name from that address
        Invoke GuiSelectionGet, GUI_DISASSEMBLY, Addr sel
        _DbgFunctions ModPathFromAddr, sel.start, Addr szModuleFilename, MAX_PATH        
        
        ; check we arent in ntdll.dll
        Invoke InString, 1, Addr szModuleFilename, Addr szNtdll
        .IF eax > 0
            IFDEF DEBUG32
            PrintText 'NTDLL.DLL'
            ENDIF
            ; we are, so swallow exception and continue onwards
            
            Invoke DbgCmdExec, Addr szCon
            Invoke DbgCmdExec, Addr szRun
            Invoke GuiAddLogMessage, Addr szStepInt3NtdllSkipping
            mov eax, TRUE
            ret
        .ENDIF
        
        IFDEF DEBUG32
        PrintStringByAddr DebugFilename
        PrintString szModuleFilename
        ENDIF
        ; not in ntdll.dll, so check modulename = name passed on cbdebuginit, just to be sure we are ok
        Invoke szCmp, DebugFilename, Addr szModuleFilename
        .IF eax == 0
        .ELSE
            ; disassemble the instruction at the breakpoint_exception address and copy it to a string
            Invoke DbgDisasmFastAt, sel.start, Addr bii
            lea ebx, bii.instruction
            Invoke szCopy, ebx, Addr szInstruction
            
            ; compare to see if its an int3 instruction, if so we skip it and tell user in the log
            Invoke szCmp, Addr szInstruction, Addr szInt3
            .IF eax == 0 ;  mo match
                IFDEF DEBUG32
                PrintText 'No Match with Int3'
                PrintString szInstruction
                ENDIF
            .ELSE
                Invoke DbgCmdExec, Addr szSkip
                ;Invoke DbgCmdExec, Addr szCon
                Invoke GuiAddLogMessage, Addr szStepInt3FoundSkipping        
            .ENDIF
        .ENDIF

    .ENDIF

    mov eax, TRUE
    ret
CBEXCEPTION endp


;=====================================================================================
; StepInt3LoadMenuIcon - Loads RT_RCDATA png resource and assigns it to ICONDATA
; Returns TRUE in eax if succesful or FALSE otherwise.
;-------------------------------------------------------------------------------------
StepInt3LoadMenuIcon PROC PUBLIC USES EBX dqImageResourceID:DWORD, lpIconData:DWORD
    LOCAL hRes:DWORD
    
    ; Load image for our menu item
    Invoke FindResource, hInstance, dqImageResourceID, RT_RCDATA ; load png image as raw data
    .IF eax != NULL
        mov hRes, eax
        Invoke SizeofResource, hInstance, hRes
        .IF eax != 0
            mov ebx, lpIconData
            mov [ebx].ICONDATA.size_, eax
            Invoke LoadResource, hInstance, hRes
            .IF eax != NULL
                Invoke LockResource, eax
                .IF eax != NULL
                    mov ebx, lpIconData
                    mov [ebx].ICONDATA.data, eax
                    mov eax, TRUE
                .ELSE
                    ;PrintText 'Failed to lock resource'
                    mov eax, FALSE
                .ENDIF
            .ELSE
                ;PrintText 'Failed to load resource'
                mov eax, FALSE
            .ENDIF
        .ELSE
            ;PrintText 'Failed to get resource size'
            mov eax, FALSE
        .ENDIF
    .ELSE
        ;PrintText 'Failed to find resource'
        mov eax, FALSE
    .ENDIF    
    ret

StepInt3LoadMenuIcon ENDP


;**************************************************************************
; IniGetStepInt3Enabled
;**************************************************************************
IniGetStepInt3Enabled PROC
    Invoke GetPrivateProfileInt, Addr szStepInt3, Addr szEnabled, 1, Addr StepInt3Ini
    ret
IniGetStepInt3Enabled ENDP


;**************************************************************************
; IniSetStepInt3Enabled
;**************************************************************************
IniSetStepInt3Enabled PROC dwValue:DWORD
    .IF dwValue == 1
        Invoke WritePrivateProfileString, Addr szStepInt3, Addr szEnabled, Addr szOne, Addr StepInt3Ini
    .ELSE
        Invoke WritePrivateProfileString, Addr szStepInt3, Addr szEnabled, Addr szZero, Addr StepInt3Ini
    .ENDIF
    mov eax, dwValue
    ret
IniSetStepInt3Enabled ENDP



END DllEntry
















