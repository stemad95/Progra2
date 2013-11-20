;Esto es para hacer el código más legible
sys_exit        equ     1
sys_read        equ     3
sys_write       equ     4
sys_open		equ		5
stdin           equ     0
stdout          equ     1
sys_close		equ 	6
sys_brk			equ		45
sys_newstat		equ		106
sys_rename		equ		38
sys_link		equ 	9
sys_unlink		equ		10

O_RDONLY		equ		0
O_WRONLY		equ		1
O_RDWR			equ		2

struc STAT        
    .st_dev:        resd 1       
    .st_ino:        resd 1    
    .st_mode:       resw 1    
    .st_nlink:      resw 1    
    .st_uid:        resw 1    
    .st_gid:        resw 1    
    .st_rdev:       resd 1        
    .st_size:       resd 1    
    .st_blksize:    resd 1    
    .st_blocks:     resd 1    
    .st_atime:      resd 1    
    .st_atime_nsec: resd 1    
    .st_mtime:      resd 1    
    .st_mtime_nsec: resd 1
    .st_ctime:      resd 1    
    .st_ctime_nsec: resd 1    
    .unused4:       resd 1    
    .unused5:       resd 1    
endstruc

%define sizeof(x) x %+ _size

section .bss
FileBuff resb 10
stat resb sizeof(STAT)
Org_Break   resd    1
TempBuf		resd	1
nombreArch  resb	50
temp		resb	32
comandoTemp     resb    20
comando1	resb	20
comando2    resb    20
comando3    resb    20
comando4	resb	20
contador	resb	50
cantLineas	resb 	40
Res			resb	2
fileBuff1	resb	100
fileBuff2	resb	100
estado		resb	20

section .data

msjPrompt: db "PcPrompt$ "
msjPromptlen: equ $-msjPrompt

ok: db "ok"
oklen: equ $-ok


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Mensajes para hacer las comparaciones entre los comandos que se ingresan 

aceptar: db "s"
mostrar: db "mostrar"
salir: db "salir"
borrar: db "borrar"
copiar: db "copiar"
comparar: db "comparar"
renombrar: db "renombrar"
ayuda: db "--ayuda"
forzado: db "--forzado"
ayudaMostrar: db "mostrar.ayuda"
ayudaRenombrar: db "renombrar.ayuda"
ayudaBorrar: db "borrar.ayuda"
ayudaCopiar: db "copiar.ayuda"
ayudaComparar: db "comparar.ayuda"


pregunta: db "Desea realizar esta acción?. (s=si/ cualquier tecla menos 's'=no)",10,"PcPrompt$ "
lenPregunta: equ $-pregunta

errorComando: db "El comando no es válido",10
lenErrorC:	equ $-errorComando

errorEspacios: db "No debe dejar más de un espacio entre comandos",10
lenErrorE:	equ $-errorEspacios

errorArchivo: db "El archivo no existe",10
lenErrorA: equ $-errorArchivo

resultado: times 16 db 0
section .text
global _start

_start:
	nop
Ejecucion:
	call 	limpiar			
	mov 	ecx, msjPrompt
	mov 	edx, msjPromptlen
	call 	DisplayText
	
	;Se toman los comandos completos en una sola linea
	mov 	ecx, nombreArch
	mov 	edx, 50
	call 	ReadText
	
;Salta para ir a generar lo comandos	
	call generarComandos

;Comparaciones del primer comando para saber que se va a realizar	
	mov 	ecx, [mostrar]
	cmp 	[comando1], ecx
	je 		Mostrar
	
	mov 	ecx, [renombrar]
	cmp 	[comando1], ecx
	je 		Renombrar
	
	mov 	ecx, [borrar]
	cmp 	[comando1], ecx
	je 		Borrar 
	
	mov 	ecx, [copiar]
	cmp 	[comando1], ecx
	je 		Copiar
	
	mov 	ecx, [comparar]
	cmp 	[comando1], ecx
	je 		Comparar

	mov 	ecx, [salir]
	cmp 	[comando1], ecx
	je 		fin				
	
	jmp 	mostrarErrorC
	
Mostrar:
	mov 	ecx, [ayuda]
	cmp		[comando2], ecx
	je		setearAyuda

