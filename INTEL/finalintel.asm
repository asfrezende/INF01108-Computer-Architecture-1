; Alexandre Schumacher Fermino Rezende
; 00578936

.model small

.stack 100h

CR	equ	0Dh
LF	equ	0Ah
BS  equ 08h

.data

; ===========================================
; VARIÁVEIS PARA NOME DO ARQUIVO E PALAVRA BUSCADA:
NOMEARQ	db 80 dup(0)
CMDLINE	db 80 dup(0)
PALAVRA db 80 dup(?)
PALAVRAACHOU db 80 dup(?)

; ===========================================
; NUMERO DE LINHAS E RESPOSTA (S/N/outro)
linhas	db 3 dup (0)
res		db 1 dup (0)

; ===========================================
; BUFFER DO CONTEUDO DO ARQUIVO:
BUFFER 	db 1000 dup(0)
BSZ		dw 0			; buffer size

; ===========================================
; MENSAGENS PADRÃO:
msg1	db	CR, LF, "-- Que palavra voce quer buscar?", CR, LF, 0
msg2	db	CR, LF, "-- Foram encontradas as seguintes ocorrencias:", 0
msg3	db	CR, LF, "-- Fim das ocorrencias.", 0
msg4	db	CR, LF, "-- Quer buscar outra palavra? (S/N)", CR, LF, 0
msg5	db	CR, LF, "-- Nao foram encontradas ocorrencias.", 0
msg6	db	CR, LF, "-- Encerrando.", 0
msg7	db	CR, LF, "-- Por favor, responda somente S ou N.", 0

; ===========================================
; MENSAGENS DE ERRO
msg8	db	"-- Erro ao abrir o arquivo.", 0
msg9	db	"-- Erro ao fechar arquivo.", 0

; ===========================================
; MENSAGENS PARA IMPRESSÃO DE OCORRENCIA:
msg10	db	"Linha ", 0
msg11	db	": ", 0
msg12	db	CR, LF, 0

; ===========================================
; FLAGS:
flag	db	0
flag_fim db 0
flag_nl	db 0		; flag para nova linha
simnao	db 0		; flag para resposta/continuar busca

; ===========================================
; CONTADORES:
conts	dw	0		; contador de ocorrencias
contl	dw	1		; contador de linhas

; ===========================================
; VARIÁVEIS PARA MANIPULAÇÃO DE STRING:
sw_n	dw	0
sw_f	db	0
sw_m	dw	0

; FILE HANDLE:
FH		dw	0
 
.code
.startup

; =========================================================
; Leitura da linha de comando

push ds 		; Salva as informacoes de segmentos
push es
mov ax, ds 		; Troca DS com ES para poder usa o REP MOVSB
mov bx, es
mov ds, bx
mov es, ax
mov si, 80h 	; Obtem o tamanho da linha de comando e coloca em CX
mov ch, 0
mov cl, [si]
mov ax, cx 		; Salva o tamanho do string em AX, para uso futuro
mov si, 81h 	; Inicializa o ponteiro de origem
lea di, CMDLINE ; Inicializa o ponteiro de destino
rep movsb
pop es 			; retorna os dados dos registradores de segmentos
pop ds
; =========================================================

;	Filtragem do nome do arquivo
	call filtragem
	lea bx, NOMEARQ

; ===========================================
;	 Inicialização:
;	- abre o arquivo e o salva no buffer
;	- notificar se tiver erro e encerrar o programa

	xor bx, bx
	call open_file
	call read_file
	
; ===========================================
;	Primeira consulta:
;	- solicitar palavra a ser consultada
;	- leitura e checagem da palavra
;	- consulta e emissão de ocorrencias, se houver alguma

flag_zero1:
	lea	 bx, msg1
	call print_msg
	lea bx, PALAVRA
	call gets_string
	cmp	flag, 1
	je	flag_zero1
	
	call consulta
	cmp	conts, 0
	jne loop_main
	lea bx, msg5
	call print_msg
	
; ===========================================
; 	Loop principal:
;	- consulta: buscar outra palavra?
;	- se S, continuar o loop,
;	- se N, encerrar o programa
;	- se responder outro caractere, perguntar novamente

;	Busca da palavra:
;	- emissão de ocorrencias, se houver alguma
;	- retorno ao loop principal

