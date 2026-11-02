# Tegion Launcher

Tegion Launcher is designed to be a **bare bones** game launcher for macOS, the app was also created with keeping the same design style of Apple.

This application is completely created inside of Xcode, which means it's completely native. 

The app is on the first version, and will probably stay like that for a while, since this app was originally just created for me. However, I decided to post the app on GitHub and make it fully open-source anyway. 

The app has **no app icon** and you probably have to allow it in settings, or run the terminal command to allow the app with no gatekeeper popping up.

## Bring your own IGDB key

The **Add Game** window has a search field that looks up game info (title, cover artwork, developer, release year, genres and summary) from [IGDB](https://www.igdb.com), an online game database. This is separate from the **Search** page, which only searches games already in your library.

The IGDB lookup runs entirely on **your own Mac** using **your own IGDB credentials**. No API key is included in this repository, and nothing is sent through the developer's computer or any server.

To use it:

1. Create a free application in the [Twitch Developer Console](https://dev.twitch.tv/console/apps). IGDB is owned by Twitch, and your Twitch account needs two-factor authentication.
2. Copy its **Client ID** and **Client Secret**.
3. Paste them into **Settings (⌘,)** in Tegion Launcher.

Without credentials you can still add games manually: type a title, choose a cover image yourself, and pick the app that launches it. Your credentials are stored only in your Mac's preferences.
