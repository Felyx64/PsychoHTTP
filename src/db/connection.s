.section .bss
  db_connection_id:
    .long 0

.section .text
  # DESCRIPTION: GET START CONNECTING TO THE DATABASE TO START WRITING TO IT
  # OVERWRITES: EAX, EBX, ECX
  ConnectDB:
    movl $1, %eax                 # move file id for db into param 1
    call Open_File_Stream         # open the file stream
    cmpl $-1, %eax                # check if error
    je .had_db_connection_error   # throw error if there is
    leal db_connection_id, %ebx   # link the fd storage in RAM to %ebx
    movl %eax, (%ebx)             # store the fd into the RAM
    .had_db_connection_error:     # label if connecting the db failed
    ret

  DisconnectDB:
    leal db_connection_id, %ebx   # link the fd storage in RAM to %ebx
    movl (%ebx), %eax             # get the fd back from the RAM
    call Close_File_Stream        # close the FD
    ret
