//
//  DLPhotoCollectionViewCell.h
//  DLPhotoPicker
//
//  Created by 沧海无际 on 16/2/21.
//  Copyright © 2016年 darling0825. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DLPhotoAsset.h"
#import "DLPhotoThumbnailView.h"

@interface DLPhotoCollectionViewCell : UICollectionViewCell

@property (nonatomic, assign, getter = isEnabled) BOOL enabled;
@property (nonatomic, assign, getter = isShowCheckMark) BOOL showCheckMark;

@property (nonatomic, weak) UIColor *disabledColor UI_APPEARANCE_SELECTOR;
@property (nonatomic, weak) UIColor *highlightedColor UI_APPEARANCE_SELECTOR;

- (void)bind:(DLPhotoAsset *)asset;
@end
