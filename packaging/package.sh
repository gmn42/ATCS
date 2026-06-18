#!/bin/bash

# Script to build ATCS.jar, replicating IntelliJ artifact definition
# Linux and Windows compatible

# --- Platform Detection ---
if [ "$1" = "-windows" ]; then
    echo "Got '-windows' flag. Running Windows version"
    PLATFORM="WINDOWS"
else
    echo "No '-windows' flag. Running Linux version"
    PLATFORM="LINUX"
fi

# --- Configuration ---
PACKAGING_DIR=$(dirname "$(readlink -f "$0" || greadlink -f "$0" || stat -f "$0")") # Directory of this script
ATCS_SOURCE_DIR=$(dirname "${PACKAGING_DIR}") # Parent directory of this script, assumed to be ATCS source root
TEMP_DIR="${PACKAGING_DIR}/tmp"
JAR_LOCATION="${PACKAGING_DIR}/ATCS.jar" # Output JAR location as per script
MANIFEST_LOCATION="${PACKAGING_DIR}/Manifest.txt"
VERSION_FILE="${ATCS_SOURCE_DIR}/res/ATCS_latest"
SOURCE_BASE_DIR="${ATCS_SOURCE_DIR}/src" # Base directory for standard source code
LIB_BASE_DIR="${ATCS_SOURCE_DIR}/lib"     # Base directory for libraries

# --- **ADDITIONAL SOURCE CODE FOLDERS** ---
EXTRA_SOURCE_DIRS=(
  "hacked-libtiled"
  "minify"
  "siphash-zackehh/src/main/java"
)

# --- Libraries to include ---
LIBRARIES=(
  "bsh-2.0b4.jar"
  "jide-oss.jar"
  "json_simple-1.1.jar"
  "jsoup-1.10.2.jar"
  "junit-4.10.jar"
  "picocli-4.7.6.jar"
  "prefuse.jar"
  "rsyntaxtextarea.jar"
  "ui.jar"
)

JPACKAGE_CMD=(bash "./jpackage.sh")
JPACKAGE_NAME="ATCS"
JPACKAGE_MAIN_CLASS="com.gpl.rpg.atcontentstudio.ATContentStudio"
JPACKAGE_LINUX_ICON="./common/ATCS.png"
JPACKAGE_WINDOWS_ICON="./common/ATCS.ico"

run_jpackage() {
    local TYPE_ARG="$1"
    local OUT_DIR_ARG="$2"
    local ICON_ARG="$3"

    "${JPACKAGE_CMD[@]}" \
        --type "$TYPE_ARG" \
        --out "$OUT_DIR_ARG" \
        --name "$JPACKAGE_NAME" \
        --jar "./common/ATCS.jar" \
        --main-class "$JPACKAGE_MAIN_CLASS" \
        --icon "$ICON_ARG"
}

can_build_deb() {
    command -v dpkg-deb >/dev/null 2>&1
}

can_build_rpm() {
    command -v rpm >/dev/null 2>&1 && command -v rpmbuild >/dev/null 2>&1
}

# --- Get version ---
echo "Getting version"
VERSION=$(tr -d '[:space:]' < "${VERSION_FILE}")
echo "Got version ${VERSION}"

# --- Prepare temporary directory ---
echo "Removing tmp folder"
rm -rf "${TEMP_DIR}"
echo "Recreating tmp folder"
mkdir -p "${TEMP_DIR}"

# --- **EXTRACT lib files directly to TEMP_DIR** ---
echo 'Extracting lib files to TEMP_DIR'
for LIB in "${LIBRARIES[@]}"; do
    echo "Extracting library: ${LIB}"
    unzip -qo "${LIB_BASE_DIR}/${LIB}" -d "${TEMP_DIR}" # Extract JAR contents to TEMP_DIR root
done

# --- Set ClassPath ---
echo "Getting source files"
# Find all java files in source directories
SOURCE_FILES=$(find "${SOURCE_BASE_DIR}" "${EXTRA_SOURCE_DIRS[@]/#/${ATCS_SOURCE_DIR}/}" -name "*.java" -print)
#echo "SourceFiles: ${SOURCE_FILES}"
echo ""

# --- Build Java classes ---
echo 'Building java classes'

# shellcheck disable=SC2086
# (we need word splitting here to pass multiple files)
javac -cp "${TEMP_DIR}" -d "${TEMP_DIR}" ${SOURCE_FILES}
if [ $? -ne 0 ]; then
    echo "Compilation failed. Please check errors above."
    exit 1
fi
echo "Compilation successful"

