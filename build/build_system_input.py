def handle_dependency_input(input_handler_info):
  if input_handler_info[0] == 10 and input_handler_info[2]:
    input_handler_info[1] += 1
    return input_handler_info[1]
  else:
    return input_handler_info[1]

# this really just does transition to next scene rather than input :/
def handle_out_cleanup_input(input_handler_info):
  if input_handler_info[2]:
    input_handler_info[1] += 1
    return input_handler_info[1]
  else:
    return input_handler_info[1]

def handle_out_creation_input(input_handler_info):
  if input_handler_info[2]:
    input_handler_info[1] += 1
    return input_handler_info[1]
  else:
    return input_handler_info[1]

def handle_Html_copyproc_input(input_handler_info):
  if input_handler_info[2]:
    input_handler_info[1] += 1
    return input_handler_info[1]
  else:
    return input_handler_info[1]

def handle_Css_copyproc_input(input_handler_info):
  if input_handler_info[2]:
    input_handler_info[1] += 1
    return input_handler_info[1]
  else:
    return input_handler_info[1]

def handle_assemble_input(input_handler_info):
  if input_handler_info[2]:
    input_handler_info[1] += 1
    return input_handler_info[1]
  else:
    return input_handler_info[1]

def get_input_handler(scene, input_handler_info):
  return [
    handle_dependency_input,
    handle_out_cleanup_input,
    handle_out_creation_input,
    handle_Html_copyproc_input,
    handle_Css_copyproc_input,
    handle_assemble_input
  ][scene](input_handler_info)
