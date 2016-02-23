//
//  DLPhotoAsset.m
//  DLPhotoPicker
//
//  Created by 沧海无际 on 16/2/20.
//  Copyright © 2016年 darling0825. All rights reserved.
//

#import "DLPhotoAsset.h"
#import "DLPhotoPickerDefines.h"

@implementation DLPhotoAsset
- (id)initWithAsset:(PHAsset *)asset
{
    self = [super init];
    if (self) {
        _asset = asset;
    }
    return self;
}

- (DLPhotoMediaType)mediaType
{
    if (DLiOS_8_OR_LATER) {
        if (_asset.mediaType == PHAssetMediaTypeImage) {
            return DLPhotoMediaTypeImage;
        }else if (_asset.mediaType == PHAssetMediaTypeVideo){
            return DLPhotoMediaTypeVideo;
        }
    }else{
        
    }
    
    return DLPhotoMediaTypeUnknown;
}

@end
