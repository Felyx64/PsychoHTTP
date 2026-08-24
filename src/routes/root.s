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

    movb $0, (%esi)
    inc %esi

    # date: Thu, 20 Aug 2026 11:54:20 GMT
    #.check_str:
    # call Clear_SCOM_2048

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
    call Clear_SCOM_2048
    ret
