import os
import subprocess

def move_debug_files():
  debug_files = []

  debug_files = os.listdir("./../gdb_scripts/")

  for dbg_file in debug_files:
    if subprocess.run(["cp", "-a", f"./../gdb_scripts/{dbg_file}", f"./../out/{dbg_file}"], capture_output=True).returncode != 0:
      print(f"error failed to copy {dbg_file}")
      exit(1)
