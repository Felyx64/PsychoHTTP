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

  # RETURNS (%EAX) THE JSON WE'RE PLOTTING THE STRING MEMBER ONTO
  # RETURNS (%EBX) THE STRING TITLE
  # RETURNS (%ECX) THE STRING CONTENT
  Plot_Json_Object_String:
    movb $0x22, (%eax) # plot 0x22 = "
    inc %eax
    pushl %ecx
    .plot_string_title_loop:        # assign the string title
    movb (%ebx), %cl
    cmpb $0, %cl
    je .setup_member_data_get_loop
    movb %cl, (%eax)
    inc %eax
    inc %ebx
    jmp .plot_jsonitem_title_loop
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
    pushl %ebx
    call Plot_Basic_Json_Object_Start
    xorl %ecx, %ecx
    movb $'0', %cl
    .make_database_result_json_loop:
    pushl %ebx
    pushl %eax
    leal db_Item_Index_Label_Name, %edi
    leal Database_Content_Maker_Area, %esi
    call String_Plot
    movb %cl, (%eax)
    inc %eax
    movb $0, (%eax)
    leal Database_Content_Maker_Area, %edi
    popl %esi
    popl %edi # temp take out of stack
    pushl %ecx
    pushl %edi # push back into stack
    leal Database_Content_Maker_Area, %edi
    call Extract_Line_From_Blob
    movl %ebx, %esi
    leal Database_Content_Maker_Area, %ecx
    leal db_index_title_characters, %ebx
    popl %eax
    pushl %esi
    call Plot_Json_Object_Start
    movl %eax, %ecx
    popl %esi
    leal Database_Content_Maker_Area, %edi
    call Extract_Line_From_Blob
    call Plot_Basic_Json_End
    movl %ecx, %eax
    leal Database_Content_Maker_Area, %ecx
    leal db_index_title_characters, %ebx
    call Plot_Json_Object_Start
    call Plot_Basic_End_Json
    call Plot_Comma_Json_Object_End
    popl %ecx
    inc %ecx
    movb (%eax), %bl
    cmpb $0, %bl
    je .assigned_json_list
    jmp .make_database_result_json_loop
    dec %eax
    movb $' ', (%eax)
    inc %eax
    call Plot_Basic_Json_Object_End
    # then we finish off the json
    ret

    #? OLD IMPLEMENTATION
    pushl %eax
    leal db_Item_Index_Label_Name, %edi
    leal Database_Index_Label_Maker_Area, %esi
    call String_Plot
    # ADD ID OT THE STRING
    call Plot_Json_Object_Start
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
