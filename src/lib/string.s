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
  # EAX, pointer to firt character of the word we are searching for
  # EBX, pointer to the first character of the string we are searching in
  # ECX, lenght of the word we are searching for
  # Overwrites: DL, ESI, EDI
  # Returns: (EAX) true of false if the word has been found 1 = true, 0 = false
  # Returns: (EBX) Poiter to the last character of the string we found in EAX in what was originally EAX
  String_Search_Word:
    movl %eax, %esi               # move %eax into temp %esi as we dont have SIL in 32-bit assembly
    movl $0, %edi                 # move 1 not 0 into %edi so we can see if we reached end of fhe string we are searching
    dec %ecx
    .string_search_loop:          # start of the finding of the first character of the string
    movb (%esi), %al              # move first character of the string we are searching for into %al
    movb (%ebx), %dl              # move the char inside text are are analyzing into %dl
    cmpb $0, %dl                  # check if we reached end of data
    je .string_not_found          # jump to string not found if we actually are at the end of %ebx
    cmpb %dl, %al                 # compare the 2 chars in %dl, %al
    je .check_string              # if 2 chars match we check if its the word we are searching for
    inc %ebx                      # if not we inc %ebx to keep looking for the wanted char
    jmp .string_search_loop       # jump back to the word search loop
    .check_string:                # here is where we check if its actually the string we are searching for
    cmpl %edi, %ecx
    je .found_str
    inc %edi                      # increment %edi since we're now checking the 2nd char
    inc %ebx                      # inc the pointer of the text wall we are checking
    inc %esi                      # inc the pointer of the text we are searching for
    movb (%esi), %al              # move the new char of %esi into %al
    movb (%ebx), %dl              # move the new char of %ebx into %dl
    cmpb $0, %dl                  # check if we are at the end of the text we are checking
    je .string_not_found          # back to the string search loop
    cmpb %al, %dl                 # compare the 2 new chars
    je .check_string              # if equal do the extra check at this procedure
    jne .character_is_not_equal   # if not equal do the extra check at this procedure
    .character_is_not_equal:      # if both characters are not equal
    subl %edi, %esi               # subtract and reset the %esi pointer
    dec %edi
    subl %edi, %ebx               # subtract and reset the %ebx pointer
    movl $0, %edi                 # move 1 back into %edi
    jmp .string_search_loop       # jump to string not found if we are
    .found_str:                   # logic if we found the string
    movl %ebx, %ebx               # move %esi to %ebx as its second return value
    movl $1, %eax                 # move 1 True into %esi
    ret                           # return
    .string_not_found:            # logic if we did not find the string
    movl $0, %eax                 # move 0 False into %esi
    ret                           # return

  #? REDO AND BUG FIX ODD NUMBERS LATER
  # PARAM (%EAX) the int that needs to be converted to string
  # PARAM (%EDI) pointer to the first character of the string we need to put the number into
  # DESCRIPTION: turn int to string
  # OVERWRITES: EBX, ESI
  # RETURNS (%EDI) first char of the converted int to string
  IntToString:
    movl $10, %ebx                # move the length into the powering area of %eax
    .int_str_convert_loop:        # start converting the int to string
    xorl %edx, %edx               # reset the insertion register
    div %ebx                      # do %eax / %ebx
    addb $0x30, %dl               # add 0x30 to the remainder so it converts fully its char aquivelant
    movb %dl, (%edi)              # push the what's now the converted char into the string
    inc %edi                      # increment the string pointer
    testl %eax, %eax              # now we will check the result we got
    jnz .int_str_convert_loop     # if the result was 0 we are at the end of the loop
    movb $0, (%edi)               # end the string with a null terminator
    movl %edi, %esi               # copy the %edi string pointer to %esi
    movl $0, %ecx                 # move 0 int the reverse length
    .search_str_start:            # start searching for the bigining of the str
    dec %esi                      # decrement %esi we have not found the starting 0
    inc %ecx                      # increment until we reach the reverse leng
    movb (%esi), %al              # move defereranced %esi to %al
    cmpb $0, %al                  # check if we have found it
    jne .search_str_start         # jump back if not
    inc %esi                      # increment %esi so its not pointing to null
    dec %edi                      # decrement %edi so we are not pointing to null there neither
    dec %ecx                      # decrement the reverse leng as we always overrun by 1
    xorl %edx, %edx               # cleanup %edx for the coming div
    movl %ecx, %eax               # move the reverse-leng to %eax tempoirly
    movl $2, %ebx                 # move 2 into $ebx so we can divede by 2
    div %ebx                      # execute: %eax / %ebx
    movl %eax, %ecx               # move the result back into %ecx as we now have to good reverse-leng
    xorl %edx, %edx               # clearout $edx again so as needed for the reverse loops
    testl $1, %ecx                # check if even or uneven number
    je .reverse_loop              # go here if even number
    jne .reverse_str_odd          # go here if odd number
    .reverse_loop:                # reverse the string if even number
    cmpl %ecx, %edx
    je .string_convert_done
    movb (%esi), %al
    movb (%edi), %bl
    movb %bl, (%esi)
    movb %al, (%edi)
    inc %esi
    dec %edi
    inc %edx
    jmp .reverse_loop             # jump back to start of loop
    .reverse_str_odd:             # reverse the string if odd number
    cmpl %ecx, %edx
    je .string_convert_done
    movb (%esi), %al
    movb (%edi), %bl
    movb %bl, (%esi)
    movb %al, (%edi)
    inc %esi
    dec %edi
    inc %edx
    jmp .reverse_str_odd
    .string_convert_done:         # if everything is done go here
    ret

  # PARAM (%EDI): Source Data Ptr (must be null terminated at the end)
  # PARAM (%ESI): Destination Data Ptr where to plot to
  # DESCRIPTION: Plot data to the Ptr without adding a null terminator to the end
  # PARAM (%EAX): Pointer to the next to last char of the destination data
  # PARAM (%EBX): How much data was plotted to the dest
  String_Plot:
    xorl %ebx, %ebx               # clearout %edx length register
    .plot_loop:                   # start of plot loop
    movb (%edi), %al              # move char from adress into %al
    cmpb $0, %al                  # check if it is end of string
    je .data_plotted              # jump if end of string
    movb %al, (%esi)              # if not move char into the dest
    inc %esi                      # increment the dest ptr
    inc %ebx                      # increment the length register
    inc %edi                      # increment the source pointer
    jmp .plot_loop                # jump back to start of loop
    .data_plotted:                # here we go if data has been plotted
    movl %esi, %eax               # move dest to main return address
    ret                           # return

  IntToStringHEX:
    ret
