.section .bss
  LoggerMemory:
    .space 4096

  LogEventCode:
    .long 0

  LogEventTypeID:
    .long 0

  FutexTimeout:
    .long 2
    .long 0

.set CLONE_FLAGS, (0x00000100 | 17)
.set FUTEX_FLAGS, (FUTEX_WAIT | FUTEX_PRIVATE_FLAG)

.section .text
  Initialize_Server_Logger:
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

    movl $240, %eax                         # move event code 240 to %eax for syscall sys_futex
    movl $LogEventCode, %ebx                # move event code into 2nd param
    movl $FUTEX_FLAGS, %ecx                 # move the flags into param 3
    movl $0, %edx                           # move 0 into %edx so we only wait till its not 0
    movl $FutexTimeout, %esi                # move the the timeout params into param 5
    movl $0, %edi                           # make param 6 empty
    movl $0, %ebp                           # make param 7 empty
    int $0x80                               # trigger syscall sys_futex

    cmpl $0, %eax                           # check event was triggered
    je .event_triggered                     # jump if it was


    jmp .start_logger_thread                # jump back if no event found
    .event_triggered:                       # label if even is triggered

    #? dev
    movl $1, %eax
    movl $9, %ebx
    int $0x80

    movl $LogEventCode, %eax                # initialize shared main-log thread event memory
    jmp *log_action_table(,(%eax),4)        # switch over the value stored in %eax to check if we need to log something

    log_action_table:                       # table of functions which we can jump to once the event listiner gets woken up
      .long invallid_log
      .long log_request                     # log format `Request: HOST_IP - - [DATE:TIME] "METHOD ROUTE (USER_AGENT)" \n`
      .long log_database                    # log format `Database: ACTION - - AMOUNT bytes \n`
      .long log_server_event                # log format `Server: EVENT - - MESSAGE \n`
      .long log_disable                     # ends the logging all togheter

    invallid_log:
      # do nothing
      jmp .start_logger_thread

    log_request:
      # log format `Request: HOST_IP - - [DATE:TIME] "METHOD ROUTE (USER_AGENT)" \n`
      #? MAY REPLACE WITH PUSHB operation

      # we need \0 so we can search for the begin of the string
      # Write to stack '\0Request: '
      pushb $'\0'
      pushb $'R'
      pushb $'e'
      pushb $'q'
      pushb $'u'
      pushb $'e'
      pushb $'s'
      pushb $'t'
      pushb $':'
      pushb $' '

      leal Request_Host_Header, %eax          # Create pointer to the first string we are searching for
      leal SCOM_User_Server_Request, %ebx     # Create pointer to the text we are searching in
      movl $6, %ecx                           # length of word we are searching for
      call String_Search_Word                 # search for word

      cmpl $0, %eax                           # check if we did find the Host ip
      je .invallid_ip_proc                    # if not we say the host was invallid
      .valid_str_loop:                        # loop writes the ip to the log if we did find something
      inc %ebx                                # increment the ip so we are looking at the ip and other vals
      pushb (%ebx)                            # push ip diget to stack
      cmpl $'\n', (%ebx)                      # check if we are end of string
      je .ip_assign_loop_done                 # jump to the assign loop end if we are at the end of the ip
      jne .valid_str_loop                     # go back to begin of loop if we are not at the ip end
      .invallid_ip_proc:
      # Write to stack 'Bad_Ip: ' if we did not get a valid ip
      pushb $'B'
      pushb $'a'
      pushb $'d'
      pushb $'_'
      pushb $'I'
      pushb $'P'
      .ip_assign_loop_done:

      # assign to stack " - - ["
      pushb $' '
      pushb $'-'
      pushb $' '
      pushb $'-'
      pushb $' '
      pushb $'['

      call get_unix_sec                       # get the current unix time

      pushl %eax                              # temp copy unix time to stack
      call get_current_year                   # get the current year
      leal SCOM_IntStr_Convert_Results, %edi  # link the string copy result buffer to %edi
      call IntToString                        # convert the resulted year to a string
      popl %ebx                               # remove the unix time from the stack to prevent corruption
      pushb 0(%edi)                           # push the year-str to the stack
      pushb 1(%edi)                           # push the year-str to the stack
      pushb 2(%edi)                           # push the year-str to the stack
      pushb 3(%edi)                           # push the year-str to the stack
      movl %edi, %eax                         # move the resulted buffer to %eax
      call Clear_SCOM                         # clear the resulted buffer
      movl %ebx, %eax                         # move the unix time back to the %eax to continue

      pushb $'-'                              # push log seperator to the stack

      pushl %eax                              # temp copy unix time to stack
      call get_current_month                  # get the current month
      leal SCOM_IntStr_Convert_Results, %edi  # link the string copy result buffer to %edi
      call IntToString                        # convert the resulted month to a string
      popl %ecx                               # remove the unix time from the stack to prevent corruption
      pushb 0(%edi)                           # push the first non-corrupt diget to the stack
      movl %esp, %ebx                         # backup the current stack-pointer to %ebx
      dec %esp                                # create space for the new potential stack pointer location
      cmpl $0, 1(%edi)                        # check if next char is end of month-str
      cmovnel 1(%edi), (%esp)                 # if yes: move move char into the stack
      cmovel %ebx, %esp                       # if no: reset the stack pointer to its previous state
      movl %edi, %eax                         # move the resulted buffer to %eax
      call Clear_SCOM                         # clear the resulted buffer
      movl %ecx, %eax                         # move the unix time back to the %eax to continue

      pushb $'-'                              # push log seperator to the stack

      pushl %eax                              # temp copy unix time to stack
      call get_current_day                    # get the current day
      leal SCOM_IntStr_Convert_Results, %edi  # link the string copy result buffer to %edi
      call IntToString                        # convert the resulted day to a string
      popl %ecx                               # remove the unix time from the stack to prevent corruption
      pushb 0(%edi)                           # push the first non-corrupt diget to the stack
      movl %esp, %ebx                         # backup the current stack-pointer to %ebx
      dec %esp                                # create space for the new potential stack pointer location
      cmpl $0, 1(%edi)                        # check if next char is end of month-str
      cmovnel 1(%edi), (%esp)                 # if yes: move move char into the stack
      cmovel %ebx, %esp                       # if no: reset the stack pointer to its previous state
      movl %edi, %eax                         # move the resulted buffer to %eax
      call Clear_SCOM                         # clear the resulted buffer
      movl %ecx, %eax                         # move the unix time back to the %eax to continue

      pushb $' '                              # push log seperator to the stack

      pushl %eax                              # temp copy unix time to stack
      call get_current_hour                   # get the current hour
      leal SCOM_IntStr_Convert_Results, %edi  # link the string copy result buffer to %edi
      call IntToString                        # convert the resulted day to a string
      popl %ecx                               # remove the unix time from the stack to prevent corruption
      pushb 0(%edi)                           # push the first non-corrupt diget to the stack
      movl %esp, %ebx                         # backup the current stack-pointer to %ebx
      dec %esp                                # create space for the new potential stack pointer location
      cmpl $0, 1(%edi)                        # check if next char is end of month-str
      cmovnel 1(%edi), (%esp)                 # if yes: move move char into the stack
      cmovel %ebx, %esp                       # if no: reset the stack pointer to its previous state
      movl %edi, %eax                         # move the resulted buffer to %eax
      call Clear_SCOM                         # clear the resulted buffer
      movl %ecx, %eax                         # move the unix time back to the %eax to continue

      pushb $':'                              # push log seperator to the stack

      call get_current_minute                 # get the current minute
      leal SCOM_IntStr_Convert_Results, %edi  # link the string copy result buffer to %edi
      call IntToString                        # convert the resulted day to a string
      pushb 0(%edi)                           # push the first non-corrupt diget to the stack
      movl %esp, %ebx                         # backup the current stack-pointer to %ebx
      dec %esp                                # create space for the new potential stack pointer location
      cmpl $0, 1(%edi)                        # check if next char is end of month-str
      cmovnel 1(%edi), (%esp)                 # if yes: move move char into the stack
      cmovel %ebx, %esp                       # if no: reset the stack pointer to its previous state
      movl %edi, %eax                         # move the resulted buffer to %eax
      call Clear_SCOM                         # clear the resulted buffer

      # push log seperators to the stack
      pushb $']'
      pushb $' '

      leal SCOM_User_Server_Request, %edi     # move the request string into edi
      movl 1(%edi), %eax                      # get the first char of the request body because it holds the method
      cmpl $'G', %eax                         # check if its G meaning GET request
      je .write_get_to_log                    # go to the write get method to log if we found it
      cmpl $'P', %eax                         # check if its P meaning POST request
      je .write_post_to_log                   # go to the write post method to the log if we found it

      # write ??? which means it was a unrocognized or disallowed request
      pushb $'?'
      pushb $'?'
      pushb $'?'

      jmp .end_of_method_write                # jump over the other log writes so no corruption happens
      .write_get_to_log:                      # start of write GET procedure

      # write GET if its a get request
      pushb $'G'
      pushb $'E'
      pushb $'T'

      jmp .end_of_method_write                # jump over the other log writes so no corruption happens
      .write_post_to_log:                     # start of write POST procedure

      # write POST if its a post request
      pushb $'P'
      pushb $'O'
      pushb $'S'
      pushb $'T'

      .end_of_method_write:                   # end of write method logic is here
      pushb $' '                              # move a seperator to the log

      .search_route_loop:                     # start loop to search for the beginning of the route
      inc %edi                                # increment the pointer to keep searching
      cmpl $'/', (%edi)                       # check if we found the route
      jne .search_route_loop                  # if we still not on the route we jump back
      .insert_to_log_loop:                    # start of write route loop
      pushb (%edi)                            # write the route to the stack
      inc %edi                                # increment the pointer
      cmpl $' ', (%edi)                       # check if we hit the end of the route
      jne .insert_to_log_loop                 # jump back if not

      pushb $' '                              # add log seperator

      # start searching for the user-agent
      leal Request_User_Agent_Header, %eax    # Create pointer to the first string we are searching for
      leal SCOM_User_Server_Request, %ebx     # Create pointer to the text we are searching in
      movl $12, %ecx                          # length of word we are searching for
      call String_Search_Word                 # search for word

      movl %ebx, %edi                         # move the found string to the string get register
      .not_found_end_of_ua:                   # start of get user-agent loop
      pushb (%edi)                            # push user agent char to the stack
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

      movl %edi, %eax                         # move the pointer to %eax so we can start logging to the logfile
      pushl %edi                              # backup the pointer to the log as we need it to clear the stack
      call Write_File_Log                     # log the request to the log file
      popl %eax                               # bring %edi back into %eax

      subl $2, %eax                           # subtract 2 from %edi so we found the old adress of the stack pointer before we started the log
      movl %edi, %esp                         # move the old stack adress so we have resetted the stack pointer

      jmp .logged_svr_msg

    log_database:
      # log format `Database: ACTION - - AMOUNT bytes \n`
      #? MAY REPLACE WITH PUSHB operation
      pushb $'\0'
      pushb $'D'
      pushb $'a'
      pushb $'t'
      pushb $'a'
      pushb $'b'
      pushb $'a'
      pushb $'s'
      pushb $'e'
      pushb $':'
      pushb $' '

      movl $LogEventTypeID, %eax
      jmp *database_action_log_table(,(%eax),4)

      database_action_log_table:
        .long invallid_databaselog    # (0) log: database is invallid
        .long write_databaselog       # (1) log: database is writing
        .long read_databaselog        # (2) log: database is reading

      invallid_databaselog:
        # log message that database log is invallid
        pushb $'I'
        pushb $'N'
        pushb $'V'
        pushb $'A'
        pushb $'L'
        pushb $'\n'

        call nstandard_console_write
        call Write_File_Log
        jmp .logged_svr_msg
      write_databaselog:
        # log if we are writing
        pushb $'W'
        pushb $'R'
        pushb $'I'
        pushb $'T'
        pushb $'E'
        pushb $' '

        #? DO LATER GRAB FROM SCOM MEMORY

        call nstandard_console_write
        call Write_File_Log
        jmp .logged_svr_msg
      read_databaselog:
        # log if we are reading
        pushb $'R'
        pushb $'E'
        pushb $'A'
        pushb $'D'
        pushb $' '

        #? DO LATER GRAB FROM SCOM MEMORY

        call nstandard_console_write
        call Write_File_Log
        jmp .logged_svr_msg


      movl $0, %eax                           # move 0 into %eax
      leal LogEventCode, %ebx                 # link the event code shared memory with %ebx
      movl %eax, (%ebx)                       # move 0 back into the event code memory to reset the logger
      leal LogEventTypeID, %ebx               # link the second event code shared memory with %ebx
      movl %eax, (%ebx)                       # move 0 back into the second event code memory to reset the logger
      jmp .start_logger_thread

    log_server_event:
      # log format `Server: EVENT - - MESSAGE \n`

      movl $LogEventTypeID, %eax              # grab the log event id and store it in %eax
      jmp *server_log_action_table(,(%eax),4) # jump to the location the id is pointing at

      server_log_action_table:                # table of functions which we can jump to once we need to do server log
        .long invallid_serverlog              # (0) log:  Server: Error - - Bad lgid detected. Bailout reccomended! (0x0)
        .long init_servermsg                  # (1) log:  Server: Info - - Initializing server
        .long socket_createdmsg               # (2) log:  Server: Info - - Socket has been created
        .long socket_configmsg                # (3) log:  Server: Info - - Socket has been configured
        .long socket_initmsg                  # (4) log:  Server: Info - - Socket has been Initialized...
        .long socket_listeningmsg             # (5) log:  Server: Info - - Socket now listening onto port 7870
        .long database_connectingdbmsg        # (6) log:  Server: Info - - Database is currently connecting
        .long database_connectedmsg           # (7) log:  Server: Info - - Database is now connected!
        .long database_disconnected           # (8) log:  Server: Info - - Database has been disconnected
        .long logger_has_been_initialized     # (9) log:  Server: Info - - Logger has been Initialized
        .long server_standard_exit            # (10) log: Server: Info - - Server is currently shutting down..
        .long server_bailout_sockererr        # (11) log: Server: Error - - Bad socket creation. Exiting server.
        .long server_bailout_sockconferr      # (12) log: Server: Error - - Bad config. Exiting Server.
        .long server_bailout_sockiniterr      # (13) log: Server: Error - - Bad socket initialization. Exiting..
        .long server_bailout_badsvr           # (14) log: Server: Error - - Bad server or listener. Exiting..
        .long server_bailout_bad_generic      # (15) log: Server: Error - - Bad or inval init. Exiting...
        .long server_bailout_bailout          # (16) log: Server: Error - - Uncat Error Flagged. Exiting..
        .long server_developer_exit           # (17) log: Server: Error - - Devexitt

        invallid_serverlog:
          # Server: Error - - Bad lgid detected. Bailout reccomended! (0x0)
          movl $Log_Server_Status_BADLGID_ERR, %eax
          call nstandard_console_write
          call Write_File_Log
          jmp .logged_svr_msg
        init_servermsg:
          # Server: Info - - Initializing server
          movl $Log_Server_Status_Initializing, %eax
          call nstandard_console_write
          call Write_File_Log
          jmp .logged_svr_msg
        socket_createdmsg:
          # Server: Info - - Socket has been created
          movl $Log_Server_Status_Created_System_Socket, %eax
          call nstandard_console_write
          call Write_File_Log
          jmp .logged_svr_msg
        socket_configmsg:
          # Server: Info - - Socket has been configured
          movl $Log_Server_Status_Configured_System_Socket, %eax
          call nstandard_console_write
          call Write_File_Log
          jmp .logged_svr_msg
        socket_initmsg:
          # Server: Info - - Socket has been Initialized...
          movl $Log_Server_Status_Initialized_server_socket, %eax
          call nstandard_console_write
          call Write_File_Log
          jmp .logged_svr_msg
        socket_listeningmsg:
          # Server: Info - - Socket now listening onto port 7870
          movl $Log_Server_Status_now_listening, %eax
          call nstandard_console_write
          call Write_File_Log
          jmp .logged_svr_msg
        database_connectingdbmsg:
          # Server: Info - - Database is currently connecting
          movl $Log_Server_Status_database_connecting, %eax
          call nstandard_console_write
          call Write_File_Log
          jmp .logged_svr_msg
        database_connectedmsg:
          # Server: Info - - Database is now connected!
          movl $Log_Server_Status_database_Connected, %eax
          call nstandard_console_write
          call Write_File_Log
          jmp .logged_svr_msg
        database_disconnected:
          # Server: Info - - Database has been disconnected
          movl $Log_Server_Status_database_disconnected, %eax
          call nstandard_console_write
          call Write_File_Log
          jmp .logged_svr_msg
        logger_has_been_initialized:
          # Server: Info - - Logger has been Initialized
          movl $Log_Server_Status_logger_initialized, %eax
          call nstandard_console_write
          call Write_File_Log
          jmp .logged_svr_msg
        server_standard_exit:
          # Server: Info - - Server is currently shutting down..
          movl $Log_Serrver_Status_Shutdown, %eax
          call nstandard_console_write
          call Write_File_Log
          jmp .logged_svr_msg
        server_bailout_sockererr:
          # Server: Error - - Bad socket creation. Exiting server.
          movl $Log_Serrver_Status_Err_BadSock, %eax
          call nstandard_console_write
          call Write_File_Log
          jmp .logged_svr_msg
        server_bailout_sockconferr:
          # Server: Error - - Bad config. Exiting Server.
          movl $Log_Serrver_Status_Err_BadConf, %eax
          call nstandard_console_write
          call Write_File_Log
          jmp .logged_svr_msg
        server_bailout_sockiniterr:
          # Server: Error - - Bad socket initialization. Exiting..
          movl $Log_Serrver_Status_Err_BadInit, %eax
          call nstandard_console_write
          call Write_File_Log
          jmp .logged_svr_msg
        server_bailout_badsvr:
          # Server: Error - - Bad server or listener. Exiting..
          movl $Log_Serrver_Status_Err_BadList, %eax
          call nstandard_console_write
          call Write_File_Log
          jmp .logged_svr_msg
        server_bailout_bad_generic:
          # Server: Error - - Bad or inval init. Exiting...
          movl $Log_Serrver_Status_Err_BadSvrInit, %eax
          call nstandard_console_write
          call Write_File_Log
          jmp .logged_svr_msg
        server_bailout_bailout:
          # Server: Error - - Uncat Error Flagged. Exiting..
          movl $Log_Serrver_Status_Err_Unkown_Error, %eax
          call nstandard_console_write
          call Write_File_Log
          jmp .logged_svr_msg
        server_developer_exit:
          # Server: Error - - Devexitt
          movl $Log_Serrver_Status_Err_Developer_Exit, %eax
          call nstandard_console_write
          call Write_File_Log
          jmp .logged_svr_msg

      .logged_svr_msg:                        # universal endpoint for all logged messages

      movl $0, %eax                           # move 0 into %eax
      leal LogEventCode, %ebx                 # link the event code shared memory with %ebx
      movl %eax, (%ebx)                       # move 0 back into the event code memory to reset the logger
      leal LogEventTypeID, %ebx               # link the second event code shared memory with %ebx
      movl %eax, (%ebx)                       # move 0 back into the second event code memory to reset the logger
      jmp .start_logger_thread

    log_disable:
      # Server: Info - - Logger has been Disabled
      movl $Log_Server_Status_Logger_Disabled, %eax
      call nstandard_console_write
      call Write_File_Log

      # kill the thread
      movl $1, %eax                              # move 1 into %EAX to call syscall (exit)
      movl $78, %ebx                             # exit with code 78 instead of 1 for debug purposes (thread_exit)
      int $0x80                                  # trigger (exit) syscall itself

    .initializtion_done:
    ret


