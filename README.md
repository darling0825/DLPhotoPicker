# DLPhotoPicker
iOS control that allows picking or displaying photos and videos from user's photo library.

[![Build Status](https://travis-ci.org/darling0825/DLPhotoPicker.svg?branch=master)](https://travis-ci.org/darling0825/DLPhotoPicker)
[![codecov.io](https://codecov.io/github/darling0825/DLPhotoPicker/coverage.svg?branch=master)](https://codecov.io/github/darling0825/DLPhotoPicker?branch=master)
[![GitHub license](https://img.shields.io/badge/license-MIT-blue.svg)](https://raw.githubusercontent.com/darling0825/DLPhotoPicker/master/LICENSE)
[![Twitter](https://img.shields.io/twitter/url/https/github.com/darling0825/DLPhotoPicker.svg?style=social)](https://twitter.com/intent/tweet?text=Wow:&url=%5Bobject%20Object%5D)

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
![image](https://github.com/darling0825/DLPhotoPicker/blob/master/Screenshot/01.PNG)
![image](https://github.com/darling0825/DLPhotoPicker/blob/master/Screenshot/02.PNG)
![image](https://github.com/darling0825/DLPhotoPicker/blob/master/Screenshot/03.PNG)
![image](https://github.com/darling0825/DLPhotoPicker/blob/master/Screenshot/04.PNG)
![image](https://github.com/darling0825/DLPhotoPicker/blob/master/Screenshot/05.PNG)
![image](https://github.com/darling0825/DLPhotoPicker/blob/master/Screenshot/06.PNG)
![image](https://github.com/darling0825/DLPhotoPicker/blob/master/Screenshot/07.PNG)
![image](https://github.com/darling0825/DLPhotoPicker/blob/master/Screenshot/08.PNG)
![image](https://github.com/darling0825/DLPhotoPicker/blob/master/Screenshot/09.PNG)
![image](https://github.com/darling0825/DLPhotoPicker/blob/master/Screenshot/10.PNG)


# Usage

First import header file: DLPhotoPicker.h

To display all albums and photos.
```
- (IBAction)clickPhotoDisplayAction:(id)sender 
{
    DLPhotoPickerViewController *picker = [[DLPhotoPickerViewController alloc] init];
    picker.delegate = self;
    picker.pickerType = DLPhotoPickerTypeDisplay;
    picker.showsNumberOfAssets = YES;
    picker.navigationTitle = NSLocalizedString(@"Albums", nil);
    
    [self presentViewController:picker animated:YES completion:nil];
  }
```

To pick photo or video from photo library.
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
