#!/bin/bash
version="0.001"
date="24/07/2015"
if [ $# -le 3 ]; then
    echo "Usage: magick-slicer.sh \"<source file>\" <tile_w> <tile_h> <step>"
    echo
    echo "    Map tiles generator. License: MIT. $date"
    echo "    Version: $version"
    echo "    Date: $date"
    echo
    echo "    - \"step\" - zoom step"
    echo "        200 -> 200%, or 2x"
    echo "        110 -> 110%, or 1.1x"
    echo "        100 -> 100%, or 1x (no resize) - infinity loop. Don't use it."
    echo
    echo "    result:"
    echo "        ./sliceResult/<zoom_Level>/<horizontal tiles line (x) (folder)>/<vertical tiles line (y) (file)>"
    echo
    echo "    More options inside (TODO: add all options into command line)"
    echo
    exit 0
fi

# ####### Options ####### #
resultFormat='png'
resizeFilter='' # http://www.imagemagick.org/Usage/filter/
resultDir='./sliceResult'
# Selector fo slicer: A or B
scaleFromImage=true     # Type of scaling: if true - scale calculates from image size to donw (slicer A), if false - image scale starts from tile size and grow up (slicer B)
gravity='NorthWest'     # Image positioning (from this option depends, which tiles sides can be cropped, if it not full size). Choices include: 'NorthWest', 'North', 'NorthEast', 'West', 'Center', 'East', 'SouthWest', 'South', 'SouthEast'. Use -list gravity to get a complete list of -gravity settings available in your ImageMagick installation.
extent=false            # Extent option (false - tiles be cropped, true - will be added transparent color to get all tiles of full size)
scale64=false

# Options omly for slicerB
upScale=false           # Maximum zoom: bigger or less then image. False - will not create upscaled image for maximum zoom; true - last zoom be equal or grater, then image.
horizontal=true         # Type of positioning of image: horizontal or vertical.
zoomReverse=false       # false: maxZoom=100%; true: minZoom=100%

# Example:
# Scale from image (scaleFromImage=true). We have Image of some size:
#  Image example
#   x
# y  ___________
#   |           |
#   |           |
#   |           |
#   |           |
#   |___________|
#
# Step 1a: resize
#   max zoom level - no need to resize
#    ___________
#   |           |
#   |           |
#   |           |
#   |           |
#   |___________|
#
# Step 1b: slicing
#   image is slicing to tiles. Some tiles can be cropped.
#   And here we have 2 options: 'extent' and 'gravity'
#
#       ____/ gravity='NorthWest' /
#       V
# Tile#  ____ ____ _ ...
#   0-> |    |    | |  . <- Not full tiles, set extent=true
#       |____|____|_|...    to get all tiles of full size
#   1-> |    |    | |  .
#       |____|____|_|...
#   2-> |____|____|_|  .
#       ................
#       ^      ^   ^__/ Dir# 2 /
#       |      |
#       |      |__/ Dir# 1 /
#       |
#       |__/ Dir# 0 /
#
# Step 2a:
#   Image resized to smaller size.
#    ______
#   |      |
#   |      |
#   |______|
#
#   Next image size formula - it calculates in percents:
#     (1) scale = scale * 100 / step
#   If step=200:
#       100% * 100 / 200 = 50%
#   If step=150:
#       100% * 100 / 175 = 57.(142857)%
#   If step=300:
#       100% * 100 / 175 = 33.(3)%
#   And here we have another question:
#       What happens, when we have very big image and large number of zoom levels?
#   Is there some loss in accuracy of calculations? (bash works with int only).
#  Yes, here exist some loss. [Right now is used pixeldirect calculations]
#  TODO: add oercent calculation in percents
#
# Step = 200 (200%)
#
# Bits CPU
# 64    1 0000000 000000000
# 32    1 0000000
#
# Step# Scale     32 loss   64 loss
#  1    1.0
# 10    0.0009765 625
# 15    0.0000305 17578125
# 20    0.0000009 536743164 0625
# 25    0.0000000 298023223 876953125
# 30    0.0000000 009313225 74615478515625
# 40    0.0000000 000018189 89403545856475830078125
# 50    0.0000000 000000177 63568394002504646778106689453
# 60    0.0000000 000000001 7347234759768070944119244813919
#
# So, as you can see - after step 20 and step 60 (for 32 and 64) we can't resize image.
#
# Example:
#   image size is '128x128' and tile size '32' and step '200' (2.0)
#   Example: (scaleFromImage=true); then zoom steps is next:
#       (1) 128/1=128 -> 128/(1*2.0)=64 -> 128/(2*2.0)=32   # 3 zoom steps
#   Example 2: (scaleFromImage=false)
#       (2) 32*1=32   -> 32*(1*2.0)=64  -> 32*(2*2.0)=128   # 3 zoom steps
#   Same result? Yes, because image have perfect size.
#   But! What happens if image size various? lets take '145x145':
#       (1a) 145/1=145 -> 145/2=72 -> 145/4=36 -> 145/8   # Oops! Wrong. Need slice tiles to parts or resize image to perfect size (size/tiles=x[int]).
#       (2a) 32*1=32   -> 32*2=64  -> 32*4=128  # result the same, but zoom not perfect - some image data was lost on resizing
#   So, the real result of (2a) be next:
#       (1b) 145/1=145, 145 -> 145/32=4, 32*4=128 (4x4 tiles), 17x32 (right), 32x17(bottom) and one 17x17(right bottom) pixels tiles. Now we have 4x4 full tiles and 4+4+1 cutted tiles.
#       145/2.0=72.5, 72.5/32=2, 32*2=64 (2x2 tiles), 8x32, 32x8, 8x8

# Next options are need if scaleFromImage=false

# if extent=true:
# Vertical:
#
# |<-image->|
#  ___ ___ _ _  _ _
# |   |   | | |  ^
# |___|___|_|_| _v_Tile
# |   |   | | |
# |___|___|_|_|
#            ^-- Transparent color (extent=true) or cropped (extent=false)
#          ^--- Not full tile
# |< image >|
#
# Horizontal:
#  ___ ___ ___  _ _
# |   |   |   |  ^
# |___|___|___|  Image
# |___|___|___| _v_
# |___|___|___| <-- Transparent color or cropped

# ####### Options end ####### #
# ———————————————————————————————————————————————————————————————————————————————————
# ####### Variables ####### #
# Getting the data
imageSource=${1}
tileW=${2}
tileH=${3}
step=${4}
imageW=''
imageH=''
# ####### Functions ####### #

getImgW(){ # image_file
    echo `identify -format "%[fx:w]" $1`
}

getImgH(){ # image_file
    echo `identify -format "%[fx:h]" $1`
}

# ———————————————————————————————————————————————————————————————————————————————————
# ######################## #
# ####### Slicer A ####### #

# Constants
scaleBase=100                   # Scale in percents - 100% (TODO: add option to use image sizes)
scaleMult=100000                # Scale multiplier (bash works only with int)
scaleMult64=100000000000000     # Scale multiplier for x64 bash and x64 convert (if you have very many zoom level and need more accuracy)
scaleStart=0
# declare -a scaledW
# declare -a scaledH
# scaledW=()
# scaledH=()

setScale(){
    if $scale64
    then
        local arch=`uname -m`
        if [ "${arch}" == "x86_64"  ]
        then
            scaleMult=$scaleMult64
        else
            echo "Your system (${arch}) isn't x86_64"
            exit 1
        fi
    fi
    scaleStart=$(( $scaleBase * $scaleMult ))
}

getZoomLevels(){ # imgLen(pixels) tileLen(pixels) step(int) # Calculate zoom levels for current step
    local imgLen=$1
    local tileLen=$2
    local zoomStep=$3
    local r=(0)
    local cnt=1
    while [ "$imgLen" -gt "$tileLen" ]
    do
        r[$cnt]=$imgLen
        let "cnt+=1"
        let "imgLen = imgLen * 100 / zoomStep"
    done
    r[$cnt]=$imgLen
    r[0]=$cnt
    echo ${r[*]}
}

# getZooms(){ # -> zoom levels for this image (it calculate zoom levels for image and tile each side)
#     local zw=`getZoomLevels $imageW $tileW $step`
#     local zh=`getZoomLevels $imageH $tileH $step`
#     echo $(( zw > zh ? zw : zh ))
# }

nextScale(){ # oldScale -> newScale
    # Calculate image zoom in percents - it need for imagemagick for image resize
    echo $(( $1 * 100 / $step ))
}

scaleToPercents(){ # scale
    local s=$1
    local sInt=0
    local sFloat=0
    let "sInt = s / $scaleMult"
    let "sFloat = s - sInt * $scaleMult"
    echo "${sInt}.${sFloat}%"
}

# scaleImage(){ # zoom scale -> file_path
#     local zoom=$1
#     local s=$2
#     local dir="${resultDir}/${zoom}"
#     local file="${dir}.${resultFormat}"
#     local size=`scaleToPercents $s`
#     mkdir -p $dir   # Imagemagick can't create directories
#     convert $imageSource $resizeFilter -resize $size $file
#     echo $file
# }

zoomImage(){ # zoom size -> file_path
    local zoom=$1
    local size=$2
    local dir="${resultDir}/${zoom}"
    local file="${dir}.${resultFormat}"
    # local size=`scaleToPercents $s`
    mkdir -p $dir   # Imagemagick can't create directories
    convert $imageSource $resizeFilter -resize $size $file
    echo $file
}

sliceImage(){ # zoom image
    local zoom=$1
    local src=$2
    local wxh="${tileW}x${tileH}"

    local tilesFormat="%[fx:page.x/${tileW}]/%[fx:page.y/${tileH}]" # This very important magic! It allow imagemagick to generate tile names with it position and place it in corect folders (but folders need to generate manually)
    local file="${resultDir}/${zoom}/%[filename:tile].png"

    local ext=''
    # local file="${resultDir}/${zoom}/%d.png"

    # Creating subdirectories for tiles (one vertical line of tiles is in one folder)
    local srcSize=`getImgW $src`               # Getting image width
    local dirNum=$(( $srcSize / $tileW ))  # Calculating number of tiles in line
    local i=0
    for(( i=0; i<=$dirNum; i++ ))
    do
        mkdir -p "${resultDir}/${zoom}/$i"  # Imagemagick can't create directories
    done
    sync

    # extent option
    if $extent
    then
        ext="-background none -extent ${wxh}"
    fi

    # Slice image to tiles
    # convert $src -crop $wxh -set filename:tile $tilesFormat +repage +adjoin -background none -gravity $gravity $ext $file
    convert $src -gravity $gravity -crop $wxh -set filename:tile $tilesFormat +repage +adjoin -gravity $gravity $ext $file
}

sliceA(){
    echo "Slicer A is running..."
    local scalesW=( `getZoomLevels $imageW $tileW $step` )
    local scalesH=( `getZoomLevels $imageH $tileH $step` )
    local zw=${scalesW[0]}
    local zh=${scalesH[0]}
    local scales=()
    local zoomMax=0
    local zoom=0
    local hMod=''
    local s=1
    local file=''
    if [ "$zw" -ge "$zh" ]
    then
        zoomMax=$zw
        scales=( ${scalesW[*]} )
        hMod=''
    else
        zoomMax=$zh
        scales=( ${scalesH[*]} )
        hMod='x'
    fi

    # local scale=$scaleStart
    # local scalep=''
    while [ "$s" -le "$zoomMax" ]
    do
        if $zoomReverse
        then
            let "zoom = s"
        else
            let "zoom = zoomMax - s + 1"
        fi
        file=`zoomImage $s "${hMod}${scales[$zoom]}"`
        echo "    Converted file: $file"
        sliceImage $s $file
        echo "    Sliced file:    $file"

        # scalep=`scaleToPercents $scale`
        # s=${scales[zoom-1]}
        # echo $zoom "$s"
        # file=`scaleImage $zoom "${hMod}${scales[$zoom]}"`
        # echo "zoom, scalep, scale: $zoom $scalep $scale $file"
        # echo ${scaledW[$i]}
        # echo ${scaledH[$i]}
        # scale=`nextScale $scale`

        let "s+=1"
    done
    echo "Sclicer A complete"
    # s=`nextScale $scaleStart`
    # s=`nextScale $s`
    # scaleToPercents $s
}

# ———————————————————————————————————————————————————————————————————————————————————
# ##########################
# ####### Slicer B ####### #

zoomPixels(){ # zoom tileSize
    local zoom=$1
    local pixels=$2
    if [ "zoom" -ne 0 ]
    then
        let "pixels = pixels * 100"
        for(( i=0; i<zoom; i++ ))
        do
            let "pixels = pixels * $step / 100"
        done
        let "pixels = pixels / 100"
    fi
    echo $pixels
}

resizeImageH(){ # zoom -> file_path
    local zoom=$1
    local dir="${resultDir}/${zoom}"
    local file="${dir}.${resultFormat}"
    local size=`zoomPixels $zoom $tileW`
    mkdir -p $dir   # Imagemagick can't create directories
    convert $imageSource $resizeFilter -resize $size $file
    echo $file
}

resizeImageV(){ # zoom -> file_path
    local zoom=$1
    local dir="${resultDir}/${zoom}"
    local file="${dir}.${resultFormat}"
    local size=`zoomPixels $zoom $tileH`
    mkdir -p $dir   # Imagemagick can't create directories
    convert $imageSource $resizeFilter -resize "x${size}" $file
    echo $file
}

resizeImage(){ # zoom -> file_path
    if $horizontal
    then
        echo `resizeImageH $1`
    else
        echo `resizeImageV $1`
    fi
}

sliceB(){
    echo "Slicer B is running..."
    local size=0
    local sizeMax=0
    local zoom=0

    if $horizontal
    then
        let "size = $tileW"
        let "sizeMax = $imageW"
    else
        let "size = $tileH"
        let "sizeMax = $imageH"
    fi

    if $upScale
    then
        let "sizeMax += $size"
    fi

    local px=$size
    while [ "$px" -lt "$sizeMax" ]
    do
        echo "    Slicing zoom level \"${zoom}\"; image main size is \"${px}\""
        sliceImage $zoom `resizeImage $zoom`
        let "zoom++"
        px=`zoomPixels $zoom $size`
    done
    echo "Slicer B complete"
}


mainScale(){ # min zoom = tile width
    if $scaleFromImage
    then
        sliceA
    else
        sliceB
    fi
    echo
}

init(){
    if [ "$step" -le 100 ]
    then
        echo "You get infinity loop. Minimum step value = 101% (101)"
        exit 1
    fi

    rm -rf $resultDir   # removing old results
    mkdir -p $resultDir # creating new results folder
    # Getting image sizes
    imageW=`getImgW $imageSource`
    imageH=`getImgH $imageSource`
    setScale            # Set scale
}

# ———————————————————————————————————————————————————————————————————————————————————
# ###################### #
# ### Programm start ### #

init
mainScale

# ### Programm end ##### #
# ###################### #
# ———————————————————————————————————————————————————————————————————————————————————
