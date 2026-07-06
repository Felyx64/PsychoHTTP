.section .data
  TempResponseRootObj:
    .asciz "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\n\r\n<h1>Root Request!</h1>"
  TempResponseRootObjLen = . - TempResponseRootObj - 1

  TempResponseStylesObj:
    .asciz "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\n\r\n<h1>Styles Request!</h1>"
  TempResponseStylesObjLen = . - TempResponseStylesObj - 1

  TempResponsePostObj:
    .asciz "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\n\r\n<h1>Post Request!</h1>"
  TempResponsePostObjLen = . - TempResponsePostObj - 1

  TempResponseUploadObj:
    .asciz "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\n\r\n<h1>Upload Request!</h1>"
  TempResponseUploadObjLen = . - TempResponseUploadObj - 1

  TempResponseErrorObj:
    .asciz "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\n\r\n<h1>Unkown Request!</h1>"
  TempResponseErrorObjLen = . - TempResponseErrorObj - 1

.section .text
  RouteRequest:
    subl $2, %eax                             # subtract 2 from %eax or else the switch wont work
    jmp *response_table(,%eax,4)              # jump to the adress which this number correlates to on the adress table (this is the switch statement)

    response_table:                           # this is the adress table for the switch statement
      .long is_get_root                       # if code 2 (root) this adress will be jumped to
      .long is_get_styles                     # if code 3 (styles) this adress will be jumped to
      .long is_get_posts                      # if code 4 (post) this adress will be jumped to
      .long is_posts_uploadpost               # if code 5 (upload) this adress will be jumped to

  is_get_root:
    leal 4(%esp), %edi                        # move server config into edi param
    movl $369, %eax                           # move syscall code (sendto) into %eax
    movl $16, %ebp                            # move the server config into last param
    movl $TempResponseRootObj, %ecx           # move response message to %ecx
    movl $TempResponseRootObjLen, %edx        # move the response length into %edx
    int $0x80                                 # call syscall 369 (sendto)

    jmp .end_sendout_res
  is_get_styles:
    leal 4(%esp), %edi                        # move server config into edi param
    movl $369, %eax                           # move syscall code (sendto) into %eax
    movl $16, %ebp                            # move the server config into last param
    movl $TempResponseStylesObj, %ecx         # move response message to %ecx
    movl $TempResponseStylesObjLen, %edx      # move the response length into %edx
    int $0x80                                 # call syscall 369 (sendto)

    jmp .end_sendout_res
  is_get_posts:
    leal 4(%esp), %edi                        # move server config into edi param
    movl $369, %eax                           # move syscall code (sendto) into %eax
    movl $16, %ebp                            # move the server config into last param
    movl $TempResponsePostObj, %ecx           # move response message to %ecx
    movl $TempResponsePostObjLen, %edx        # move the response length into %edx
    int $0x80                                 # call syscall 369 (sendto)

    jmp .end_sendout_res
  is_posts_uploadpost:
    leal 4(%esp), %edi                        # move server config into edi param
    movl $369, %eax                           # move syscall code (sendto) into %eax
    movl $16, %ebp                            # move the server config into last param
    movl $TempResponseUploadObj, %ecx         # move response message to %ecx
    movl $TempResponseUploadObjLen, %edx      # move the response length into %edx
    int $0x80                                 # call syscall 369 (sendto)

    .end_sendout_res:                         # this is always the end of the switch statement

    ret
