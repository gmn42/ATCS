# ATContentStudio Gradle build

This Gradle build replaces the old IDE-only setup and covers compile, test, packaging, and runtime-image generation.

## Requirements

- JDK 21
- GitHub checkout with the Gradle wrapper

## Common commands

### Build everything
```sh
./gradlew build
```

This runs the default build, creates the shadow jar, builds the ZIP distribution, and runs `jpackage`.

### Run the app
```sh
./gradlew run
```

### Run tests
```sh
./gradlew test
```

### Build just the fat jar
```sh
./gradlew shadowJar
```

Output:

```text
build/libs/ATContentStudio-<version>-all.jar
```

### Build the ZIP distribution
```sh
./gradlew packageZip
```

Output:

```text
build/distributions/ATContentStudio-<version>.zip
```

### Build the runtime image / jpackage output
```sh
./gradlew jpackage
```

This uses the Shadow jar as input and generates the app image under the Gradle build directory.

## Notes

- Local jars are loaded from `lib/`.
- Source roots include `src`, `hacked-libtiled`, `minify`, and `siphash-zackehh/src/main/java`.
- `hacked-libtiled/tiled/io/resources/map.dtd` is copied into the runtime resources so TMX loading works.
- The build currently uses a Gradle-managed JDK 21 toolchain so `jlink` can run without a hard-coded path.
- Windows installers include Start Menu and desktop shortcuts.
- Windows packaging uses `packaging/Windows/ATCS.ico` for the installer and launcher icon.
