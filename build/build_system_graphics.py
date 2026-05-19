import curses

class gui_screen:
  def __init__(self) -> None:
    self.stdscr = curses.initscr()
    if curses.has_colors():
      self.stdscr.clear()
      self.stdscr.keypad(True)

      self.user_input_value = 0

      self.stdscr.nodelay(False)

      curses.start_color()
      curses.use_default_colors()
      curses.init_pair(1, curses.COLOR_BLACK, curses.COLOR_WHITE)
      curses.init_pair(2, curses.COLOR_WHITE, curses.COLOR_BLACK)
      curses.init_pair(3, curses.COLOR_RED, curses.COLOR_BLACK)
      curses.init_pair(4, curses.COLOR_GREEN, curses.COLOR_BLACK)
      curses.set_escdelay(1)
      curses.noecho()
      curses.cbreak()
    else:
      self.exit()
      print("Please run this program on a terminal that allows the display of colors...")
      exit(1)
    pass

  def exit(self):
    curses.endwin()
    pass

  def startup_message(self):
    seconds_to_wait = 3

    while seconds_to_wait != 0:
      self.stdscr.addstr(5, 5, "starting build system in: " + str(seconds_to_wait))
      self.stdscr.refresh()

      seconds_to_wait = seconds_to_wait - 1
      self.stdscr.clear()

    pass

  def wait_for_input(self):
    curses.flushinp()
    return self.stdscr.getch()

  def display_standard_screen_graphics(self):
    self.stdscr.clear();
    self.stdscr.box()
    self.stdscr.attron(curses.color_pair(2))
    self.stdscr.addstr(self.stdscr.getmaxyx()[0] - 1, 20, "ESC: exit the build system")
    self.stdscr.addstr(self.stdscr.getmaxyx()[0] - 1, 60, "ENTER: Next step in the build system")
    self.stdscr.attroff(curses.color_pair(2))
    pass

  def display_dependency_check_screen(self, scene_info):
    self.stdscr.attron(curses.A_BOLD)
    self.stdscr.addstr(3, 20, "Checking if correct dependencies are installed: ")
    self.stdscr.attroff(curses.A_BOLD)

    if scene_info[0]:
      self.stdscr.attron(curses.color_pair(4))
      self.stdscr.addstr(5, 20, "[V]")
      self.stdscr.attroff(curses.color_pair(4))

      self.stdscr.attron(curses.color_pair(2))
      self.stdscr.addstr(5, 24, "Correct gcc compiler version installed! (" + scene_info[1] + ")")
      self.stdscr.attroff(curses.color_pair(2))
    else:
      self.stdscr.attron(curses.color_pair(3))
      self.stdscr.addstr(5, 20, "[X]")
      self.stdscr.attroff(curses.color_pair(3))

      self.stdscr.attron(curses.color_pair(2))
      self.stdscr.addstr(5, 24, "Err: compiler version not new enough, minimum version is (15.2.1)")
      self.stdscr.attroff(curses.color_pair(2))

    pass

  def display_out_dir_cleanup(self, scene_info):
    self.stdscr.attron(curses.A_BOLD)
    self.stdscr.addstr(3, 20, "Checking if out-dir cleanup was done well: ")
    self.stdscr.attroff(curses.A_BOLD)

    if scene_info[0]:
      self.stdscr.attron(curses.color_pair(4))
      self.stdscr.addstr(5, 20, "[V]")
      self.stdscr.attroff(curses.color_pair(4))

      self.stdscr.attron(curses.color_pair(2))
      self.stdscr.addstr(5, 24, "The out directory has been cleaned correctly")
      self.stdscr.attroff(curses.color_pair(2))
    else:
      self.stdscr.attron(curses.color_pair(3))
      self.stdscr.addstr(5, 20, "[X]")
      self.stdscr.attroff(curses.color_pair(3))

      self.stdscr.attron(curses.color_pair(2))
      self.stdscr.addstr(5, 24, "Err: something went wrong with cleanup on /out")
      self.stdscr.attroff(curses.color_pair(2))

  def display_new_dir_creation(self, scene_info):
    self.display_out_dir_cleanup([True])

    self.stdscr.attron(curses.A_BOLD)
    self.stdscr.addstr(7, 20, "Checking if out-dir cleanup was done well: ")
    self.stdscr.attroff(curses.A_BOLD)

    if scene_info[0]:
      self.stdscr.attron(curses.color_pair(4))
      self.stdscr.addstr(9, 20, "[V]")
      self.stdscr.attroff(curses.color_pair(4))

      self.stdscr.attron(curses.color_pair(2))
      self.stdscr.addstr(9, 24, "Successfully created a new out directory")
      self.stdscr.attroff(curses.color_pair(2))
    else:
      self.stdscr.attron(curses.color_pair(3))
      self.stdscr.addstr(9, 20, "[X]")
      self.stdscr.attroff(curses.color_pair(3))

      self.stdscr.attron(curses.color_pair(2))
      self.stdscr.addstr(9, 24, "Err: something wont wrong creating a new out directory")
      self.stdscr.attroff(curses.color_pair(2))

  def display_html_copy_status(self, scene_info):
    self.stdscr.attron(curses.A_BOLD)
    self.stdscr.addstr(2, 10, "Checking if html copying process was succesfull: ")
    self.stdscr.attroff(curses.A_BOLD)

    if scene_info[0]:
      self.stdscr.attron(curses.color_pair(4))
      self.stdscr.addstr(3, 10, "[V]")
      self.stdscr.attroff(curses.color_pair(4))

      self.stdscr.attron(curses.color_pair(2))
      self.stdscr.addstr(3, 14, "HTML files where succesfully copied")
      self.stdscr.attroff(curses.color_pair(2))
    else:
      self.stdscr.attron(curses.color_pair(3))
      self.stdscr.addstr(3, 10, "[X]")
      self.stdscr.attroff(curses.color_pair(3))

      self.stdscr.attron(curses.color_pair(2))
      self.stdscr.addstr(3, 14, "Err: something wont wrong with the HTML copying process")
      self.stdscr.attroff(curses.color_pair(2))

  def display_css_copy_status(self, scene_info):
    self.display_html_copy_status([True])

    self.stdscr.attron(curses.A_BOLD)
    self.stdscr.addstr(5, 10, "Checking if css copying process was succesfull: ")
    self.stdscr.attroff(curses.A_BOLD)

    if scene_info[0]:
      self.stdscr.attron(curses.color_pair(4))
      self.stdscr.addstr(6, 10, "[V]")
      self.stdscr.attroff(curses.color_pair(4))

      self.stdscr.attron(curses.color_pair(2))
      self.stdscr.addstr(6, 14, "CSS files where succesfully copied")
      self.stdscr.attroff(curses.color_pair(2))
    else:
      self.stdscr.attron(curses.color_pair(3))
      self.stdscr.addstr(6, 10, "[X]")
      self.stdscr.attroff(curses.color_pair(3))

      self.stdscr.attron(curses.color_pair(2))
      self.stdscr.addstr(6, 14, "Err: something wont wrong with the CSS copying process")
      self.stdscr.attroff(curses.color_pair(2))

  def display_js_copy_status(self, scene_info):
    self.display_html_copy_status([True])
    self.display_css_copy_status([True])

    self.stdscr.attron(curses.A_BOLD)
    self.stdscr.addstr(8, 10, "Checking if js copying process was succesfull: ")
    self.stdscr.attroff(curses.A_BOLD)

    if scene_info[0]:
      self.stdscr.attron(curses.color_pair(4))
      self.stdscr.addstr(9, 10, "[V]")
      self.stdscr.attroff(curses.color_pair(4))

      self.stdscr.attron(curses.color_pair(2))
      self.stdscr.addstr(9, 14, "JS files where succesfully copied")
      self.stdscr.attroff(curses.color_pair(2))
    else:
      self.stdscr.attron(curses.color_pair(3))
      self.stdscr.addstr(9, 10, "[X]")
      self.stdscr.attroff(curses.color_pair(3))

      self.stdscr.attron(curses.color_pair(2))
      self.stdscr.addstr(9, 14, "Err: something went wrong with the JS copying process")
      self.stdscr.attroff(curses.color_pair(2))

  def display_compile_status(self, scene_info):
    self.stdscr.attron(curses.A_BOLD)
    self.stdscr.addstr(2, 10, "Checking if assemble process was sucessfull: ")
    self.stdscr.attroff(curses.A_BOLD)

    if scene_info[0]:
      self.stdscr.attron(curses.color_pair(4))
      self.stdscr.addstr(3, 10, "[V]")
      self.stdscr.attroff(curses.color_pair(4))

      self.stdscr.attron(curses.color_pair(2))
      self.stdscr.addstr(3, 14, "Assembly files where succesfully assembled!")
      self.stdscr.attroff(curses.color_pair(2))
    else:
      self.stdscr.attron(curses.color_pair(3))
      self.stdscr.addstr(3, 10, "[X]")
      self.stdscr.attroff(curses.color_pair(3))

      self.stdscr.attron(curses.color_pair(2))

      self.stdscr.addstr(3, 14, "Err: something wont wrong with the Assemble process")

      self.stdscr.attron(curses.A_UNDERLINE)
      self.stdscr.addstr(5, 14, "logs where sent to ./log.txt")
      self.stdscr.attroff(curses.A_UNDERLINE)

      self.stdscr.attron(curses.color_pair(2))


  def render_variable_graphics(self, scene, scene_info):
    [
      self.display_dependency_check_screen,
      self.display_out_dir_cleanup,
      self.display_new_dir_creation,
      self.display_html_copy_status,
      self.display_css_copy_status,
      self.display_js_copy_status,
      self.display_compile_status
    ][scene](scene_info)

    pass