# this file stores keywords we will be searching for in SCOM or other data during the logging process
.section .data
  Request_Host_Header:
    .ascii "Host: "

  Request_User_Agent_Header:
    .ascii "User-Agent: "

# this section stores random server status constants for logging
.section .data
  Log_Server_Status_BADLGID_ERR:
    .asciz "Server: Error - - Bad lgid detected. Bailout reccomended! (0x0) \n"
  Log_Server_Status_Initializing:
    .asciz "Server: Info - - Initializing server \n"
  Log_Server_Status_Created_System_Socket:
    .asciz "Server: Info - - Socket has been created \n"
  Log_Server_Status_Configured_System_Socket:
    .asciz "Server: Info - - Socket has been configured \n"
  Log_Server_Status_Initialized_server_socket:
    .asciz "Server: Info - - Socket has been Initialized... \n"
  Log_Server_Status_now_listening:
    .asciz "Server: Info - - Socket now listening onto port 7870 \n"
  Log_Server_Status_database_connecting:
    .asciz "Server: Info - - Database is currently connecting \n"
  Log_Server_Status_database_Connected:
    .asciz "Server: Info - - Database is now connected! \n"
  Log_Server_Status_database_disconnected:
    .asciz "Server: Info - - Database has been disconnected \n"
  Log_Server_Status_logger_initialized:
    .asciz "Server: Info - - Logger has been Initialized \n"
  Log_Server_Status_Logger_Disabled:
    .asciz "Server: Info - - Logger has been Disabled \n"
  Log_Serrver_Status_Shutdown:
    .asciz "Server: Info - - Server is currently shutting down.."
  Log_Serrver_Status_Err_BadSock:
    .asciz "Server: Error - - Bad socket creation. Exiting server."
  Log_Serrver_Status_Err_BadConf:
    .asciz "Server: Error - - Bad config. Exiting Server."
  Log_Serrver_Status_Err_BadInit:
    .asciz "Server: Error - - Bad socket initialization. Exiting.."
  Log_Serrver_Status_Err_BadList:
    .asciz "Server: Error - - Bad server or listener. Exiting.."
  Log_Serrver_Status_Err_BadSvrInit:
    .asciz "Server: Error - - Bad or inval init. Exiting..."
  Log_Serrver_Status_Err_Unkown_Error:
    .asciz "Server: Error - - Uncat Error Flagged. Exiting.."
  Log_Serrver_Status_Err_Developer_Exit:
    .asciz "Server: Error - - Devexitt"
