# Tegion Launcher

A **bare-bones** game launcher for macOS, designed to feel like it was made by Apple.

Tegion Launcher is built entirely in Xcode, so it's fully native: no wrappers, no web views, no Electron. It uses Apple's **Liquid Glass** design language and keeps the interface quiet and uncluttered, so your games are the thing that stands out.

> **Heads up:** this app was originally made just for me. I decided to put it on GitHub and make it fully open-source anyway. It's on its first version and will probably stay that way for a while.

## Features

- **Home** – your library, organised into shelves by platform: Native Mac, Windows, Mobile, Nintendo, Native Nintendo, Xbox and PlayStation. Shelf titles and dividers use subtle category colours (Nintendo red, PlayStation blue and so on), and covers tilt in 3D when you hover over them.
- **Search** – instantly search the games already in your library.
- **Add Game** – open it with the **+** button. Look up a game on IGDB, or add one entirely by hand.
- **Launch anything** – each game launches whichever app you point it to.
- **Flexible storage** – keep games on your Mac or on an external drive (for example, a drive named *1TB SSD*).
- **Native feel** – hand cursor over games, Liquid Glass styling, and nothing you didn't ask for.

## Requirements

- A Mac running a version of macOS that supports Liquid Glass
- Xcode, if you want to build it yourself
- *(Optional)* a free IGDB account for automatic game info (see below)

## Installation

1. Download the latest build from the [Releases](../../releases) page, or clone the repository and build it in Xcode:

   ```bash
   git clone https://github.com/22Teg222/Tegion-Launcher.git
   cd Tegion-Launcher
   open TegionLauncher.xcodeproj
   ```

2. Press **⌘R** in Xcode to build and run.

### Opening the app for the first time

Tegion Launcher has **no app icon** yet, and it isn't signed with a paid Apple Developer certificate. macOS Gatekeeper will probably block it the first time you open it. You can allow it in either of these ways:

- **System Settings:** go to **Privacy & Security**, scroll to the message about Tegion Launcher and click **Open Anyway**.
- **Terminal:** remove the quarantine flag so no Gatekeeper popup appears:

  ```bash
  xattr -dr com.apple.quarantine /path/to/Tegion\ Launcher.app
  ```

## Adding games

1. Click the **+** button to open **Add Game**.
2. Search for the game on IGDB to fill in its details automatically, or enter them yourself.
3. Choose the app that launches the game.
4. Pick a platform shelf and save.

Your new game appears on the **Home** page, ready to launch.

## Bring your own IGDB key

The **Add Game** window has a search field that looks up game info (title, cover artwork, developer, release year, genres and summary) from [IGDB](https://www.igdb.com), an online game database. This is separate from the **Search** page, which only searches games already in your library.

The IGDB lookup runs entirely on **your own Mac** using **your own IGDB credentials**. No API key is included in this repository, and nothing is sent through the developer's computer or any server.

To use it:

1. Create a free application in the [Twitch Developer Console](https://dev.twitch.tv/console/apps). IGDB is owned by Twitch, and your Twitch account needs two-factor authentication.
2. Copy its **Client ID** and **Client Secret**.
3. Paste them into **Settings (⌘,)** in Tegion Launcher.

Without credentials you can still add games manually: type a title, choose a cover image yourself, and pick the app that launches it. Your credentials are stored only in your Mac's preferences.

## Privacy

Tegion Launcher has no accounts, analytics or telemetry. Your library and settings stay on your Mac. The only network requests it makes are the IGDB lookups you trigger yourself, sent directly from your Mac to IGDB with your own credentials.

## Contributing

It's open source, so issues and pull requests are welcome. Keep in mind the goal: a simple, native, Apple-style launcher, so changes that add lots of complexity may not fit.

## License

Add your license here (for example, MIT) and include a `LICENSE` file in the repository.
