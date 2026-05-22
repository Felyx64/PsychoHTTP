.global _start

.section .data
  Init_Message:
    .asciz "Initializing server...\n"

  Server_Creation_Message:
    .asciz "Server Socket in krnl Created... \n"

  Server_Configuration_Message:
    .asciz "Server Socket in krnl Configured... \n"

  Server_Initialization_Message:
    .asciz "Server Socket in krnl Initialized... \n"

.section .data
  .global bailout_handler
  .type exit_handler, @function

  exit_handler:
    mov $1, %eax                              # move 1 into %EAX to call syscall (exit)
    mov $99, %ebx                             # exit with code 99 (bailout)
    int $0x80                                 # trigger (exit) syscall itself

.section .text
  _start:
    # setup bailout handler so abnormal terminations are handled
    # SIGSEGV - segmentation fault
    movl $48, %eax                            # assign 48 to %EAX for the signal syscall so we can greacefully exit when this error happens
    movl $11, %ebx                            # move the signal $11 SIGSEGV into the 2nd param
    leal bailout_handler, %ecx                # move the bailout function into the 3rd param
    int $0x80                                 # trigger the syscall

    # SIGABRT - abort signal
    movl $48, %eax                            # assign 48 to %EAX for the signal syscall so we can greacefully exit when this error happens
    movl $6, %ebx                             # move the signal $6 SIGABRT into the 2nd param
    leal bailout_handler, %ecx                # move the bailout function into the 3rd param
    int $0x80                                 # trigger the syscall

    # SIGTERM - termination signal
    movl $48, %eax                            # assign 48 to %EAX for the signal syscall so we can greacefully exit when this error happens
    movl $15, %ebx                            # move the signal $15 SIGTERM into the 2nd param
    leal bailout_handler, %ecx                # move the bailout function into the 3rd param
    int $0x80                                 # trigger the syscall

    # check if assigns went well
    cmpl $-1, %eax                            # check if the signal assigns went correctly
    je program_exit_initerr                   # if they didn't shut down the server pramuterly

    # show initilization message
    movl $Init_Message, %ecx                  # Move The initialization Message into %ECX
    call standard_console_write               # Engage the write to console from the lib/iostream file

    # start the server itself
    call create_uninitialized_server          # Call function that registers the server in the OS via syscall (socket)
    cmpl $-1, %eax                            # check if the function returned an error
    je program_exit_socket                    # Jump to program exit if the function returned an error

    pushl %eax                                # Push %eax to stack so we dont need to deal with it in RAM

    # show socket creation message
    movl $Server_Creation_Message, %ecx       # Move The Server socket creation Message into %ECX
    call standard_console_write               # Engage the write to console from the lib/iostream file

    movl (%esp), %ebx                         # move server fd into %ebx as needed for the setsockopt syscall

    # configure the server settings
    call configure_server                     # Call function that configures the server's behaviour itself before its assigned a port and ip. Via Syscall (setsockopt)
    cmpl $-1, %eax                            # check if the function returned an error
    je program_exit_opterr                    # Jump to program exit if the function returned an error

    #? ADD EXTRA CONFIGS LIKE (SO_REUSEPORT)

    # show socket configuration message
    movl $Server_Configuration_Message, %ecx  # Move The Server socket configuration Message into %ECX
    call standard_console_write               # Engage the write to console from the lib/iostream file

    # initialize server config struct here
    subl  $16, %esp                           # Creates a stack allocation of 16 needed for this struct
    movw  $2, (%esp)                          # moves 2 (AF_INET) into the struct which tells again that the server is ipv4
    movw  $0x391E, 2(%esp)                    # moves `Big-Edian` version of number 7870 into the struct so htons is not required
    movl  $0x0100007F, 4(%esp)                # moves `Big-Edian` version of current adress im reading of 127.0.0.1 into the struct so htons is not required

    movl 16(%esp), %ebx                       # move server fd into %ebx as needed for the setsockopt syscall
    movl %esp, %ecx                           # Create a pointer to the stack memory %ESP is pointer to in %ECX so (bind) can read the struct that was created

    # initialize the server
    call initialialize_server                 # Call function that binds the server port and ip to it. Via Syscall (bind)
    cmpl $-1, %eax                            # check if the function returned an error
    je program_exit_binderr                   # Jump to program exit if the function returned an error

    # show socket initialization message
    movl $Server_Initialization_Message, %ecx # Move The Server socket configuration Message into %ECX
    call standard_console_write               # Engage the write to console from the lib/iostream file

    # tell the server to start listening on port 7870
    movl 16(%esp), %ebx                       # get server fd from stack as 1st param for server
    call start_server                         # starts the server itself on port 7870
    cmpl $-1, %eax                            # check if the function returned an error
    je program_exit_servererr                 # Jump to program exit if the function returned an error

    movl $0, %ecx                             # mov 0 into the %R8D register which acts as a shutdown signal
    pushl %ecx                                # pushes the checker if loop is done to stack. Ignore the error

    #? DEV
    call dev_exit_handler
    # i pushed server-fd to stack (REMEMBER THAT!!)


    # http server handling done here

    .server_loop:                             # start the loop where we check for requests to the server

    #? fix r8d and swap for other
    cmpl $1, (%esp)                           # check the shutdown signal
    je .start_shutdown_process                # jump to the shutdown server if we did get a signal
    jmp .server_loop                          # jump back the the start of the loop if there we have not gotten a signal yet
    .start_shutdown_process:                  # label we need to jump to if we need to shutdown the server

    call program_exit


# here goes server utils
.include "/home/f65/Documents/proj/PsychoHTTP/src/server/create.s"
.include "/home/f65/Documents/proj/PsychoHTTP/src/server/configure.s"
.include "/home/f65/Documents/proj/PsychoHTTP/src/server/listen.s"

# lib goes in bottom
.include "/home/f65/Documents/proj/PsychoHTTP/src/lib/iostream.s"
.include "/home/f65/Documents/proj/PsychoHTTP/src/lib/logic.s"

# BIND ERRORS
# EACCES	You tried to bind to a protected port (<1024) without being root.
# EADDRINUSE	Another process is already using this port, or it's in TIME_WAIT.
# EBADF	sockfd is not a valid file descriptor.
# EINVAL	The socket is already bound to an address.
