::version 0.1d by #McZ
::TODO:
::  - how to properly unify file attributes like fps, tbn, audio format etc to get rid of 'Non-monotonous DTS in output stream...' warnings
::  - add some tests maybe
::  - ...
::to get file info:
  ::ffmpeg -hide_banner -i input.mp4 
::ffmpeg Windows binaries here: https://github.com/BtbN/FFmpeg-Builds/releases

::trim source video not to contain bullshit
:: !WARNING - trimming times must be set manually according to source video
ffmpeg -ss 00:00:04 -i v-origIN.mp4 -to 00:00:21 -c copy v-indentro.mp4

::prepare intro and outro
:: !WARNING - parameters like fps, format, video codec and timescale must be changed manually according to source video!
ffmpeg -framerate 1/10 -i "pr02-intro-1.png" -c:v libx264 -vf "fps=25,format=yuv420p" -crf 1 -video_track_timescale 30k v-intro-1.mp4
ffmpeg -framerate 1/5 -i "pr02-intro-2.png" -c:v libx264 -vf "fps=25,format=yuv420p" -crf 1 -video_track_timescale 30k v-intro-2.mp4
ffmpeg -framerate 1/5 -i "pr02-outro-1.png" -c:v libx264 -vf "fps=25,format=yuv420p" -crf 1 -video_track_timescale 30k v-outro-1.mp4
ffmpeg -framerate 1/10 -i "pr02-outro-2.png" -c:v libx264 -vf "fps=25,format=yuv420p" -crf 1 -video_track_timescale 30k v-outro-2.mp4

::add empty sound stream:
::(dummy sound stream is required in order to have an issue-less concatenation via '-f concat' later on
:: !WARNING - parameters like sample rate, channels, format etc. must be changed manually according to source video!
ffmpeg -i v-intro-1.mp4 -f lavfi -i anullsrc=channel_layout=mono:sample_rate=32000 -vcodec copy -acodec aac -shortest v-intro-1+audio.mp4
ffmpeg -i v-intro-2.mp4 -f lavfi -i anullsrc=channel_layout=mono:sample_rate=32000 -vcodec copy -acodec aac -shortest v-intro-2+audio.mp4
ffmpeg -i v-outro-1.mp4 -f lavfi -i anullsrc=channel_layout=mono:sample_rate=32000 -vcodec copy -acodec aac -shortest v-outro-1+audio.mp4
ffmpeg -i v-outro-2.mp4 -f lavfi -i anullsrc=channel_layout=mono:sample_rate=32000 -vcodec copy -acodec aac -shortest v-outro-2+audio.mp4

:::concatenate videos method 1
:::https://stackoverflow.com/a/37216101
::ffmpeg -i v-intro.720p+audio.mp4   -c copy -bsf:v h264_mp4toannexb -f mpegts 01.tmp.ts
::ffmpeg -i v-indentro.mp4           -c copy -bsf:v h264_mp4toannexb -f mpegts 02.tmp.ts
::ffmpeg -i v-outro.720p+audio.mp4   -c copy -bsf:v h264_mp4toannexb -f mpegts 03.tmp.ts
:::concatenate videos and delete tmp
::ffmpeg -i "concat:01.tmp.ts|02.tmp.ts|03.tmp.ts" -c copy -bsf:a aac_adtstoasc v-out.mp4 && del *.tmp.ts

::concatenate videos method 2 + add metadata
::prefferred method because of some issues with the method 1 above
:: !WARNING - metadata must be changed manually for every video
ffmpeg -safe 0 -f concat -i vidInputList.txt -map_metadata -1 -metadata title="Faktaoklimatu.cz: Data a souvislosti #2: Emisni povolenky" -metadata comment="v cervnu 2021 prednasel Tomas Protivinsky a Katerina Davidova" -codec copy v-out-concat+metadata.mp4
