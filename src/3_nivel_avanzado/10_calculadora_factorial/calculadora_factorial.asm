; ============================================================
; Programa: Calculadora de Factorial (Estructura de Funcion) 
; Descripción: Calcula el factorial de un numero (1-5) usando
;              una subrutina llamada calcular_factorial.
;              El numero se define como variable fija en .data
; Compilar:  nasm -f elf64 calculadora_factorial.asm -o calculadora_factorial.o
; Enlazar:   ld calculadora_factorial.o -o calculadora_factorial
; Ejecutar:  ./calculadora_factorial
; ============================================================

; ──────────────────────────────────────────────────────────
; SECCION .data  ---  datos inicializados
; ──────────────────────────────────────────────────────────
section .data
    ;  VARIABLE FIJA: cambia este valor entre 1 y 5
    numero          db  4               ; numero del que se calculara el factorial

    ; Etiqueta de entrada: "Factorial de X = "
    msg_de          db  "Factorial de "     ; primera parte del mensaje
    len_de          equ $ - msg_de
    msg_signo_igual db  " = "              ; separador entre el numero y el resultado
    len_signo_igual equ $ - msg_signo_igual

; ──────────────────────────────────────────────────────────
; SECCION .bss  ---  datos NO inicializados (reserva de espacio)
; ──────────────────────────────────────────────────────────
section .bss
    ; Buffer para convertir cualquier entero a texto ASCII
    buffer  resb    20

; ──────────────────────────────────────────────────────────
; SECCION .text  ---  código ejecutable
; ──────────────────────────────────────────────────────────
section .text
    global _start           ; punto de entrada visible para el enlazador

; ============================================================
; SUBRUTINA: calcular_factorial
; ─────────────────────────────
; Entrada  : RBX = numero entero n  (1 ≤ n ≤ 5)
; Salida   : RAX = n!
; Registros modificados: RAX, RCX
; ============================================================
calcular_factorial:
    ; ── Caso base: si n ≤ 1,  factorial = 1 ──────────────────
    cmp rbx, 1              ; compara n con 1
    jle .base               ;  si n ≤ 1, salta al caso base

    ; ── Caso general: bucle iterativo  n * (n-1) * … * 1 ────
    mov rax, 1              ; acumulador del producto (comienza en 1)
    mov rcx, rbx            ; RCX = contador del bucle (desde n hasta 1)

.bucle:
    imul rax, rcx           ;  RAX = RAX × RCX  (multiplicación con signo)
    dec rcx                 ; decrementa el contador: RCX--
    cmp rcx, 1              ; ¿el contador es mayor que 1?
    jg  .bucle              ; si RCX > 1, repite el bucle

    ret                     ;  retorna --- RAX contiene n!

.base:
    mov rax, 1              ; 0! = 1  y  1! = 1
    ret                     ; retorna --- RAX = 1

; ============================================================
; SUBRUTINA: imprimir_entero
; ──────────────────────────
; Entrada  : RAX = numero entero a imprimir (sin salto de linea)
; Salida   : ninguna
; Registros modificados: RAX, RCX, RDX, RSI, RDI (syscall)
; ============================================================
imprimir_entero:
    ; Apuntamos al final del buffer y llenamos de derecha a izquierda
    lea rsi, [buffer + 19]  ; RSI apunta al ultimo byte del buffer
    mov rcx, 10             ; divisor = 10 (base decimal)

.conv:
    xor rdx, rdx            ;  limpiar RDX antes de DIV (obligatorio en x86-64)
    div rcx                 ; RAX = cociente,  RDX = resto (digito actual)
    add dl, '0'             ;  digito numerico --- caracter ASCII
    mov [rsi], dl           ; almacena el caracter en el buffer
    dec rsi                 ; retrocede una posición en el buffer
    test rax, rax           ; ¿quedan mas digitos? (¿cociente = 0?)
    jnz .conv               ; si RAX ≠ 0, extrae el siguiente digito

    inc rsi                 ;  ajuste: RSI apunta al primer digito valido

    ; Calcular longitud y escribir con sys_write
    lea rdx, [buffer + 20]  ; RDX = dirección posterior al buffer
    sub rdx, rsi            ;  RDX = longitud real de la cadena numerica
    mov rdi, 1              ; descriptor 1 --- stdout
    mov rax, 1              ; syscall sys_write
    syscall                 ; imprime el numero en pantalla

    ret                     ; retorna al llamador

; ============================================================
; PUNTO DE ENTRADA PRINCIPAL: _start
; ============================================================
_start:
    ; ── 1. Cargar la variable fija desde .data en RBX ────────
    movzx rbx, byte [numero]    ;  lee 'numero' y lo extiende a 64 bits sin signo
                                ;   evita basura en los bits superiores de RBX

    ; ── 2. Llamar a la subrutina de factorial ─────────────────
    call calcular_factorial     ; resultado en RAX = n!

    ; ── 3. Preservar el resultado en R12 ──────────────────────
    ;    R12 es callee-saved: las syscalls no lo modifican
    mov r12, rax                ; R12 = factorial calculado

    ; ── 4. Imprimir "Factorial de " ───────────────────────────
    mov rdx, len_de             ; RDX = longitud de "Factorial de "
    mov rsi, msg_de             ; RSI = dirección de la cadena
    mov rdi, 1                  ; stdout
    mov rax, 1                  ; sys_write
    syscall                     ; imprime la primera parte del mensaje

    ; ── 5. Imprimir el numero de entrada (n) ──────────────────
    movzx rax, byte [numero]    ;  carga nuevamente 'numero' en RAX para imprimirlo
    call imprimir_entero        ; imprime el digito (ej: "5")

    ; ── 6. Imprimir " = " ─────────────────────────────────────
    mov rdx, len_signo_igual    ; RDX = longitud de " = "
    mov rsi, msg_signo_igual    ; RSI = dirección de la cadena
    mov rdi, 1                  ; stdout
    mov rax, 1                  ; sys_write
    syscall                     ; imprime el separador

    ; ── 7. Imprimir el resultado del factorial ─────────────────
    mov rax, r12                ; RAX = factorial preservado en R12
    call imprimir_entero        ; imprime el resultado (ej: "120")

    ; ── 8. Imprimir salto de linea final ──────────────────────
    lea rsi, [buffer + 19]      ; reutilizamos el buffer
    mov byte [rsi], 10          ; '\n' en ASCII
    mov rdx, 1                  ; longitud = 1 byte
    mov rdi, 1                  ; stdout
    mov rax, 1                  ; sys_write
    syscall                     ; imprime el salto de linea

    ; ── 9. Finalizar el proceso con código de salida 0 ────────
    mov rax, 60                 ; RAX = 60 --- syscall sys_exit
    xor rdi, rdi                ; RDI = 0  --- código de salida (exito)
    syscall                     ;  termina el programa
