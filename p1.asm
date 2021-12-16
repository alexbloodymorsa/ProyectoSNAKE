title "Proyecto: Snake" ;codigo opcional. Descripcion breve del programa, el texto entrecomillado se imprime como cabecera en cada pagina de codigo
	.model small	;directiva de modelo de memoria, small => 64KB para memoria de programa y 64KB para memoria de datos
	.386			;directiva para indicar version del procesador
	.stack 64 		;Define el tamano del segmento de stack, se mide en bytes
	.data			;Definicion del segmento de datos
;Definición de constantes
;Valor ASCII de caracteres para el marco del programa
marcoEsqInfIzq 		equ 	200d 	;'╚'
marcoEsqInfDer 		equ 	188d	;'╝'
marcoEsqSupDer 		equ 	187d	;'╗'
marcoEsqSupIzq 		equ 	201d 	;'╔'
marcoCruceVerSup	equ		203d	;'╦'
marcoCruceHorDer	equ 	185d 	;'╣'
marcoCruceVerInf	equ		202d	;'╩'
marcoCruceHorIzq	equ 	204d 	;'╠'
marcoCruce 			equ		206d	;'╬'
marcoHor 			equ 	205d 	;'═'
marcoVer 			equ 	186d 	;'║'
;Atributos de color de BIOS
;Valores de color para carácter
cNegro 			equ		00h
cAzul 			equ		01h
cVerde 			equ 	02h
cCyan 			equ 	03h
cRojo 			equ 	04h
cMagenta 		equ		05h
cCafe 			equ 	06h
cGrisClaro		equ		07h
cGrisOscuro		equ		08h
cAzulClaro		equ		09h
cVerdeClaro		equ		0Ah
cCyanClaro		equ		0Bh
cRojoClaro		equ		0Ch
cMagentaClaro	equ		0Dh
cAmarillo 		equ		0Eh
cBlanco 		equ		0Fh
;Valores de color para fondo de carácter
bgNegro 		equ		00h
bgAzul 			equ		10h
bgVerde 		equ 	20h
bgCyan 			equ 	30h
bgRojo 			equ 	40h
bgMagenta 		equ		50h
bgCafe 			equ 	60h
bgGrisClaro		equ		70h
bgGrisOscuro	equ		80h
bgAzulClaro		equ		90h
bgVerdeClaro	equ		0A0h
bgCyanClaro		equ		0B0h
bgRojoClaro		equ		0C0h
bgMagentaClaro	equ		0D0h
bgAmarillo 		equ		0E0h
bgBlanco 		equ		0F0h

;Número de columnas para el área de controles
area_controles_ancho 		equ 	20d

;Definicion de variables
;Títulos
nameStr			db 		"SNAKE"
recordStr 	db 		"HI-SCORE"
scoreStr 		db 		"SCORE"
levelStr 		db 		"LEVEL"
speedStr 		db 		"SPEED"

;Variables auxiliares para posicionar cursor al imprimir en pantalla
col_aux  		db 		0
ren_aux 		db 		0

conta 			db 		0 			;contador auxiliar para el procedimiento STOP
tick_ms			dw 		55 			;55 ms por cada tick del sistema, esta variable se usa para operación de MUL convertir ticks a segundos
mil					dw		1000 		;dato de valor decimal 1000 para operación DIV entre 1000
diez 				dw 		10  		;dato de valor decimal 10 para operación DIV entre 10
dos 				db 		2 			;dato de valor decimal 2 para operación MUL por 2 y DIV entre 2
sesenta			db 		60 			;dato de valor decimal 60 para operación DIV entre 60
status 			db 		0 			;0 pausa, 1 activo, 2 stop
t_inicial 	dw 		0,0 		
milisegundos 	dw 		0
divisorCol		dw		58d		;Dato para calcular la columna aleatoria del item
divisorRen		dw 		23d 	;Dato para calcular el renglón aleatorio del item

flash				dw		0 			;Dato que guarda ticks del sistema utilzado para hacer que la serpiente parpadee
banStop			db		0 			;Bandera que indica con 1 si acaba de pasar el procedimiento stop

;Variables para el juego
score 			dw 		0
hi_score	 	dw 		0
speed 			db 		0
speed_indicador	dw 		1000
speed_conta			db 		0 			;contador de items comidos
cmp_conta 	db 				10      ; comparador para el contador de items comidos

;Variables para 'head'. Datos de la cabeza de la serpiente
head_ren		db 		12d 	;Posición del renglón (0-24d)
head_col 		db 		25d 	;Posición de la columna (0-79d)
head_dir 		db 		0d 		;Dirección del siguiente movimiento
	;0: derecha
	;1: arriba
	;2: izquierda
	;3: abajo
;Bits 14-15: No definidos
;Posición inicial: renglón 12, columna 23, dirección derecha

;Datos de la cola de la serpiente
;los primeros dos valores son fijos y se imprimen al inicio del juego
;el resto se deben calcular conforme avanza el juego
;El primer elemento del arreglo 'tail' es el más cercano a la cabeza
;Parte baja: renglón
;Parte alta: columna
;1355
tail 			dw 		1100000001100b, 1011100001100b, 1011000001100b, 1010100001100b, 1351 dup(0)
tail_conta 		dw 		4  	;contador para la longitud de la cola

;variables para las coordenadas del objeto actual en pantalla
item_col 		db 		50  	;columna
item_ren 		db 		16 		;renglon

;Variables que sirven de parametros para el procedimiento IMPRIME_BOTON
boton_caracter 	db 		0 		;caracter a imprimir
boton_renglon 	db 		0 		;renglon de la posicion inicial del boton
boton_columna 	db 		0 		;columna de la posicion inicial del boton
boton_color			db 		0  		;color del caracter a imprimir dentro del boton
boton_bg_color	db 		0 		;color del fondo del boton

;Auxiliar para calculo de coordenadas del mouse
ocho			db 		8
;Cuando el driver del mouse no esta disponible
no_mouse		db 	'No se encuentra driver de mouse. Presione [enter] para salir$'

;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;Macros;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;
;clear - Limpia pantalla
clear macro
	mov ax,0003h 	;ah = 00h, selecciona modo video
					;al = 03h. Modo texto, 16 colores
	int 10h		;llama interrupcion 10h con opcion 00h. 
				;Establece modo de video limpiando pantalla
endm

;posiciona_cursor - Cambia la posición del cursor a la especificada con 'renglon' y 'columna' 
posiciona_cursor macro renglon,columna
	mov dh,renglon	;dh = renglon
	mov dl,columna	;dl = columna
	mov bx,0
	mov ax,0200h 	;preparar ax para interrupcion, opcion 02h
	int 10h 		;interrupcion 10h y opcion 02h. Cambia posicion del cursor
