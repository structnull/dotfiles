
from typing import List  # noqa: F401
import os
import subprocess
from libqtile import qtile, bar, layout, widget, hook
from libqtile.config import Click, Drag, Group, Key, Match, Screen
from libqtile.command import lazy
from libqtile.lazy import lazy

mod = "mod4"
alt = "mod1"
terminal = "lxterminal"
sysmonitor = "gnome-system-monitor"

# Resize functions for bsp layout
def resize(qtile, direction):
    layout = qtile.current_layout
    child = layout.current
    parent = child.parent
    while parent:
        if child in parent.children:
            layout_all = False

            if (direction == "left" and parent.split_horizontal) or ( direction == "up" and not parent.split_horizontal
            ):
                parent.split_ratio = max(5, parent.split_ratio - layout.grow_amount)
                layout_all = True
            elif (direction == "right" and parent.split_horizontal) or ( direction == "down" and not parent.split_horizontal
            ):
                parent.split_ratio = min(95, parent.split_ratio + layout.grow_amount)
                layout_all = True

            if layout_all:
                layout.group.layout_all()
                break
        child = parent
        parent = child.parent
@lazy.function
def resize_left(qtile):
    resize(qtile, "left")
@lazy.function
def resize_right(qtile):
    resize(qtile, "right")
@lazy.function
def resize_up(qtile):
    resize(qtile, "up")
@lazy.function
def resize_down(qtile):
    resize(qtile, "down")

keys = [
    #essentials
    Key([mod], "Return", lazy.spawn(terminal), desc="Launches My Terminal"),
    # Switch between windows
    Key([mod], "Left", lazy.layout.left(), desc="Move focus to left"),
    Key([mod], "Right", lazy.layout.right(), desc="Move focus to right"),
    Key([mod], "Down", lazy.layout.down(), desc="Move focus down"),
    Key([mod], "Up", lazy.layout.up(), desc="Move focus up"),
    #Key([mod], "n",lazy.layout.next(),desc="Switch focus to other pane of stack"),

    # Move windows between left/right columns or move up/down in current stack.
    # Moving out of range in Columns layout will create new column.
    Key([mod, "shift"], "Left", lazy.layout.shuffle_left(),desc="Move window to the left"),
    Key([mod, "shift"], "Right", lazy.layout.shuffle_right(),desc="Move window to the right"),
    Key([mod, "shift"], "Down", lazy.layout.shuffle_down(),desc="Move window down"),
    Key([mod, "shift"], "Up", lazy.layout.shuffle_up(),desc="Move window up"),
    Key([mod, "shift"], "n",lazy.layout.client_to_next(),desc="move window to next stack"),

    # Grow windows. If current window is on the edge of screen and direction
    # will be to screen edge - window would shrink.
    Key([mod, alt], "Left",resize_left,desc="Grow window to the left"),
    Key([mod, alt], "Right",resize_right,desc="Grow window to the right"),
    Key([mod, alt], "Down",resize_down,desc="Grow window down"),
    Key([mod, alt], "Up",resize_up, desc="Grow window up"),
    Key([mod, alt], "Down", lazy.layout.grow_down()),
    Key([mod, alt], "Up", lazy.layout.grow_up()),
    Key([mod, alt], "Left", lazy.layout.grow_left()),
    Key([mod, alt], "Right", lazy.layout.grow_right()),

    # Rotation of windows
    Key([mod], "r",lazy.layout.rotate(),desc="Rotate windows in Stack mode"),
    Key([mod,"control"], "j",lazy.layout.flip_left(),desc="Flip windows towards left"),
    Key([mod,"control"], "k",lazy.layout.flip_right(),desc="Flip windows towards right"),

    # Toggle between different layouts as defined below
    Key([mod,"shift"], "q", lazy.window.kill(), desc="Kill focused window"),
    Key([mod],"y",lazy.window.toggle_floating(),desc="Toggle floating on focused window",),
    Key([mod,"shift"],"c",lazy.window.toggle_minimize(),desc="Toggle Minimize"),
    Key([mod,"control"], "f", lazy.window.toggle_fullscreen(), desc="Toggle fullscreen"),
    Key([mod], "Tab", lazy.next_layout(),desc="Toggle next layout"),
    Key([mod, "shift"], "Tab", lazy.prev_layout(),desc="Toggle previous layout"),

    # Qtile
    Key([mod, "control"], "r", lazy.restart(), desc="Restart Qtile"),
    Key([mod, "control"], "q", lazy.shutdown(), desc="Shutdown Qtile"),


    # Group Changer
    Key([alt], "F2", lazy.screen.next_group(),desc="Switch to next group"),
    Key([alt], "F1", lazy.screen.prev_group(),desc="Switch to previous group"),
    Key([mod], "u", lazy.next_urgent(),desc="Switch to urgent window"),

]

