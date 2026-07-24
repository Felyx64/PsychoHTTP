.section .data
  filter_fileroute:
    .asciz "./config/filter.txt"
  db_fileroute:
    .asciz "./database.txt"
  log_fileroute:
    .asciz "./server.log"
  scom_maximalized_error:
    .asciz "Error: scom memory boundry hit! Please edit server src or optamize folder read."

.section .text
  # file codes:
  # 0 = ./config/filter.txt
  # 1 = ./database.txt
  # 2 = ./server.log

  #? MAKE APPENDABLE
  # DESCRIPTION: writes a log to the logfile
  # PARAM: (%EAX) pointer to the start of the string what where logging
  Write_File_Log:
    movl %eax, %esi                     # move the string ptr to the %esi string index register
    movl $2, %eax                       # move file code 2 server.log into %eax
    call Open_File_Stream               # open the read-file-stream
    cmpl $-1, %eax                      # check for error
    je .bad_log_write_error             # throw error if we found error

    movl $0, %ecx                       # move 0 into %ecx so we can see how big the log is
    leal SCOM_File_Write_Data, %edi     # link the write scom to the %edi
    .copy_to_write_data:                # label to start the data writing
    movb (%esi), %bl                    # move a char from the log to temp %bl
    movb %bl, (%edi)                    # move the temp item into the scom
    inc %esi                            # increment log ptr
    inc %edi                            # increment scom ptr
    inc %ecx                            # increment length ptr
    cmpl $1023, %ecx                    # check if we're not overruning scom
    je .end_of_log_write                # jump if we are
    cmpb $'\0', %bl                     # check if we're at end of log ptr
    jne .copy_to_write_data             # jump back if we're still copying
    .end_of_log_write:                  # end of loop label
    movl $'\n', (%edi)                  # replace null with new line

    movl %eax, %ebx                     # move the server fd into param 1
    movl %ecx, %edx                     # move the length of string to write into param 3
    leal SCOM_File_Write_Data, %ecx     # link the SCOM_File_Write_Data to param 2
    movl $4, %eax                       # move syscall id to %eax
    int $0x80                           # trigger syscall 'write'

    movl $6, %eax                       # move syscall id to %eax
    int $0x80                           # trigger syscall 'close'

    movl %ecx, %eax                     # move the scom to %eax for the coming function
    call Clear_SCOM                     # clear the scom memory

    .bad_log_write_error:               # go back label
    ret                                 # return

  # reads a file and pushes its data to the scom
  # Param: (%eax) code for which file has to be read
  # RETURNS: (%eax) pointer to beginning of the scom data
  # USING: %EAX, %EBX, %ECX, %EDX, %ESI
  Read_File_Standard:
    call Open_File_Stream               # create a FileReadStream
    cmpl $-1, %eax                      # compare with -1 for error
    je  .bad_file_open_error            # jump to end of function if failed

    movl $0, %esi                       # move 2 into %esi as a temp object needed for
    movl %eax, %ebx                     # move the fd we got from opening to stream to %ebx
    leal SCOM_File_Read_Results, %ecx   # make %ecx point towards the scom memory
    movl %ecx, %edi                     # copy the pointer to the scom memory
    addl $1023, %edi                    # add 1023 to the pointer code so we dont write further than the scom memory itself
    movl $1, %edx                       # move 1 into %edx so we are always reading 1 char. Also acts as smth we can use to check if we stopeed bc scom or file space
    .read_char_loop:                    # read loop starts here
    movl $3, %eax                       # move the syscall id back into %eax so the result is overwritten
    int $0x80                           # engage syscall
    inc %ecx                            # increment the pointer to the scom

    cmpl %edi, %ecx                     # compare the 2 pointers if we have reached scom boundry
    cmovel %esi, %edx                   # move 0 into edx if we have hit end of scom memory
    je .done_reading_file               # exit the loop if we have reached the end of scom

    cmpl $0, %eax                       # check if we have hit the end of the file
    jne .read_char_loop                 # exit the loop if we did hit the end of the file
    .done_reading_file:

    movl $0, (%ecx)                     # move null terminator to end of scom memory

    cmpl $0, %edx                       # this is if we hit end of scom
    jne .not_scom_boundry               # jump if we did not hit scom boundry
    pushl %ebx                          # temp push readstream towards the stack
    movl $scom_maximalized_error, %eax  # move the scom max error to the %eaxmovl $1, %eax

    call nstandard_console_write        # report on user the scom boundry error
    popl %eax                           # pop the stack and move the readstream back into %ebx
    .not_scom_boundry:                  # go on here if we did not hit scom boundry

    call Close_File_Stream              # call function to close readstream

    .bad_file_open_error:
    ret

  # queries the file if db and moves queried data to scom
  Read_File_Query:
    ret

  # writes to the database file
  Write_File_Query:
    ret

  # opens up a read file stream
  # Param (%eax) pointer to file location
  # RETURNS: (%eax) file_stream or error
  Open_File_Stream:
    call Parse_File_Id                  # get the file from its id
    movl %eax, %ebx                     # move param into 2nd param
    movl $5, %eax                       # move syscall id into first param
    int $0x80                           # call syscall SYS_Open
    ret

  # get the file route from the provided file_id
  # Param: (%eax) the file code itself
  # Returns: (%eax) pointer to the file route
  Parse_File_Id:
    jmp *file_id_table(,%eax,4)         # switch statement the file id's

    file_id_table:                      # table of possible places to go to in the switch statement
      .long is_filter_id                # for if its the filter file
      .long is_db_id                    # for if its the db file
      .long is_log_id                   # for it its the log file

    is_filter_id:                       # start of function return filter file_route
    leal filter_fileroute, %eax         # link filter file route and return
    ret                                 # return

    is_db_id:                           # start of function return db file_route
    leal db_fileroute, %eax             # link db file route and return
    ret                                 # return

    is_log_id:                          # start of function return log file_route
    leal log_fileroute, %eax            # link log file route and return
    ret                                 # return

  # close a potential file read stream
  # Param: (%eax) the file readstream itself
  # Returns: (%eax) error-sucess code
  # OVERWRITES: EBX
  Close_File_Stream:
    movl %eax, %eax                     # move syscall code (SYS_close) to the %eax
    movl $6, %eax                       # pop the stack and move the readstream back into %ebx
    int $0x80                           # trigger syscall (SYS_close)
    ret
