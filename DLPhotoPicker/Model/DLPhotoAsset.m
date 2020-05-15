//
//  DLPhotoAsset.m
//  DLPhotoPicker
//
//  Created by 沧海无际 on 16/2/20.
//  Copyright © 2016年 darling0825. All rights reserved.
//

#import "DLPhotoAsset.h"
#import "DLPhotoManager.h"

#import "UIImage+DLPhotoPicker.h"
#import "DLPhotoPickerDefines.h"


@interface DLPhotoAsset()

@property (nonatomic, strong) NSDictionary *phAssetInfo;

@property (nonatomic, strong) UIImage *originImage;
@property (nonatomic, strong) NSData *originImageData;
@property (nonatomic, strong) UIImage *thumbnailImage;
@property (nonatomic, strong) UIImage *previewImage;

@property (nonatomic, strong) AVPlayerItem *avPlayerItem;

@property (nonatomic, assign) PHImageRequestID imageRequestID;
@property (nonatomic, assign) PHImageRequestID avAssetRequestID;

@end

@implementation DLPhotoAsset

- (id)initWithAsset:(id)asset
{
    self = [super init];
    if (self) {
        if ([asset isKindOfClass:[PHAsset class]]) {
            _phAsset = asset;
        }
    }
    return self;
}

//  override
- (BOOL)isEqual:(DLPhotoAsset *)object
{
    return [self.phAsset.localIdentifier isEqual:object.phAsset.localIdentifier];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@{%@}",self.fileName,self.url];
}

#pragma mark - Accessers
- (DLPhotoMediaType)mediaType
{
    if (_phAsset.mediaType == PHAssetMediaTypeImage) {
        return DLPhotoMediaTypeImage;
    }else if (_phAsset.mediaType == PHAssetMediaTypeVideo){
        return DLPhotoMediaTypeVideo;
    }else{
        return DLPhotoMediaTypeUnknown;
    }
    
    return DLPhotoMediaTypeUnknown;
}

- (CGSize)assetdimensions
{
    return CGSizeMake(self.phAsset.pixelWidth, self.phAsset.pixelHeight);
}

- (UIImageOrientation)imageOrientation
{
    __block UIImageOrientation orientation = 0;
    if (!_phAssetInfo) {
        // PHAsset 的 UIImageOrientation 需要调用过 requestImageDataForAsset 才能获取
        [self requestPHAssetInfo:^(NSDictionary *info) {
            _phAssetInfo = [NSDictionary dictionaryWithDictionary:info];
            orientation = (UIImageOrientation)[_phAssetInfo[@"PHImageFileOrientationKey"] integerValue];
        }];
    }

    return orientation;
}

- (long long)fileSize
{
    __block long long size = 0;
    if (!_phAssetInfo) {
        // PHAsset 的 assetSize 需要调用过 requestImageDataForAsset 才能获取
        [self requestPHAssetInfo:^(NSDictionary *info) {
            _phAssetInfo = [NSDictionary dictionaryWithDictionary:info];
            size = [(NSData *)_phAssetInfo[@"PHImageFileDataKey"] length];
        }];
    }else{
        size = [(NSData *)_phAssetInfo[@"PHImageFileDataKey"] length];
    }
    return size;
}

- (NSString *)fileName
{
    __block NSString *name = @"";
    // if (!_phAssetInfo) {
    //     // PHAsset 的 assetSize 需要调用过 requestImageDataForAsset 才能获取
    //     [self requestPHAssetInfo:^(NSDictionary *info) {
    //         _phAssetInfo = [NSDictionary dictionaryWithDictionary:info];
    //         if ([_phAssetInfo objectForKey:@"PHImageFileURLKey"]) {
    //             /* path looks like this -
    //              * file:///var/mobile/Media/DCIM/###APPLE/IMG_####.JPG
    //              */
    //             name = [[_phAssetInfo objectForKey:@"PHImageFileURLKey"] lastPathComponent];
    //         }
    //     }];
    // }else{
    //     name = [[_phAssetInfo objectForKey:@"PHImageFileURLKey"] lastPathComponent];
    // }
    name = [[self phAsset] valueForKey:@"filename"];
    
    return name;
}

- (NSDate *)createDate
{
    return self.phAsset.creationDate;
}

/**
 *  url
 *
 *  iOS 8 or later  : "file:///var/mobile/Media/DCIM/102APPLE/IMG_2215.PNG"
 *  iOS 7           : "assets-library://asset/asset.JPG?id=08FCD299-9B14-4065-860D-A843D615561E&ext=JPG"
 *  @return NSURL
 */
- (NSURL *)url
{
    __block NSURL *url = nil;
    if (!_phAssetInfo) {
        // PHAsset 的 assetSize 需要调用过 requestImageDataForAsset 才能获取
        [self requestPHAssetInfo:^(NSDictionary *info) {
            _phAssetInfo = [NSDictionary dictionaryWithDictionary:info];
            if ([_phAssetInfo objectForKey:@"PHImageFileURLKey"]) {
                /* path looks like this -
                 * file:///var/mobile/Media/DCIM/###APPLE/IMG_####.JPG
                 */
                url = [_phAssetInfo objectForKey:@"PHImageFileURLKey"];
            }
        }];
    } else {
        url = [_phAssetInfo objectForKey:@"PHImageFileURLKey"];
    }
    
    return url;
}

