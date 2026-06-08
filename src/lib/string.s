.section .text
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

  #? UNTESTED
  # Search for first word in string line beginning
  # EAX, string we are searching the line from
  # EBX, buffer which will hold the line we are getting, 1 if we got nothing in the search
  # ECX, line start string we are searching for
  # Overwrites: EDX, ESI
  String_Search_Line_Begin:
    movl $0, %esi                 # start array get index at 0
    movl $0, %edi                 # start array set index at 0
    .string_search_loop:          # start a loop to search for the text we are searching for
    cmpb $0, (%ecx, %edi)         # check if we got the string we are searching for
    je .back_to_line_begin_loop   # jump to the done searching if we are done searching for the string
    movb (%eax, %esi), %dl        # get the char from %eax
    cmpb $0, %dl                  # check if we are at end of file
    je .line_not_found            # jump out of loop if we are
    cmpb %dl, (%ecx, %edi)        # check if the char and the search char are the same
    inc %edi                      # increment index of array set
    inc %esi                      # increment index of array get
    je .string_search_loop        # jump to begin begin of loop if they are the same
    movl $0, %edi                 # reset the array set index if it is not
    .fast_foward_next_line:       # start loop to go to next line
    cmpb $10, (%eax, %esi)        # check if we hit next line
    inc %esi                      # increment %esi here so we dont hit \n next time we start scanning again
    je .string_search_loop        # jump back to line search if we hit new line
    jmp .fast_foward_next_line    # back to the loop start if we did not hit next line

    .back_to_line_begin_loop:     # this loop takes us back to the beginning of the line so the line can be extracted
    cmpb $10, (%eax, %esi)        # check if we hit \n
    je .got_line_begin            # if we did then we go the the get line loop
    dec %esi                      # if not decrement the index till we do
    jmp .back_to_line_begin_loop  # back to loop start if we have not hit \n

    .got_line_begin:              # from here setup the params for the line extract
    inc %esi                      # increment %esi so we are no longer on the \n
    movl $0, %edi                 # set the %edi index back to 0 because we no longer need to scan %ecx not now %ebx
    .getline_loop_start:          # start line setter loop
    movb (%eax, %esi), %dl        # extract char from %eax
    cmpb $10, %dl                 # compare if we are at the end of line
    je .hit_eol                   # go to the hit end of line if we did
    cmpb $0, %dl                  # check if we are at end of file
    je .hit_eol                   # same end of line procecure happens here
    movb %dl, (%ebx, %edi)        # move the eax char into the dest %ebx
    inc %edi                      # increment the setter index
    inc %esi                      # increment the getter index
    jmp .getline_loop_start       # jump back to begin of loop to redo the incructions
    .hit_eol:                     # return if we hit the end of line
    movb $0, (%ebx, %edi)         # end off %ebx with \0 so its a all out full line
    ret                           # return
    .line_not_found:              # if we encountered an error
    movl $0, %ebx                 # return an error inside %ebx
    ret                           # return

  # sear

  # search for certain word
  String_Search:
    ret

  # search for a char in string
  String_Search_Chr:
    ret
