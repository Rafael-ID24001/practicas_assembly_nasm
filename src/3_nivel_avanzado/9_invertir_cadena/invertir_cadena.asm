; ============================================================
; ####### EJERCICIO 9 #######
; ============================================================
; PROGRAMA: Inversion de una Cadena de Texto
; Archivo: invertir_cadena.asm
; Descripcion: La cadena se define en .data (en la variable cadena) 
;              con cualquier contenido y longitud hasta 255 caracteres.
;              El programa calcula su tamanio dinamicamente buscando el byte nulo (0),
;              luego invierte con PILA (PUSH/POP) y la imprime.
; Compilar: nasm -f elf64 invertir_cadena.asm -o invertir_cadena.o
; Enlazar:  ld invertir_cadena.o -o invertir_cadena
; Ejecutar: ./invertir_cadena
; ============================================================

; ------------------------------------------------------------
; SECCION .data — datos inicializados en memoria
; ------------------------------------------------------------
section .data

    ; (*) UNICA LINEA QUE SE PUEDE EDITAR para cambiar la cadena.
    ;     Puede tener cualquier longitud. siempre dejar 0 al final.
    cadena      db 'Anona', 0         ; (*)

    lbl_orig    db 'Original : '        ; Etiqueta de la cadena original
    long_lbl_o  equ $ - lbl_orig        ; Longitud de la etiqueta

    lbl_inv     db 'Invertida: '        ; Etiqueta de la cadena invertida
    long_lbl_i  equ $ - lbl_inv         ; Longitud de la etiqueta

    salto       db 0x0A                 ; Caracter de nueva linea

; ------------------------------------------------------------
; SECCION .bss --- memoria reservada (sin inicializar)
; ------------------------------------------------------------
section .bss
    buffer_inv  resb 256    ; Buffer para la cadena invertida (hasta 255 caracteres)

; ------------------------------------------------------------
; SECCION .text --- codigo ejecutable
; ------------------------------------------------------------
section .text
    global _start

; ============================================================
; _start --- punto de entrada del programa
; ============================================================
_start:

    ; ----------------------------------------------------------
    ; PASO 1: Calcular la longitud de la cadena dinamicamente
    ;
    ; Recorremos la cadena byte a byte hasta encontrar el 0x00
    ; (terminador nulo). No usamos ninguna constante de longitud.
    ; Al terminar, R12 = numero de caracteres reales.
    ; ----------------------------------------------------------
    mov rsi, cadena         ; RSI apunta al inicio de la cadena
    xor r12, r12            ; R12 = 0, sera el contador de longitud

.calcular_longitud:
    cmp byte [rsi], 0       ; ¿El byte actual es el nulo terminador?
    je  .longitud_lista     ; Si es 0, terminamos de contar
    inc r12                 ; Si no, incrementamos la longitud
    inc rsi                 ; Avanzamos al siguiente byte
    jmp .calcular_longitud  ; Repetimos

.longitud_lista:
    ; RSI apunta ahora al nulo. R12 = longitud real de la cadena.
    ; Ej: 'UES-FMO',0  →  R12 = 7
    ; Ej: 'Hola Mundo', 0 → R12 = 10

    ; ----------------------------------------------------------
    ; PASO 2: Imprimir etiqueta + cadena original
    ; ----------------------------------------------------------
    mov rax, 1
    mov rdi, 1
    mov rsi, lbl_orig
    mov rdx, long_lbl_o
    syscall

    mov rax, 1
    mov rdi, 1
    mov rsi, cadena         ; Imprimimos desde el inicio de la cadena
    mov rdx, r12            ; Exactamente R12 bytes (longitud calculada)
    syscall

    mov rax, 1              ; Salto de linea tras la cadena original
    mov rdi, 1
    mov rsi, salto
    mov rdx, 1
    syscall

    ; ----------------------------------------------------------
    ; PASO 3: Apilar la cadena byte a byte (PUSH)
    ;
    ; Recorremos de izquierda a derecha empujando cada caracter.
    ; La pila (LIFO) los devolvera en orden INVERSO al hacer POP.
    ; ----------------------------------------------------------
    mov rcx, r12            ; RCX = cantidad de caracteres a apilar
    mov rsi, cadena         ; RSI = direccion base de la cadena

.bucle_push:
    movzx rax, byte [rsi]   ; Carga el byte actual (zero-extend a 64 bits)
    push rax                ; Apila el caracter; RSP -= 8
    inc rsi                 ; Avanza al siguiente caracter
    dec rcx                 ; Decrementa el contador
    jnz .bucle_push         ; Continua hasta apilar toda la cadena

    ; ----------------------------------------------------------
    ; PASO 4: Desapilar al buffer de salida (POP)
    ;
    ; Cada POP extrae el ultimo caracter apilado,
    ; construyendo la cadena en orden inverso en buffer_inv.
    ; ----------------------------------------------------------
    mov rcx, r12            ; RCX = cantidad de caracteres a desapilar
    mov rdi, buffer_inv     ; RDI = direccion del buffer de salida

.bucle_pop:
    pop rax                 ; Extrae de la cima; RSP += 8
    mov [rdi], al           ; *Escribe el byte bajo (AL) en el buffer
    inc rdi                 ; Avanza en el buffer
    dec rcx
    jnz .bucle_pop

    ; ----------------------------------------------------------
    ; PASO 5: Imprimir etiqueta + cadena invertida
    ; ----------------------------------------------------------
    mov rax, 1
    mov rdi, 1
    mov rsi, lbl_inv
    mov rdx, long_lbl_i
    syscall

    mov rax, 1
    mov rdi, 1
    mov rsi, buffer_inv
    mov rdx, r12            ; Misma longitud, ahora en orden inverso
    syscall

    mov rax, 1              ; Salto de linea final
    mov rdi, 1
    mov rsi, salto
    mov rdx, 1
    syscall

    ; ----------------------------------------------------------
    ; PASO 6: Salir limpiamente
    ; ----------------------------------------------------------
    mov rax, 60
    xor rdi, rdi
    syscall