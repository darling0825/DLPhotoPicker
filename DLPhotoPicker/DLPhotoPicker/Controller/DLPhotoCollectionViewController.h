//
//  DLPhotoCollectionViewController.h
//  DLPhotoPicker
//
//  Created by 沧海无际 on 16/2/20.
//  Copyright © 2016年 darling0825. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DLPhotoCollection;
@class DLPhotoPickerViewController;

@interface DLPhotoCollectionViewController : UICollectionViewController

@property (nonatomic, weak) DLPhotoPickerViewController *picker;

@property (nonatomic, strong) DLPhotoCollection *photoCollection;

@property (nonatomic, strong) NSMutableArray *selectedAssets;

/**
 modifying status
 */
@property (nonatomic, assign, getter=isModifying) BOOL modifying;

@end
