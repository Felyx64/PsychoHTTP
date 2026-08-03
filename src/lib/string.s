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
  # Overwrites: DL, ESI
  # Returns: (EAX) true of false if the word has been found 1 = true, 0 = false
  # Returns: (EBX) Poiter to the last character of the string we found in EAX in what was originally EAX
  String_Search_Word:
    movl %eax, %esi               # move %eax into temp %esi as we dont have SIL in 32-bit assembly
    movb (%esi), %al              # move first character of the string we are searching for into %al
    movl $1, %edi                 # move 1 not 0 into %edi so we can see if we reached end of fhe string we are searching
    .string_search_loop:          # start of the finding of the first character of the string
    movb (%ebx), %dl              # move the char inside text are are analyzing into %dl
    cmpb $0, %dl                  # check if we reached end of data
    je .string_not_found          # jump to string not found if we actually are at the end of %ebx
    cmpb %dl, %al                 # compare the 2 chars in %dl, %al
    je .check_string              # if 2 chars match we check if its the word we are searching for
    inc %ebx                      # if not we inc %ebx to keep looking for the wanted char
    jmp .string_search_loop       # jump back to the word search loop
    .check_string:                # here is where we check if its actually the string we are searching for
    inc %ebx                      # inc the pointer of the text wall we are checking
    inc %esi                      # inc the pointer of the text we are searching for
    movb (%esi), %al              # move the new char of %esi into %al
    movb (%ebx), %dl              # move the new char of %ebx into %dl
    cmpb %al, %dl                 # compare the 2 new chars
    je .character_is_equal        # if equal do the extra check at this procedure
    jne .character_is_not_equal   # if not equal do the extra check at this procedure
    .character_is_equal:          # extra logic for if equal clause
    inc %edi                      # increment %edi i.e how far we are in the check
    cmpl %edi, %ecx               # compare the limit and how far we are
    je .found_str                 # keep looking if we still are not there yet
    jne .check_string             # go to the return true if we are
    .character_is_not_equal:      # if both characters are not equal
    cmpb $0, %dl                  # check if we are at the end of the text we are checking
    jne .string_search_loop       # back to the string search loop
    subl %edi, %esi               # subtract and reset the %esi pointer
    movl $1, %edi                 # move 1 back into %edi
    je .string_not_found          # jump to string not found if we are
    .found_str:                   # logic if we found the string
    movl %esi, %ebx               # move %esi to %ebx as its second return value
    movl $1, %eax                 # move 1 True into %esi
    ret                           # return
    .string_not_found:            # logic if we did not find the string
    movl %esi, %ebx               # move %esi to %ebx as its second return value
    movl $0, %eax                 # move 0 False into %esi
    ret                           # return

  # PARAM (%EAX) the int that needs to be converted to string
  # PARAM (%EDI) pointer to the first character of the string we need to put the number into
  # DESCRIPTION: turn int to string
  # OVERWRITES: EBX, ECX, ESI
  # RETURNS (%EDI) first char of the converted int to string
  IntToString:
    movl $0, %ecx                 # move 0 into the counter
    .int_str_convert_loop:        # start converting the int to string
    xorl %edx, %edx               # reset the insertion register
    movl $10, %ebx                # move 10 into devision for the coming divison operation
    div %ebx                      # execute %eax = %eax / %ebx
    addb $0x30, %dl               # add 0x30 to the remainder so it converts fully its char aquivelant
    movb %dl, -1(%edi,%ecx)       # push the what's now the converted char into the string
    incl %ecx                     # increment the counter
    testl %eax, %eax              # now we will check the result we got
    jnz .int_str_convert_loop     # if the result was 0 we are at the end of the loop
    movb $0, (%edi,%ecx)          # move the null teminator into the string to end it off
    leal -1(%edi,%ecx), %esi      # get last number of string back into %esi as temp as we need to reverse it now
    leal (%edi), %edi             # create a link to the first number in the string to %edi
    .reverse_loop:                # start reversing the string as we now have the string but innverseded
    cmp %esi, %edi                # compare %esi to %edi to check if we have fully reversed the string
    jge .strint_convert_done      # jump to convertsion done if it is
    movb -1(%esi), %dl            # grab char 1
    movb -1(%edi), %al            # grab char 2
    movb %dl, -1(%edi)            # place char 1
    movb %al, (%esi)              # place char 2
    decl %esi                     # decmrement %esi
    incl %edi                     # increment %edi
    jmp .reverse_loop             # jump back to start of loop
    .strint_convert_done:         # if everything is done go here
    ret
