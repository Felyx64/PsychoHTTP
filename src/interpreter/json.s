.section .data

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