# Display kebindings in rofi menu
def show_keys(keys):
  """
  print current keybindings in a pretty way for a rofi/dmenu window.
  """
  key_help = ""
  keys_ignored = (
      "XF86AudioMute",  #
      "XF86AudioLowerVolume",  #
      "XF86AudioRaiseVolume",  #
      "XF86AudioPlay",  #
      "XF86AudioNext",  #
      "XF86AudioPrev",  #
      "XF86AudioStop",
  )
  text_replaced = {
      "mod4": "[S]",  #
      "control": "[Ctl]",  #
      "mod1": "[Alt]",  #
      "shift": "[Shf]",  #
      "twosuperior": "²",  #
      "less": "<",  #
      "ampersand": "&",  #
      "Escape": "Esc",  #
      "Return": "Enter",  #
  }
  for k in keys:
    if k.key in keys_ignored:
      continue

    mods = ""
    key = ""
    desc = k.desc.title()
    for m in k.modifiers:
      if m in text_replaced.keys():
        mods += text_replaced[m] + " + "
      else:
        mods += m.capitalize() + " + "

    if len(k.key) > 1:
      if k.key in text_replaced.keys():
        key = text_replaced[k.key]
      else:
        key = k.key.title()
    else:
      key = k.key

    key_line = "{:<30} {}".format(mods + key, desc + "\n")
    key_help += key_line

    # debug_print(key_line)  # debug only

  xbind_keys = [["[S] + Space","Application Launcher"],
                ["[S] + c","Show Clipboard History"],
                ["[S] + =","Open Calculator"],
                ["[S] + Return","Open Terminal"],
                ["[S] + f","Open File Manager"],
                ["[S] + b","Open Browser"],
                ["PrtScr","Fullscreen Screenshot"],
                ["[Ctl] + PrtScr","Screenshot"],
                ]
  for i in xbind_keys:
      key_help += "{:<30} {}".format(i[0],i[1]+"\n")

  return key_help
keys.extend([Key([mod], "F1", lazy.spawn("sh -c 'echo \"" + show_keys(keys) + "\" | rofi -dmenu -i -mesg \"Keyboard shortcuts\"'"), desc="Print keyboard bindings")])

colors = [["#000000","#000000"], # BLACK
          ["#ffffff","#ffffff"], # WHITE
          ["#01fdb0","#01fdb0"], # MINT
          ["#131519","#131519"], # DARK GREY
          ["#46474f","#46474f"], # LIGHT GREY
          ["#ffff55","#ffff55"], # YELLOW
          ["#ff4444","#ff4444"], # SALMON
          ["#2392fb","#2392fb"], # BLUE
          ["#ff5cc6","#ff5cc6"],
          ["#282a36","#282a36"]]

def init_group_names():
    return [("I",{'layout':'bsp'}),
            ("II",{'layout':'bsp'}),
            ("III",{'layout':'bsp'}),
            ("IV",{'layout':'bsp'}),
            ("V",{'layout':'bsp','matches':[Match(wm_class=["discord"])]}),
            ("VI",{'layout':'bsp','matches':[Match(wm_class=["pavucontrol"])]})]

def init_groups():
    return [Group(name,**kwargs) for name, kwargs in group_names]