- (NSTimeInterval)duration
{
    if (self.mediaType == DLPhotoMediaTypeVideo) {
        return self.phAsset.duration;
    }
    return 0;
}

- (UIImage *)badgeImage
{
    NSString *imageName = nil;
    
    if (self.isHighFrameRateVideo){
        imageName = @"BadgeSlomoSmall";
    }
    else if (self.isTimelapseVideo){
        imageName = @"BadgeTimelapseSmall";
    }
    else if (self.isVideo){
        imageName = @"BadgeVideoSmall";
    }
    
    if (imageName){
        return [[UIImage assetImageNamed:imageName] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }else{
        return nil;
    }
}

- (NSString *)accessibilityLabel
{
    return self.phAsset.accessibilityLabel;
}

- (BOOL)isHighFrameRateVideo
{
    return (self.phAsset.mediaType == PHAssetMediaTypeVideo &&
            (self.phAsset.mediaSubtypes & PHAssetMediaSubtypeVideoHighFrameRate));
}

- (BOOL)isTimelapseVideo
{
    return (self.phAsset.mediaType == PHAssetMediaTypeVideo &&
            (self.phAsset.mediaSubtypes & PHAssetMediaSubtypeVideoTimelapse));
}

- (BOOL)isVideo
{
    return [self mediaType] == DLPhotoMediaTypeVideo;
}

- (BOOL)deletable
{
    return [self.phAsset canPerformEditOperation:PHAssetEditOperationDelete];
}

- (BOOL)editable
{
    return [self.phAsset canPerformEditOperation:PHAssetEditOperationProperties];
}

#pragma mark - Cancel Request Image
- (void)cancelRequestAsset
{
    [self cancelRequestImage];
    [self cancelRequestVideo];
}

- (BOOL)cancelRequestImage
{
    if (self.imageRequestID){
        [[[DLPhotoManager sharedInstance] phCachingImageManager] cancelImageRequest:self.imageRequestID];
        return YES;
    }
    return NO;
}

- (BOOL)cancelRequestVideo
{
    if (self.avAssetRequestID){
        [[[DLPhotoManager sharedInstance] phCachingImageManager] cancelImageRequest:self.avAssetRequestID];
        return YES;
    }
    return NO;
}

#pragma mark - Request Image
- (UIImage *)originImage
{
    @autoreleasepool {
        if (_originImage) {
            return _originImage;
        }
        
        __block UIImage *resultImage;
        
        //  image after edited
        PHImageRequestOptions *originRequestOptions = [[PHImageRequestOptions alloc] init];
        originRequestOptions.version = PHImageRequestOptionsVersionCurrent;
        originRequestOptions.networkAccessAllowed = YES;
        originRequestOptions.synchronous = YES;

        //sync requests are automatically processed this way regardless of the specified mode
        //originRequestOptions.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;

        originRequestOptions.progressHandler = ^(double progress, NSError *__nullable error, BOOL *stop, NSDictionary *__nullable info){
            dispatch_main_async_safe(^{

            });
        };

        /*
         Printing description of info:
         {
         PHImageResultDeliveredImageFormatKey = 9999;
         PHImageResultIsDegradedKey = 0;
         PHImageResultIsInCloudKey = 0;
         PHImageResultIsPlaceholderKey = 0;
         PHImageResultWantedImageFormatKey = 9999;
         }
         */

        [[[DLPhotoManager sharedInstance] phCachingImageManager] requestImageForAsset:self.phAsset
                                                                           targetSize:PHImageManagerMaximumSize
                                                                          contentMode:PHImageContentModeDefault
                                                                              options:originRequestOptions
                                                                        resultHandler:^(UIImage *result, NSDictionary *info) {
                                                                            @autoreleasepool {
                                                                                // 排除取消，错误，低清图三种情况，即已经获取到了高清图时，把这张高清图缓存到 _originImage 中
                                                                                BOOL downloadFinined = ![[info objectForKey:PHImageCancelledKey] boolValue] &&
                                                                                ![info objectForKey:PHImageErrorKey] &&
                                                                                ![[info objectForKey:PHImageResultIsDegradedKey] boolValue] && result;

                                                                                if (downloadFinined) {
                                                                                    resultImage = result;
                                                                                }
                                                                            }

                                                                        }];

        /*
         if ([self.phAsset canPerformEditOperation:PHAssetEditOperationContent] &&
         !(self.phAsset.mediaSubtypes & PHAssetMediaSubtypePhotoLive))
         {
         PHContentEditingInputRequestOptions *options = [[PHContentEditingInputRequestOptions alloc] init];
         options.networkAccessAllowed = YES;
         options.canHandleAdjustmentData = ^BOOL(PHAdjustmentData *adjustmentData) { return YES; };

         //  We synchronously have the asset
         dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

         [self.phAsset requestContentEditingInputWithOptions:options
         completionHandler:^(PHContentEditingInput *contentEditingInput, NSDictionary *info) {


         //http://www.cnblogs.com/crazypebble/p/5259641.html

         NSURL *url = [contentEditingInput fullSizeImageURL];
         NSData *imageData = [NSData dataWithContentsOfURL:url];
         resultImage = [[UIImage alloc] initWithData:imageData];

         dispatch_semaphore_signal(semaphore);

         }];

         dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
         }
         */

        // 不能及时释放内存
        //_originImage = resultImage;
        
        //return resultImage ? resultImage : [self originImage];
        return resultImage;
    }
}

- (NSData *)originImageData {
    @autoreleasepool {
        if (_originImageData) {
            return _originImageData;
        }
        
        __block NSData *resultImageData;
        
        //  image after edited
        PHImageRequestOptions *originRequestOptions = [[PHImageRequestOptions alloc] init];
        originRequestOptions.version = PHImageRequestOptionsVersionCurrent;
        originRequestOptions.networkAccessAllowed = YES;
        originRequestOptions.synchronous = YES;
        
        //sync requests are automatically processed this way regardless of the specified mode
        //originRequestOptions.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
        
        originRequestOptions.progressHandler = ^(double progress, NSError *__nullable error, BOOL *stop, NSDictionary *__nullable info){
            dispatch_main_async_safe(^{
                
            });
        };
        
        [[[DLPhotoManager sharedInstance] phCachingImageManager] requestImageDataForAsset:self.phAsset
                                                                                  options:originRequestOptions
                                                                            resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info)
        {
            @autoreleasepool {
                // 排除取消，错误，低清图三种情况，即已经获取到了高清图时，把这张高清图缓存到 _originImage 中
                BOOL downloadFinined = ![[info objectForKey:PHImageCancelledKey] boolValue] &&
                ![info objectForKey:PHImageErrorKey] &&
                ![[info objectForKey:PHImageResultIsDegradedKey] boolValue] && imageData;
                
                if (downloadFinined) {
                    resultImageData = imageData;
                }
            }
        }];
        
        // 不能及时释放内存
        //_originImageData = resultImageData;
        
        //return resultImageData ? resultImageData : [self originImageData];
        return resultImageData;
    }
}

