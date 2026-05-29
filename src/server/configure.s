.section .data
  # configuration errors

  Edom_Err_Msg:
    .asciz "Configure Err: (Edom), Timeout is too big! \n"

  Einval_Err_Msg:
    .asciz "Configure Err: (Einval), Invallid configuration! \n"

  Eisconn_Err_Msg:
    .asciz "Configure Err: (Eisconn), Socket Already Connected! \n"

  Enoprotoopt_Err_Msg:
    .asciz "Configure Err: (Enoprotoopt), Option Not Supported by this protocol! \n"

  Enotsock_Err_Msg:
    .asciz "Configure Err: (Enotsock), Invallid Socket FD! \n"

  Enomen_Err_Msg:
    .asciz "Configure Err: (Enomem), Isuficient Memory! \n"

  EnoBufs_Err_Msg:
    .asciz "Configure Err: (EnoBufs), Isuficient Resources! \n"

  Unkown_Config_Err_Msg:
    .asciz "Configure Err: (?!?!), Unkown or undoc ERR! \n"

  Efault_Err_Msg:
    .asciz "Configure Err: (EFAULT), Bad Optval! \n"

  # initialize errors
  Unkown_Init_Err_Msg:
    .asciz "InitErr: (?!?!), Unkown or undoc ERR! \n"

.section .text
  # CONFIGURE_SERVER: CONFIGURES THE SERVER BEFORE ITS BEEN ASSIGNED ITS ADDRESS VIA SYSCALL (setsockopt)
  # OVERWRITES: EAX, ECX, EDX, ESI, EDI
  # PARAMETERS: (EBX): NEEDS TO CONTAIN SERVER FD
  # RETURNS: (EAX) EXIT CODE OF THE OPERATION
configure_server:
    # SET CONFIG SO_REUSEADDR
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

    neg %eax                                # make the number in %EAX positive if it is an error so it can be analyzed

    cmpl $33, %eax                          # check for error: EDOM
    jne .not_edom_error                     # jump if not error "EDOM"

    movl $Edom_Err_Msg, %ecx                # Move the Error to print into the %ECX parameter
    call standard_console_write             # call the console write procedure
    movl $-1, %eax                          # move -1 into %EAX signaling an error
    jmp .configuration_succesfull           # jump to the end of the function

    .not_edom_error:
    cmpl $22, %eax                          # check for error: EINVAL
    jne .not_einval_error                   # jump if not error "EINVAL"

    movl $Einval_Err_Msg, %ecx              # Move the Error to print into the %ECX parameter
    call standard_console_write             # call the console write procedure
    movl $-1, %eax                          # move -1 into %EAX signaling an error
    jmp .configuration_succesfull           # jump to the end of the function

    .not_einval_error:
    cmpl $106, %eax                         # check for error: EISCONN
    jne .not_eisconn_error                  # jump if not error "EISCONN"

    movl $Eisconn_Err_Msg, %ecx             # Move the Error to print into the %ECX parameter
    call standard_console_write             # call the console write procedure
    movl $-1, %eax                          # move -1 into %EAX signaling an error
    jmp .configuration_succesfull           # jump to the end of the function

    .not_eisconn_error:
    cmpl $92, %eax                          # check for error: ENOPROTOOPT
    jne .not_enoprotoopt_error              # jump if not error "ENOPROTOOPT"

    movl $Enoprotoopt_Err_Msg, %ecx             # Move the Error to print into the %ECX parameter
    call standard_console_write             # call the console write procedure
    movl $-1, %eax                          # move -1 into %EAX signaling an error
    jmp .configuration_succesfull           # jump to the end of the function

    .not_enoprotoopt_error:
    cmpl $88, %eax                          # check for error: ENOTSOCK
    jne .not_enotsock_error                 # jump if not error "ENOTSOCK"

    movl $Enotsock_Err_Msg, %ecx            # Move the Error to print into the %ECX parameter
    call standard_console_write             # call the console write procedure
    movl $-1, %eax                          # move -1 into %EAX signaling an error
    jmp .configuration_succesfull           # jump to the end of the function

    .not_enotsock_error:
    cmpl $12, %eax                          # check for error: ENOMEM
    jne .not_enomem_error                   # jump if not error "ENOMEM"

    movl $Enomen_Err_Msg, %ecx              # Move the Error to print into the %ECX parameter
    call standard_console_write             # call the console write procedure
    movl $-1, %eax                          # move -1 into %EAX signaling an error
    jmp .configuration_succesfull           # jump to the end of the function

    .not_enomem_error:
    cmpl $105, %eax                         # check for error: ENOBUFS
    jne .not_enobufs_error                  # jump if not error "ENOBUFS"

    movl $EnoBufs_Err_Msg, %ecx             # Move the Error to print into the %ECX parameter
    call standard_console_write             # call the console write procedure
    movl $-1, %eax                          # move -1 into %EAX signaling an error
    jmp .configuration_succesfull           # jump to the end of the function

    .not_enobufs_error:
    cmpl $14, %eax                         # check for error: EFAULT
    jne .not_efault_error                  # jump if not error "EFAULT"

    movl $Efault_Err_Msg, %ecx              # Move the Error to print into the %ECX parameter
    call standard_console_write             # call the console write procedure
    movl $-1, %eax                          # move -1 into %EAX signaling an error
    jmp .configuration_succesfull           # jump to the end of the function

    .not_efault_error:

    movl $Unkown_Config_Err_Msg, %ecx       # Move the Error to print into the %ECX parameter
    call standard_console_write             # call the console write procedure
    movl $-1, %eax                          # move -1 into %EAX signaling an error
    jmp .configuration_succesfull           # jump to the end of the function

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

    movl $Unkown_Init_Err_Msg, %ecx         # Move the Error to print into the %ECX parameter
    call standard_console_write             # call the console write procedure
    movl $-1, %eax                          # move -1 into %EAX signaling an error

    # check for errors on %EAX
    # errors can be found here: https:#pubs.opengroup.org/onlinepubs/009695099/functions/bind.html

    # BIND ERRORS
    # EACCES	You tried to bind to a protected port (<1024) without being root.
    # EADDRINUSE	Another process is already using this port, or it's in TIME_WAIT.
    # EBADF	sockfd is not a valid file descriptor.
    # EINVAL	The socket is already bound to an address.


    .bind_succesfull:
    ret
