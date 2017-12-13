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
@class DLPhotoCollectionViewController;

@protocol DLPhotoCollectionViewControllerDelegate <NSObject>

- (void)collectionViewController:(DLPhotoCollectionViewController *)controller photoLibraryDidChangeForPhotoCollection:(DLPhotoCollection *)assetCollection;

@end

@interface DLPhotoCollectionViewController : UICollectionViewController

@property (nonatomic, weak) id<DLPhotoCollectionViewControllerDelegate> delegate;

@property (nonatomic, strong) DLPhotoCollection *photoCollection;

/**
 *  Reload Data
 */
- (void)reloadData;

/**
 *  Call this method after receive notification of ALAssetsLibraryChangedNotification
 */
- (void)resetAssetsAndReload;
@end
