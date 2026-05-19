.global main

.section .data
  Init_Message:
    .ascii "Initializing server...\n"
    .set Init_Message_len, . - Init_Message

.section .data
  .global bailout_handler
  .type exit_handler, @function

  exit_handler:
    mov $1, %eax                      # move 1 into %EAX to call syscall (exit)
    mov $99, %ebx                     # exit with code 99 (bailout)
    int $0x80                         # trigger (exit) syscall itself

.section .text
  main:
    # setup bailout handler so abnormal terminations are handled
    # SIGSEGV - segmentation fault
    movl $48, %eax                    # assign 48 to %EAX for the signal syscall so we can greacefully exit when this error happens
    movl $11, %ebx                    # move the signal $11 SIGSEGV into the 2nd param
    leal bailout_handler, %ecx        # move the bailout function into the 3rd param
    int $0x80                         # trigger the syscall

    # SIGABRT - abort signal
    movl $48, %eax                    # assign 48 to %EAX for the signal syscall so we can greacefully exit when this error happens
    movl $6, %ebx                     # move the signal $6 SIGABRT into the 2nd param
    leal bailout_handler, %ecx        # move the bailout function into the 3rd param
    int $0x80                         # trigger the syscall

    # SIGTERM - termination signal
    movl $48, %eax                    # assign 48 to %EAX for the signal syscall so we can greacefully exit when this error happens
    movl $15, %ebx                    # move the signal $15 SIGTERM into the 2nd param
    leal bailout_handler, %ecx        # move the bailout function into the 3rd param
    int $0x80                         # trigger the syscall

    #? DEV
    call bailout_handler

    # check if assigns went well
    cmpl $-1, %eax                    # check if the signal assigns went correctly
    je program_exit_initerr           # if they didn't shut down the server pramuterly

    # show initilization message
    movl $Init_Message, %ecx          # Move The initialization Message into %ECX
    call standard_console_write       # Engage the write to console from the lib/iostream file

    # start the server itself
    call create_uninitialized_server  # Call function that registers the server in the OS via syscall (socket)
    cmpl $-1, %eax                    # check if the function returned an error
    je program_exit_socket            # Jump to program exit if the function returned an error

    movl %eax, %ebx                   # Move Server_fd to %EBX due to %EAX Having to be used for syscalls

    # initialize struct here

    # configure the server settings
    call configure_server             # Call function that configures the server's behaviour itself before its assigned a port and ip. Via Syscall (setsockopt)
    cmpl $-1, %eax                    # check if the function returned an error
    je program_exit_opterr            # Jump to program exit if the function returned an error

    # initialize the server
    call initialialize_server         # Call function that binds the server port and ip to it. Via Syscall (bind)
    cmpl $-1, %eax                    # check if the function returned an error
    je program_exit_binderr           # Jump to program exit if the function returned an error

    # tell the server to start listening on port 7870
    call start_server                 # starts the server itself on port 7870
    cmpl $-1, %eax                    # check if the function returned an error
    je program_exit_servererr         # Jump to program exit if the function returned an error

    movl $0, %ecx                     # mov 0 into the %R8D register which acts as a shutdown signal
    pushl %ecx                        # pushes the checker if loop is done to stack. Ignore the error

    # http server handling done here

    .server_loop:                     # start the loop where we check for requests to the server

    #? fix r8d and swap for other
    cmpl $1, (%esp)                   # check the shutdown signal
    je .start_shutdown_process        # jump to the shutdown server if we did get a signal
    jmp .server_loop                  # jump back the the start of the loop if there we have not gotten a signal yet
    .start_shutdown_process:          # label we need to jump to if we need to shutdown the server

    call program_exit


# here goes server utils
.include "/home/f65/Documents/proj/PsychoHTTP/src/server/create.s"
.include "/home/f65/Documents/proj/PsychoHTTP/src/server/configure.s"
.include "/home/f65/Documents/proj/PsychoHTTP/src/server/listen.s"

# lib goes in bottom
.include "/home/f65/Documents/proj/PsychoHTTP/src/lib/iostream.s"
.include "/home/f65/Documents/proj/PsychoHTTP/src/lib/logic.s"
.include "/home/f65/Documents/proj/PsychoHTTP/src/lib/struct.s"

# BIND ERRORS
# EACCES	You tried to bind to a protected port (<1024) without being root.
# EADDRINUSE	Another process is already using this port, or it's in TIME_WAIT.
# EBADF	sockfd is not a valid file descriptor.
# EINVAL	The socket is already bound to an address.