endm 

;inicializa_ds_es - Inicializa el valor del registro DS y ES
inicializa_ds_es 	macro
	mov ax,@data
	mov ds,ax
	mov es,ax 		;Este registro se va a usar, junto con BP, para imprimir cadenas utilizando interrupción 10h
endm

;muestra_cursor_mouse - Establece la visibilidad del cursor del mouser
muestra_cursor_mouse	macro
	mov ax,1		;opcion 0001h
	int 33h			;int 33h para manejo del mouse. Opcion AX=0001h
					;Habilita la visibilidad del cursor del mouse en el programa
endm

;posiciona_cursor_mouse - Establece la posición inicial del cursor del mouse
posiciona_cursor_mouse	macro columna,renglon
	mov dx,renglon
	mov cx,columna
	mov ax,4		;opcion 0004h
	int 33h			;int 33h para manejo del mouse. Opcion AX=0001h
					;Habilita la visibilidad del cursor del mouse en el programa
endm

;oculta_cursor_teclado - Oculta la visibilidad del cursor del teclado
oculta_cursor_teclado	macro
	mov ah,01h 		;Opcion 01h
	mov cx,2607h 	;Parametro necesario para ocultar cursor
	int 10h 		;int 10, opcion 01h. Cambia la visibilidad del cursor del teclado
endm

;apaga_cursor_parpadeo - Deshabilita el parpadeo del cursor cuando se imprimen caracteres con fondo de color
;Habilita 16 colores de fondo
apaga_cursor_parpadeo	macro
	mov ax,1003h 		;Opcion 1003h
	xor bl,bl 			;BL = 0, parámetro para int 10h opción 1003h
  	int 10h 			;int 10, opcion 01h. Cambia la visibilidad del cursor del teclado
endm

;imprime_caracter_color - Imprime un caracter de cierto color en pantalla, especificado por 'caracter', 'color' y 'bg_color'. 
;Los colores disponibles están en la lista a continuacion;
; Colores:
; 0h: Negro
; 1h: Azul
; 2h: Verde
; 3h: Cyan
; 4h: Rojo
; 5h: Magenta
; 6h: Cafe
; 7h: Gris Claro
; 8h: Gris Oscuro
; 9h: Azul Claro
; Ah: Verde Claro
; Bh: Cyan Claro
; Ch: Rojo Claro
; Dh: Magenta Claro
; Eh: Amarillo
; Fh: Blanco
; utiliza int 10h opcion 09h
; 'caracter' - caracter que se va a imprimir
; 'color' - color que tomará el caracter
; 'bg_color' - color de fondo para el carácter en la celda
; Cuando se define el color del carácter, éste se hace en el registro BL:
; La parte baja de BL (los 4 bits menos significativos) define el color del carácter
; La parte alta de BL (los 4 bits más significativos) define el color de fondo "background" del carácter
imprime_caracter_color macro caracter,color,bg_color
	mov ah,09h				;preparar AH para interrupcion, opcion 09h
	mov al,caracter 		;AL = caracter a imprimir
	mov bh,0				;BH = numero de pagina
	mov bl,color 			
	or bl,bg_color 			;BL = color del caracter
							;'color' define los 4 bits menos significativos 
							;'bg_color' define los 4 bits más significativos 
	mov cx,1				;CX = numero de veces que se imprime el caracter
							;CX es un argumento necesario para opcion 09h de int 10h
	int 10h 				;int 10h, AH=09h, imprime el caracter en AL con el color BL
endm

;imprime_caracter_color - Imprime un caracter de cierto color en pantalla, especificado por 'caracter', 'color' y 'bg_color'. 
; utiliza int 10h opcion 09h
; 'cadena' - nombre de la cadena en memoria que se va a imprimir
; 'long_cadena' - longitud (en caracteres) de la cadena a imprimir
; 'color' - color que tomarán los caracteres de la cadena
; 'bg_color' - color de fondo para los caracteres en la cadena
imprime_cadena_color macro cadena,long_cadena,color,bg_color
	mov ah,13h				;preparar AH para interrupcion, opcion 13h
	lea bp,cadena 			;BP como apuntador a la cadena a imprimir
	mov bh,0				;BH = numero de pagina
	mov bl,color 			
	or bl,bg_color 			;BL = color del caracter
							;'color' define los 4 bits menos significativos 
							;'bg_color' define los 4 bits más significativos 
	mov cx,long_cadena		;CX = longitud de la cadena, se tomarán este número de localidades a partir del apuntador a la cadena
	int 10h 				;int 10h, AH=09h, imprime el caracter en AL con el color BL
endm

;lee_mouse - Revisa el estado del mouse
;Devuelve:
;;BX - estado de los botones
;;;Si BX = 0000h, ningun boton presionado
;;;Si BX = 0001h, boton izquierdo presionado
;;;Si BX = 0002h, boton derecho presionado
;;;Si BX = 0003h, boton izquierdo y derecho presionados
; (400,120) => 80x25 =>Columna: 400 x 80 / 640 = 50; Renglon: (120 x 25 / 200) = 15 => 50,15
;;CX - columna en la que se encuentra el mouse en resolucion 640x200 (columnas x renglones)
;;DX - renglon en el que se encuentra el mouse en resolucion 640x200 (columnas x renglones)
lee_mouse	macro
	mov ax,0003h
	int 33h
endm

;comprueba_mouse - Revisa si el driver del mouse existe
comprueba_mouse 	macro
	mov ax,0		;opcion 0
	int 33h			;llama interrupcion 33h para manejo del mouse, devuelve un valor en AX
					;Si AX = 0000h, no existe el driver. Si AX = FFFFh, existe driver
endm

;leer_ticks - Lee el valor del contador de ticks y lo guarda en variable t_inicial
leer_ticks macro
	mov ah,00h 				;opción 0
	int 1Ah 				;interrupción para leer el contador de ticks
	mov [t_inicial],dx 		;Se guarda el valor en t_inicial
	mov [t_inicial+2],cx
endm

;delimitar_cursor - No permite que el mouse salga del área de controles
delimitar_cursor macro
	mov al, area_controles_ancho 		;Se guarda la columna límite del area de controles en AX
	mul [ocho]											;Se multiplica AX por 8 para obtener las columnas en la correcta resolución
	mov dx, ax 											;DX guarda la columna máxima que se puede acceder
	mov cx, 0 											;CX guarda la columna mínima que se puede acceder
	mov ax, 0007h 									;Opción 7 -> restrige el movimiento horizaontal del mouse desde CX hasta DX
	int 33h													;llama interrupcion 33h para manejo del mouse
