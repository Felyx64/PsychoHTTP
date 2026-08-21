.section .data
    time_buf:
      .long 0

.section .text
  #? UNTESTED
  # DESCRIPTION: GETS ALL THE
  # RETURNS (EAX-ESI) all date info
  # EAX: SECONDS
  # EBX: MINUTE
  # ECX: HOUR
  # EDX: MONTH
  # ESI: DAY
  # EDI: YEAR
  get_current_full_time:
    call get_unix_sec                     # get the current unix time
    movl (%eax), %eax                     # got the result out of the RAM
    pushl %eax                            # backup the unix time
    call get_current_year                 # get the current year
    pushl %eax                            # backup the year
    call check_leap_year                  # check if we are one a leap year
    movl %eax, %ecx                       # move leap year fact to the %ecx
    popl %ebx                             # get back the current year
    popl %eax                             # get the current unix time
    pushl %ebx                            # push back the current year
    pushl %eax                            # push back the current unix time
    call get_current_daymonth             # get the current day and month
    popl %ecx                             # get back the unix time in %ecx
    pushl %eax                            # push month to stack
    pushl %ebx                            # put current day to the stack
    movl %ecx, %eax                       # move unix time back to %eax
    pushl %eax                            # backup unix time once again
    call get_current_hour                 # get the current hour
    popl %ebx                             # get back the unix time
    pushl %eax                            # push current hour to stack
    movl %ebx, %eax                       # move unix time to %eax after %eax was backuped
    pushl %ebx                            # backup unix time
    call get_current_minute               # get current minute
    movl %eax, %edx                       # move minute to %edx
    popl %eax                             # get back the unix time
    pushl %edx                            # backup minute time again
    call get_current_second               # get the current second
    popl %ebx                             # put current minute to ebx
    popl %ecx                             # put current hours to ecx
    popl %edx                             # put current days to edx
    popl %esi                             # put current months to esi
    popl %edi                             # put current years to ebx
    ret

  # RETURNS (%EAX) THE CURRENT UNIX TIME
  # OVERWRITES %EAX, %EBX
  get_unix_sec:
    movl $13, %eax                        # move sys_time syscall id into %eax
    movl $time_buf, %ebx                  # tell sys_time where do send to unix time to
    int $0x80                             # call the syscall
    movl $time_buf, %eax                  # push the unix time to %eax which we got from the result
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
  # OVERWRITES: %EBX, %EDX
  get_current_hour:
    # x = floor(time() / 3600 + 2) mod 24
    # x = floor((unix_time + timezone_offset) / 3600) mod 24
    cvtsi2sd %eax, %xmm0
    movsd CET_Offset_secinhour, %xmm1
    divsd %xmm1, %xmm0
    addsd Timezone_Summer_Offeset, %xmm0
    cvtsd2si %xmm0, %eax
    xorl %edx, %edx
    movl $24, %ebx
    div %ebx
    movl %edx, %eax
    ret

  # PARAM: (%EAX) holds current iso data-time
  # RETURNS: (%EAX) holds the current minute
  # OVERWRITES: %EBX, %EDX
  get_current_minute:
    # x = ((unix_time % 86400) / 60) mod 60
    movl $NUMBER_IN_DAY_INT, %ebx
    xorl %edx, %edx
    div %ebx
    movl %edx, %eax
    xorl %edx, %edx
    movl $SECONDS_IN_MINUTES, %ebx
    div %ebx
    movl $SECONDS_IN_MINUTES, %ebx
    xorl %edx, %edx
    div %ebx
    movl %edx, %eax
    ret

  # PARAM: (%EAX) holds current iso data-time
  # RETURNS: (%EAX) holds the current second
  # OVERWRITES: %EBX, %EDX
  get_current_second:
    movl $SECONDS_IN_MINUTES, %ebx
    xorl %edx, %edx
    div %ebx
    movl %edx, %eax
    ret

  # PARAM: (%EAX) CURRENT YEAR
  # PARAM: (%EBX) CURRENT MONTH
  # PARAM: (%ECX) CURRENT DAY
  # DISCRIPTION: GET THE CURRENT DAY OF THE WEEK IN THE FORM OF A CHAR*
  # OVERWRITES: EVERY REGISTER
  # RETURNS: (%EAX) CHAR* TO CURRENT DAY OF THE WEEK
  get_current_day_of_week:
    # if month < 3: (month += 12) or: (year -= 1)
    # x = (day + floor((13 * (month + 1)) / 5) + year + floor(year / 4) - floor(year / 100) + floor(year / 400)) % 7
    cmpl $3, %ebx
    jnl .month_no_month_ajust
    addl $12, %ebx
    dec %eax
    .month_no_month_ajust:
    cvtsi2sd %eax, %xmm1
    movsd %xmm1, %xmm0
    divsd Get_Day_Conv_Req_1, %xmm0
    cvttsd2si %xmm0, %esi
    movsd %xmm1, %xmm0
    divsd Get_Day_Conv_Req_2, %xmm0
    cvttsd2si %xmm0, %edx
    movsd %xmm1, %xmm0
    divsd Get_Day_Conv_Req_3, %xmm0
    cvttsd2si %xmm0, %edi
    addl %eax, %edi
    subl %edx, %edi
    addl %esi, %edi
    movl %ecx, %eax
    movl %edi, %ecx
    addl $1, %ebx
    cvtsi2sd %ebx, %xmm0
    mulsd Get_Day_Conv_Req_5, %xmm0
    divsd Get_Day_Conv_Req_4, %xmm0
    cvttsd2si %xmm0, %ebx
    addl %ecx, %ebx
    addl %ebx, %eax
    movl $7, %ebx
    xorl %edx, %edx
    div %ebx
    dec %edx

    jmp *link_day_table(,%edx,4)

    link_day_table:
      .long is_Sunday
      .long is_Monday
      .long is_Tuesday
      .long is_Wednesday
      .long is_Thursday
      .long is_Friday
      .long is_Saturday

      is_Sunday:
        leal Sunday_Day, %eax
        jmp .linked_day
      is_Monday:
        leal Monday_Day, %eax
        jmp .linked_day
      is_Tuesday:
        leal Tuesday_Day, %eax
        jmp .linked_day
      is_Wednesday:
        leal Wednsday_Day, %eax
        jmp .linked_day
      is_Thursday:
        leal Thursday_Day, %eax
        jmp .linked_day
      is_Friday:
        leal Friday_Day, %eax
        jmp .linked_day
      is_Saturday:
        leal Saturday_Day, %eax
        jmp .linked_day

    .linked_day:
    ret

