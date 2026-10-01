.section .text
  # PROGRAM_EXIT: EXITS THE PROGRAM WITH STANDARD NO-ERROR EXIT CODE
  # PARAM: (EAX) THE EXIT CODE THE PROGRAM LEAVES AT
  # OVERWRITES: EBX, EAX
  program_exit:
    pushl %eax

    movl $10, %ebx                  # move the message id to the 2nd log param
    movl $3, %eax                   # move the id into the 1st log param
    call Log_Message                # trigger the logger

    pushl $0                        # push 0 to stack as temp needed for wait4

    movl $114, %eax                 # move syscall id 114 sys_wait4 to %eax
    movl $-1, %ebx                  # move -1 so we wait for all threads
    movl %esp, %ecx                 # move the stack ptr to the val value to 2nd param
    movl $1, %edx                   # move 1 into the 3rd param aka default settings
    movl $0, %esi                   # move NULL to the 4th param as we dont need the struct

    inc %esp                        # remove the temp 0 from the stack needed for wait4

    movl $1, %eax                   # move 1 into %EBX so syscall (exit) can be called
    popl %ebx                       # 0 moved into $EBX to set a return code
    int $0x80                       # call the exit syscall. Program will exit here after

  # PROGRAM_EXIT_SOCKET: EXITS THE PROGRAM WITH ERROR EXIT CODE OF 2 WHICH MEANS SOCKET CREATION ERROR
  # OVERWRITES: EBX, EAX
  program_exit_socket:
    # trigger exit log
    movl $11, %ebx                  # move the message id to the 2nd log param
    movl $3, %eax                   # move the id into the 1st log param
    call Log_Message                # trigger the logger

    movl $2, %eax                   # 2 moved into $EAX to set a exit code
    call program_exit               # trigger standard exit

  program_exit_opterr:
    # trigger exit log
    movl $12, %ebx                  # move the message id to the 2nd log param
    movl $3, %eax                   # move the id into the 1st log param
    call Log_Message                # trigger the logger

    movl $3, %eax                   # 3 moved into $EAX to set a exit code
    call program_exit               # trigger standard exit

  program_exit_binderr:
    # trigger exit log
    movl $13, %ebx                  # move the message id to the 2nd log param
    movl $3, %eax                   # move the id into the 1st log param
    call Log_Message                # trigger the logger

    movl $4, %eax                   # 4 moved into $EAX to set a exit code
    call program_exit               # trigger standard exit

  program_exit_servererr:
    # trigger exit log
    movl $14, %ebx                  # move the message id to the 2nd log param
    movl $3, %eax                   # move the id into the 1st log param
    call Log_Message                # trigger the logger

    movl $5, %eax                   # 5 moved into $EAX to set a exit code
    call program_exit               # trigger standard exit

  program_exit_initerr:
    # trigger exit log
    movl $15, %ebx                  # move the message id to the 2nd log param
    movl $3, %eax                   # move the id into the 1st log param
    call Log_Message                # trigger the logger

    movl $6, %eax                   # 5 moved into $EAX to set a exit code
    call program_exit               # trigger standard exit

  bailout_handler:
    # trigger exit log
    movl $16, %ebx                  # move the message id to the 2nd log param
    movl $3, %eax                   # move the id into the 1st log param
    call Log_Message                # trigger the logger

    movl $1, %eax                   # 5 moved into $EAX to set a exit code
    call program_exit               # trigger standard exit

  dev_exit_handler:
    # trigger exit log
    movl $17, %ebx                  # move the message id to the 2nd log param
    movl $3, %eax                   # move the id into the 1st log param
    call Log_Message                # trigger the logger

    movl $7, %eax                   # 5 moved into $EAX to set a exit code
    call program_exit               # trigger standard exit