endm

;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;Fin Macros;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;

	.code
inicio:					;etiqueta inicio
	inicializa_ds_es 	;inicializa registros DS y ES
	comprueba_mouse		;macro para revisar driver de mouse
	xor ax,0FFFFh		;compara el valor de AX con FFFFh, si el resultado es zero, entonces existe el driver de mouse
	jz imprime_ui		;Si existe el driver del mouse, entonces salta a 'imprime_ui'
	;Si no existe el driver del mouse entonces se muestra un mensaje
	lea dx,[no_mouse]
	mov ax,0900h	;opcion 9 para interrupcion 21h
	int 21h			;interrupcion 21h. Imprime cadena.
	jmp fin			;salta a 'fin'
imprime_ui:
	clear 					;limpia pantalla
	oculta_cursor_teclado	;oculta cursor del mouse
	apaga_cursor_parpadeo 	;Deshabilita parpadeo del cursor
	call DIBUJA_UI 			;procedimiento que dibuja marco de la interfaz
	delimitar_cursor 		;delimita el área del cursor
	muestra_cursor_mouse 	;hace visible el cursor del mouse
	posiciona_cursor_mouse 10d,0d	;establece la posición del mouse en la posición

;Lee el valor del contador de ticks y lo guarda en variable t_inicial
	leer_ticks

;Revisar que el boton izquierdo del mouse no esté presionado
;Si el botón no está suelto, no continúa
;Se realizan los procesos del juego como mover la víbora
mouse_no_clic:
	lee_mouse
	test bx,0001h
	jnz mouse_no_clic 
;Lee el mouse y avanza hasta que se haga clic en el boton izquierdo
mouse:
	cmp status, 0 			
	je no_contenido 		;Si el status es 0 (pausa) no se mueve al jugador
	cmp status, 2
	je status_stop 			;Si el status es 2 (stop) no se analizan botones y se hace un salto
	call CALCULO_SPEED 		;Se calcula cada cuantos milisegundos se hace un movimiento
	mov ax,[speed_indicador]
	cmp milisegundos, ax 	;Mover cada [speed_indicador] milisegundos
	jbe no_mover 			;No mover a la víbora
	call MOVER 				;Se mueve a la víbora si ya transcurrieron los milisegundos de [speed_indicador]

	leer_ticks 				;Se reinician las ticks
no_mover:
	call CRONO 				;actualiza los milisegundos

	mov ah,01h 				;Opción para leer el estado del buffer del teclado
    int 16h					;int 16h: servicios del teclado
    jz no_contenido			;Si hay contenido se lee la tecla de lo contrario se salta al siguiente proceso
    cmp banStop, 1  ;Se verifica si se acaba de pasar por el procedimiento STOP
    je derecha			;De ser así, se debe mover a la primero a la dercha la serpiente por lo que no se revisa la tecla presionada
    mov ah,00h 				;Opción para leer una tecla y almacenarla en al
    int 16h 				;int 16h: servicios del teclado

	cmp [head_dir], 0 		
    je tecla_w 					;Si la serpiente se mueve a la derecha entonces solo puede ir verticalmente
    cmp [head_dir], 1
    je tecla_d 					;Si la serpiente se mueve a hacia arriba entonces solo puede ir horizontalmente
    cmp [head_dir], 2
    je tecla_w 					;Si la serpiente se mueve a la izquierda entonces solo puede ir verticalmente

    ;Inicia la lógica para ver qué tecla se pulsó. Se compara el registro al con el valor ASCII de las teclas.
    ;Si no se aprieta A, S, D o W no se hace nada.
tecla_d:
    cmp al, 100d 			;Tecla D
    jne tecla_a 			;Si no se presionó D se analiza A
    mov [head_dir],0 		;Si se presiona D se mueve hacia la derecha
    jmp no_contenido
tecla_a:
	cmp al, 97d 			;Tecla A
    jne no_contenido 	;Si no se presionó A no hace nada
    mov [head_dir],2 		;Si se presiona A se mueve hacia la izquierda
    jmp no_contenido	
tecla_w:
	cmp al, 119d 			;Tecla W
    jne tecla_s				;Si no se presionó W se analiza S
    mov [head_dir],1 		;Si se presiona W se mueve hacia arriba
    jmp no_contenido
tecla_s:
	cmp al, 115d 			;Tecla S
    jne no_contenido	;Si no se presionó S no hace nada
    mov [head_dir],3 		;Si se presiona S se mueve hacia abajo
    jmp no_contenido

derecha:							;En caso de ser el primer movimiento después del procedimiento STOP
	mov [head_dir],0 		;se forza el movimiento hacia la dercha
	dec banStop					;y la bandera vuleve a ser 0

no_contenido:
	lee_mouse

conversion_mouse:
	;Leer la posicion del mouse y hacer la conversion a resolucion
	;80x25 (columnas x renglones) en modo texto
	mov ax,dx 			;Copia DX en AX. DX es un valor entre 0 y 199 (renglon)
	div [ocho] 			;Division de 8 bits
						;divide el valor del renglon en resolucion 640x200 en donde se encuentra el mouse
						;para obtener el valor correspondiente en resolucion 80x25
	xor ah,ah 			;Descartar el residuo de la division anterior
	mov dx,ax 			;Copia AX en DX. AX es un valor entre 0 y 24 (renglon)

	mov ax,cx 			;Copia CX en AX. CX es un valor entre 0 y 639 (columna)
	div [ocho] 			;Division de 8 bits
						;divide el valor de la columna en resolucion 640x200 en donde se encuentra el mouse
						;para obtener el valor correspondiente en resolucion 80x25
	xor ah,ah 			;Descartar el residuo de la division anterior
	mov cx,ax 			;Copia AX en CX. AX es un valor entre 0 y 79 (columna)

	test bx,0001h 		;Para revisar si el boton izquierdo del mouse fue presionado
	jz mouse 			;Si el boton izquierdo no fue presionado, vuelve a leer el estado del mouse

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Lógica de la posicion del mouse;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Si el mouse fue presionado en el renglon 0, se va a revisar si fue dentro del boton [X]
	cmp dx,0
	je boton_x

;Si el mouse fue presionado en el renglon 11, 12 o 13, se revisa si fue dentro de los botones speed
	cmp dx,11
	je boton_sd
	cmp dx,12
	je boton_sd
	cmp dx,13
	je boton_sd

