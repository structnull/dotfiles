#!/bin/sh

sourceRoot="$(echo ~/.var/app/com.valvesoftware.Steam/.local/share/Steam/steamapps/common/Proton\ -\ Experimental)";
runnerDir="$(echo ~/.var/app/com.usebottles.bottles/data/bottles/runners)";
root="$runnerDir/GE-Proton-Experimental";

mkdir -p "$root";
find "$sourceRoot" -type f -exec bash -c '
    relativeFile="$(realpath --relative-to "'"$sourceRoot"'" "{}")";
    cd "'"$root"'";
    dir="$(dirname "$relativeFile")";
    [ ! -d "$dir" ] && echo "Creating dir $dir" && mkdir -p "$dir";
    echo "linking file $relativeFile" && sudo ln "{}" "$relativeFile"' \;

