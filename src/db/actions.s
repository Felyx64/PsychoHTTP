.section .bss
  Database_Write_Data:
    .space 326

  Database_Read_Result_Data:
    .space 326

  GetIndex_Map:
    .long 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

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

  # PARAM (%EAX) WHICH PAGE OF THE DB WE'RE READING
  QueryMultipleItems:
    pushl %eax
    movl $1, %eax
    call Read_File_Standard
    call RunToEnd

    popl %ecx
    # add run to page logic
    .map_desired_db_indexes:
    movb (%eax), %bl
    # GetIndex_Map
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

  # THIS PROCEDURE GOT TOO BLOATED AND COMPLEX. TO BE REPLACED
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

    response_table:
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
      leal PostTitle_Memory, %esi
      leal title_of_post_item, %edi   #? TMP
      call String_Plot
      leal PostTitle_Memory, %ebx
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
    .check_str:
    ret

    # seek the page we're instead ^


    # returns last index in case we need to read more
    # \x1E is deleted value
    ret

  # EXAMPLE: B|Post Title|31|Welcome the this fun post. This post is a example \n