;Si el mouse fue presionado en el renglon 19, 20 o 21, se revisa si fue dentro de los botones de estado
	cmp dx,19
	je boton_pausa
	cmp dx,20
	je boton_pausa
	cmp dx,21
	je boton_pausa

;Si no se presionó en ninguno de los renglones con botones, se realiza otra vez los procesos del juego
	jmp mouse_no_clic


;Lógica para revisar si el mouse fue presionado en [X]
;[X] se encuentra en renglon 0 y entre columnas 17 y 19
boton_x:
	cmp cx,17
	jb mouse_no_clic
	cmp cx,19
	ja mouse_no_clic
	;Se cumplieron todas las condiciones
	jmp salir


;Lógica para revisar si el mouse fue presionado para modificar Speed
;Speed down se encuentra en renglon 11, 12, y 13 y entre columnas 12 y 14
boton_sd:
	cmp [status], 1
	je mouse_no_clic 	;Si el estatus es play no se puede modificar la velocidad.
	cmp [speed], 0 		;Si speed es 0 no se puede decrementar
	je boton_su 		;Se checa el botón de speed up

	cmp cx,12
	jb mouse_no_clic
	cmp cx,14
	ja boton_su
	;Se cumplieron todas las condiciones se le resta uno a la velocidad y se actualiza
	dec [speed]
	call IMPRIME_SPEED
	jmp mouse_no_clic

;Speed up se encuentra en renglon 11, 12, y 13 y entre columnas 16 y 18
boton_su:
	cmp cx,16
	jb mouse_no_clic
	cmp cx,18
	ja mouse_no_clic
	;Se cumplieron todas las condiciones se le suma uno a la velocidad y se actualiza
	inc [speed]
	call IMPRIME_SPEED
	jmp mouse_no_clic


;Lógica para revisar si el mouse fue presionado en un boton de cambio de estado
;Pausa se encuentra en renglon 19, 20, y 21 y entre columnas 3 y 5
boton_pausa:
	cmp cx,3
	jb mouse_no_clic
	cmp cx,5
	ja boton_stop
	;Se cumplieron todas las condiciones se cambia el estado a 0
	mov [status], 0
	jmp mouse_no_clic

;Stop se encuentra en renglon 19, 20, y 21 y entre columnas 9 y 11
boton_stop:
	cmp cx,9
	jb mouse_no_clic
	cmp cx,11
	ja boton_play
	;Se cumplieron todas las condiciones se cambia el estado a 2
	mov [status], 2
	jmp mouse_no_clic

;Play se encuentra en renglon 19, 20, y 21 y entre columnas 15 y 17
boton_play:
	cmp cx,15
	jb mouse_no_clic
	cmp cx,17
	ja mouse_no_clic
	;Se cumplieron todas las condiciones se cambia el estado a 1
	mov [status], 1
	jmp mouse_no_clic


;Bloque que se realiza cuando se encuentra la serpiente en estado STOP
status_stop:
	call STOP 					;Se llama procedimiento STOP y como su estado cambia a 0 (pausa)
	jmp no_contenido 		;se hace el salto a no_contenido


;Si no se encontró el driver del mouse, muestra un mensaje y el usuario debe salir tecleando [enter]
fin:
	mov ah,08h
	int 21h 		;opción 08h int 21h. Lee carácter del teclado sin eco
	cmp al,0Dh		;compara la entrada de teclado si fue [enter]
	jnz fin 		;Sale del ciclo hasta que presiona la tecla [enter]

