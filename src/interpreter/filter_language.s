.section .data
  Filter_Ptr:
    .int 0

.section .text
  # initializez the server filter
  # OVERWRITES: EAX
  Initialize_Filter_Language:
    leal GSCOM_Server_Filter, %eax    # create a pointer to the filter file
    .in_cor_init_check:
    movl %eax, Filter_Ptr             # move the filter file pointer to the language pointer
    movl $Filter_Ptr, %ebx  # ebx is not the same value as %eax
    .in_cor_init_check_2:
    ret                               # go back as the filter has been initialized

  # returns first char of next item on the filter
  # Returns: (EAX) Pointer to first char of what item we are filtering
  Get_Filtered_String:
    movl $Filter_Ptr, %eax            # move current pointer to %eax
    ret                               # go back

  #? UNWANTED INCREMENTS
  # go to next item on the filter
  # OVERWRITES: EAX, EBX
  Next_Filtered_String:
    movl $Filter_Ptr, %eax            # move pointer into %eax
    .search_next_item:                # start of loop which moves to next item
    movl (%eax), %ebx                 # move what's in the pointer to %ebx

    # WE LOOP INFENATELY HERE
    cmpl $0, %ebx                     # check if we hit end of file
    je .hit_eof                       # go to the hit eof if it is truly the \0
    cmpl $10, %ebx                    # check if its an \n
    je .hit_next_item                 # go to the hit next item if it is the next item
    inc %eax                          # increment the pointer if its neither one of them
    jmp .search_next_item             # go back to begin of loop if we have not hit neither exit conditions
    .hit_next_item:                   # this is if we hit the next item
    inc %eax                          # increment the pointer the last time so we are not looking at the \0
    cmpl $0, (%eax)                   # check if we hit end of file
    je .hit_eof                       # go to the hit eof if it is truly the \0
    movl %eax, Filter_Ptr             # move new pointer to the filter ptr right after
    ret                               # go back as we are now looking at the next item
    .hit_eof:                         # if we hit end of filter file
    leal GSCOM_Server_Filter, %eax    # Move start of filterfile into %eax again
    movl %eax, Filter_Ptr             # move start of filter back into the filter_ptr re-initializing the filter again
    ret                               # go back

  # checks if the filter has restarted and returns bool based on that
  # OVERWRITES: EBX
  # Returns: (EAX) bool if we have hit the end of file 1 = we started again. 0 = we have not hit the end
  Is_End_Of_FilterFile:
    leal GSCOM_Server_Filter, %eax    # create link to begin of filter file
    movl $Filter_Ptr, %ebx            # get the current filter pointer
    .check_here_again:
    movl $1, %eax
    movl $9, %ebx
    int $0x80
    cmpl %eax, %ebx                   # compare the 2 pointers
    je .has_restarted                 # jump if we are the begin of file again meaning the filter has restarted
    jne .not_restarted                # jump to has not restarted procedure
    .has_restarted:                   # start of has restarted func
    movl $1, %eax                     # move 1 into %eax meaning it has restarted
    ret                               # go back
    .not_restarted:                   # start of has not restared func
    movl $0, %eax                     # move 0 into %eax meaning it has not yet restarted
    ret                               # go back
