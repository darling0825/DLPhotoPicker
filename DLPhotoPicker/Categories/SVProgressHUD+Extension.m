//
//  SVProgressHUD+Extension.m
//  DLPhotoPickerDemo
//
//  Created by 沧海无际 on 2016/11/8.
//  Copyright © 2016年 darling0825. All rights reserved.
//

#import "SVProgressHUD+Extension.h"


@implementation SVProgressHUD(Extension)
+ (void)showActivity {
    [SVProgressHUD setDefaultStyle:SVProgressHUDStyleCustom];
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeClear];
    [SVProgressHUD setBackgroundColor:[UIColor clearColor]];
    [SVProgressHUD show];
}

+ (void)showSuccessStatus:(NSString *)status {
    [SVProgressHUD setDefaultStyle:SVProgressHUDStyleDark];
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeClear];
    [SVProgressHUD showSuccessWithStatus:status];
}
@end
