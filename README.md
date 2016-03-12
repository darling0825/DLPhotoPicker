# DLPhotoPicker

[![Build Status](https://travis-ci.org/darling0825/DLPhotoPicker.svg?branch=master)](https://travis-ci.org/darling0825/DLPhotoPicker)
[![codecov.io](https://codecov.io/github/darling0825/DLPhotoPicker/coverage.svg?branch=master)](https://codecov.io/github/darling0825/DLPhotoPicker?branch=master)
[![CocoaPods](https://img.shields.io/cocoapods/v/DLPhotoPicker.svg)]()
[![GitHub watchers](https://img.shields.io/github/watchers/darling0825/DLPhotoPicker.svg?style=social&label=Watch)]()
[![GitHub stars](https://img.shields.io/github/stars/darling0825/DLPhotoPicker.svg)](https://github.com/darling0825/DLPhotoPicker/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/darling0825/DLPhotoPicker.svg)](https://github.com/darling0825/DLPhotoPicker/network)
[![GitHub issues](https://img.shields.io/github/issues/darling0825/DLPhotoPicker.svg)](https://github.com/darling0825/DLPhotoPicker/issues)
[![GitHub license](https://img.shields.io/badge/license-MIT-blue.svg)](https://raw.githubusercontent.com/darling0825/DLPhotoPicker/master/LICENSE)
[![Twitter](https://img.shields.io/twitter/url/https/github.com/darling0825/DLPhotoPicker.svg?style=social)](https://twitter.com/intent/tweet?text=Wow:&url=%5Bobject%20Object%5D)

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
![image](https://github.com/darling0825/DLPhotoPicker/blob/master/Screenshot/11.PNG)
![image](https://github.com/darling0825/DLPhotoPicker/blob/master/Screenshot/12.PNG)
![image](https://github.com/darling0825/DLPhotoPicker/blob/master/Screenshot/13.PNG)
![image](https://github.com/darling0825/DLPhotoPicker/blob/master/Screenshot/14.PNG)

#Features
- Support AssetsLibrary(iOS7) and Photos(iOS 8 or later) framework.
- Support photo display, edit and pick.
- Suppert save the photo to a album and save to document of app sandbox.

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

The Delegate of DLPhotoPicker
```
-(void)pickerController:(DLPhotoPickerViewController *)picker didFinishPickingAssets:(NSArray *)assets
{
    [self dismissViewControllerAnimated:YES completion:nil];
    
    self.assets = [NSArray arrayWithArray:assets];
    
    // to operation with 'self.assets'
}

- (BOOL)pickerController:(DLPhotoPickerViewController *)picker shouldScrollToBottomForPhotoCollection:(DLPhotoCollection *)assetCollection;
{
    return YES;
}

- (BOOL)pickerController:(DLPhotoPickerViewController *)picker shouldEnableAsset:(DLPhotoAsset *)asset
{
    return YES;
}

- (BOOL)pickerController:(DLPhotoPickerViewController *)picker shouldSelectAsset:(DLPhotoAsset *)asset
{
    NSInteger max = 10;
    
    if (picker.selectedAssets.count >= max){
        UIAlertController *alert =
        [UIAlertController alertControllerWithTitle:@"Attention"
                                            message:[NSString stringWithFormat:@"Please select not more than %ld assets", (long)max]
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *action =
        [UIAlertAction actionWithTitle:@"OK"
                                 style:UIAlertActionStyleDefault
                               handler:nil];
        
        [alert addAction:action];
        
        [picker presentViewController:alert animated:YES completion:nil];
    }
    
    // limit selection to max
    return (picker.selectedAssets.count < max);
    
    return YES;
}

- (void)pickerController:(DLPhotoPickerViewController *)picker didSelectAsset:(DLPhotoAsset *)asset
{
    // didSelectAsset
}

- (BOOL)pickerController:(DLPhotoPickerViewController *)picker shouldDeselectAsset:(DLPhotoAsset *)asset
{
    return YES;
}

- (void)pickerController:(DLPhotoPickerViewController *)picker didDeselectAsset:(DLPhotoAsset *)asset
{
    // didDeselectAsset
}

- (BOOL)pickerController:(DLPhotoPickerViewController *)picker shouldHighlightAsset:(DLPhotoAsset *)asset
{
    return YES;
}

- (void)pickerController:(DLPhotoPickerViewController *)picker didHighlightAsset:(DLPhotoAsset *)asset
{
   //  didHighlightAsset
}
```

# License
DLPhotoPicker is released under the MIT license. See LICENSE for details.