/**
 *  synchronous：    指定请求是否同步执行。
 *  resizeMode：     对请求的图像怎样缩放。有三种选择：None，不缩放；Fast，尽快地提供接近或稍微大于要求的尺寸；Exact，精准提供要求的尺寸。
 *  deliveryMode：   图像质量。有三种值：Opportunistic，在速度与质量中均衡；
 *                   HighQualityFormat，不管花费多长时间，提供高质量图像；
 *                   FastFormat，以最快速度提供好的质量。这个属性只有在 synchronous 为 true 时有效。
 *  normalizedCropRect：用于对原始尺寸的图像进行裁剪，基于比例坐标。只在 resizeMode 为 Exact 时有效。
 */

/**
 *  .Current 会递送包含所有调整和修改的图像；
 *  .Unadjusted 会递送未被施加任何修改的图像；
 *  .Original 会递送原始的、最高质量的格式的图像
 *  (例如 RAW 格式的数据。而当将属性设置为 .Unadjusted 时，会递送一个 JPEG)

 */
- (NSInteger)requestOriginImageWithCompletion:(void (^)(UIImage *, NSDictionary *))completion
                          withProgressHandler:(PHAssetImageProgressHandler)phProgressHandler
{
    @autoreleasepool {
        if (_originImage) {
            // 如果已经有缓存的图片则直接拿缓存的图片
            dispatch_main_async_safe(^{
                if (completion) {
                    completion(_originImage, nil);
                }
            })
            return 0;
        } else {

            PHImageRequestOptions *originRequestOptions = [[PHImageRequestOptions alloc] init];
            // 允许访问网络
            originRequestOptions.version = PHImageRequestOptionsVersionCurrent;
            originRequestOptions.networkAccessAllowed = YES;
            originRequestOptions.progressHandler = phProgressHandler;
            self.imageRequestID = [[[DLPhotoManager sharedInstance] phCachingImageManager]
                                   requestImageForAsset:self.phAsset
                                   targetSize:PHImageManagerMaximumSize
                                   contentMode:PHImageContentModeDefault
                                   options:originRequestOptions
                                   resultHandler:^(UIImage *result, NSDictionary *info) {
                                       @autoreleasepool {
                                           // 排除取消，错误，低清图三种情况，即已经获取到了高清图时，把这张高清图缓存到 _originImage 中
                                           BOOL downloadFinined = ![[info objectForKey:PHImageCancelledKey] boolValue] &&
                                           ![info objectForKey:PHImageErrorKey] &&
                                           ![[info objectForKey:PHImageResultIsDegradedKey] boolValue];

                                           if (downloadFinined) {
                                               //_originImage = result;
                                               if (completion) {
                                                   completion(result, info);
                                               }
                                           }
                                       }
                                   }];

            return self.imageRequestID;

            /*
             // Completion and progress handlers are called on an arbitrary serial queue.
             if ([self.phAsset canPerformEditOperation:PHAssetEditOperationContent] &&
             !(self.phAsset.mediaSubtypes & PHAssetMediaSubtypePhotoLive))
             {
             PHContentEditingInputRequestOptions *options = [[PHContentEditingInputRequestOptions alloc] init];
             options.networkAccessAllowed = YES;
             options.canHandleAdjustmentData = ^BOOL(PHAdjustmentData *adjustmentData) {return YES;};

             [self.phAsset requestContentEditingInputWithOptions:options
             completionHandler:^(PHContentEditingInput *contentEditingInput, NSDictionary *info) {
             NSURL *url = [contentEditingInput fullSizeImageURL];
             NSData *imageData = [NSData dataWithContentsOfURL:url];
             _originImage = [[UIImage alloc] initWithData:imageData];
             }];
             }

             return 0;
             */
        }
    }
}

