# Finger Block — installing it on your phone

Five files, no build step, no dependencies. Put them in a repo and turn on GitHub Pages.

```
index.html
manifest.json
sw.js
icon-180.png
icon-192.png
icon-512.png
icon-512-maskable.png
```

## Deploy

1. New GitHub repo — `finger-block`. Public is fine (there's nothing sensitive; your log lives on your phone, not in the repo).
2. Drag all the files into the repo root. **Root, not a subfolder** — the service worker's scope depends on it.
3. Settings → Pages → Source: *Deploy from a branch* → `main` / `(root)` → Save.
4. Wait ~60 seconds. Your URL will be `https://<your-username>.github.io/finger-block/`.

HTTPS matters here: service workers and "add to home screen" both refuse to run over plain HTTP. GitHub Pages gives you HTTPS automatically.

## Install

**iOS (Safari only — Chrome on iOS can't do this):**
Open the URL → Share → Add to Home Screen.

**Android (Chrome):**
Open the URL → ⋮ menu → Install app, or Add to Home screen.

Either way it launches full-screen with no browser chrome, and the service worker caches everything on first load — so it works in a basement gym with no signal.

## Where your data lives

`localStorage`, on that device, under the key `fingerblock:v1`. Consequences worth knowing before you start:

- **It does not sync.** Phone and laptop keep separate logs.
- **It does not transfer from the Claude artifact version.** Pick one and start there. Since you haven't logged a session yet, this is a free choice.
- **Clearing site data wipes it.** Use the Export JSON button occasionally — that's your backup.
- iOS may evict localStorage for a home-screen web app that goes ~7 days unused. You'll be opening it three times a week, so this shouldn't bite, but export before any long break.

## Changing it later

Edit `index.html`, then bump the cache name in `sw.js`:

```js
const CACHE = "fingerblock-v1";   →   "fingerblock-v2"
```

Without that bump the service worker keeps serving the old cached copy and you'll swear your edit didn't work. Your logged data survives the update — it's in localStorage, not the cache.

The session definitions are in one array near the top of the script, labelled `const SESSIONS`. Each entry is one session; the phases are defined just below it in `PHASES`. That's the only place you need to touch to change the program.