if __name__ in ["config","__main__"]:
    group_names=init_group_names()
    groups=init_groups()
    group_keycodes = ['KP_End','KP_Down','KP_Next','KP_Left','KP_Begin','KP_Right','KP_Home','KP_Up','KP_Prior']

for i, (name,kwargs) in enumerate(group_names,1):
    keys.append(Key([mod],group_keycodes[i-1],lazy.group[name].toscreen()))
    keys.append(Key([mod],str(i),lazy.group[name].toscreen()))
    keys.append(Key([mod,"shift"],group_keycodes[i-1],lazy.window.togroup(name,switch_group=True)))
    keys.append(Key([mod,"shift"],str(i),lazy.window.togroup(name,switch_group=True)))


layout_theme = {
        "border_width":2,
        "margin":4,
        "border_normal":"131519",
        "border_focus":"818696",
        "grow_amount": 4,
        }
layouts = [
    layout.Bsp(**layout_theme,fair=False,name=''),
    layout.Columns(**layout_theme,name=''),
    layout.Stack(num_stacks=1,margin=4,border_width=0,name='洛'),
   #layout.RatioTile(),
   #layout.Zoomy(),
]

widget_defaults = dict(
    font='JetBrainsMono Nerd Font Medium',
    fontsize=12,
 )
extension_defaults = widget_defaults.copy()

screens = [
    Screen(
        top=bar.Bar(
            [
                widget.Sep(
                    background=colors[0],
                    foreground=colors[0],
                    linewidth=4,
                ),
                widget.GroupBox(
                    font = "Nimbus Sans, Bold",
                    padding=4,
                    margin_y=5,
                    fontsize=16,
                    highlight_color=colors[5],
                    block_highlight_text_color=colors[6],
                    inactive=colors[4],
                    active=colors[1],
                    this_current_screen_border=colors[0],
                    disable_drag=True,
                    this_screen_border=colors[3],
                    other_current_screen_border=colors[3],
                    other_screen_border=colors[3],
                    background=colors[0],
                    urgent_text=colors[5],
                    mouse_callbacks = {'Button1': lambda: None},
                    urgent_border=colors[3],
                    ),
                # widget.Sep(
                #     background=colors[3],
                #     foreground=colors[3],
                #     linewidth=1,
                # ),
                widget.WindowName(
                    padding = 10,
                    background=colors[0],
                    ),
                widget.Sep(
                    background=colors[0],
                    foreground=colors[0],
                    linewidth=8,
                    ),
                widget.Systray(
                    background=colors[0],
                    padding=5,
                    ),
                widget.Sep(
                    background=colors[0],
                    foreground=colors[0],
                    linewidth=8,
                    ),
                widget.TextBox(
                    text = '|',
                    background = colors[0],
                    foreground = colors[4],
                    padding =-3,
                    fontsize = 20,
                       ),
                widget.CurrentLayout(
                    fontsize = 20,
                    foreground = colors[1],
                    padding = 3,
                    background = colors[0],
                ),
                widget.Sep(
                    background=colors[0],
                    foreground=colors[0],
                    linewidth=1,
                    ),
                 widget.TextBox(
                    text = '|',
                    background = colors[0],
                    foreground = colors[4],
                    padding =-3,
                    fontsize = 20,
                    ),
                widget.TextBox(
                    text = "  ",
                    foreground = colors[8],
                    background = colors[0],
                    padding = -3,
                    fontsize = 14,
                    mouse_callbacks = {'Button1': lambda: qtile.cmd_spawn('pavucontrol')},
                    ),
                widget.Volume(
                    background = colors[0],
                    foreground = colors[8],
                    padding = 3,
                    mouse_callbacks = {'Button1': lambda: qtile.cmd_spawn('pavucontrol')},
                ),
                widget.TextBox(
                    text = '|',
                    background = colors[0],
                    foreground = colors[4],
                    padding =-3,
                    fontsize = 20,
                    ),
                widget.TextBox(
                    text = "  ",
                    foreground = colors[2],
                    background = colors[0],
                    padding = 0,
                    mouse_callbacks = {'Button1': lambda: qtile.cmd_spawn(sysmonitor)},
                    fontsize = 12
                    ),
                 widget.CPU(
                    foreground = colors[2],
                    background = colors[0],
                    format = '{load_percent}',
                    mouse_callbacks = {'Button1': lambda: qtile.cmd_spawn(sysmonitor)},
                    padding = 3
                    ),
                widget.TextBox(
                    text = '|',
                    background = colors[0],
                    foreground = colors[4],
                    padding =-3,
                    fontsize = 20,
                    ),
                widget.TextBox(
                    text = "  ",
                    foreground = colors[5],
                    background = colors[0],
                    padding = 0,
                    mouse_callbacks = {'Button1': lambda: qtile.cmd_spawn(terminal + ' -e htop')},
                    fontsize = 12
                    ),
              widget.Memory(
                    measure_mem='M',
                    foreground = colors[5],
                    background = colors[0],
                    format = '{MemUsed:.0f}{mm}',
                    mouse_callbacks = {'Button1': lambda: qtile.cmd_spawn(terminal + ' -e htop')},
                    padding = 3,
                     ),
                 widget.TextBox(
                    text = '|',
                    background = colors[0],
                    foreground = colors[4],
                    padding =-3,
                    fontsize = 20,
                    ),
                widget.TextBox(
                    text = "  ",
                    foreground = colors[7],
                    background = colors[0],
                    padding = 0,
                    fontsize = 12
                    ),
                widget.Clock(
                    foreground=colors[7],
                    background=colors[0],
                    format="%A %B %d - %I:%M:%S %p",
                    ),
                widget.TextBox(
                    text = '|',
                    background = colors[0],
                    foreground = colors[4],
                    padding =-3,
                    fontsize = 20,
                    ),
                widget.QuickExit(
                    default_text=" ",
                    countdown_format="{}",
                    countdown_start=6,
                    foreground=colors[6],
                    background=colors[0],
                    padding=10,
                    mouse_callbacks = {'Button1': lambda: qtile.cmd_spawn('/home/adharsh/.config/rofi/scripts/powermenu.sh'),'Button3': lambda: qtile.cmd_spawn('systemctl poweroff')},
                         ),
            ],
            30,
            opacity=0.6,
            margin=[6,6,2,6],
        ),
        bottom = bar.Gap(2),
        left = bar.Gap(2),
        right = bar.Gap(2),
    ),
]


