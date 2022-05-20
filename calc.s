section .rodata
    link_size: equ 5
    default_numstr_size: equ 8
    calcprefix: db "calc: ", 0
    err_over: db "Error: Operand Stack Overflow", 10, 0
    err_under: db "Error: Insufficient Number of Arguments on Stack", 10, 0
    octal_format: db "%o", 10, 0
    hexa_format: db "0x%X", 10, 0
    string_format: db "%s", 10, 0
    input_size: dd 82
section .bss
    head: resb 4
    numstr: resd 2
    input: resb 82
section .data
    stack_size: dd 5
    stack_len: dd 0
    debug: dd 0
    testn: dd "0", 10,0

%macro checkunder 2
    cmp dword [stack_len], 0
    jg %1
    push err_under
    call print_err
    add esp, 4
    jmp %2
%endmacro

%macro checkover 2
    mov eax, dword [stack_len]
    cmp eax, dword [stack_size]
    jl %1
    push err_over
    call print_err
    add esp, 4
    jmp %2
%endmacro

%define undopop inc dword [stack_len]

%macro peak 0
    call op_pop
    undopop
%endmacro

section .text
  align 16
  global main ; done
  extern printf
  extern fprintf 
  extern fflush
  extern malloc
  extern calloc
  extern free
  ; extern gets
  extern getchar
  extern fgets
  extern stdout
  extern stdin
  extern stderr
  global myclac ; done
  global read
  global op_pop
  global op_push
  global op_add ; done
  global op_pnp ; done
  global op_dup ; done
  global op_and ; done
  global op_nbytes ; done
  global op_mul ; ?
  global op_shl
  global pushnum ; done
  global numlen
  global rts
  global print_err
  global newlink
  global freelink
  global freeopstack
  global realloc_numstr
  global print_hexa
main:
    push ebp
    mov ebp, esp
    pushad

    mov ebx, dword [ebp + 12]
    mov eax, 1
    mov edx, 5
    

    MAIN_ARGS_LOOP: cmp eax, dword [ebp + 8]
    je CALC_START
    mov esi, dword [ebx + 4 * eax]
    cmp byte [esi + 1], 'd'
    jne MAIN_CHECK_STACK_SIZE
    mov byte [debug], 1
    MAIN_CHECK_STACK_SIZE: cmp byte [esi], '0'
    jl MAIN_NEXT_ARG
    cmp byte [esi], '9'
    jg MAIN_NEXT_ARG
    mov dl, byte [esi]
    sub edx, '0'
    cmp byte [esi + 1], '0'
    jl MAIN_NEXT_ARG
    cmp byte [esi + 1], '9'
    jg MAIN_NEXT_ARG
    shl edx, 3
    mov cl, byte [esi + 1]
    sub cl, '0'
    add dl, cl
    MAIN_NEXT_ARG: inc eax
    jmp MAIN_ARGS_LOOP

    CALC_START: mov dword [stack_size], edx
    call myclac

    push eax
    push octal_format
    call printf
    add esp, 8

    popad
    mov esp, ebp
    pop ebp
    ret

myclac: 
    push ebp
    mov ebp, esp
    sub esp, 4
    pushad

    mov eax, dword [stack_size]
    shl eax, 2
    push eax
    call malloc
    add esp, 4
    mov dword [head], eax
    mov ebx, 0

    MYCALC_READ: call read
    cmp byte [eax], 'q'
    je MYCALC_DONE
    cmp byte [eax], 'p'
    jne MYCALC_ADD
    call op_pnp
    jmp MYCALC_NEXT_OP
    MYCALC_ADD: cmp byte [eax], '+'
    jne MYCALC_DUP
    call op_add
    jmp MYCALC_NEXT_OP
    MYCALC_DUP: cmp byte [eax], 'd'
    jne MYCALC_AND
    call op_dup
    jmp MYCALC_NEXT_OP
    MYCALC_AND: cmp byte [eax], '&'
    jne MYCALC_NBYTES
    call op_and
    jmp MYCALC_NEXT_OP
    MYCALC_NBYTES: cmp byte [eax], 'n'
    jne MYCALC_MUL
    call op_nbytes
    jmp MYCALC_NEXT_OP
    MYCALC_MUL: cmp byte [eax], '*'
    jne MYCALC_NUM
    ; peak
    ; push eax
    ; call op_shl
    ; add esp, 4
    jmp MYCALC_NEXT_OP
    MYCALC_NUM: push eax
    call pushnum
    add esp, 4
    jmp MYCALC_READ
    MYCALC_NEXT_OP: inc ebx
    jmp MYCALC_READ

    MYCALC_DONE: call freeopstack
    mov dword [ebp - 4], ebx

    popad
    mov eax, dword [ebp - 4]
    add esp, 4
    mov esp, esp
    pop ebp
    ret

