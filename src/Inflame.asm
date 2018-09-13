format PE console
entry main

include 'INCLUDE/win32ax.inc'

section '.text' code executable

proc main
    locals
        argc    dd ?
        argv    dd ?
        env     dd ?
    endl

    cinvoke __getmainargs, [argc], [argv], [env], 0
    cmp [argc], 3
    jne error
    stdcall inject
    invoke ExitProcess, 0
    ret
endp

error:
    invoke ExitProcess, 1

proc inject
    mov esi, [argv]
    invoke GetFullPathNameA, dword [esi + 4], MAX_PATH, dllPath, 0
    cinvoke strlen, dllPath
    inc eax
    mov [dllPathLength], eax
    mov esi, [argv]
    invoke OpenProcess, PROCESS_VM_WRITE + PROCESS_VM_OPERATION + PROCESS_QUERY_INFORMATION + PROCESS_CREATE_THREAD, FALSE, <cinvoke atoi, dword [esi + 8]>
    mov [processHandle], eax
    invoke VirtualAllocEx, [processHandle], NULL, [dllPathLength], MEM_COMMIT + MEM_RESERVE, PAGE_READWRITE
    mov [allocatedMemory], eax
    invoke WriteProcessMemory, [processHandle], [allocatedMemory], dllPath, [dllPathLength], NULL
    invoke CreateRemoteThread, [processHandle], NULL, 0, <invoke GetProcAddress, <invoke GetModuleHandleA, <'kernel32.dll', 0>>, <'LoadLibraryA', 0>>, [allocatedMemory], 0, NULL
    invoke CloseHandle, [processHandle]
    ret
endp

section '.data' data readable writable

argc    dd ?
argv    dd ?
env     dd ?
dllPath rb MAX_PATH
dllPathLength dd ?
processHandle dd ?
allocatedMemory dd ?

section '.idata' data readable import

library kernel32, 'kernel32.dll', \
        msvcrt, 'msvcrt.dll'

import kernel32, \
       ExitProcess, 'ExitProcess', \
       GetFullPathNameA, 'GetFullPathNameA', \
       GetModuleHandleA, 'GetModuleHandleA', \
       GetProcAddress, 'GetProcAddress', \
       OpenProcess, 'OpenProcess', \
       VirtualAllocEx, 'VirtualAllocEx', \
       WriteProcessMemory, 'WriteProcessMemory', \
       CreateRemoteThread, 'CreateRemoteThread', \
       CloseHandle, 'CloseHandle'

import msvcrt, \
       __getmainargs, '__getmainargs', \
       printf, 'printf', \
       getchar, 'getchar', \
       strlen, 'strlen', \
       atoi, 'atoi'
