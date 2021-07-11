# ImgWizard

This is a small image resizer, built as a code challenge. Do not use this in production.

## Setup

In order to use the default resizing adapter, the `mogrify` command from the ImageMagick
suite of tools must be available on your system. Get it here: [https://imagemagick.org/script/download.php](https://imagemagick.org/script/download.php)

## Quick Start

From within the project directory, create a release (Unix systems only at this time) with `MIX_ENV=prod mix release`.

You can then start the server on the port of your choosing (e.g. port 4040):

```
IMG_WIZARD_PORT=4040 _build/dev/rel/unix/bin/unix start
```

By default, the server will start on port 4040.

Two endpoints are available:

### PUT /info

By sending an image via an HTTP PUT request to the "/info" path, you will receive a JSON reply containing key metadata:

From within `test/fixtures`:

```
$ curl -X PUT -F image=@logo.png "http://localhost:4040/info"
```

will return

```javascript
{
  "dimensions": {
    "height":64,
    "width":64
  },
  "mimetype":"image/png",
  "size":7636
}
```

### PUT /resize

By sending an image via an HTTP PUT request to the "/resize" path and provide `height` and `width` paraeters
as query strings, you will receive a binary response containing the resized file.

From within `test/fixtures`:

```
$ curl -X PUT -F image=@logo.png "http://localhost:4040/resize?width=40&height=40" -o resized.png
```

`test/fixtures/resized.png` will be the resized file at 40 by 40 pixels (whereas the original was 64 by 64).

Note that the width/height parameters are interpreted as a maximum bounding box, with the original image's
aspect ratio preserved.

## Notes on Design

### Versioning

The API isn't versioned, as it is simple and has room for evolution: extra information can be returned from `/info`
without breaking existing clients, and the same is true for `resize` which could see additional query parameters
being added. Versioning could naturally be added, but the intent was to keep things simple.

### Extracting Packages

The original idea was to have `ImgWizard` be a standalone img transformation package, and have the separate API
package depend on it, but I decided against that in the end. Given the scope of the code challenge, it didn't
really make sense to add the overhead of having an external package, or implementing an umbrella app.
