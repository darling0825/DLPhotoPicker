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
        }else if ([asset isKindOfClass:[ALAsset class]]){
            _alAsset = asset;
        }else{
        }
    }
    return self;
}

//  override
- (BOOL)isEqual:(DLPhotoAsset *)object
{
    if (UsePhotoKit) {
        return [self.phAsset.localIdentifier isEqual:object.phAsset.localIdentifier];
    }else{
        return [self.url isEqual:object.url];
    }
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@{%@}",self.fileName,self.url];
}

#pragma mark - Accessers
- (DLPhotoMediaType)mediaType
{
    if (UsePhotoKit) {
        if (_phAsset.mediaType == PHAssetMediaTypeImage) {
            return DLPhotoMediaTypeImage;
        }else if (_phAsset.mediaType == PHAssetMediaTypeVideo){
            return DLPhotoMediaTypeVideo;
        }else{
            return DLPhotoMediaTypeUnknown;
        }
    }else{
        NSString *type = [self.alAsset valueForProperty:ALAssetPropertyType];
        if ([type isEqualToString:ALAssetTypePhoto]) {
            return DLPhotoMediaTypeImage;
        }else if ([type isEqualToString:ALAssetTypeVideo]) {
            return DLPhotoMediaTypeVideo;
        }else{
            return DLPhotoMediaTypeUnknown;
        }
    }
    
    return DLPhotoMediaTypeUnknown;
}

- (CGSize)assetdimensions
{
    if (UsePhotoKit) {
        return CGSizeMake(self.phAsset.pixelWidth, self.phAsset.pixelHeight);
    }else{
        /**
         *  Fix Bug: [self.alAsset defaultRepresentation] == nil
         */
        CGSize dimensions;
        if ([self.alAsset defaultRepresentation]) {
            dimensions = [[self.alAsset defaultRepresentation] dimensions];
        }
        else{
            CGImageRef imageRef = self.alAsset.aspectRatioThumbnail;
            if (imageRef) {
                UIImage *image = [[UIImage alloc] initWithCGImage:imageRef];
                if (image) {
                    dimensions = [image size];
                }
            }
        }
        return dimensions;
    }
}

- (UIImageOrientation)imageOrientation
{
    __block UIImageOrientation orientation = 0;
    if (UsePhotoKit) {
        if (!_phAssetInfo) {
            // PHAsset 的 UIImageOrientation 需要调用过 requestImageDataForAsset 才能获取
            [self requestPHAssetInfo:^(NSDictionary *info) {
                _phAssetInfo = [NSDictionary dictionaryWithDictionary:info];
                orientation = (UIImageOrientation)[_phAssetInfo[@"PHImageFileOrientationKey"] integerValue];
            }];
        }
    } else {
        orientation = (UIImageOrientation)[[_alAsset valueForProperty:@"ALAssetPropertyOrientation"] integerValue];
    }
    return orientation;
}

- (long long)fileSize
{
    __block long long size = 0;
    if (UsePhotoKit) {
        if (!_phAssetInfo) {
            // PHAsset 的 assetSize 需要调用过 requestImageDataForAsset 才能获取
            [self requestPHAssetInfo:^(NSDictionary *info) {
                _phAssetInfo = [NSDictionary dictionaryWithDictionary:info];
                size = [(NSData *)_phAssetInfo[@"PHImageFileDataKey"] length];
            }];
        }else{
            size = [(NSData *)_phAssetInfo[@"PHImageFileDataKey"] length];
        }
    } else {
        size = [[[self alAsset] defaultRepresentation] size];
    }
    return size;
}

- (NSString *)fileName
{
    __block NSString *name = @"";
    if (UsePhotoKit) {
        if (!_phAssetInfo) {
            // PHAsset 的 assetSize 需要调用过 requestImageDataForAsset 才能获取
            [self requestPHAssetInfo:^(NSDictionary *info) {
                _phAssetInfo = [NSDictionary dictionaryWithDictionary:info];
                if ([_phAssetInfo objectForKey:@"PHImageFileURLKey"]) {
                    /* path looks like this -
                     * file:///var/mobile/Media/DCIM/###APPLE/IMG_####.JPG
                     */
                    name = [[_phAssetInfo objectForKey:@"PHImageFileURLKey"] lastPathComponent];
                }
            }];
        }else{
            name = [[_phAssetInfo objectForKey:@"PHImageFileURLKey"] lastPathComponent];
        }
    } else {
        name = [[[self alAsset] defaultRepresentation] filename];
    }
    
    return name;
}

