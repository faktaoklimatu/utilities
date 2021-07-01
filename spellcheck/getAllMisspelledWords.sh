#!/bin/bash
#hnusně zbastlený rychloskript na nalezení nečeských (resp. neslovníkových dle `aspell`) slov na faktaoklimatu.cz
#crysman (copyleft) 2020-2021
#
#changelog:
# - 2021-07-01a some czech diacritics chars were missing in grep, added
# - 2021-07-01  minor tweaks, englishized!
# - 2021-01-17a dump via elinks instead of lynx, addWord.sh added, search improved, colored output improved, local build support added
# - 2021-01-17  some checking added, colored output, custom dictionary
# - initial release

#vars:  
VERSION="2021-01-17a"
DOMAIN="faktaoklimatu.cz"
PORT="" #to be set later on
TMPDIR="/tmp/${DOMAIN}_spellcheck_online_$VERSION"
TMPOUTFILE="misspelled.txt"
CUSTOMDICT="FoKCustomDict.cs.pws"
MISSPELLEDNO=0
#tput color table
RED=`tput setaf 1`
GREEN=`tput setaf 2`
YELLOW=`tput setaf 3`
BLUE=`tput setaf 4`
MAGENTA=`tput setaf 5`
CYAN=`tput setaf 6`
WHITE=`tput setaf 7`
NOCOLOR=`tput sgr0`

function _err() {
  echo "${RED}== ERR: $1, exitting${NOCOLOR}" >&2
  exit    
}

function _info() {
  echo "${GREEN}== INFO: $1${NOCOLOR}"
  if test -z "$2"; then
    sleep 1
  fi  
}

function usage {
  echo "usage: `basename $0` [online*|local]" >&2
}


#args
if test -z "$1"; then
  usage
  _info "no argument provided, using $DOMAIN as a domain..."
elif test "$1" == "online"; then
  continue
elif test "$1" == "local"; then
  TMPDIR="/tmp/${DOMAIN}_spellcheck_local_$VERSION"
  DOMAIN="localhost"
  PORT=":4000"
  test -z "`wget -qO- localhost:4000`" && _err "local webserver seems NOT to be running, check your 'make local' output..."
else
  usage
  _err "bad arguments"
fi

#check prereqs or die:
test -w /tmp >/dev/null 2>&1 || _err "unable to write to /tmp"
which wget >/dev/null 2>&1 || _err "this script requires 'wget'"
which aspell >/dev/null 2>&1 || _err "this script requires 'aspell'"
aspell dump dicts | grep ^cs >/dev/null 2>&1 || _err "this script requires 'aspell-cs' package"
which elinks >/dev/null 2>&1 || _err "this script requires 'elinks'"

#prepare /tmp...
mkdir -p "$TMPDIR" &&
cp -f "$CUSTOMDICT" "$TMPDIR" &&
cd "$TMPDIR" && 

#get all text pages into faktaoklimatu.cz folder:
test -d "$TMPDIR/$DOMAIN" && {
  _info "most probably already downloaded, using local copy..."
} || {
  _info "checking up the version on $DOMAIN (might take a while)..." &&
  for URL in `wget --spider --force-html -r -l10 --reject '*.js,*.css,*.ico,*.txt,*.gif,*.jpg,*.jpeg,*.png,*.mp3,*.pdf,*.tgz,*.flv,*.avi,*.mpeg,*.iso,*.zip,*.svg,*.mp4,*.mov' --ignore-tags=img,link,script --header="Accept: text/html" -D "$DOMAIN" "${DOMAIN}${PORT}" 2>&1 | grep ^Removing | sed 's~\.tmp.*~~' | awk '{print $2}'`; do elinks -dump -no-references "http://$URL" > "./$URL"; done
} &&

#get all czech-only misspelled words
_info "finding and writing-out misspelled words..."
for f in `find "./${DOMAIN}${PORT}" -type f`; do cat "$f" | aspell -l cs list; done | sort | uniq | aspell -l en list | aspell --master="./$CUSTOMDICT" -l cs list | tee ${TMPOUTFILE} &&

_info "printing-out where the words are located..." &&
for WORD in `cat ${TMPDIR}/${TMPOUTFILE}`; do _info "misspelled: ${NOCOLOR}{${RED}${WORD}${NOCOLOR}}:" "nosleep"; grep --color=always -RI "[^a-zA-ZÁáČčĎďÉéĚěÍíŇňÓóŘřŠšŤťÚúŮůÝýŽž]$WORD[^a-zA-ZÁáČčĎďÉéĚěÍíŇňÓóŘřŠšŤťÚúŮůÝýŽž]" --exclude=${TMPOUTFILE} "./${DOMAIN}${PORT}"; echo ""; let "MISSPELLEDNO=MISSPELLEDNO+1"; done &&

#go back to original dir
cd - >/dev/null &&
echo "---" &&
echo "OK, all done. ${RED}$MISSPELLEDNO misspelled words${NOCOLOR} in total" &&
echo "(copy of misspelled words is in ${MAGENTA}$TMPDIR/$TMPOUTFILE${NOCOLOR})"
echo "[optional] use \`${MAGENTA}./`basename $0` 2>&1 | aha > `basename $0`.out.html${NOCOLOR}\` to generate colorized html output"
