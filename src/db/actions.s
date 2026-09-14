.section .bss
  Database_Write_Data:
    .space 326

  Database_Read_Result_Data:
    .space 3140

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
  #   2 = LAST PAGE FOUND
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
  # GET MULTIPLE ITEMS FROM THE DB AND PLOT THEM TO A TEXT RESULT
  # OVERWRITES: ALL REGISTERS
  # RETURNS (%EAX) EITHER 0 OR POINTER TO THE DB GET RESULTS
  QueryMultipleItems:
    pushl %eax                             # temp push back the db page number
    movl $1, %eax                          # move file_code 1 into $eax
    call Read_File_Standard                # read the database file
    call Strlen                            # get the length of the database
    pushl %eax                             # temp push the length to stack
    movl %ebx, %eax                        # move the database end to $eax
    call RunToEnd                          # move string result db pointer to end
    movl %eax, %ebx                        # move the file pointer to $ebx 2nd param
    popl %eax                              # get back the db length and move it into $eax first param
    popl %ecx                              # get back db page number and put into $ecx thrird param
    call Create_GetDBIndexMap              # map out and find the database page

    cmpl $1, %eax                          # check if the search was a sucess
    je .no_page_found                      # jump to no_page_found if we found no valid data
    leal Database_Read_Result_Data, %eax   # link the db result block to the $eax
    xorl %edi, %edi                        # clear out %edi
    .make_get_db_results_loop:             # start of the get db items loop
    movl (%ebx), %ecx                      # get a pointer item from the result map
    addl $4, %ebx                          # increment the result map
    cmpl $0, %ecx                          # check if pointer is null pointer
    je .gained_results_from_db_map         # if null_ptr: jump to return with db results label
    .run_to_title:                         # analyze first chunk of db index here
    movb (%ecx), %dl                       # move char from db index to %dl
    cmpb $'|', %dl                         # check for chunk seperator
    je .read_title                         # jump to next chunk analyzer if we have found it
    inc %ecx                               # increment db result ptr
    jmp .run_to_title                      # jump back to begin of chunk analyzer
    .read_title:                           # analyze second chunk of db index here
    inc %ecx                               # increment db result ptr
    movb (%ecx), %dl                       # move char from db index to %dl
    cmpb $'|', %dl                         # check for chunk seperator
    je .got_title                          # jump to next chunk analyzer if we have found it
    movb %dl, (%eax)                       # move the database chunk item into the result
    inc %eax                               # move the database chunk item into the result
    jmp .read_title                        # jump back to begin of chunk analyzer
    .got_title:                            # analyze third chunk of db index here
    movb $10, (%eax)                       # put result seperatator into the result
    inc %eax                               # move the database chunk item into the result
    .run_to_desc:                          # analyze fourth chunk of db index here
    inc %ecx                               # increment db result ptr
    movb (%ecx), %dl                       # move char from db index to %dl
    cmpb $'|', %dl                         # check for chunk seperator
    je .read_desc                          # jump to next chunk analyzer if we have found it
    jmp .run_to_desc                       # jump back to begin of chunk analyzer
    .read_desc:                            # analyze fifth chunk of db index here
    inc %ecx                               # increment db result ptr
    movb (%ecx), %dl                       # move char from db index to %dl
    cmpb $10, %dl                          # check if end of db index
    je .got_db_index                       # jump if we are at end of db index
    movb %dl, (%eax)                       # move the database chunk item into the result
    inc %eax                               # increment the result pointer
    jmp .read_desc                         # jump back to begin of chunk analyzer
    .got_db_index:                         # analyze sixth and last chunk of db index here
    movb $10, (%eax)                       # put result seperatator into the result
    inc %eax                               # move the database chunk item into the result
    inc %edi                               # increment $edi db result limiter if we hit end of db index
    cmpl $9, %edi                          # check if db result limiter if at end
    je .gained_results_from_db_map         # jump to return result if we are
    jmp .make_get_db_results_loop          # go back and get another index if we are not
    .gained_results_from_db_map:           # label if we got all db results
    movb $0, (%eax)                        # move the end signal null terminator into $eax
    leal Database_Read_Result_Data, %eax   # re-link the begin of the db results to $eax
    ret                                    # return to caller
    .no_page_found:                        # we jump to this label if we did not find valid db result
    xorl %eax, %eax                        # clear out $eax as this means we did not get db result
    ret                                    # return to caller

  # \x1E is deleted value
  # EXAMPLE: B|Post Title|31|Welcome the this fun post. This post is a example \n