muestraAyuda:
	mov		ebx, comando2
	mov		ecx, stat
	mov		eax, sys_newstat
	int		80H

	;Se toma el largo del archivo 
	xor		ebx, ebx
	mov		eax, sys_brk
	int		80H
	mov		[Org_Break], eax
	mov		[TempBuf], eax
	push	eax
	
	;Se extiende el archivo hasta su largo completo
	pop		ebx
	add		ebx, dword [stat + STAT.st_size]
	mov		eax, sys_brk
	int		80H
	
	;Se abre el archivo
	mov		ebx, comando2
	mov		ecx, O_RDONLY
	xor		edx, edx
	mov		eax, sys_open
	int		80H
	test	eax,eax
	js		errorArch
    xchg    eax, esi
	
	;Lee lo que hay dentro del archivo usando como largo la estructura
	;STAT.st_size
	mov     ebx, esi
	mov		ecx, [TempBuf]
	mov		edx, dword [stat + STAT.st_size]
	mov		eax, sys_read
	int		80H

	;Se imprime en consola lo que hay en el archivo
	mov		ebx, stdout
	mov		ecx, [TempBuf]
	mov		edx, eax
	mov		eax, sys_write
	int		80H
	
	;Se cierra el archivo
	mov		ebx, esi 
	mov		eax, sys_close
	int		80H

	;Se libera memoria
	mov     ebx, [Org_Break]
    mov     eax, sys_brk
    int     80H
	jmp 	Ejecucion
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Renombrar:
	mov 	ecx, [ayuda]
	cmp		[comando2], ecx
	je		setearAyuda
	
	mov		ecx, [forzado]
	cmp		[comando4], ecx
	je 		continuaRen
	jmp 	hacerPregunta
	
continuaRen:
	xor ebx,ebx
	mov [Res], ebx
	mov eax, sys_rename
	mov ebx, comando2
	mov ecx, comando3
	int 80h
	jmp Ejecucion
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Borrar se utiliza para tomar un archivo mediante su nombre y borrarlo

Borrar:
	mov 	ecx, [ayuda]
	cmp		[comando2], ecx
	je		setearAyuda
	mov		ecx, [forzado]
	cmp		[comando3], ecx
	je 		continuaBorrar
	jmp 	hacerPregunta

continuaBorrar:
	xor ebx,ebx
	mov [Res], ebx
	mov eax, sys_unlink
	mov ebx, comando2
	int 80h
	jmp Ejecucion
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Copiar se utiliza para tomar un archivo mediante su nombre y copiar su contenido en
;otro archivo tambien creado por esta misma sección 

Copiar:
	mov 	ecx, [ayuda]
	cmp		[comando2], ecx
	je		setearAyuda
	
	mov eax, sys_link
	mov ebx, comando2
	mov ecx, comando3
	int 80h
	jmp Ejecucion	

Comparar:
	mov 	ecx, [ayuda]
	cmp		[comando2], ecx
	je		setearAyuda

;Seccion en la que se abren ambos archivos
	mov		ebx, comando2
	mov		ecx, 0		
	mov		eax,sys_open
	int		80h
	test	eax, eax	;Se chequea que exista el archivo
	js		errorArch
	
	mov		ebx, eax
	mov		ecx, fileBuff1
	mov		edx, 100
	mov		eax, sys_read
	int 	80h
	
	mov		ebx, comando3
	mov		ecx, 0		
	mov		eax,sys_open
	int		80h
	test	eax, eax	;Se chequea que exista el archivo
	js		errorArch
	
	mov		ebx, eax
	mov		ecx, fileBuff2
	mov		edx, 100
	mov		eax, sys_read
	int		80h

;Se limpian los registros para iniciar desde 0	
mov byte[contador],1
        xor ecx,ecx
        xor eax,eax
        xor ebx,ebx
        xor edx,edx

;Inicia comparar tomando el primer byte de ambos archivos y comparandolos
;entre si para saber si son iguales o si son diferentes, y en ese caso
;imprimir la linea en la que son diferentes
        .comparar:
                mov dl,byte[fileBuff1+ecx]
                mov bl,byte[fileBuff2+eax]
                cmp dl,0
                je Ejecucion
                cmp bl,0
                je Ejecucion
                cmp dl,bl
                jne .imprimirLinea
                cmp bl,10
                je .adelantarBuf1
                cmp dl,10
                je .adelantarBuf2
                cmp dl,bl
                je .continua


;Incrementa los indices hasta el enter para
;iniciar en la siguiente linea
                        
        .adelantarBuf1:
                mov dl,byte[fileBuff1+ecx]
                cmp edx,0
                je  Ejecucion
                cmp edx,10
                je .adelantarBuf2
                inc ecx
                jmp .adelantarBuf1

;Incrementa los indices hasta el enter para
;iniciar en la siguiente linea
        .adelantarBuf2:
                mov bl,byte[fileBuff2 + eax]
                cmp ebx,0
                je  Ejecucion
                cmp ebx,10
                je .incrementarLinea
                inc eax
                jmp .adelantarBuf2

