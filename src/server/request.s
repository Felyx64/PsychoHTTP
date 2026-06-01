.global Handle_Request

.section .data
  TempResponseObj:
    .asciz "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\n\r\n<h1>Hello World!</h1>"
  TempResponseObjLen = . - TempResponseObj - 1

.section .text
  Handle_Request:
    movl %ebx, %ecx                         # move server config pointer to correctly allign function params
    movl %eax, %ebx                         # move server fd to coorectly allign function params
    movl $364, %eax                         # move 364 to the %eax so we can syscall (accept4)
    pushl $16                               # push size of server config to ram as required by coming syscall
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

    movl %ecx, %eax                         # temp move %ecx server config to %eax
    movl %esp, %ecx                         # move the buffer to the $ecx register
    pushl %ebx                              # push server fd to the stack as we have no registers to keep this inside
    pushl %eax                              # push server config to the stack as we have no registers to fit it in

    call standard_console_write             # printout the buffer

    popl %eax                               # move server config back into %edi as we need to for the next syscall
    popl %ebx                               # move server fd back into the %ebx register from the stack

    addl $1024, %esp                        # clear up the request from the stack

    movl %eax, %edi
    movl $369, %eax                         # move syscall code (sendto) into %eax
    movl $16, %ebp                          # move the server config into last param
    movl $TempResponseObj, %ecx             # move response message to %ecx
    movl $TempResponseObjLen, %edx          # move the response length into %edx
    int $0x80                               # call syscall 369 (sendto)

    cmpl $0, %eax                           # check if sendmsg had an error
    jnl .no_sendmsg_error_found             # jump over error handling if not

    .no_sendmsg_error_found:                # jump here if no error

    movl $6, %eax                           # move syscall code (6) close to %eax
    # %ebx already set to correct param
    int $0x80                               # call syscall (close)

    .end_of_request_handler:                # request handler stops here

    ret
