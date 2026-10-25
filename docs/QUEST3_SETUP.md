# Meta Quest 3 + Godot 4 (OpenXR) setup

This project uses Godot’s built-in **OpenXR** module. You do **not** need a separate “Godot VR SDK” package.

**Meta Quest 3** connects as a **PC VR** headset through **Meta Quest Link** (cable) or **Air Link** (Wi‑Fi). Godot runs on the PC and streams to the headset.

> Standalone Quest APK export is **not** configured in this repo yet. Use Link / Air Link from the Godot editor (or a Windows PC export).

---

## What you need

| Item | Notes |
|------|--------|
| Meta Quest 3 (or Quest 3S) | Updated system software |
| Windows PC | Meets [Quest Link requirements](https://www.meta.com/help/quest/articles/headsets-and-accessories/oculus-link/requirements-quest/) |
| Connection | USB‑C Link cable **or** strong 5 GHz / Wi‑Fi 6 for Air Link |
| [Godot 4.4+](https://godotengine.org/download) | Standard (non‑.NET) build is enough |
| This project | Folder with `project.godot` |

---

## 1. Prepare the Quest 3

1. Put on the headset and finish **guardian / boundary** setup.
2. Update the headset: **Settings → System → Software update**.
3. (Recommended for development) Enable **Developer Mode**:
   - Create / log in to a [Meta developer](https://developer.meta.com/) account.
   - In the phone **Meta Horizon** app: **Devices → Headset settings → Developer Mode** → On.
4. Charge Touch Plus controllers and pair them if needed.

---

## 2. Install Meta software on the PC

1. Install the **Meta Horizon** / **Meta Quest** PC app:  
   https://www.meta.com/quest/setup/
2. Log in with the **same Meta account** as on the headset.
3. Allow the app through Windows Firewall if prompted.
4. In the PC app, enable apps from **unknown sources** if you plan to run editor / unsigned builds:
   - **Settings → General → Unknown Sources** (wording may vary by app version).

---

## 3. Connect Quest 3 to the PC

### Option A — Cable (Quest Link)

1. Connect Quest 3 ↔ PC with a high‑quality USB‑C cable (USB 3 recommended).
2. Put on the headset. Accept the **Allow access to data** / USB prompt if shown.
3. Open **Quick Settings** (or the universal menu) → **Quest Link** → enable **Link**.
4. Select your PC and start the Link session.
5. Confirm the headset shows the PC VR home / Link desktop environment.

### Option B — Wireless (Air Link)

1. Put PC and Quest 3 on the **same strong 5 GHz or Wi‑Fi 6** network (avoid crowded 2.4 GHz).
2. In the **Meta Quest PC app**, enable **Air Link**.
3. On the headset: **Quick Settings → Quest Link → Air Link** → select your PC → connect.
4. Prefer PC wired to Ethernet when possible for a more stable stream.

### Option C — Steam Link / Virtual Desktop (optional)

Third‑party PC VR bridges can work if they expose a working **OpenXR** runtime to Windows. For this project, **Meta Quest Link / Air Link** is the supported path.

---

## 4. Set Meta as the active OpenXR runtime

Godot uses whichever OpenXR runtime Windows currently has active.

1. Keep the **Link / Air Link session running**.
2. In the Meta Quest PC app, set Meta as the OpenXR runtime if the option is available (often under **Settings → General → OpenXR Runtime** or similar).
3. If **SteamVR** is installed, quit SteamVR so it does not steal the OpenXR runtime.

**Quick check (Windows):**

- `%LOCALAPPDATA%\openxr\1\active_runtime.json` should point at Meta’s OpenXR runtime while Link is active.

---

## 5. Open this game in Godot

1. Launch **Godot 4.4+**.
2. Import / open this project (`project.godot`).
3. Confirm OpenXR is on:
   - **Project → Project Settings → XR → OpenXR → Enabled** = **On**  
   - Already enabled in this repository under `[xr]` in `project.godot`.
4. Keep Quest 3 in an active Link / Air Link session.
5. Press **F5** (Play the main scene).

What happens next (see `scripts/autoload/xr_manager.gd`):

1. Godot finds the **OpenXR** interface.
2. It starts an XR session and sets `viewport.use_xr = true`.
3. The player switches to VR (headset camera + hand controllers).

If OpenXR is unavailable, the game automatically falls back to **PC first‑person** mode.

---

## 6. Do **not** use these for VR

| Command / habit | Why |
|-----------------|-----|
| `./run_pc.sh` | Forces `--xr-mode off` (PC only) |
| `godot --xr-mode off ...` | Disables XR on purpose |
| Starting Play before Link connects | Often stays in flat PC mode or shows a black headset view |

Start **Link first**, then press **F5** in Godot.

---

## 7. In‑game VR controls (this project)

| Action | Quest 3 controllers |
|--------|---------------------|
| Move | Left thumbstick |
| Turn | Right thumbstick |
| Make a snowball | Grip or Trigger while the hand is near the snow |
| Throw | Release Grip / Trigger |

---

## 8. Troubleshooting

| Problem | What to try |
|---------|-------------|
| Game stays in mouse / WASD mode | Link/Air Link not active; Meta not the OpenXR runtime; check Godot Output for `OpenXR` / `No OpenXR runtime` |
| Black screen in headset | Start Play **after** Link is connected; try a cable instead of Air Link; restart Meta app + Godot |
| Controllers missing or frozen | Re‑center view; replace controller batteries/charge; restart Link |
| Tracking jitter (Air Link) | Move closer to router; use 5 GHz/Wi‑Fi 6; Ethernet on PC; close bandwidth‑heavy apps |
| Godot fails to initialize OpenXR | Quit SteamVR; set Meta as OpenXR runtime; reboot PC; reconnect Link |
| “Unknown sources” blocked | Enable unknown sources in Meta PC app for editor / dev builds |

---

## 9. Project‑specific notes

- OpenXR is enabled in `project.godot` (`[xr] openxr/enabled=true`).
- XR boot logic: `scripts/autoload/xr_manager.gd`.
- Player VR rig: `scenes/player/player.tscn` (`XROrigin3D`, `XRCamera3D`, hand controllers).
- Quest 2 users: see also [`QUEST2_SETUP.md`](QUEST2_SETUP.md) (same OpenXR idea; this Quest 3 guide matches current Meta Horizon / Link UI naming).

---

## Official references

- Godot XR setup: https://docs.godotengine.org/en/stable/tutorials/xr/setting_up_xr.html
- Godot OpenXR: https://docs.godotengine.org/en/stable/tutorials/xr/openxr_introduction.html
- Meta Quest Link: https://www.meta.com/help/quest/articles/headsets-and-accessories/oculus-link/connect-with-quest-link/
- Air Link: https://www.meta.com/help/quest/articles/headsets-and-accessories/oculus-link/connect-with-air-link/
