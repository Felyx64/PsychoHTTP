import os
import subprocess

def move_debug_files():
  debug_files = []

  debug_files = os.listdir("./../other/gdb/")

  x = ""

  for dbg_file in debug_files:
    if subprocess.run(["cp", "-a", f"./../other/gdb/{dbg_file}", f"./../out/{dbg_file}"], capture_output=True).returncode != 0:
      print(f"error failed to copy {dbg_file}")
      exit(1)
