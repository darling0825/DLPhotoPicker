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
        }
    }
    return self;
}

//  override
- (BOOL)isEqual:(DLPhotoCollection *)object
{
    return [self.assetCollection.localIdentifier isEqual:object.assetCollection.localIdentifier];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@{%@}",self.title,self.assetCollection.localIdentifier];
}

#pragma mark - Accessers
- (NSString *)title
{
    return self.assetCollection.localizedTitle;
}

- (NSUInteger)count
{
    return [[DLPhotoManager sharedInstance] assetCountOfPhotoCollection:self];
}

- (NSUInteger)countOfAssetsWithVideoType
{
    return [self.fetchResult countOfAssetsWithMediaType:PHAssetMediaTypeVideo];
}

- (NSUInteger)countOfAssetsWithImageType
{
    return [self.fetchResult countOfAssetsWithMediaType:PHAssetMediaTypeImage];
}

- (UIImage *)badgeImage
{
    NSString *imageName;
    PHAssetCollectionSubtype type = self.assetCollection.assetCollectionSubtype;
        switch (type) {
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

        default:
            imageName = nil;
            break;
    }

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_9_0
    if (@available(iOS 9.0, *)) {
        if (type == PHAssetCollectionSubtypeSmartAlbumScreenshots) {
            imageName = @"BadgeScreenshots";
        }else if (type == PHAssetCollectionSubtypeSmartAlbumSelfPortraits) {
            imageName = @"BadgeSelfPortraits";
        }
    }
#endif
    
    if (imageName){
        return [[UIImage assetImageNamed:imageName] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    else{
        return nil;
    }
}

- (BOOL)isSmartAlbum
{
    return self.assetCollection.assetCollectionType == PHAssetCollectionTypeSmartAlbum &&
    self.assetCollection.assetCollectionSubtype != PHAssetCollectionSubtypeSmartAlbumAllHidden;
}

- (BOOL)deletable
{
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

@end
