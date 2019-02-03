#!/bin/bash

NAME_ROOT=vialectrum

# These settings probably don't need any change
export WINEPREFIX=/opt/wine64
export PYTHONDONTWRITEBYTECODE=1
export PYTHONHASHSEED=22

PYHOME=c:/python3
PYTHON="wine $PYHOME/python.exe -OO -B"


# Let's begin!
cd `dirname $0`
set -e

mkdir -p tmp
cd tmp

pushd $WINEPREFIX/drive_c/vialectrum

# Load electrum-icons and electrum-locale for this release
git submodule init
git submodule update

VERSION=`git describe --tags --dirty --always`
echo "Last commit: $VERSION"

pushd ./contrib/deterministic-build/vialectrum-locale
if ! which msgfmt > /dev/null 2>&1; then
    echo "Please install gettext"
    exit 1
fi
for i in ./locale/*; do
    dir=$WINEPREFIX/drive_c/vialectrum/vialectrum/$i/LC_MESSAGES
    mkdir -p $dir
    msgfmt --output-file=$dir/electrum.mo $i/electrum.po || true
done
popd

find -exec touch -d '2000-11-11T11:11:11+00:00' {} +
popd

cp $WINEPREFIX/drive_c/vialectrum/LICENCE .
cp $WINEPREFIX/drive_c/vialectrum/contrib/deterministic-build/vialectrum-icons/icons_rc.py $WINEPREFIX/drive_c/vialectrum/vialectrum/gui/qt/

# Install frozen dependencies
$PYTHON -m pip install -r ../../deterministic-build/requirements.txt

$PYTHON -m pip install -r ../../deterministic-build/requirements-hw.txt

pushd $WINEPREFIX/drive_c/vialectrum
$PYTHON setup.py install
popd

cd ..

rm -rf dist/

# build standalone and portable versions
wine "$PYHOME/scripts/pyinstaller.exe" --noconfirm --ascii --clean --name $NAME_ROOT-$VERSION -w deterministic.spec

# set timestamps in dist, in order to make the installer reproducible
pushd dist
find -exec touch -d '2000-11-11T11:11:11+00:00' {} +
popd

# build NSIS installer
# $VERSION could be passed to the electrum.nsi script, but this would require some rewriting in the script itself.
wine "$WINEPREFIX/drive_c/Program Files (x86)/NSIS/makensis.exe" /DPRODUCT_VERSION=$VERSION electrum.nsi

cd dist
mv vialectrum-setup.exe $NAME_ROOT-$VERSION-setup.exe
cd ..

echo "Done."
sha256sum dist/electrum*exe
