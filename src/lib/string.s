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

  # PARAM (%EAX) the int that needs to be converted to string
  # PARAM (%EDI) pointer to the first character of the string we need to put the number into
  # DESCRIPTION: turn int to string
  # OVERWRITES: EBX, ESI, ECX, EDX
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
  # OVERWRITES: EAX, EBX
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

  # PARAM (%EAX): CHAR* to any character
  # DISCRIPTION: Makes the pointer run forward till it detects a \0
  # OVERWRITES: EBX
  # RETURNS (%EAX): Pointer to the location where it found the \0
  RunToEnd:
    .run_till_null_loop:
    movb (%eax), %bl
    cmpb $0, %bl
    je .nullfinish_crossed
    inc %eax
    jmp .run_till_null_loop
    .nullfinish_crossed:
    ret

  # PARAM (%EAX): CHAR* to any character
  # DISCRIPTION: Makes the pointer run forward till it detects a \n
  # OVERWRITES: EBX
  # RETURNS (%EAX): Pointer to the location where it found the \n
  RunToNewLineChar:
    .run_till_nl_loop:
    movb (%eax), %bl
    cmpb $10, %bl
    je .nlfinish_crossed
    inc %eax
    jmp .run_till_nl_loop
    .nlfinish_crossed:
    ret


  # PARAM (%EAX) LINE OF TEXT WE NEED TO CONVERT
  # DESCRIPTION: TURNS THE PARAM STRING FOR A CHUNKED RES
  # OVERWRITES: EBX, ECX, EDX, EDI, ESI
  # RETURNS (%EAX) THE CONVERTED LINE
  # REUTNRS (%EBX) SIGNAL IF IT IS 1: WE HIT THE END, 0 = end not hit
  CreateResponseFracturePartition:
    xorl %ecx, %ecx
    pushl %eax
    .get_length:
    movb (%eax), %bl
    inc %eax
    inc %ecx
    cmpb $0, %bl
    jne .get_length
    dec %ecx
    movl %ecx, %eax
    leal ResponseFractureMemory, %edi
    call CreateBase16Number
    movl %edi, %esi
    leal Response_Line_Starter_And_Terminator, %edi
    call String_Plot
    movl %eax, %esi
    popl %edi
    call String_Plot
    leal Response_Line_Starter_And_Terminator, %edi
    call String_Plot
    movb $0, (%eax)
    leal ResponseFractureMemory, %eax
    ret

  # PARAM (%EAX) NUMBER THAT NEEDS TO BE CONVERTED TO BASE16
  # PARAM (%EDI) CHAR* WE'RE ASSIGNING THE BASE16 TO
  # MAX NUMBER IT CAN YEILD IS: FF/255
  # OVERWRITES: EBX, EDX, ECX
  # RETURNS (%EDI) CHAR* CONTAINING THE BASE16 NUMBER ON THE BIG ENDIAN SIDE
  CreateBase16Number:
    # iterate over modulo-16 to get our number
    movl $16, %ebx
    .convert_hex_loop:
    xorl %edx, %edx
    div %ebx

    leal Base16_Digits, %ecx
    addl %edx, %ecx
    movb (%ecx), %dl

    cmpl $0, %eax
    je .only_one_digitbase16

    leal Base16_Digits, %ecx
    addl %eax, %ecx
    movb (%ecx), %bl

    movb %bl, (%edi)
    inc %edi
    movb %dl, (%edi)
    inc %edi

    ret
    .only_one_digitbase16:

    movb %dl, (%edi)
    inc %edi

    ret

  # PARAM (%EAX) POINTER TO THE STRING WE'RE GETTING THE LENTH OF OFF
  # OVERWRTIES: ECX
  # RETURNS (%EAX) LENGTH OF THE STRING
  # RETURNS (%EBX) THE OLD POINTER PASSED IN
  Strlen:
    xorl %ebx, %ebx                     # clear %ebx as we're incrementing the getting the length from here
    movl %eax, %ecx                     # backup the %eax pointer to %ecx
    dec %eax                            # temp decrement %eax so we dont break the coming loop
    .not_end_strlen:                    # start of get string length loop
    inc %eax                            # increment %eax pointer
    inc %ebx                            # increment the string length counter
    movb (%eax), %dl                    # extract the current char we are looking at
    cmpb $0, %dl                        # check if we reached the end of the string
    jne .not_end_strlen                 # jump back if not
    dec %ebx                            # dec %ebx as we are not overrunning by 1
    movl %ebx, %eax                     # move %ebx into %eax i.e the 1st return
    movl %ecx, %ebx                     # move the beckup pointer back into %ebx i.e the 2nd return
    ret                                 # return

  # PARAM: (%EAX) CHAR* WHICH WE'RE RUNNING TO THE DESIRED LOCATION
  # DESCRIPTION: run pointer till we see \r\n\r\n
  # OVERWRITES: EAX, BL
  RunToEndOfReqHeader:
    .we_at_begin_again:
    movb (%eax), %bl
    cmpb $'\r', %bl
    je .found_1_desired
    inc %eax
    jmp .we_at_begin_again
    .found_1_desired:
    inc %eax
    movb (%eax), %bl
    cmpb $'\n', %bl
    je .found_2_desired
    jmp .we_at_begin_again
    .found_2_desired:
    inc %eax
    movb (%eax), %bl
    cmpb $'\r', %bl
    je .found_final_desired
    jmp .we_at_begin_again
    .found_final_desired:
    inc %eax
    movb (%eax), %bl
    cmpb $'\n', %bl
    jne .we_at_begin_again
    inc %eax
    ret

  # PARAM (%ESI) PTR TO THE STRING WE'RE TAKING FROM THE BLOB
  # PARAM (%EDI) DESTINATION OF WHERE WE ARE PUTTING THE EXTRACTED STRING
  # DESCRIPTION: EXTRACT DATA FROM %ESI AND MOVE IT INTO %EDI UNTIL WE FOUND A \n
  # RETURNS (%EAX) DEST STRING WHERE THE TEXT LINE WAS MOVE INTO
  # RETURNS (%EBX) POINTER TO THE DEST WE WHERE LOOKING AT
  Extract_Line_From_Blob:
    .take_line_from_db_result:        # start of extraction loop
    movb (%esi), %al                  # take 1 char from source
    cmpb $10, %al                     # check if we are at end of source
    je .got_json_item_index_response  # jump to end of function if we are
    movb %al, (%edi)                  # move char into dest if not
    inc %esi                          # increment source
    inc %edi                          # increment dest
    jmp .take_line_from_db_result     # jump back to start
    .got_json_item_index_response:    # label for end of function process
    movb $0, (%edi)                   # move null terminator to end of dest string
    inc %esi                          # increment the source so we are not looking at the /n anymore
    movl %edi, %eax                   # move dest into $eax
    movl %esi, %ebx                   # move source into $ebx
    ret                               # return

.section .bss
  TimeMakerMemory:
    .space 256

  ResponseFractureMemory:
    .space 256

.section .data
  Base16_Digits:
    .ascii "0123456789abcdef"
