import subprocess

root_build_dir = subprocess.run("pwd", cwd="..", text=True)

def check_dep_versions():
  gcc_ver_command = subprocess.run(["gcc", "--version"], capture_output=True, text=True)
  gcc_ver = gcc_ver_command.stdout.splitlines()[0].split()[2]
  gcc_ver_str = gcc_ver
  gcc_ver = gcc_ver.replace(".", "")
  gcc_status = []

  if int(gcc_ver) >= 1521:
    gcc_status = [True, gcc_ver_str]
  else:
    gcc_status = [False, gcc_ver_str]

  return gcc_status

def do_out_dir_cleanup():
  rmout_cmd = subprocess.run(["rm", "-r", "./../out"], capture_output=True)

  if rmout_cmd.returncode != 0:
    return [False]

  return [True]

def create_new_out_dirs():
  sucess_codes = [
    subprocess.run(["mkdir", "./../out"], capture_output=True),
    subprocess.run(["mkdir", "./../out/obj"], capture_output=True),
    subprocess.run(["mkdir", "./../out/content"], capture_output=True),
    subprocess.run(["mkdir", "./../out/content/html"], capture_output=True),
    subprocess.run(["mkdir", "./../out/content/css"], capture_output=True),
    subprocess.run(["mkdir", "./../out/content/js"], capture_output=True)
  ]

  if all(sc.returncode != 0 for sc in sucess_codes):
    return [False]

  return [True]

def copy_html_code():
  cpy_html_cmd = subprocess.run(["cp", "-a", "./../src/frontend/html/", "./../out/content/html"], capture_output=True)

  if cpy_html_cmd.returncode != 0:
    return [False]

  return [True]

def copy_css_code():
  cpy_css_cmd = subprocess.run(["cp", "-a", "./../src/frontend/css/", "./../out/content/css"], capture_output=True)

  if cpy_css_cmd.returncode != 0:
    return [False]

  return [True]

def copy_js_code():
  cpy_js_cmd = subprocess.run(["cp", "-a", "./../src/frontend/js/", "./../out/content/js"], capture_output=True)

  if cpy_js_cmd.returncode != 0:
    return [False]

  return [True]

def compile_asm_files():
  # org ./../src/*.s ./../src/server/*.s ./../src/lib/*.s
  compile_cmd = subprocess.run([
    "gcc -nostdlib -m32 ./../src/home.s"
  ], capture_output=True, text=True, shell=True)

  if compile_cmd.returncode != 0:
    full_errput = compile_cmd.stderr
    full_output = compile_cmd.stdout

    olines = full_output.splitlines()

    log_file_contents = ""

    for oline in olines:
      log_file_contents += oline
      log_file_contents += '\n'

    log_file_contents += "\n\nERRPUT HERE: \n"

    errlines = full_errput.splitlines()

    for errline in errlines:
      log_file_contents += errline
      log_file_contents += '\n'

    with open("./log.txt", "w") as f:
      f.write(log_file_contents)

    return [False]

  return [True]

def do_scene_action(scene):
  return [
    check_dep_versions,
    do_out_dir_cleanup,
    create_new_out_dirs,
    copy_html_code,
    copy_css_code,
    copy_js_code,
    compile_asm_files
  ][scene]()
