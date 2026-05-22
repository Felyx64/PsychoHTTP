.section .data
  EafNoSupport_Err_Msg:
    .asciz "Socket_Error: Kernel does not support this socket config.\n"

  EMFile_Err_Msg:
    .asciz "Socket_Error: Too many allowed fd's \n"

  EAcess_Err_Msg:
    .asciz "Privelages error. Dangerous Creation on SOCK_RAW not allowed! \n"

  Unkown_Err_Msg:
    .asciz "Server Failure! Cannot make SOCK. UnkownERR \n"

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

    neg %eax                         # make the number in %EAX positive if it is an error so it can be analyzed

    # Checks for errors here:

    cmpl $97, %eax                   # check for error: EAFNOSUPPORT
    jne .not_eafnosupport_error      # jump if not error "EAFNOSUPPORT"

    movl $EafNoSupport_Err_Msg, %ecx # Move the Error to print into the %ECX parameter
    call standard_console_write      # call the console write procedure
    movl $-1, %eax                   # move -1 into %EAX signaling an error
    jmp .server_creation_done        # jump to the end of the function

    .not_eafnosupport_error:
    cmpl $24, %eax                   # check for error: EMFILE
    jne .not_emfile_error            # jump if not error "EMFILE"

    movl $EMFile_Err_Msg, %ecx       # Move the Error to print into the %ECX parameter
    call standard_console_write      # call the console write procedure
    movl $-1, %eax                   # move -1 into %EAX signaling an error
    jmp .server_creation_done        # jump to the end of the function

    .not_emfile_error:
    cmpl $13, %eax                   # check for error: EACCES
    jne .unkown_error                # jump if not error "EACCES"

    movl $EAcess_Err_Msg, %ecx       # Move the Error to print into the %ECX parameter
    call standard_console_write      # call the console write procedure
    movl $-1, %eax                   # move -1 into %EAX signaling an error
    jmp .server_creation_done        # jump to the end of the function

    .unkown_error:
    movl $Unkown_Err_Msg, %ecx       # check for error: UNKNOWN
    call standard_console_write      # call the console write procedure
    movl $-1, %eax                   # move -1 into %EAX signaling an error

    # stops here if server creation is done
    .server_creation_done:
    ret