- (NSInteger)requestOriginImageDataWithCompletion:(void (^)(NSData *, NSDictionary *))completion
                              withProgressHandler:(PHAssetImageProgressHandler)phProgressHandler
{
    @autoreleasepool {
        if (_originImageData) {
            // 如果已经有缓存的图片则直接拿缓存的图片
            dispatch_main_async_safe(^{
                if (completion) {
                    completion(_originImageData, nil);
                }
            })
            return 0;
        } else {
            
            PHImageRequestOptions *originRequestOptions = [[PHImageRequestOptions alloc] init];
            // 允许访问网络
            originRequestOptions.version = PHImageRequestOptionsVersionCurrent;
            originRequestOptions.networkAccessAllowed = YES;
            originRequestOptions.progressHandler = phProgressHandler;
            self.imageRequestID = [[[DLPhotoManager sharedInstance] phCachingImageManager]
                                   requestImageDataForAsset:self.phAsset
                                   options:originRequestOptions
                                   resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info)
                                   {
                                       @autoreleasepool {
                                           // 排除取消，错误，低清图三种情况，即已经获取到了高清图时，把这张高清图缓存到 _originImage 中
                                           BOOL downloadFinined = ![[info objectForKey:PHImageCancelledKey] boolValue] &&
                                           ![info objectForKey:PHImageErrorKey] &&
                                           ![[info objectForKey:PHImageResultIsDegradedKey] boolValue];
                                           
                                           if (downloadFinined) {
                                               //_originImage = result;
                                               if (completion) {
                                                   completion(imageData, info);
                                               }
                                           }
                                       }
                                   }];
            return self.imageRequestID;
        }
    }
}

- (AVAsset *)originVideoAsset
{
    if (_avAsset) {
        return _avAsset;
    }
    __block AVAsset *resultAsset;
    PHVideoRequestOptions *videoRequestOptions = [[PHVideoRequestOptions alloc] init];
    // 允许访问网络
    videoRequestOptions.networkAccessAllowed = YES;
    /**
     *  This will not work with slow motion videos, because AVComposition instead of AVURLAsset is returned.
     *  Possible solution is to use PHVideoRequestOptionsVersionOriginal video file version
     *  http://stackoverflow.com/questions/29774011/upload-videos-from-gallery-using-photos-framework
     */
    videoRequestOptions.version = PHVideoRequestOptionsVersionOriginal;

    //  We synchronously have the asset
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    [[[DLPhotoManager sharedInstance] phCachingImageManager] requestAVAssetForVideo:self.phAsset
                                                                            options:videoRequestOptions
                                                                      resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {

                                                                          resultAsset = asset;
                                                                          dispatch_semaphore_signal(semaphore);
                                                                      }];

    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);

    _avAsset = resultAsset;
    return resultAsset;
}

