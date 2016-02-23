//
//  DLPhotoCollection.m
//  DLPhotoPicker
//
//  Created by 沧海无际 on 16/2/20.
//  Copyright © 2016年 darling0825. All rights reserved.
//

#import "DLPhotoCollection.h"
#import "DLPhotoPickerDefines.h"
#import "DLPhotoManager.h"

@implementation DLPhotoCollection

- (id)initWithAssetCollection:(PHAssetCollection *)assetCollection
{
    self = [super init];
    if (self) {
        _assetCollection = assetCollection;
    }
    return self;
}

- (NSString *)title
{
    if (DLiOS_8_OR_LATER) {
        return self.assetCollection.localizedTitle;
    }else{
        return @"ios7";
    }
}

- (NSUInteger)count
{
    if (DLiOS_8_OR_LATER) {
        return [[DLPhotoManager sharedInstance] assetCountOfCollection:self];
    }else{
        return 0;
    }
}

@end
