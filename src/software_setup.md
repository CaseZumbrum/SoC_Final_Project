Instructions for adding the software to the OS (done after building Petalinux)

## Building

- Start in petalinux project root directory
- `petalinux-create apps --name audio-application --enable`
- The new app will be located at `project-spec/meta-user/recipes-apps/audio-application`
- at `project-spec/meta-user/recipes-apps/audio-application/files` replace `audio-application.c` with the version from this repository
- `petalinux-build`
- `petalinux-package --force prebuilt`

## Running (inside OS)
- `sudo audio-application`
