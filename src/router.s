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

  TempResponseDisallowedObj:
    .asciz "HTTP/1.1 403 OK\r\nContent-Type: text/html\r\n\r\n<h1>You are forbidded for entering this website!</h1>"
  TempResponseDisallowedObjLen = . - TempResponseDisallowedObj - 1

  TempResponseErrorObj:
    .asciz "HTTP/1.1 500 OK\r\nContent-Type: text/html\r\n\r\n<h1>An error occured!</h1>"
  TempResponseErrorObjLen = . - TempResponseErrorObj - 1

.section .bss
  RequestTimeSetterMemory:
    .space 256

.section .data
  Response_Line_Starter_And_Terminator:
    .asciz "\r\n"

  Disallowed_Route_Response:
    .ascii "HTTP/1.1 403 FORBIDDEN\r\n"
    .ascii "Content-Type: text/html\r\n"
    .ascii "Server: SpookyFunnyAssemblyServer :3\r\n"
    .ascii "Allow: GET\r\n"
    .ascii "Connection: close\r\n"
    .ascii "Transfer-Encoding: chunked\r\n"
    .asciz "Date: "

.section .text
  # PARAM ($EAX) THE SERVER ROUTE CODE
  # PARAM ($EBX) PTR TO SERVER CONFIG
  # PARAM ($ECX) SERVER-FD
  RouteRequest:
    subl $2, %eax                                   # subtract 2 from %eax or else the switch wont work
    jmp *response_table(,%eax,4)                    # jump to the adress which this number correlates to on the adress table (this is the switch statement)

    response_table:                                 # this is the adress table for the switch statement
      .long is_get_root                             # if code 2 (root) this adress will be jumped to
      .long is_get_styles                           # if code 3 (styles) this adress will be jumped to
      .long is_post_posts                           # if code 4 (post) this adress will be jumped to
      .long is_posts_uploadpost                     # if code 5 (upload) this adress will be jumped to
      .long is_disallowed_request                   # if code 6 (disallowed) this adress will be jumped to

  is_get_root:
    call Handle_Root_Route_Request
    jmp .end_sendout_res
  is_get_styles:
    call Handle_Styles_Route_Request
    jmp .end_sendout_res
  is_post_posts:
    pushl %edi
    pushl %ecx
    leal SCOM_User_Server_Request, %eax               # link the requuest to $eax
    call RunToEndOfReqHeader                          # move req ptr to req content
    call Extract_From_Get_Post_Json
    call QueryMultipleItems
    cmpl $0, %eax
    je .no_db_items

    call Handle_GetPost_Route_Request                 # handle the non-empty db and make the response here

    movl %eax, %edx                                   # move response message to %ecx
    movl %ebx, %ecx                                   # move the response length into %edx
    popl %ebx                                         # move server-fd into the 2nd param
    popl %edi                                         # move server config into edi param
    movl $369, %eax                                   # move syscall code (sendto) into %eax
    movl $16, %ebp                                    # move the server config into last param
    int $0x80                                         # call syscall 369 (sendto)

    jmp .end_sendout_res

    .no_db_items:
    popl %ebx                                         # move server-fd into the 2nd param
    popl %edi                                         # move server config into edi param
    movl $369, %eax                                   # move syscall code (sendto) into %eax
    movl $16, %ebp                                    # move the server config into last param
    movl $TempResponsePostObj, %ecx                   # move response message to %ecx
    movl $TempResponsePostObjLen, %edx                # move the response length into %edx
    int $0x80                                         # call syscall 369 (sendto)

    jmp .end_sendout_res
  is_posts_uploadpost:
    call Handle_UploadPost_Route_Request
    jmp .end_sendout_res
  is_disallowed_request:
    movl %ebx, %edi                             # move server config into edi param
    movl %ecx, %ebx                             # move server-fd into the 2nd param
    movl $369, %eax                             # move syscall code (sendto) into %eax
    movl $16, %ebp                              # move the server config into last param
    movl $TempResponseDisallowedObj, %ecx       # move response message to %ecx
    movl $TempResponseDisallowedObjLen, %edx    # move the response length into %edx
    int $0x80                                   # call syscall 369 (sendto)

    .end_sendout_res:

    ret

# ADD MULTITHREAD VIA THIS
.ifdef __RELEASE__MODE__

.else

.endif
