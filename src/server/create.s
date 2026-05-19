.section .data
  EafNoSupport_Err_Msg:
    .ascii "Socket_Error: Kernel does not support this socket config.\n"
    .set EafNoSupport_Err_Msg_Len, . - EafNoSupport_Err_Msg

  EMFile_Err_Msg:
    .ascii "Too many allowed fd's :\ \n"
    .set EMFile_Err_Msg_Len, . - EMFile_Err_Msg

  EAcess_Err_Msg:
    .ascii "Privelages error. Dangerous Creation on SOCK_RAW not allowed! \n"
    .set EAcess_Err_Msg_Len, . - EAcess_Err_Msg

  Unkown_Err_Msg:
    .ascii "Server Failure! Cannot make SOCK. UnkownERR \n"
    .set Unkown_Err_Msg_Len, . - Unkown_Err_Msg

.section .text
  # CREATE_UNINITIALIZED_SERVER: CREATES AND RETURNS AN FD TO A SOCK AKA A DORMENT SERVER INSTANCE IN OUR CASE
  # OVERWRITES: EAX, EBX, ECX, EDX
  # RETURNS: (EAX) FD TOWARDS THE UNIITIALIZED SERVER ITSELF, -1 = SERVER FAILED TO CREATE
  create_uninitialized_server:
    # create un-init server
    movl $359, %eax               # Move Syscall number into EAX Register (socket)
    movl $2, %ebx                 # 2 aka (AF_INET) moved into %EBX which tells the server should be ipv4
    movl $1, %ecx                 # 1 aka (SOCK_STREAM) moved into %ECX tells the server should be TCP
    movl $0, %edx                 # 0 aka (dafeault protocol) moved into %EDX. Tells that the SOCK_STREAM in %ECX is the default
    int $0x80                     # execute the (socket) syscall itself

    # check if there no error
    cmpl $0, %eax                 # checks if socket creation has returned an error or not
    jnl .server_creation_done     # if no error then jump to the creation done flag

    neg %eax                      # make the number in %EAX positive if it is an error so it can be analyzed

    # Checks for errors here:

    # check for error: EAFNOSUPPORT
    cmpl $97, %eax
    jne .not_eafnosupport_error
    movl $EafNoSupport_Err_Msg, %ecx
    movl $EafNoSupport_Err_Msg_Len, %edx
    call systemcall_console_write
    movl $-1, %eax
    jmp .server_creation_done

    .not_eafnosupport_error:
    # check for error EMFILE
    cmpl $24, %eax
    jne .not_emfile_error
    movl $EMFile_Err_Msg, %ecx
    movl $EMFile_Err_Msg_Len, %edx
    call systemcall_console_write
    movl $-1, %eax
    jmp .server_creation_done

    .not_emfile_error:
    # check for error EACCES
    cmpl $13, %eax
    jne .unkown_error
    movl $EAcess_Err_Msg, %ecx
    movl $EAcess_Err_Msg_Len, %edx
    call systemcall_console_write
    movl $-1, %eax
    jmp .server_creation_done

    .unkown_error:
    # report unkown error with SOCK
    movl $Unkown_Err_Msg, %ecx
    movl $Unkown_Err_Msg_Len, %edx
    call systemcall_console_write
    movl $-1, %eax

    # stops here if server creation is done
    .server_creation_done:
    ret
