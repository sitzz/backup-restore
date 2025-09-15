#!/bin/bash

# Delete files not accessed or modified last 90 days
find /home/myname/Downloads -type f \( -atime +90 -o -mtime +90 \) -delete

# Delete empty directories
find /home/myname/Downloads -type d -empty -delete