# Drag floating layouts.
mouse = [
    Drag([mod], "Button1", lazy.window.set_position_floating(),
         start=lazy.window.get_position()),
    Drag([mod], "Button3", lazy.window.set_size_floating(),
         start=lazy.window.get_size()),
    Click([mod], "Button2", lazy.window.bring_to_front()),
]

floating_layout = layout.Floating(
    **layout_theme,
    float_rules=[
    # Run the utility of `xprop` to see the wm class and name of an X client.
    *layout.Floating.default_float_rules,
    Match(wm_type='utility'),
    Match(wm_type='notification'),
    Match(wm_type='toolbar'),
    Match(wm_type='splash'),
    Match(wm_type='dialog'),
    Match(wm_class='file_progress'),
    Match(wm_class='confirm'),
    Match(wm_class='download'),
    Match(wm_class='error'),
    Match(wm_class='notification'),
    Match(wm_class='toolbar'),
    Match(wm_class='confirmreset'),  # gitk
    Match(wm_class='makebranch'),  # gitk
    Match(wm_class='maketag'),  # gitk
    Match(wm_class='ssh-askpass'),  # ssh-askpass
    Match(title='branchdialog'),  # gitk
    Match(title='pinentry'),  # GPG key password entry
    Match(title='Qalculate'),
])

# Configuration Variables
dgroups_key_binder = None
dgroups_app_rules = []  # type: List
follow_mouse_focus = True
bring_front_click = False
cursor_warp = False
auto_fullscreen = True
auto_minimize = False
focus_on_window_activation = "focus"
wmname = "LG3D"

@hook.subscribe.startup_once
def autostart():
    home = os.path.expanduser('~')
    subprocess.call([home+'/.config/qtile/autostart.sh'])


