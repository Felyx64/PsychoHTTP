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

    # plot ({\n)
    # PARAM (%EAX) THE JSON WE'RE PLOTTING THE START ON
    Plot_Basic_Json_Start:
      movb $'{', (%eax)
      inc %eax
      movb $'\n', (%eax)
      inc %eax
      ret

    # plot ()
    Plot_Basic_Json_End:
      ret

    # PARAM (%EAX) THE JSON WE'RE PLOTTING THE OBJECT START ONTO
    # PARAM (%EAX) THE OBJECT NAME IN FOROM OF CHAR*
    # plot ("*Inserted Json Start*": {\n)
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
      movb $':', (%eax)            # push to string ":"
      inc %eax                      # increment the char*
      movb $' ', (%eax)             # add ' ' so we are seperating the obj begin and title
      inc %eax                      # increment the char*
      movb $'{', (%eax)             # add '{' to the json string
      inc %eax                      # increment the char*
      movb $'\n', (%eax)            # push the \n to the json string
      inc %eax                      # increment the char*
      ret                           # return

    Plot_Json_Object_End:
      ret

    # RETURNS (%EAX) THE JSON WE'RE PLOTTING THE STRING MEMBER ONTO
    # RETURNS (%EBX) THE STRING TITLE
    # RETURNS (%ECX) THE STRING CONTENT
    Plot_Json_Object_String:
      ret

    Plot_Comma_On_Json:
      ret
