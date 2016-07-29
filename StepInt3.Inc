;=====================================================================================
; x64dbg plugin SDK for Masm - fearless 2016
;
; StepInt3.inc
;
;-------------------------------------------------------------------------------------
include windows.inc
include user32.inc
include kernel32.inc
includelib user32.lib
includelib kernel32.lib
include masm32.inc
includelib masm32.lib

StepInt3LoadMenuIcon    PROTO :DWORD, :DWORD
IniGetStepInt3Enabled   PROTO
IniSetStepInt3Enabled   PROTO :DWORD

.CONST
CRLF                TEXTEQU <13,10,0> ; carriage return and linefeed for strings that require them (GuiAddLogMessage for example) 

MENU_STEPINT3       EQU 1

ICO_STEPINT3        EQU 100
IMG_STEPINT3        EQU 101 ; PNG image for plugin menu icon
IMG_MENU_CHECK      EQU 121 ; Checkmark (tick)
IMG_MENU_NOCHECK    EQU 122 ; No checkmark, just blank space

.DATA
szStepInt3          DB "StepInt3",0
szEnabled           DB "Enabled",0
szPluginLoaded      DB "StepInt3 loaded.",CRLF
szPluginUnloaded    DB "StepInt3 unloaded.",CRLF
szStepInt3Info       DB 13,10         
                    DB "StepInt3 x32dbg plugin by fearless 2016 - www.LetTheLight.in",13,10
                    DB 13,10
                    DB "StepInt3 Features & Usage:",13,10
                    DB " - Steps over int3 instructions, swallowing the breakpoint exception.",13,10  
                    DB 13,10,0
                    
szStepInt3FoundSkipping   DB "StepInt3 - Found a int3 (breakpoint_exception), stepping over it.",CRLF
szStepInt3NtdllSkipping   DB "StepInt3 - Found a int3 (breakpoint_exception) in ntdll.dll, skipping this.",CRLF

szLogStepInt3Enabled DB "StepInt3 - Enabled",CRLF
szLogStepInt3Disabled DB "StepInt3 - Disabled",CRLF


StepInt3Ini         DB MAX_PATH DUP (0)
szModuleFilename    DB MAX_PATH DUP (0)

szIni               DB "ini",0
szOne               DB "1",0
szZero              DB "0",0
szNtdll             DB "ntdll.dll",0
szInt3              DB "int3",0
szRet               DB "ret",0
szSkip              DB "skip",0
szCon               DB "con",0
szRun               DB "run",0
szInstruction       DB MAX_PATH DUP (0)
sel                 SELECTIONDATA <>


hImgCheck           ICONDATA <> ; IMG_MENU_CHECK
hImgNoCheck         ICONDATA <> ; IMG_MENU_NOCHECK


g_StepInt3Enabled   DD 1


.DATA?
hInstance           DD ?
DbgVar              DD ?
DebugFilename       DD ?