loop_main:
    lea bx, msg3
    call print_msg
    
volta_main:
;	Pega resposta S/N 
    lea bx, msg4
    call print_msg
    call pega_res
    
;	Verifica resposta S/N
    cmp simnao, 0
	je fim_programa
	
    cmp simnao, 1
	je segue_main
   
;	Se nao for N ou S, pedir a palavra novamente
	lea bx, msg7
	call print_msg
	jmp volta_main
	

segue_main:
	lea bx, msg1
	call print_msg
	call limpa_buffer
    call gets_string
    cmp flag, 1
    je flag_zero1
    
;	Reinicializacao de variaveis
    lea si, BUFFER        
    mov flag_fim, 0       
    mov contl, 1          
    mov flag_nl, 1        
    
    call consulta
    cmp conts, 0
    jne loop_main
    lea bx, msg5
    call print_msg
    jmp loop_main
	
; ===========================================
;	Fim do programa:
;	- fechar o arquivo
;	- notificar fim do programa
;	- encerrar execução

fim_programa:
	call close_file
	lea bx, msg6
	call print_msg
	mov ax, 4C00h
    int 21h
	.exit


; =========================================================
; =========================================================
; Filtragem: pega apenas o do nome do arquivo da linha de comando
; Inicialização:
;	SI = *(CMDLINE)
;	CX = strlength(&SI)
;	DX = 0

filtragem proc near

lea	si, CMDLINE 
mov	cx, ax
 	
xor dx, dx
xor bx, bx

; Loop:
;	while(SI[BX] != ' ')
;		BX++
loop_filtragem:
	cmp byte ptr [si+bx], ' ' 	; transformação de word para byte para comparação
	je	filtragem_in
	inc	bx
	loop loop_filtragem
	
; Filtragem do nome arquivo:
;	BX++
;	DI = *NOMEARQ
;	while(SI[BX] != '\0' || BX != CX){
;		AL = SI[BX]
;		NOMEARQ[BX] = AL
;	} NOMEARQ[BX+1] = '\0'
filtragem_in:
	lea di, NOMEARQ
	inc bx

loop_copia:
	cmp	bx, cx
	je	final_copia
	
	cmp	byte ptr [si+bx], 0
	je	final_copia
	
	mov	al, [si+bx]
	mov	[di], al
	
	inc	bx
	inc	di
	
	jmp	loop_copia
	
final_copia:
	mov byte ptr [di], 0
	ret
	
filtragem endp

; =========================================================
; =========================================================
; Print_msg: imprime uma das mensagens padroes
; while(*s!=0){
;	putchar(*s)
;	s++ }

print_msg proc near
		mov dl, [bx]
		cmp	dl, 0
		je	final_print_msg
		
		push bx
		mov	ah, 2
		int	21h
		pop	bx
		inc	bx
		
		jmp	print_msg
		
final_print_msg:
	ret
	
print_msg endp

; =========================================================
; =========================================================
; Gets_string: lê determinada palavra
; while(char != ENTER)
;	PALAVRA[DX] = *char
;	MAX = 15
;	CX = MAX

gets_string proc near

	xor bx, bx
	xor cx, cx
;	Ponteiro para a string
	xor dx, dx
	xor ah, ah
	
;	Maximo de caracteres aceitos
	mov	cx, 25
	lea bx, PALAVRA

; "Main" da função
g_s:
;	Waitkey
	mov	ah, 7
	int	21h
	
;	Leitura da tecla e inserção na string
	cmp	al, CR
	jne	g_s1
	
;	Fim da string
	mov	byte ptr[bx], 0
	
	call check_string
	ret
	
g_s1:
;	if(char != BS)
;	(g_s2)
	cmp	al, BS
	jne	g_s2
	
;	else if(char == 0)
;	ret
	cmp	dx, 0
	jz	g_s
	
;	else 
;	(inserção do BackSpace)
;	return
	push dx
	mov	dl, BS
	mov ah, 2
	int	21h
	
	mov	dl, ' '
	mov ah, 2
	int 21h
	pop dx
	
	dec bx
	inc cx
	dec dx
	
	jmp	g_s
	
g_s2:
;	if(CX = 0)
;	return
	cmp	cx, 0
	je	g_s
	
