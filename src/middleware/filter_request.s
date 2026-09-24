.section .text
  # checks if the request contains any filtered items
  # Returns: (EAX) 0 = request is not allowed to pass, 1 = request is allowed to pass
  Filter_Request:
    leal GSCOM_Server_Filter, %eax # contains data i wrote to other objects when program runs 2nd time
    call Get_Filtered_String              # get string from the filter file
    leal SCOM_User_Server_Request, %ebx   # create pointer to request in %ebx
    .start_filter_loop:                   # starts the filter loop
    call String_Search_Word               # search if filtered word is in the request
    cmpl $1, %eax                         # check if 1 which means we found a filtered word in the request
    je .is_not_allowed                    # jump to notify the user that request is not allowed
    call Next_Filtered_String             # move the filter to the next string
    call Is_End_Of_FilterFile             # ask the filter if we have hit the end
    cmpl $0, %eax                         # check we answer of the filter
    je .start_filter_loop                 # back to start of loop if we have not hit the end
    xorl %eax, %eax                       # move 0 aka request allowed into %eax if loop stopped
    ret                                   # go back
    .is_not_allowed:                      # procedure if request is not allowed
    movl $1, %eax                         # move 1 aka request denied into %eax if we found a filtered string
    ret                                   # go back
