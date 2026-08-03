# PARAM (EAX) event type id
# PARAM (EBX) event paremeter 1
# DESCRIPTION: logs a certain server event to the console
.section .text
  Log_Message:
    jmp *log_action_table(,%eax,4)          # switch over the value stored in %eax to check if we need to log something
    log_action_table:                       # table of functions which we can jump to once the event listiner gets woken up
      .long invallid_log
      .long log_request                     # log format `Request: HOST_IP - - [DATE:TIME] "METHOD ROUTE (USER_AGENT)" \n`
      .long log_database                    # log format `Database: ACTION - - AMOUNT bytes \n`
      .long log_server_event                # log format `Server: EVENT - - MESSAGE \n`

    invallid_log:
      # do nothing
      jmp .logging_done

    log_request:
      # log format `Request: HOST_IP - - [DATE:TIME] "METHOD ROUTE (USER_AGENT)" \n`
      #? MAY REPLACE WITH pushw operation

      # we need \0 so we can search for the begin of the string
      # Write to stack '\0Request: '
      pushw $'\0'
      pushw $'R'
      pushw $'e'
      pushw $'q'
      pushw $'u'
      pushw $'e'
      pushw $'s'
      pushw $'t'
      pushw $':'
      pushw $' '

      leal Request_Host_Header, %eax          # Create pointer to the first string we are searching for
      leal SCOM_User_Server_Request, %ebx     # Create pointer to the text we are searching in
      movl $6, %ecx                           # length of word we are searching for
      call String_Search_Word                 # search for word

      cmpl $0, %eax                           # check if we did find the Host ip
      je .invallid_ip_proc                    # if not we say the host was invallid
      .valid_str_loop:                        # loop writes the ip to the log if we did find something
      inc %ebx                                # increment the ip so we are looking at the ip and other vals
      pushw (%ebx)                            # push ip diget to stack
      cmpl $'\n', (%ebx)                      # check if we are end of string
      je .ip_assign_loop_done                 # jump to the assign loop end if we are at the end of the ip
      jne .valid_str_loop                     # go back to begin of loop if we are not at the ip end
      .invallid_ip_proc:
      # Write to stack 'Bad_Ip: ' if we did not get a valid ip
      pushw $'B'
      pushw $'a'
      pushw $'d'
      pushw $'_'
      pushw $'I'
      pushw $'P'
      .ip_assign_loop_done:

      # assign to stack " - - ["
      pushw $' '
      pushw $'-'
      pushw $' '
      pushw $'-'
      pushw $' '
      pushw $'['

      call get_unix_sec                       # get the current unix time

      pushl %eax                              # temp copy unix time to stack
      call get_current_year                   # get the current year
      leal SCOM_IntStr_Convert_Results, %edi  # link the string copy result buffer to %edi
      call IntToString                        # convert the resulted year to a string
      popl %ebx                               # remove the unix time from the stack to prevent corruption
      pushw 0(%edi)                           # push the year-str to the stack
      pushw 1(%edi)                           # push the year-str to the stack
      pushw 2(%edi)                           # push the year-str to the stack
      pushw 3(%edi)                           # push the year-str to the stack
      movl %edi, %eax                         # move the resulted buffer to %eax
      call Clear_SCOM                         # clear the resulted buffer
      movl %ebx, %eax                         # move the unix time back to the %eax to continue

      pushw $'-'                              # push log seperator to the stack

      pushl %eax                              # temp copy unix time to stack
      call get_current_month                  # get the current month
      leal SCOM_IntStr_Convert_Results, %edi  # link the string copy result buffer to %edi
      call IntToString                        # convert the resulted month to a string
      popl %ecx                               # remove the unix time from the stack to prevent corruption
      pushw 0(%edi)                           # push the first non-corrupt diget to the stack
      cmpl $0, 1(%edi)                        # check if next char is end of month-str
      je .no_second_month_diget               # jump if not second diget
      pushw 1(%edi)                           # if yes: push char into the stack
      .no_second_month_diget:                 # label to jump to if there is no second diget
      movl %edi, %eax                         # move the resulted buffer to %eax
      call Clear_SCOM                         # clear the resulted buffer
      movl %ecx, %eax                         # move the unix time back to the %eax to continue

      pushw $'-'                              # push log seperator to the stack

      pushl %eax                              # temp copy unix time to stack
      call get_current_day                    # get the current day
      leal SCOM_IntStr_Convert_Results, %edi  # link the string copy result buffer to %edi
      call IntToString                        # convert the resulted day to a string
      popl %ecx                               # remove the unix time from the stack to prevent corruption
      pushw 0(%edi)                           # push the first non-corrupt diget to the stack
      cmpl $0, 1(%edi)                        # check if next char is end of month-str
      je .no_second_day_diget                 # jump if not second diget
      pushw 1(%edi)                           # if yes: push char into the stack
      .no_second_day_diget:                   # label to jump to if there is no second diget
      movl %edi, %eax                         # move the resulted buffer to %eax
      call Clear_SCOM                         # clear the resulted buffer
      movl %ecx, %eax                         # move the unix time back to the %eax to continue

      pushw $' '                              # push log seperator to the stack

      pushl %eax                              # temp copy unix time to stack
      call get_current_hour                   # get the current hour
      leal SCOM_IntStr_Convert_Results, %edi  # link the string copy result buffer to %edi
      call IntToString                        # convert the resulted day to a string
      popl %ecx                               # remove the unix time from the stack to prevent corruption
      pushw 0(%edi)                           # push the first non-corrupt diget to the stack
      cmpl $0, 1(%edi)                        # check if next char is end of month-str
      je .no_second_hour_diget                # jump if not second diget
      pushw 1(%edi)                           # if yes: push char into the stack
      .no_second_hour_diget:                  # label to jump to if there is no second diget
      movl %edi, %eax                         # move the resulted buffer to %eax
      call Clear_SCOM                         # clear the resulted buffer
      movl %ecx, %eax                         # move the unix time back to the %eax to continue

      pushw $':'                              # push log seperator to the stack

      call get_current_minute                 # get the current minute
      leal SCOM_IntStr_Convert_Results, %edi  # link the string copy result buffer to %edi
      call IntToString                        # convert the resulted day to a string
      pushw 0(%edi)                           # push the first non-corrupt diget to the stack
      cmpl $0, 1(%edi)                        # check if next char is end of month-str
      je .no_second_minute_diget              # jump if not second diget
      pushw 1(%edi)                           # if yes: push char into the stack
      .no_second_minute_diget:                # label to jump to if there is no second diget
      cmovel %ebx, %esp                       # if no: reset the stack pointer to its previous state
      movl %edi, %eax                         # move the resulted buffer to %eax
      call Clear_SCOM                         # clear the resulted buffer

      # push log seperators to the stack
      pushw $']'
      pushw $' '

      leal SCOM_User_Server_Request, %edi     # move the request string into edi
      movl 1(%edi), %eax                      # get the first char of the request body because it holds the method
      cmpl $'G', %eax                         # check if its G meaning GET request
      je .write_get_to_log                    # go to the write get method to log if we found it
      cmpl $'P', %eax                         # check if its P meaning POST request
      je .write_post_to_log                   # go to the write post method to the log if we found it

      # write ??? which means it was a unrocognized or disallowed request
      pushw $'?'
      pushw $'?'
      pushw $'?'

      jmp .end_of_method_write                # jump over the other log writes so no corruption happens
      .write_get_to_log:                      # start of write GET procedure

      # write GET if its a get request
      pushw $'G'
      pushw $'E'
      pushw $'T'

      jmp .end_of_method_write                # jump over the other log writes so no corruption happens
      .write_post_to_log:                     # start of write POST procedure

      # write POST if its a post request
      pushw $'P'
      pushw $'O'
      pushw $'S'
      pushw $'T'

      .end_of_method_write:                   # end of write method logic is here
      pushw $' '                              # move a seperator to the log

      .search_route_loop:                     # start loop to search for the beginning of the route
      inc %edi                                # increment the pointer to keep searching
      cmpl $'/', (%edi)                       # check if we found the route
      jne .search_route_loop                  # if we still not on the route we jump back
      .insert_to_log_loop:                    # start of write route loop
      pushw (%edi)                            # write the route to the stack
      inc %edi                                # increment the pointer
      cmpl $' ', (%edi)                       # check if we hit the end of the route
      jne .insert_to_log_loop                 # jump back if not

      pushw $' '                              # add log seperator

      # start searching for the user-agent
      leal Request_User_Agent_Header, %eax    # Create pointer to the first string we are searching for
      leal SCOM_User_Server_Request, %ebx     # Create pointer to the text we are searching in
      movl $12, %ecx                          # length of word we are searching for
      call String_Search_Word                 # search for word

      movl %ebx, %edi                         # move the found string to the string get register
      .not_found_end_of_ua:                   # start of get user-agent loop
      pushw (%edi)                            # push user agent char to the stack
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

      #? POSSIBLE BAD LOG DUE TO PUSHW
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
      #? MAY REPLACE WITH pushw operation
      pushw $'\0'
      pushw $'D'
      pushw $'a'
      pushw $'t'
      pushw $'a'
      pushw $'b'
      pushw $'a'
      pushw $'s'
      pushw $'e'
      pushw $':'
      pushw $' '

      jmp *database_action_log_table(,%ebx,4)

      database_action_log_table:
        .long invallid_databaselog    # (0) log: database is invallid
        .long write_databaselog       # (1) log: database is writing
        .long read_databaselog        # (2) log: database is reading

      invallid_databaselog:
        # log message that database log is invallid
        pushw $'I'
        pushw $'N'
        pushw $'V'
        pushw $'A'
        pushw $'L'
        pushw $'\n'

        call nstandard_console_write
        call Write_File_Log
        jmp .logged_svr_msg
      write_databaselog:
        # log if we are writing
        pushw $'W'
        pushw $'R'
        pushw $'I'
        pushw $'T'
        pushw $'E'
        pushw $' '

        #? DO LATER GRAB FROM SCOM MEMORY

        call nstandard_console_write
        call Write_File_Log
        jmp .logged_svr_msg
      read_databaselog:
        # log if we are reading
        pushw $'R'
        pushw $'E'
        pushw $'A'
        pushw $'D'
        pushw $' '

        #? DO LATER GRAB FROM SCOM MEMORY

        call nstandard_console_write
        call Write_File_Log
        jmp .logged_svr_msg

      jmp .logging_done

    log_server_event:
      # log format `Server: EVENT - - MESSAGE \n`

      jmp *server_log_action_table(,%ebx,4)   # jump to the location the id is pointing at

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
          movl $Log_Server_Status_BADLGID_ERR, %eax
          call Write_File_Log
          jmp .logged_svr_msg
        init_servermsg:
          # Server: Info - - Initializing server
          movl $Log_Server_Status_Initializing, %eax
          call nstandard_console_write
          movl $Log_Server_Status_Initializing, %eax
          call Write_File_Log
          jmp .logged_svr_msg
        socket_createdmsg:
          # Server: Info - - Socket has been created
          movl $Log_Server_Status_Created_System_Socket, %eax
          call nstandard_console_write
          movl $Log_Server_Status_Created_System_Socket, %eax
          call Write_File_Log
          jmp .logged_svr_msg
        socket_configmsg:
          # Server: Info - - Socket has been configured
          movl $Log_Server_Status_Configured_System_Socket, %eax
          call nstandard_console_write
          movl $Log_Server_Status_Configured_System_Socket, %eax
          call Write_File_Log
          jmp .logged_svr_msg
        socket_initmsg:
          # Server: Info - - Socket has been Initialized...
          movl $Log_Server_Status_Initialized_server_socket, %eax
          call nstandard_console_write
          movl $Log_Server_Status_Initialized_server_socket, %eax
          call Write_File_Log
          jmp .logged_svr_msg
        socket_listeningmsg:
          # Server: Info - - Socket now listening onto port 7870
          movl $Log_Server_Status_now_listening, %eax
          call nstandard_console_write
          movl $Log_Server_Status_now_listening, %eax
          call Write_File_Log
          jmp .logged_svr_msg
        database_connectingdbmsg:
          # Server: Info - - Database is currently connecting
          movl $Log_Server_Status_database_connecting, %eax
          call nstandard_console_write
          movl $Log_Server_Status_database_connecting, %eax
          call Write_File_Log
          jmp .logged_svr_msg
        database_connectedmsg:
          # Server: Info - - Database is now connected!
          movl $Log_Server_Status_database_Connected, %eax
          call nstandard_console_write
          movl $Log_Server_Status_database_Connected, %eax
          call Write_File_Log
          jmp .logged_svr_msg
        database_disconnected:
          # Server: Info - - Database has been disconnected
          movl $Log_Server_Status_database_disconnected, %eax
          call nstandard_console_write
          movl $Log_Server_Status_database_disconnected, %eax
          call Write_File_Log
          jmp .logged_svr_msg
        logger_has_been_initialized:
          # Server: Info - - Logger has been Initialized
          movl $Log_Server_Status_logger_initialized, %eax
          call nstandard_console_write
          movl $Log_Server_Status_logger_initialized, %eax
          call Write_File_Log
          jmp .logged_svr_msg
        server_standard_exit:
          # Server: Info - - Server is currently shutting down..
          movl $Log_Serrver_Status_Shutdown, %eax
          call nstandard_console_write
          movl $Log_Serrver_Status_Shutdown, %eax
          call Write_File_Log
          jmp .logged_svr_msg
        server_bailout_sockererr:
          # Server: Error - - Bad socket creation. Exiting server.
          movl $Log_Serrver_Status_Err_BadSock, %eax
          call nstandard_console_write
          movl $Log_Serrver_Status_Err_BadSock, %eax
          call Write_File_Log
          jmp .logged_svr_msg
        server_bailout_sockconferr:
          # Server: Error - - Bad config. Exiting Server.
          movl $Log_Serrver_Status_Err_BadConf, %eax
          call nstandard_console_write
          movl $Log_Serrver_Status_Err_BadConf, %eax
          call Write_File_Log
          jmp .logged_svr_msg
        server_bailout_sockiniterr:
          # Server: Error - - Bad socket initialization. Exiting..
          movl $Log_Serrver_Status_Err_BadInit, %eax
          call nstandard_console_write
          movl $Log_Serrver_Status_Err_BadInit, %eax
          call Write_File_Log
          jmp .logged_svr_msg
        server_bailout_badsvr:
          # Server: Error - - Bad server or listener. Exiting..
          movl $Log_Serrver_Status_Err_BadList, %eax
          call nstandard_console_write
          movl $Log_Serrver_Status_Err_BadList, %eax
          call Write_File_Log
          jmp .logged_svr_msg
        server_bailout_bad_generic:
          # Server: Error - - Bad or inval init. Exiting...
          movl $Log_Serrver_Status_Err_BadSvrInit, %eax
          call nstandard_console_write
          movl $Log_Serrver_Status_Err_BadSvrInit, %eax
          call Write_File_Log
          jmp .logged_svr_msg
        server_bailout_bailout:
          # Server: Error - - Uncat Error Flagged. Exiting..
          movl $Log_Serrver_Status_Err_Unkown_Error, %eax
          call nstandard_console_write
          movl $Log_Serrver_Status_Err_Unkown_Error, %eax
          call Write_File_Log
          jmp .logged_svr_msg
        server_developer_exit:
          # Server: Error - - Devexitt
          movl $Log_Serrver_Status_Err_Developer_Exit, %eax
          call nstandard_console_write
          movl $Log_Serrver_Status_Err_Developer_Exit, %eax
          call Write_File_Log
          jmp .logged_svr_msg

      .logged_svr_msg:                        # universal endpoint for all logged messages
      jmp .logging_done

    .logging_done:
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
    .asciz "Server: Info - - Server is currently shutting down.. \n"
  Log_Serrver_Status_Err_BadSock:
    .asciz "Server: Error - - Bad socket creation. Exiting server. \n"
  Log_Serrver_Status_Err_BadConf:
    .asciz "Server: Error - - Bad config. Exiting Server. \n"
  Log_Serrver_Status_Err_BadInit:
    .asciz "Server: Error - - Bad socket initialization. Exiting.. \n"
  Log_Serrver_Status_Err_BadList:
    .asciz "Server: Error - - Bad server or listener. Exiting.. \n"
  Log_Serrver_Status_Err_BadSvrInit:
    .asciz "Server: Error - - Bad or inval init. Exiting... \n"
  Log_Serrver_Status_Err_Unkown_Error:
    .asciz "Server: Error - - Uncat Error Flagged. Exiting.. \n"
  Log_Serrver_Status_Err_Developer_Exit:
    .asciz "Server: Error - - Devexitt \n"
