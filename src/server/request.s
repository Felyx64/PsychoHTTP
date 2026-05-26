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

    movl $Edom_Err_Msg, %ecx                # Move the Error to print into the %ECX parameter
    call standard_console_write             # call the console write procedure
    movl $-1, %eax                          # move -1 into %EAX signaling an error
    jmp .end_of_request_handler             # jump to end of request so program can be exited later there

    .no_request_error_found:                # continue from here if no error

    subl $1024, %esp                        # allocate the raw data which should contain the request
    movl %eax, %ebx                         # move the accept fd to its correct parameter
    movl $371, %eax                         # move the syscall code for (recvfrom) to %eax
    movl %ecx, %esi                         # move server config to %esi
    movl %esp, %ecx                         # move ptr to buffer to the %ecx register
    movl $1024, %edx                        # move the buffer size to edx
    subl $1, %edx                           # decrement the max size for memory safety
    shll $2, %edx                           # bitshift left 2 times so we have the correct 32-bit size
    pushl $1024                             # push size of the buffer to the stack
    movl %esp, %ebp                         # move the size ptr on the stack to the edp
    int $0x80                               # call syscall (recvfrom)

    addl $4, %esp                           # remove the size of request out of the stack

    cmpl $0, %eax                           # check if recv had an error
    jnl .no_recv_error_found                # jump over error handling if not

    # handle error here

    jmp .end_of_request_handler             # jump to end of request handler if error happened
    .no_recv_error_found:                   # label to jump to if there was no error

    movl %esp, %ecx                         # move the buffer to the $ecx register
    call standard_console_write             # printout the buffer

    # sendmsg
    movl $369, %eax                         # move syscall code 369 (sendmsg) to %eax
    # ebx already holds correct fd
    movl TempResponseObj, %ecx              # move the response str to %ecx
    movl TempResponseObjLen, %edx           # move leng of res to %edx
    movl $0, %edi                           # move the flag 0 to the %edi register
    # esi already set correctly which is the ptr to the server config
    pushl $16                               # push memory size indicator to the stack
    movl %esp, %ebp                         # move size of ptr to the memory size indicator to %ebp
    int $0x80                               # call syscall (sendmsg)

    addl $4, %esp                           # remove the config size indicator

    cmpl $0, %eax                           # check if sendmsg had an error
    jnl .no_sendmsg_error_found             # jump over error handling if not

    .no_sendmsg_error_found:                # jump here if no error

    movl $6, %eax                           # move syscall code (6) close to %eax
    # %ebx already set to correct param
    int $0x80                               # call syscall (close)

    .end_of_request_handler:                # request handler stops here
    ret
