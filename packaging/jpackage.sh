#!/usr/bin/env bash
set -euo pipefail

#############################################################################
# jpackage.sh
#
# Create a package (app-image, installer, etc.) for ATCS using jpackage.
# Defaults are tuned for this repository layout without assuming a platform.
#############################################################################

show_help() {
  cat <<EOF
Usage: $(basename "$0") [options]

Options:
  --type <type>       jpackage package type (app-image, exe, msi, deb, rpm). Default: app-image
  --out <dir>         output directory. Default: packaging/dist/jpackage
  --name <name>       application name. Default: ATCS
  --jar <file>        path to the main JAR. Default: packaging/common/ATCS.jar or packaging/ATCS.jar
  --main-class <cls>  main class. Default: com.gpl.rpg.atcontentstudio.ATContentStudio
  --icon <file>       icon file (.png or .ico). Default: packaging/common/ATCS.png (falls back to .ico files)
  -h, --help          show this help

Examples:
  ./jpackage.sh --type app-image
  ./jpackage.sh --type msi --out dist/windows
EOF
}

# Default configuration
TYPE="app-image"
PACKAGING_DIR=$(dirname "$(readlink -f "$0" 2>/dev/null || realpath "$0")")
OUT_DIR="${PACKAGING_DIR}/dist/jpackage"
NAME="ATCS"
MAIN_CLASS="com.gpl.rpg.atcontentstudio.ATContentStudio"
JLINK_OPTIONS=()
JAR_CANDIDATES=("${PACKAGING_DIR}/common/ATCS.jar" "${PACKAGING_DIR}/ATCS.jar")
ICON_CANDIDATES=("${PACKAGING_DIR}/common/ATCS.png" "${PACKAGING_DIR}/common/ATCS.ico" "${PACKAGING_DIR}/Windows/ATCS.ico")

# Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --type)
      TYPE="$2"; shift 2;;
    --out)
      OUT_DIR="$2"; shift 2;;
    --name)
      NAME="$2"; shift 2;;
    --jar)
      JAR_CANDIDATES=("$2"); shift 2;;
    --main-class)
      MAIN_CLASS="$2"; shift 2;;
    --icon)
      ICON_CANDIDATES=("$2"); shift 2;;
    -h|--help)
      show_help; exit 0;;
    *)
      echo "Unknown option: $1" >&2; show_help; exit 2;;
  esac
done

# Find jpackage
JPACKAGE=""
if command -v jpackage >/dev/null 2>&1; then
  JPACKAGE=$(command -v jpackage)
elif [ -n "${JAVA_HOME:-}" ] && [ -x "${JAVA_HOME}/bin/jpackage" ]; then
  JPACKAGE="${JAVA_HOME}/bin/jpackage"
else
  echo "Error: 'jpackage' not found in PATH and JAVA_HOME is not set to a JDK containing jpackage." >&2
  echo "Please install a JDK with jpackage (JDK 14+ or a recent OpenJDK build) and retry." >&2
  exit 3
fi

# Find the main jar
MAIN_JAR=""
for cand in "${JAR_CANDIDATES[@]}"; do
  if [ -f "$cand" ]; then
    MAIN_JAR="$cand"
    break
  fi
done
if [ -z "$MAIN_JAR" ]; then
  echo "Error: could not find main JAR. Looked for: ${JAR_CANDIDATES[*]}" >&2
  echo "Run 'packaging/package.sh' first to build the JAR, or pass --jar <path>." >&2
  exit 4
fi

# Find icon if available
ICON_ARG=()
for ic in "${ICON_CANDIDATES[@]}"; do
  if [ -f "$ic" ]; then
    ICON_ARG=(--icon "$ic")
    break
  fi
done

APP_VERSION_RAW=$(tr -d '[:space:]' < "${PACKAGING_DIR}/../res/ATCS_latest" 2>/dev/null || echo unknown)
APP_VERSION="${APP_VERSION_RAW#v}"

echo "Using jpackage at: $JPACKAGE"
echo "Package type: $TYPE"
echo "Main jar: $MAIN_JAR"
echo "Main class: $MAIN_CLASS"
echo "App version: $APP_VERSION"
echo "Output dir: $OUT_DIR"

# Prepare input dir for jpackage (it expects jars listed with --input)
INPUT_DIR="${PACKAGING_DIR}/jpackage-input-windows"
rm -rf "$INPUT_DIR"
mkdir -p "$INPUT_DIR"
cp -f "$MAIN_JAR" "$INPUT_DIR/"

# Copy additional jars from lib/ if they exist alongside packaging (common case)
LIB_DIR="${PACKAGING_DIR%/packaging}/lib"
if [ -d "$LIB_DIR" ]; then
  echo "Copying library jars from $LIB_DIR into jpackage input (if any)"
  find "$LIB_DIR" -maxdepth 1 -type f -name "*.jar" -exec cp -f {} "$INPUT_DIR/" \; || true
fi

# Ensure output directory exists
rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR"

# Installer-specific packaging options only make sense for Windows installers.
INSTALLER_EXTRA_ARGS=()
case "$TYPE" in
  exe|msi)
    INSTALLER_EXTRA_ARGS=(--win-shortcut --win-menu --win-menu-group "$NAME" --win-dir-chooser)
    ;;
esac

# Compose jpackage command
JP_CMD=("$JPACKAGE" --type "$TYPE" --name "$NAME" --app-version "$APP_VERSION" --input "$INPUT_DIR" --main-jar "$(basename "$MAIN_JAR")" --main-class "$MAIN_CLASS" --dest "$OUT_DIR")

if [ ${#ICON_ARG[@]} -gt 0 ]; then
  JP_CMD+=("${ICON_ARG[@]}")
fi

if [ ${#INSTALLER_EXTRA_ARGS[@]} -gt 0 ]; then
  JP_CMD+=("${INSTALLER_EXTRA_ARGS[@]}")
fi

JP_CMD+=(--jlink-options "${JLINK_OPTIONS[*]}")

echo "Running jpackage..."
echo "${JP_CMD[*]}"

# Run the command
"${JP_CMD[@]}"

RC=$?
if [ $RC -ne 0 ]; then
  echo "jpackage failed with exit code $RC" >&2
  exit $RC
fi

echo "jpackage completed. Output written to $OUT_DIR"