# set constants needed for the conversions
.set SECONDS_IN_MINUTES, 60
.set NUMBER_IN_DAY_INT, 86400

.section .data
  number_in_day_float:
    .float 86400.0
  number_in_day_float_64:
    .double 86400.0
  year_calc_num:
    .float 365.25
  year_calc_num_64:
    .double 365.25
  CET_Offset_secinhour:
    .double 3600.0
  Timezone_Summer_Offeset:
    .double 2.0

  Get_Day_Conv_Req_1:
    .double 400.0
  Get_Day_Conv_Req_2:
    .double 100.0
  Get_Day_Conv_Req_3:
    .double 4.0
  Get_Day_Conv_Req_4:
    .double 5.0
  Get_Day_Conv_Req_5:
    .double 13.0

  # month map
  January_Month:
    .asciz "January"
    .byte 1
  February_Month:
    .asciz "February"
    .byte 2
  March_Month:
    .asciz "March"
    .byte 3
  April_Month:
    .asciz "April"
    .byte 4
  May_Month:
    .asciz "May"
    .byte 5
  June_Month:
    .asciz "June"
    .byte 6
  July_Month:
    .asciz "July"
    .byte 7
  August_Month:
    .asciz "August"
    .byte 8
  September_Month:
    .asciz "September"
    .byte 9
  October_Month:
    .asciz "October"
    .byte 10
  November_Month:
    .asciz "November"
    .byte 11
  December_Month:
    .asciz "December"
    .byte 12

  Sunday_Day:
    .asciz "Sun, "
  Monday_Day:
    .asciz "Mon, "
  Tuesday_Day:
    .asciz "Tue, "
  Wednsday_Day:
    .asciz "Wed, "
  Thursday_Day:
    .asciz "Thu, "
  Friday_Day:
    .asciz "Fri, "
  Saturday_Day:
    .asciz "Sat, "
