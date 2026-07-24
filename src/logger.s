.section .bss
    LoggerMemory:
      .space 4096

    LogEventCode:
      .long 0

.set CLONE_FLAGS, (0x00000100 | 17)

.section .text
  Initialize_Server_Logger:
    # NEED FLAG 0x00000100 aka CLONE_VM for the event process
    movl $120, %eax                         # move the syscall sys_clone code into %eax
    movl $CLONE_FLAGS, %ebx                 # move the syscall flags in second param %ebx
    movl $LoggerMemory, %ecx                # give our logging thread some stack memory
    addl $4096, %ecx                        # move the stack pointer back to the end
    int $0x80                               # create new thread with syscall
    cmpl $0, %eax                           # do some checking so that main thread can get out of the way of the 2nd thread's business
    jne  .initializtion_done                # jump out of the function if we are the main thread
    .start_logger_thread:                   # 2nd thread starts here

    # logger operates here as an event driven engine
    # so events are handled and checked for in this loop

    # add sleep until not 0

    leal LogEventCode, %eax   # initialize shared main-log thread event memory
    jmp *log_action_table(,(%eax),4)        # switch over the value stored in %eax to check if we need to log something

    log_action_table:                       # table of functions which we can jump to once the event listiner gets woken up
      .long invallid_log
      .long log_request                     # log format `Request: HOST_IP - - [DATE:TIME] "METHOD ROUTE (USER_AGENT)" \n`
      .long log_database                    # log format `Database: ACTION - - AMOUNT bytes \n`
      .long log_server_event                # log format `Server: EVENT - - MESSAGE \n`

    invallid_log:
      # do nothing
      jmp .start_logger_thread

    log_request:
      # log format `Request: HOST_IP - - [DATE:TIME] "METHOD ROUTE (USER_AGENT)" \n`
      #? MAY REPLACE WITH PUSHB operation

      pushl %esp                              # push the current stack cordinates to the stack so we know where to reset to

      # we need \0 so we can search for the begin of the string
      # Write to stack '\0Request: '
      pushl $'\0'
      pushl $'R'
      pushl $'e'
      pushl $'q'
      pushl $'u'
      pushl $'e'
      pushl $'s'
      pushl $'t'
      pushl $':'
      pushl $' '

      leal Request_Host_Header, %eax          # Create pointer to the first string we are searching for
      leal SCOM_User_Server_Request, %ebx     # Create pointer to the text we are searching in
      movl $6, %ecx                           # length of word we are searching for
      call String_Search_Word                 # search for word

      cmpl $0, %eax                           # check if we did find the Host ip
      je .invallid_ip_proc                    # if not we say the host was invallid
      .valid_str_loop:                        # loop writes the ip to the log if we did find something
      inc %ebx                                # increment the ip so we are looking at the ip and other vals
      pushl (%ebx)                            # push ip diget to stack
      cmpl $'\n', (%ebx)                      # check if we are end of string
      je .ip_assign_loop_done                 # jump to the assign loop end if we are at the end of the ip
      jne .valid_str_loop                     # go back to begin of loop if we are not at the ip end
      .invallid_ip_proc:
      # Write to stack 'Bad_Ip: ' if we did not get a valid ip
      pushl $'B'
      pushl $'a'
      pushl $'d'
      pushl $'_'
      pushl $'I'
      pushl $'P'
      .ip_assign_loop_done:

      # assign to stack " - - ["
      pushl $' '
      pushl $'-'
      pushl $' '
      pushl $'-'
      pushl $' '
      pushl $'['

      call get_unix_sec                       # get the current unix time

      pushl %eax                              # temp copy unix time to stack
      call get_current_year                   # get the current year
      leal SCOM_IntStr_Convert_Results, %edi  # link the string copy result buffer to %edi
      call IntToString                        # convert the resulted year to a string
      popl %ebx                               # remove the unix time from the stack to prevent corruption
      pushl 0(%edi)                           # push the year-str to the stack
      pushl 1(%edi)                           # push the year-str to the stack
      pushl 2(%edi)                           # push the year-str to the stack
      pushl 3(%edi)                           # push the year-str to the stack
      movl %edi, %eax                         # move the resulted buffer to %eax
      call Clear_SCOM                         # clear the resulted buffer
      movl %ebx, %eax                         # move the unix time back to the %eax to continue

      pushl $'-'                              # push log seperator to the stack

      pushl %eax                              # temp copy unix time to stack
      call get_current_month                  # get the current month
      leal SCOM_IntStr_Convert_Results, %edi  # link the string copy result buffer to %edi
      call IntToString                        # convert the resulted month to a string
      popl %ecx                               # remove the unix time from the stack to prevent corruption
      pushl 0(%edi)                           # push the first non-corrupt diget to the stack
      movl %esp, %ebx                         # backup the current stack-pointer to %ebx
      dec %esp                                # create space for the new potential stack pointer location
      cmpl $0, 1(%edi)                        # check if next char is end of month-str
      cmovnel 1(%edi), (%esp)                 # if yes: move move char into the stack
      cmovel %ebx, %esp                       # if no: reset the stack pointer to its previous state
      movl %edi, %eax                         # move the resulted buffer to %eax
      call Clear_SCOM                         # clear the resulted buffer
      movl %ecx, %eax                         # move the unix time back to the %eax to continue

      pushl $'-'                              # push log seperator to the stack

      pushl %eax                              # temp copy unix time to stack
      call get_current_day                    # get the current day
      leal SCOM_IntStr_Convert_Results, %edi  # link the string copy result buffer to %edi
      call IntToString                        # convert the resulted day to a string
      popl %ecx                               # remove the unix time from the stack to prevent corruption
      pushl 0(%edi)                           # push the first non-corrupt diget to the stack
      movl %esp, %ebx                         # backup the current stack-pointer to %ebx
      dec %esp                                # create space for the new potential stack pointer location
      cmpl $0, 1(%edi)                        # check if next char is end of month-str
      cmovnel 1(%edi), (%esp)                 # if yes: move move char into the stack
      cmovel %ebx, %esp                       # if no: reset the stack pointer to its previous state
      movl %edi, %eax                         # move the resulted buffer to %eax
      call Clear_SCOM                         # clear the resulted buffer
      movl %ecx, %eax                         # move the unix time back to the %eax to continue

      pushl $' '                              # push log seperator to the stack

      pushl %eax                              # temp copy unix time to stack
      call get_current_hour                   # get the current hour
      leal SCOM_IntStr_Convert_Results, %edi  # link the string copy result buffer to %edi
      call IntToString                        # convert the resulted day to a string
      popl %ecx                               # remove the unix time from the stack to prevent corruption
      pushl 0(%edi)                           # push the first non-corrupt diget to the stack
      movl %esp, %ebx                         # backup the current stack-pointer to %ebx
      dec %esp                                # create space for the new potential stack pointer location
      cmpl $0, 1(%edi)                        # check if next char is end of month-str
      cmovnel 1(%edi), (%esp)                 # if yes: move move char into the stack
      cmovel %ebx, %esp                       # if no: reset the stack pointer to its previous state
      movl %edi, %eax                         # move the resulted buffer to %eax
      call Clear_SCOM                         # clear the resulted buffer
      movl %ecx, %eax                         # move the unix time back to the %eax to continue

      pushl $':'                              # push log seperator to the stack

      call get_current_minute                 # get the current minute
      leal SCOM_IntStr_Convert_Results, %edi  # link the string copy result buffer to %edi
      call IntToString                        # convert the resulted day to a string
      pushl 0(%edi)                           # push the first non-corrupt diget to the stack
      movl %esp, %ebx                         # backup the current stack-pointer to %ebx
      dec %esp                                # create space for the new potential stack pointer location
      cmpl $0, 1(%edi)                        # check if next char is end of month-str
      cmovnel 1(%edi), (%esp)                 # if yes: move move char into the stack
      cmovel %ebx, %esp                       # if no: reset the stack pointer to its previous state
      movl %edi, %eax                         # move the resulted buffer to %eax
      call Clear_SCOM                         # clear the resulted buffer

      # push log seperators to the stack
      pushl $']'
      pushl $' '

      leal SCOM_User_Server_Request, %edi     # move the request string into edi
      movl 1(%edi), %eax                      # get the first char of the request body because it holds the method
      cmpl $'G', %eax                         # check if its G meaning GET request
      je .write_get_to_log                    # go to the write get method to log if we found it
      cmpl $'P', %eax                         # check if its P meaning POST request
      je .write_post_to_log                   # go to the write post method to the log if we found it

      # write ??? which means it was a unrocognized or disallowed request
      pushl $'?'
      pushl $'?'
      pushl $'?'

      jmp .end_of_method_write                # jump over the other log writes so no corruption happens
      .write_get_to_log:                      # start of write GET procedure

      # write GET if its a get request
      pushl $'G'
      pushl $'E'
      pushl $'T'

      jmp .end_of_method_write                # jump over the other log writes so no corruption happens
      .write_post_to_log:                     # start of write POST procedure

      # write POST if its a post request
      pushl $'P'
      pushl $'O'
      pushl $'S'
      pushl $'T'

      .end_of_method_write:                   # end of write method logic is here
      pushl $' '                              # move a seperator to the log

      .search_route_loop:                     # start loop to search for the beginning of the route
      inc %edi                                # increment the pointer to keep searching
      cmpl $'/', (%edi)                       # check if we found the route
      jne .search_route_loop                  # if we still not on the route we jump back
      .insert_to_log_loop:                    # start of write route loop
      pushl (%edi)                            # write the route to the stack
      inc %edi                                # increment the pointer
      cmpl $' ', (%edi)                       # check if we hit the end of the route
      jne .insert_to_log_loop                 # jump back if not

      pushl $' '                              # add log seperator

      # start searching for the user-agent
      leal Request_User_Agent_Header, %eax    # Create pointer to the first string we are searching for
      leal SCOM_User_Server_Request, %ebx     # Create pointer to the text we are searching in
      movl $12, %ecx                          # length of word we are searching for
      call String_Search_Word                 # search for word

      movl %ebx, %edi                         # move the found string to the string get register
      .not_found_end_of_ua:                   # start of get user-agent loop
      pushl (%edi)                            # push user agent char to the stack
      inc %edi                                # increment the pointer looking at the user agent
      cmpl $'\n', (%edi)                      # check if we are at the end of the string
      jne .not_found_end_of_ua                # jump back to begin of loop if not at end of user-agent get loop

      movl %esp, %edi                         # push stack pointer to %edi as we are now gonna string search the start of the log again as its done
      addl $1, %edi                           # add 1 so we dont auto-complete the search with the null-termintor
      .search_start_of_log:                   # start of search log begin loop
      dec %edi                                # decrement the pointer
      cmpl $0x0, (%edi)                       # see if we have found null which is also at the start of the string
      jne .search_start_of_log                # jump back if we have not hit the start of the string
      inc %edi                                # increment the pointer again so we are not looking at the start null to not confuse the incoming log

      movl %edi, %eax                         # move the pointer to %eax so we can start logging to the console
      call nstandard_console_write            # log the request log to the console

      # log to log-file

      jmp .start_logger_thread

    log_database:
      jmp .start_logger_thread

    log_server_event:
      jmp .start_logger_thread

    # request log done here


    jmp .start_logger_thread                  # 2nd thread ends here but goes back to the start of the loop
    .initializtion_done:
    ret


    cmpl $0, %eax
    jne  .initializtion_done


# this file stores keywords we will be searching for in SCOM or other data during the logging process
.section .data
  Request_Host_Header:
    .ascii "Host: "

  Request_User_Agent_Header:
    .ascii "User-Agent: "
