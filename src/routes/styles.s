.section .data
  Styles_Route_Response:
    .ascii "HTTP/1.1 200 OK\r\n"
    .ascii "Content-Type: text/css\r\n"
    .ascii "Server: SpookyFunnyAssemblyServer :3"
    .ascii "Allow: GET\r\n"
    .ascii "Connection: close\r\n"
    .ascii "Transfer-Encoding: chunked\r\n"
    .asciz "Date: "

.section .text
  Handle_Styles_Route_Request:
    pushl %ecx
    pushl %ebx

    leal Styles_Route_Response, %eax
    movl $4, %ebx
    call build_response

    leal SCOM_Response_Creation_Table, %eax           # link start of res to %eax
    call Strlen                                       # get total length of response

    movl %eax, %edx                                   # move the response length into %edx
    movl %ebx, %ecx                                   # move response message to %ecx
    popl %edi                                         # move server config into edi param
    popl %ebx                                         # move server-fd into the 2nd param
    movl $369, %eax                                   # move syscall code (sendto) into %eax
    movl $16, %ebp                                    # move the server config into last param
    int $0x80                                         # call syscall 369 (sendto)

    pushl %ebx

    # clear the response object
    leal SCOM_Response_Creation_Table, %eax
    call Clear_SCOM_12288

    popl %ebx
    ret