- (NSInteger)requestOriginAVAssetWithCompletion:(void (^)(AVAsset *asset, AVAudioMix *audioMix, NSDictionary *info))completion
                            withProgressHandler:(PHAssetVideoProgressHandler)progressHandler
{
    if (_avAsset) {
        // 如果已经有缓存的图片则直接拿缓存的图片
        dispatch_main_async_safe(^{
            if (completion) {
                completion(_avAsset, nil, nil);
            }
        })
        return 0;
    } else {
        PHVideoRequestOptions *videoRequestOptions = [[PHVideoRequestOptions alloc] init];
        // 允许访问网络
        videoRequestOptions.networkAccessAllowed = YES;
        videoRequestOptions.progressHandler = progressHandler;
        /**
         *  This will not work with slow motion videos, because AVComposition instead of AVURLAsset is returned.
         *  Possible solution is to use PHVideoRequestOptionsVersionOriginal video file version
         *  http://stackoverflow.com/questions/29774011/upload-videos-from-gallery-using-photos-framework
         */
        videoRequestOptions.version = PHVideoRequestOptionsVersionOriginal;

        self.avAssetRequestID = [[[DLPhotoManager sharedInstance] phCachingImageManager]
                                 requestAVAssetForVideo:self.phAsset
                                 options:videoRequestOptions
                                 resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {

                                     /**
                                      * [asset isKindOfClass:[AVURLAsset class]]
                                      * file:///var/mobile/Media/DCIM/102APPLE/IMG_2241.MOV
                                      */

                                     /**
                                      Printing description of info:
                                      {
                                      PHImageFileSandboxExtensionTokenKey = "d3a4d2f938413e0605d5a0d9d1d81f972e4a1102;00000000;00000000;000000000000001b;com.apple.avasset.read-only;00000001;01000002;000000000193ad8b;/private/var/mobile/Media/DCIM/102APPLE/IMG_2090.MOV";
                                      PHImageResultDeliveredImageFormatKey = 20000;
                                      PHImageResultIsInCloudKey = 0;
                                      PHImageResultWantedImageFormatKey = 20000;
                                      }
                                      */

                                     BOOL downloadFinined = ![[info objectForKey:PHImageCancelledKey] boolValue] &&
                                     ![info objectForKey:PHImageErrorKey] &&
                                     ![[info objectForKey:PHImageResultIsDegradedKey] boolValue];

                                     if (downloadFinined) {
                                         _avAsset = asset;
                                     }

                                     dispatch_main_async_safe(^{
                                         if (completion) {
                                             completion(asset, audioMix, info);
                                         }
                                     })
                                 }];
        return self.avAssetRequestID;
    }
}

- (UIImage *)thumbnailWithSize:(CGSize)size
{
    if (_thumbnailImage) {
        return _thumbnailImage;
    }
    
    __block UIImage *resultImage;
    
    PHImageRequestOptions *thumbnailRequestOptions = [[PHImageRequestOptions alloc] init];
    thumbnailRequestOptions.synchronous = YES;
    thumbnailRequestOptions.resizeMode = PHImageRequestOptionsResizeModeExact;

    /* 在 PHImageManager 中，targetSize 等 size 都是使用 px 作为单位，
     * 因此需要对targetSize 中对传入的 Size 进行处理，宽高各自乘以 ScreenScale，从而得到正确的图片
     */
    [[[DLPhotoManager sharedInstance] phCachingImageManager]
     requestImageForAsset:self.phAsset
     targetSize:CGSizeMake(size.width * ScreenScale, size.height * ScreenScale)
     contentMode:PHImageContentModeAspectFill
     options:thumbnailRequestOptions
     resultHandler:^(UIImage *result, NSDictionary *info) {
         resultImage = result;
     }];
    
    _thumbnailImage = resultImage;
    return resultImage;
}

- (NSInteger)requestThumbnailImageWithSize:(CGSize)size completion:(void (^)(UIImage *, NSDictionary *))completion
{
    if (_thumbnailImage) {
        dispatch_main_async_safe(^{
            if (completion) {
                completion(_thumbnailImage, nil);
            }
        })
        return 0;
    } else {
        PHImageRequestOptions *thumbnailRequestOptions = [[PHImageRequestOptions alloc] init];
        thumbnailRequestOptions.resizeMode = PHImageRequestOptionsResizeModeExact;

        /* 在 PHImageManager 中，targetSize 等 size 都是使用 px 作为单位，
         * 因此需要对targetSize 中对传入的 Size 进行处理，宽高各自乘以 ScreenScale，从而得到正确的图片
        */
        self.imageRequestID = [[[DLPhotoManager sharedInstance] phCachingImageManager]
                               requestImageForAsset:self.phAsset
                               targetSize:CGSizeMake(size.width * ScreenScale, size.height * ScreenScale)
                               contentMode:PHImageContentModeAspectFill
                               options:thumbnailRequestOptions
                               resultHandler:^(UIImage *result, NSDictionary *info) {
                                   // 排除取消，错误，低清图三种情况，即已经获取到了高清图时，把这张高清图缓存到 _thumbnailImage 中
                                   BOOL downloadFinined = ![[info objectForKey:PHImageCancelledKey] boolValue] &&
                                   ![info objectForKey:PHImageErrorKey] &&
                                   ![[info objectForKey:PHImageResultIsDegradedKey] boolValue];
                                   if (downloadFinined) {
                                       _thumbnailImage = result;
                                   }
                                   if (completion) {
                                       completion(result, info);
                                   }
                               }];
        return self.imageRequestID;
    }
}

- (UIImage *)previewImage
{
    if (_previewImage) {
        return _previewImage;
    }
    
    __block UIImage *resultImage;
    
    PHImageRequestOptions *previewRequestOptions = [[PHImageRequestOptions alloc] init];
    previewRequestOptions.synchronous = YES;

    [[[DLPhotoManager sharedInstance] phCachingImageManager]
     requestImageForAsset:_phAsset
     targetSize:CGSizeMake(ScreenWidth*ScreenScale, ScreenHeight*ScreenScale)
     contentMode:PHImageContentModeAspectFill
     options:previewRequestOptions
     resultHandler:^(UIImage *result, NSDictionary *info) {
         resultImage = result;
     }];
    
    _previewImage = resultImage;
    return resultImage;
}

