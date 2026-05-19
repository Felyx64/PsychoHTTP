.global standard_console_write
.global systemcall_console_write

.section .text
  # STANDARD_CONSOLE_WRITE: PRINTOUT A STRING WITHOUT HAVING STRING NEEDING TO BE SPECIFIED. STRING DOES NEED NULL TERMINATOR THOUGH
  # PARAMETER: ECX [CHAR*] (THE STRING ITSELF BEING PRINTEND OUT)
  # OVERWRITES: EBX, EAX, EDX, ESI
  standard_console_write:
    movl $0, %esi                         # Move $0 into %ESI as %ESI may be corrupt which would be bad as %ESI is used to get str leng of what is being printed out.
  _standard_print___str_leng_loop:        # starts get the str leng loop here
    cmpl $0, (%ecx, %esi)                 # check if we have hit a null-terminator (\0) in the char of string im reading
    je _standard_print___loop_end         # jump out of the loop if get str leng is done
    inc %esi                              # increment %ESI aka string length if we did not get a \0
    jmp _standard_print___str_leng_loop   # jump back to the beginning of the loop
  _standard_print___loop_end:             # this marks the end of the get string length loop
    movl %esi, %edx                       # move the string length result of %ESI into %EDX which is the (write) syscall str leng paramater
    call systemcall_console_write         # goto standard console write syscall function to write out the text
    ret

  # SYSTEMCALL_CONSOLE_WRITE: PRINT OUT A STRING TO THE CONSOLE BUT STRING NEEDS TO BE SPECIFIED
  # PARAMETER: EDX [INT64] (THE LENGTH OF THE STRING BEING PRINTED OUT)
  # PARAMETER: ECX [CHAR*] (THE STRING ITSELF BEING PRINTEND OUT)
  # OVERWRITES: EBX, EAX
  systemcall_console_write:
    movl $1, %ebx
    movl $4, %eax
    int $0x80
    ret
