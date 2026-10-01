.global _start

.section .data
  .type exit_handler, @function

  exit_handler:
    call DisconnectDB                         # disconnect the fd if we're shutting down the server

    movl $1, %ebx                             # move the message id to the 2ndlog param
    movl $8, %eax                             # move the id into the 1st log param
    call Log_Message                          # trigger the logger

    movl $1, %ebx                             # move the message id to the 2ndlog param
    movl $3, %eax                             # move the id into the 1st log param
    call Log_Message                          # trigger the logger

.section .text
  _start:
    movl $0, %eax                             # move code 1 saying we need the filter folder
    call Read_File_Standard                   # call the read file operation

    leal SCOM_File_Read_Results, %eax         # link scom result to %eax
    leal GSCOM_Server_Filter, %ebx            # link global filter scom to %ebx
    call Copy_SCOM                            # copy and paste scom results to the Global filter scom

    leal SCOM_File_Read_Results, %eax         # link the scom results again to %eax
    call Clear_SCOM                           # clear the scom

    call Initialize_Filter_Language           # Initialze the server filter

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
    movl $1, %ebx                             # move the message id to the 2ndlog param
    movl $3, %eax                             # move the id into the 1st log param
    call Log_Message                          # trigger the logger

    # show message saying we're initializing the database
    movl $6, %ebx                             # move the message id to the 2ndlog param
    movl $3, %eax                             # move the id into the 1st log param
    call Log_Message                          # trigger the logger

    call ConnectDB                            # initialize the database fd
    cmpl $-1, %eax                            # check for error
    je exit_handler                           # jump if bad fd creation

    movl $7, %ebx                             # move the message id to the 2ndlog param
    movl $3, %eax                             # move the id into the 1st log param
    call Log_Message                          # trigger the logger

    # start the server itself
    call create_uninitialized_server          # Call function that registers the server in the OS via syscall (socket)
    cmpl $-1, %eax                            # check if the function returned an error
    je program_exit_socket                    # Jump to program exit if the function returned an error

    pushl %eax                                # Push %eax to stack so we dont need to deal with it in RAM

    # show socket creation message
    movl $2, %ebx                             # move the message id to the 2nd log param
    movl $3, %eax                             # move the id into the 1st log param
    call Log_Message                          # trigger the logger

    movl (%esp), %ebx                         # move server fd into %ebx as needed for the setsockopt syscall

    # configure the server settings
    call configure_server                     # Call function that configures the server's behaviour itself before its assigned a port and ip. Via Syscall (setsockopt)
    cmpl $-1, %eax                            # check if the function returned an error
    je program_exit_opterr                    # Jump to program exit if the function returned an error

    # show socket configuration message
    movl $3, %ebx                             # move the message id to the 2nd log param
    movl $3, %eax                             # move the id into the 1st log param
    call Log_Message                          # trigger the logger

    # initialize server config struct here
    subl  $16, %esp                           # Creates a stack allocation of 16 needed for this struct
    movw  $2, (%esp)                          # moves 2 (AF_INET) into the struct which tells again that the server is ipv4
    movw  $0xBE1E, 2(%esp)                    # moves `Big-Edian` version of number 7870 into the struct so htons is not required
    movl  $0x0100007F, 4(%esp)                # moves `Big-Edian` version of current adress im reading of 127.0.0.1 into the struct so htons is not required

    movl 16(%esp), %ebx                       # move server fd into %ebx as needed for the setsockopt syscall
    movl %esp, %ecx                           # Create a pointer to the stack memory %ESP is pointer to in %ECX so (bind) can read the struct that was created

    # initialize the server
    call initialialize_server                 # Call function that binds the server port and ip to it. Via Syscall (bind)
    cmpl $-1, %eax                            # check if the function returned an error
    je program_exit_binderr                   # Jump to program exit if the function returned an error

    # show socket initialization message
    movl $4, %ebx                             # move the message id to the 2nd log param
    movl $3, %eax                             # move the id into the 1st log param
    call Log_Message                          # trigger the logger

    # tell the server to start listening on port 7870
    movl 16(%esp), %eax                       # get server fd from stack as 1st param for server
    call start_server                         # starts the server itself on port 7870
    cmpl $-1, %eax                            # check if the function returned an error
    je program_exit_servererr                 # Jump to program exit if the function returned an error

    movl $0, %ecx                             # mov 0 into the %ECX register which acts as a shutdown signal
    pushl %ecx                                # pushes the checker if loop is done to stack. Ignore the error

    movl $5, %ebx                             # move the message id to the 2nd log param
    movl $3, %eax                             # move the id into the 1st log param
    call Log_Message                          # trigger the logger

    # http server handling done here

    .server_loop:                             # start the loop where we check for requests to the server
    cmpl $1, (%esp)                           # check the shutdown signal
    je .start_shutdown_process                # jump to the shutdown server if we did get a signal

    movl 20(%esp), %eax                       # get server fd from stack as 1st param for the request
    call Handle_Request                       # wait for the request and handle stuff here

    # push back from here until no longer needed
    pushl %eax

    call Analyze_Request                      # call a function that analyses what the host is asking

    pushl %eax                                # temp backup the routecode
    movl $1, %eax                             # move the id into the 1st log param
    call Log_Message                          # trigger the logger
    popl %eax                                 # get back the routecode

    cmpl $1, %eax                             # compare if the route getter return 1 meaning its not a valid request
    jne .no_get_routeerr                      # if it is valid we check what type of request it was
    popl %ebx                                 # move connection fd into the %ebx second param
    leal 4(%esp), %edi                        # move server config into edi param
    movl $369, %eax                           # move syscall code (sendto) into %eax
    movl $16, %ebp                            # move the server config size into last param
    movl $ResponseDisallowedObj, %ecx          # move response message to %ecx
    movl $ResponseDisallowedObjLen, %edx       # move the response length into %edx
    int $0x80                                 # call syscall 369 (sendto)
    jmp .close_req                            # jump over switch to close the request

    .no_get_routeerr:                         # label to jump to if we had no bad request

    pushl %eax                                # temp backup the routecode
    call Filter_Request                       # filter the request to check if its allowed

    cmpl $0, %eax                             # look what the filter said about the request
    je .request_allowed                       # jump it request is allowed
    movl $8, %eax                             # move 8 which will become 6 if request was not allowed
    addl $4, %esp                             # lower the stack pointer to invalidate the routecode
    jmp .do_route
    .request_allowed:                         # label to jump to if request is allowed

    popl %eax                                 # get back the routecode
    .do_route:
    popl %ecx                                 # move connection fd into the %ebx second param

    call RouteRequest

    .close_req:

    movl $373, %eax                           # move syscall code (373) to $eax
    movl $2, %ecx                             # move SHUT_RDWR into the 2nd param of the syscall
    # $ebx is already set
    int $0x80                                 # call syscall (shutdown)

    movl $6, %eax                             # move syscall code (6) close to %eax
    # $ebx is already set
    int $0x80                                 # call syscall (close)

    jmp .server_loop                          # jump back the the start of the loop if there we have not gotten a signal yet
    .start_shutdown_process:                  # label we need to jump to if we need to shutdown the server

    movl $0, %eax                             # move 0 into %eax so we dont return with exit code >1
    call program_exit                         # exit the server

# server router goes here
.include "./../src/routes/root.s"
.include "./../src/routes/styles.s"
.include "./../src/routes/upload_post.s"
.include "./../src/routes/get_post.s"

# importing some response assisting code here
.include "./../src/default_router_builder.s"

# server logger goes here
.include "./../src/logger.s"

# database utils go here
.include "./../src/db/actions.s"
.include "./../src/db/connection.s"
.include "./../src/db/utility.s"

# middleware goes here
.include "./../src/middleware/filter_request.s"

# router logic imported here
.include "./../src/routecode_getter.s"
.include "./../src/router.s"

# server imported here
.include "./../src/server/request.s"
.include "./../src/server/create.s"
.include "./../src/server/configure.s"
.include "./../src/server/listen.s"

# interpreters go here
.include "./../src/interpreter/filter_language.s"
.include "./../src/interpreter/json.s"

# lib goes in near bottom
.include "./../src/lib/iostream.s"
.include "./../src/lib/string.s"
.include "./../src/lib/fsio.s"
.include "./../src/lib/exit.s"
.include "./../src/lib/time.s"

# scom goes in bottom as its globally accessed
.include "./../src/scom.s"