- (NSInteger)requestPreviewImageWithCompletion:(void (^)(UIImage *, NSDictionary *))completion
                           withProgressHandler:(PHAssetImageProgressHandler)progressHandler
{
    if (_previewImage) {
        // 如果已经有缓存的图片则直接拿缓存的图片
        dispatch_main_async_safe(^{
            if (completion) {
                completion(_previewImage, nil);
            }
        })
        return 0;
    }else {
        PHImageRequestOptions *previewRequestOptions = [[PHImageRequestOptions alloc] init];
        // 允许访问网络
        previewRequestOptions.networkAccessAllowed = YES;
        previewRequestOptions.progressHandler = progressHandler;

        self.imageRequestID = [[[DLPhotoManager sharedInstance] phCachingImageManager]
                               requestImageForAsset:self.phAsset
                               targetSize:CGSizeMake(ScreenWidth*ScreenScale, ScreenHeight*ScreenScale)
                               contentMode:PHImageContentModeAspectFill
                               options:previewRequestOptions
                               resultHandler:^(UIImage *result, NSDictionary *info) {
                                   // 排除取消，错误，低清图三种情况，即已经获取到了高清图时，把这张高清图缓存到 _previewImage 中
                                   BOOL downloadFinined = ![[info objectForKey:PHImageCancelledKey] boolValue] &&
                                   ![info objectForKey:PHImageErrorKey] &&
                                   ![[info objectForKey:PHImageResultIsDegradedKey] boolValue];
                                   if (downloadFinined) {
                                       _previewImage = result;
                                   }
                                   if (completion) {
                                       completion(result, info);
                                   }
                               }];
        return self.imageRequestID;
    }
}

/*
 video
 {
 PHImageFileDataKey = <PLXPCShMemData: 0x12e724cf0> bufferLength=3006464 dataLength=3005361;
 PHImageFileOrientationKey = 0;
 PHImageFileSandboxExtensionTokenKey = "b2257165adb127e9bd9a18a0332d719a1f35c591;00000000;00000000;000000000000001a;com.apple.app-sandbox.read;00000001;01000002;0000000001b1e700;/private/var/mobile/Media/DCIM/102APPLE/IMG_2235.MOV";
 PHImageFileURLKey = "file:///var/mobile/Media/DCIM/102APPLE/IMG_2235.MOV";
 PHImageFileUTIKey = "dyn.ah62d4uv4ge804550";
 PHImageResultDeliveredImageFormatKey = 9999;
 PHImageResultIsDegradedKey = 0;
 PHImageResultIsInCloudKey = 0;
 PHImageResultIsPlaceholderKey = 0;
 PHImageResultWantedImageFormatKey = 9999;
 }
 
 image
 {
 PHImageFileDataKey = <PLXPCShMemData: 0x13eff1d20> bufferLength=1110016 dataLength=1107049;
 PHImageFileOrientationKey = 0;
 PHImageFileSandboxExtensionTokenKey = "c6a8f058f6fdd15b1160980b54a95db4088c3f95;00000000;00000000;000000000000001a;com.apple.app-sandbox.read;00000001;01000002;0000000001a712ca;/private/var/mobile/Media/DCIM/102APPLE/IMG_2215.PNG";
 PHImageFileURLKey = "file:///var/mobile/Media/DCIM/102APPLE/IMG_2215.PNG";
 PHImageFileUTIKey = "public.png";
 PHImageResultDeliveredImageFormatKey = 9999;
 PHImageResultIsDegradedKey = 0;
 PHImageResultIsInCloudKey = 0;
 PHImageResultIsPlaceholderKey = 0;
 PHImageResultWantedImageFormatKey = 9999;
 }
 */

- (void)requestPHAssetInfo:(void (^)(NSDictionary *info))completion
{
    PHImageRequestOptions *imageRequestOptions = [[PHImageRequestOptions alloc] init];
    imageRequestOptions.synchronous = YES;
    
    [[[DLPhotoManager sharedInstance] phCachingImageManager]
     requestImageDataForAsset:self.phAsset
     options:imageRequestOptions
     resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
        completion(info);
    }];
}

#pragma mark - Write to file
- (BOOL)writeOriginImageToFile:(NSString *)filePath
{
    __block BOOL result = NO;
    NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
    [fileCoordinator coordinateWritingItemAtURL:[NSURL fileURLWithPath:filePath]
                                        options:NSFileCoordinatorWritingForReplacing
                                          error:nil
                                     byAccessor:^(NSURL * _Nonnull accessorUrl) {
        
        UIImage *image = [self originImage];
        if (image) {
            NSData *data = UIImagePNGRepresentation(image);
            if (data) {
                result = [data writeToFile:accessorUrl.path atomically:YES];
            }
        }
    }];
    
    return result;
}

