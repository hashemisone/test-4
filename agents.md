Godot binary: "C:\Program Files (x86)\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64.exe"

Godot is not on PATH. Call that binary. It is 4.6.2. A working project to copy file shape from is `C:/Users/softb/Desktop/coding/github/godot/2d jumping game/2d-jumping-game`.

## Commit and push before reporting back

This is for every folder you change, not only this one. Any bot using this file does it before coming back.

1. If the folder you changed is not a git repository, make it one with `git init -b main`.
2. Commit the file changes. Leave a Godot `.godot/` folder untracked. Do not commit secrets or credentials.
3. Push. If the repo already has a remote, push the current branch. If it has no remote, create a GitHub repository for the signed-in account `hashemisone` and push `main` there. Do not force-push.

`git push` on this machine can sit forever on Git Credential Manager's browser sign-in. GitHub Desktop is installed and signed in. Use the saved Windows credential `GitHub - https://api.github.com/hashemisone` as the git username and password instead of waiting on the browser. Do not print the token. PowerShell will not run a script file unless you start it with `-ExecutionPolicy Bypass`.

This Snake project is already a repo: branch `main`, remote `origin`, https://github.com/hashemisone/test-2.git.

## Make a project Godot will show

A folder with `project.godot` does not appear in the Project Manager by itself. This machine's list is `%APPDATA%\Godot\projects.cfg`, and Godot has only been scanning `C:/Users/softb/Desktop/coding/github/godot/`.

1. Close Godot first. If it is open, it loaded the old list and will overwrite `projects.cfg` on exit.
2. Create the project folder and `project.godot` (see below).
3. Append the project folder to `projects.cfg`. Forward slashes, one section per project:

```
[C:/Users/softb/Desktop/coding/grok build/test 2]

favorite=false
```

4. Start Godot again. The name in `config/name` is what the list shows.

Use Forward Plus and D3D12, the same as the jumping game. A GL Compatibility project runs on the wrong renderer here.

```
config_version=5

[application]

config/name="Game Name"
run/main_scene="res://main.tscn"
config/features=PackedStringArray("4.6", "Forward Plus")

[display]

window/size/viewport_width=640
window/size/viewport_height=480
window/stretch/mode="canvas_items"

[rendering]

rendering_device/driver.windows="d3d12"
```

## Scenes and scripts

Match 4.6 text scenes. `load_steps` is obsolete. Give every script a sibling `.gd.uid` file, one line. A scene saved by the editor cites that same id:

`main.gd.uid`

```
uid://c3s6dyam0an2d
```

`main.tscn`

```
[gd_scene format=3 uid="uid://b2aqiq146qnk6"]

[ext_resource type="Script" uid="uid://c3s6dyam0an2d" path="res://main.gd" id="1_main"]

[node name="Main" type="Node2D" unique_id=835674020]
script = ExtResource("1_main")
```

Use a fresh uid for each file. A valid id is `uid://` plus 13 characters, the same shape as the jumping game. Do not invent one from the file name.

When you write a scene by hand, omit the `uid` attribute on `ext_resource` and keep the path. Godot adds the uid the next time the editor saves the scene. Citing a uid that this project has not imported yet aborts a headless `load()` of that scene. The log line `invalid UID ... using text path instead` is not a safe fallback.

## Instance separate scenes

Put each part in its own folder and scene. The main scene instances those scenes. It does not rebuild their nodes. In this project that is `board/board.tscn`, `snake/snake.tscn`, `food/food.tscn`, and `hud/hud.tscn`.

A part scene is a normal scene. Its root name is the name the parent will use. HUD roots are `CanvasLayer`. Anything that should be visible in the editor is a real node, not only `_draw()`.

`snake/snake.tscn`

