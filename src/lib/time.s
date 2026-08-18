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
    #call get_current_month                # get the month
    popl %ebx                             # pop the unix time from the stack back to the %ebx register
    pushl %eax                            # push the month to the stack so it sits there unharmed
    movl %ebx, %eax                       # move the unix time back to %eax
    pushl %eax                            # copy the unix time to the stack as a temp
    #call get_current_day                  # get the day
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
    cvtss2sd %xmm1, %xmm1
    divsd %xmm1, %xmm0
    cvttsd2si %xmm0, %eax
    addl $1970, %eax
    ret

  # PARAM: (%EBX) holds the curret year
  # OVERWRITES: EBX, EDX, ESI
  # RETURNS: (%EAX) holds if its a leap year or not. 0 = no_leap, 1 = leap
  check_leap_year:
    movl $1, %ecx
    movl $0, %esi
    movl $4, %ebx
    div %ebx
    cmpl $0, %edx
    cmovel %ecx, %eax
    cmovnel %esi, %eax
    ret

  # PARAM: (%EAX) holds current iso data-time
  # PARAM: (%EBX) holds the curret year
  # PARAM: (%ECX) holds info if its the leap year
  # OVERWRITES: EDX, ESI
  # DESCRIPTION: gets the current momth of the year
  # RETURNS: (%EAX) holds the current month of the year
  get_current_daymonth:
    # get days since jan-1
    # x = floor(unix_time / 86400 - (current_year - 1970) * 365.25)
    subl $1970, %ebx
    cvtsi2sd %ebx, %xmm0
    movsd year_calc_num_64, %xmm1
    mulsd %xmm1, %xmm0
    movsd number_in_day_float_64, %xmm2
    cvtsi2sd %eax, %xmm1
    divsd %xmm2, %xmm1
    subsd %xmm0, %xmm1
    cvttsd2si %xmm1, %eax

    # check if we are on january
    cmpl $31, %eax                        # if: 31 > days_since_jan1(%eax)
    ja .not_january                       # skip logic if true
    inc %eax
    leal January_Month, %ebx
    ret
    .not_january:

    movl $60, %ebx

    # check if we have a leap year
    cmpl $0, %ecx
    je .not_ly
    inc %ebx                              # increment to account the leap year
    .not_ly:

    movl %ecx, %esi                       # move the leap year info %esi

    # check if we are on february
    cmpl %eax, %ebx                       # if: days_since_jan1(%eax) < days_counter(%ebx)
    jl .not_february                      # skip logic if true
    subl $30, %eax
    leal February_Month, %ebx
    ret
    .not_february:

    # iterate over other months
    movl $31, %ecx                        # (x) determines and iterates if the month has 31 or 30 days
    xorl %edx, %edx                       # (y) array index on which month we have
    .month_getter_loop:                   # start of get month loop
    cmpl %eax, %ebx                       # if: days_since_jan1(%eax) < days_counter(%ebx)
    jl .did_not_hit_good_month            # skip logic if true
    call switch_days                      # switch the %ecx from 31/30 last time
    cmpl $0, %esi                        # check if we are leap year (again)
    jne .not_leap_year                    # jump if we are in a leap year
    subl $2, %ebx
    dec %edx
    .not_leap_year:                       # start here if leap year
    subl %ecx, %ebx # may need to rotate the 2 subls
    subl %ebx, %eax
    call link_month
    ret
    .did_not_hit_good_month:               # if we still have not gotten the month
    addl %ecx, %ebx
    call switch_days                       # switch the %ecx from 31/30
    inc %edx
    jmp .month_getter_loop

    switch_days:
      cmpl $31, %ecx
      jne .31_days
      movl $30, %ecx
      jmp .switched_days
      .31_days:
      movl $31, %ecx
      .switched_days:
      ret

    link_month:
      jmp *link_month_table(,%edx,4)
      link_month_table:
        .long is_March
        .long is_April
        .long is_May
        .long is_June
        .long is_July
        .long is_August
        .long is_September
        .long is_October
        .long is_November
        .long is_December

        is_March:
          leal March_Month, %ebx
          jmp .linked_month
        is_April:
          leal April_Month, %ebx
          jmp .linked_month
        is_May:
          leal May_Month, %ebx
          jmp .linked_month
        is_June:
          leal June_Month, %ebx
          jmp .linked_month
        is_July:
          leal July_Month, %ebx
          jmp .linked_month
        is_August:
          leal August_Month, %ebx
          jmp .linked_month
        is_September:
          leal September_Month, %ebx
          jmp .linked_month
        is_October:
          leal October_Month, %ebx
          jmp .linked_month
        is_November:
          leal November_Month, %ebx
          jmp .linked_month
        is_December:
          leal December_Month, %ebx
          jmp .linked_month

      .linked_month:
      ret
  # return happens inside the got month section

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
  number_in_day_float_64:
    .double 86400.0
  year_calc_num:
    .float 365.25
  year_calc_num_64:
    .double 365.25

  # month map
  January_Month:
    .asciz "January"
  February_Month:
    .asciz "February"
  March_Month:
    .asciz "March"
  April_Month:
    .asciz "April"
  May_Month:
    .asciz "May"
  June_Month:
    .asciz "June"
  July_Month:
    .asciz "July"
  August_Month:
    .asciz "August"
  September_Month:
    .asciz "September"
  October_Month:
    .asciz "October"
  November_Month:
    .asciz "November"
  December_Month:
    .asciz "December"
