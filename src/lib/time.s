.section .data
    time_buf:
      .long 0

.section .text

  # RETURNS (%EAX) THE CURRENT UNIX TIME
  # OVERWRITES %EAX, %EBX
  get_unix_sec:
    movl $13, %eax                        # move sys_time syscall id into %eax
    movl $time_buf, %ebx                  # tell sys_time where do send to unix time to
    int $0x80                             # call the syscall
    movl $time_buf, %eax                  # push the unix time to %eax which we got from the result
    ret

  # DESCRIPTION: GETS ALL THE
  # OVERWRITES: ALL REGISTERS
  # RETURNS (EAX) THE CURRENT YEAR
  # RETURNS (EBX) THE CURRENT MONTH
  # RETURNS (ECX) THE CURRENT DAY
  # RETURNS (EDX) THE CURRENT HOUR
  # RETURNS (EDI) THE CURRENT MINUTE
  get_full_date:
    call get_unix_sec                     # get the current unix time

    pushl %eax                            # copy the unix time to the stack as a temp
    call get_current_year                 # get the year
    popl %ebx                             # pop the unix time from the stack back to the %ebx register
    pushl %eax                            # push the year to the stack so it sits there unharmed
    movl %ebx, %eax                       # move the unix time back to %eax
    pushl %eax                            # copy the unix time to the stack as a temp
    call get_current_month                # get the month
    popl %ebx                             # pop the unix time from the stack back to the %ebx register
    pushl %eax                            # push the month to the stack so it sits there unharmed
    movl %ebx, %eax                       # move the unix time back to %eax
    pushl %eax                            # copy the unix time to the stack as a temp
    call get_current_day                  # get the day
    popl %ebx                             # pop the unix time from the stack back to the %ebx register
    pushl %eax                            # push the day to the stack so it sits there unharmed
    movl %ebx, %eax                       # move the unix time back to %eax
    pushl %eax                            # copy the unix time to the stack as a temp
    call get_current_hour                 # get the hour
    popl %ebx                             # pop the unix time from the stack back to the %ebx register
    pushl %eax                            # push the hour to the stack so it sits there unharmed
    movl %ebx, %eax                       # move the unix time back to %eax
    call get_current_minute               # get the minute
    movl %eax, %edi                       # push the current minutes into %edi
    popl %edx                             # push the current hours into %edx
    popl %ecx                             # push the current days into %ecx
    popl %ebx                             # push the current months into %ebx
    popl %eax                             # push the current year into %eax
    ret

  # PARAM: (%EAX) holds current iso data-time
  # DESCRIPTION: gets the current year
  # RETURNS: (%EAX) the current year
  get_current_year:
    # x = 1970 + floor(time() / (86400 * 365.25))
    movss number_in_day_float, %xmm0
    movss year_calc_num, %xmm1
    mulss %xmm0, %xmm1
    cvtsi2sd %eax, %xmm0
    movss %xmm1, %xmm0
    cvtss2sd %xmm1, %xmm1
    divsd %xmm1, %xmm0
    cvttsd2si %xmm0, %eax
    addl $1970, %eax
    ret

  # PARAM: (%EAX) holds current iso data-time
  # DESCRIPTION: gets the current momth of the year
  # RETURNS: (%EAX) holds the current month of the year
  # OVERWRITES: %ECX %EDX
  # RETURNS: (%EAX) the current month
  get_current_month:
    pushl %eax                            # push the iso int to the stack tempoirly
    call get_current_year                 # get the current year so we can tell if its a leap year or not
    movl $1, %eax                         # move 1 into the month counter to initialize it
    movl %ebx, %ecx                       # move the leap year info to %ecx
    popl %ebx                             # bring the iso date back into the ebx register
    movl $1, %edi                         # move 1 into %edi as its needed for a cmovel later on
    .get_month_in_year:                   # start of get month loop

    pushl %eax                            # temp push iso date to stack
    pushl %ebx                            # temp push current month info to stack
    pushl %ecx                            # temp push leap year info to stack
    movl $2, %ecx                         # move the divisor needed to getting the good month to %ecx
    movl %ebx, %eax                       # temp move on_month copy to the %eax needed for devision
    div %ecx                              # enact the devision %eax / %ecx, remainder stored in %edx
    popl %ecx                             # restore the leap year info back from the stack
    popl %ebx                             # restore the current month info back from the stack
    popl %eax                             # restore the iso date back from the stack
    cmpl $0, %edx                         # check if we have a leap year as this is what the division remainder tells us
    je .long_month                        # if 0 its a short month (30 days)
    jne .short_month                      # if not 0 its a long month (31 days)

    .short_month:                         # remove the short month from the iso date
    cmpl $13, %eax                        # check if we have hit month 13 meaning we need to reset the month timer
    cmovel %edi, %eax                     # reset %eax if it is
    je .get_month_in_year                 # back to loop if it is month 13
    subl $NUMBERS_IN_NORMAL_MONTH, %ebx   # remove a short month worth of seconds from %ebx
    cmpl $NUMBERS_IN_NORMAL_MONTH, %ebx   # check we found the good month
    jl .found_the_month                   # goto end of function if we found the good month
    inc %eax                              # increment the current month if not
    jmp .get_month_in_year                # back to loop if not

    .long_month:                          # remove the long month from the iso date
    cmpl $2, %eax                         # check if we have hit the 2 which is feb aka not a normal month
    je .in_february                       # jump to february if we are in february
    subl $NUMBERS_IN_LONG_MONTH, %ebx     # remove a long month worth of seconds from %ebx
    cmpl $NUMBERS_IN_LONG_MONTH, %ebx     # check we found the good month
    jl .found_the_month                   # goto end of function if we found the good month
    inc %eax                              # increment the current month if not
    jmp .get_month_in_year                # back to loop if not

    .in_february:                         # remove the normal february from the iso date
    cmpl $4, %ecx                         # check if we are in a leap year
    je .in_february_leap                  # move the the leap year logic if is leap year
    subl $NUMBERS_IN_FEBRUARY, %ebx       # remove a february worth of seconds from %ebx
    cmpl $NUMBERS_IN_FEBRUARY, %ebx       # check we found the good month
    jl .found_the_month                   # goto end of function if we found the good month
    inc %eax                              # increment the current month if not
    jmp .get_month_in_year                # back to loop if not

    .in_february_leap:                    # remove the leap february from the iso date
    subl $NUMBERS_IN_LEAP_FEBRUARY, %ebx  # remove a leap february worth of seconds from %ebx
    cmpl $NUMBERS_IN_LEAP_FEBRUARY, %ebx  # check we found the good month
    jl .found_the_month                   # goto end of function if we found the good month
    inc %eax                              # increment the current month if not
    jmp .get_month_in_year                # back to loop if not

    .found_the_month:                     # end of function if we found the month
    movl %ebx, %eax                       # move result to accumilator
    ret                                   # return

  # PARAM: (%EAX) holds current iso data-time
  # RETURNS: (%EAX) holds the current day of the month
  # OVERWRITES: %ECX, %EDX
  # RETURNS: (%EAX) the current day
  get_current_day:
    call get_current_month
    movl $NUMBERS_IN_DAY, %ecx
    div %ecx
    ret

  # PARAM: (%EAX) holds current iso data-time
  # RETURNS: (%EAX) holds the current hour
  # OVERWRITES: %ECX, %EDX
  # RETURNS: (%EAX) the current hour
  get_current_hour:
    movl $NUMBERS_IN_HOURS, %ecx
    xorl %edx, %edx
    divl %ecx
    movl %edx, %eax
    ret

  # PARAM: (%EAX) holds current iso data-time
  # RETURNS: (%EAX) holds the current minute
  # OVERWRITES: %ECX, %EDX
  # RETURNS: (%EAX) the current minute
  get_current_minute:
    movl $NUMBERS_IN_SECONDS, %ecx
    xorl %edx, %edx
    divl %ecx
    movl %edx, %eax
    ret

# set constants needed for the conversions
.set NUMBERS_IN_SECONDS, 60
.set NUMBERS_IN_HOURS, 3600
.set NUMBERS_IN_DAY, 86400

# set constants needed for the month conversions
.set NUMBERS_IN_NORMAL_MONTH, 2592000
.set NUMBERS_IN_LONG_MONTH, 2678400
.set NUMBERS_IN_FEBRUARY, 2419200
.set NUMBERS_IN_LEAP_FEBRUARY, 2505600

# set constants needed for the year conversions
.set NUMBERS_IN_NORMAL_YEAR, 31536000
.set NUMBERS_IN_LEAP_YEAR, 31622400

.section .data
  number_in_day_float:
    .float 86400.0
  year_calc_num:
    .float 365.25