read: 
    push ebp
    mov ebp, esp
    sub esp, 4
    pushad

    push calcprefix
    call printf
    add esp, 4

    push dword [stdin]
    push dword [input_size]
    push input
    call fgets
    mov dword [ebp - 4], eax
    add esp, 12

    popad
    mov eax, dword [ebp - 4]
    add esp, 4
    mov esp, ebp
    pop ebp
    ret

newlink:
    push ebp
    mov ebp, esp
    sub esp, 4
    pushad

    push dword link_size
    push dword 1
    CAL: call calloc
    add esp, 8
    mov [ebp - 4], eax
    
    popad
    mov eax, dword [ebp - 4]
    add esp, 4
    mov esp, ebp
    pop ebp
    ret

freelink:
    push ebp
    mov ebp, esp
    pushad

    mov ecx, dword [ebp + 8]

    NEXT_FREE: cmp ecx, 0
    je LINK_FREED
    mov edx, dword [ecx + 1]
    pushad
    push ecx
    call free
    add esp, 4
    popad
    mov ecx, edx
    jmp NEXT_FREE

    LINK_FREED: popad
    mov esp, ebp
    pop ebp
    ret

freeopstack:
    push ebp
    mov ebp, esp
    pushad

    NEXT_LINK: cmp dword [stack_len], 0
    je ALL_FREED
    call op_pop
    push eax
    call freelink
    add esp, 4
    jmp NEXT_LINK

    ALL_FREED: push dword [head]
    call free
    add esp, 4
    popad
    mov esp, ebp
    pop ebp
    ret

realloc_numstr:
    push ebp
    mov ebp, esp
    sub esp, 4
    pushad

    mov eax, dword [numstr + 4]
    mov dword [ebp - 4], eax
    
    shl dword [numstr + 4], 1
    push 1
    push dword [numstr + 4]
    call calloc
    add esp, 8
    mov edi, eax
    mov esi, dword [numstr]
    mov ebx, dword [numstr] ; old string
    mov dword [numstr], eax

    REALLOC_COPY_BYTES: cmp byte [esi], 0
    je REALLOC_NULL
    mov cl, byte [esi]
    mov byte [edi], cl
    inc edi
    inc esi
    jmp REALLOC_COPY_BYTES

    REALLOC_NULL: push ebx
    call free
    add esp, 4

    popad
    mov eax, dword [ebp - 4]
    add esp, 4
    add eax, dword [numstr]
    dec eax
    mov esp, ebp
    pop ebp
    ret


