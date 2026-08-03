.section .text
  # CONFIGURE_SERVER: CONFIGURES THE SERVER BEFORE ITS BEEN ASSIGNED ITS ADDRESS VIA SYSCALL (setsockopt)
  # OVERWRITES: EAX, ECX, EDX, ESI, EDI
  # PARAMETERS: (EBX): NEEDS TO CONTAIN SERVER FD
  # RETURNS: (EAX) EXIT CODE OF THE OPERATION
configure_server:
    movl $366, %eax                         # move 366 which is syscall id of (setsockopt) into EAX for for the syscall
    # server's fd is inside the %ebx register
    movl $1, %ecx                           # move 1 aka (SOL_SOCKET) into %ECX register.
    movl $2, %edx                           # move 2 aka (SO_REUSEADDR) to the %EDX Register
    pushl $1                                # push integer of value 1 to stack as needed for opt
    movl %esp, %esi                         # tell %esp to point to stack memory integer 1
    movl $4, %edi                           # Send the size of the opt paramater
    int $0x80                               # call the (setsockopt) syscall

    addl $4, %esp                           # clear the stack memory after syscall has been done

    cmpl $0, %eax                           # checks if bind action has returned an error or not
    je .configuration_succesfull            # if no error then jump to the creation done flag

    movl $-1, %eax                          # move -1 into %EAX signaling an error

    .configuration_succesfull:
    ret

    # INITIALIALIZE_SERVER: SET THE SERVERS REQUIRED ADRESS INFO VIA SYSCALL (bind)
    # OVERWRITES: EAX, ECX, EDX
    # PARAMETERS: (EBX): NEEDS TO CONTAIN SERVER FD
    # RETURNS: (EAX) EXIT CODE OF THE OPERATION
  initialialize_server:
    movl $361, %eax                         # move 361 which is syscall id of (bind) into EAX for for the syscall
    movl $16, %edx                          # pass in the size of the struct into the last parameter which is %EDX
    int $0x80                               # call the (bind) syscall

    cmpl $0, %eax                           # checks if bind action has returned an error or not
    je .bind_succesfull                     # if no error then jump to the creation done flag

    movl $-1, %eax                          # move -1 into %EAX signaling an error

    .bind_succesfull:
    ret
