from build_system_graphics import gui_screen
from build_system_comp import do_scene_action
from build_system_input import get_input_handler

# initialize the tui
compiler_tui = gui_screen()
# display the startup countdown
compiler_tui.startup_message()

tui_loop = True
render_scene = 0
scene_info = []

while tui_loop:
  last_scene = render_scene

  compiler_tui.display_standard_screen_graphics()
  scene_info = do_scene_action(render_scene)
  compiler_tui.render_variable_graphics(render_scene, scene_info)
  user_input = compiler_tui.wait_for_input()
  render_scene = get_input_handler(render_scene, [user_input, render_scene, scene_info[0]])

  if render_scene == 6 or user_input == 27:
    tui_loop = False

  if last_scene != render_scene:
    scene_info.clear()


compiler_tui.exit()
