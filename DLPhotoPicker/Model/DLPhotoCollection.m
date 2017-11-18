//
//  DLPhotoCollection.m
//  DLPhotoPicker
//
//  Created by 沧海无际 on 16/2/20.
//  Copyright © 2016年 darling0825. All rights reserved.
//

#import "DLPhotoCollection.h"
#import "DLPhotoManager.h"
#import "UIImage+DLPhotoPicker.h"
#import "DLPhotoPickerDefines.h"

@implementation DLPhotoCollection

- (id)initWithAssetCollection:(id)assetCollection
{
    self = [super init];
    if (self) {
        if ([assetCollection isKindOfClass:[PHAssetCollection class]]) {
            _assetCollection = assetCollection;
        }else if ([assetCollection isKindOfClass:[ALAssetsGroup class]]){
            _assetGroup = assetCollection;
        }else{
        }
    }
    return self;
}

//  override
- (BOOL)isEqual:(DLPhotoCollection *)object
{
    if (UsePhotoKit) {
        return [self.assetCollection.localIdentifier isEqual:object.assetCollection.localIdentifier];
    }else{
        return [self.url isEqual:object.url];
    }
}

- (NSString *)description
{
    if (UsePhotoKit) {
        return [NSString stringWithFormat:@"%@{%@}",self.title,self.assetCollection.localIdentifier];
    }else{
        return [NSString stringWithFormat:@"%@{%@}",self.title,self.url];
    }
}

#pragma mark - Accessers
- (NSString *)title
{
    if (UsePhotoKit) {
        return self.assetCollection.localizedTitle;
    }else{
        return [self.assetGroup valueForProperty:ALAssetsGroupPropertyName];
    }
}

- (NSURL *)url
{
    if (UsePhotoKit) {
        // no url
        return nil;
    }else{
        return [self.assetGroup valueForProperty:ALAssetsGroupPropertyURL];
    }
}

- (NSUInteger)count
{
    return [[DLPhotoManager sharedInstance] assetCountOfPhotoCollection:self];
}

- (NSUInteger)countOfAssetsWithVideoType
{
    if (UsePhotoKit) {
        return [self.fetchResult countOfAssetsWithMediaType:PHAssetMediaTypeVideo];
    }else{
        [self.assetGroup setAssetsFilter:[ALAssetsFilter allVideos]];
        return self.assetGroup.numberOfAssets;
    }
    return 0;
}

- (NSUInteger)countOfAssetsWithImageType
{
    if (UsePhotoKit) {
        return [self.fetchResult countOfAssetsWithMediaType:PHAssetMediaTypeImage];
    }else{
        [self.assetGroup setAssetsFilter:[ALAssetsFilter allPhotos]];
        return self.assetGroup.numberOfAssets;
    }
    return 0;
}

- (UIImage *)badgeImage
{
    NSString *imageName;
    
    if (UsePhotoKit) {
        switch (self.assetCollection.assetCollectionSubtype)
        {
            case PHAssetCollectionSubtypeSmartAlbumUserLibrary:
                imageName = @"BadgeAllPhotos";
                break;
                
            case PHAssetCollectionSubtypeSmartAlbumPanoramas:
                imageName = @"BadgePanorama";
                break;
                
            case PHAssetCollectionSubtypeSmartAlbumVideos:
                imageName = @"BadgeVideo";
                break;
                
            case PHAssetCollectionSubtypeSmartAlbumFavorites:
                imageName = @"BadgeFavorites";
                break;
                
            case PHAssetCollectionSubtypeSmartAlbumTimelapses:
                imageName = @"BadgeTimelapse";
                break;
                
            case PHAssetCollectionSubtypeSmartAlbumRecentlyAdded:
                imageName = @"BadgeLastImport";
                break;
                
            case PHAssetCollectionSubtypeSmartAlbumBursts:
                imageName = @"BadgeBurst";
                break;
                
            case PHAssetCollectionSubtypeSmartAlbumSlomoVideos:
                imageName = @"BadgeSlomo";
                break;

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_9_0
            case PHAssetCollectionSubtypeSmartAlbumScreenshots:
                imageName = @"BadgeScreenshots";
                break;
                
            case PHAssetCollectionSubtypeSmartAlbumSelfPortraits:
                imageName = @"BadgeSelfPortraits";
                break;
#endif
                
            default:
                imageName = nil;
                break;
        }
    }
    
    if (imageName){
        return [[UIImage assetImageNamed:imageName] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    else{
        return nil;
    }
}

- (BOOL)isSmartAlbum
{
    if (UsePhotoKit) {
        return self.assetCollection.assetCollectionType == PHAssetCollectionTypeSmartAlbum &&
        self.assetCollection.assetCollectionSubtype != PHAssetCollectionSubtypeSmartAlbumAllHidden;
    }
    return NO;
}

- (BOOL)deletable
{
    if (UsePhotoKit) {
        /**
        PHCollectionEditOperationDeleteContent    = 1, // Delete things it contains
        PHCollectionEditOperationRemoveContent    = 2, // Remove things it contains, they're not deleted from the library
        PHCollectionEditOperationAddContent       = 3, // Add image
        PHCollectionEditOperationCreateContent    = 4, // Create new things, or duplicate them from others in the same container
        PHCollectionEditOperationRearrangeContent = 5, // Change the order of things
        PHCollectionEditOperationDelete           = 6, // Deleting of the container, not the content
        PHCollectionEditOperationRename           = 7, // Renaming of the container, not the content
         */
        return [self.assetCollection canPerformEditOperation:PHCollectionEditOperationRemoveContent];
    }
    return NO;
}

@end
