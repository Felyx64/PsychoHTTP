.section .text
  # PARAM (%EAX): CHAR* TO WHAT WE'RE GONNA FILTER
  # DESCRIPTION: FILTERS OUT ALL THE |'S OF THE CHAR* AND REPLACES THEM WITH i'S
  # OVERWRITES: EBX, ECX
  # RETURNS (%EAX) CHAR* WITH EVERYTHING FILTERED OUT
  FilterOutSeperators:
    movl %eax, %ecx                   # backup the string ptr in %ecx
    dec %eax                          # temp decrement the char*
    .filter_seperators_out_loop:      # start pf the filter loop
    inc %eax                          # increment the char* by one
    movb (%eax), %bl                  # extract char from char*
    cmpb $0, %bl                      # check if we hit end of string
    je .done_filteringdbchars         # jump to done filtering if we found the end
    cmpb $'|', %bl                    # check if we found a seperator if not
    je .replaceseperator              # jump to replacement logic if we did
    jmp .filter_seperators_out_loop   # jump back to start of loop if we did not
    .replaceseperator:                # replace the seperator accordingly in this chunk
    movb $'I', (%eax)                 # replace the seperatator in this line
    jmp .filter_seperators_out_loop   # go back after replacement
    .done_filteringdbchars:           # label to go to at end of filter
    movl %ecx, %eax                   # reset the ptr b4 going back
    ret                               # return

  # PARAM (%EAX): CHAR* TO WHAT WE'RE GONNA FILTER
  # DESCRIPTION: FILTERS OUT ALL THE \n'S OF THE CHAR* AND REPLACES THEM WITH \x1E'S
  # OVERWRITES: EBX, ECX
  # RETURNS (%EAX) CHAR* WITH EVERYTHING FILTERED OUT
  FilterOutNewlines:
    movl %eax, %ecx                   # backup the string ptr in %ecx
    dec %eax                          # temp decrement the char*
    .replace_char_loop:               # start pf the filter loop
    inc %eax                          # increment the char* by one
    movb (%eax), %bl                  # extract char from char*
    cmpb $0, %bl                      # check if we hit end of string
    je .endreplacementloopdb          # jump to done filtering if we found the end
    cmpb $'\n', %bl                   # check if we found a \n or not
    jne .replace_char_loop            # jump back if we did not
    movb $0x1E, (%eax)                # replace the \n in this line which is the 1E record seperator
    jmp .replace_char_loop            # go back after replacement
    .endreplacementloopdb:            # label to go to at end of filter
    movl %ecx, %eax                   # reset the ptr b4 going back
    ret                               # return

  Determine_Writer_Size:
    ret

  Parse_WriterType_Id:
    ret

  # PARAM (%EAX): CHAR* TO THE TITLE STRING
  # PARAM (%EBX): CHAR* TO THE DESC STRING
  # DESCRIPTION: CREATES A FORMATTED DATABASE INDEX READY TO BE INSERTED
  # OVERWRITES: ALL REGISTERS
  # RETURNS (%EAX): A FORMATTED DATABASE INDEX
  Create_Database_Index:
    pushl %ebx                        # backup the description string
    call Strlen                       # get lenght of the title string
    pushl %ebx                        # backupt the title string now
    leal Database_Write_Data, %edi    # link the database write data to %edi
    call CreateBase16Number           # get base16 version of strlen(title)
    movl %edi, %esi                   # move the plotter entry to %esi
    movb $'|', (%esi)                 # add a seperator to the string
    inc %esi                          # increment the string pointer
    popl %edi                         # get back the title and put it into the %edi
    call String_Plot                  # plot the title onto the entry
    movb $'|', (%eax)                 # add a seperator
    inc %eax                          # increment the string ptr
    movl %eax, %edi                   # move the string ptr into %edi
    popl %eax                         # get back the desc
    call Strlen                       # get lenght of the desc
    pushl %ebx                        # backup the desc ptr
    call CreateBase16Number           # convert desc length to base16 and plot it to the entry
    movb $'|', (%edi)                 # move seperator into the entry
    inc %edi                          # increment the string ptr
    movl %edi, %esi                   # move the string ptr into %esi
    popl %edi                         # get the desc back
    call String_Plot                  # plot the desc onto the entry
    movb $10, (%eax)                  # move new-line onto the string
    inc %eax                          # increment the string ptr
    movb $0, (%eax)                   # put end of file onto the string ptr
    leal Database_Write_Data, %eax    # reset the string ptr before returning
    ret                               # return

  Parse_Database_Index:
    ret
