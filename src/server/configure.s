.section .text
  # CONFIGURE_SERVER: CONFIGURES THE SERVER BEFORE ITS BEEN ASSIGNED ITS ADDRESS VIA SYSCALL (setsockopt)
  # OVERWRITES: EAX, ECX, EDX, ESI, EDI
  # RETURNS: (EAX) EXIT CODE OF THE OPERATION
configure_server:
    # SET CONFIG SO_REUSEADDR
    movl $366, %eax                         # move 366 which is syscall id of (setsockopt) into EAX for for the syscall
    # servers_fd is not being moved into %EBX as it should be already inside EBX
    movl $1, %ecx                           #******************* move 1 aka (SOL_SOCKET) into %ECX register
    movl $2, %edx                           #******************* move 2 aka (SO_REUSEADDR) to the %EDX Register
    orl $15, %edx                           #******************* SO_REUSEADDR | SO_REUSEPORT
    movl $1, %esi                           #******************* int opt
    movl $4, %edi                           #******************* sizeof int opt
    int $0x80                               # call the (setsockopt) syscall

    cmpl $0, %eax                           # checks if bind action has returned an error or not
    je .configuration_succesfull            # if no error then jump to the creation done flag
    call kill_server_instance               # gets rid of the server instance in the system before exiting

    # check for errors on %RAX
    # errors can be found here: https:#pubs.opengroup.org/onlinepubs/009695099/functions/setsockopt.html

    .configuration_succesfull:
    ret

    # INITIALIALIZE_SERVER: SET THE SERVERS REQUIRED ADRESS INFO VIA SYSCALL (bind)
    # OVERWRITES: EAX, ESP, ECX, EDX
    # RETURNS: (EAX) EXIT CODE OF THE OPERATION
  initialialize_server:
    call create__sockaddr_in__struct        # create a stack memory struct of sockaddr_in

    movl $361, %eax                         # move 361 which is syscall id of (bind) into EAX for for the syscall
    # servers_fd is not being moved into %EBX as it should be already inside EBX
    leal (%esp), %ecx                       # Create a pointer to the stack memory %ESP is pointer to in %ECX so (bind) can read the struct that was created
    movl $16, %edx                          # pass in the size of the struct into the last parameter which is %EDX
    int $0x80                               # call the (bind) syscall

    call clear__sockaddr_in__struct         # clear the sockaddr_in struct from the stack

    cmpl $0, %eax                           # checks if bind action has returned an error or not
    je .bind_succesfull                     # if no error then jump to the creation done flag
    call deconfig_server_and_rest           # gets rid of the server instance in the system before exiting

    # check for errors on %RAX
    # errors can be found here: https:#pubs.opengroup.org/onlinepubs/009695099/functions/bind.html

    .bind_succesfull:
    ret
