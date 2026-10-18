#!/usr/bin/env bash

set -u

usage() {
    printf 'Usage: %s <video-file>\n' "${0##*/}" >&2
    exit 2
}

[[ $# -eq 1 ]] || usage
input=$1

if [[ ! -f "$input" ]]; then
    printf 'Input file not found: %s\n' "$input" >&2
    exit 1
fi

for command in ffmpeg ffprobe; do
    if ! command -v "$command" >/dev/null 2>&1; then
        printf 'Required command not found: %s\n' "$command" >&2
        exit 1
    fi
done

filename=${input##*/}
if [[ "$filename" == *.* ]]; then
    output="${input%.*}-whatsapp.mp4"
else
    output="${input}-whatsapp.mp4"
fi

if [[ -e "$output" ]]; then
    printf 'Output already exists: %s\n' "$output" >&2
    exit 1
fi

video_info=$(ffprobe -v error -select_streams v:0 \
    -show_entries stream=codec_name,pix_fmt \
    -of csv=p=0 "$input") || exit 1
audio_codec=$(ffprobe -v error -select_streams a:0 \
    -show_entries stream=codec_name -of csv=p=0 "$input") || exit 1
video_codec=${video_info%%,*}
pixel_format=${video_info#*,}
[[ "$pixel_format" == "$video_info" ]] && pixel_format=""

tmp_output="${output%.mp4}.tmp.$$.mp4"
cleanup() {
    rm -f -- "$tmp_output"
}
trap cleanup EXIT

if [[ "$video_codec" == h264 && "$pixel_format" == yuv420p && ( "$audio_codec" == aac || -z "$audio_codec" ) ]]; then
    printf 'Input is WhatsApp-compatible; copying streams without quality loss.\n'
    if ffmpeg -hide_banner -y -i "$input" \
        -map 0:v:0 -map '0:a:0?' -c copy -movflags +faststart \
        "$tmp_output"; then
        mv -- "$tmp_output" "$output"
        printf 'Saved: %s\n' "$output"
        exit 0
    fi
    printf 'Stream copy failed; trying a high-quality encode.\n' >&2
    rm -f -- "$tmp_output"
fi

base_args=(-hide_banner -y -i "$input" -map 0:v:0 -map '0:a:0?'
    -map_metadata 0 -map_chapters 0 -sn -dn
    -vf 'scale=trunc(iw/2)*2:trunc(ih/2)*2:flags=lanczos,format=yuv420p'
    -c:a aac -b:a 256k -movflags +faststart -tag:v avc1)

try_encode() {
    local encoder=$1
    shift
    rm -f -- "$tmp_output"
    printf 'Trying %s hardware encoding...\n' "$encoder"
    if ffmpeg "${base_args[@]}" "$@" "$tmp_output"; then
        mv -- "$tmp_output" "$output"
        printf 'Saved: %s\n' "$output"
        return 0
    fi
    return 1
}

encoders=$(ffmpeg -hide_banner -encoders 2>/dev/null || true)

if [[ "$encoders" == *h264_nvenc* ]] && try_encode h264_nvenc \
    -c:v h264_nvenc -preset p7 -tune hq -rc vbr -cq 18 -b:v 0; then
    exit 0
fi

if [[ "$encoders" == *h264_qsv* ]] && try_encode h264_qsv \
    -c:v h264_qsv -preset veryslow -global_quality 18; then
    exit 0
fi

if [[ "$encoders" == *h264_amf* ]] && try_encode h264_amf \
    -c:v h264_amf -quality quality -rc cqp -qp_i 18 -qp_p 18; then
    exit 0
fi

for device in /dev/dri/renderD*; do
    [[ -e "$device" ]] || continue
    if [[ "$encoders" == *h264_vaapi* ]]; then
        rm -f -- "$tmp_output"
        printf 'Trying h264_vaapi hardware encoding on %s...\n' "$device"
        if ffmpeg -hide_banner -y -vaapi_device "$device" -i "$input" \
            -map 0:v:0 -map '0:a:0?' -map_metadata 0 -map_chapters 0 -sn -dn \
            -vf 'scale=trunc(iw/2)*2:trunc(ih/2)*2:flags=lanczos,format=nv12,hwupload' \
            -c:v h264_vaapi -qp 18 -c:a aac -b:a 256k \
            -movflags +faststart -tag:v avc1 "$tmp_output"; then
            mv -- "$tmp_output" "$output"
            printf 'Saved: %s\n' "$output"
            exit 0
        fi
    fi
done

printf 'Hardware encoding unavailable; using high-quality CPU encoding.\n'
if ffmpeg "${base_args[@]}" -c:v libx264 -preset slow -crf 18 "$tmp_output"; then
    mv -- "$tmp_output" "$output"
    printf 'Saved: %s\n' "$output"
else
    printf 'Conversion failed.\n' >&2
    exit 1
fi
