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
    pushl %ebx
    pushl %ecx

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
    movb $'+', (%esi)
    inc %esi
    movb $'2', (%esi)
    inc %esi

    leal Response_Line_Starter_And_Terminator, %edi
    call String_Plot
    leal Response_Line_Starter_And_Terminator, %edi
    call String_Plot

    pushl %esi
    movl $3, %eax
    call Read_File_Standard

    # does not do it here
    leal SCOM_File_Read_Results, %ebx
    leal SCOM_converted_chunked_response_data, %eax
    .partion_responseloop:
    movb (%ebx), %cl
    movb %cl, (%eax)
    inc %ebx
    inc %eax
    cmpb $10, %cl
    je .convert_roothtmlfile_line
    cmpb $0, %cl
    je .done_paritioning_html
    jmp .partion_responseloop
    .convert_roothtmlfile_line:
    dec %eax
    inc %ebx
    movb $0, (%eax)
    leal SCOM_converted_chunked_response_data, %eax
    pushl %ebx
    call CreateResponseFracturePartition
    popl %ebx
    popl %esi
    .extract_converted_roothtmlchunked_loop:
    movb (%eax), %cl
    movb (%esi), %dl
    movb %cl, (%esi)
    inc %eax
    inc %esi
    cmpb $0, %cl
    jne .extract_converted_roothtmlchunked_loop
    movb %dl, (%esi)

    leal SCOM_Response_Creation_Table, %esi
    .check_str:
    nop
    #pushl %esi
    #jmp .partion_responseloop
    .done_paritioning_html:
    #movb $0, (%esi)
    #inc %esi

    movl $1, %eax
    movl $51, %ebx
    int $0x80

    popl %esi

    popl %ebx
    popl %ecx

    # temp remove
    movl %ebx, %edi                             # move server config into edi param
    movl %ecx, %ebx                             # move server-fd into the 2nd param
    movl $369, %eax                             # move syscall code (sendto) into %eax
    movl $16, %ebp                              # move the server config into last param
    movl $TempResponseRootObj, %ecx             # move response message to %ecx
    movl $TempResponseRootObjLen, %edx          # move the response length into %edx
    int $0x80                                   # call syscall 369 (sendto)

    # clear the response object
    leal SCOM_Response_Creation_Table, %eax
    call Clear_SCOM_6144

    ret
