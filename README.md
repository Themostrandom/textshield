# TextShield

TextShield is a Lua-based **anti-spam and chat moderation mod** for [Minetest](https://www.minetest.net/). It provides tools to automatically filter, detect, and block spam, excessive capitalization, and offensive words in multiple languages, helping to maintain a healthy and enjoyable multiplayer environment.

---

## Features

* **Anti-spam protection**: Blocks repeated or rapid messages.
* **Caps filter**: Detects and prevents excessive use of capital letters.
* **Profanity filter**: Includes badword lists in multiple languages (`ar`, `de`, `en`, `es`, `fr`, `it`, `ja`, `ko`, `ru`, `zh`).
* **History tracking**: Keeps a record of messages to better detect spam patterns.
* **Configurable settings**: Adjustable parameters via `settingtypes.txt`.
* **Lightweight integration**: Works out-of-the-box with Minetest servers.

---

## Installation

1. Download or clone this repository into your Minetest `mods/` directory:

   ```bash
   git clone https://github.com/yourusername/textshield.git
   ```

2. Ensure the folder is named `textshield/`.

3. Enable the mod for your world in Minetest.

---

## Configuration

You can configure the mod via the `settingtypes.txt` file or directly in Minetest's in-game settings menu.

Typical configuration options include:

* Thresholds for spam detection
* Caps percentage allowed before filtering
* Language-specific badword lists

---

## Usage

Once installed and enabled:

* TextShield automatically monitors all player chat messages.
* Spam, excessive caps, and offensive words are blocked before reaching other players.
* Server admins can customize the sensitivity to fit their community.

---

## Project Structure

```
textshield/
├── antispam.lua        # Spam detection logic
├── caps_filter.lua     # Capitalization filter
├── history.lua         # Message history tracking
├── init.lua            # Main entry point for the mod
├── LICENSE             # License file
├── mod.conf            # Minetest mod configuration
├── screenshot.png      # Preview image
├── settingtypes.txt    # User-configurable settings
└── badwords/           # Badword lists for multiple languages
```

---

## Requirements

* Minetest 5.0.0 or higher
* No external Lua dependencies

---

## License

This project is licensed under the terms described in the [LICENSE](textshield/LICENSE) file.

---

## Contributing

Contributions are welcome! You can help by:

* Expanding the badword lists
* Improving detection algorithms
* Adding support for more languages

To contribute, fork this repository, make your changes, and submit a pull request.

---

## Author

Developed by **\Themostrandom01**.