salir:				;inicia etiqueta salir
	clear 			;limpia pantalla
	mov ax,4C00h	;AH = 4Ch, opción para terminar programa, AL = 0 Exit Code, código devuelto al finalizar el programa
	int 21h			;señal 21h de interrupción, pasa el control al sistema operativo

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;PROCEDIMIENTOS;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	DIBUJA_UI proc
		;imprimir esquina superior izquierda del marco
		posiciona_cursor 0,0
		imprime_caracter_color marcoEsqSupIzq,cAmarillo,bgNegro
		
		;imprimir esquina superior derecha del marco
		posiciona_cursor 0,79
		imprime_caracter_color marcoEsqSupDer,cAmarillo,bgNegro
		
		;imprimir esquina inferior izquierda del marco
		posiciona_cursor 24,0
		imprime_caracter_color marcoEsqInfIzq,cAmarillo,bgNegro
		
		;imprimir esquina inferior derecha del marco
		posiciona_cursor 24,79
		imprime_caracter_color marcoEsqInfDer,cAmarillo,bgNegro
		
		;imprimir marcos horizontales, superior e inferior
		mov cx,78 		;CX = 004Eh => CH = 00h, CL = 4Eh 
	marcos_horizontales:
		mov [col_aux],cl
		;Superior
		posiciona_cursor 0,[col_aux]
		imprime_caracter_color marcoHor,cAmarillo,bgNegro
		;Inferior
		posiciona_cursor 24,[col_aux]
		imprime_caracter_color marcoHor,cAmarillo,bgNegro
		mov cl,[col_aux]
		loop marcos_horizontales

		;imprimir marcos verticales, derecho e izquierdo
		mov cx,23 		;CX = 0017h => CH = 00h, CL = 17h 
	marcos_verticales:
		mov [ren_aux],cl
		;Izquierdo
		posiciona_cursor [ren_aux],0
		imprime_caracter_color marcoVer,cAmarillo,bgNegro
		;Inferior
		posiciona_cursor [ren_aux],79
		imprime_caracter_color marcoVer,cAmarillo,bgNegro
		;Interno
		posiciona_cursor [ren_aux],area_controles_ancho
		imprime_caracter_color marcoVer,cAmarillo,bgNegro
		
		mov cl,[ren_aux]
		loop marcos_verticales

		;imprimir marcos horizontales internos
		mov cx,area_controles_ancho 		;CX = 0014h => CH = 00h, CL = 14h 
	marcos_horizontales_internos:
		mov [col_aux],cl
		;Interno izquierdo (marcador player 1)
		posiciona_cursor 8,[col_aux]
		imprime_caracter_color marcoHor,cAmarillo,bgNegro

		;Interno derecho (marcador player 2)
		posiciona_cursor 16,[col_aux]
		imprime_caracter_color marcoHor,cAmarillo,bgNegro

		mov cl,[col_aux]
		loop marcos_horizontales_internos

		;imprime intersecciones internas	
		posiciona_cursor 0,area_controles_ancho
		imprime_caracter_color marcoCruceVerSup,cAmarillo,bgNegro
		posiciona_cursor 24,area_controles_ancho
		imprime_caracter_color marcoCruceVerInf,cAmarillo,bgNegro

		posiciona_cursor 8,0
		imprime_caracter_color marcoCruceHorIzq,cAmarillo,bgNegro
		posiciona_cursor 8,area_controles_ancho
		imprime_caracter_color marcoCruceHorDer,cAmarillo,bgNegro

		posiciona_cursor 16,0
		imprime_caracter_color marcoCruceHorIzq,cAmarillo,bgNegro
		posiciona_cursor 16,area_controles_ancho
		imprime_caracter_color marcoCruceHorDer,cAmarillo,bgNegro

		;imprimir [X] para cerrar programa
		posiciona_cursor 0,17
		imprime_caracter_color '[',cAmarillo,bgNegro
		posiciona_cursor 0,18
		imprime_caracter_color 'X',cRojoClaro,bgNegro
		posiciona_cursor 0,19
		imprime_caracter_color ']',cAmarillo,bgNegro

		;imprimir título
		posiciona_cursor 0,38
		imprime_cadena_color [nameStr],5,cAmarillo,bgNegro

		call IMPRIME_DATOS_INICIALES
		ret
	endp

	;Reinicia scores y speed, e imprime
	DATOS_INICIALES proc
		call IMPRIME_SCORE
		call IMPRIME_HISCORE
		call IMPRIME_SPEED
		ret
	endp

	;Imprime la información inicial del programa
	IMPRIME_DATOS_INICIALES proc
		call DATOS_INICIALES

		;imprime cadena 'HI-SCORE'
		posiciona_cursor 3,2
		imprime_cadena_color recordStr,8,cGrisClaro,bgNegro

		;imprime cadena 'SCORE'
		posiciona_cursor 5,2
		imprime_cadena_color scoreStr,5,cGrisClaro,bgNegro

		;imprime cadena 'SPEED'
		posiciona_cursor 12,2
		imprime_cadena_color speedStr,5,cGrisClaro,bgNegro
		
		;imprime viborita
		call IMPRIME_PLAYER

		;imprime ítem
		call IMPRIME_ITEM

		;Botón Speed down
		mov [boton_caracter],31 		;▼
		mov [boton_color],bgAmarillo
		mov [boton_renglon],11
		mov [boton_columna],12
		call IMPRIME_BOTON

		;Botón Speed UP
		mov [boton_caracter],30 		;▲
		mov [boton_color],bgAmarillo
		mov [boton_renglon],11
		mov [boton_columna],16
		call IMPRIME_BOTON

		;Botón Pause
		mov [boton_caracter],186 		;║
		mov [boton_color],bgAmarillo
		mov [boton_renglon],19
		mov [boton_columna],3
		call IMPRIME_BOTON

		;Botón Stop
		mov [boton_caracter],254d 		;■
		mov [boton_color],bgAmarillo
		mov [boton_renglon],19
		mov [boton_columna],9
		call IMPRIME_BOTON

		;Botón Start
		mov [boton_caracter],16d 		;►
		mov [boton_color],bgAmarillo
		mov [boton_renglon],19
		mov [boton_columna],15
		call IMPRIME_BOTON

		ret
	endp

	;Procedimiento utilizado para imprimir el score actual
	;Establece las coordenadas en variables auxiliares en donde comienza a imprimir.
	;Pone el valor en BX que se imprime con el procedimiento IMPRIME_SCORE_BX
	IMPRIME_SCORE proc
		mov [ren_aux],5
		mov [col_aux],12
		mov bx,[score]
		call IMPRIME_SCORE_BX
		ret
	endp

	;Procedimiento utilizado para imprimir el score global HI-SCORE
	;Establece las coordenadas en variables auxiliares en donde comienza a imprimir.
	;Pone el valor en BX que se imprime con el procedimiento IMPRIME_SCORE_BX
	IMPRIME_HISCORE proc
		mov [ren_aux],3
		mov [col_aux],12
		mov bx,[hi_score]
		call IMPRIME_SCORE_BX
		ret
	endp

	;Imprime el valor contenido en BX
	;Se imprime un valor de 5 dígitos. Si el número es menor a 10000, se completan los 5 dígitos con ceros a la izquierda
	IMPRIME_SCORE_BX proc
		mov ax,bx 		;AX = BX
		mov cx,5 		;CX = 5. Se realizan 5 divisiones entre 10 para obtener los 5 dígitos
	;En el bloque div10, se obtiene los dígitos del número haciendo divisiones entre 10 y se almacenan en la pila
	div10:
		xor dx,dx
		div [diez]
		push dx
		loop div10
		mov cx,5
	;En el bloque imprime_digito, se recuperan los dígitos anteriores calculados para imprimirse en pantalla.
	imprime_digito:
		mov [conta],cl
		posiciona_cursor [ren_aux],[col_aux]
		pop dx
		or dl,30h
		imprime_caracter_color dl,cBlanco,bgNegro
		xor ch,ch
		mov cl,[conta]
		inc [col_aux]
		loop imprime_digito
		ret
	endp

	;Procedimiento para imprimir el valor de SPEED en pantalla
	;Se imprime en dos caracteres.
	;La variable speed es de tipo byte, su valor puede ser hasta 255d, pero solo se requieren dos dígitos
	;si speed es mayor a igual a 100d, se limita a establecerse en 99d
	IMPRIME_SPEED proc
		;Coordenadas en donde se imprime el valor de speed
		mov [ren_aux],12
		mov [col_aux],9
		;Si speed es mayor o igual a 100, se limita a 99
		cmp [speed],100d
		jb continua
		mov [speed],99d
	continua:
		;posiciona el cursor en la posición a imprimir
		posiciona_cursor [ren_aux],[col_aux]
		;Se convierte el valor de 'speed' a ASCII
		xor ah,ah 		;AH = 00h
		mov al,[speed] 	;AL = [speed]
		aam 			;AH: Decenas, AL: Unidades
		push ax 		;guarda AX temporalmente
		mov dl,ah 		;Decenas en DL
		or dl,30h 		;Convierte BCD a su ASCII
		imprime_caracter_color dl,cBlanco,bgNegro
		inc [col_aux] 	;Desplaza la columna a la derecha
		posiciona_cursor [ren_aux],[col_aux]
		pop dx 			;recupera valor de la pila
		or dl,30h  	 	;Convierte BCD a su ASCII, DL están las unidades
		imprime_caracter_color dl,cBlanco,bgNegro
		ret
	endp

	;Imprime viborita
	IMPRIME_PLAYER proc
		call IMPRIME_HEAD 
		call IMPRIME_TAIL
		ret
	endp

	;Imprime objeto en pantalla
	IMPRIME_ITEM proc
		posiciona_cursor [item_ren],[item_col]
		imprime_caracter_color 3,cVerdeClaro,bgNegro
		ret
	endp

	;Imprime la cabeza de la serpiente
	IMPRIME_HEAD proc
		posiciona_cursor [head_ren],[head_col]
		imprime_caracter_color 2,cCyanClaro,bgNegro
		ret
	endp

	;Imprime el cuerpo/cola de la serpiente
	;Cada valor del arreglo 'tail' iniciando en el primer elemento es un elemento del cuerpo/cola
	;Los valores establecidos en 0 son espacios reservados para el resto de los elementos.
	;Se imprimen todos los elementos iniciando en el primero, hasta que se encuentre un 0 
	IMPRIME_TAIL proc
		lea bx,[tail]
	loop_tail:
		push bx
		mov ax,[bx]
		mov [ren_aux],al
		mov [col_aux],ah
		posiciona_cursor [ren_aux],[col_aux]
		imprime_caracter_color 254,cCyanClaro,bgNegro
		pop bx
		add bx,2
		cmp word ptr [bx],0
		jne loop_tail
		ret 
	endp

	;Borra la serpiente para reimprimirla en una posición actualizada
	BORRA_PLAYER proc
		posiciona_cursor [head_ren],[head_col] 			;Posiciona el cursor en la cabeza
		imprime_caracter_color 254,cNegro,bgNegro 		;Se imprime un caracter negro en su lugar
		lea bx,[tail] 									;Se recorre el cuerpo de la víbora
	loop_tail1:
		push bx
		mov ax,[bx]
		mov [ren_aux],al 								;Se obtiene el renglón y columna de cada elemento		
		mov [col_aux],ah 
		posiciona_cursor [ren_aux],[col_aux] 			;Se posiciona el cursor en el renglón y columna obtenidos
		imprime_caracter_color 254,cNegro,bgNegro 		;Se imprime un caracter negro en su lugar
		pop bx
		add bx,2 										;Se recorre el siguiente elemento
		cmp word ptr [bx],0  							;Se recorre todos los elementos con un valor
		jne loop_tail1
		ret
	endp

	;procedimiento IMPRIME_BOTON
	;Dibuja un boton que abarca 3 renglones y 5 columnas
	;con un caracter centrado dentro del boton
	;en la posición que se especifique (esquina superior izquierda)
	;y de un color especificado
	;Utiliza paso de parametros por variables globales
	;Las variables utilizadas son:
	;boton_caracter: debe contener el caracter que va a mostrar el boton
	;boton_renglon: contiene la posicion del renglon en donde inicia el boton
	;boton_columna: contiene la posicion de la columna en donde inicia el boton
	;boton_color: contiene el color del boton
	IMPRIME_BOTON proc
	 	;background de botón
		mov ax,0600h 		;AH=06h (scroll up window) AL=00h (borrar)
		mov bh,cRojo	 	;Caracteres en color amarillo
		xor bh,[boton_color]
		mov ch,[boton_renglon]
		mov cl,[boton_columna]
		mov dh,ch
		add dh,2
		mov dl,cl
		add dl,2
		int 10h
		mov [col_aux],dl
		mov [ren_aux],dh
		dec [col_aux]
		dec [ren_aux]
		posiciona_cursor [ren_aux],[col_aux]
		imprime_caracter_color [boton_caracter],cRojo,[boton_color]
	 	ret 			;Regreso de llamada a procedimiento
	endp	 			;Indica fin de procedimiento UI para el ensamblador
	
	;Procedimiento para actualizar los milisegundos que transcurren desde el tick inicial
	CRONO proc
		;Se vuelve a leer el contador de ticks
		;Se lee para saber cuántos ticks pasaron entre la lectura inicial y ésta
		;De esa forma, se obtiene la diferencia de ticks
		;por cada incremento en el contador de ticks, transcurrieron 55 ms
		mov ah,00h
		int 1Ah

		;Se recupera el valor de los ticks iniciales para poder hacer la diferencia entre el valor inicial y el último recuperado
		mov ax,[t_inicial]		;AX = parte baja de t_inicial
		mov bx,[t_inicial+2]	;BX = parte alta de t_inicial
		
		;Se hace la resta de los valores para obtener la diferencia
		sub dx,ax  				;DX = DX - AX = t_final - t_inicial, DX guarda la parte baja del contador de ticks
		sbb cx,bx 				;CX = CX - BX - C = t_final - t_inicial - C, CX guarda la parte alta del contador de ticks y se resta el acarreo si hubo en la resta anterior

		;Se asume que el valor de CX es cronómetro
		mov ax,dx

		;Se multiplica la diferencia de ticks por 55ms para obtener 
		;la diferencia en milisegundos
		mul [tick_ms]
		
		;Se guardan los milisegundos en una variable
		;Nota: este valor se guarda en hexadecimal
		mov [milisegundos],ax

		ret
	endp

	;Procedimiento para que la víbora se mueva una posición en cierta dirección
	MOVER proc
		call BORRA_PLAYER 					;Se borra la víbora del jugador

		mov ah, [head_col] 					;Se obtiene el valor del renglón y columna de la serpiente
		mov al, [head_ren]					
		push ax 										;y se guarda en la pila para que esa posición la tome el primer elemento de la cola
		cmp [head_dir], 0 					;Se compara para saber si la dirección es cero (derecha)
		jne izq
		inc [head_col] 							;Si va a la derecha, se incrementa uno el valor de la columna
		jmp cuerpo
	izq:
		cmp [head_dir], 2 					;Se compara para saber si la dirección es dos (izquierda)
		jne arriba
		dec [head_col] 							;Se decrementa uno el valor de la columna
		jmp cuerpo
	arriba:
		cmp [head_dir], 1 					;Se compara para saber si la dirección es uno (arriba)
		jne abajo
		dec [head_ren] 							;Se decrementa uno el valor del renglón
		jmp cuerpo
	abajo:											;Si no se cumple ninguna se mueve hacia abajo
		inc [head_ren]						;Se incrementa uno el valor del renglón

	;Se mueve el cuerpo de la cola. Se recorre el valor de la cola en una posición para que se tenga el valor
	;de la posición pasada del elemento contiguo
	cuerpo: 
		call COMER_OBJ						;Primero se analiza si en la posición actual se comió un objeto						
		lea bx,[tail] 						;se obtiene la posición de la cola para modificarla
		mov cx,[bx] 							;Se guarda el valor de la primera posición
	loop_tail2:
		mov ax,[bx+2] 						;Se guarda el valor de la posicion contigua
		mov [bx+2],cx 						;Se le asigna el valor viejo a la posición actual
		mov cx, ax 								;Se actualiza el valor viejo
		add bx,2 									;Se incrementa en dos la posición
		cmp word ptr [bx+2],0 		;Se recorren las posiciones de la cola hasta que haya un elemento de 0
		jne loop_tail2

		call COMER_MISMA 				;Se comprueba que no se haya comido a sí misma

		pop ax
		mov [tail],ax 						;Se recupera el valor de la cabeza anterior y se le asigna al primer elemento de la cola

		call COMER_MARCO  				;Se analiza si en la posición actual no chocó con un marco
		call IMPRIME_PLAYER 			;Se imprime la serpiente con los valores actualizados
		ret
	endp


	;Procedimiento que compara las posiciones del cuerpo con la posición anterior de la cabeza.
	;Si alguna parte del cuerpo es igual a la de la cabeza se reinicia el juego con el estado STOP.
	COMER_MISMA proc
		lea bx,[tail] 						;se obtiene la posición de la cola para modificarla
	loop_tail4:
		mov ax,[bx] 						;Se guarda el valor de la posición actual
		cmp ah,[head_col] 					;Si el valor de la columna coincide
		jne siguiente
		cmp al,[head_ren]					;Y el valor del renglón también
		jne siguiente
		mov [status],2 						;El status cambia a dos
	siguiente: 								;De lo contrario sigue comparando
		add bx,2 									;Se incrementa en dos la posición
		cmp word ptr [bx],0 		;Se recorren las posiciones de la cola hasta que haya un elemento de 0
		jne loop_tail4
		ret
	endp

	;Procedimiento para calcular el indicador de la velocidad a partir del valor de speed
	;El valor máximo de movimiento es de 300 milisegundos. Cada que se aumenta el valor de speed
	;se le restan 3 milisegundos a dicho valor. El valor mínimo entre movimientos es de 3 milisegundos.
	CALCULO_SPEED proc
		;Se multiplica el valor de speed x10
		mov al, [speed]
		mov bl, 3
		mul bl
		;Se le resta a 300 el valor de dicha multiplicación
		mov bx, 300
		sub bx, ax
		;Ese valor es el nuevo indicador
		mov [speed_indicador], bx

		ret
	endp

	;Proecedimiento para borrar el item actual
	BORRA_ITEM proc
		posiciona_cursor [item_ren],[item_col] 			;Posiciona el cursor en la columna y renglon del item
		imprime_caracter_color 254,cNegro,bgNegro 		;Se imprime un caracter negro en su lugar
		ret 
	endp

	;Procedimiento para calcular la posición aleatoria del item después de que la víbora se lo come
	;Se utiliza el valor del tiempo del sistema y al dividirlo sobre un número, se utiliza el residuo.
	;Se le suma una constante al residuo para obtener un número dentro de un rango de valores donde el
	;mínimo es la constante sumada y el máximo es el divisor - 1 + constante
	CALCULO_ITEM proc
	calculo:
	;Se calcula la columna del item 
		mov ax, 0
		int 1Ah						;Opción AX=0 de la int 1Ah, obtiene los tics del tiempo del sistema en dx
		mov ax, dx				;se cambia el valor a AX para hacer la división
		xor dx, dx				;se cambia el valor de DX a 0 para no afectar la división
		div divisorCol		;DX = DX:AX % 58d => se obtiene un valor en DX de 0d a 57d
		add dl, 21d 			;Se suma 21d a DL para obtener valores de [21d a 78d], que son las columnas disponibles
		mov [item_col], dl 	;Se actualiza el valor de item_col
	;Se calcula el renglon del item	
		mov ax, 0
		int 1Ah						;Opción AX=0 de la int 1Ah, obtiene los tics del tiempo del sistema en dx
		mov ax, dx				;se cambia el valor a AX para hacer la división
		xor dx, dx				;se cambia el valor de DX a 0 para mo afectar la división
		div divisorRen		;DX = DX:AX % 23d => se obtiene un valor en DX de 0d a 22d
		inc dl 						;Se suma 1d a DL para obtener valores de [1d a 23d], que son los renglones disponibles
		mov [item_ren], dl 	;Se actualiza el valor de item_col
		
		mov ah, [head_col] 
		mov al, [head_ren]		;Se obtiene la posición de la cabeza en AX
		mov bh, [item_col]
		mov bl, [item_ren]		;Se obtiene la posición del objeto en BX
		cmp ax, bx 						;Se compara si la cabeza y el objeto están en la misma posición
		je calculo 						;Si es así, se hace un nuevo cálculo del objeto

		mov ax, [tail] 				;Se obtiene la localidad 0 de la cola en AX
		xor di, di 						;Se cambia el valor del indice di a 0
		mov cx, tail_conta 		;CX = numero de elementos en la cola => para repetir el ciclo por cada elemento en la cola				
	loop_tail3:
		cmp [tail+di], bx 		;se compara la posición de ese elemento de a cola con la posición del item
		je calculo  					;Si son iguales, se hace un nuevo cálculo del item
		inc di
		inc di 								;Si no son iguales, se suma 2 a di para comparar el siguiente elemento
		loop loop_tail3

		ret
	endp

	;Procedimiento en el cual se compara la cabeza con el valor del objeto, comer y reposicionar objeto
	;Se utilizan las variables de la posición de la cabeza y las variables del objeto
	COMER_OBJ proc 
		mov bh, [item_col]	;se guardan los valores de la columna 
		mov bl, [item_ren]	;y en el renglón del item en ambas partes del registro BX
		xor bx, ax 					;se utiliza xor para comparar el valor de ax (posición de head) y bx (posicion item)
		jz llamarITEM 			;si la bandera está encendida (son iguales) se salta a llamarITEM
		jmp RETU 						;se salta al final en caso de que no se haya comido nada
	llamarITEM:
		call CALCULO_ITEM		;se llama el procedimiento que calcula la nueva posicion del item
		call IMPRIME_ITEM		;se imprime el item en una posición aleatoria
		mov ax, tail_conta 	;Se pone el contador de la cola en ax
		mul [dos] 					;Se multiplica para usarlo como índice
		mov si, ax
		mov [tail+si], 1d 	;La nueva posición es diferente de cero. Cuando se recorre la cola se termina de recorrer
												;cuando el elemento es cero. Si deja de ser igual a cero se le asigna un valor y se imprime.
		inc [tail_conta] 		;Nuevo valor de la cola
		inc [speed]
		inc [speed]
		call IMPRIME_SPEED
		mov bx, [score] 		;se guarda el valor de score en bx para sumarle 10
		add bx, 10d
		mov [score], bx  		;se guarda el nuevo valor de score para imprimirlo 
		call IMPRIME_SCORE  ;se llama el procedimiento que imprime al score
		mov bx, [hi_score]	;se mueve el highscore a bx para compararlo
		cmp bx, [score]			;se comparan ambos 
		jb HISCORE 					;si score es mayor a higscore se salta para actualizar el high score
		jmp RETU 						;si no se cambia highscore, se sale
	HISCORE:
		mov bx, [score] 		;se mueve score a bx 
		mov [hi_score], bx  ;se cambia highscore por score
		call IMPRIME_HISCORE 	;se imprime highscore
	RETU:
		
		ret
	endp

	;Procedimiento para el estado de STOP
	;Al pulsar STOP, la víbora se detiene, parpadea dos veces y se coloca en la posición inicial
	;Los valores de speed y score se reinician y se debe picar play para que se mueva la víbora 
	;Se utilizan los ticks del sistema para el parpadeo, hasta que pasen 5 ticks continúa el procedimiento
	STOP proc 
		mov conta, 4d 				;Se cambia el valor de conta a 4 para que la víbora parpadee dos veces

	desaparece:
		call BORRA_PLAYER			;Se borra la vibora en la posición donde se detuvo o chocó
		mov ax,0000h 					;opción 0
		int 1Ah 							;interrupción para leer el contador de ticks
		mov flash, dx 				;se mueven los tics parte baja a flash para compararlo despues
		dec conta 						;se decrementa conta para saber que ya se borro la víbora
		jmp esperar						
	aparece:
		call IMPRIME_PLAYER		;Se imprime la vibora en la posición donde se detuvo o chocó
		mov ax,0000h					;opción 0
		int 1Ah 							;interrupción para leer el contador de ticks
		mov flash, dx 				;se mueven los tics parte baja a flash para compararlo despues
		dec conta 						;se decrementa conta para saber que ya se imprimió la víbora
	
	;Los bloques aparece y desaparece siguen su flujo en este bloque donde esperan el tiempo necesario para volver a borrar o imprimir
	esperar:
		int 1Ah 							;interrupción para leer el contador de ticks
		sub dx, flash					;Se le resta a los ticks nuevos, los ticks viejos (flash)
		cmp dx, 5d 						;Se compara la resta con 5
		jbe esperar						;Si es menor (no han pasado 5 ticks), se vuelve a obtener un tick y se compara
		cmp conta, 0 					;Se compara si conta es 0, si lo es termina el parpadeo
		je despues
		mov al, conta 				;se mueve conta a AL para dividirlo sobre dos
		div dos
		cmp ah, 0 						;Si la división no residuo (conta es par), se debe borrar la víbora
		je desaparece 
		jmp aparece 					;Si la división genera residuo (conta es impar), se debe imprimir la víbora

	despues: 								;una vez que acaba el parpadeo se reinician los datos
		call BORRA_PLAYER
		call REGRESA_DATOSIN
		call IMPRIME_PLAYER
		call IMPRIME_SCORE
		call IMPRIME_SPEED
		call BORRA_ITEM
		call CALCULO_ITEM
		call IMPRIME_ITEM
		inc banStop 					;se activa la bandera para indicar que se acaba de realizar el procedimiento STOP

		ret
	endp

	;Procedimiento para regresar a los valores de Head, Tail, Score y Speed iniciales
	;Se llama en el procedimiento STOP
	REGRESA_DATOSIN proc
		mov [head_ren], 12d
		mov [head_col], 25d 	;se regresa la cabeza a la posición inicial
	
		mov cx, [tail_conta] 	;se utiliza el valor de tail_conta para recorrer cada posición de la cola
		xor di, di 						;se vuelve 0 el indice para recorrer la cola
	borrar: 								;todos los elementos de la cola se vuelven cero en el ciclo borrar
		mov [tail+di], 0
		add di, 2
		loop borrar

		xor di, di 						;se vuelve 0 el indice para recorrer la cola
		mov ax, 1100000001100b	;se le asigna el valor del primer elemento de la cola a AX
	meter:									;en este ciclo se le asignan los valores correspondientes a los 4 elementos inciales de la cola
		mov [tail+di], ax 		;se le asigna el valor de AX a una posición de la cola
		sub ax, 0100h					;se le resta 100h a AX (una columna menos)
		add di, 2 						;aumenta el índice
		cmp di, 8 						;se compara el índice a 8 (4 elementos de la cola) para salir del ciclo
		jne meter 

		;se regresan otras variables a su valor inicial
		mov [tail_conta], 4 	
		mov [score], 0
		mov [speed], 0
		mov [speed_indicador], 1000
		mov [speed_conta], 0
		mov [cmp_conta], 0
		mov [status], 0 			;el estado cambia a 0 (pausa)
		mov [head_dir],0 			;la dirección de la cabeza cambia a 0 (para la derecha)
	 	ret 
	endp

	;Procedimiento para identificar cuando la serpiente choca con el marco y se debe reinicar el juego
  COMER_MARCO proc
  	;Se compara si la cabeza toca el renglón 0 (marco superior)
		cmp [head_ren], 0
		jne marco1
		inc [head_ren]  	;para evitar borrar el marco, la cabeza se hace un renglón para abajo
		call STOP 				;se llama el procedimiento STOP para recolocar la serpiente

		;Se compara si la cabeza toca el renglón 24 (marco inferior)
		marco1:
		cmp [head_ren],24
		jne marco2
		dec [head_ren]		;para evitar borrar el marco, la cabeza se hace un renglón para arriba
		call STOP 				;se llama el procedimiento STOP para recolocar la serpiente

		;Se compara si la cabeza toca la columna 20 (marco izquierdo)
		marco2:
		cmp [head_col],20
		jne marco3
		inc [head_col]		;para evitar borrar el marco, la cabeza se hace un renglón a la derecha
		call STOP 				;se llama el procedimiento STOP para recolocar la serpiente

		;Se compara si la cabeza toca la columna 79 (marco derecho)
		marco3:
		cmp [head_col],79
		jne	final1
		dec [head_col] 		;para evitar borrar el marco, la cabeza se hace un renglón a la izquierda
		call STOP 				;se llama el procedimiento STOP para recolocar la serpiente

		final1:						;si no se toca ningun marco, el procedimiento no hace nada
		ret
	endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;FIN PROCEDIMIENTOS;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	end inicio			;fin de etiqueta inicio, fin de programa 