- (void)writeOriginImageToFile:(NSString *)filePath
               progressHandler:(void (^)(double progress))progressHandler
             completionHandler:(void (^)(BOOL success, NSError *error))completionHandler
{
    NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
    [fileCoordinator coordinateWritingItemAtURL:[NSURL fileURLWithPath:filePath] options:NSFileCoordinatorWritingForReplacing error:nil byAccessor:^(NSURL * _Nonnull accessorUrl) {
        [self requestOriginImageDataWithCompletion:^(NSData *data, NSDictionary *info) {
            NSError *error = [info objectForKey:PHImageErrorKey];
            if (error){
                if (completionHandler) {
                    completionHandler(NO, error);
                }
            }else{
                if (data) {
                    [data writeToFile:accessorUrl.path atomically:YES];
                    if (progressHandler) {
                        progressHandler(1.0);
                    }
                }
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    if (completionHandler) {
                        completionHandler(data != nil, nil);
                    }
                });
            }
        } withProgressHandler:^(double progress, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
            if (progressHandler) {
                progressHandler(progress);
            }
        }];

        /*
        [self requestOriginImageWithCompletion:^(UIImage *image, NSDictionary *info) {
            NSError *error = [info objectForKey:PHImageErrorKey];
            if (error){
                if (completionHandler) {
                    completionHandler(NO, error);
                }
            }else{
                if (image) {
                    NSData *data = UIImagePNGRepresentation(image);
                    if (data) {
                        [data writeToFile:accessorUrl.path atomically:YES];
                        if (progressHandler) {
                            progressHandler(1.0);
                        }
                    }
                }
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    if (completionHandler) {
                        completionHandler(image != nil, nil);
                    }
                });
            }
        } withProgressHandler:^(double progress, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
            if (progressHandler) {
                progressHandler(progress);
            }
        }];
         */
    }];
}

- (BOOL)writeOriginVideoToFile:(NSString *)filePath
{
    __block BOOL result = YES;
    NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
    [fileCoordinator coordinateWritingItemAtURL:[NSURL fileURLWithPath:filePath] options:NSFileCoordinatorWritingForReplacing error:nil byAccessor:^(NSURL * _Nonnull accessorUrl) {
        
        AVURLAsset *avURLAsset = (AVURLAsset *)[self originVideoAsset];

        /**
         NSData *data = [NSData dataWithContentsOfURL:avURLAsset.URL];
         [data writeToFile:accessorUrl.path atomically:YES];
         */

        AVAssetExportSession *session = [AVAssetExportSession exportSessionWithAsset:avURLAsset presetName:AVAssetExportPresetHighestQuality];
        session.outputFileType = AVFileTypeQuickTimeMovie;
        session.outputURL = [NSURL fileURLWithPath:accessorUrl.path];
        //session.shouldOptimizeForNetworkUse = YES;

        //  We synchronously have the asset
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

        [session exportAsynchronouslyWithCompletionHandler:^{
            switch (session.status) {

                case AVAssetExportSessionStatusUnknown:
                    NSLog(@"AVAssetExportSessionStatusUnknown");
                    break;

                case AVAssetExportSessionStatusWaiting:
                    NSLog(@"AVAssetExportSessionStatusWaiting");
                    break;

                case AVAssetExportSessionStatusExporting:
                    NSLog(@"AVAssetExportSessionStatusExporting");
                    break;

                case AVAssetExportSessionStatusCompleted:
                    NSLog(@"AVAssetExportSessionStatusCompleted");
                    break;

                case AVAssetExportSessionStatusFailed:
                    NSLog(@"AVAssetExportSessionStatusFailed");
                    result = NO;
                    break;

                case AVAssetExportSessionStatusCancelled:
                    NSLog(@"AVAssetExportSessionStatusCancelled");
                    result = NO;
                    break;
            }

            dispatch_semaphore_signal(semaphore);
        }];

        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    }];
    
    return result;
}

- (void)writeOriginVideoToFile:(NSString *)filePath completion:(void (^)(BOOL success, NSError *error))completion
{
    NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
    [fileCoordinator coordinateWritingItemAtURL:[NSURL fileURLWithPath:filePath] options:NSFileCoordinatorWritingForReplacing error:nil byAccessor:^(NSURL * _Nonnull accessorUrl) {
        
        AVURLAsset *avURLAsset = (AVURLAsset *)[self originVideoAsset];

        /**
         NSData *data = [NSData dataWithContentsOfURL:avURLAsset.URL];
         [data writeToFile:accessorUrl.path atomically:YES];
         */

        __block BOOL result = YES;

        AVAssetExportSession *session = [AVAssetExportSession exportSessionWithAsset:avURLAsset presetName:AVAssetExportPresetHighestQuality];
        session.outputFileType = AVFileTypeQuickTimeMovie;
        session.outputURL = [NSURL fileURLWithPath:accessorUrl.path];
        //session.shouldOptimizeForNetworkUse = YES;
        [session exportAsynchronouslyWithCompletionHandler:^{
            switch (session.status) {

                case AVAssetExportSessionStatusUnknown:
                    NSLog(@"AVAssetExportSessionStatusUnknown");
                    break;

                case AVAssetExportSessionStatusWaiting:
                    NSLog(@"AVAssetExportSessionStatusWaiting");
                    break;

                case AVAssetExportSessionStatusExporting:
                    NSLog(@"AVAssetExportSessionStatusExporting");
                    break;

                case AVAssetExportSessionStatusCompleted:
                    NSLog(@"AVAssetExportSessionStatusCompleted");
                    break;

                case AVAssetExportSessionStatusFailed:
                    NSLog(@"AVAssetExportSessionStatusFailed");
                    result = NO;
                    break;

                case AVAssetExportSessionStatusCancelled:
                    NSLog(@"AVAssetExportSessionStatusCancelled");
                    result = NO;
                    break;
            }

            if (completion) {
                completion(result,nil);
            }
        }];
    }];
}

