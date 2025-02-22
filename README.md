# Backup+Restore

Collection of scripts that I use for creating backup files and restoring from those files on my computers running Manjaro.

Scripts are likely a neverending project and are very much customized for my own needs, so - YMMV!

## How to use
Please keep in mind that this script is very much aligned with my personal needs, so its way of working might not suit you. It could however still serve as a sane template for your own version, and of course you can just copy everything in it.

### Backup
1. Clone the repository.
2. Copy files `include.example.txt` to `include.txt`, update the file to your liking.
    1. __Please note__; Any entry in this file will be assumed being a relative path from your home directory. Absolute paths are not supported!
3. Run `./backup.sh` from you console and answer the prompts.
4. Rejoice!

### Restore
1. Clone the repository.
2. Copy your backup zip-file into the directory.
3. Run `./restore.sh` from your console and answer the prompts.
4. Rejoice!

## Credits

### checkupdates.sh
[Work--reddit](https://www.reddit.com/user/Work--Reddit/) and [DatCodeMania](https://www.reddit.com/user/DatCodeMania/)

The `checkupdates.sh` script and associated files are inspired/copied from [this Reddit comment thread](https://www.reddit.com/r/archlinux/comments/1ap45n8/comment/kq6evvq/).
