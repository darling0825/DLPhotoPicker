# DLPhotoPicker
iOS control that allows picking or displaying photos and videos from user's photo library.

# Installation with CocoaPods
[CocoaPods](http://cocoapods.org) is a dependency manager for Objective-C, which automates and simplifies the process of using 3rd-party libraries like DLPhotoPicker in your projects.  You can install it with the following command:

```
$ gem install cocoapods
```

# Podfile
To integrate DLPhotoPicker into your Xcode project using CocoaPods, specify it in your Podfile:

```
pod 'DLPhotoPicker'
```

Then, run the following command:
```
$ pod install
```
# Screenshot
![image](https://github.com/darling0825/DLPhotoPicker/Screenshot/01.jpg)
![image](https://github.com/darling0825/DLPhotoPicker/Screenshot/02.jpg)
![image](https://github.com/darling0825/DLPhotoPicker/Screenshot/03.jpg)
![image](https://github.com/darling0825/DLPhotoPicker/Screenshot/04.jpg)
![image](https://github.com/darling0825/DLPhotoPicker/Screenshot/05.jpg)
![image](https://github.com/darling0825/DLPhotoPicker/Screenshot/06.jpg)
![image](https://github.com/darling0825/DLPhotoPicker/Screenshot/07.jpg)
![image](https://github.com/darling0825/DLPhotoPicker/Screenshot/08.jpg)
![image](https://github.com/darling0825/DLPhotoPicker/Screenshot/09.jpg)
![image](https://github.com/darling0825/DLPhotoPicker/Screenshot/10.jpg)


# Usage

# import header file: DLPhotoPicker.h

### To display all albums and photos.
```
- (IBAction)clickPhotoDisplayAction:(id)sender {
    DLPhotoPickerViewController *picker = [[DLPhotoPickerViewController alloc] init];
    picker.delegate = self;
    picker.pickerType = DLPhotoPickerTypeDisplay;
    picker.showsNumberOfAssets = YES;
    picker.navigationTitle = NSLocalizedString(@"Albums", nil);
    
    [self presentViewController:picker animated:YES completion:nil];
  }
```
### To pick photo or video from photo library.
```
- (void)pickAssets:(id)sender
{
    DLPhotoPickerViewController *picker = [[DLPhotoPickerViewController alloc] init];
    picker.delegate = self;
    picker.pickerType = DLPhotoPickerTypePicker;
    picker.navigationTitle = NSLocalizedString(@"Albums", nil);
    
    [self presentViewController:picker animated:YES completion:nil];
}
```
# License
DLPhotoPicker is released under the MIT license. See LICENSE for details.
