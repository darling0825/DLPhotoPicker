set -e
cd `dirname $0`

echo "$(date +%Y-%m-%d-%H-%M-%S) Start Build..."
echo 

pod update --project-directory=./DLPhotoPickerDemo
xctool -workspace DLPhotoPickerDemo/DLPhotoPickerDemo.xcworkspace -scheme DLPhotoPickerDemo -sdk iphonesimulator ONLY_ACTIVE_ARCH=NO

echo "***************************************************"
echo "*******************Have fun !!!********************"
echo "***************************************************"
echo
exit 0