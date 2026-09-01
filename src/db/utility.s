.section .data
  ForbiddenChars:
    .ascii "|"

  ReplaceAbleChars:
    .ascii "\n\x1E"

.section .text
  Filter_Forbidden_DB_Chars:
    ret

  ReplaceReplaceable_DB_Chars:
    ret

  Determine_Writer_Size:
    ret

  Parse_WriterType_Id:
    ret
