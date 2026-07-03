import os
import time
import pathlib

# gets all files in src
def get_src_files(dir_route):
  path_str = dir_route if dir_route != "" else "./../src"
  scandir = pathlib.Path(path_str)

  return [str(f) for f in scandir.rglob("*") if f.is_file()]

def get_file_edit_date(files):
    file_edit_times = {}
    for file_path in files:
        file_edit_times[file_path] = os.path.getmtime(file_path)

    return file_edit_times

def compare_file_times(time_x, time_y):
  for file_path in time_x:
    if time_y.get(file_path) != time_x[file_path]:
      return True
  return False

# watch-server config
SRC_DIR = "./../src/"
SCAN_EDIT_INTERVAL = 1

def Start_comp_watch(complogic):
    while True:
        Tracked_Files = get_src_files("./../src")
        old_file_edit_time = get_file_edit_date(Tracked_Files)

        time.sleep(SCAN_EDIT_INTERVAL)

        if compare_file_times(old_file_edit_time, get_file_edit_date(Tracked_Files)):
          print("found changes in a file. Recompiling")
          complogic()


# add file exists check
