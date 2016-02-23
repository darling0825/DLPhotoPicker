//
//  DLPhotoTableViewController.h
//  DLPhotoPicker
//
//  Created by 沧海无际 on 16/2/20.
//  Copyright © 2016年 darling0825. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DLPhotoPickerViewController;

@interface DLPhotoTableViewController : UITableViewController

@property (nonatomic, weak) DLPhotoPickerViewController *picker;

/**
 Array used to specify which albums to be shown in table view.
 */
@property (nonatomic, strong) NSArray *assetCollections;

@end