;Se incrementan los indices hasta el enter para cambiar de linea cada vez que se encuentra una 
;diferencia entre dos lineas
                
        .incBuf1:
                mov dl,byte[fileBuff1+ecx]
                cmp dl,0
                je Ejecucion
                cmp dl,10
                je .incBuf2
                inc ecx
                jmp .incBuf1
        
        .incBuf2:
                mov bl,byte[fileBuff2+eax]
                cmp bl,0
                je Ejecucion
                cmp bl,10
                je .incrementarLinea
                inc eax
                jmp .incBuf2

;Se incrementan los indices cada vez que se compara un par de dígitos

        .continua:
                inc ecx
                inc eax
                jmp .comparar
                
;Se incrementa la linea cada vez que se salta de linea por un enter

        .incrementarLinea:
                xor edx,edx
                mov edx,dword[contador]
                inc edx
                mov dword[contador],edx
                jmp .continua

;Guarda los registros para no perder el indice y brinca para imprimir
                
        .imprimirLinea:
                push eax
                push ecx
                jmp .llamarImprimir

;Se imprime en pantalla la linea donde es diferente el archivo
                
        .llamarImprimir:
                mov eax,dword[contador]
                call intAscci
                pop ecx
                pop eax
                jmp .incBuf1
                
		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
;En esta sección de código se generan los comandos, desde el primero en el que
;se encuentra ya sea mostrar, salir, etc. Hasta los nombres de los archivos  
	
generarComandos:
	mov ecx,0			;Se inicializan los registros en para utilizarlos mientras nos movemos dentro del 
	mov esi,0			;archivo
	xor ebx,ebx
	jmp Comando.ciclo
Comando:
	mov ecx, edi
	xor ebx,ebx
	.ciclo:
		mov dl,byte[nombreArch + ecx]		;Se toma cada byte del input y se translada a su respectiva posición dentro del
		mov byte[comandoTemp + ebx],dl			;buffer donde se guarda temporalmente el comando 
		inc ecx
		inc ebx
		cmp dl,0 							;Al encontrarse con un cero significa que dentro del buffer no quedan más
		je ciclo							;comandos por tomar y salta a ciclo para ser tratado
		cmp dl," "							;Si hay un espacio significa que en el archivo hay más comandos por lo que
		je incESI							;salta a incESI para tomar el estado actual de el contador con el que nos movermos
		jmp .ciclo							;en el buffer y lo guarda dentro de el registro edi

;Aqui salta solo si quedan comandos por tomar
incESI:					
	inc esi									;El registro esi será nuestro guía para saber a que buffer se debe de mover el
	mov edi, ecx							;comando luego de ser tratado


;Dentro de ciclo se tomará el comando recién tomado por el ciclo anterior y se le eliminará el salto de linea o el cero que
;tenga al final, y que podría perjudicar la funcionalidad del programa
ciclo:
	mov eax,-1
	call len									;Se toma el largo del comando
	mov ecx, 0
	dec eax										;Se decrementa el largo y así se tiene el tope al cual llegara el comando que deseamos
												;dejar sin último caracter
	.ciclo2:									;Se mueve el nombre del archivo ingresado dentro de otro buffer	
		mov		dl, byte [comandoTemp + ecx]	;Para que se tome unicamente el largo del archivo y no mas caracteres que 
		mov     byte[temp + ecx],dl				;Afecten el reconocimiento
		inc		ecx		
		cmp		ecx, eax
		jne 	.ciclo2
		;En este segmento se toma el estado actual del registro esi y así saltar a la etiqueta que movera el comando tratado
		;a otro buffer limpio que se utilizará en las ejecuciones
		mov 	ecx, 0
		cmp 	esi,0
		je 		movComandoS
		cmp 	esi,1
		je		movComando1
		cmp 	esi,2
		je		movComando2
		cmp 	esi,3
		je		movComando2
		cmp 	esi,4
		je		movComando3
		cmp 	esi,5
		je		movComando3
		cmp 	esi,6
		je		movComando4
		ret
		
;Se toma el largo del comando mediante un call
len:
	inc eax
    cmp byte[comandoTemp + eax],0
    jne len
    ret	
  
;Etiqueta especial para cuando se ingresa un solo comando, en este caso solo funciona con "salir"  
movComandoS:
	mov dl, byte[temp + ecx]
	mov byte[comando1 + ecx], dl
	inc ecx
	cmp dl, 0
	jne movComandoS
	mov ecx, 0
	call limpiarTemp
	call limpiarcomando
	ret   
  
