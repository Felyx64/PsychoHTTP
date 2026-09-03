from pathlib import Path
import subprocess

class Comp_logic:
  def __init__(self) -> None:
    self.root_build_dir = subprocess.run("pwd", cwd="..", text=True)
    self.error_code = 0

  def check_dep_versions(self):
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

  def do_out_dir_cleanup(self):
    out_dir_path = Path("./../out")
    rootcopy = out_dir_path

    for root, dirs, files in out_dir_path.walk(top_down=False):
      for fname in files:
        (root / fname).unlink()
        for name in dirs:
          if not root == rootcopy:
            (root / name).rmdir()

  def create_new_out_dirs(self):
    sucess_codes = [
      subprocess.run(["mkdir", "./../out"], capture_output=True),
      subprocess.run(["mkdir", "./../out/content"], capture_output=True),
      subprocess.run(["mkdir", "./../out/config"], capture_output=True)
    ]

    if all(sc.returncode != 0 for sc in sucess_codes):
      self.error_code = 1

    self.error_code = 0

  def copy_html_code(self):
    cpy_html_cmd_codes = [
      subprocess.run(["cp", "-a", "./../src/frontend/home.html", "./../out/content/home.html"], capture_output=True),
      subprocess.run(["cp", "-a", "./../src/frontend/403.html", "./../out/content/403.html"], capture_output=True),
    ]

    if all(sc.returncode != 0 for sc in cpy_html_cmd_codes):
      self.error_code = 1

    self.error_code = 0

  def copy_css_code(self):
    cpy_css_cmd = subprocess.run(["cp", "-a", "./../src/frontend/style.css", "./../out/content/style.css"], capture_output=True)

    if cpy_css_cmd.returncode != 0:
      self.error_code = 1

    self.error_code = 0

  def copy_json_files(self):
    sucess_codes = [
      subprocess.run([
        "cp",
        "-a",
        "./../src/frontend/failed_db_status.json",
        "./../out/content/failed_db_status.json"], capture_output=True),
      subprocess.run([
        "cp",
        "-a",
        "./../src/frontend/succesful_db_status.json",
        "./../out/content/succesful_db_status.json"], capture_output=True),
    ]

    if all(sc.returncode != 0 for sc in sucess_codes):
      self.error_code = 1

    self.error_code = 0

  def generate_other_files(self):
    gen_cmd = subprocess.run(
      [
        "touch",
        "./../out/config/filter.txt",
        "./../out/database.txt",
        "./../out/server.log"
      ],
      capture_output=True
    )

    if gen_cmd.returncode != 0:
      self.error_code = 1

    self.error_code = 0

  def compile_asm_files(self):
    # org ./../src/*.s ./../src/server/*.s ./../src/lib/*.s
    compile_cmd = subprocess.run([
      "gcc -g -O0 -nostdlib -msse -m32 ./../src/home.s -o ./../out/server.out"
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

      print("Note: An error accured during the assemble process. error logs can be found in log.txt")

      self.error_code = 1

    self.error_code = 0
