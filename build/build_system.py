from build_system_comp import Comp_logic
from build_system_watch import Start_comp_watch
from build_system_debug import move_debug_files

import argparse

scene_info = []
comp_actions = Comp_logic()

dep_res = comp_actions.check_dep_versions()

if not dep_res[0]:
  print("error: you are not on the desired version of GCC, version required is 1521. You are on version, " + dep_res[1])
  exit(1)

def assemble_files():
  comp_actions.do_out_dir_cleanup()
  comp_actions.create_new_out_dirs()
  comp_actions.copy_html_code()
  comp_actions.copy_css_code()
  comp_actions.generate_other_files()
  comp_actions.compile_asm_files()

  if comp_actions.error_code == 1:
    print("error something went wrong while assembling or copying the files")

def Compile_With_Debug():
  assemble_files()
  move_debug_files()

def main():
  arguement_parser = argparse.ArgumentParser()

  arguement_parser.add_argument("--debug", action="store_true")
  arguement_parser.add_argument("--watch", action="store_true")
  arguement_parser.add_argument("--only-debug", action="store_true")

  arg_result = arguement_parser.parse_args()

  procedure_to_do = assemble_files()

  if arg_result.debug:
    procedure_to_do = Compile_With_Debug

  if arg_result.only_debug:
    procedure_to_do = move_debug_files

  if arg_result.watch:
    procedure_to_do = Start_comp_watch

  procedure_to_do()


if __name__ == "__main__":
  main()
