#!/bin/bash
#hnusně zbastlený rychloskript na nalezení nečeských (resp. neslovníkových dle `aspell`) slov na faktaoklimatu.cz
#crysman (copyleft) 2020
#
#changelog:
# - 2022-06-04a tmux usage added (split-window with elinks to have a better workflow), more verbosity added
# - 2022-06-03  interactive mode added (revising the words and ad-hoc adding to dict), script arguments fine-tuned
# - 2021-07-01a some czech diacritics chars were missing in grep, added
# - 2021-07-01  minor tweaks, englishized!
# - 2021-01-17a dump via elinks instead of lynx, addWord.sh added, search improved, colored output improved, local build support added
# - 2021-01-17  some checking added, colored output, custom dictionary
# - 2020        initial release

#vars:
VERSION="2022-06-04a"
DOMAIN="faktaoklimatu.cz"
PORT="" #to be set later on
TMPDIR="/tmp/${DOMAIN}_spellcheck_online_$VERSION"
TMPOUTFILE="misspelled.txt"
CUSTOMDICT="FoKCustomDict.cs.pws"
SCRIPTDIR=`pwd`
INTERACTIVE=
MISSPELLEDNO=0
#tput formatting table
RED=`tput setaf 1`
GREEN=`tput setaf 2`
YELLOW=`tput setaf 3`
BLUE=`tput setaf 4`
MAGENTA=`tput setaf 5`
CYAN=`tput setaf 6`
WHITE=`tput setaf 7`
BOLD=`tput smso`
NOBOLD=`tput rmso`
NOFORMAT=`tput sgr0`

function _err() {
  echo "${RED}== ERR: $1, exitting${NOFORMAT}" >&2
  exit
}

function _info() {
##  echo "$@"
  local str=${1:?string required}
  local delay=${2:-1} #default $2 to 1
  echo "${GREEN}== INFO: $str${NOFORMAT}"
  if [ "$delay" != "--nosleep" ]; then sleep "$delay"; fi
}

function usage {
  echo "usage:|`basename $0` ARGS|v.$VERSION
  |--online| perform on webpages online [default]
  |--local| perform on local build
  -h|--help| help
  -i|--interactive| interactive mode" | column -t -s "|" >&2
}

function confirm() {
    echo -n "$@ [yes/no]: "
    read answer
    for response in y Y yes YES Yes Sure sure SURE OK ok Ok;do
        if [ "_$answer" == "_$response" ];then
            return 0
        fi
    done
    return 1
}

#args check and setup
test -z "$1" && {
  _info "no arguments provided, printing-out usage and invoking [online] mode"
  usage
}

while [[ "$1" == -* ]]; do
  case "$1" in
  -i|--interactive) INTERACTIVE=1
    _info "interactive mode ON"
  ;;
  -h|--help) usage && exit 0;;
  --online) _info "online mode ON"
  ;;
  --local) _info "local mode ON"
    TMPDIR="/tmp/${DOMAIN}_spellcheck_local_$VERSION"
    DOMAIN="localhost"
    PORT=":4000"
    test -z "`wget -qO- localhost:4000`" && _err "local webserver seems NOT to be running, check your 'make local' output..."
  ;;
  --) shift && break;;
  *)
    usage
    _err "bad arguments"
  ;;
  esac
  shift
done

#check prereqs or die:
test -w /tmp >/dev/null 2>&1 || _err "unable to write to /tmp (required)"
which wget >/dev/null 2>&1 || _err "this script requires 'wget' (suggesting 'sudo apt install wget')"
which aspell >/dev/null 2>&1 || _err "this script requires 'aspell' (suggesting 'sudo apt install aspell')"
aspell dump dicts | grep ^cs >/dev/null 2>&1 || _err "this script requires 'aspell-cs' package (suggesting 'sudo apt install aspell-cs')"
which elinks >/dev/null 2>&1 || _err "this script requires 'elinks' (suggesting 'sudo apt install elinks')"

#prepare /tmp...
mkdir -p "$TMPDIR" &&
cp -f "$CUSTOMDICT" "$TMPDIR" &&
cd "$TMPDIR" &&

#get all text pages into faktaoklimatu.cz folder:
test -d "$TMPDIR/$DOMAIN" && {
  _info "most probably already downloaded, using local copy..."
} || {
  _info "crawling through $DOMAIN with wget and dump with elinks (might take a while)..." &&
  for URL in `wget --spider --force-html -r -l10 --reject '*.js,*.css,*.ico,*.txt,*.gif,*.jpg,*.jpeg,*.png,*.mp3,*.pdf,*.tgz,*.flv,*.avi,*.mpeg,*.iso,*.zip,*.svg,*.mp4,*.mov' --ignore-tags=img,link,script --header="Accept: text/html" -D "$DOMAIN" "${DOMAIN}${PORT}" 2>&1 | grep ^Removing | sed 's~\.tmp.*~~' | awk '{print $2}'`; do
    _info "dumping ${MAGENTA}${URL}${NOFORMAT}..." --nosleep &&
    elinks -dump -no-references -verbose 0 "http://$URL" > "./$URL";
  done
} &&

#get all czech-only misspelled words
_info "finding and writing-out misspelled words..."
for f in `find "./${DOMAIN}${PORT}" -type f`; do
  cat "$f" | aspell -l cs list;
done | sort | uniq | aspell -l en list | aspell --master="./$CUSTOMDICT" -l cs list | tee ${TMPOUTFILE} &&

_info "printing-out where the words are located..." &&
for WORD in `cat ${TMPDIR}/${TMPOUTFILE}`; do
  _info "misspelled: ${NOFORMAT}{${RED}${WORD}${NOFORMAT}}:" --nosleep;
  grep --color=always -RI "[^a-zA-ZÁáČčĎďÉéĚěÍíŇňÓóŘřŠšŤťÚúŮůÝýŽž]$WORD[^a-zA-ZÁáČčĎďÉéĚěÍíŇňÓóŘřŠšŤťÚúŮůÝýŽž]" --exclude=${TMPOUTFILE} "./${DOMAIN}${PORT}";
  if [ $INTERACTIVE ]; then
    #if in tmux, attach in split-window:
    which tmux >/dev/null && tmux ls >/dev/null 2>&1 && {
      tmux split-window "elinks \"https://duckduckgo.com/?q=${WORD}\""\;
    } || {
      echo "sleeping for 3 sec before opening elinks to browse on the word..." && sleep 3 &&
      elinks "https://duckduckgo.com/?q=${WORD}";
    }
    confirm "add the word ${YELLOW}${WORD}${NOFORMAT} to dict?" && cd "$SCRIPTDIR" && ./addWord.sh "${WORD}" && _info "word added to dictionary."
    cd "$TMPDIR"
  fi
  let "MISSPELLEDNO=MISSPELLEDNO+1";
done &&

#go back to original dir
cd "$SCRIPTDIR" &&
echo "---" &&
echo "OK, all done. ${RED}$MISSPELLEDNO misspelled words${NOFORMAT} in total" &&
echo "copy of misspelled words is in ${MAGENTA}$TMPDIR/$TMPOUTFILE${NOFORMAT}"
echo "[optional] use \`${MAGENTA}./`basename $0` 2>&1 | aha > `basename $0`.out.html${NOFORMAT}\` to generate colorized html output"
