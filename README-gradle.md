# Gradle build for ATContentStudio

This Gradle build replaces the old IDE-only build configuration and covers the current custom packaging flow.

## Requirements

- JDK 11 or newer
- Gradle wrapper recommended

The project is configured to compile to Java 11 bytecode.

## Main tasks

### Build everything
```sh
./gradlew build