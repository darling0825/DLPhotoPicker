//
//  DLPhotoAsset.h
//  DLPhotoPicker
//
//  Created by 沧海无际 on 16/2/20.
//  Copyright © 2016年 darling0825. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>

typedef NS_ENUM(NSInteger, DLPhotoMediaType) {
    DLPhotoMediaTypeUnknown = 0,
    DLPhotoMediaTypeImage   = 1,
    DLPhotoMediaTypeVideo   = 2,
};

@interface DLPhotoAsset : NSObject

@property (nonatomic, strong) PHAsset *asset;

- (id)initWithAsset:(PHAsset *)asset;
- (DLPhotoMediaType)mediaType;

@end
