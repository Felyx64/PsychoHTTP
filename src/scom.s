# SCOM which stands for: State. Carry. Over. Memory
# is reserved memory used to handle transitional memory when transitioning from state to state.
# Without having to deal with the heap.
# GSCOM Also exists as always alive memory: Global, State, Carry, Over, Memory

.section .bss
  SCOM_User_Server_Request:
    .space 1024

  SCOM_File_Read_Results:
    .space 4096

  SCOM_File_Write_Data:
    .space 1024

  SCOM_IntStr_Convert_Results:
    .space 512

  SCOM_Response_Creation_Table:
    .space 6144

  GSCOM_Server_Filter:
    .space 1024

  SCOM_converted_chunked_response_data:
    .space 256

  SCOM_extracted_json_title_data:
    .space 65

  SCOM_extracted_json_description_data:
    .space 257

.section .text
  # clears an scom if needed
  # Param: (%eax) pointer to scom that has to be cleared
  # OVERWRITES: EBX
  Clear_SCOM:
    movl %eax, %ebx       # copy scom pointer to %ebx
    addl $1024, %ebx      # add scom's limit to %ebx
    .clear_loop:          # start clerance loop
    movb $0, (%eax)       # move 0 into the scom index
    incl %eax             # increment %eax
    cmpl %ebx, %eax       # compare the max and current pointer
    jne .clear_loop       # jump back to the start of the loop if we're not done clearing'
    ret

  # clears an scom with 2048 size if needed
  # Param: (%eax) pointer to scom that has to be cleared
  # OVERWRITES: EBX
  Clear_SCOM_4096:
    movl %eax, %ebx       # copy scom pointer to %ebx
    addl $4096, %ebx      # add scom's limit to %ebx
    .clear_loop_4096:     # start clerance loop
    movb $0, (%eax)       # move 0 into the scom index
    incl %eax             # increment %eax
    cmpl %ebx, %eax       # compare the max and current pointer
    jne .clear_loop_4096  # jump back to the start of the loop if we're not done clearing'
    ret

  Clear_SCOM_6144:
    movl %eax, %ebx       # copy scom pointer to %ebx
    addl $6144, %ebx      # add scom's limit to %ebx
    .clear_loop_6144:     # start clerance loop
    movb $0, (%eax)       # move 0 into the scom index
    incl %eax             # increment %eax
    cmpl %ebx, %eax       # compare the max and current pointer
    jne .clear_loop_6144  # jump back to the start of the loop if we're not done clearing'
    ret

  # copies and pastes scom from 1 memory location to another
  # Param: (%eax) copied scom location
  # Param: (%ebx) pasted scom location
  # OVERWRITES: ECX, EDX
  Copy_SCOM:
    movl %eax, %ecx       # move %eax ptr to %ecx
    addl $1023, %ecx      # add 1023 to %ecx so it can act as a limit to where we are writing
    .copy_loop:           # start copying
    movb (%eax), %dl      # move what's in %eax in the temp %edx
    movb %dl, (%ebx)      # move temp into %ebx
    cmpl %eax, %ecx       # compare %eax to limiter %ecx
    je .copying_done      # jump to copying done if copying we done
    incl %eax             # incrememnt %eax if not
    incl %ebx             # incrememnt %ebx if not
    jmp .copy_loop        # jump back to loop if we are not done looping
    .copying_done:        # label if copying has been done
    ret
