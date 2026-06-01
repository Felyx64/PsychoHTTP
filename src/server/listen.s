.section .data
  Listen_Server_Error:
    .asciz "ListenErr: Server Listening Action failed!"

.section .text
  start_server:
    mov %eax, %ebx                     # moves server fd in %EAX to %EBX
    mov $363, %eax                     # move syscall number to %EAX (listen)
    mov $10, %ecx                      # moves 10 to the backlog parameter
    int $0x80                          # trigger the syscall itself

    cmpl $0, %eax                      # checks if listen action has returned an error or not
    je .listen_succesfull              # jump to end of procedure if no error gained

    movl $Listen_Server_Error, %eax    # Move the Error to print into the %EAX parameter
    call nstandard_console_write       # call the console write procedure
    movl $-1, %eax                     # move -1 into %EAX signaling an error

    .listen_succesfull:                # end of procedure label
    ret
