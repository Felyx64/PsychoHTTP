.section .data
  GET_REQ_MESSAGE:
    .ascii "GET"

  POST_REQ_MESSAGE:
    .ascii "POST"

.section .text
  Search_Path_Start:
    movl $0, %ecx                        # move 0 into ecx so we have a getter
    .find_path_loop_start:               # label is start of loop where we search the path part of the request
    movb (%eax, %ecx), %dl               # move char into %dl so it can be scanned
    cmpb $0x2F, %dl                      # check if %dl holds the begin of the request path
    je .found_a_path                     # goto the found a path if we found the path start
    inc %ecx                             # increment ecx so we can keep checking
    jmp .find_path_loop_start            # go back to start of loop to keep looking for start of path
    .found_a_path:                       # we start scanning the path here
    inc %ecx                             # increment %ecx so we are no longer looking at the root of the path
    ret

  Analyze_Request:
    leal SCOM_User_Server_Request, %eax  # get a link to first char to request for analysis
    movb (%eax), %dl                     # move first character into %dl
    cmpb $0x47, %dl                      # if char 'G' analyze as GET request
    je .is_get_request                   # move to GET analyzer if we got G
    cmpb $0x50, %dl                      # if char 'P' analyze as POST request
    je .is_post_request                  # move to POST analyzer if we got P
    movl $1, %eax                        # move 1 aka error into eax
    jmp .request_analysis_done           # move to error exit once error

    .is_get_request:
    # if is GET request

    call Search_Path_Start               # search for the start of the request path
    movb (%eax, %ecx), %dl               # move into %dl the next character
    movl $2, %esi                        # temp move 2 into %esi for cmovel
    cmpb $0x20, %dl                      # if nothing its the root path
    cmovel %esi, %ebx                    # move code 2 "root" into the temp return object if root
    je .request_analysis_done
    movl $3, %esi                        # temp move 3 into %esi for cmovel
    cmpb $0x73, %dl                      # check if it is s which means we are asking for the css
    cmovel %esi, %ebx                    # move code 3 "styles" into the temp return object if styles
    je .request_analysis_done

    movl $1, %ebx                        # move error code 1 into eax if the path is not valid

    jmp .request_analysis_done           # jump once analysis is done
    .is_post_request:                    # we start analyzing the POST request here
    # if is POST request

    call Search_Path_Start               # search for the start of the request path

    movb (%eax, %ecx), %dl               # move into %dl the next character
    cmpb $0x75, %dl                      # check if there is 'u' in the path
    movl $5, %esi                        # temp move 5 into %esi for cmovel
    cmovel %esi, %ebx                    # move code 5 "upload_post" into the temp return object if upload_post
    je .request_analysis_done
    movl $4, %esi                        # temp move 4 into %esi for cmovel
    cmpb $0x70, %dl                      # check if it is 'p' which means we are asking for a post
    cmovel %esi, %ebx                    # move code 4 "posts" into the temp return object if posts
    je .request_analysis_done

    movl $1, %ebx                        # move error code 1 into eax if the path is not valid

    .request_analysis_done:              # label insignifies the end of the procedure
    movl %ebx, %eax                      # move the code into the %eax
    ret

# GET /
# normal get the home page
# GET /styles
# get the page css
# GET /posts/0T10
# get amount of posts from server maximum posts to get is 10.
# T the range of which posts
# POST /upload_post
# Upload a post to the backend

# returns
