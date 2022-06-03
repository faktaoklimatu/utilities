#!/bin/bash
#adds a new word to custom dictionary (and keeps it sorted)
# crysman (copyleft) 2021
#CHANGELOG
# 2022-06-03 + automatically adding first uppercase (Capitalized), too
# 2021-07-01 * initial release

function usage {
  echo "usage: `basename $0` <one_word_to_add>" >&2
}

DICT="FoKCustomDict.cs.pws"
if test -n "$1"; then
  newWord="$1"
else
  echo "ERR: a word to add missing..."
  usage && exit 2
fi

if test -w "$DICT"; then
  echo "$newWord" >> "$DICT" &&
  #add a Capitalized version, too:
  echo "$newWord" | awk '{ print toupper( substr( $0, 1, 1 ) ) substr( $0, 2 ); }' >> "$DICT" &&
  #print all but first line (an aspell meta string):
  words=`tail -n +2 "$DICT" | sort | uniq` &&
  #aspell requires this on 1st line:
  echo "personal_ws-1.1 cs 0 utf-8" > "$DICT" &&
  #return all the words:
  echo "$words" >> "$DICT"
else
  echo "ERR: $DICT not writable..."
  exit 3
fi