- (void)writeOriginVideoToFile:(NSString *)filePath
               progressHandler:(void (^)(double progress))progressHandler
             completionHandler:(void (^)(BOOL success, NSError *error))completionHandler
{
    NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
    [fileCoordinator coordinateWritingItemAtURL:[NSURL fileURLWithPath:filePath] options:NSFileCoordinatorWritingForReplacing error:nil byAccessor:^(NSURL * _Nonnull accessorUrl) {
        
        [self requestOriginAVAssetWithCompletion:^(AVAsset *asset, AVAudioMix *audioMix, NSDictionary *info) {
            NSError *error = [info objectForKey:PHImageErrorKey];
            if (error){
                if (completionHandler) {
                    completionHandler(NO, error);
                }
            }else{
                AVURLAsset *avURLAsset = (AVURLAsset *)asset;
                
                /**
                 NSData *data = [NSData dataWithContentsOfURL:avURLAsset.URL];
                 [data writeToFile:accessorUrl.path atomically:YES];
                 */
                
                __block BOOL result = YES;
                
                AVAssetExportSession *session = [AVAssetExportSession exportSessionWithAsset:avURLAsset presetName:AVAssetExportPresetHighestQuality];
                session.outputFileType = AVFileTypeQuickTimeMovie;
                session.outputURL = [NSURL fileURLWithPath:accessorUrl.path];
                //session.shouldOptimizeForNetworkUse = YES;
                [session exportAsynchronouslyWithCompletionHandler:^{
                    switch (session.status) {
                            
                        case AVAssetExportSessionStatusUnknown:
                            NSLog(@"AVAssetExportSessionStatusUnknown");
                            break;
                            
                        case AVAssetExportSessionStatusWaiting:
                            NSLog(@"AVAssetExportSessionStatusWaiting");
                            break;
                            
                        case AVAssetExportSessionStatusExporting:
                            NSLog(@"AVAssetExportSessionStatusExporting");
                            break;
                            
                        case AVAssetExportSessionStatusCompleted:
                            NSLog(@"AVAssetExportSessionStatusCompleted");
                            break;
                            
                        case AVAssetExportSessionStatusFailed:
                            NSLog(@"AVAssetExportSessionStatusFailed");
                            result = NO;
                            break;
                            
                        case AVAssetExportSessionStatusCancelled:
                            NSLog(@"AVAssetExportSessionStatusCancelled");
                            result = NO;
                            break;
                    }
                    
                    if (progressHandler) {
                        progressHandler(1.0);
                    }
                    
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        if (completionHandler) {
                            completionHandler(result,nil);
                        }
                    });
                }];
            }
        } withProgressHandler:^(double progress, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
            if (progressHandler) {
                progressHandler(progress);
            }
        }];
    }];
}

- (BOOL)writeThumbnailImageToFile:(NSString *)filePath
{
    __block BOOL result = NO;
    NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
    [fileCoordinator coordinateWritingItemAtURL:[NSURL fileURLWithPath:filePath] options:NSFileCoordinatorWritingForReplacing error:nil byAccessor:^(NSURL * _Nonnull accessorUrl) {
        
        UIImage *image = [self thumbnailImage];
        if (image) {
            NSData *data = UIImagePNGRepresentation(image);
            if (data) {
                [data writeToFile:accessorUrl.path atomically:YES];
                result = YES;
            }
        }
    }];
    return result;
}

- (BOOL)writePreviewImageToFile:(NSString *)filePath
{
    __block BOOL result = NO;
    NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
    [fileCoordinator coordinateWritingItemAtURL:[NSURL fileURLWithPath:filePath] options:NSFileCoordinatorWritingForReplacing error:nil byAccessor:^(NSURL * _Nonnull accessorUrl) {
        
        UIImage *image = [self previewImage];
        if (image) {
            NSData *data = UIImagePNGRepresentation(image);
            if (data) {
                [data writeToFile:accessorUrl.path atomically:YES];
                result = YES;
            }
        }
    }];
    return result;
}

@end