- (NSDate *)createDate
{
    __block NSDate *createDate = nil;
    if (UsePhotoKit) {
        createDate = self.phAsset.creationDate;
    }else{
        createDate = [self.alAsset valueForProperty:ALAssetPropertyDate];
    }
    return createDate;
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
    if (UsePhotoKit) {
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
        }else{
            url = [_phAssetInfo objectForKey:@"PHImageFileURLKey"];
        }
    } else {
        url = [[[self alAsset] defaultRepresentation] url];
    }
    
    return url;
}

- (NSTimeInterval)duration
{
    if (self.mediaType == DLPhotoMediaTypeVideo) {
        if (UsePhotoKit) {
            return self.phAsset.duration;
        }else{
            //NSURL *assetURL = [self.alAsset valueForProperty:ALAssetPropertyAssetURL];
            return [[self.alAsset valueForProperty:ALAssetPropertyDuration] doubleValue];
        }
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
    if (UsePhotoKit) {
        return self.phAsset.accessibilityLabel;
    }else{
        return self.alAsset.accessibilityLabel;
    }
}

- (BOOL)isHighFrameRateVideo
{
    if (UsePhotoKit) {
        return (self.phAsset.mediaType == PHAssetMediaTypeVideo &&
                (self.phAsset.mediaSubtypes & PHAssetMediaSubtypeVideoHighFrameRate));
    }
    return NO;
}

- (BOOL)isTimelapseVideo
{
    if (UsePhotoKit) {
        return (self.phAsset.mediaType == PHAssetMediaTypeVideo &&
                (self.phAsset.mediaSubtypes & PHAssetMediaSubtypeVideoTimelapse));
    }
    return NO;
}

- (BOOL)isVideo
{
    return [self mediaType] == DLPhotoMediaTypeVideo;
}

- (BOOL)deletable
{
    if (UsePhotoKit) {
        return [self.phAsset canPerformEditOperation:PHCollectionEditOperationDeleteContent];
    }
    return NO;
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
    if (_originImage) {
        return _originImage;
    }
    __block UIImage *resultImage;
    if (UsePhotoKit) {
        PHImageRequestOptions *originRequestOptions = [[PHImageRequestOptions alloc] init];
        originRequestOptions.synchronous = YES;
        
        /**
        [[[DLPhotoManager sharedInstance] phCachingImageManager]
         requestImageForAsset:self.phAsset
         targetSize:PHImageManagerMaximumSize
         contentMode:PHImageContentModeDefault
         options:originRequestOptions
         resultHandler:^(UIImage *result, NSDictionary *info) {
             resultImage = result;
         }];
        */
        PHContentEditingInputRequestOptions *options = [[PHContentEditingInputRequestOptions alloc] init];
        options.networkAccessAllowed = YES;
        options.canHandleAdjustmentData = ^ BOOL (PHAdjustmentData *adjustmentData) { return YES; };
        [self.phAsset requestContentEditingInputWithOptions:options
                                          completionHandler:^(PHContentEditingInput * _Nullable contentEditingInput, NSDictionary * _Nonnull info) {
                                              resultImage = [UIImage imageWithContentsOfFile:contentEditingInput.fullSizeImageURL.path];
            
        }];
    } else {
        CGImageRef fullResolutionImageRef = [[self.alAsset defaultRepresentation] fullResolutionImage];
        /*
         *通过 fullResolutionImage 获取到的的高清图实际上并不带上在照片应用中使用“编辑”处理的效果，
         *需要额外在 AlAssetRepresentation 中获取这些信息
         */
        NSString *adjustment = [[[self.alAsset defaultRepresentation] metadata] objectForKey:@"AdjustmentXMP"];
        if (adjustment) {
            // 如果有在照片应用中使用“编辑”效果，则需要获取这些编辑后的滤镜，手工叠加到原图中
            NSData *xmpData = [adjustment dataUsingEncoding:NSUTF8StringEncoding];
            CIImage *tempImage = [CIImage imageWithCGImage:fullResolutionImageRef];
            
            NSError *error;
            NSArray *filterArray = [CIFilter filterArrayFromSerializedXMP:xmpData
                                                         inputImageExtent:tempImage.extent
                                                                    error:&error];
            CIContext *context = [CIContext contextWithOptions:nil];
            if (filterArray && !error) {
                for (CIFilter *filter in filterArray) {
                    [filter setValue:tempImage forKey:kCIInputImageKey];
                    tempImage = [filter outputImage];
                }
                fullResolutionImageRef = [context createCGImage:tempImage fromRect:[tempImage extent]];
            }
        }
        // 生成最终返回的 UIImage，同时把图片的 orientation 也补充上去
        resultImage = [UIImage imageWithCGImage:fullResolutionImageRef scale:[[self.alAsset defaultRepresentation] scale] orientation:(UIImageOrientation)[[self.alAsset defaultRepresentation] orientation]];
    }
    _originImage = resultImage;
    return resultImage;
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
    if (UsePhotoKit) {
        if (_originImage) {
            // 如果已经有缓存的图片则直接拿缓存的图片
            if (completion) {
                completion(_originImage, nil);
            }
            return 0;
        } else {
            PHImageRequestOptions *originRequestOptions = [[PHImageRequestOptions alloc] init];
            // 允许访问网络
            originRequestOptions.networkAccessAllowed = YES;
            originRequestOptions.progressHandler = phProgressHandler;
            self.imageRequestID = [[[DLPhotoManager sharedInstance] phCachingImageManager]
                                   requestImageForAsset:self.phAsset
                                   targetSize:PHImageManagerMaximumSize
                                   contentMode:PHImageContentModeDefault
                                   options:originRequestOptions
                                   resultHandler:^(UIImage *result, NSDictionary *info) {
                                       // 排除取消，错误，低清图三种情况，即已经获取到了高清图时，把这张高清图缓存到 _originImage 中
                                       BOOL downloadFinined = ![[info objectForKey:PHImageCancelledKey] boolValue] &&
                                       ![info objectForKey:PHImageErrorKey] &&
                                       ![[info objectForKey:PHImageResultIsDegradedKey] boolValue];
                                       if (downloadFinined) {
                                           _originImage = result;
                                       }
                                       if (completion) {
                                           completion(result, info);
                                       }
                                   }];
            /** And to get fullsize image url:
            PHContentEditingInputRequestOptions *options = [[PHContentEditingInputRequestOptions alloc] init];
            options.canHandleAdjustmentData = ^BOOL(PHAdjustmentData *adjustmentData) {
                return YES;
            };
            
            [self.phAsset requestContentEditingInputWithOptions:options
                                              completionHandler:^(PHContentEditingInput *contentEditingInput, NSDictionary *info) {
                                                  // use contentEditingInput.fullSizeImageURL
                                              }];
             */
            
            return self.imageRequestID;
        }
    } else {
        if (completion) {
            completion([self originImage], nil);
        }
        return 0;
    }
}

- (AVAsset *)originVideoAsset
{
    if (_avAsset) {
        return _avAsset;
    }
    __block AVAsset *resultAsset;
    if (UsePhotoKit) {
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

    } else {
        /**
         *   url: assets-library://asset/asset.MOV?id=4663818B-F56A-414A-88C6-C46B33EB23B3&ext=MOV
         */
        NSURL *url = [[self.alAsset defaultRepresentation] url];
        resultAsset = [AVAsset assetWithURL:url];
    }
    _avAsset = resultAsset;
    return resultAsset;
}

- (NSInteger)requestOriginAVAssetWithCompletion:(void (^)(AVAsset *asset, AVAudioMix *audioMix, NSDictionary *info))completion
                            withProgressHandler:(PHAssetVideoProgressHandler)progressHandler
{
    if (UsePhotoKit) {
        if (_avAsset) {
            // 如果已经有缓存的图片则直接拿缓存的图片
            if (completion) {
                completion(_avAsset, nil, nil);
            }
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
                                         if (completion) {
                                             completion(asset, audioMix, info);
                                         }
                                     }];
            return self.avAssetRequestID;
        }
    } else {
        if (completion) {
            completion([self originVideoAsset], nil, nil);
        }
        return 0;
    }
}

