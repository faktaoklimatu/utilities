#!/bin/bash
# WARNING: this is beta - no tests, leaves tmp files

#let's use the .bat file and do not maintain two versions of the same script...
sed 's~^[[:space:]]*:.*~~' vidconcat.bat | sed '/^[[:space:]]*$/d' | tr -d '\015' > vidconcat.sh.tmp
#    ^ removing "comments"                      ^ removing empty lines      ^removing 'CR', leaving only LF
/bin/bash vidconcat.sh.tmp
#rm vidConcat.sh.tmp
