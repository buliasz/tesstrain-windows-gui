# Tesseract train GUI for Windows

> Tesseract language training Windows GUI v2.0 for Tesseract 4+. Both Windows executable and source AutoHotKey script files are provided.

## Install

The GUI executable is portable. You can copy the `tesstrain_gui.exe` file to any directory and execute it.

### Requirements

You will need version 4 or newer of Tesseract executables (that include the
training tools and matching leptonica bindings).

You can download executables built from the latest code version using the [zdenop's
AppVeyor](https://ci.appveyor.com/project/zdenop/tesseract/build/artifacts). You will also need
a copy of 'traineddata' which you can find for example on the [official Tesseract
website](https://tesseract-ocr.github.io/tessdoc/#traineddata-files-1)).

If you prefer, you can also [build](https://tesseract-ocr.github.io/tessdoc/Compiling.html#windows) and 
[install](https://tesseract-ocr.github.io/tessdoc/Compiling-%E2%80%93-GitInstallation)
binaries on your own. More information can be found in the [Tesseract User
Manual](https://tesseract-ocr.github.io/tessdoc/).

### Python

You need a recent version of Python 3.x. For image processing the Python library `Pillow` is used.
If you don't have a global installation, the GUI will try to install `Pillow` and other required Python modules on
the first run.
'python' or 'python3' command must be working from the project's directory (Python's executable folder should be
in your PATH environment variable).

### Language data

Tesseract expects some configuration data (a file `radical-stroke.txt`). It will be downloaded automatically by the GUI when needed from [this address](https://github.com/tesseract-ocr/langdata_lstm/raw/main/radical-stroke.txt) and placed in the configurable "Output data directory".


## Choose model name

Tesstrain GUI will ask you for a name for your model. By convention, Tesseract stack models including
language-specific resources use (lowercase) three-letter codes defined in
[ISO 639](https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes) with additional
information separated by underscore. E.g., `chi_tra_vert` for **tra**ditional
Chinese with **vert**ical typesetting. Language-independent (i.e. script-specific)
models use the capitalized name of the script type as identifier. E.g.,
`Hangul_vert` for Hangul script with vertical typesetting. In the following,
the model name is referenced by `MODEL_NAME`.

## Provide ground truth

Place ground truth consisting of line images and transcriptions in a folder of your choice (default: 
`data/MODEL_NAME-ground-truth`). GUI will generate list of those files, and split into training and evaluation data, the ratio can be defined in the GUI.

Images must be in `.tif`, `.png`, `.bin.png`, `.nrm.png` or `.bmp` format.

Transcriptions must be single-line plain text and have the same name as the
line image but with the image extension replaced by `.gt.txt`. If any supported
image file won't have corresponding `.gt.txt` file, you will be asked for content on the
start of training, and it will be saved in a proper file.

The repository contains a folder with sample ground truth, see
[ocrd-testset](./ocrd-testset).

**NOTE:** If you want to generate line images for transcription from a full
page, see tips in [issue 7](https://github.com/OCR-D/ocrd-train/issues/7) and
in particular [@Shreeshrii's shell
script](https://github.com/OCR-D/ocrd-train/issues/7#issuecomment-419714852).

## Train

Execute the `tesstrain_gui.exe` and follow the displayed instructions.

## License

Software is provided under the terms of the `Apache 2.0` license.

Sample training data provided by [Deutsches Textarchiv](https://deutschestextarchiv.de) is [in the public
domain](http://creativecommons.org/publicdomain/mark/1.0/).
