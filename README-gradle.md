# ATContentStudio Gradle build

This Gradle build replaces the old IDE-only setup and covers compile, test, packaging, and runtime-image generation.

## Requirements

- JDK 21
- GitHub checkout with the Gradle wrapper

## Common commands

### Build the project
```sh
./gradlew build
```
This runs the default build and produces two outputs in `build/libs`:
* `ATContentStudio-<version>.jar` - the conventional ("thin") jar without support libraries.
* `ATContentStudio-<version>-all.jar` - the "fat" jar with support libraries, suitable for running with `java -jar`

### Run the app
```sh
./gradlew run
```

### Run tests
```sh
./gradlew test
```
(Only very minimal testing has been implemented so far)

## Packages
### Windows

On Windows, build installers with:

```powershell
.\gradlew.bat packageExe
.\gradlew.bat packageMsi
```

Windows installer outputs are written under `build/distributions/`. The helper archive tasks copy them to `build/distribution/`.
### JPackage

To build a native `jpackage` installer or app image for the current platform:

```sh
./gradlew jpackage
```
The output will be left in `build/jpackage`.  This has not been tested on macOS, and may require other build tools installed depending on platform.

### Zip Distribution
To build an old-style ZIP distribution using the fat jar with icon and start script (requires a compatible JVM installed on target system):

```sh
./gradlew packageZip
```
The zip file will be written to `build/distributions/ATCS-<version>.zip`

### Source Distribution

```
./gradlew sourcesJar
```
A source distribution is written to `build/libs/ATContentStudio-<version>-sources.jar`.

## Notes

- Local jars are loaded from `lib/`.
- Source roots include `src`, `hacked-libtiled`, `minify`, and `siphash-zackehh/src/main/java`.
- `hacked-libtiled/tiled/io/resources/map.dtd` is copied into the runtime resources so TMX loading works.
- The build currently uses a Gradle-managed JDK 21 toolchain so `jlink` can run without a hard-coded path.
- Windows installers include Start Menu and desktop shortcuts.
- Windows packaging uses `packaging/Windows/ATCS.ico` for the installer and launcher icon.
