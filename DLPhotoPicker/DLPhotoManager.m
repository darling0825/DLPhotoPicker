//
//  DLPhotoManager.m
//  DLPhotoPicker
//
//  Created by 沧海无际 on 16/2/20.
//  Copyright © 2016年 darling0825. All rights reserved.
//

#import "DLPhotoManager.h"
#import "DLPhotoPickerDefines.h"
#import "PHAssetCollection+DLPhotoPicker.h"
#import "DLPhotoAsset.h"
#import "DLPhotoCollection.h"

@interface DLPhotoManager()

@property (nonatomic, strong) PHCachingImageManager *imageManager;
@property (nonatomic, copy) NSArray *fetchResults;

@end

@implementation DLPhotoManager

+ (instancetype)sharedInstance
{
    static DLPhotoManager *photoManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        photoManager = [[[self class] alloc] init];
    });
    return photoManager;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setDefaults];
        [self initAssetCollectionSubtypes];
        [self initThumbnailRequestOptions];
    }
    
    return self;
}

- (void)setDefaults
{
    _imageManager = [PHCachingImageManager new];
    _showsEmptyAlbums = YES;
    _assetCollectionThumbnailSize = DLPhotoCollectionThumbnailSize;
}

#pragma mark - Init properties
- (void)initAssetCollectionSubtypes
{
    _assetCollectionSubtypes =
    @[[NSNumber numberWithInt:PHAssetCollectionSubtypeSmartAlbumUserLibrary],
      [NSNumber numberWithInt:PHAssetCollectionSubtypeAlbumMyPhotoStream],
      [NSNumber numberWithInt:PHAssetCollectionSubtypeSmartAlbumRecentlyAdded],
      [NSNumber numberWithInt:PHAssetCollectionSubtypeSmartAlbumFavorites],
      [NSNumber numberWithInt:PHAssetCollectionSubtypeSmartAlbumPanoramas],
      [NSNumber numberWithInt:PHAssetCollectionSubtypeSmartAlbumVideos],
      [NSNumber numberWithInt:PHAssetCollectionSubtypeSmartAlbumSlomoVideos],
      [NSNumber numberWithInt:PHAssetCollectionSubtypeSmartAlbumTimelapses],
      [NSNumber numberWithInt:PHAssetCollectionSubtypeSmartAlbumBursts],
      [NSNumber numberWithInt:PHAssetCollectionSubtypeSmartAlbumAllHidden],
      [NSNumber numberWithInt:PHAssetCollectionSubtypeSmartAlbumGeneric],
      [NSNumber numberWithInt:PHAssetCollectionSubtypeAlbumRegular],
      [NSNumber numberWithInt:PHAssetCollectionSubtypeAlbumSyncedAlbum],
      [NSNumber numberWithInt:PHAssetCollectionSubtypeAlbumSyncedEvent],
      [NSNumber numberWithInt:PHAssetCollectionSubtypeAlbumSyncedFaces],
      [NSNumber numberWithInt:PHAssetCollectionSubtypeAlbumImported],
      [NSNumber numberWithInt:PHAssetCollectionSubtypeAlbumCloudShared]];
    
    // Add iOS 9's new albums
    if ([[PHAsset new] respondsToSelector:@selector(sourceType)])
    {
        NSMutableArray *subtypes = [NSMutableArray arrayWithArray:self.assetCollectionSubtypes];
        [subtypes insertObject:[NSNumber numberWithInt:PHAssetCollectionSubtypeSmartAlbumSelfPortraits] atIndex:4];
        [subtypes insertObject:[NSNumber numberWithInt:PHAssetCollectionSubtypeSmartAlbumScreenshots] atIndex:10];
        
        self.assetCollectionSubtypes = [NSArray arrayWithArray:subtypes];
    }
}

- (void)initThumbnailRequestOptions
{
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    options.resizeMode = PHImageRequestOptionsResizeModeFast;
//    options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    
    _thumbnailRequestOptions = options;
}

#pragma mark - Authorization
- (void)checkAuthorizationStatus
{
    if (DLiOS_8_OR_LATER) {
        [self checkAuthorizationStatus_AfteriOS8];
    }else{
        [self checkAuthorizationStatus_BeforeiOS8];
    }
}

- (void)requestAuthorization
{
    if (DLiOS_8_OR_LATER) {
        [self requestAuthorizationStatus_AfteriOS8];
    }else{
        [self requestAuthorizationStatus_BeforeiOS8];
    }
}

- (void)checkAuthorizationStatus_AfteriOS8
{
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    
    switch (status)
    {
        case PHAuthorizationStatusNotDetermined:
            [self requestAuthorizationStatus_AfteriOS8];
            break;
        case PHAuthorizationStatusRestricted:
        case PHAuthorizationStatusDenied:
        {
            [self showAccessDenied];
            break;
        }
        case PHAuthorizationStatusAuthorized:
        default:
        {
            [self checkAssetsCount];
            break;
        }
    }
}

- (void)requestAuthorizationStatus_AfteriOS8
{
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status){
        switch (status) {
            case PHAuthorizationStatusAuthorized:
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self checkAssetsCount];
                });
                break;
            }
            default:
            {
                [self showAccessDenied];
                break;
            }
        }
    }];
}

- (void)checkAuthorizationStatus_BeforeiOS8
{
    
}

- (void)requestAuthorizationStatus_BeforeiOS8
{
    
}

#pragma mark - DLPhotoManagerDelegate
- (void)showAccessDenied
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(accessDenied)]) {
            [self.delegate accessDenied];
        }
    });
}

- (void)showNoAssets
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(haveNonePhotoCollection)]) {
            [self.delegate haveNonePhotoCollection];
        }
    });
}

