adb shell cmd package list packages --user 0 | sed 's/package://g' | grep tachiyomi | while read pkg; do
  adb shell cmd package uninstall --user 0 "$pkg"
done
