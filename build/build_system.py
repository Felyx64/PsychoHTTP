from build_system_comp import Comp_logic
from build_system_watch import Start_comp_watch
import sys

scene_info = []
comp_actions = Comp_logic()

dep_res = comp_actions.check_dep_versions()

if not dep_res[0]:
  print("error: you are not on the desired version of GCC, version required is 1521. You are on version, " + dep_res[1])
  exit(1)

def Assemble_Files():
  comp_actions.do_out_dir_cleanup()
  comp_actions.create_new_out_dirs()
  comp_actions.copy_html_code()
  comp_actions.copy_css_code()
  comp_actions.generate_other_files()
  comp_actions.compile_asm_files()

  if comp_actions.error_code == 1:
    print("error something went wrong while assembling or copying the files")

if len(sys.argv) > 1 and sys.argv[1] == "--watch":
  Start_comp_watch(Assemble_Files)
else:
  Assemble_Files()