;Se mueve el comando al buffer comando1 el cual tendrá siempre la instrucción que se desea ejecutar sobre los archivos 
movComando1:
	mov dl, byte[temp + ecx]
	mov byte[comando1 + ecx], dl
	inc ecx
	cmp dl, 0
	jne movComando1
	inc esi
	mov ecx, 0
	call limpiarTemp
	call limpiarcomando
	jmp	Comando  
  
;Se mueve el comando al buffer comando2 el cual tendra ya sea el nombre de algún archivo o el comando --ayuda  
movComando2:
	mov dl, byte[temp + ecx]
	mov byte[comando2 + ecx], dl
	inc ecx
	cmp dl, 0
	jne movComando2
	inc esi
	mov ecx, 0
	call limpiarTemp
	call limpiarcomando
	jmp	Comando

;Se mueve el comando al buffer comando3 el cual tendra ya sea el nombre de algún archivo o el comando --forzado
movComando3:
	mov dl, byte[temp + ecx]
	mov byte[comando3 + ecx], dl
	inc ecx
	cmp dl, 0
	jne movComando3	
	inc esi
	mov ecx, 0
	call limpiarTemp
	call limpiarcomando
	jmp	Comando
	

;Se mueve el comando al buffer comando4 el cual tendra el comando --forzado que se utilizará siempre que se utilice la instrucción	
; "renombrar"
movComando4:
	mov dl, byte[temp + ecx]
	mov byte[comando4 + ecx], dl
	inc ecx
	cmp dl, 0
	jne movComando4	
	mov ecx, 0
	call limpiarTemp
	call limpiarcomando
	ret
	
;En esta etiqueta se salta a su respectiva subetiqueta para mostrar el mensaje de ayuda que se solicitó. Esta etiqueta solo	
;será llamada si dentro de alguna de las intrucciones como mostrar, copiar,etc, se detectó el mensaje --ayuda dentro del comando2
setearAyuda:
	xor ecx, ecx
	mov eax, [comando1]
	cmp [mostrar],eax
	je .ayudaMostrar
	cmp [renombrar],eax
	je .ayudaRenombrar
	cmp [borrar], eax
	je .ayudaBorrar
	cmp [copiar], eax
	je .ayudaCopiar
	jmp .ayudaComparar
	;Cada subetiqueta hace un ciclo en el que se toma como punto final el largo del nombre del archivo a abrir para 
	;mostrar el mensaje de ayuda
	
	;Subetiqueta para mover a comando2 el mensaje de ayuda de mostrar e imprimirlo
	.ayudaMostrar:
		mov dl, byte[ayudaMostrar+ecx]
		mov byte[comando2+ecx],dl
		inc ecx
		cmp ecx, 13
		jne .ayudaMostrar
		jmp muestraAyuda
		
	;Subetiqueta para mover a comando2 el mensaje de ayuda de renombrar e imprimirlo
	.ayudaRenombrar:
		mov dl, byte[ayudaRenombrar+ecx]
		mov byte[comando2+ecx],dl
		inc ecx
		cmp ecx, 15
		jne .ayudaRenombrar
		jmp muestraAyuda
		
	;Subetiqueta para mover a comando2 el mensaje de ayuda de borrar e imprimirlo
	.ayudaBorrar:
		mov dl, byte[ayudaBorrar+ecx]
		mov byte[comando2+ecx],dl
		inc ecx
		cmp ecx, 12
		jne .ayudaBorrar
		jmp muestraAyuda
		
	;Subetiqueta para mover a comando2 el mensaje de ayuda de copiar e imprimirlo
	.ayudaCopiar:
		mov dl, byte[ayudaCopiar+ecx]
		mov byte[comando2+ecx],dl
		inc ecx
		cmp ecx, 12
		jne .ayudaCopiar
		jmp muestraAyuda
		
	;Subetiqueta para mover a comando2 el mensaje de ayuda de comparar e imprimirlo
	.ayudaComparar:
		mov dl, byte[ayudaComparar + ecx]
		mov byte[comando2+ecx],dl
		inc ecx
		cmp ecx, 14
		jne .ayudaComparar
		jmp muestraAyuda	
	
;Esta etiqueta se usa mediante un call. En ella se limpian los buffers ya sea por medio de moverles un ragistro limpio
;o realizando limpiezas byte por byte
limpiar:
	mov ecx,0
	xor	eax, eax
	call limpiarnombreArch
	call limpiarcomando
	call limpiarcomando1
	call limpiarcomando2
	call limpiarcomando3
	call limpiarTemp
	mov [contador], eax
	mov [cantLineas], eax
	mov [TempBuf], eax
	mov [stat], eax
	mov [Org_Break], eax
	mov [Res], eax
	ret


