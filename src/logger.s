.section .bss
  StringLogMemory:
    .space 1024

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

      leal StringLogMemory, %edi

      # Write to logstack 'Request: '
      movb $'R', (%edi)
      inc %edi
      movb $'e', (%edi)
      inc %edi
      movb $'q', (%edi)
      inc %edi
      movb $'u', (%edi)
      inc %edi
      movb $'e', (%edi)
      inc %edi
      movb $'s', (%edi)
      inc %edi
      movb $'t', (%edi)
      inc %edi
      movb $':', (%edi)
      inc %edi
      movb $' ', (%edi)
      inc %edi

      pushl %edi                              # temp backup log-stackptr
      leal Request_Host_Header, %eax          # Create pointer to the first string we are searching for
      leal SCOM_User_Server_Request, %ebx     # Create pointer to the text we are searching in
      movl $6, %ecx                           # length of word we are searching for
      call String_Search_Word                 # search for word
      popl %edi                               # bring back log-stackptr

      cmpl $0, %eax                           # check if we did find the Host ip
      je .invallid_ip_proc                    # if not we say the host was invallid
      inc %ebx                                # increment the ip so we are looking at the ip and other vals
      .valid_str_loop:                        # loop writes the ip to the log if we did find something
      movb (%ebx), %al
      cmpb $10, %al
      je .ip_assign_loop_done
      cmpb $13, %al
      je .ip_assign_loop_done
      movb %al, (%edi)
      inc %edi
      inc %ebx
      jmp .valid_str_loop                     # go back to begin of loop if we are not at the ip end
      .invallid_ip_proc:
      # Write to stack 'Bad_Ip: ' if we did not get a valid ip
      movb $'B', (%edi)
      inc %edi
      movb $'a', (%edi)
      inc %edi
      movb $'d', (%edi)
      inc %edi
      movb $'_', (%edi)
      inc %edi
      movb $'I', (%edi)
      inc %edi
      movb $'P', (%edi)
      inc %edi
      .ip_assign_loop_done:

      # assign to stack " - - ["
      movb $' ', (%edi)
      inc %edi
      movb $'-', (%edi)
      inc %edi
      movb $' ', (%edi)
      inc %edi
      movb $'-', (%edi)
      inc %edi
      movb $' ', (%edi)
      inc %edi
      movb $'[', (%edi)
      inc %edi

      call get_unix_sec                       # get the current unix time

      movl %eax, %ebx                         # temp put in in the adress of the unix time in $ebx
      movl (%ebx), %eax                       # deferenace the $ebx pointer back into $eax

      pushl %eax                              # push the unix time to stack as temp
      pushl %edi
      call get_current_year                   # get the current year
      pushl %eax                              # temp push year to the stack
      leal TimeMakerMemory, %edi              # link the timer memory to the %edi 2nd parameter
      call IntToString                        # convert the resulted year to a string

      popl %eax                               # temp get back the year for %edi extraction
      popl %edi
      pushl %eax                              # push back the current year
      leal TimeMakerMemory, %eax

      movb (%eax), %bl
      movb %bl, (%edi)
      inc %edi
      movb $0, (%eax)
      inc %eax

      movb (%eax), %bl
      movb %bl, (%edi)
      inc %edi
      movb $0, (%eax)
      inc %eax

      movb (%eax), %bl
      movb %bl, (%edi)
      inc %edi
      movb $0, (%eax)
      inc %eax

      movb (%eax), %bl
      movb %bl, (%edi)
      inc %edi
      movb $0, (%eax)
      inc %eax

      popl %ebx                               # get the current year
      pushl %ebx                              # copy and push back to stack
      movl %ebx, %eax                         # move the year into the leap_year check param
      call check_leap_year                    # check if it is a leap year
      movl %eax, %ecx                         # move the leap year info to the correct daymonth param
      popl %ebx                               # get the current year (again)
      popl %eax                               # take back the unix time for the month getter

      movl $'-', (%edi)
      inc %edi

      pushl %eax                              # backup the unix time again
      call get_current_daymonth               # get current month and day of year
      pushl %eax                              # push back day for later
      movl %edi, %esi
      movl %ebx, %edi
      call String_Plot                        # put month on log
      movl %esi, %edi

      movl $'-', (%edi)
      inc %edi

      popl %eax                               # put day on the log around this section
      pushl %edi
      leal TimeMakerMemory, %edi
      cmpl $10, %eax                          # check if signle diget
      jnae .single_diget_stringify
      call IntToString
      jmp .done_day_stringification
      .single_diget_stringify:
      addl $0x30, %eax
      movb %al, (%edi)
      inc %edi
      movb $0, (%edi)
      .done_day_stringification:

      popl %esi
      leal TimeMakerMemory, %edi
      call String_Plot
      movl %esi, %edi

      movl $' ', (%edi)
      inc %edi

      popl %eax                               # take the unix time back from the backup
      pushl %eax                              # backup the unix time for the so-many'th time

      call get_current_hour                   # get current hour of the day

      # convert the hour we got to string and plot it onto the log
      cmpl $10, %eax
      jl .lower_hour
      xorl %edx, %edx
      movl $10, %ebx
      div %ebx
      addl $0x30, %eax
      movb %al, (%edi)
      inc %edi
      addl $0x30, %edx
      movb %dl, (%edi)
      inc %edi
      jmp .assigned_hour
      .lower_hour:
      movb $0x30, (%edi)                      # 0x30 = just 0 in ascii, not to be confusted with \0
      inc %edi
      addl $0x30, %eax
      movb %al, (%edi)
      inc %edi
      .assigned_hour:

      movl $':', (%edi)
      inc %edi

      popl %eax
      call get_current_minute                 # get the current minute of the day

      # convert the minute we got to string and plot it onto the log
      cmpl $10, %eax
      jl .lower_minute
      xorl %edx, %edx
      movl $10, %ebx
      div %ebx
      addl $0x30, %eax
      movb %al, (%edi)
      inc %edi
      addl $0x30, %edx
      movb %dl, (%edi)
      inc %edi
      jmp .assigned_minute
      .lower_minute:
      movb $0x30, (%edi)                      # 0x30 = just 0 in ascii, not to be confusted with \0
      inc %edi
      addl $0x30, %eax
      movb %al, (%edi)
      inc %edi
      .assigned_minute:

      # push log seperators to the stack
      movb $']', (%edi)
      inc %edi
      movb $' ', (%edi)
      inc %edi

      leal SCOM_User_Server_Request, %ebx     # move the request string into edi
      movb (%ebx), %al                        # move the first param of method into %al
      cmpb $'G', %al                          # check if its G meaning GET request
      je .write_get_to_log                    # go to the write get method to log if we found it
      cmpb $'P', %al                          # check if its P meaning POST request
      je .write_post_to_log                   # go to the write post method to the log if we found it

      # write ??? which means it was a unrocognized or disallowed request
      movb $'?', (%edi)
      inc %edi
      movb $'?', (%edi)
      inc %edi
      movb $'?', (%edi)
      inc %edi

      jmp .end_of_method_write                # jump over the other log writes so no corruption happens
      .write_get_to_log:                      # start of write GET procedure

      # write GET if its a get request
      movb $'G', (%edi)
      inc %edi
      movb $'E', (%edi)
      inc %edi
      movb $'T', (%edi)
      inc %edi

      jmp .end_of_method_write                # jump over the other log writes so no corruption happens
      .write_post_to_log:                     # start of write POST procedure

      # write POST if its a post request
      movb $'P', (%edi)
      inc %edi
      movb $'O', (%edi)
      inc %edi
      movb $'S', (%edi)
      inc %edi
      movb $'T', (%edi)
      inc %edi

      .end_of_method_write:                   # end of write method logic is here

      # move a seperator to the log
      movb $' ', (%edi)
      inc %edi

      .search_route_loop:                     # start loop to search for the beginning of the route
      inc %ebx                                # increment the pointer to keep searching
      cmpb $'/', (%ebx)                       # check if we found the route
      jne .search_route_loop                  # if we still not on the route we jump back
      .insert_to_log_loop:                    # start of write route loop
      # write the route to the stack
      movb (%ebx), %al
      movb %al, (%edi)
      inc %edi
      inc %ebx                                # increment the pointer
      cmpb $' ', (%ebx)                       # check if we hit the end of the route
      jne .insert_to_log_loop                 # jump back if not

      # add log seperator
      movb $' ', (%edi)
      inc %edi

      pushl %edi

      # start searching for the user-agent
      leal Request_User_Agent_Header, %eax    # Create pointer to the first string we are searching for
      leal SCOM_User_Server_Request, %ebx     # Create pointer to the text we are searching in
      movl $12, %ecx                          # length of word we are searching for
      call String_Search_Word                 # search for word

      popl %edi

      inc %ebx
      .not_found_end_of_ua:                   # start of get user-agent loop
      movb (%ebx), %al
      cmpb $10, %al
      je .end_of_ua_getter_loop
      cmpb $13, %al
      je .end_of_ua_getter_loop
      movb %al, (%edi)
      inc %edi
      inc %ebx
      jmp .not_found_end_of_ua
      .end_of_ua_getter_loop:

      # and terminate the string we made
      movb $0x0, (%edi)
      leal StringLogMemory, %eax
      call nstandard_console_write            # log the request log to the console

      # write log to file
      leal StringLogMemory, %eax              # move the pointer to %eax so we can start logging to the logfile
      call Write_File_Log                     # log the request to the log file

      # clear the string we where logging
      leal StringLogMemory, %eax
      call Clear_SCOM

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
