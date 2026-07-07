.section .text
  # checks if the request contains any filtered items
  # Returns: (EAX) 0 = request is not allowed to pass, 1 = request is allowed to pass
  Filter_Request:
    .start_filter_loop:                   # starts the filter loop
    call Get_Filtered_String              # get string from the filter file
    pushl %eax                            # copy the string we got to stack tempoirly
    movl $1, %ecx                         # move 1 into %ecx as this is the size of the string so far
    .get_item_len_loop:                   # start the get length of item we are searching for loop
    inc %eax                              # increment the pointer to our current item so we look further to the end of word
    inc %ecx                              # increment %ecx i.e the word length that we know of
    #cmpl $0, %eax                         # check if we found end of file
    #jne .get_item_len_loop                # if we did not find eof than we go back
    # DILLEMA WE NEED TO CHECK BOTH
    cmpl $10, %eax                        # check if we found the \n
    jne .get_item_len_loop                # go back if its not the \n
    dec %ecx                              # decrement the lenght as we overshoot by 1 with this loop
    popl %eax                             # move the original pointer back into %eax from memory
    leal SCOM_User_Server_Request, %ebx   # create pointer to request in %ebx
    call String_Search_Word               # search if filtered word is in the request
    cmpl $1, %eax                         # check if 1 which means we found a filtered word in the request
    je .is_not_allowed                    # jump to notify the user that request is not allowed
    call Next_Filtered_String             # move the filter to the next string
    call Is_End_Of_FilterFile             # ask the filter if we have hit the end
    cmpl $0, %eax                         # check we answer of the filter
    je .start_filter_loop                 # back to start of loop if we have not hit the end
    movl $0, %eax                         # move 0 aka request allowed into %eax if loop stopped
    ret                                   # go back
    .is_not_allowed:                      # procedure if request is not allowed
    movl $1, %eax                         # move 1 aka request denied into %eax if we found a filtered string
    ret                                   # go back
