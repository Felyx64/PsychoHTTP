.section .bss
  Database_Write_Data:
    .space 326

.section .text
  QueryUPLOAD_PostToDB:
    pushl %ebx                    # temp backup the length
    pushl %eax                    # temp backup the string pointer
    leal db_connection_id, %ebx   # link the fp to %ebx
    movl (%ebx), %ebx             # get the data from the pointer and make it param 1 for the next syscall
    movl $19, %eax                # move syscall id 19 into $eax
    movl $0, %ecx                 # make the syscall param 2 $0
    movl $0, %edx                 # make the syscall param 3 $0
    int $0x80                     # trigger syscall lseek (move fp to end of file)
    movl $4, %eax                 # move syscall id 4 into $eax
    popl %ecx                     # get back the char* and move into param 2
    popl %edx                     # get back the length and move into param 3
    int $0x80                     # trigger syscall sys_write
    movl $148, %eax               # move syscall id 148 into $eax
    int $0x80                     # trigger syscall sys_fdatasync to quickly save the written data
    movl $0, %eax                 # move non code into $eax
    ret                           # return
    .bad_post_query:              # label to go to if we got a error code
    movl $1, %eax                 # move error code into $eax
    ret                           # return

  QuerySELECT_PostFromDB:
    # \x1E is deleted value
    ret

  QeurySELECT_MultiplePostsFromDB:
    # returns last index in case we need to read more
    # \x1E is deleted value
    ret

  # EXAMPLE: B|Post Title|31|Welcome the this fun post. This post is a example \n