# --- Copy res stuff to temp folder ---
echo "Copying some stuff to temp folder"
cp -r "${ATCS_SOURCE_DIR}"/res/* "${TEMP_DIR}/"
mkdir -p "${TEMP_DIR}/com/gpl/rpg/atcontentstudio/img"
mkdir -p "${TEMP_DIR}/tiled/io/resources/"
cp -r "${ATCS_SOURCE_DIR}"/src/com/gpl/rpg/atcontentstudio/img/* "${TEMP_DIR}/com/gpl/rpg/atcontentstudio/img/" # some icons
cp -r "${ATCS_SOURCE_DIR}"/hacked-libtiled/tiled/io/resources/* "${TEMP_DIR}/tiled/io/resources/" # dtd file for tmx maps
cp "${VERSION_FILE}" "${TEMP_DIR}/" # Copy version file

# --- Create JAR file ---
echo ""
echo "Creating jar at location: ${JAR_LOCATION}"

cd "${TEMP_DIR}" || exit # Change to temp dir for JAR command

# JAR command WITHOUT lib directory
jar cfm "${JAR_LOCATION}" "${MANIFEST_LOCATION}"  -C . .
if [ $? -ne 0 ]; then
    echo "JAR creation failed."
    exit 1
fi

cd "${PACKAGING_DIR}" || exit # Go back to packaging dir

echo ''
echo "Done creating jar at ${JAR_LOCATION}"
cp -f "${JAR_LOCATION}" "${PACKAGING_DIR}/common/ATCS.jar" # Copy JAR to versioned name

# --- Create archive ---
cd "${PACKAGING_DIR}" || exit
echo "Creating packages"

# jpackage doesn't like 'v' in the version, so this gets a number without it.  Needs to be cleaned up.
APP_VERSION_RAW=$(tr -d '[:space:]' < "${PACKAGING_DIR}/../res/ATCS_latest" 2>/dev/null || echo unknown)
APP_VERSION="${APP_VERSION_RAW#v}"

if [ "$PLATFORM" = "WINDOWS" ]; then
    WINDOWS_ZIP_DIR="./dist/windows/zip"
    WINDOWS_EXE_DIR="./dist/windows/exe"
    WINDOWS_APP_IMAGE_DIR="./dist/windows/app-image"
    WINDOWS_MSI_DIR="./dist/windows/msi"


    # Use PowerShell's Compress-Archive which is available by default on Windows
    echo "Creating Windows ZIP archive (jar version)"
    powershell.exe -Command "Compress-Archive -Path './common/*' -DestinationPath './ATCS_${VERSION}-jar-only.zip' -Force"

    # Build a Windows EXE installer with jpackage
    echo "Creating Windows EXE installer"
    if ! run_jpackage "exe" "${WINDOWS_EXE_DIR}" "${JPACKAGE_WINDOWS_ICON}"; then
        echo "Package creation failed." >&2
        exit 1
    fi
    cp "${WINDOWS_EXE_DIR}/ATCS-${APP_VERSION}.exe" "./ATCS_${VERSION}-installer.exe"

    # Build a Windows MSI installer with jpackage
    echo "Creating Windows MSI installer"
    if ! run_jpackage "msi" "${WINDOWS_MSI_DIR}" "${JPACKAGE_WINDOWS_ICON}"; then
        echo "Package creation failed." >&2
        exit 1
    fi
    cp "${WINDOWS_MSI_DIR}/ATCS-${APP_VERSION}.msi" "./ATCS_${VERSION}-installer.msi"

    # Build a Windows MSI installer with jpackage
    echo "Windows portable zip archive"
    if ! run_jpackage "app-image" "${WINDOWS_APP_IMAGE_DIR}" "${JPACKAGE_WINDOWS_ICON}"; then
        echo "Package creation failed." >&2
        exit 1
    fi
    powershell.exe -Command "Compress-Archive -Path '${WINDOWS_APP_IMAGE_DIR}/*' -DestinationPath './ATCS_${VERSION}-portable.zip' -Force"

else
    echo "Creating Linux app-image package with jpackage"
    rm -rf "./dist/app-image"
    if ! run_jpackage "app-image" "./dist/app-image" "${JPACKAGE_LINUX_ICON}"; then
        echo "Package creation failed." >&2
        exit 1
    fi

    if can_build_deb; then
        echo "Creating Linux deb package with jpackage"
        rm -rf "./dist/deb"
        if ! run_jpackage "deb" "./dist/deb" "${JPACKAGE_LINUX_ICON}"; then
            echo "Warning: deb package could not be created on this host." >&2
        fi
    else
        echo "Warning: skipping deb package because dpkg-deb is not installed on this host." >&2
    fi

    if can_build_rpm; then
        echo "Creating Linux rpm package with jpackage"
        rm -rf "./dist/rpm"
        if ! run_jpackage "rpm" "./dist/rpm" "${JPACKAGE_LINUX_ICON}"; then
            echo "Warning: rpm package could not be created on this host." >&2
        fi
    else
        echo "Warning: skipping rpm package because rpm/rpmbuild are not installed on this host." >&2
    fi
fi
echo "Created packages under ${PACKAGING_DIR}/dist"

echo "Script finished."
