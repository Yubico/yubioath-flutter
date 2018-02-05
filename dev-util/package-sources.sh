#!/bin/bash
# Similar to git-archive(1), but recurses into currently checked out
# submodules. Also generates a VERSION file, and has some special handling of
# submodules named `qt-solutions`.
#
# NOTE: Submodules' state is not checked. You should ensure that all submodules
# are checked out to the commits specified in `.gitmodules`.

PROJECT_NAME="yubioath-desktop"
TMP_DIR=$(mktemp -d "git-archive-recursive-${PROJECT_NAME}-XXXXXX")
SUBMODULES_DIR="${TMP_DIR}/submodules/"
OUTPUT_DIR="${TMP_DIR}/dist"
VERSION_FILE=VERSION

cleanup() {
  rm -rf "${TMP_DIR}"
}

die() {
  echo "Error occurred - exiting!" >&2
  cleanup
  exit 1
}

# Exit on error
trap die ERR


version=$(python3 compute-version.py "${PROJECT_NAME}"-)
commit=$(git rev-parse --short HEAD)
archive_name="archive-${commit}.tar.gz"
output_archive_base_name="${1:-${PROJECT_NAME}}"
output_archive_name="${output_archive_base_name}-${version}"
output_archive_dir="${OUTPUT_DIR}/${output_archive_name}"
output_archive_file_name="${output_archive_name}.tar.gz"

mkdir -p "${SUBMODULES_DIR}"
mkdir -p "${output_archive_dir}"

python3 compute-version.py "${PROJECT_NAME}"- > "${output_archive_dir}/${VERSION_FILE}"
echo "Embedded ${VERSION_FILE} file:"
cat "${output_archive_dir}/${VERSION_FILE}"
echo

# Create sources archive for root repo
git archive "$commit" > "${TMP_DIR}/${archive_name}"
# Unpack sources into output directory
tar xf "${TMP_DIR}/${archive_name}" -C "${output_archive_dir}"

IFS='
'
for submodule_line in $(git submodule status --recursive); do
  submodule_commit=$(echo "$submodule_line" | cut -d ' ' -f 2)
  submodule_dir=$(echo "$submodule_line" | cut -d ' ' -f 3)
  submodule_name=$(basename "$submodule_dir")

  short_commit=$(git -C "$submodule_dir" rev-parse --short "$submodule_commit")
  submodule_archive="${SUBMODULES_DIR}/${submodule_name}-${short_commit}.tar.gz"

  # Create sources archive for submodule
  git -C "$submodule_dir" archive "$submodule_commit" > "${submodule_archive}"

  # Unpack sources into output directory
  mkdir -p "${output_archive_dir}/${submodule_dir}"
  if [[ "$submodule_name" == "qt-solutions" ]]; then
    tar xf "${submodule_archive}" -C "${output_archive_dir}/${submodule_dir}" qtsingleapplication/common.pri qtsingleapplication/src
  else
    tar xf "${submodule_archive}" -C "${output_archive_dir}/${submodule_dir}"
  fi
done

# Bundle all sources together
tar cf "${output_archive_file_name}" -C "${OUTPUT_DIR}" --auto-compress .

echo "Wrote ${output_archive_file_name}"

cleanup
