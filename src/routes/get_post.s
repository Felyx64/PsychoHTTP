.section .data
  GetPosts_Route_Response:
    .ascii "HTTP/1.1 200 OK\r\n"
    .ascii "Content-Type: application/json\r\n"
    .ascii "Server: SpookyFunnyAssemblyServer :3\r\n"
    .ascii "Allow: GET\r\n"
    .ascii "Connection: close\r\n"
    .ascii "Range: bytes=1000-1999\r\n"
    .ascii "Transfer-Encoding: chunked\r\n"
    .asciz "Date: "

.section .text
  Handle_GetPost_Route_Request:
    pushl %eax
    leal SCOM_Response_Creation_Table, %esi
    leal GetPosts_Route_Response, %edi
    call String_Plot

    pushl %eax
    pushl $2147483647

    # assign the data time from here

    call get_unix_sec_gmt                 # get the current unix gmt-ajusted time

    call get_current_full_time
    pushl %eax # secs
    pushl %ebx # mins
    pushl %ecx # hours
    pushl %edi # year
    pushl %edx # month
    pushl %esi # days

    # Get the month id from the returned month data.
    # This data is located after the string.
    movl %edx, %eax
    call RunToEnd
    inc %eax
    movb (%eax), %cl
    xorl %ebx, %ebx
    movb %cl, %bl

    # get the current day of the week string-chunk for the date
    movl %edi, %eax
    movl %esi, %ecx
    call get_current_day_of_week
    movl %eax, %ecx

    # search in the stack from the
    # added a search instead of hardcoding it bc i might push more things later
    movl %esp, %esi
    .r_search_get_req_head_ptr:
    addl $4, %esi
    movl (%esi), %edi
    cmpl $2147483647, %edi
    jne .r_search_get_req_head_ptr
    addl $4, %esi
    movl (%esi), %edi                     # get the req head pointer and store it in %edi

    movl %edi, %esi

    movl %ecx, %edi
    call String_Plot
    movl %eax, %esi

    # assign the day
    popl %eax
    cmpl $10, %eax
    ja .r_bigger_dmo_diget
    addb $0x30, %al
    movb %al, (%esi)
    inc %esi
    jmp .r_assigned_dmo
    .r_bigger_dmo_diget:
    movl $10, %ebx
    xorl %edx, %edx
    div %ebx
    addb $0x30, %al
    addb $0x30, %dl
    movb %al, (%esi)
    inc %esi
    movb %dl, (%esi)
    inc %esi
    .r_assigned_dmo:

    movb $' ', (%esi)
    inc %esi

    # assign Month
    popl %eax
    movb (%eax), %bl
    movb %bl, (%esi)
    inc %eax
    inc %esi
    movb (%eax), %bl
    movb %bl, (%esi)
    inc %eax
    inc %esi
    movb (%eax), %bl
    movb %bl, (%esi)
    inc %esi

    movb $' ', (%esi)
    inc %esi

    # assign year
    popl %eax
    pushl %esi
    leal TimeMakerMemory, %edi
    call IntToString
    popl %esi

    leal TimeMakerMemory, %edi
    movb (%edi), %al
    movb %al, (%esi)
    inc %edi
    inc %esi
    movb (%edi), %al
    movb %al, (%esi)
    inc %edi
    inc %esi
    movb (%edi), %al
    movb %al, (%esi)
    inc %edi
    inc %esi
    movb (%edi), %al
    movb %al, (%esi)
    inc %esi

    movb $' ', (%esi)
    inc %esi

    # assign the hour
    popl %eax
    cmpl $10, %eax
    ja .r_bigger_hoftd_diget
    movb $0x30, (%esi)
    inc %esi
    addb $0x30, %al
    movb %al, (%esi)
    inc %esi
    jmp .r_assigned_hoftd
    .r_bigger_hoftd_diget:
    movl $10, %ebx
    xorl %edx, %edx
    div %ebx
    addb $0x30, %al
    addb $0x30, %dl
    movb %al, (%esi)
    inc %esi
    movb %dl, (%esi)
    inc %esi
    .r_assigned_hoftd:

    movb $':', (%esi)
    inc %esi

    # assign the minute
    popl %eax
    cmpl $10, %eax
    ja .r_bigger_moth_diget
    movb $0x30, (%esi)
    inc %esi
    addb $0x30, %al
    movb %al, (%esi)
    inc %esi
    jmp .r_assigned_moth
    .r_bigger_moth_diget:
    movl $10, %ebx
    xorl %edx, %edx
    div %ebx
    addb $0x30, %al
    addb $0x30, %dl
    movb %al, (%esi)
    inc %esi
    movb %dl, (%esi)
    inc %esi
    .r_assigned_moth:

    movb $':', (%esi)
    inc %esi

    # assign the second
    popl %eax
    cmpl $10, %eax
    ja .r_bigger_sotm_diget
    movb $0x30, (%esi)
    inc %esi
    addb $0x30, %al
    movb %al, (%esi)
    inc %esi
    jmp .r_assigned_sotm
    .r_bigger_sotm_diget:
    movl $10, %ebx
    xorl %edx, %edx
    div %ebx
    addb $0x30, %al
    addb $0x30, %dl
    movb %al, (%esi)
    inc %esi
    movb %dl, (%esi)
    inc %esi
    .r_assigned_sotm:

    movb $' ', (%esi)
    inc %esi
    movb $'G', (%esi)
    inc %esi
    movb $'M', (%esi)
    inc %esi
    movb $'T', (%esi)
    inc %esi

    # assign the request-body seperator here

    leal Response_Line_Starter_And_Terminator, %edi
    call String_Plot
    movl %eax, %esi
    leal Response_Line_Starter_And_Terminator, %edi
    call String_Plot

    addl $8, %esp
    # Continue assigning here

    popl %ecx
    pushl %eax
    movl %ecx, %eax
    leal SCOM_json_maker_table, %ebx

    call Convert_DB_Results_To_Json

    # parse into chunked response here
    movl %eax, %ebx
    .start_json_linechunkerloop:                      # start of the converrsion loop is here
    leal SCOM_converted_chunked_response_data, %eax   # link the conversion blob to %eax
    .partion_json_responseloop:                       # start of assign to conversionblob loop
    movb (%ebx), %cl
    movb %cl, (%eax)
    inc %ebx
    inc %eax
    cmpb $10, %cl
    je .convert_json_line
    cmpb $0, %cl
    je .done_paritioning_json
    jmp .partion_json_responseloop
    .convert_json_line:                               # assign conversionblob loop ends here
    dec %eax                                          # decrement the null newline away from the conversionblob
    movb $0, (%eax)                                   # end the conversionblob with null terminator
    leal SCOM_converted_chunked_response_data, %eax   # link the start back to %eax
    pushl %ebx                                        # backup the file read results
    call CreateResponseFracturePartition              # partition the single line on the conversionblob
    popl %ebx                                         # get back the file results
    popl %esi                                         # get the response object back as well
    .extract_converted_jsonchunked_loop:              # assign the converted line to the response in this loop
    movb (%eax), %cl
    movb (%esi), %dl
    movb %cl, (%esi)
    inc %eax
    inc %esi
    cmpb $0, %cl
    jne .extract_converted_jsonchunked_loop
    dec %esi
    pushl %esi
    jmp .start_json_linechunkerloop
    .done_paritioning_json:

    popl %esi                                         # get the response blob back
    movb $0x30, (%esi)                                # add char '0' i.e 0x30 to the %esi so the chunked res has an end
    inc %esi                                          # increment the response blob
    leal Response_Line_Starter_And_Terminator, %edi   # link the line ender to %edi
    call String_Plot                                  # plot the line ender onto the res blob
    inc %eax                                          # increment %eax as the res str_plot does not do that
    movb $0, (%eax)                                   # move null terminator into the last char

    leal SCOM_Response_Creation_Table, %eax           # re-link the response to $eax
    call Strlen                                       # get lenght of reponse

    ret
