# Meta Quest 2 + Godot 4 (OpenXR) setup

This project uses Godot’s built-in **OpenXR** (no separate “Godot VR SDK” package).  
Quest 2 connects through a PC OpenXR runtime (usually **Meta Quest Link**).

## What you need

- Meta Quest 2
- PC that meets [Quest Link requirements](https://www.meta.com/help/quest/articles/headsets-and-accessories/oculus-link/requirements-quest/)
- USB-C Link cable **or** Air Link (Wi‑Fi 5/6 recommended)
- [Godot 4.4+](https://godotengine.org/download) (standard build)
- This project folder (`project.godot`)

## 1. Prepare the Quest 2

1. Update Quest system software.
2. Enable developer options (optional but useful):
   - Create/login to a Meta developer account
   - On headset: **Settings → System → Developer** → enable developer mode
3. Put on the headset and complete guardian/boundary setup.

## 2. Install Meta software on PC

1. Install **Meta Quest app** (formerly Oculus PC app):  
   https://www.meta.com/quest/setup/
2. Log in with the same Meta account as the headset.
3. Enable unknown sources if prompted (needed for editor/dev apps).

## 3. Connect Quest 2 to the PC

### Option A — Cable (Quest Link)

1. Connect Quest 2 ↔ PC with a high-quality USB-C cable.
2. In the headset popup, enable **Link**.
3. Confirm the headset appears as connected in the Meta Quest PC app.

### Option B — Wireless (Air Link)

1. PC and Quest on the same strong 5 GHz Wi‑Fi.
2. In Meta Quest PC app: enable **Air Link**.
3. On headset: **Quick Settings → Quest Link → Air Link** → select your PC.

## 4. Make OpenXR use Meta’s runtime

Godot talks to whatever OpenXR runtime is active on the PC.

1. Open **Meta Quest PC app**.
2. Ensure Link/Air Link session is active (headset in PC VR mode).
3. Meta’s OpenXR runtime should become the active runtime while Link is running.

Check (Windows):

- Settings related to OpenXR in the Meta app, or  
- `%LOCALAPPDATA%\openxr\1\active_runtime.json` points at Meta’s runtime

Check (Linux — less common for Quest Link):

- `~/.config/openxr/1/active_runtime.json`

If SteamVR is also installed, temporarily quit SteamVR so Meta remains the active OpenXR runtime.

## 5. Open this game in Godot

1. Launch **Godot 4.4+**.
2. Import / open this project (`project.godot`).
3. Confirm OpenXR is enabled:
   - **Project → Project Settings → XR → OpenXR → Enabled** = On  
   - (Already set in this repo.)
4. Keep the headset on and Link/Air Link connected.
5. Press **F5** (Play main scene).

`XRManager` will:

- find the OpenXR interface
- start the XR session
- switch the player to VR hands + stick locomotion

If OpenXR is missing/unavailable, the game falls back to PC first-person mode automatically.

## 6. VR controls in this game

| Action | Quest controllers |
|---|---|
| Move | Left thumbstick |
| Turn | Right thumbstick |
| Make snowball | Grip or Trigger near the snow ground |
| Throw | Release Grip/Trigger |

## Troubleshooting

| Problem | What to try |
|---|---|
| Game stays in PC/mouse mode | Link/Air Link not active; OpenXR runtime not Meta; check Godot console for `OpenXR` / `No OpenXR runtime` warnings |
| Black screen in headset | Start Play **after** Link is connected; disable VRS/experimental GPU features; try cable instead of Air Link |
| Controllers not tracking | Re-center in Quest; ensure controllers charged; restart Link session |
| Godot can’t initialize OpenXR | Close SteamVR; relaunch Meta app + Link; restart Godot |
| Using `--xr-mode off` or `./run_pc.sh` | Those force PC mode — don’t use them for VR |

## Notes specific to this project

- There is **no extra Godot XR plugin** to install for this repo.
- OpenXR is enabled in `project.godot` under `[xr]`.
- Startup logic lives in `scripts/autoload/xr_manager.gd`.
- Exporting a standalone `.apk` for standalone Quest play is **not** set up yet — current VR path is **PC VR via Link/Air Link** while running from the Godot editor (or a Windows/Linux export).

## Official references

- Godot OpenXR: https://docs.godotengine.org/en/stable/tutorials/xr/setting_up_xr.html
- Meta Quest Link: https://www.meta.com/help/quest/articles/headsets-and-accessories/oculus-link/connect-with-quest-link/
