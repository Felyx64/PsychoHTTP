.global standard_exit

.section .text
  # PROGRAM_EXIT: EXITS THE PROGRAM WITH STANDARD NO-ERROR EXIT CODE
  # OVERWRITES: EBX, EAX
  program_exit:
    movl $1, %eax     # move 1 into %EBX so syscall (exit) can be called
    movl $0, %ebx     # 0 moved into $EBX to set a return code
    int $0x80         # call the exit syscall. Program will exit here after

  # PROGRAM_EXIT_SOCKERR: EXITS THE PROGRAM WITH ERROR EXIT CODE OF 2 WHICH MEANS SOCKET CREATION ERROR
  # OVERWRITES: EBX, EAX
  program_exit_socket:
    movl $1, %eax     # move 1 into %EBX so syscall (exit) can be called
    movl $2, %ebx     # 2 moved into $EBX to set a return code
    int $0x80         # call the exit syscall. Program will exit here after

  program_exit_opterr:
    movl $1, %eax     # move 1 into %EBX so syscall (exit) can be called
    movl $3, %ebx     # 3 moved into $EBX to set a return code
    int $0x80         # call the exit syscall. Program will exit here after

  program_exit_binderr:
    movl $1, %eax     # move 1 into %EBX so syscall (exit) can be called
    movl $4, %ebx     # 4 moved into $EBX to set a return code
    int $0x80         # call the exit syscall. Program will exit here after

  program_exit_servererr:
    movl $1, %eax     # move 1 into %EBX so syscall (exit) can be called
    movl $5, %ebx     # 5 moved into $EBX to set a return code
    int $0x80         # call the exit syscall. Program will exit here after

  program_exit_initerr:
    movl $1, %eax     # move 1 into %EBX so syscall (exit) can be called
    movl $6, %ebx     # 6 moved into $EBX to set a return code
    int $0x80         # call the exit syscall. Program will exit here after
