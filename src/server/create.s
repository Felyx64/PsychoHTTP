.section .text
  # CREATE_UNINITIALIZED_SERVER: CREATES AND RETURNS AN FD TO A SOCK AKA A DORMENT SERVER INSTANCE IN OUR CASE
  # OVERWRITES: EAX, EBX, ECX, EDX
  # RETURNS: (EAX) FD TOWARDS THE UNIITIALIZED SERVER ITSELF, -1 = SERVER FAILED TO CREATE
  create_uninitialized_server:
    # create un-init server
    movl $359, %eax                  # Move Syscall number into EAX Register (socket)
    movl $2, %ebx                    # 2 aka (AF_INET) moved into %EBX which tells the server should be ipv4
    movl $1, %ecx                    # 1 aka (SOCK_STREAM) moved into %ECX tells the server should be TCP
    movl $0, %edx                    # 0 aka (dafeault protocol) moved into %EDX. Tells that the SOCK_STREAM in %ECX is the default
    int $0x80                        # execute the (socket) syscall itself

    # check if there no error
    cmpl $0, %eax                    # checks if socket creation has returned an error or not
    jnl .server_creation_done        # if no error then jump to the creation done flag

    movl $-1, %eax                   # move -1 into %EAX signaling an error

    # stops here if server creation is done
    .server_creation_done:
    ret
