# MagickSlicer

[![Join the chat at https://gitter.im/VoidVolker/MagickSlicer](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/VoidVolker/MagickSlicer?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

DZI and custom map tiles generator.

## Usage:

    magick-slicer.sh [options] [-i] /source/image [[-o] result/dir]
    magick-slicer.sh /source/image [options] [result/dir]
    magick-slicer.sh /source/image [result/dir] [options]

## Dependencies:
* [ImageMagick](http://www.imagemagick.org/script/index.php) - convert, identify

## OS support:
* Linux
* OSX

Use quotes for path or options with spaces. First unknown string interpreting as source image, if it not defined. Second unknown string is interpreting as result path, if it not defined. Also, for source and result you can use options '-i' and '-o'.

---

## Help options

### -?, --help [option]

Show basic help or show help for selected option.

Type:     str

### -m, --man

Show full help for all options.

Type:     str

---

## Options list:

### [ -v, --verbose <level> ]

User-selected verbosity levels (0=none, 1=warnings, 2=warnings+info, 3=warning+info+debug)
Also, exists short commands for each level: -v0 -v1 -v2 -v3

Default:  0

Type:     logic switch

### [ -i, --in <file_path> ]

Input file to slice.

Type:     str

### [ -o, --out <directory_path> ]

Output directory for result.

Default:  same as source

Type:     str

### [ -e, --extension <file_extesion> ]

Set result files extension.

Default:  same as source

Type:     str

### [ -w, --width <tile_width> ]

Set tile width.

Default:  256 pixels or same as height, if height is present.

Type:     int

### [ -h, --height <tile_height> ]

Set tile height

Default:  256 pixels or same as width, if width is present.

Type:     int

### [ -s, --step <zoom_step_value> ]

Zoom step value. Formula:

`(1) image_size[i+1] = image_size[i] * 100 / step`

```
200 -> 200% or 2x    -> 100% * 100 / 200 = 50%
175 -> 175% or 1.75x -> 100% * 100 / 175 = 57.(142857)%
120 -> 120% or 1.2x  -> 100% * 100 / 120 = 83.(3)%
300 -> 300% or 3x    -> 100% * 100 / 300 = 33.(3)%
100 -> 100% or 1x (no resize) -> infinity loop. Don't use it.
```

Default:  200

Type:     int

### [ -p, --options 'imagemagick options string']

Specifies additional imagemagick options for 'convert'.

Type:     str

### [ -g, --gravity <type> ]

Types: `NorthWest North NorthEast West Center East SouthWest South SouthEast`
The direction you choose specifies where to position of cuts start on image. Use -list gravity to get a complete list of -gravity settings available in your ImageMagick installation.
http://www.imagemagick.org/script/command-line-options.php#gravity

Default:  NorthWest

Type:     str

### [ -x, --extent ]

Specifies the edge tiles size: cropped or extent them to full size and fill transparent color.

Default:  false

Type:     logic switch

### [ -d, --dzi ]

Specifies output format.

Default:  true

Type:     logic switch

### [ -a, --slicea ]

Type of slicing - slice A. Image scale starts from image size to down. Inverts option '--scliceb'.

Default:  true

Type:     logic switch

### [ -b, --sliceb ]

Type of slicing - slice B. Image scale starts from tile size and grow up. Inverts option '--slicea'.

Default:  false

Type:     logic switch

### [ -c, --scaleover ]

Create upscaled image for maximum zoom (last zoom be equal or grater, then image).
`zoom[i-1]_size < source_image_size < zoom[i]_size`
Work only in slice B mode. In other cases ignored.

Default:  false

Type:     logic switch

### [ -r, --horizontal ]

Tiles divide image on horizontal side without remains. On this side tiles will not be croped.
Work only in slice B mode. In other cases ignored.

```
 ___ ___ ___  _ _
|   |   |   |  ^
|___|___|___|  Image
|___|___|___| _v_   <- Not full tiles.
|_._|_._|_._| <-- Transparent color (extent=true) or cropped (extent=false)
```

Default:  true

Type:     logic switch

### [ -t, --vertical ]

Tiles divide image on vertical side without remains. On this side tiles will not be croped.
Work only in slice B mode. In other cases ignored.

```
|<-image->|
 ___ ___ _ _  _ _
|   |   | |.|  ^
|___|___|_|_| _v_Tile
|   |   | |.|
|___|___|_|_|
           ^-- Transparent color (extent=true) or cropped (extent=false)
         ^--- Not full tiles
```

Default:  false

Type:     logic switch

