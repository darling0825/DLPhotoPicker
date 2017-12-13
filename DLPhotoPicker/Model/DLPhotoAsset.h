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
    DLPhotoMediaTypeUnknown         = 0,
    DLPhotoMediaTypeImage           = 1,
    DLPhotoMediaTypeVideo           = 2,
    DLPhotoMediaTypeLivePhoto       = 3,
};



@interface DLPhotoAsset : NSObject

@property (nonatomic, strong) PHAsset *phAsset;
@property (nonatomic, strong) AVAsset *avAsset;
@property (nonatomic, copy) NSString *albumName;


/**
 *  DLPhotoAsset Init
 *
 *  @param asset PHAsset or ALAsset
 *
 *  @return DLPhotoAsset
 */
- (id)initWithAsset:(id)asset;

- (DLPhotoMediaType)mediaType;

- (CGSize)assetdimensions;

- (long long)fileSize;

- (NSString *)fileName;

- (NSDate *)createDate;

- (NSURL *)url;

- (NSTimeInterval)duration;

- (UIImage *)badgeImage;

- (NSString *)accessibilityLabel;

- (BOOL)deletable;
- (BOOL)editable;

/**
 *  isHighFrameRateVideo,isTimelapseVideo,isVideo
 *
 *
 *  @return BOOL
 */
- (BOOL)isHighFrameRateVideo;
- (BOOL)isTimelapseVideo;
- (BOOL)isVideo;

/**
 *  Image Orientation
 *
 *  @return UIImageOrientation
 */
- (UIImageOrientation)imageOrientation;
/**
 *  Cancel Request
 */
- (void)cancelRequestAsset;
- (BOOL)cancelRequestImage;
- (BOOL)cancelRequestVideo;


/**
 *  Asset 的原图（包含系统相册“编辑”功能处理后的效果
 *
 *  @return Asset 的原图
 */
- (UIImage *)originImage;
- (NSData *)originImageData;
- (AVAsset *)originVideoAsset;


/**
 *  异步请求 Asset 的原图，包含了系统照片“编辑”功能处理后的效果（剪裁，旋转和滤镜等），可能会有网络请求
 *
 *  @param completion        完成请求后调用的 block，参数中包含了请求的原图以及图片信息，在 iOS 8.0 或以上版本中，
 *                           这个 block 会被多次调用，其中第一次调用获取到的尺寸很小的低清图，然后不断调用，直接获取到高清图，
 *                           获取到高清图后 QMUIAsset 会缓存起这张高清图，这时 block 中的第二个参数（图片信息）返回的为 nil。
 *  @param phProgressHandler 处理请求进度的 handler，不在主线程上执行，在 block 中修改 UI 时注意需要手工放到主线程处理。
 *
 *  @wraning iOS 8.0 以下中并没有异步请求预览图的接口，因此实际上为同步请求，这时 block 中的第二个参数（图片信息）返回的为 nil。
 *
 *  @return 返回请求图片的请求 id
 */

- (NSInteger)requestOriginImageWithCompletion:(void (^)(UIImage *image, NSDictionary *info))completion
                          withProgressHandler:(PHAssetImageProgressHandler)phProgressHandler;
- (NSInteger)requestOriginImageDataWithCompletion:(void (^)(NSData *, NSDictionary *))completion
                              withProgressHandler:(PHAssetImageProgressHandler)phProgressHandler NS_AVAILABLE_IOS(8.0);
/**
 *  异步请求 AVAsset
 *
 *  @param completion      completion block, is called on an arbitrary queue.
 *  @param progressHandler progress block, is called on an arbitrary queue.
 *
 *  @wraning The completion handler is called on an arbitrary queue.
 *  @return PHImageRequestID
 */
- (NSInteger)requestOriginAVAssetWithCompletion:(void (^)(AVAsset *asset, AVAudioMix *audioMix, NSDictionary *info))completion withProgressHandler:(PHAssetVideoProgressHandler)progressHandler;

/**
 *  Asset 的缩略图
 *
 *  @param size 指定返回的缩略图的大小，仅在 iOS 8.0 及以上的版本有效，其他版本则调用 ALAsset 的接口由系统返回一个合适当前平台的图片
 *
 *  @return Asset 的缩略图
 */
- (UIImage *)thumbnailWithSize:(CGSize)size;

/**
 *  异步请求 Asset 的缩略图，不会产生网络请求
 *
 *  @param size       指定返回的缩略图的大小，仅在 iOS 8.0 及以上的版本有效，其他版本则调用 ALAsset 的接口由系统返回一个合适当前平台的图片
 *  @param completion 完成请求后调用的 block，参数中包含了请求的缩略图以及图片信息，在 iOS 8.0 或以上版本中，这个 block 会被多次调用，
 *                    其中第一次调用获取到的尺寸很小的低清图，然后不断调用，直接获取到高清图，获取到高清图后会缓存起这张高清图，
 *                    这时 block 中的第二个参数（图片信息）返回的为 nil。
 *
 *  @return 返回请求图片的请求 id
 */
- (NSInteger)requestThumbnailImageWithSize:(CGSize)size completion:(void (^)(UIImage *image, NSDictionary *info))completion;


/**
 *  Asset 的预览图
 *
 *  @warning 仿照 ALAssetsLibrary 的做法输出与当前设备屏幕大小相同尺寸的图片，如果图片原图小于当前设备屏幕的尺寸，则只输出原图大小的图片
 *  @return Asset 的全屏图
 */
- (UIImage *)previewImage;

/**
 *  异步请求 Asset 的预览图，可能会有网络请求
 *
 *  @param completion        完成请求后调用的 block，参数中包含了请求的预览图以及图片信息，在 iOS 8.0 或以上版本中，
 *                           这个 block 会被多次调用，其中第一次调用获取到的尺寸很小的低清图，然后不断调用，直接获取到高清图，
 *                           获取到高清图后会缓存起这张高清图，这时 block 中的第二个参数（图片信息）返回的为 nil。
 *  @param phProgressHandler 处理请求进度的 handler，不在主线程上执行，在 block 中修改 UI 时注意需要手工放到主线程处理。
 *
 *  @wraning iOS 8.0 以下中并没有异步请求预览图的接口，因此实际上为同步请求，这时 block 中的第二个参数（图片信息）返回的为 nil。
 *
 *  @return 返回请求图片的请求 id
 */
- (NSInteger)requestPreviewImageWithCompletion:(void (^)(UIImage *image, NSDictionary *info))completion withProgressHandler:(PHAssetImageProgressHandler)phProgressHandler;

/**
 *  Save asset to a file
 *
 *  @return Success or not.
 */
- (BOOL)writeOriginImageToFile:(NSString *)filePath;
- (void)writeOriginImageToFile:(NSString *)filePath
               progressHandler:(void (^)(double progress))progressHandler
             completionHandler:(void (^)(BOOL success, NSError *error))completionHandler;

- (BOOL)writeOriginVideoToFile:(NSString *)filePath;
- (void)writeOriginVideoToFile:(NSString *)filePath completion:(void (^)(BOOL success, NSError *error))completion;
- (void)writeOriginVideoToFile:(NSString *)filePath
               progressHandler:(void (^)(double progress))progressHandler
             completionHandler:(void (^)(BOOL success, NSError *error))completionHandler;

- (BOOL)writeThumbnailImageToFile:(NSString *)filePath;
- (BOOL)writePreviewImageToFile:(NSString *)filePath;
@end
