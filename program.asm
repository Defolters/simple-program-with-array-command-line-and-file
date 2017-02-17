code_seg segment
ASSUME CS:CODE_SEG,DS:code_seg,ES:code_seg
org 100h
;=====================================================   
;Macros:
scan_from_keyboard macro var; macro for input a char in variable
local input_is_enter, input_is_digit, first_input, second_input, exit
push AX
push DX
;---------------------------------------------------------------
first_input:
;read first digit from keyboard  (tens)
mov ah,1 
int 21h 
xor ah,ah
;check that the entered character - a digit, otherwise offer to enter the digit again
cmp al, 39h
ja first_input

cmp al, 30h
jb first_input
 
push ax
;---------------------------------------------------------------
second_input:
;read second digit from keyboard  (units)
mov ah,1 
int 21h 
xor ah,ah
;check that the entered character - a digit, otherwise offer to enter the digit again
cmp al, 39h
ja second_input

cmp al, 30h
jae input_is_digit

;if the entered character - a enter, we don't consider it
cmp al, 0Dh
jne second_input
jmp  input_is_enter
;---------------------------------------------------------------
input_is_digit:
;if the entered character - a digit, we transform it from ascii to value
sub al, 30h
mov var, ax

pop ax

sub al, 30h
jz  exit

;transform the first entered character into the tens
mov BL, 10
mul BL        
add var, ax

jmp  exit
;---------------------------------------------------------------
input_is_enter:
pop ax
sub al, 30h
mov var, ax  

exit:
 
pop DX
pop AX
endm
;---------------------------------------------------------------
print_message macro message ;print message on the screen
local msg, nxt
push AX
push DX

call print_newLine


mov DX, offset msg
mov AH, 09h
int 21h 

call print_newLine

pop DX
pop AX
jmp nxt
msg DB message,'$'
nxt:
endm 
;---------------------------------------------------------------
check_input macro var, max ;check the entered value, because it should not to exceed bounds of array
    local contt
    push ax 
    
    mov ax, max 
    cmp ax, var
    jnb contt
    print_message 'You are out of array bounds'

    contt:
    pop ax
endm
;=====================================================  
start:
main proc near

mov CL, ES:[80h] ; check length parameter in psp
cmp CL, 0
jne $cont ;if length not equal 0, continue

print_message 'Not command line parameters' ; not parameters
; program was run without parameters
int 20h
;---------------------------------------------------------------
$cont:
xor BH, BH
mov BL, ES:[80h]
mov byte ptr [BX+81h], 0
;---------------------------------------------------------------
mov CL, ES:80h ;length of tale
xor CH, CH
cld
mov DI, 81h ; beginning of tale
mov AL,' ' ; remove space
repe scasb ; scan tale while space
dec DI
;---------------------------------------------------------------
mov AX, 3C02h ; Create new file for write

mov DX, DI 
int 21h
jnc createOK  

print_message 'ERROR: File has not been created'
int 20h
;---------------------------------------------------------------
createOK:
mov handler, ax 
;---------------------------------------------------------------
print_message 'File has been created'
print_message 'Enter a number of char that you want to edit'   

scan_from_keyboard number_of_char 

;if number_of_char = 0, close program
cmp number_of_char, 0
jnz cont
ret

cont:
 
mov cx, number_of_char
;---------------------------------------------------------------
write_char_in_array_from_keyboard:

call read_X_coord
call read_Y_coord

;write char in array (x,y)
print_message 'Enter a symbol:'
mov ah,1
int 21h
mov si, X_coord
add si, Y_coord
mov array[si],al

loop write_char_in_array_from_keyboard
;---------------------------------------------------------------
call print_array_on_the_screen
call write_array_to_file

ret
main endp    
;=====================================================
;Procedures:   
read_X_coord proc near
    print_message 'Enter X coord(0-79)'
    
    scan_from_keyboard X_coord
    
    check_input X_coord, 79 
    jns  continue_X_coord
    jmp read_X_coord
    
    continue_X_coord:        
    ret
read_X_coord endp
;---------------------------------------------------------------
read_Y_coord proc near
    print_message 'Enter Y coord(0-24)'
    
    scan_from_keyboard Y_coord
    
    check_input Y_coord, 24
    jns  continue_Y_coord
    jmp read_Y_coord
    
    continue_Y_coord:
    mov ax, Y_coord
    cmp ax, 0
    jz if_zero
    mov BL, 80
    mul BL
    
    if_zero: 
    mov Y_coord, ax

    ret
read_Y_coord endp 
;---------------------------------------------------------------
print_array_on_the_screen proc near
   
    call print_newLine
    
    mov si,0
    mov cx, 25; DOSBOX PRINTS(CONTAINS) ONLY 23 LINES
    loopone: 
        push cx
        mov cx, 80
        
    looptwo:
        mov	dl,array[si]
        mov	ah,02h
        int	21h
        inc si
        
    loop looptwo
        
    pop cx       
    loop loopone
    ret
print_array_on_the_screen endp 
;---------------------------------------------------------------
write_array_to_file proc near      
    mov bx, handler
  
    mov pointerToArray, 0
;write to file first 80 symbols, then go to a new line, write next 80 symbols, and so on
write_in_file_while:
    mov ah, 40h
    mov cx, 80
    mov dx, offset array
    add dx, pointerToArray
    add pointerToArray, 80
    int 21h
   
    
    mov AH, 40h
    mov cx, 2
    mov dx, offset newLine
    int 21h
    
    cmp pointerToArray, 2000
jne write_in_file_while
     
    mov AH, 3Eh
    mov BX, handler
    int 21h
    
    ret   
write_array_to_file endp    
;---------------------------------------------------------------
print_newLine proc near
push dx
push ax

mov dx, offset newLine
mov ah, 9
int 21h 

pop ax
pop dx
ret    
print_newLine endp
;=====================================================  
array db 2000 DUP(' ')
number_of_char dw ?
X_coord dw ?
Y_coord dw ? 
handler dw ?
newLine db 13,10,'$' 
pointerToArray dw 0
;=====================================================  
code_seg ends
end start 
