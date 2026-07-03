.section .data
  # reads a file and pushes its data to the stack
  # Param: (%eax) code for which file has to be read
  # RETURNS: (%eax) pointer to beginning of the stack data
  Read_File_Stack:
