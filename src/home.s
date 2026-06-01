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

  Server_Listen_Message:
    .asciz "Server Socket now listening onto port 7870 \n"

.section .data
  .global bailout_handler
  .type exit_handler, @function

  exit_handler:
    mov $1, %eax                              # move 1 into %EAX to call syscall (exit)
    mov $99, %ebx                             # exit with code 99 (bailout)
    int $0x80                                 # trigger (exit) syscall itself

.section .text
  _start:
    # create the SA_RESTART handler struct required for the coming syscall. struct is C struct "struct sigaction"
    # coming syscall will make it that the listiners for new requests will not auto-fail once we start the listening
    pushl $0                                  # set sa_restorer struct member to NULL
    pushl $0x10000000                         # set sa_flags struct member to SA_RESTART aka 0x1000000
    pushl $0                                  # set sa_mask struct member to 0. this basically acts as sigemptyset on the member
    pushl $1                                  # set sa_handler struct member to 1 aka SIG_IGN

    # trigger syscall (sigaction)
    movl $67, %eax                            # move the syscall code into the %eax register
    movl $28, %ebx                            # move $28 aka SIGWINCH into %ebx register
    movl %esp, %ecx                           # move the struct to the ecx register
    movl $0, %edx                             # move NULL into the last parameter
    int $0x80                                 # trigger syscall

    addl $16, %esp                            # clear up the struct from the stack so the program can continue

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
    movl $Init_Message, %eax                  # Move The initialization Message into %ECX
    call nstandard_console_write              # Engage the write to console from the lib/iostream file

    # start the server itself
    call create_uninitialized_server          # Call function that registers the server in the OS via syscall (socket)
    cmpl $-1, %eax                            # check if the function returned an error
    je program_exit_socket                    # Jump to program exit if the function returned an error

    pushl %eax                                # Push %eax to stack so we dont need to deal with it in RAM

    # show socket creation message
    movl $Server_Creation_Message, %eax       # Move The Server socket creation Message into %ECX
    call nstandard_console_write              # Engage the write to console from the lib/iostream file

    movl (%esp), %ebx                         # move server fd into %ebx as needed for the setsockopt syscall

    # configure the server settings
    call configure_server                     # Call function that configures the server's behaviour itself before its assigned a port and ip. Via Syscall (setsockopt)
    cmpl $-1, %eax                            # check if the function returned an error
    je program_exit_opterr                    # Jump to program exit if the function returned an error

    #? ADD EXTRA CONFIGS LIKE (SO_REUSEPORT)

    # show socket configuration message
    movl $Server_Configuration_Message, %eax  # Move The Server socket configuration Message into %ECX
    call nstandard_console_write              # Engage the write to console from the lib/iostream file

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
    movl $Server_Initialization_Message, %eax # Move The Server socket configuration Message into %ECX
    call nstandard_console_write              # Engage the write to console from the lib/iostream file

    # tell the server to start listening on port 7870
    movl 16(%esp), %eax                       # get server fd from stack as 1st param for server
    call start_server                         # starts the server itself on port 7870
    cmpl $-1, %eax                            # check if the function returned an error
    je program_exit_servererr                 # Jump to program exit if the function returned an error

    movl $0, %ecx                             # mov 0 into the %R8D register which acts as a shutdown signal
    pushl %ecx                                # pushes the checker if loop is done to stack. Ignore the error

    movl $Server_Listen_Message, %eax         # Move the Error to print into the %ECX parameter
    call nstandard_console_write              # call the console write procedure


    # http server handling done here

    .server_loop:                             # start the loop where we check for requests to the server
    cmpl $1, %esp                             # check the shutdown signal
    je .start_shutdown_process                # jump to the shutdown server if we did get a signal

    movl 20(%esp), %eax                       # get server fd from stack as 1st param for the request
    leal 4(%esp), %ebx                        # get the server config from the stack as second paramater
    call Handle_Request

    call Handle_Response

    jmp .server_loop                          # jump back the the start of the loop if there we have not gotten a signal yet
    .start_shutdown_process:                  # label we need to jump to if we need to shutdown the server

    call program_exit

# handlers imported here
.include "/home/f65/Documents/proj/PsychoHTTP/src/middleware/middleware.s"
.include "/home/f65/Documents/proj/PsychoHTTP/src/parse/request.s"

# server imported here
.include "/home/f65/Documents/proj/PsychoHTTP/src/server/request.s"
.include "/home/f65/Documents/proj/PsychoHTTP/src/server/response.s"
.include "/home/f65/Documents/proj/PsychoHTTP/src/server/create.s"
.include "/home/f65/Documents/proj/PsychoHTTP/src/server/configure.s"
.include "/home/f65/Documents/proj/PsychoHTTP/src/server/listen.s"

# lib goes in bottom
.include "/home/f65/Documents/proj/PsychoHTTP/src/lib/iostream.s"
.include "/home/f65/Documents/proj/PsychoHTTP/src/lib/logic.s"
