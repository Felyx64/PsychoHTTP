.section .bss
    LoggerMemory:
      .space 4096

    LogEventCode:
      .long 0

    SharedEventLogMemory:
      .long 0
      .long 0

.set CLONE_FLAGS, (0x00000100 | 17)

.section .text
  Initialize_Server_Logger:
    # NEED FLAG 0x00000100 aka CLONE_VM for the event process
    movl $120, %eax                       # move the syscall sys_clone code into %eax
    movl $CLONE_FLAGS, %ebx               # move the syscall flags in second param %ebx
    movl $LoggerMemory, %ecx              # give our logging thread some stack memory
    addl $4096, %ecx                      # move the stack pointer back to the end
    int $0x80                             # create new thread with syscall
    cmpl $0, %eax                         # do some checking so that main thread can get out of the way of the 2nd thread's business
    jne  .initializtion_done              # jump out of the function if we are the main thread
    .start_logger_thread:                 # 2nd thread starts here

    # logger operates here as an event driven engine
    # so events are handled and checked for in this loop

    # add sleep until not 0

    leal LogEventCode, %eax   # initialize shared main-log thread event memory
    jmp *log_action_table(,(%eax),4)      # switch over the value stored in %eax to check if we need to log something

    log_action_table:                     # table of functions which we can jump to once the event listiner gets woken up
      .long invallid_log
      .long log_request                   # log format `Request: HOST_IP - - [DATE:TIME] "METHOD ROUTE (USER_AGENT)" \n`
      .long log_database                  # log format `Database: ACTION - - AMOUNT bytes \n`
      .long log_server_event              # log format `Server: EVENT - - MESSAGE \n`

    invallid_log:
      # do nothing
      jmp .start_logger_thread

    log_request:
      # log format `Request: HOST_IP - - [DATE:TIME] "METHOD ROUTE (USER_AGENT)" \n`
      #? MAY REPLACE WITH PUSHB operation

      pushl %esp                            # push the current stack cordinates to the stack so we know where to reset to

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

      leal Request_Host_Header, %eax        # Create pointer to the first string we are searching for
      leal SCOM_User_Server_Request, %ebx   # Create pointer to the text we are searching in
      movl $6, %ecx                         # length of word we are searching for
      call String_Search_Word               # search for word

      cmpl $0, %eax                         # check if we did find the Host ip
      je .invallid_ip_proc                  # if not we say the host was invallid
      .valid_str_loop:                      # loop writes the ip to the log if we did find something
      inc %ebx                              # increment the ip so we are looking at the ip and other vals
      pushl (%ebx)                          # push ip diget to stack
      cmpl $'\n', (%ebx)                    # check if we are end of string
      je .ip_assign_loop_done               # jump to the assign loop end if we are at the end of the ip
      jne .valid_str_loop                   # go back to begin of loop if we are not at the ip end
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

      # get time and date

      jmp .start_logger_thread
    # request log done here


    jmp .start_logger_thread              # 2nd thread ends here but goes back to the start of the loop
    .initializtion_done:
    ret


    cmpl $0, %eax
    jne  .initializtion_done


# this file stores keywords we will be searching for in SCOM or other data during the logging process
.section .data
  Request_Host_Header:
    .ascii "Host: "

# 1. extract data from scom


# 2. get current time
# 3. log to console
# 4. log to log-file

# log user request
jmp .start_logger_thread
