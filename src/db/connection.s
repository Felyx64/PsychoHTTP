.section .text
  ConnectDB:
    ret

  DisconnectDB:
    ret

  UploadPostToDB:
    ret

  DeletePostFromDB:
    ret

  SelectPostFromDB:
    ret

  GetMultiplePostsFromDB:
    ret

# format in DB: title, string(50)|description, string(250)
# Stored Item can be maximum and is avarage size of 300 chars
# avarage each entry is a line, each line is the id
# | = End of Text aka 0x02
# , = BELL aka 0x07
# edit in db is get new item and just re-write
