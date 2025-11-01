# UIStrokeScaler — yet another UIStroke scale implementation
* 🔥 Blazingly fast
* ⬇️ Minimal memory impact
* 🤝 Convenient plugin tools
* ♻️ Supports runtime changes & Instance recycling

[Get the latest release here](https://github.com/ishtar112/ui-stroke-scaler/releases/tag/stable) • [Install the plugin](https://github.com/ishtar112/ui-stroke-scaler/releases/download/stable/UIStrokeScaler.rbxm) • [Install the demo](https://github.com/ishtar112/ui-stroke-scaler/releases/download/stable/UIStrokeScalerDemo.rbxl)

# How to Install
1. [Download the .rbxmx](https://github.com/ishtar112/ui-stroke-scaler/releases/download/stable/UIStrokeScaler.rbxmx)
2. Install it as a Local Plugin in Roblox Studio

Do **not** copy and paste the raw source code — the client script is meant to be installed by the plugin.

# Usage
* **Inserting the client script** — the `Insert` button will insert a copy of the client script into `StarterPlayerScripts`; you are welcome to put the script anywhere you want as long as you put it somewhere it can run
* **Caching UIStrokes** — the plugin provides a handful of different ways to cache UIStrokes:
  * **Selection** — caches any selected UIStrokes
  * **Descendants** — caches any UIStrokes that are descendants of any selected Instances
  * **StarterGui** — caches all UIStrokes that are descendants of `StarterGui`
  * **All** — caches all UIStrokes in the game
  * **Cached** — updates all UIStrokes that have already been cached
* **Setting Thickness scale** — set the `Parent` to the desired size, then set the desired UIStroke `Thickness`, and cache the `UIStroke` using any of the ways mentioned above: the `UIStroke` will automatically adjust its `Thickness` as its `Parent` changes size during gameplay
  * ‼️ **When testing different devices when editing in Studio, UIStrokes will look weird**; UIStrokes only resize at runtime
* **Removing UIStrokes** — UIStrokes can be easily removed from the auto-adjuster at any time: just remove the `@scale` tag from the UIStroke, or use the `Clear` plugin button to instantly un-cache **all** UIStrokes