;	if(AL >= ' '){
;		*char = AL
;		char++
;		CX++
;		DX++ }

	cmp	al, ' '
	jl	g_s

	mov	[bx], al
	inc	bx
	dec cx
	inc dx
	
;	Inserção do caractere na string
	push dx
	mov	dl, al
	mov ah, 2
	int 21h
	pop dx
	
	jmp	g_s
	
gets_string endp

; =========================================================
; =========================================================
; Check string: confere se a palavra a ser buscada é valida
; while(char != 0 && char < 65)
;	char++
;	if(char < 65)
;		(clear_string)
;	return

check_string proc near

	lea	si, PALAVRA
	xor bx, bx
	mov	flag, 0

;	Confere os caracteres até o fim da string 
;	ou até achar um caractere inválido
loop_check:

	cmp byte ptr [si+bx], 0
	je	final_check
	
	cmp byte ptr [si+bx], 'A'
	jb	tecla_invalida
	jmp	segue_check
	
;	Se o caractere for inválido, seta a flag e retorna
tecla_invalida:
	mov flag, 1
	ret

;	Se não, continuar checagem
segue_check:
	inc	bx
	loop loop_check
	
;	Quando terminar, retornar
final_check:
	ret

check_string endp

; =========================================================
; =========================================================
; Open file: abre arquivo e notifica se houver erro

open_file proc near

	mov	FH, 0
	
	mov	ah, 3Dh
	mov al, 0
	lea dx, NOMEARQ
	int 21h
	
	jnc	ok1
	lea bx, msg8
	call print_msg
	jmp	fim_programa

ok1:
	mov	FH, ax
	ret
open_file endp

; =========================================================
; =========================================================
; Close file: fecha arquivo e seta uma flag se houver erro

close_file proc near

	mov ah, 3Eh
	mov	bx, FH
	int 21h
	
	jnc	ok2
	lea	bx, msg9
	call print_msg
	
ok2:
	ret
close_file endp

; =========================================================
; =========================================================
; Read file: salva o conteudo do arquivo num buffer de string

read_file proc near

	mov	ah, 3Fh
	mov bx, FH
	mov cx, 999
	lea dx, BUFFER
	int 21h
	mov	BSZ, ax
	
;	Prepara o registrador para procura da palavra
	lea si, buffer

	ret
read_file endp

; =========================================================
; =========================================================
; Consultas: confere o buffer em busca da palavra escolhida
; ao encontrar a palavra, emitir notificação de ocorrencia
; repetir o processo até o fim do arquivo. Se não encontrar 
; a palavra, notificar que nao ha ocorrencia.

consulta proc near

;	Inicialização:
;	- colocar strings nos registradores
;	- preparar flags
    lea si, BUFFER 
    lea di, PALAVRA    
    
    mov conts, 0        
    mov flag_fim, 0        
    mov contl, 0          
    mov flag_nl, 1         

loop_consulta:
    
    cmp si, offset BUFFER 
    jb fim_arquivo
    mov bx, offset BUFFER
    add bx, BSZ
    cmp si, bx            
    jae fim_arquivo
	
segue1:
    
    mov al, [si]          

;	Verifica se chegou no fim do arquivo
    cmp al, 0             
    je fim_arquivo

;	Verifica se chegou no fim da linha
    cmp al, CR            
    je segue_consulta1
    cmp al, LF            
    je check_nl
    
    jmp segue_consulta1

;	Seta flag de nova linha
check_nl:
    mov flag_nl, 1
    jmp segue_consulta1

;	Incrementa contagem de linhas e reseta flag 
segue_consulta1:
    cmp flag_nl, 1        
    jne segue_consulta2
    call nova_linha
    mov flag_nl, 0      

segue_consulta2:
    lea di, PALAVRA
 
; 	Compara a palavra com o texto:
;	- se um caractere for diferente, segue no texto e reseta a palavra
;	- se chegar no último caractere da palavra buscada (0), relatar ocorrencia
compara_palavra:
    mov al, [si]          
    mov bl, [di]         
    
    cmp bl, 0             
	je	encontrou_palavra
   
    cmp al, bl            
    jne next_char 

    inc si
    inc di
    jmp compara_palavra

next_char:
    inc si
    lea di, PALAVRA
    jmp loop_consulta

encontrou_palavra:
    call ocorrencia      
    inc si
    jmp loop_consulta     

