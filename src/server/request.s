.section .text
  Handle_Request:
    xorl %ecx, %ecx                         # leave server config params empty
    movl %eax, %ebx                         # move server fd to coorectly allign function params
    movl $364, %eax                         # move 364 to the %eax so we can syscall (accept4)
    pushl $0                                # push size 0 to ram
    movl %esp, %edx                         # create pointer in value to the stack data we just pushed %esp to edx
    movl $0, %esi                           # move 0 to the final flags paramater of syscall (accept4)
    int $0x80                               # call syscall accept4 itself

    addl $4, %esp                           # clear the stack memory after syscall has been done

    cmpl $0, %eax                           # check if there is an error with the request
    jnl .no_request_error_found             # jump if no error

    # handle error

    jmp .end_of_request_handler             # jump to end of request so program can be exited later there

    .no_request_error_found:                # continue from here if no error

    subl $1024, %esp                        # allocate the raw data which should contain the request
    movl %eax, %ebx                         # move the accept fd to its correct parameter
    movl $371, %eax                         # move the syscall code for (recvfrom) to %eax
    movl $0, %esi                           # move 0 into %edi so not extra args are used by the syscall
    movl %ecx, %edi                         # move server config to %edi
    movl %esp, %ecx                         # move ptr to buffer to the %ecx register
    movl $1024, %edx                        # move the buffer size to edx
    pushl $1024                             # push size of the buffer to the stack
    movl %esp, %ebp                         # move the size ptr on the stack to the ebp
    int $0x80                               # call syscall (recvfrom)

    addl $4, %esp                           # remove the size of request out of the stack

    cmpl $0, %eax                           # check if recv had an error
    jnl .no_recv_error_found                # jump over error handling if not

    # handle error here

    jmp .end_of_request_handler             # jump to end of request handler if error happened
    .no_recv_error_found:                   # label to jump to if there was no error

    movl %esp, %eax                         # move the stack pointer to the 1st param of strcpy
    pushl %ebx                              # push connection fd to the stack as we have no registers to keep this inside
    leal SCOM_User_Server_Request, %ebx     # move the scom temp data memory block into %ebx
    call String_Copy                        # copy stack data into SCOM memory

    popl %eax                               # move the connection fd back into the %eax return accumulator register

    addl $1024, %esp                        # clear up the request from the stack

    .end_of_request_handler:                # request handler stops here

    ret
