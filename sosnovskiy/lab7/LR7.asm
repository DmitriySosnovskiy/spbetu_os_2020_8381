DATA SEGMENT
	PSP_SEGMENT dw 0

	OVL_PARAM_SEG 			dw 0
	OVL_ADRESS 				dd 0

	mem_cl_str				db 13,10, "Cleared memory$"
	size_error_str 		db 13, 10, "Can't get overlay size$"
	no_file_str 				db 13, 10, "No overlay file$"
	no_path_str 				db 13, 10, "Can't find path$"
	load_error_str 			db 13, 10, "Overlay wasn't load$"
	ovl1_str 				db "ovl1.ovl", 0
	ovl2_str 				db "ovl2.ovl", 0
	STR_PATH 				db 100h dup(0)
	OFFSET_OVL_NAME 		dw 0
	NAME_POS 				dw 0
	MEMORY_ERROR 			dw 0
	
	DTA 					db 43 dup(0)
DATA ENDS

STACKK SEGMENT STACK
	dw 100h dup (0)
STACKK ENDS

CODE SEGMENT
	ASSUME CS:CODE, DS:DATA, SS:STACKK

print 	PROC	near
		push 	AX
		mov 	AH, 09h
		int		21h
		pop 	AX
	ret
print 	ENDP

FREEMEM 	PROC
		lea 	BX, PROGEND
		mov 	AX, ES
		sub 	BX, AX
		mov 	CL, 8
		shr 	BX, CL
		sub 	AX, AX
		mov 	AH, 4Ah
		int 	21h
		jc 		MCATCH
		mov dx, offset mem_cl_str
		call print
		jmp 	MDEFAULT
	MCATCH:
		mov 	MEMORY_ERROR, 1
	MDEFAULT:
	ret
FREEMEM 	ENDP


OVL_RUN PROC
		push	AX
		push	BX
		push	CX
		push	DX
		push	SI

		mov 	OFFSET_OVL_NAME, AX
		mov 	AX, PSP_SEGMENT
		mov 	ES, AX
		mov 	ES, ES:[2Ch]
		mov 	SI, 0
	FIND_ZERO:
		mov 	AX, ES:[SI]
		inc 	SI
		cmp 	AX, 0
		jne 	FIND_ZERO
		add 	SI, 3
		mov 	DI, 0
	WRITE_PATH:
		mov 	AL, ES:[SI]
		cmp 	AL, 0
		je 		WRITE_PATH_NAME
		cmp 	AL, '\'
		jne 	NEW_SYMB
		mov 	NAME_POS, DI
	NEW_SYMB:
		mov 	BYTE PTR [STR_PATH + DI], AL
		inc 	DI
		inc 	SI
		jmp 	WRITE_PATH
	WRITE_PATH_NAME:
		cld
		mov 	DI, NAME_POS
		inc 	DI
		add 	DI, offset STR_PATH
		mov 	SI, OFFSET_OVL_NAME
		mov 	AX, DS
		mov 	ES, AX
	UPDATE:
		lodsb
		stosb
		cmp 	AL, 0
		jne 	UPDATE

		mov 	AX, 1A00h
		mov 	DX, offset DTA
		int 	21h
		
		mov 	AH, 4Eh
		mov 	CX, 0
		mov 	DX, offset STR_PATH
		int 	21h
		
		jnc 	NOERROR
		mov 	DX, offset size_error_str
		call 	print
		cmp 	AX, 2
		je 		NOFILE
		cmp 	AX, 3
		je 		NOPATH
		jmp 	PATH_ENDING
	NOFILE:
		mov 	DX, offset no_file_str
		call 	print
		jmp 	PATH_ENDING
	NOPATH:
		mov 	DX, offset no_path_str
		call 	print
		jmp 	PATH_ENDING
	NOERROR:
		mov 	SI, offset DTA
		add 	SI, 1Ah
		mov 	BX, [SI]
		mov 	AX, [SI + 2]
		mov		CL, 4
		shr 	BX, CL
		mov		CL, 12
		shl 	AX, CL
		add 	BX, AX
		add 	BX, 2
		mov 	AX, 4800h
		int 	21h
		
		jnc 	SET_SEG
		jmp 	PATH_ENDING
	SET_SEG:
		mov 	OVL_PARAM_SEG, AX
		mov 	DX, offset STR_PATH
		push 	DS
		pop 	ES
		mov 	BX, offset OVL_PARAM_SEG
		mov 	AX, 4B03h
		int 	21h
		
		jnc 	LO_SUCCESS		
		mov 	DX, offset load_error_str
		call 	print
		jmp		PATH_ENDING

	LO_SUCCESS:
		mov		AX, OVL_PARAM_SEG
		mov 	ES, AX
		mov 	WORD PTR OVL_ADRESS + 2, AX
		call 	OVL_ADRESS
		mov 	ES, AX
		mov 	AH, 49h
		int 	21h

	PATH_ENDING:
		pop 	SI
		pop 	DX
		pop 	CX
		pop 	BX
		pop 	AX
		ret
	OVL_RUN ENDP
	
	BEGIN:
		mov 	AX, DATA
		mov 	DS, AX
		mov 	PSP_SEGMENT, ES
		call 	FREEMEM
		cmp 	MEMORY_ERROR, 1
		je 		MAIN_END
		mov 	AX, offset ovl1_str
		call 	OVL_RUN
		mov 	AX, offset ovl2_str
		call 	OVL_RUN
		
	MAIN_END:
		mov AX, 4C00h
		int 21h
	PROGEND:
CODE ENDS
END BEGIN