pushnum:
    push ebp
    mov ebp, esp
    sub esp, 1 ; save octal bit counter
    pushad

    checkover DO_PUSH_NUM, NULL

    DO_PUSH_NUM: mov ecx, dword [ebp + 8]
    cmp byte [ecx], '0'
	jl NULL

    call newlink
    push eax
    call op_push
    pop ebx
    mov byte [ebp - 1], 1

    push ecx
    call numlen
    add esp, 4
    add ecx, eax

    mov dl, 1 ; link bit counter

	LOOP_COND: cmp eax, 0
    jl PUSHNUM_TRIM_CHECK
    cmp byte [ebp - 1], 1
    jne BIT
    push ecx
    mov cl, byte [ecx]
    BIT: test cl, byte [ebp - 1]
    jz NEXT
    or byte [ebx], dl
	NEXT: cmp byte [ebp - 1], 4 ; check 3rd bit
    je RESET_OCTAL_BIT_COUNTER
    shl byte [ebp - 1], 1
    jmp CHECK_BYTE_COUNTER
    RESET_OCTAL_BIT_COUNTER: mov byte [ebp - 1], 1
    dec eax
    pop ecx
    dec ecx
    CHECK_BYTE_COUNTER: cmp dl, 128 ; check 8th bit
    je RESET_BYTE_COUNTER
    shl dl, 1
    jmp LOOP_COND
    RESET_BYTE_COUNTER: mov dl, 1
    cmp eax, 0
    jl PUSHNUM_TRIM_CHECK
    push eax
    call newlink
    mov dword [ebx + 1], eax
    mov ebx, eax
    pop eax
    jmp LOOP_COND

    PUSHNUM_TRIM_CHECK: cmp byte [ebx], 0
    jne PUSHNUM_DEBUG
    cmp dword [ebx + 1], 0
    jne PUSHNUM_DEBUG
    peak
    cmp eax, ebx
    je PUSHNUM_DEBUG
    PUSHNUM_TRIM_LOOP: cmp dword [eax + 1], ebx
    je PUSHNUM_TRIM
    mov eax, dword [eax + 1]
    jmp PUSHNUM_TRIM_LOOP
    PUSHNUM_TRIM: mov dword [eax + 1], 0
    push ebx
    call free
    add esp, 4

    PUSHNUM_DEBUG: cmp dword [debug], 0
    je NULL
    call print_hexa

	NULL: popad
    add esp, 1
    mov esp, ebp
    pop ebp
    ret

numlen:
    push ebp
    mov ebp, esp
    sub esp, 4
    pushad

    mov ecx, dword [ebp + 8]
    
    mov eax, 0
    LOOP: cmp byte [ecx], '0'
    jl BREAK
    sub byte [ecx], '0'
    inc eax
    inc ecx
    jmp LOOP

    BREAK: dec eax
    mov [ebp - 4], eax
    popad
    mov eax, [ebp - 4]
    add esp, 4
    mov esp, ebp
    pop ebp
    ret

rts: 
    push ebp
    mov ebp, esp
    pushad

    mov esi, dword [numstr]
    mov edi, esi

    mov ecx, 0
    RTS_LAST_INDEX: cmp byte [esi], 0
    je RTS_REMOVE_LEADING_ZEROS
    inc esi
    inc ecx
    jmp RTS_LAST_INDEX

    RTS_REMOVE_LEADING_ZEROS: cmp byte [esi - 1], '0'
    jne RTS_START
    dec ecx
    dec esi
    mov byte [esi], 0
    jmp RTS_REMOVE_LEADING_ZEROS

    RTS_START: shr ecx, 1
    RTS_LOOP: cmp ecx, 0
    je RTS_NULL
    dec esi
    mov al, byte [esi]
    mov bl, byte [edi]   
    mov byte [edi], al
    mov byte [esi], bl
    inc edi
    dec ecx
    jmp RTS_LOOP

    RTS_NULL: popad
    mov esp, ebp
    pop ebp
    ret

print_err:
    push ebp
    mov ebp, esp
    pushad

    mov eax, [ebp + 8]
    push eax
    push dword [stderr]
    call fprintf
    add esp, 8

    popad
    mov esp, ebp
    pop ebp
    ret

op_pop:
    push ebp
    mov ebp, esp
    sub esp, 4
    pushad

    mov dword [ebp - 4], 0
    checkunder DO_POP, POP_ERR

    DO_POP: dec dword [stack_len]
    mov eax, dword [stack_len]
    shl eax, 2
    mov ebx, dword [head]
    mov ebx, dword [ebx + eax]
    mov dword [ebp - 4], ebx

    POP_ERR: popad
    mov eax, dword [ebp - 4]
    add esp, 4
    mov esp, ebp
    pop ebp
    ret

op_push:
    push ebp
    mov ebp, esp
    pushad

    checkover DO_PUSH, PUSH_ERR

    DO_PUSH: mov ecx, [ebp + 8]
    mov eax, dword [stack_len]
    shl eax, 2
    mov ebx, dword [head]
    mov dword [ebx + eax], ecx
    inc dword [stack_len]

    PUSH_ERR: popad
    mov esp, ebp
    pop ebp
    ret

