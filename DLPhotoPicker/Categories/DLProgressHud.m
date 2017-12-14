//
//  SVProgressHUD+Extension.m
//  DLPhotoPickerDemo
//
//  Created by 沧海无际 on 2016/11/8.
//  Copyright © 2016年 darling0825. All rights reserved.
//

#import "DLProgressHud.h"
#import "SVProgressHUD.h"

@implementation DLProgressHud
+ (void)showActivity {
    [SVProgressHUD setDefaultStyle:SVProgressHUDStyleCustom];
    [SVProgressHUD setForegroundColor:[UIColor lightGrayColor]];
    [SVProgressHUD setBackgroundColor:[UIColor clearColor]];
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
    [SVProgressHUD setDefaultAnimationType:SVProgressHUDAnimationTypeNative];
    [SVProgressHUD show];
}

+ (void)showSuccessStatus:(NSString *)status {
    [SVProgressHUD setDefaultStyle:SVProgressHUDStyleCustom];
    [SVProgressHUD setForegroundColor:[UIColor grayColor]];
    [SVProgressHUD setBackgroundColor:[UIColor clearColor]];
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
    [SVProgressHUD setDefaultAnimationType:SVProgressHUDAnimationTypeFlat];
    [SVProgressHUD showSuccessWithStatus:status];
}

+ (void)dismiss {
    [SVProgressHUD dismiss];
}
@end