```
[gd_scene format=3 uid="uid://<fresh>"]

[ext_resource type="Script" path="res://snake/snake.gd" id="1_snake"]

[node name="Snake" type="Node2D"]
script = ExtResource("1_snake")

[node name="Head" type="ColorRect" parent="."]
offset_left = 161.0
offset_top = 241.0
offset_right = 179.0
offset_bottom = 259.0
mouse_filter = 2
color = Color(0.64, 1, 0.5, 1)
```

`main.tscn` lists each part as a `PackedScene`, then instances it. Sibling order is draw order: later nodes draw on top. Put the HUD last.

```
[gd_scene format=3 uid="uid://<fresh>"]

[ext_resource type="Script" path="res://main.gd" id="1_main"]
[ext_resource type="PackedScene" path="res://board/board.tscn" id="2_board"]
[ext_resource type="PackedScene" path="res://snake/snake.tscn" id="3_snake"]
[ext_resource type="PackedScene" path="res://food/food.tscn" id="4_food"]
[ext_resource type="PackedScene" path="res://hud/hud.tscn" id="5_hud"]

[node name="Main" type="Node2D"]
script = ExtResource("1_main")

[node name="Board" parent="." instance=ExtResource("2_board")]

[node name="Snake" parent="." instance=ExtResource("3_snake")]

[node name="Food" parent="." instance=ExtResource("4_food")]

[node name="HUD" parent="." instance=ExtResource("5_hud")]
```

The `name` on the instance line is the node name in the parent. The parent script keeps the rules and calls the parts by that name:

```
@onready var snake_view = $Snake
@onready var food_view = $Food
@onready var hud = $HUD
```

Each part script only draws and exposes methods (`show_cells`, `grow`, `show_cell`, `show_scores`). Nodes created in code go on the part that should own their draw order. New snake segments are children of the Snake node, so Food still draws above them.

To spawn another copy of the same scene at runtime, load the packed scene, instance it, then add it. Godot 4.6 cannot infer the type of `load().instantiate()`, so do not use `:=` on that call.

```
var packed = load("res://food/food.tscn")
var node = packed.instantiate()
add_child(node)
```

Do not define `hide()` or `show()` on a script that extends `CanvasItem` (`Node2D`, `ColorRect`, and so on). Godot treats that override as an error and the scene fails to load. Name the method `hide_food()` or similar. Do not put `@tool` on a script that only draws in `_draw()`. It runs during load and can abort a headless open.

Nodes drawn only in `_draw()` stay invisible in the editor. Put real nodes in the `.tscn` so the 2D view shows the scene before F5. Set `mouse_filter = 2` on full-screen Control nodes so they do not eat arrow keys.

## Use sprites and images

For any game, use a sprite or image for as many visuals as possible: characters, creatures, items, terrain, scenery, backgrounds, and UI frames and buttons. Save the pictures as PNGs under `res://art/` and show them with `Sprite2D`, `AnimatedSprite2D`, `TextureRect`, or `NinePatchRect`.

A `ColorRect` is only for a flat wash that is not a picture, such as a dim behind a panel. The `ColorRect` in the scene example above is only there to show the node shape.

Keep words that change, or that the game will translate, in a `Label` or on a `Button`. Do not paint those words into the image.

Keep a collision shape at the size gameplay needs. The picture can be a little larger than the hit box. Line the picture up with that shape, such as a character's feet on the bottom of the collision. Draw a side-view character facing right, and flip the visual when it faces left.

When a node is scaled to cover a long or tall area, repeat a tile. Do not stretch one picture across that area. A cap, border, or lip stays a fixed size while the repeating part fills the rest. If something moves, give it more than one frame.

## Check it

From the project folder, using the binary above:

- Import: `--headless --path "<project dir>" --import --quit`
- Parse the script: `--headless --path "<project dir>" --check-only --quit --script res://main.gd`
- Boot the game: `--path "<project dir>" --quit-after 30`

Read the log. A clean boot prints the D3D12 / Forward+ device line and no script errors. The first Forward+ launch compiles shaders, so a window can stay blank for a bit. `--quit-after` of only a few frames can exit during that compile and prove nothing.