op_nbytes:
    push ebp
    mov ebp, esp
    pushad

    call op_pop
    cmp eax, 0
    je NBYTES_EMPTY

    mov ebx, eax
    mov ecx, ebx
    call newlink
    push eax
    call op_push
    add esp, 4

    COUNT_LINK: cmp ebx, 0
    je NULL_NBYTES
    NBYTES_RIPPLE: inc byte [eax]
    jnz NBYTES_NEXT_LINK
    cmp dword [eax + 1], 0
    jne HAS_NEXT
    mov edx, eax
    call newlink
    mov dword [edx + 1], eax
    jmp NBYTES_RIPPLE
    HAS_NEXT: mov eax, dword [eax + 1]
    jmp NBYTES_RIPPLE
    NBYTES_NEXT_LINK: peak
    mov ebx, dword [ebx + 1]
    jmp COUNT_LINK

    NULL_NBYTES:
    push ecx
    call freelink
    add esp, 4
    cmp dword [debug], 0
    je NBYTES_EMPTY
    call print_hexa

    NBYTES_EMPTY: popad
    mov esp, ebp
    pop ebp
    ret

print_hexa:
    push ebp
    mov ebp, esp
    pushad

    call op_pop
    mov ebx, eax
    mov edx, ebx

    PNP_COND: cmp ebx, 0
    je DONE_PNP
    mov ecx, dword [ebx]
    and ecx, 0xff
    pushad
    push ecx
    push hexa_format
    call printf
    add esp, 8
    popad
    mov ebx, dword [ebx + 1]
    jmp PNP_COND

    DONE_PNP: undopop

    popad
    mov esp, ebp
    pop ebp
    ret

op_pnp:
    push ebp
    mov ebp, esp
    sub esp, 1 ; save link bit counter
    pushad

    call op_pop
    cmp eax, 0
    je PNP_ERR

    push eax 
    push dword default_numstr_size
    push dword 1
    CALPNP: call calloc
    add esp, 8
    mov dword [numstr], eax
    mov dword [numstr + 4], dword default_numstr_size
    mov ebx, 1

    pop ecx ; link pointer

    mov byte [ebp - 1], 1 ; byte link counter
    mov dl, 1 ; octal bit counter

	PNP_LOOP_COND: cmp ecx, 0
    je PNP_NULL
    cmp byte [ebp - 1], 1
    jne PNP_BIT
    push ecx
    mov cl, byte [ecx]
    PNP_BIT: test cl, byte [ebp - 1]
    jz PNP_NEXT
    or byte [eax], dl
	PNP_NEXT: cmp dl, 4 ; check 3rd bit
    je PNP_RESET_OCTAL_BIT_COUNTER
    shl dl, 1
    jmp PNP_CHECK_BYTE_COUNTER
    PNP_RESET_OCTAL_BIT_COUNTER: mov dl, 1
    add byte [eax], '0'
    inc eax
    inc ebx
    cmp ebx, dword [numstr + 4]
    jne PNP_CHECK_BYTE_COUNTER
    call realloc_numstr
    PNP_CHECK_BYTE_COUNTER: cmp byte [ebp - 1], 128 ; check 8th bit
    je PNP_RESET_BYTE_COUNTER
    shl byte [ebp - 1], 1
    jmp PNP_BIT
    PNP_RESET_BYTE_COUNTER: mov byte [ebp - 1], 1
    pop ecx
    mov ecx, dword [ecx + 1]
    jmp PNP_LOOP_COND

    PNP_NULL: cmp byte [eax], 0
    je PNP_PRINT
    add byte [eax], '0'

    PNP_PRINT: call rts
    push dword [numstr]
    push string_format
    call printf
    add esp, 8

    undopop
    call op_pop
    push eax
    call freelink
    add esp, 4

    push dword [numstr]
    call free
    add esp,4

	PNP_ERR: popad
    add esp, 1
    mov esp, ebp
    pop ebp
    ret

