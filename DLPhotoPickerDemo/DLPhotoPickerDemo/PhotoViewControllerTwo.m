//
//  PhotoViewControllerTwo.m
//  DLPhotoPickerDemo
//
//  Created by 沧海无际 on 16/3/14.
//  Copyright © 2016年 darling0825. All rights reserved.
//

#import "PhotoViewControllerTwo.h"

@interface PhotoViewControllerTwo()<UINavigationControllerDelegate,DLPhotoPickerViewControllerDelegate>
@property (nonatomic, copy) NSArray *assets;
@end

@implementation PhotoViewControllerTwo

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.delegate = self;
        self.showsNumberOfAssets = YES;
        self.showsCancelButton = NO;
        self.hidesBottomBarWhenPushedInAssetView = YES;
        self.navigationTitle = NSLocalizedString(@"Albums", nil);
        self.pickerType = DLPhotoPickerTypeDisplay;
    }
    return self;
}


-(void)pickerController:(DLPhotoPickerViewController *)picker didFinishPickingAssets:(NSArray *)assets
{
    self.assets = [NSArray arrayWithArray:assets];
    
    // to operation with 'self.assets'
}

@end
