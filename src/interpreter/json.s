.section .text
  # PARAM (%EAX) THE STRING WE'RE CHECKING THE END A STRING STRING ITEM
  # OVERWRITES: %EBX, %ESI
  # DESCRIPTION: CHECKS IF WE ARE AT A JSON ITEMS END
  # RETURNS (%EDI) IF IS 1: WE HAVE HIT THE JSON STRING END
  Check_For_JsonItem_End:
    movw (%eax), %bx
    cmpw $8748, %bx # 8748 = (",)
    cmovel %esi, %edi
    ret

  # PARAM (%EAX) THE LAST JSON STRING WE'RE CHECKING FOR
  # OVERWRITES: %EBX, %ESI
  # DESCRIPTION: CHECKS IF WE ARE AT THE END OF LAST JSON STRING
  # RETURNS (%EDI) IF IS 1: WE HAVE HIT JSON LAST STRING END
  Check_For_Json_End:
    movb (%eax), %bl
    cmpb $34, %bl # 34 = (")
    cmovel %esi, %edi
    ret

  # PARAM (%EAX) POINTER CHAR* TO THE JSON WE HAVE RECIEVED
  # OVERWRITES: ALL REGISTERS
  # DESCRIPTION: EXTRACTS THE ITEMS FRM THE POST_JSON
  # RETURNS (%EAX): CHAR* TO THE TITLE WE GOT
  # RETURNS (%EBX): CHAR* TO THE DESCRIPTION WE GOT
  Extract_From_Post_Json:
    addl $11, %eax                                    # add 1 to the %eax ptr so we reach the first variable
    leal SCOM_extracted_json_title_data, %ecx         # link the title to the %ecx
    xorl %edx, %edx                                   # clear out edx
    xorl %edi, %edi                                   # empty out the edi
    movl $1, %esi                                     # move 1 into %esi
    .extract_json_title:                              # starter label for the title-copy process
    call Check_For_JsonItem_End                       # check if we reached end of title
    cmpl $1, %edi                                     # check if it returned the signal that we hit the end
    je .got_json_title                                # jump if we did
    movb (%eax), %bl                                  # copy to %bl the a char if not
    movb %bl, (%ecx)                                  # then paste it to dest
    inc %eax                                          # increment ptr %eax
    inc %ecx                                          # increment ptr %ecx
    inc %edx                                          # increment deilimiter %edx
    cmpl $64, %edx                                    # check if delimiter is at max value
    je .got_json_title                                # jump if we did
    jmp .extract_json_title                           # jump back to begin of loop if we did not
    .got_json_title:                                  # label for when copying title is done
    dec %ecx                                          # decrement the dest ptr
    movb $0, (%ecx)                                   # add null terminator to dest so string is ended
    leal SCOM_extracted_json_description_data, %ecx   # assign description dest memory-ptr to %ecx
    addl $14, %eax                                    # jump to start of description json starter
    xorl %edi, %edi                                   # reset the %edi bool
    xorl %edx, %edx                                   # reset the %edx delimiter
    .extract_json_desc:                               # start of extract description loop
    call Check_For_Json_End                           # check if we are at end of desc string
    cmpl $1, %edi                                     # check for a signal
    je .got_json_desc                                 # jump to end if we got a singal
    movb (%eax), %bl                                  # if not move the char out of the json
    movb %bl, (%ecx)                                  # and plot it into the dest
    inc %eax                                          # increment the json pointer
    inc %ecx                                          # increment the dest pointer
    inc %edx                                          # increment the dilimiter
    cmpl $256, %edx                                   # check if we are at dilimiter end
    je .got_json_desc                                 # jump to end we are hit the end
    jmp .extract_json_desc                            # jump to start of assign loop if not
    .got_json_desc:                                   # label means end of description assign loop
    movb $0, (%ecx)                                   # null terminate the dest end
    leal SCOM_extracted_json_title_data, %eax         # link the title to the eax
    leal SCOM_extracted_json_description_data, %ebx   # link the desc to the ebx
    ret                                               # return

  # PARAM (%EAX) JSON WE'RE TRYING TO PARSE
  # RETURNS (%EAX) THE NUMBER WE PARSED OUT OF THE JSON
  Extract_From_Get_Post_Json:
    xorl %ecx, %ecx
    addl $23, %eax
    movb (%eax), %bl
    inc %eax
    movb (%eax), %cl
    subb $0x30, %bl
    movsx %bl, %eax
    cmpb $'}', %cl
    jne .only_single_chared
    ret
    .only_single_chared:
    xorl %edx, %edx
    movl $2, %ebx
    mul %eax
    subb $0x30, %cl
    addl %ecx, %eax
    ret

  # WRITE FUNCTIONS FROM HERE

  # plot ({\n)
  # PARAM (%EAX) THE JSON WE'RE PLOTTING THE START ON
  Plot_Basic_Json_Object_Start:
    movb $'{', (%eax)
    inc %eax
    movb $'\n', (%eax)
    inc %eax
    ret

  # plot (}\n)
  # PARAM (%EAX) THE JSON WE'RE PLOTTING THE OBJ END ONTO
  Plot_Basic_Json_Object_End:
    movb $'}', (%eax)
    inc %eax
    movb $'\n', (%eax)
    inc %eax
    ret

  # plot (},\n)
  # PARAM (%EAX) THE JSON WE'RE PLOTTING THE OBJ COMMA END ONTO
  Plot_Comma_Json_Object_End:
    movb $'}', (%eax)
    inc %eax
    movb $',', (%eax)
    inc %eax
    movb $'\n', (%eax)
    inc %eax
    ret

  # plot (,\n)
  # PARAM (%EAX) THE JSON WE'RE PLOTTING THE COMMA END ONTO
  Plot_Comma_End_Json:
    movb $',', (%eax)
    inc %eax
    movb $10, (%eax)
    inc %eax
    ret

  # plot (\n)
  # PARAM (%EAX) THE JSON WE'RE PLOTTING THE GENERIC END ONTO
  Plot_Basic_End_Json:
    movb $10, (%eax)
    inc %eax
    ret

  # PARAM (%EAX) THE JSON WE'RE PLOTTING THE OBJECT START ONTO
  # PARAM (%EBX) THE OBJECT NAME IN FOROM OF CHAR*
  # plot ("*Inserted Json Start*": {\n)
  # OVERWRITES: %ECX
  # RETURNS (%EAX) THE JSON WITH THE OBJECT START PUSHED ONTO IT
  Plot_Json_Object_Start:
    movb $0x22, (%eax)            # push to string (0x22 = ")
    inc %eax                      # increment the char*
    .plot_jsonitem_title_loop:    # start plot string title loop
    movb (%ebx), %cl              # get char from source
    cmpb $0, %cl                  # check if we are at end of source
    je .plotted_title_itelf       # jump if we are
    movb %cl, (%eax)              # if not: move char into the dest json
    inc %eax                      # if not: increment both pointers
    inc %ebx                      # if not: increment both pointers
    jmp .plot_jsonitem_title_loop # if not: and then jump back
    .plotted_title_itelf:         # label which we jump to if we got the title
    movb $0x22, (%eax)            # push to string (0x22 = ")
    inc %eax                      # increment the char*
    movb $':', (%eax)             # push to string ":"
    inc %eax                      # increment the char*
    movb $' ', (%eax)             # add ' ' so we are seperating the obj begin and title
    inc %eax                      # increment the char*
    movb $'{', (%eax)             # add '{' to the json string
    inc %eax                      # increment the char*
    movb $'\n', (%eax)            # push the \n to the json string
    inc %eax                      # increment the char*
    ret                           # return

  # PARAM (%EAX) THE JSON WE'RE PLOTTING THE STRING MEMBER ONTO
  # PARAM (%EBX) THE STRING TITLE
  # PARAM (%ECX) THE STRING CONTENT
  # RETURNS (%EAX) THE JSON AFTER WE PLOTTED THE STRING ONTO IT
  Plot_Json_Object_String:
    movb $0x22, (%eax)              # plot 0x22 = "
    inc %eax
    pushl %ecx
    .plot_string_title_loop:        # assign the string title
    movb (%ebx), %cl
    cmpb $0, %cl
    je .setup_member_data_get_loop
    movb %cl, (%eax)
    inc %eax
    inc %ebx
    jmp .plot_string_title_loop
    .setup_member_data_get_loop:    # assign title-content inbetween
    popl %ebx
    movb $0x22, (%eax)
    inc %eax
    movb $':', (%eax)
    inc %eax
    movb $' ', (%eax)
    inc %eax
    movb $0x22, (%eax)
    inc %eax
    .plot_string_memberdata_loop:   # assign the string content
    movb (%ebx), %cl
    cmpb $0, %cl
    je .done_taking_data
    movb %cl, (%eax)
    inc %eax
    inc %ebx
    jmp .plot_string_memberdata_loop
    .done_taking_data:                # we're done here
    movb $0x22, (%eax)
    inc %eax
    ret

  # PARAM (%EAX) THE DATABASE RESULTS WE ARE ASSIGNING TO THE JSON
  # PARAM (%EBX) THE RESPONSE OBJECT WE'RE ASSIGNING THE JSON ONTO
  Convert_DB_Results_To_Json:
    pushl %ebx                              # temp push res object to stack
    xchg %eax, %ebx                         # temp swap res-obj and db-res
    call Plot_Basic_Json_Object_Start       # plot the json object start to res object
    xchg %eax, %ebx                         # swap back res-obj and db-res
    xorl %ecx, %ecx                         # clear out %ecx from extraction safety
    movb $'0', %cl                          # move char '0' into %cl counting db entries
    .make_database_result_json_loop:        # start of db-res to json loop
    pushl %ebx                              # temp backup json-write ptr
    pushl %eax                              # temp backup the db results
    leal db_Item_Index_Label_Name, %edi     # link the db index result to %edi
    leal Database_Content_Maker_Area, %esi  # link the area we're writing the db index onto to %esi
    call String_Plot                        # plot db index string to the maker area
    movb %cl, (%eax)                        # plot the index number we're on right now and write
    inc %eax                                # Increment the write area ptr
    movb $0, (%eax)                         # null terminate the write area
    popl %esi                               # take out the db results out of the stack
    popl %eax                               # temp take result content writer out of stack
    leal Database_Content_Maker_Area, %ebx  # re-link the index maker area to the %edi
    pushl %ecx                              # push the index counter to the stack now
    call Plot_Json_Object_Start             # Plot start of object to json
    pushl %eax                              # push the response json area into stack
    leal Database_Content_Maker_Area, %edi  # re-link database maker area again so we can start plotting again
    call Extract_Line_From_Blob             # Extract line from the db result and plot it onto the maker area
    movl %ebx, %esi                         # move the result maker area to %ebx
    leal Database_Content_Maker_Area, %ecx  # re-link the repopulated json area
    leal db_index_title_characters, %ebx    # link the title to %ebx
    popl %eax                               # get the json writer out of the stack
    pushl %esi                              # push the db-results back to the stack
    call Plot_Json_Object_String            # Plot the string onto the result
    call Plot_Comma_End_Json                # end off the json index with a comma and line end
    movl %eax, %ecx                         # move the resulted json ptr into %ecx
    popl %esi                               # get the db-results back out of the stack
    leal Database_Content_Maker_Area, %edi  # re-link database maker area again so we can start plotting again
    call Extract_Line_From_Blob             # Extract line from the db result and plot it onto the maker area
    movl %ecx, %eax                         # move the json ptr back into $eax
    leal Database_Content_Maker_Area, %ecx  # re-link the index content to $ecx
    leal db_index_content_characters, %ebx  # link the title to $ebx
    call Plot_Json_Object_String            # Plot the string member to the json
    call Plot_Basic_End_Json                # plot just a basic end this time as we are at the index end
    call Plot_Comma_Json_Object_End         # Plot a comma as we are at end of index but there could be more indexes
    popl %ecx                               # take back the index counter
    # PUSH OTHER VALS (JSON PTR = $eax & DB RESULT PTR = $esi)
    inc %cl                                 # increment the index counter
    xorl %ebx, %ebx   #? DEV LESSENING INTERFEATANCE

    cmpb $0, %bl                            # check if null which means we are at end of db results
    je .assigned_json_list                  # if we are: jump to the last conversion steps
    movl %eax, %ebx                         # if not: move $eax > $ebx (reset the ptr register locations)
    movl %esi, %eax                         # if not: move $esi > $eax (reset the ptr register locations)
    jmp .make_database_result_json_loop     # if not: continue looping
    .assigned_json_list:                    # label to jump to if we are at end of result
    subl $2, %eax                           # decrement the json ptr
    movb $' ', (%eax)                       # remove the comma from which the ptr should be looking at right now
    addl $2, %eax                           # re-increment the json ptr
    call Plot_Basic_Json_Object_End         # plot the last few chars so the json is whole made
    movb $0, (%eax)
    inc %eax

    # STANDARD PRINT OUT HERE
    leal TSCOM_Tempoirly_Object, %eax
    call nstandard_console_write
    .check_str:
    movl $1, %eax
    movl $9, %ebx
    int $0x80

    ret

.section .bss
  Database_Content_Maker_Area:
    .space 260

.section .data
  db_Item_Index_Label_Name:
    .asciz "PostID_"

  db_index_title_characters:
    .asciz "Title"

  db_index_content_characters:
    .asciz "Content"
  # db item titles
