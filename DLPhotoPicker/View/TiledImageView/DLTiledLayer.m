//
//  DLTiledLayer.m
//  DLPhotoPickerDemo
//
//  Created by 沧海无际 on 2017/5/7.
//  Copyright © 2017年 darling0825. All rights reserved.
//

#import "DLTiledLayer.h"

CFTimeInterval adjustableFadeDuration = 0.25;

@implementation DLTiledLayer

+ (CFTimeInterval)fadeDuration {
    return adjustableFadeDuration;
}

+ (void)setFadeDuration:(CFTimeInterval)fadeDuration {
    adjustableFadeDuration = fadeDuration;
}

@end
