.section .bss
  Database_Write_Data:
    .space 326

.section .text
  QueryUPLOAD_PostToDB:
    ret

  QueryDELETE_PostFromDB:
    # 32-bit/16-bit/8-bit scanner for this to speed up the deletion
    ret

  QuerySELECT_PostFromDB:
    ret

  QeurySELECT_MultiplePostsFromDB:
    # returns last index in case we need to read more
    ret


# format in DB: title, string(64)|description, string(256)
# Stored Item can be maximum and is avarage size of 326 chars
# avarage each entry is a line, each line is the id
# | = End of Text aka 0x02
# , = BELL aka 0x07
# edit in db is get new item and just re-write

# EXAMPLE: B|Post Title|Welcome the this fun post. This post is a example \n
# DECIDERS CAN BE: 8-bit(B), 16-bit(D), 32-bit(I)
# REPLACE \n with 0x1E
# BECAUSE \n means end of index
# | = End of entry of index

# db_connection_id = db connection id
