.section .text
  # PARAM (%EAX) number which needs to be powered
  # PARAM (%EBX) number to the power of
  # OVERWRITES: $ECX, %EDX
  # RETURNS (%EAX) the result of the math_pow
  Math_Pow:
    movl %eax, %ecx     # move EAX param 1 into ecx for the coming multiply
    movl $1, %eax       # move 1 into %eax as it acts as the result
    .powering_loop:     # start of the math_pow loop
    pushl %ecx          # push %ecx to stack so it does not get affected by the mul instruction
    mul %ecx            # do %eax = %eax * %ecx
    popl %ecx           # reset %ecx
    dec %ebx            # decrement the number to be powered of of
    cmpl $0, %ebx       # check if the powering is done
    jl .powering_loop   # jump back if its not
    ret                 # return with result in %eax

  # PARAM (%EAX) number which needs to be logorithmed to the base of 10
  # OVERWRITES %EBX, %ECX, %EDX
  Math_Logarithm10:     # %eax acts as x
    movl $0, %ebx       # move 0 into %ebx as it acts as the y
    movl $0, %ecx       # move 0 into %ecx which acts as the result
    .logorithm_loop:    # logorithm loop starts here
    pushl %eax          # backup %eax
    pushl %ecx          # backup %ecx
    movl $10, %eax      # move 10 into the math_pow for the log10
    call Math_Pow       # do math_pow(10, %ecx)
    movl %eax, %ebx     # move the returned val into the result
    popl %ecx           # get back the %ecx
    popl %eax           # get back the %eax
    inc %ecx            # increment the y
    cmpl %eax, %ebx     # check if logorithm loop is done
    ja .logorithm_loop  # go back if its not
    dec %ecx            # decrement to fix the overun in the loop
    movl %ecx, %eax     # move the result into %eax once we're done
    ret

  Math_Modulo:

    ret
