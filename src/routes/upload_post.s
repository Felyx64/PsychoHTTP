.section .data
  UploadPosts_Route_Response:
    .ascii "HTTP/1.1 200 OK\r\n"
    .ascii "Content-Type: application/json"
    .ascii "Server: SpookyFunnyAssemblyServer :3"
    .ascii "Allow: POST\r\n"
    .ascii "Connection: close\r\n"
    .ascii "Transfer-Encoding: chunked\r\n"
    .asciz "Date: "

.section .text
  Handle_UploadPost_Route_Request:
    pushl %ecx
    pushl %ebx

    leal SCOM_User_Server_Request, %eax          # link the requuest to $eax
    call RunToEndOfReqHeader                     # move req ptr to req content
    call Extract_From_Post_Json                  # parse the json

    # do some filtering work on the json result
    pushl %eax
    movl %ebx, %eax
    call FilterOutSeperators
    popl %ebx
    pushl %eax
    movl %ebx, %eax
    call FilterOutSeperators
    popl %ebx

    # and then some more
    pushl %eax
    movl %ebx, %eax
    call FilterOutSeperators
    popl %ebx
    pushl %eax
    movl %ebx, %eax
    call FilterOutSeperators
    popl %ebx

    call Create_Database_Index                  # convert the content to a db index
    call Strlen                                 # get the length of the index needed for writing
    xchgl %eax, %ebx                            # swap the 2 registers into the right place
    call QueryUPLOAD_PostToDB                   # Query the post of the database

    movl $5, %ecx                               # id for file if we got an error
    movl $6, %ebx                               # id for file if no error
    cmpl $1, %eax                               # check if we got error from upload
    cmovel %ecx, %ebx                           # move error_json id if we got an error
    leal UploadPosts_Route_Response, %eax       # Link the status response back to $eax
    call build_response                         # build the full response

    leal SCOM_Response_Creation_Table, %eax     # link start of res to %eax
    call Strlen                                 # get total length of response

    movl %eax, %edx                             # move the response length into %edx
    movl %ebx, %ecx                             # move response message to %ecx
    popl %edi                                   # move server config into edi param
    popl %ebx                                   # move server-fd into the 2nd param
    movl $369, %eax                             # move syscall code (sendto) into %eax
    movl $16, %ebp                              # move the server config into last param
    int $0x80                                   # call syscall 369 (sendto)

    pushl %ebx

    # clear the response object
    leal SCOM_Response_Creation_Table, %eax
    call Clear_SCOM_8192

    popl %ebx

    ret
