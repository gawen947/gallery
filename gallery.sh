#!/bin/sh
# File: gallery.sh
#  Time-stamp: <2012-12-24 21:27:06 gawen>
#
#  Copyright (C) 2012 David Hauweele <david@hauweele.net>
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#   along with this program. If not, see <http://www.gnu.org/licenses/>.

set -- $(getopt "hVvOEe:t:n:q:C:T:" $*)

IMG_EXT="jpg jpeg png"

usage() (
    echo "$0 [OPTION...] <IMAGES>"
)

help() (
    usage
    echo " -h Show this help message."
    echo " -V Show the version."
    echo " -v Verbose mode"
    echo " -O Conserve original images."
    echo " -e Output images extension (default: jpg)."
    echo " -T Title (default: Gallery)."
    echo " -t Tiny size (default: '120x')."
    echo " -n Normal size (defualt: '800x')."
    echo " -q Reduce quality."
    echo " -C Extra convert arguments."
    echo " -E Add Exiv comments."
)

output=public_html
extension=jpg
tiny_size=120x60
normal_size=800x600
main_title="Gallery"
quality=80

while [ $1 != "--" ]
do
    case $1 in
        -h)
            help
            exit 0
            ;;
        -V)
            echo "Gallery v0.1 by David Hauweele <david@hauweele.net>"
            exit 0
            ;;
        -v) verbose=1;;
        -O) original=1;;
        -E) exiv=1;;
        -T) main_title=$2; shift;;
        -o) output=$2; shift;;
        -e) extension=$2; shift;;
        -q) quality=$2; shift;;
        *)
            help
            exit 0
            ;;
    esac
    shift
done
shift

convert -version >/dev/null 2>&1 || { echo "ImageMagick Convert Command-Line Tool required." >&2; exit 1; }
if [ -n "$exiv" ]
then
    exiv2 -V >/dev/null 2>&1 || { echo "EXIF/IPTC metadata manipulation tool required." >&2; exit 1; }
fi

if [ $# != 1 ]
then
    usage
fi

output_tiny="$output/tiny"
output_orig="$output/orig"
output_normal="$output/normal"

mkdir -p "$output"
mkdir -p "$output_normal"
mkdir -p "$output_tiny"
if [ -n "$original" ]
then
    mkdir -p "$output_orig"
fi

if [ -n "$quality" ]
then
    quality="-quality $quality"
fi

for ext in $IMG_EXT
do
    find_filter="$find_filter -iname \"*.$ext\" -o"
done
find_filter="$find_filter -false"

if [ -x "$(which par)" ]
then
    par="$(which par)"
fi

if [ -x "$(which base)" -a -x "$(which crc32)" ]
then
    use_crcbase=1
fi

output_name() (
    if [ -n "$use_crcbase" ]
    then
        out=$(crc32 $1 | cut -d' ' -f 1 | base -O "0123456789abcdefghijklmnopqrstuvwxyz")
    else
        out=$(sha1sum $1)
    fi
    echo $out
)

exiv_data() (
    echo "<div id=\"exif\" class=\"toggle\" onclick=\"toggle('exif', 'visible');toggle('exif_switch', 'hidden');\"><table>"
    exiv2 "$1" | while read line
    do
        echo "<tr>"
        echo "<td>$(echo $line | cut -d':' -f1)</td>"
        echo "<td><b>$(echo $line | cut -d':' -f2)</b></td>"
        echo "</tr>"
    done
    echo "</table></div>"
)

index="$output/index.html"
echo "<html>" > "$index"
echo "<head>" >> "$index"
echo "  <link rel=\"stylesheet\" type=\"text/css\" href=\"style.css\">" >> "$index"
echo "  <link rel=\"shortcut icon\" type=\"image/png\" href=\"favicon.png\">" >> "$index"
echo "  <title>$main_title</title>" >> "$index"
echo "</head>" >> "$index"
echo "<body>" >> "$index"
echo "  <center>" >> "$index"
echo "  <h1>$main_title</h1>" >> "$index"
echo "  <div id=\"gallery\">" >> "$index"

tmp=$(tempfile)
for opt in $*
do
    files=$(eval find "$opt" $find_filter | xargs echo)
    for file in $files
    do
        out=$(output_name "$file")
        $par convert $quality -resize "$normal_size" "$file" "$output_normal/${out}_n.$extension"
        $par convert $quality -resize "$tiny_size" "$file" "$output_tiny/${out}_t.$extension"
        if [ -n "$original" ]
        then
            cp "$file" "$output_orig/${out}_o.$extension"
        fi

        title=$(basename "$file")
        title=$(basename "$title" .$(echo "$title" | cut -d'.' -f 2))
        if [ -n "$original" ]
        then
            img_div="<a href=\"orig/${out}_o.$extension\"/><img alt=\"$title\" src=\"normal/${out}_n.$extension\"/></a>"
        else
            img_div="<img alt=\"$title\" src=\"normal/${out}_n.$extension\"/>"
        fi

        if [ -n "$exiv" ]
        then
            exiv_div=$(exiv_data "$file")
        fi

        if [ -n "$preceding" ]
        then
            preceding_div="<a rel=\"prev\" href=\"$preceding.html\">&larr;</a>"
            sed "s/##FOLLOWING_DIV##/<a rel=\"next\" href=\"$out.html\">\&rarr;<\/a>/g" "$output/$preceding.html" > $tmp
            cp $tmp "$output/$preceding.html"
        else
            preceding_div="&larr;"
        fi

        cat <<EOF>"$output/$out.html"
<html>
<head>
  <title>$title</title>
  <link rel="stylesheet" type="text/css" href="style.css">
  <link rel="shortcut icon" type="image/png" href="favicon.png">
</head>
<body>
  <script language=javascript type='text/javascript'>
    function toggle(id, defvalue) {
      var visibility = document.getElementById(id).style.visibility;
      if((visibility != "visible") && (visibility != "hidden"))
        document.getElementById(id).style.visibility = defvalue;
      else if(visibility == "visible")
        document.getElementById(id).style.visibility = "hidden";
      else
        document.getElementById(id).style.visibility = "visible";
    }
  </script>
  <center>
  <h1>$(basename $file)</h1>
<p>
  <div id="nav">$preceding_div ##FOLLOWING_DIV## <a href="index.html">&#x2302;</a></div>
  <div id="photo">$img_div</div>
</p>

<div id="exif_switch" class="toggle"><a href="#" onclick="toggle('exif_switch', 'hidden');toggle('exif', 'visible');">Exif</a></div>

<p>
  $exiv_div
</p>
</center>
</body>
</html>
EOF
        preceding="$out"
        echo "<div id=\"preview\"><a href=\"$out.html\"><img alt=\"[$title]\" src=\"tiny/${out}_t.$extension\"/></a><div>$title</div>" >> "$index"
    done

    sed "s/##FOLLOWING_DIV##//g" "$output/$preceding.html" > $tmp
    cp $tmp "$output/$preceding.html"
done

rm $tmp
echo "</div>" >> "$index"
echo "</center>" >> "$index"
echo "</body>" >> "$index"
echo "</html>" >> "$index"
