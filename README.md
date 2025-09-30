# catmarks 🐾

*A category-based bookmark system powered by Rofi.*

![Using Catmarks Gif](https://github.com/Ozzly/catmarks/blob/main/assets/catmarks_usage.gif)

`catmarks` is a lightweight shell script that lets you organise and launch bookmarks through [Rofi](https://github.com/davatorium/rofi).  
Bookmarks are grouped into **categories** (folders) and the script will attempt to download thumbnails for supported sites to give a visual picker in Rofi.



## Features
- Organize bookmarks into **categories** (filesystem folders).  
- Launch bookmarks quickly via **Rofi**.  
- Auto-download thumbnail images for supported sites (saved beside each bookmark).  
- Single-file shell script, easy to extend, minimal requirements.



## Installation

1. Clone the repo (or copy `catmarks.sh` to your machine):
   ```bash
   git clone https://github.com/ozzly/catmarks.git
   cd catmarks
   ```
2. Make the script executable
    ```bash
    chmod +x catmarks.sh
    ```



## Dependencies

+ rofi
+ curl
+ notify-send
+ magick - optional if websites only use png/jpg
+ xdg-open

> [!NOTE]
> Rofi requires a thumbnailer to be installed on your system to display images.


## Usage
Running the script will generate a default directory on first run.
By default the script will add an option to rofi to add a new category or bookmark, however this can be done manually.

catmarks will override your system default rofi theme if `rofi_theme.rasi` is present in a directory.


## File storage

By default the script uses:
```bash
$HOME/catmarks
```
Format:
+ **Categories** = directories (e.g. Stickers, Origami, Work)
+ **Bookmarks** = plain text files with the bookmark URL in the file contents. The filename (without extension) is used as the bookmark title.
+ **Thumbnails** = image files saved beside the bookmark file with the same basename (e.g. my-video.txt and my-video.jpg).

Example layout:
```
~/catmarks/
 ├── Shopping/
 │   ├── etsy-ring.txt    # contains https://www.etsy.com/...
 │   └── etsy-ring.jpg    # thumbnail downloaded by script
 └── YouTube/
     ├── cool-video.txt   # contains https://youtube.com/watch?v=...
     └── cool-video.jpg   # thumbnail downloaded by script
```


## TODO
This project is still in early days and has alot of work to come.
