# SCOM which stands for: State. Carry. Over. Memory
# is reserved memory used to handle transitional memory when transitioning from state to state.
# Without having to deal with the heap.

.section .bss
  SCOM_User_Server_Request:
    .space 1024
