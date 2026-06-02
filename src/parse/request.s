.section .text
  Analyze_Request:
    leal SCOM_User_Server_Request, %eax

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
