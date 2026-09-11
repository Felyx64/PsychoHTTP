.section .bss
  Database_Write_Data:
    .space 326

  Database_Read_Result_Data:
    .space 326

  GetIndex_Map:
    .space 44  # 44 = 4 * 10 + 4

.section .data
  title_of_post_item:   #? TMP
    .asciz "post_1"

  postjson_title_text:
    .asciz "\"title\": "

  postjson_desc_text:
    .asciz "\"desc\": "

.section .text
  QueryUPLOAD_PostToDB:
    pushl %ebx                    # temp backup the length
    pushl %eax                    # temp backup the string pointer
    leal db_connection_id, %ebx   # link the fp to %ebx
    movl (%ebx), %ebx             # get the data from the pointer and make it param 1 for the next syscall
    movl $19, %eax                # move syscall id 19 into $eax
    movl $0, %ecx                 # make the syscall param 2 $0
    movl $2, %edx                 # make the syscall param 3 $0
    int $0x80                     # trigger syscall lseek (move fp to end of file)
    cmpl $0, %eax                 # check if we got error
    jl .bad_post_query            # jump to error if we did get an error
    movl $4, %eax                 # move syscall id 4 into $eax
    popl %ecx                     # get back the char* and move into param 2
    popl %edx                     # get back the length and move into param 3
    int $0x80                     # trigger syscall sys_write
    cmpl $0, %eax                 # check if we got error
    jl .bad_post_query            # jump to error if we did get an error
    movl $148, %eax               # move syscall id 148 into $eax
    int $0x80                     # trigger syscall sys_fdatasync to quickly save the written data
    cmpl $0, %eax                 # check if we got error
    jl .bad_post_query            # jump to error if we did get an error
    movl $0, %eax                 # move non code into $eax
    ret                           # return
    .bad_post_query:              # label to go to if we got a error code
    movl $1, %eax                 # move error code into $eax
    ret                           # return

  # PARAM (%EAX) LENGTH OF DATA WE'RE SEARCHING
  # PARAM (%EBX) CHAR* THAT POINTS TO THE END OF THE DB
  # PARAM (%ECX) THE PAGE OF THE DB WE'RE GETTING
  # DESCRIPTION: MAPS OUT A PART OF THE DATABASE
  # OVERWRTES: EDX, EDI
  # RETURNS (%EAX) RESULT FROM THE DB MAPPING (
  #   0 = FULL PAGE GAINED
  #   1 = PAGE DOES NOT EXIST
  #   3 = LAST PAGE FOUND
  # )
  # RETURNS (%EBX) STRING WE JUST SEARCH EVERYTHING ON
  Create_GetDBIndexMap:
    cmpl $0, %eax                     # check if database at least has smth in it
    je .page_not_found_return_label   # jump to return with error if there is not

    pushl %eax                        # temp push the database data length to stack
    pushl %ebx                        # temp push the database data pointer to the stack
    # get the correct database page
    # %ecx * 10 - 10
    movl %ecx, %eax                   # move desired page into $eax
    movl $10, %ebx                    # move 10 int $ebx
    xorl %edx, %edx                   # clear out %edx to prevent errors
    mul %ebx                          # do calculation $eax * $ebx
    subl $9, %eax                     # remove 10 from $eax so we can get the full page
    movl %eax, %ecx                   # move the page back into its original register
    xorl %edi, %edi                   # clear out the $edi as the register will keep track of how many pages we already got
    popl %eax                         # get back the database pointer
    popl %ebx                         # get back the database lenght

    cmpl %edi, %ecx                   # check if we are at the correct page
    je .got_correct_db_page           # jump if we are at the correct page
    .run_do_database_page:            # start searching for correct page on db
    cmpl %edi, %ecx                   # check if we are at the correct page (again)
    je .got_higher_db_page            # jump if we are at the correct page (again + different label)
    movb (%eax), %dl                  # if not get a char from $eax so we can check it
    cmpb $10, %dl                     # check if its a new line
    jne .no_page_increment            # if not: do not increment the index tracker
    inc %edi                          # if yes: increment the page tracker
    .no_page_increment:               # jump spot if we are not doing inc $edi
    dec %eax                          # decrement the pointer on $eax
    dec %ebx                          # decrement the counter on $ebx
    cmpl $0, %ebx                     # check if we reached end of db
    je .page_not_found_return_label   # if yes: jump to return with code 1
    jmp .run_do_database_page         # if not: jump and keep counting it all

    .got_higher_db_page:              # if we are at a upper page of the db we go to this label
    inc %ebx                          # increment both %eax, %ebx so the next subl wont break it
    inc %eax                          # increment both %eax, %ebx so the next subl wont break it
    .got_correct_db_page:             # if we are at first page. We go here
    cmpl $0, %ebx                     # Check if we are not at end of db
    jle .page_not_found_return_label  # jump if we are
    subl $2, %ebx                     # subl both so the parsing can start
    subl $2, %eax                     # subl both so the parsing can start

    # GET ALL INDEXES OF THE PAGE
    leal GetIndex_Map, %edi           # create db page map here
    xorl %ecx, %ecx                   # clear out %ecx as we track the limit of the db page map
    .map_page_indexes:                # start of get db index loop
    movb (%eax), %dl                  # move char into %dl
    cmpb $10, %dl                     # check if new db index
    jne .did_not_find_entry           # jump over if we did not
    movl %eax, (%edi)                 # move db index adress into the map
    addl $4, %edi                     # increment the map
    inc %ecx                          # increment the db-map limiter
    .did_not_find_entry:              # label if we are not at new index
    dec %eax                          # decrement the db pointer
    dec %ebx                          # decrement the db limiter
    cmpl $0, %ebx                     # check if we are at end of db
    je .incomplete_page_return        # Jump if we are bc we found a incomplete db adress
    cmpl $9, %ecx                     # check if we are at the db-map limit
    je .got_a_full_page               # jump to full page gained if we are
    jmp .map_page_indexes             # go back to start of loop if both checks are false
    .got_a_full_page:                 # label if we got a full page
    leal GetIndex_Map, %ebx           # re-link the db map to return-2
    movl $0, %eax                     # move the status into return-1
    ret                               # return
    .page_not_found_return_label:     # if somethign went wrong: we go here
    movl $1, %eax                     # return the status to return-1
    ret                               # return
    .incomplete_page_return:          # go here if we gained an incomple map
    movl %eax, (%edi)                 # move the last index-ptr into the map
    addl $4, %edi                     # increment the map by 4 again
    movl $0, (%edi)                   # move null into the map to signify the end of the map
    leal GetIndex_Map, %ebx           # move start of map into %ebx aka return-2
    movl $2, %eax                     # move the status into return-1
    ret                               # return

  # PARAM (%EAX) WHICH PAGE OF THE DB WE'RE READING
  QueryMultipleItems:
    pushl %eax  # temp push back the db page number
    movl $1, %eax
    call Read_File_Standard
    call Strlen
    pushl %eax
    movl %ebx, %eax
    call RunToEnd
    movl %eax, %ebx
    popl %eax
    popl %ecx
    call Create_GetDBIndexMap
    ret
    # ^ Create a map on this

    popl %ecx
    # add run to page logic
    .map_desired_db_indexes:
    movb (%eax), %bl
    cmpb $0x1E, %bl
    je .not_valid_index
    cmpb $0, %bl
    je .got_all_indexes
    cmpl $0, %ecx
    je .got_all_indexes
    # not and end of file (run to next record)
    .not_valid_index:
    call RunToNewLineChar
    jmp .map_desired_db_indexes
    .got_all_indexes:
    # scan for are valid indexes
    # write to SCOM_Database_Select_Result_List

    # parse all valid indexes
    # Place them in an SCOM in a list structure
    ret

  #! THIS PROCEDURE GOT TOO BLOATED AND COMPLEX. TO BE REPLACED
  # (%EAX) WHICH PAGE OF THE DB NEEDS TO BE GOTTEN
  # (%EBX) POINTER OF THE JSON WE'RE PLOTTING THIS DATA ONTO
  QeurySELECT_MultiplePostsFromDB_And_PlotJSON:
    popl %eax
    movl %ebx, %eax
    call Plot_Basic_Json_Start
    popl %edi
    pushl %eax
    leal db_connection_id, %ebx   # link the fp to %ebx
    movl (%ebx), %ebx             # get the data from the pointer and make it param 1 for the next syscall
    movl $19, %eax                # move syscall id 19 into $eax
    movl $0, %ecx                 # make the syscall param 2 $0
    movl $0, %edx                 # make the syscall param 3 $0 (SEEK_SET)
    int $0x80                     # trigger syscall lseek (move fp to end of file)
    movl %edi, %eax
    xorl %edx, %edx
    movl $10, %ebx
    mul %ebx
    movl %eax, %edi
    movl $1, %eax
    call Read_File_Standard
    dec %edi
    xorl %esi, %esi
    popl %ecx
    .seek_page_end:
    movb (%eax), %bl
    cmpb $0, %bl
    je .found_end_of_page
    cmpl $0, %edi
    je .found_end_of_page
    cmpb $10, %bl
    je .got_end_of_line
    jmp *extraction_procedure_table(,%esi,4)

    extraction_procedure_table:
      .long db_index_start_analysis # done 2 times bc we have 2 seperators
      .long add_json_entry_start
      .long title_extract
      .long db_index_middle_analysis
      .long desc_extraction

    db_index_start_analysis:
      cmpb $0x1E, %bl
      je .enact_run_line_runner
      inc %eax
      cmpb $'|', %bl
      jne .seek_page_end
      inc %esi
      jmp .seek_page_end
      .enact_run_line_runner:
      movb (%eax), %bl
      cmpb $10, %bl
      je .seek_page_end
      inc %eax
      jmp .enact_run_line_runner
    add_json_entry_start:
      # check for overwritten items on: eax, ecx, edi
      pushl %eax
      pushl %edi
      pushl %esi
      pushl %ecx
      #leal PostTitle_Memory, %esi
      leal title_of_post_item, %edi   #? TMP
      call String_Plot
      #leal PostTitle_Memory, %ebx
      popl %eax
      call Plot_Json_Object_Start
      movl %eax, %ecx
      popl %esi
      inc %esi
      popl %edi
      popl %eax
      # assign string start
      jmp .seek_page_end
    title_extract:
      cmpb $'|', %bl
      jne .seek_page_end
      inc %esi
      .get_char_from_title:
      movb %bl, (%ecx)
      jmp .seek_page_end
    db_index_middle_analysis:

      jmp .seek_page_end
    desc_extraction:

      jmp .seek_page_end
    # do something with the char
    # check if we got a title or desc as we're tracking that as well
    .got_end_of_line:
    dec %edi
    inc %eax
    jmp .seek_page_end
    .found_end_of_page:
    # read 1024 chunks at a time
    # get 10 index lines

    popl %eax # get back the writing on json data

    movb $0, (%eax)
    leal SCOM_Response_Creation_Table, %eax
    ret

    # seek the page we're instead ^


    # returns last index in case we need to read more
    # \x1E is deleted value
    ret

  # EXAMPLE: B|Post Title|31|Welcome the this fun post. This post is a example \n