- (void)getAlbumsSuccess
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(getAlbumsSuccess)]) {
            [self.delegate getAlbumsSuccess];
        }
    });
}

#pragma mark -
- (void)checkAssetsCount
{
    PHFetchResult *fetchResult = [PHAsset fetchAssetsWithOptions:self.assetsFetchOptions];
    
    if (fetchResult.count > 0) {
        [self getAlbumsFromDevice];
    } else {
        [self showNoAssets];
    }
}

- (void)getAlbumsFromDevice
{
    NSMutableArray *fetchResults = [NSMutableArray new];
    
    for (NSNumber *subtypeNumber in self.assetCollectionSubtypes)
    {
        PHAssetCollectionType type = [PHAssetCollection ctassetPickerAssetCollectionTypeOfSubtype:subtypeNumber.integerValue];
        PHAssetCollectionSubtype subtype = subtypeNumber.integerValue;
        
        PHFetchResult *fetchResult =
        [PHAssetCollection fetchAssetCollectionsWithType:type
                                                 subtype:subtype
                                                 options:self.assetCollectionFetchOptions];
        
        [fetchResults addObject:fetchResult];
    }
    
    self.fetchResults = [NSMutableArray arrayWithArray:fetchResults];
    
    [self updateAssetCollections];
    
    [self getAlbumsSuccess];
}

- (void)updateAssetCollections
{
    NSMutableArray *assetCollections = [NSMutableArray new];
    
    for (PHFetchResult *fetchResult in self.fetchResults)
    {
        for (PHAssetCollection *assetCollection in fetchResult)
        {
            BOOL showsAssetCollection = YES;
            
            if (!self.showsEmptyAlbums)
            {
                PHFetchOptions *options = [PHFetchOptions new];
                options.predicate = self.assetsFetchOptions.predicate;
                
                if ([options respondsToSelector:@selector(setFetchLimit:)])
                    options.fetchLimit = 1;
                
                NSInteger count = [assetCollection ctassetPikcerCountOfAssetsFetchedWithOptions:options];
                
                showsAssetCollection = (count > 0);
            }
            
            if (showsAssetCollection)
                [assetCollections addObject:[[DLPhotoCollection alloc] initWithAssetCollection:assetCollection]];
        }
    }
    
    self.assetCollections = [NSMutableArray arrayWithArray:assetCollections];
}

#pragma mark - Request Thumbnail
- (void)requestThumbnailsForPhotoAsset:(DLPhotoAsset *)photoAsset containerSize:(CGSize)containerSize completion:(void (^)(UIImage *thumbnail))completion
{
    if (DLiOS_8_OR_LATER) {
        CGSize targetSize = [self imageSizeForContainerSize:containerSize];
        [self.imageManager requestImageForAsset:photoAsset.asset
                                     targetSize:targetSize
                                    contentMode:PHImageContentModeAspectFill
                                        options:self.thumbnailRequestOptions
                                  resultHandler:^(UIImage *image, NSDictionary *info){
                                      completion(image);
                                  }];
    }else{
        
    }
}

#pragma mark -
- (NSArray *)assetsForPhotoCollection:(DLPhotoCollection *)photoCollection
{
    NSMutableArray *photoAssets = [NSMutableArray arrayWithCapacity:photoCollection.count];
    
    if (DLiOS_8_OR_LATER) {
        PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:photoCollection.assetCollection
                                                                   options:self.assetsFetchOptions];
        
        photoCollection.countOfAssetsWithVideoType = [fetchResult countOfAssetsWithMediaType:PHAssetMediaTypeVideo];
        photoCollection.countOfAssetsWithImageType = [fetchResult countOfAssetsWithMediaType:PHAssetMediaTypeImage];
        
        for (PHAsset *asset in fetchResult) {
            [photoAssets addObject:[[DLPhotoAsset alloc] initWithAsset:asset]];
        }
    }
    else{
        
    }
    
    return photoAssets;
}

- (NSUInteger)assetCountOfCollection:(DLPhotoCollection *)collection
{
    PHFetchResult *result = [PHAsset fetchAssetsInAssetCollection:collection.assetCollection options:self.assetsFetchOptions];
    return result.count;
}

#pragma mark - 
- (NSArray *)posterAssetsFromAssetCollection:(DLPhotoCollection *)collection count:(NSUInteger)count
{
    PHFetchOptions *options = [PHFetchOptions new];
    options.predicate       = self.assetsFetchOptions.predicate; // aligned specified predicate
    options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES]];
    
    PHFetchResult *result = [PHAsset fetchKeyAssetsInAssetCollection:collection.assetCollection options:options];
    
    NSUInteger location = 0;
    NSUInteger length   = (result.count < count) ? result.count : count;
    NSArray *assets     = [self itemsFromFetchResult:result range:NSMakeRange(location, length)];
    
    NSMutableArray *photoAssets = [NSMutableArray arrayWithCapacity:assets.count];
    for (PHAsset *asset in assets) {
        [photoAssets addObject:[[DLPhotoAsset alloc] initWithAsset:asset]];
    }
    
    return photoAssets;
}

- (NSArray *)itemsFromFetchResult:(PHFetchResult *)result range:(NSRange)range
{
    if (result.count == 0)
        return nil;
    
    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:range];
    NSArray *array = [result objectsAtIndexes:indexSet];
    
    return array;
}

#pragma mark - Image target size

- (CGSize)imageSizeForContainerSize:(CGSize)size
{
    CGFloat scale = UIScreen.mainScreen.scale;
    return CGSizeMake(size.width * scale, size.height * scale);
}

@end
