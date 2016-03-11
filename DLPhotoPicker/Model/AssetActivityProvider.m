//
//  AssetActivityProvider.m
//  AssetActivityProvider
//
//  Created by 沧海无际 on 16/3/8.
//  Copyright © 2016年 darling0825. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "AssetActivityProvider.h"
#import "DLPhotoManager.h"

NSString * const WhatsappActivityType   = @"net.whatsapp.WhatsApp.ShareExtension";
NSString * const WeixinActivityType     = @"com.tencent.xin.sharetimeline";
NSString * const QQActivityType         = @"com.tencent.mqq.ShareExtension";
NSString * const AppleNotesActivityType = @"com.apple.mobilenotes.SharingExtension";
NSString * const AppleStreamShareActivityType = @"com.apple.mobileslideshow.StreamShareService";

@interface AssetActivityProvider()
@property (nonatomic, strong) DLPhotoAsset *asset;
@property (nonatomic, strong) NSString *filePath;
@end

@implementation AssetActivityProvider
- (id)initWithAsset:(DLPhotoAsset *)asset
{
    self = [super init];
    if (self) {
        _asset = asset;
    }
    
    return self;
}

//- (id)item
//{
//    if (self.asset.mediaType == DLPhotoMediaTypeImage) {
//        return [[DLPhotoManager sharedInstance] originImage:self.asset];
//    }
//    else if (self.asset.mediaType == DLPhotoMediaTypeVideo) {
//        
//        if ([self.activityType isEqualToString:WhatsappActivityType] ||
//            [self.activityType isEqualToString:WeixinActivityType] ||
//            [self.activityType isEqualToString:QQActivityType]
//            ||[self.activityType isEqualToString:AppleNotesActivityType]
//            ||[self.activityType isEqualToString:AppleStreamShareActivityType]) {
//            
//            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory,NSUserDomainMask,YES);
//            NSString *cachesDirectory = [paths objectAtIndex:0];
//            NSFileManager *manager = [NSFileManager defaultManager];
//            
//            self.filePath = [cachesDirectory stringByAppendingPathComponent:self.asset.fileName];
//            NSError *error;
//            if ([manager fileExistsAtPath:self.filePath]) {
//                BOOL success = [manager removeItemAtPath:self.filePath error:&error];
//                if (success) {
//                    NSLog(@">>> %@ is removed.",self.filePath);
//                }
//            }
//            
//            if ([self.asset writeOriginVideoToFile:self.filePath]) {
//                return [NSURL fileURLWithPath:self.filePath];
//            }
//        }else{
//            AVURLAsset *urlAsset = (AVURLAsset *)[self.asset originVideoAsset];
//            return urlAsset.URL;
//        }
//    }
//    
//    return nil;
//}

- (void)cleanup
{
    NSFileManager *manager = [NSFileManager defaultManager];
    NSError *error;
    if ([manager fileExistsAtPath:self.filePath]) {
        BOOL success = [manager removeItemAtPath:self.filePath error:&error];
        if (success) {
            NSLog(@">>> %@ cleaned.",self.filePath);
        }else{
            NSLog(@">>> %@",error);
        }
    }
}

#pragma mark - UIActivityItemSource
- (id)activityViewControllerPlaceholderItem:(UIActivityViewController *)activityViewController
{
    return [[UIImage alloc] init];
}

- (nullable id)activityViewController:(UIActivityViewController *)activityViewController itemForActivityType:(NSString *)activityType
{
    if (self.asset.mediaType == DLPhotoMediaTypeImage) {
        //return [[DLPhotoManager sharedInstance] originImage:self.asset];
        return [self.asset originImage];
    }
    else if (self.asset.mediaType == DLPhotoMediaTypeVideo) {
        
        if ([activityType isEqualToString:WhatsappActivityType] ||
            [activityType isEqualToString:WeixinActivityType] ||
            [activityType isEqualToString:QQActivityType]
            ||[activityType isEqualToString:AppleNotesActivityType]
            ||[activityType isEqualToString:AppleStreamShareActivityType]) {
            
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory,NSUserDomainMask,YES);
            NSString *cachesDirectory = [paths objectAtIndex:0];
            NSFileManager *manager = [NSFileManager defaultManager];
            
            self.filePath = [cachesDirectory stringByAppendingPathComponent:self.asset.fileName];
            NSError *error;
            if ([manager fileExistsAtPath:self.filePath]) {
                BOOL success = [manager removeItemAtPath:self.filePath error:&error];
                if (success) {
                    NSLog(@">>> %@ is removed.",self.filePath);
                }
            }
            
            if ([self.asset writeOriginVideoToFile:self.filePath]) {
                return [NSURL fileURLWithPath:self.filePath];
            }
        }else{
            AVURLAsset *urlAsset = (AVURLAsset *)[self.asset originVideoAsset];
            return urlAsset.URL;
        }
    }
    
    return nil;
}

//- (NSString *)activityViewController:(UIActivityViewController *)activityViewController subjectForActivityType:(nullable NSString *)activityType
//{
//    
//}

//- (NSString *)activityViewController:(UIActivityViewController *)activityViewController dataTypeIdentifierForActivityType:(nullable NSString *)activityType
//{
//    
//}

- (nullable UIImage *)activityViewController:(UIActivityViewController *)activityViewController thumbnailImageForActivityType:(nullable NSString *)activityType suggestedSize:(CGSize)size
{
    return [self.asset thumbnailWithSize:size];
}

@end