fim_arquivo:
    ret

consulta endp

; =========================================================
; =========================================================
; Nova linha:

nova_linha proc near
	inc	contl
	ret
nova_linha endp
	
; =========================================================
; =========================================================
; Ocorrencia: notifica quando uma palavra é encontrada no texto

ocorrencia proc near

;	Conversão da palavra para maiúsculo	
	lea di, PALAVRA
	lea bx, PALAVRAACHOU
	call to_upperkey
	
	inc conts
	
;	Comparar conts com 1 para notificação da msg2
	cmp conts, 1
	jne segue_ocorrencia
	
	lea bx, msg2
	call print_msg
	
segue_ocorrencia:
	
;	Espaço em branco
	lea bx, msg12
	call print_msg
	
;	"Linha "
	lea bx, msg10
	call print_msg
	
;	Impressao do numero de linhas
	mov ax, contl
	lea bx, linhas
	call print_num
	lea bx, linhas
	call print_num2
	
;	": "
	lea bx, msg11
	call print_msg
	
;	Impressao da palavra em maiusculo
	lea bx, PALAVRAACHOU
	call print_msg

	call limpa_bUPPER
	
	ret
ocorrencia endp

; =========================================================
; =========================================================
; Print número:
; converte um numero para string e coloca na variável

print_num proc near

	mov		sw_n,ax
	mov		cx,5
	mov		sw_m,10000
	mov		sw_f,0
	
sw_do:

	mov		dx,0
	mov		ax,sw_n
	div		sw_m
	
	cmp		al,0
	jne		sw_store
	cmp		sw_f,0
	je		sw_continue

sw_store:
	add		al,'0'
	mov		[bx],al
	inc		bx
	
	mov		sw_f,1
sw_continue:
	
	mov		sw_n,dx
	
	mov		dx,0
	mov		ax,sw_m
	mov		bp,10
	div		bp
	mov		sw_m,ax
	
	dec		cx
	
	cmp		cx,0
	jnz		sw_do

	cmp		sw_f,0
	jnz		sw_continua2
	mov		[bx],'0'
	inc		bx
sw_continua2:


	mov		byte ptr[bx],0
		
	ret
print_num endp

; =========================================================
; =========================================================
; Pega resposta: pega um unico caractere e seta a flag de acordo com a resposta

pega_res proc near

	mov ah, 1
	int 21h
	and al, 0DFh
	
	cmp al, 'S'
	je tecla_s
	
	cmp al, 'N'
	je tecla_n
	
	mov simnao, 2
	ret
	
tecla_s:
	mov simnao, 1
	ret

tecla_n:
	mov	simnao, 0
	ret
	
pega_res endp

; =========================================================
; =========================================================
; Print numéro (2): imprime a string de número convertido

print_num2	proc	near

	mov		dl,[bx]
	cmp		dl,0
	je		ps_1

	push	bx
	mov		ah,2
	int		21H
	pop		bx

	inc		bx

	jmp		print_num2
		
ps_1:
	ret
	
print_num2	endp

; =========================================================
; =========================================================
; Limpa buffer: limpa o buffer para inserção de nova PALAVRA

limpa_buffer proc near

	mov ah, 0Ch
	xor al, al
	int 21h
	ret
	
limpa_buffer endp

; =========================================================
; =========================================================
; To upper-key: converte a palavra para maiúsculo

to_upperkey proc near

loop_to_uk:
	mov al, [di]
	cmp al, 0
	je fim_uk
	
;	Se o caractere estar antes de 'a' ou depois de 'z', ja é maiusculo
	cmp al, 'z'
	ja maisc
	cmp al, 'a'
	jb maisc
	
;	Se nao for o caso, converter para maiusculo
	sub al, 32	
	
maisc:
;	Inserir caractere na string nova
	mov [bx], al
	inc di
	inc bx
	jmp loop_to_uk
	
fim_uk:	
	ret
to_upperkey endp

; =========================================================
; =========================================================
; Limpa buffer UPPER: limpa buffer da palavra maiuscula

limpa_bUPPER proc near

    lea di, PALAVRAACHOU  
    mov cx, 80             
    mov al, ' '            

loop_buffer:
    mov [di], al           
    inc di 
	cmp [di], 0
    jne loop_buffer      

	ret
limpa_bUPPER endp

end
