#!/usr/bin/env bash

filepath="$3"
[[ ! -f "$filepath" ]] && exit 0

filename="$(basename "$filepath")"

# Detect MIME type
mime_type="$(file --mime-type -b "$filepath")"
type="${mime_type%%/*}"
subtype="${mime_type##*/}"

# Extract file extension and handle compound extensions (e.g. .tar.gz)
ext="$(basename "$filename" | grep -oE '\.[^.]+(\.[^.]+)?$' | sed 's/^\.//')"

# Default fallback directory
target_dir="$HOME/Downloads/uncategorized"

# Main routing logic
case "$type" in
  video)
    target_dir="$HOME/Videos"
    ;;

  audio)
    target_dir="$HOME/Music/$subtype"
    ;;

  image)
    target_dir="$HOME/Pictures/$subtype"
    ;;

application)
  case "$subtype" in
    # Archives
    zip|x-7z-compressed|x-rar|x-bzip2|x-xz|x-tar|x-gtar|x-iso9660-image|x-lzma|x-zstd)
      target_dir="$HOME/Downloads/archives/${ext:-$subtype}"
      ;;

    # Office-like
    pdf|msword|rtf|x-mswrite|epub)
      target_dir="$HOME/Documents/$subtype"
      ;;

    # OpenXML docs (use full MIME subtype)
    vnd.openxmlformats-officedocument.wordprocessingml.document)
      target_dir="$HOME/Documents/word"
      ;;
    vnd.openxmlformats-officedocument.spreadsheetml.sheet)
      target_dir="$HOME/Documents/spreadsheet"
      ;;
    vnd.openxmlformats-officedocument.presentationml.presentation)
      target_dir="$HOME/Documents/presentation"
      ;;

    # LibreOffice / ODF formats (e.g., ODP, ODS, ODT)
    vnd.oasis.opendocument.text)
      target_dir="$HOME/Documents/word"
      ;;
    vnd.oasis.opendocument.spreadsheet)
      target_dir="$HOME/Documents/spreadsheet"
      ;;
    vnd.oasis.opendocument.presentation)
      target_dir="$HOME/Documents/presentation"
      ;;

    # Executables / binaries
    x-sharedlib|x-dosexec|x-executable)
      target_dir="$HOME/Downloads/binaries/$subtype"
      ;;

    # Code files
    x-python-code|x-shellscript|x-csrc|x-c++src|x-java)
      target_dir="$HOME/Downloads/code/$subtype"
      ;;

    octet-stream)
      target_dir="$HOME/Documents/$subtype"
      ;;
  esac
  ;;

  text)
    case "$subtype_clean" in
      plain|markdown|csv|x-c|x-c++|x-java|x-python)
        target_dir="$HOME/Documents/$subtype"
        ;;
      html|css|javascript)
        target_dir="$HOME/Downloads/code/$subtype"
        ;;
      *)
        target_dir="$HOME/Documents/text"
        ;;
    esac
    ;;
esac

# Ensure destination directory exists
mkdir -p "$target_dir"

# Handle name conflicts by appending _1, _2, etc.
dest_path="$target_dir/$filename"
if [[ -e "$dest_path" ]]; then
  name="${filename%.*}"
  ext="${filename##*.}"
  i=1
  while [[ -e "$target_dir/${name}_$i.$ext" ]]; do
    ((i++))
  done
  dest_path="$target_dir/${name}_$i.$ext"
fi

# Move file
mv -n "$filepath" "$dest_path"
