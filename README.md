# MagickSlicer

[![Join the chat at https://gitter.im/VoidVolker/MagickSlicer](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/VoidVolker/MagickSlicer?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

DZI and custom map tiles generator.

## Dependencies
* [ImageMagick](http://www.imagemagick.org/script/index.php) - convert, identify
* Bash

## OS support
* Linux
* OSX

## Viewers supprot
* [OpenSeadragon](https://github.com/openseadragon/openseadragon)

## Usage
    magick-slicer.sh [options] [-i] /source/image [[-o] result/dir]
    magick-slicer.sh /source/image [options] [result/dir]
    magick-slicer.sh /source/image [result/dir] [options]

Use quotes for path or options with spaces. First unknown string interpreting as source image, if it not defined. Second unknown string is interpreting as result path, if it not defined. Also, for source and result you can use options `-i` and `-o`. As result you will get sliced image in default format (basic DZI).

### Example:

    ./magick-slicer.sh foo.jpg

Result:

```html
[file]  foo.dzi
[dir]   foo_files
[dir]       0
[file]          0_0.jpg (1x1px)
            1
                0_0.jpg (1x1)
            2
                0_0.jpg (2x2)
            3
                0_0.jpg (4x4)
            ...

            8
                0_0.jpg (WxH)      W<=256, H<=256
            9
                0_0.jpg (256x256)
                x_y.jpg (WxH)      W<=256, H<=256
            10
                0_0.jpg
                0_1.jpg
                1_0.jpg
                1_1.jpg
                ...
                x_y.jpg
            ...
            N (max zoom level)
                0_0.jpg
                ...
                x_y.jpg
```

Example OSD render:

```
<!DOCTYPE html><html><head>
    <meta charset="UTF-8">
    <script type="text/javascript" src="openseadragon.min.js"></script>
    <style>
        BODY {
            padding: 0;
            margin: 0;
            border: 0;
            left: 0;
            top: 0;
            right: 0;
            bottom: 0;
            overflow: hidden;
            position: absolute;
        }

        #map {
            width: 100%;
            height: 100%;
            background-color: #434343;
        }
    </style>
</head>
<body>
    <div id="map"></div>
    <script type="text/javascript">
        OpenSeadragon({
            id: 'map'
            , prefixUrl: 'images/'
            , tileSources: 'foo.dzi'
        });
    </script>
</body>
</html>
```

---

## Help options

### -?, --help [option]

Show basic help or show help for selected option.

Type:     str

### -m, --man

Show full help for all options.

---

## Options list

### [ -v, --verbose &lt;level&gt; ]

User-selected verbosity levels (0=none, 1=warnings, 2=warnings+info, 3=warning+info+debug)
Also, exists short commands for each level: -v0 -v1 -v2 -v3

Default:  0

Type:     int

### [ -i, --in &lt;file_path&gt; ]

Input file to slice.

Type:     str

### [ -o, --out &lt;directory_path&gt; ]

Output directory for result.

Default:  same as source

Type:     str

### [ -e, --extension &lt;file_extesion&gt; ]

Set result files extension.

Default:  same as source

Type:     str

### [ -w, --width &lt;tile_width&gt; ]

Set tile width.

Default:  256 pixels or same as height, if height is present.

Type:     int

### [ -h, --height &lt;tile_height&gt; ]

Set tile height

Default:  256 pixels or same as width, if width is present.

Type:     int

### [ -s, --step &lt;zoom_step_value&gt; ]

Zoom step value. Formula:

`image_size[i+1] = image_size[i] * 100 / step` (1)

```
200 -> 200% or 2x    -> 100% * 100 / 200 = 50%
175 -> 175% or 1.75x -> 100% * 100 / 175 = 57.(142857)%
120 -> 120% or 1.2x  -> 100% * 100 / 120 = 83.(3)%
300 -> 300% or 3x    -> 100% * 100 / 300 = 33.(3)%
100 -> 100% or 1x (no resize) -> infinity loop. Don't use it.
```

Default:  200

Type:     int

### [ -p, --options 'imagemagick options string' ]

Specifies additional imagemagick options for `convert`.

Type:     str

### [ -g, --gravity &lt;type&gt; ]

Types: `NorthWest North NorthEast West Center East SouthWest South SouthEast`

The direction you choose specifies where to position image, when it will be sliced. Use `-list gravity` to get a complete list of `-gravity` settings available in your ImageMagick installation.
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

Type of slicing - slice A. Image scale starts from image size to down. Inverts option `--sliceb`.

Default:  true

Type:     logic switch

### [ -b, --sliceb ]

Type of slicing - slice B. Image scale starts from tile size and grow up. Inverts option `--slicea`.

Default:  false

Type:     logic switch

### [ -c, --scaleover ]

Create upscaled image for maximum zoom (last zoom be equal or grater, then image).
````
zoom[i-1]_size < source_image_size < zoom[i]_size
````
`zoom[i]_size` - this is upscaled image.

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

