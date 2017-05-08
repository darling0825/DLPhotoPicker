//
//  DLTiledLayer.h
//  DLPhotoPickerDemo
//
//  Created by 沧海无际 on 2017/5/7.
//  Copyright © 2017年 darling0825. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

@interface DLTiledLayer : CATiledLayer

+ (CFTimeInterval)fadeDuration;
+ (void)setFadeDuration:(CFTimeInterval)fadeDuration;

@end
