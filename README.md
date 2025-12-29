# Swift on Server

This repository contains the source code for the [swiftonserver.com](https://swiftonserver.com/) website.

## Dependencies

The website is built using [Toucan](https://toucansites.com/), a static site generator. To get started, you will need to [install](https://toucansites.com/docs/installation/macos/) Toucan (e.g. via Homebrew on macOS):

```sh
brew install toucansites/toucan/toucan
```

## Local Development

You can build, watch, and serve the website locally using the following commands.

**Create a development build**

Run this command to generate the site:

```sh
make dev
```

**Watch for changes**

To automatically rebuild the site whenever you modify the source files, execute:

```sh
make watch
```

**Serve the site**

To host the site locally on your machine, run:

```sh
make serve
```

Once the server is running, open [http://localhost:3000/](http://localhost:3000/) in your browser to preview the website.

**Generating Cover Images**

You can automatically generate missing `assets/cover.jpg` files for blog and devlog posts by running the command below.

```
make cover
```

**Note:** This requires [Swift](https://www.swift.org/install/) to be installed on your machine.

**Optimizing Images**

To enable image optimization, please install the following tools:

```sh
brew install optipng jpegoptim
```

To optimize your image assets, run the following command:

```sh
make png && make jpg
```

This uses `optipng` and `jpegoptim` to compress your PNG and JPEG files, respectively.

**Optimizing Videos**

To ensure consistent playback and quality across the site, please adhere to the following specifications when adding video content.

**Recommended Settings:** If you are exporting from tools like Final Cut Pro or DaVinci Resolve, please ensure your export settings match the following:

* **Video Codec:** H.264 (preferred for widest support) or H.265/HEVC.
* **Audio Codec:** AAC.
* **Resolution:** 1920x1080 (1080p).
* **File Format:** `.mp4`

> **Note:** If you are exporting from **Canva**, these settings are used by default, so no manual adjustment is needed.

If your video does not match these specifications, you can convert it using one of the methods.

For a visual tool, you can download and use [HandBrake](https://handbrake.fr/downloads.php) to convert your files to MP4.

If you prefer the command line, you can use FFmpeg.

First, install the tool via Homebrew:

```sh
brew install ffmpeg
```

Single File Conversion Run the following to convert a specific file:

```sh
ffmpeg -i input.mov -vcodec h264 -acodec aac output.mp4
```

Bulk Conversion To convert all `.mov` files in the current directory to `.mp4`, run this loop:

```sh
for file in *.mov; do
  ffmpeg -i "$file" -vcodec h264 -acodec aac "${file%.mov}.mp4"
done
```

To ensure your videos load quickly and play smoothly on all devices, we recommend generating optimized versions in three formats: MP4, WebM, and OGV.

You can use the following `ffmpeg` commands to generate these files:

```sh
# fully web optimized mp4
ffmpeg -i input.mp4 -vcodec libx264 -pix_fmt yuv420p -profile:v baseline -level 3 output.mp4
# webm
ffmpeg -i input.mp4 -vcodec libvpx -qmin 0 -qmax 50 -crf 10 -b:v 1M -acodec libvorbis output.webm
# ogv
ffmpeg -i input.mp4 -c:v libtheora -c:a libvorbis output.ogv
```

Ideally, we want to achieve an HTML structure similar to the snippet below, which provides fallback sources for different browsers:

```html
<video width="320" height="240" autoplay muted loop controls>
    <source src="movie.mp4" type="video/mp4">
    <source src="movie.webm" type="video/webm">
    <source src="movie.ogg" type="video/ogg">
    Your browser does not support the video tag.
</video>
```

> **Important Note:** Raw HTML tags will not render inside our Markdown files. Please do not paste the code above directly into your article. Instead, use a custom block directive or a template to embed videos.