- (UIImage *)thumbnailWithSize:(CGSize)size
{
    if (_thumbnailImage) {
        return _thumbnailImage;
    }
    __block UIImage *resultImage;
    if (UsePhotoKit) {
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
    } else {
        CGImageRef thumbnailImageRef = [self.alAsset thumbnail];
        if (thumbnailImageRef) {
            resultImage = [UIImage imageWithCGImage:thumbnailImageRef];
        }
    }
    _thumbnailImage = resultImage;
    return resultImage;
}

- (NSInteger)requestThumbnailImageWithSize:(CGSize)size completion:(void (^)(UIImage *, NSDictionary *))completion
{
    if (UsePhotoKit) {
        if (_thumbnailImage) {
            if (completion) {
                completion(_thumbnailImage, nil);
            }
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
    } else {
        if (completion) {
            completion([self thumbnailWithSize:size], nil);
        }
        return 0;
    }
}

- (UIImage *)previewImage
{
    if (_previewImage) {
        return _previewImage;
    }
    __block UIImage *resultImage;
    if (UsePhotoKit) {
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
    } else {
        CGImageRef fullScreenImageRef = [[self.alAsset defaultRepresentation] fullScreenImage];
        if (fullScreenImageRef == nil) {
            fullScreenImageRef = [self.alAsset aspectRatioThumbnail];
        }
        if (fullScreenImageRef == nil) {
            fullScreenImageRef = [[self.alAsset defaultRepresentation] fullResolutionImage];
        }
        if (fullScreenImageRef == nil) {
            fullScreenImageRef = [self.alAsset thumbnail];
        }
            
        resultImage = [UIImage imageWithCGImage:fullScreenImageRef];
    }
    _previewImage = resultImage;
    return resultImage;
}

- (NSInteger)requestPreviewImageWithCompletion:(void (^)(UIImage *, NSDictionary *))completion
                           withProgressHandler:(PHAssetImageProgressHandler)progressHandler
{
    if (UsePhotoKit) {
        if (_previewImage) {
            // 如果已经有缓存的图片则直接拿缓存的图片
            if (completion) {
                completion(_previewImage, nil);
            }
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
    } else {
        if (completion) {
            completion([self previewImage], nil);
        }
        return 0;
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
    UIImage *image = [self originImage];
    if (image) {
        NSData *data = UIImagePNGRepresentation(image);
        if (data) {
            [data writeToFile:filePath atomically:YES];
            return YES;
        }
    }
    
    return NO;
}

- (BOOL)writeOriginVideoToFile:(NSString *)filePath error: (NSError **) error
{
    if (UsePhotoKit) {
#warning 需要分段写入
        AVURLAsset *avURLAsset = (AVURLAsset *)[self originVideoAsset];
        NSData *data = [NSData dataWithContentsOfURL:avURLAsset.URL];
        [data writeToFile:filePath atomically:YES];
    }else{
        [[NSFileManager defaultManager] createFileAtPath:filePath contents:nil attributes:nil];
        NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:filePath];
        if (filePath) {
            NSUInteger bufferSize  = 1024;
            long long  offset  = 0;
            NSUInteger bytesRead   = 0;
            uint8_t *buffer = calloc(bufferSize, sizeof(*buffer));
            
            do {
                @try {
                    bytesRead = [self.alAsset.defaultRepresentation getBytes:buffer fromOffset:offset length:bufferSize error:error];
                    [fileHandle writeData:[NSData dataWithBytesNoCopy:buffer length:bytesRead freeWhenDone:NO]];
                    offset += bytesRead;
                } @catch (NSException *exception) {
                    free(buffer);
                    return NO;
                }
                
            } while (bytesRead > 0);
            
            free(buffer);
        }
    }
    
    return NO;
}

- (BOOL)writeThumbnailImageToFile:(NSString *)filePath
{
    UIImage *image = [self thumbnailImage];
    if (image) {
        NSData *data = UIImagePNGRepresentation(image);
        if (data) {
            [data writeToFile:filePath atomically:YES];
            return YES;
        }
    }
    
    return NO;
}

- (BOOL)writePreviewImageToFile:(NSString *)filePath
{
    UIImage *image = [self previewImage];
    if (image) {
        NSData *data = UIImagePNGRepresentation(image);
        if (data) {
            [data writeToFile:filePath atomically:YES];
            return YES;
        }
    }
    
    return NO;
}

@end
