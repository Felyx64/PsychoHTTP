.section .text
  #? UNTESTED
  # copies string from dest-1 to dest-2
  # Param: EAX, dest-1
  # Param: EBX, dest-2
  # Overwrites: ECX, EDX
  String_Copy:
    movl $0, %ecx                 # index of both strings we are copying
    .str_copy_loop:               # start of loop
    cmpb $0, (%eax, %ecx)         # check if we hit '\0' terminator
    je .done_copying_string       # jump out of loop if we did
    movb (%eax, %ecx), %dl        # copy string from dest-1 to temp %dl if we did not hit '\0'
    movb %dl, (%ebx, %ecx)        # copy string to dest-2 from %dl
    inc %ecx                      # increment the index
    jmp .str_copy_loop            # jump back to start of loop
    .done_copying_string:         # end of string copy loop
    movb $0, (%ebx, %ecx)         # add '\0' null terminator to the dest-2
    ret

  #? UNTESTED
  # concats string dest-1 to dest-2 with a max_val as 3rd param
  # Param: EAX, dest-1
  # Param: EBX, dest-2
  # Overwrites: ECX, EDX
  # Returns EBX, aka dest-2
  String_Concat:
    movl $0, %ecx                 # initiate %ecx which is index of dest-2
    .get_start_second_param:      # start loop to search for end of dest-2
    cmpb $0, (%ebx, %ecx)         # check if we hit end of dest-2
    je .done_getting_start        # jump to end of loop if we hit end of dest-2
    inc %ecx                      # increment index of dest-2 if we did not hit end of dest-2
    jmp .get_start_second_param   # jump to begin of loop to continue loop
    .done_getting_start:          # label for end of get end of dest-2 loop here

    movl $0, %edx                 # initiate %edx which is index of dest-1
    .concat_desta_to_destb:       # start of concat loop
    cmpb $0, (%eax, %edx)         # check if we hit null terminator on dest-1 to see if concat loop is done
    je .done_concatinating        # jump to end of loop if done with concatination
    movb (%eax, %edx), %dl        # move char from dest-1 to %dl
    movb %dl, (%ebx, %ecx)        # move char from %dx to dest-2
    inc %edx                      # increment index of dest-2
    inc %ecx                      # increment index of dest-1
    jmp .concat_desta_to_destb    # jump back to begin of concatination loop
    .done_concatinating:          # end of concatination loop
    movb $0, (%ebx, %edx)         # add '\0' null terminator to the dest-2
    ret

  #? UNTESTED
  # compare 2 strings
  # compares to strings byte by byte
  # Param: EAX, dest-1
  # Param: EBX, dest-2
  # Overwrites: EDX
  # Return: ECX, 1 if not the same, 0 if the same
  String_Compare:
    movl $0, %ecx                 # move string index into %ecx
    .string_compare_loop:         # start comparison loop
    cmpb $0, (%eax, %ecx)         # end if we hit '\0' of dest-1
    je .check_second_null         # jump to check dest-2 if we did hit '\0'
    movb (%eax, %ecx), %dl        # move char in dest-1 into tmp %dl
    cmpb %dl, (%ebx, %ecx)        # compare dest-1 to dest-2 via the tmp
    inc %ecx                      # increment %ecx if both strings are still equal
    je .string_compare_loop       # jump back to start of compare loop if we still have not hit the end
    jmp .not_equal_string         # jump to the error label if both are not equal
    .check_second_null:           # checks if we also hit dest-2 end
    cmpb $0, (%ebx, %ecx)         # check if char in dest-2 is also a '\0'
    movl $0, %ecx                 # move the 0 into %ecx signifying there is not an error
    je .end_of_compare_loop       # jump to end of loop if both are at the end
    .not_equal_string:            # jump to this label if both strings are not equal
    movl $1, %ecx                 # move the error code into %ecx if we did get an error
    .end_of_compare_loop:         # jump here if we did not get an error at the end of the loop
    ret

  # search for certain word
  String_Search:
    ret

  # search for a char in string
  String_Search_Chr:
    ret