op_dup:
    push ebp
    mov ebp, esp
    pushad

    checkover DUP_PEAK, DUP_ERR

    DUP_PEAK: call op_pop
    cmp eax, 0
    je DUP_ERR
    undopop
    mov ebx, eax
    call newlink
    push eax
    call op_push
    add esp, 4

    DUP_BYTE: mov cl, byte [ebx]
    mov byte [eax], cl
    cmp dword [ebx + 1], 0
    je DUP_DEBUG
    mov edx, eax
    call newlink
    mov [edx + 1], eax
    mov ebx, dword [ebx + 1]
    jmp DUP_BYTE

    DUP_DEBUG: cmp dword [debug], 0
    je DUP_ERR
    call print_hexa

    DUP_ERR: popad
    mov esp, ebp
    pop ebp
    ret

op_and:
    push ebp
    mov ebp, esp
    pushad

    call op_pop
    cmp eax, 0
    je AND_ERR
    mov ebx, eax
    peak

    cmp eax, 0
    je AND_ERR
    push ebx

    AND_COND: cmp eax, 0
    je AND_FREE_1ST
    AND_CHECK_2ND: cmp ebx, 0
    mov cl, byte [ebx]
    and byte [eax], cl
    mov edx, eax
    mov eax, dword [eax + 1]
    cmp dword [ebx + 1], 0
    je AND_FREE_1ST
    mov ebx, dword [ebx + 1]
    jmp AND_COND

    AND_FREE_1ST: cmp dword [edx + 1], 0
    je AND_FREE_2ND
    push dword [edx + 1]
    call freelink
    add esp, 4
    mov dword [edx + 1], 0

    AND_FREE_2ND: call freelink
    add esp, 4

    cmp dword [debug], 0
    je ADD_ERR
    call print_hexa

    AND_ERR: popad
    mov esp, ebp
    pop ebp
    ret

op_add:
    push ebp
    mov ebp, esp
    pushad

    call op_pop
    cmp eax, 0
    je ADD_ERR
    mov ebx, eax
    peak
    cmp eax, 0
    je ADD_ERR
    
    push ebx
    add eax, 0
    pushfd
    ADD_COND: cmp ebx, 0
    je ADD_CHECK_CARRY
    mov cl, byte [ebx]
    jmp ADD_RIPPLE
    ADD_CHECK_CARRY: mov cl, 0
    popfd
    jnc ADD_FREE_1ST
    pushfd
    ADD_RIPPLE: popfd
    adc byte [eax], cl
    pushfd
    cmp dword [eax + 1], 0
    jne ADD_2ND_NEXT
    mov edx, eax
    call newlink
    mov dword [edx + 1], eax
    mov eax, edx
    ADD_2ND_NEXT: mov eax, dword [eax + 1]
    cmp ebx, 0
    je ADD_COND
    mov ebx, dword [ebx + 1]
    jmp ADD_COND

    ADD_FREE_1ST: cmp byte [eax], 0
    jne ADD_FREE_2ND
    push eax
    call freelink
    add esp, 4
    mov dword [edx + 1], 0


    ADD_FREE_2ND: call freelink
    add esp, 4

    cmp dword [debug], 0
    je ADD_ERR
    call print_hexa

    ADD_ERR: popad
    mov esp, ebp
    pop ebp
    ret

op_mul:
    ret

op_shl:
    push ebp
    mov ebp, esp
    pushad

    mov ecx, dword [ebp + 8]

    add ecx, 0
    pushfd
    SHL_LOOP: cmp ecx, 0
    je SHL_NULL
    popfd
    jnc SHL_SHIFT
    shl byte[ecx], 1
    pushfd
    or byte [ecx], 1
    jmp SHL_CHECK_CARRY
    SHL_SHIFT: shl byte [ecx], 1
    pushfd
    SHL_CHECK_CARRY: jnc SHL_NEXT
    cmp dword [ecx + 1], 0
    call newlink
    mov dword [ecx + 1], eax
    SHL_NEXT:  mov ecx, dword [ecx + 1]
    jmp SHL_LOOP

    SHL_NULL: popfd
    popad
    mov esp, ebp
    pop ebp
    ret