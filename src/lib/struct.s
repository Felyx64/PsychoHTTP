.section .text
  // CREATE__SOCKADDR_IN__STRUCT: Create a stack memory struct required for the (bind) syscall
  // OVERWRITES: ESP
  // RETURNS: (ESP), stack pointer to the struct that has been created
  create__sockaddr_in__struct:              // Creates the sockaddr_in struct required for the (bind) syscall
    subq  $16, %esp                         // Creates a stack allocation of 16 needed for this struct
    movb  $2, (%esp)                        // moves 2 (AF_INET) into the struct which tells again that the server is ipv4
    movb  $0x391E, 2(%esp)                  // moves `Big-Edian` version of number 7870 into the struct so htons is not required
    movl  $0x0100007F, 4(%esp)              // moves `Big-Edian` version of current adress im reading of 127.0.0.1 into the struct so htons is not required
    ret

  // CLEAR__SOCKADDR_IN__STRUCT: clears the sockaddr_in struct from the stack
  // OVERWRITES: ESP (duhh)
  // RETURNS: NONE
  clear__sockaddr_in__struct:               // Clears the stack pointer to the sockaddr_in struct
    addl $16, %esp                          // move the stack pointer back to the original location
    ret

# WE GOT MASSIVE STACK REMOVAL ERROR HERE. FIX LATER
# FIX NEEDS TO BE IN configure.s