;Estas etiquetas se limpian byte por byte para que no existan "basuras" que afecten al leer los mensajes	
limpiarnombreArch:
	mov byte[nombreArch + ecx],0
	inc ecx
	cmp ecx,49
	jne limpiarnombreArch
	mov ecx, 0
	ret


limpiarcomando:
	mov byte[comandoTemp + ecx],0
	mov byte[estado + ecx], 0
	inc ecx
	cmp ecx,19
	jne limpiarcomando
	mov ecx, 0
	ret
	
limpiarcomando1:
	mov byte[comando1 + ecx],0
	inc ecx
	cmp ecx,19
	jne limpiarcomando1
	mov ecx, 0
	ret

limpiarcomando2:
	mov byte[comando2 + ecx],0
	inc ecx
	cmp ecx,19
	jne limpiarcomando2
	mov ecx, 0
	ret
	
limpiarcomando3:
	mov byte[comando3 + ecx],0
	inc ecx
	cmp ecx,19
	jne limpiarcomando3
	mov ecx, 0
	ret	

limpiarTemp:
	mov byte[temp + ecx],0
	inc ecx
	cmp ecx,31
	jne limpiarTemp
	mov ecx, 0
	ret			
	
;Termina el sector de limpiar buffers	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;Etiqueta utilizada para hacer la pregunta en los casos de renombrar y borrar
hacerPregunta:
	mov ecx, pregunta
	mov edx, lenPregunta
	call DisplayText
	
	mov ecx, Res
	mov edx, 5
	call ReadText
	;Luego de tomar la respuesta mediante un input, se compara para ver si la respuesta es de aceptación o de negación
	mov al, byte[Res]
	cmp	al, "s"
	je 	.verificarCom
	xor ebx,ebx
	mov [Res], ebx
	jmp Ejecucion

	;Se verifica a que comando hay que saltar para continuar la ejecución normal
	.verificarCom:
		mov ecx, [renombrar]
		cmp [comando1], ecx
		je 	continuaRen
		jmp continuaBorrar
		
;Mensajes de error dentro de la ejecución	

;Error cuando el primer comando no existe entre los especificados	
mostrarErrorC:
	mov ecx, errorComando
	mov edx, lenErrorC
	call DisplayText
	jmp Ejecucion
		
;Error cuando el archivo que se intenta mostrar no existe		
errorArch:
	mov ecx, errorArchivo
	mov edx, lenErrorA
	call DisplayText
	jmp Ejecucion	

;Finalización del proceso
fin:  
    mov     eax, sys_exit
    xor     ebx, ebx
    int     80H	
    
DisplayText:
    mov     eax, sys_write
    mov     ebx, stdout
    int     80H 
    ret

ReadText:
    mov     ebx, stdin
    mov     eax, sys_read
    int     80H
    ret


;Esta sección se encarga de imprimir la linea por la que se mueve el archivo en la función de comparar	
intAscci:
	divisiones_sucesivas:
	xor edx,edx					;Limpia la parte alta del número a dividir
	mov eax,dword[contador]		;Numero que se toma desde el contador de linea
	mov ecx,10					;divisor
	xor bx,bx					;limpia el resgistro para usarlo de contador de digitos

.division:
								;la division se hara así: edx:eax/ecx
								;el resultado quedara en eax y el residuo en edx
	xor edx,edx					;limpia el residuo anterior
	div ecx						;efectua division sin signos
	push dx						;guarda en la pila el digito (dx = 16 bits)
	inc bx						;contador + 1
	test eax,eax				;fin del ciclo? (revisa si el numero ya es 0)
	jnz .division				;recursivo sino es 0 continua el ciclo

acomoda_digitos:
	mov edx,resultado			;edx apunta al buffer resultado
	mov cx,bx					;contador se copia a cx (para no perderlo)

.siguiente_digito:
	pop ax						;saca de la pila 16 bits pero solo importan 8
	or al, 30h					;lo convierte al correspondiente ascii
	mov [edx],byte al			;escribo en la direccion apuntada por edx el resultado
	inc edx						;para escribir bien la siguiente vez
	loop .siguiente_digito

.agregar_punto:
	mov [edx],byte 2Eh			;agrega un punto
	inc edx

.agregar_cambio_linea:
	mov[edx],byte 0Ah			;agrega al final un cambio de linea

imprime_numero:
	push bx	
	mov ecx,resultado
	xor edx,edx					;limpia para poner resultado
	pop dx						;cantidad de digitos
	inc dx						;para mostrar el punto
	inc dx						;para mostrar linea de agregado
	call DisplayText
	ret
