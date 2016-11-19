//
//  SVProgressHUD+Extension.h
//  DLPhotoPickerDemo
//
//  Created by 沧海无际 on 2016/11/8.
//  Copyright © 2016年 darling0825. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DLProgressHud : NSObject 
+ (void)showActivity;
+ (void)showSuccessStatus:(NSString *)status;
+ (void)dismiss;
@end
