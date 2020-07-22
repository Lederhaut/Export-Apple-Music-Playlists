# Export Apple Music Playlists

A script to export playlists from Apple Music (since MacOS 10.5 Catalina this app replaces iTunes) to a folder. Includes the song files and an m3u playlist file.

Created to easily export playlists and media from Apple Music to other locations.

[![Download latest](https://img.shields.io/badge/link-this%20repo-blue.svg)](https://github.com/lederhaut/Export-iTunes-Playlists)
[![Download latest](https://img.shields.io/badge/download-latest-blue.svg)](https://github.com/lederhaut/Export-iTunes-Playlists/releases/latest)

Kudos to [Daniel Petrescu](https://github.com/dpet23) as this was forked from his original project [dpet23
/
Export-iTunes-Playlists](https://github.com/dpet23/Export-iTunes-Playlists) for iTunes.

[![Download latest](https://img.shields.io/badge/link-this%20repo-blue.svg)](https://github.com/dpet23/Export-iTunes-Playlists)
[![Download latest](https://img.shields.io/badge/download-latest-blue.svg)](https://github.com/dpet23/Export-iTunes-Playlists/releases/latest)

---

**NOTE:**

* This script will work only with Apple Music on macOS Catalina (> 10.5). It's written in AppleScript, a language built into the Mac operating system since Mac OS 7.

* Tested with:
  * macOS 10.15.6
  * Apple Music 1.0.6.10

---

## How to use

### The script

1. Compile the script. This can be done in various ways:
    * Use the Makefile; or
    * Compile and export as an application from the Script Editor app
1. Run the app.

### Integrate into Apple Music

1. Compile the script
1. Move the app to `~/Library/Music/Scripts/`
    * The `make deploy` command compiles the script and moves the app to the correct location.
1. Open Apple Music.
1. The script can be run by opening Apple Music's Script menu (scroll icon) and selecting the script's name.

### Makefile

| Rule | Description |
| --- | --- |
| `make` | Build an app, and save it to this directory |
| `make deploy` | Build an app, and move it to `~/Library/Music/Scripts/` |
| `make exportplaylists` | Build an app from the `ExportPlaylists` script |
| `make clean` | Remove all apps from this directory |
| `make clean-deploy` | Remove the app from `~/Library/Music/Scripts/` |

---

## Options

The options that can be set before exporting:

* The playlists to export (one or more can be chosen).
* The location in which to export.
* The method in which to export multiple playlists:
  * Same folder - Creates a new folder and places all songs from all playlists there. All m3u playlist files are saved to a subfolder.
  * Different folders - Makes separate subfolders for each playlist. The m3u playlist is saved in this folder, and a further subfolder is made for the media files.
* The folder structure and filename rules to use for the media files.
  * Can use the Apple Music metadata. Available attributes are: `[album]`, `[album artist]`, `[artist]`, `[composer]`, `[track name]`, `[track number]`, `[disc number]`, `[playlist order number]`, `[original file name]`.
  * These attributes can be used to form the folder structure and filename.  
      For example: `[artist] > [album] > [track number] - [track name]`  
        - This will create `<export location>/<playlist name>/[artist]/[album]/file.extension`.  
        - The file will be renamed to `[track number] - [track name]`, and its original extension will be kept.

---

## Why use the script?

Apple Music already has an option to export a playlist. This creates a playlist file in several formats (`m3u`, `xml`, etc.), but doesn't export the actual media files, which can make it difficult to use the exported playlists on other devices.

The script makes a copy of all media files in a playlist alongside the `m3u` file. However, `m3u` is the only format supported.
