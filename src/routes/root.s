.section .data
  Root_Route_Reponse:
    .ascii "HTTP/1.1 200 OK\r\n"
    .ascii "Content-Type: text/html\r\n"
    .ascii "Server: SpookyFunnyAssemblyServer :3\r\n"
    .ascii "Allow: GET\r\n"
    .ascii "Connection: close\r\n"
    .ascii "Transfer-Encoding: chunked\r\n"
    .asciz "Date: "

.section .text
  Handle_Root_Route_Request:
    pushl %ecx
    pushl %ebx

    call get_unix_sec_gmt                 # get the current unix time

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

    leal SCOM_Response_Creation_Table, %esi
    leal Root_Route_Reponse, %edi
    call String_Plot

    movl %ecx, %edi
    call String_Plot

    # assign the day
    popl %eax
    cmpl $10, %eax
    ja .bigger_dmo_diget
    addb $0x30, %al
    movb %al, (%esi)
    inc %esi
    jmp .assigned_dmo
    .bigger_dmo_diget:
    movl $10, %ebx
    xorl %edx, %edx
    div %ebx
    addb $0x30, %al
    addb $0x30, %dl
    movb %al, (%esi)
    inc %esi
    movb %dl, (%esi)
    inc %esi
    .assigned_dmo:

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
    ja .bigger_hoftd_diget
    addb $0x30, %al
    movb %al, (%esi)
    inc %esi
    jmp .assigned_hoftd
    .bigger_hoftd_diget:
    movl $10, %ebx
    xorl %edx, %edx
    div %ebx
    addb $0x30, %al
    addb $0x30, %dl
    movb %al, (%esi)
    inc %esi
    movb %dl, (%esi)
    inc %esi
    .assigned_hoftd:

    movb $':', (%esi)
    inc %esi

    # assign the minute
    popl %eax
    cmpl $10, %eax
    ja .bigger_moth_diget
    addb $0x30, %al
    movb %al, (%esi)
    inc %esi
    jmp .assigned_moth
    .bigger_moth_diget:
    movl $10, %ebx
    xorl %edx, %edx
    div %ebx
    addb $0x30, %al
    addb $0x30, %dl
    movb %al, (%esi)
    inc %esi
    movb %dl, (%esi)
    inc %esi
    .assigned_moth:

    movb $':', (%esi)
    inc %esi

    # assign the second
    popl %eax
    cmpl $10, %eax
    ja .bigger_sotm_diget
    addb $0x30, %al
    movb %al, (%esi)
    inc %esi
    jmp .assigned_sotm
    .bigger_sotm_diget:
    movl $10, %ebx
    xorl %edx, %edx
    div %ebx
    addb $0x30, %al
    addb $0x30, %dl
    movb %al, (%esi)
    inc %esi
    movb %dl, (%esi)
    inc %esi
    .assigned_sotm:

    movb $' ', (%esi)
    inc %esi
    movb $'G', (%esi)
    inc %esi
    movb $'M', (%esi)
    inc %esi
    movb $'T', (%esi)
    inc %esi

    leal Response_Line_Starter_And_Terminator, %edi
    call String_Plot
    movl %eax, %esi
    leal Response_Line_Starter_And_Terminator, %edi
    call String_Plot

    # read the root html file
    pushl %eax
    movl $3, %eax
    call Read_File_Standard

    # parse into chunked response here
    leal SCOM_File_Read_Results, %ebx                 # link the file results to %ebx
    .start_roothtml_linechunkerloop:                  # start of the converrsion loop is here
    leal SCOM_converted_chunked_response_data, %eax   # link the conversion blob to %eax
    .partion_responseloop:                            # start of assign to conversionblob loop
    movb (%ebx), %cl
    movb %cl, (%eax)
    inc %ebx
    inc %eax
    cmpb $10, %cl
    je .convert_roothtmlfile_line
    cmpb $0, %cl
    je .done_paritioning_html
    jmp .partion_responseloop
    .convert_roothtmlfile_line:                       # assign conversionblob loop ends here
    dec %eax                                          # decrement the null newline away from the conversionblob
    movb $0, (%eax)                                   # end the conversionblob with null terminator
    leal SCOM_converted_chunked_response_data, %eax   # link the start back to %eax
    pushl %ebx                                        # backup the file read results
    call CreateResponseFracturePartition              # partition the single line on the conversionblob
    popl %ebx                                         # get back the file results
    popl %esi                                         # get the response object backa as well
    .extract_converted_roothtmlchunked_loop:          # assign the converted line to the response in this loop
    movb (%eax), %cl
    movb (%esi), %dl
    movb %cl, (%esi)
    inc %eax
    inc %esi
    cmpb $0, %cl
    jne .extract_converted_roothtmlchunked_loop
    dec %esi
    pushl %esi
    jmp .start_roothtml_linechunkerloop
    .done_paritioning_html:

    # assign last parts of the res to the response object
    popl %esi                                         # get the response blob back
    movb $0x30, (%esi)                                # add char '0' i.e 0x30 to the %esi so the chunked res has an end
    inc %esi                                          # increment the response blob
    leal Response_Line_Starter_And_Terminator, %edi   # link the line ender to %edi
    call String_Plot                                  # plot the line ender onto the res blob
    inc %eax                                          # increment %eax as the res str_plot does not do that
    movb $0, (%eax)                                   # move null terminator into the last char

    leal SCOM_Response_Creation_Table, %eax           # link start of res to %eax
    call Strlen                                       # get total length of response
    movl %eax, %edx                                   # move the response length into %edx
    movl %ebx, %ecx                                   # move response message to %ecx
    popl %edi                                         # move server config into edi param
    popl %ebx                                         # move server-fd into the 2nd param
    movl $369, %eax                                   # move syscall code (sendto) into %eax
    movl $16, %ebp                                    # move the server config into last param
    int $0x80                                         # call syscall 369 (sendto)

    # clear the response object
    leal SCOM_Response_Creation_Table, %eax
    call Clear_SCOM_6144

    ret
