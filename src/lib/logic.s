.global standard_exit

.section .text
  # PROGRAM_EXIT: EXITS THE PROGRAM WITH STANDARD NO-ERROR EXIT CODE
  # PARAM: (EAX) THE EXIT CODE THE PROGRAM LEAVES AT
  # OVERWRITES: EBX, EAX
  program_exit:
    pushl %eax
    movl $10, $LogEventTypeID       # move logid 10 into the 2nd param of the log notifier
    movl $3, $LogEventCode          # trigger the logger so we're telling the server owner we're exiting the server

    movl $4, $LogEventCode          # move code 4 into the logger thread so we can tell it to stop now

    pushl $0                        # push 0 to stack as temp needed for wait4

    movl $114, %eax                 # move syscall id 114 sys_wait4 to %eax
    movl $-1, %ebx                  # move -1 so we wait for all threads
    movl %esp, %ecx                 # move the stack ptr to the val value to 2nd param
    movl $1, %edx                   # move 1 into the 3rd param aka default settings
    movl $0, %esi                   # move NULL to the 4th param as we dont need the struct

    movl $1, %eax                   # move 1 into %EBX so syscall (exit) can be called
    popl %ebx                       # 0 moved into $EBX to set a return code
    int $0x80                       # call the exit syscall. Program will exit here after

  # PROGRAM_EXIT_SOCKET: EXITS THE PROGRAM WITH ERROR EXIT CODE OF 2 WHICH MEANS SOCKET CREATION ERROR
  # OVERWRITES: EBX, EAX
  program_exit_socket:
    # trigger exit log
    movl $11, $LogEventTypeID
    movl $3, $LogEventCode

    movl $2, %eax                   # 2 moved into $EAX to set a exit code
    call program_exit               # trigger standard exit

  program_exit_opterr:
    # trigger exit log
    movl $12, $LogEventTypeID
    movl $3, $LogEventCode

    movl $3, %eax                   # 3 moved into $EAX to set a exit code
    call program_exit               # trigger standard exit

  program_exit_binderr:
    # trigger exit log
    movl $13, $LogEventTypeID
    movl $3, $LogEventCode

    movl $4, %eax                   # 4 moved into $EAX to set a exit code
    call program_exit               # trigger standard exit

  program_exit_servererr:
    # trigger exit log
    movl $14, $LogEventTypeID
    movl $3, $LogEventCode

    movl $5, %eax                   # 5 moved into $EAX to set a exit code
    call program_exit               # trigger standard exit

  program_exit_initerr:
    # trigger exit log
    movl $15, $LogEventTypeID
    movl $3, $LogEventCode

    movl $6, %eax                   # 5 moved into $EAX to set a exit code
    call program_exit               # trigger standard exit

  bailout_handler:
    # trigger exit log
    movl $16, $LogEventTypeID
    movl $3, $LogEventCode

    movl $1, %eax                   # 5 moved into $EAX to set a exit code
    call program_exit               # trigger standard exit

  dev_exit_handler:
    # trigger exit log
    movl $17, $LogEventTypeID
    movl $3, $LogEventCode

    movl $7, %eax                   # 5 moved into $EAX to set a exit code
    call program_exit               # trigger standard exit
