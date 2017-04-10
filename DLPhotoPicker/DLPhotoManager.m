//
//  DLPhotoManager.m
//  DLPhotoPicker
//
//  Created by 沧海无际 on 16/2/20.
//  Copyright © 2016年 darling0825. All rights reserved.
//

#import "DLPhotoManager.h"
#import "DLPhotoPickerDefines.h"

static NSString * const AdjustmentFormatIdentifier = @"com.darlingcoder.DLPhotoPicker";
static NSString * const AdjustmentFormatVersion = @"1.0";

typedef void (^AddImageToCollectionBlock)(UIImage *, PHAssetCollection *);
typedef void (^AddImageDataToCollectionBlock)(NSData *, PHAssetCollection *);
typedef void (^AddVideoToCollectionBlock)(NSURL *, PHAssetCollection *);

@interface DLPhotoManager()

@property (nonatomic, strong) PHCachingImageManager *phCachingImageManager;
@property (nonatomic, strong) ALAssetsLibrary *assetsLibrary;

@property (nonatomic, strong) dispatch_semaphore_t semaphore;

@property (nonatomic, copy) void(^fetchCollectionCompletion)(BOOL success);
@property (nonatomic, copy) void(^checkAuthorizationCompletion)(DLAuthorizationStatus status);

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
    }
    
    return self;
}

- (void)setDefaults
{
    _phCachingImageManager          = [PHCachingImageManager new];
    _assetsLibrary                  = [ALAssetsLibrary new];
    _showsEmptyAlbums               = YES;
    
    _semaphore = dispatch_semaphore_create(1);
    
    /**
     *  开启 Photo Stream 容易导致 exception
     */
    //[ALAssetsLibrary disableSharedPhotoStreamsSupport];
}

#pragma mark - setter
-(void)setFetchResults:(NSArray *)fetchResults
{
    _fetchResults = [NSArray arrayWithArray:fetchResults];
    [self __updateAssetCollections];
}

#pragma mark - Init properties
- (NSArray *)assetCollectionSubtypes
{
    if (!_assetCollectionSubtypes) {
        /**
         // PHAssetCollectionTypeAlbum regular subtypes
         PHAssetCollectionSubtypeAlbumRegular         = 2,
         PHAssetCollectionSubtypeAlbumSyncedEvent     = 3,
         PHAssetCollectionSubtypeAlbumSyncedFaces     = 4,
         PHAssetCollectionSubtypeAlbumSyncedAlbum     = 5,
         PHAssetCollectionSubtypeAlbumImported        = 6,
         
         // PHAssetCollectionTypeAlbum shared subtypes
         PHAssetCollectionSubtypeAlbumMyPhotoStream   = 100,
         PHAssetCollectionSubtypeAlbumCloudShared     = 101,
         
         // PHAssetCollectionTypeSmartAlbum subtypes
         PHAssetCollectionSubtypeSmartAlbumGeneric    = 200,
         PHAssetCollectionSubtypeSmartAlbumPanoramas  = 201,
         PHAssetCollectionSubtypeSmartAlbumVideos     = 202,
         PHAssetCollectionSubtypeSmartAlbumFavorites  = 203,
         PHAssetCollectionSubtypeSmartAlbumTimelapses = 204,
         PHAssetCollectionSubtypeSmartAlbumAllHidden  = 205,
         PHAssetCollectionSubtypeSmartAlbumRecentlyAdded = 206,
         PHAssetCollectionSubtypeSmartAlbumBursts     = 207,
         PHAssetCollectionSubtypeSmartAlbumSlomoVideos = 208,
         PHAssetCollectionSubtypeSmartAlbumUserLibrary = 209,
         PHAssetCollectionSubtypeSmartAlbumSelfPortraits NS_AVAILABLE_IOS(9_0) = 210,
         PHAssetCollectionSubtypeSmartAlbumScreenshots NS_AVAILABLE_IOS(9_0) = 211,
         */
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
            NSMutableArray *subtypes = [NSMutableArray arrayWithArray:_assetCollectionSubtypes];
            [subtypes insertObject:[NSNumber numberWithInt:PHAssetCollectionSubtypeSmartAlbumSelfPortraits] atIndex:4];
            [subtypes insertObject:[NSNumber numberWithInt:PHAssetCollectionSubtypeSmartAlbumScreenshots] atIndex:10];
            
            _assetCollectionSubtypes = [NSArray arrayWithArray:subtypes];
        }
    }
    return _assetCollectionSubtypes;
}

- (PHImageRequestOptions *)thumbnailRequestOptions
{
    if (!_thumbnailRequestOptions) {
        PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
        options.resizeMode = PHImageRequestOptionsResizeModeFast;
        //options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
        _thumbnailRequestOptions = options;
    }
    return _thumbnailRequestOptions;
}

#pragma mark - Authorization
- (void)checkAuthorizationStatus:(void(^)(DLAuthorizationStatus status))completion
{
    self.checkAuthorizationCompletion = completion;
    if (UsePhotoKit) {
        [self checkAuthorizationStatus_AfteriOS8];
    }else{
        [self checkAuthorizationStatus_BeforeiOS8];
    }
}

- (void)requestAuthorization
{
    if (UsePhotoKit) {
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
            [self checkAuthorizationSuccess];
            break;
        }
    }
}

- (void)requestAuthorizationStatus_AfteriOS8
{
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status){
        dispatch_async(dispatch_get_main_queue(), ^{
            switch (status) {
                case PHAuthorizationStatusAuthorized:
                {
                    [self checkAuthorizationSuccess];
                    break;
                }
                default:
                {
                    [self showAccessDenied];
                    break;
                }
            }
        });
    }];
}

- (void)checkAuthorizationStatus_BeforeiOS8
{
    ALAuthorizationStatus status = [ALAssetsLibrary authorizationStatus];
    switch (status)
    {
        case ALAuthorizationStatusNotDetermined:
            [self requestAuthorizationStatus_AfteriOS8];
            break;
        case ALAuthorizationStatusRestricted:
        case ALAuthorizationStatusDenied:
        {
            [self showAccessDenied];
            break;
        }
        case ALAuthorizationStatusAuthorized:
        default:
        {
            [self checkAuthorizationSuccess];
            break;
        }
    }
}

- (void)requestAuthorizationStatus_BeforeiOS8
{
    //do nothing
}

#pragma mark - DLPhotoManagerDelegate
- (void)checkAuthorizationSuccess
{
    if (self.checkAuthorizationCompletion) {
        self.checkAuthorizationCompletion(DLAuthorizationStatusSuccess);
    }
}

- (void)showAccessDenied
{
    if (self.checkAuthorizationCompletion) {
        self.checkAuthorizationCompletion(DLAuthorizationStatusAccessDenied);
    }
}

- (void)showNoAssets
{
    if (self.checkAuthorizationCompletion) {
        self.checkAuthorizationCompletion(DLAuthorizationStatusNoAssets);
    }
}

- (void)getAlbumsCompletion:(BOOL)success
{
    if (self.fetchCollectionCompletion) {
        self.fetchCollectionCompletion(success);
    }
}

#pragma mark - default album
- (NSString *)defaultAlbum
{
    return self.defaultCollection.title;
}

- (DLPhotoCollection *)defaultCollection
{
    if (self.photoCollections.count > 0) {
        return self.photoCollections[0];
    }
    return nil;
}

#pragma mark - favorite
- (void)favoriteAsset:(DLPhotoAsset *)photoAsset
           completion:(void(^)(BOOL success, NSError *error))completion
{
    if (UsePhotoKit) {
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            PHAssetChangeRequest *request = [PHAssetChangeRequest changeRequestForAsset:photoAsset.phAsset];
            [request setFavorite:!photoAsset.phAsset.favorite];
            
        } completionHandler:^(BOOL success, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) {
                    completion(success, error);
                }
            });
        }];
    }else{
        //  do nothimg
    }
}

#pragma mark - create album
- (void)createAlbumWithName:(NSString *)albumName
                resultBlock:(void(^)(DLPhotoCollection *collection))completion
               failureBlock:(void(^)(NSError *error))failure
{
    if (UsePhotoKit) {
        __block NSString *localIdentifier = nil;
        
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            PHAssetCollectionChangeRequest *assetCollectionChangeRequest = [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:albumName];
            localIdentifier = assetCollectionChangeRequest.placeholderForCreatedAssetCollection.localIdentifier;
            
        } completionHandler:^(BOOL success, NSError *error){
            dispatch_async(dispatch_get_main_queue(), ^{
                if (success) {
                    PHAssetCollection *assetCollection = [[PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[localIdentifier] options:nil] firstObject];
                    DLPhotoCollection *collection = [[DLPhotoCollection alloc] initWithAssetCollection:assetCollection];
                    completion(collection);
                }else{
                    completion(nil);
                }
                
                if (error && failure) {
                    failure(error);
                }
            });
        }];
        
    }else{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        [self.assetsLibrary addAssetsGroupAlbumWithName:albumName resultBlock:^(ALAssetsGroup *group) {
            if (completion) {
                if (group) {
                    DLPhotoCollection *collection = [[DLPhotoCollection alloc] initWithAssetCollection:group];
                    completion(collection);
                }else{
                    completion(nil);
                }
            }
        } failureBlock:^(NSError *error) {
            if (error && failure) {
                failure(error);
            }
        }];
    }
#pragma clang diagnostic pop
}

- (void)removeAlbum:(DLPhotoCollection *)photoCollection
        resultBlock:(void(^)(BOOL success))completion
       failureBlock:(void(^)(NSError *error))failure
{
    if (UsePhotoKit) {
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            [PHAssetCollectionChangeRequest deleteAssetCollections:@[photoCollection.assetCollection]];
        } completionHandler:^(BOOL success, NSError *error){
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) {
                    if (success) {
                        completion(YES);
                    }else{
                        completion(NO);
                    }
                }
                
                if (error && failure) {
                    failure(error);
                }
            });
        }];
    }else{
        /**
         *  http://stackoverflow.com/questions/11054860/alassetslibrary-delete-alassetsgroup-alasset/11058934#11058934
         *  This is not possible using any documented API. Only the photos app can delete Albums.
         */
    }
}

#pragma mark - save/remove image

/**
 *  -writeImageToSavedPhotosAlbum: orientation: completionBlock:
 *  -writeImageToSavedPhotosAlbum: metadata: completionBlock:
 *  -writeImageDataToSavedPhotosAlbum: metadata: completionBlock:
 *
 *  第一个使用了我们传进去的方向，
 *  第二个可以通过传入image的metadata保留image的metadata，前两个都是把图片转成 CGImageRef 再保存，
 *  第三个是传入NSData所以可以完整保留image的信息，同时也有metadata传进去，如果image自带的信息与metadata冲突那metadata会覆盖图片本身所带的metadata。
 */

- (void)saveImage:(UIImage *)image
          toAlbum:(NSString *)albumName
       completion:(void(^)(BOOL success))completion
          failure:(void(^)(NSError *error))failure
{
    if (UsePhotoKit) {
        //  find album
        BOOL albumWasFound = NO;
        PHAssetCollection *savedAssetCollection = nil;
        for (PHFetchResult *fetchResult in self.fetchResults){
            if (albumWasFound) {
                break;
            }
            
            for (PHAssetCollection *assetCollection in fetchResult){
                // Compare the names of the albums
                if ([albumName isEqualToString:assetCollection.localizedTitle]) {
                    
                    // Target album is found
                    albumWasFound = YES;
                    savedAssetCollection = assetCollection;
                    break;
                }
            }
        }
        
        //  a block to add assets to a album
        AddImageToCollectionBlock addAssetsBlock = [self _addImageBlockWithCompletion:completion failure:failure];
        
        if (!albumName.length) {
            //  add asset to default collection
            addAssetsBlock(image, nil);
        }else if (albumWasFound) {
            //  add asset
            addAssetsBlock(image, savedAssetCollection);
        }else{
            //  create a new album
            [self createAlbumWithName:albumName resultBlock:^(DLPhotoCollection *collection) {
                if (collection) {
                    //  add asset to new collection
                    addAssetsBlock(image, collection.assetCollection);
                }else{
                    //  add asset to default collection
                    addAssetsBlock(image, nil);
                }
            } failureBlock:failure];
        }
        
    }else{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        [self.assetsLibrary writeImageToSavedPhotosAlbum:image.CGImage
                                             orientation:(ALAssetOrientation)image.imageOrientation
                                         completionBlock:[self _resultBlockOfAddingToAlbum:albumName
                                                                                completion:completion
                                                                                   failure:failure]];
#pragma clang diagnostic pop
    }
}

- (void)saveImageData:(NSData *)data
              toAlbum:(NSString *)albumName
           completion:(void(^)(BOOL success))completion
              failure:(void(^)(NSError *error))failure
{
    //  find album
    BOOL albumWasFound = NO;
    PHAssetCollection *savedAssetCollection = nil;
    for (PHFetchResult *fetchResult in self.fetchResults){
        if (albumWasFound) {
            break;
        }
        
        for (PHAssetCollection *assetCollection in fetchResult){
            // Compare the names of the albums
            if ([albumName isEqualToString:assetCollection.localizedTitle]) {
                
                // Target album is found
                albumWasFound = YES;
                savedAssetCollection = assetCollection;
                break;
            }
        }
    }
    
    //  a block to add assets to a album
    AddImageDataToCollectionBlock addAssetsBlock = [self _addImageDataBlockWithCompletion:completion failure:failure];
    
    if (!albumName.length) {
        //  add asset to default collection
        addAssetsBlock(data, nil);
    }else if (albumWasFound) {
        //  add asset
        addAssetsBlock(data, savedAssetCollection);
    }else{
        //  create a new album
        [self createAlbumWithName:albumName resultBlock:^(DLPhotoCollection *collection) {
            if (collection) {
                //  add asset to new collection
                addAssetsBlock(data, collection.assetCollection);
            }else{
                //  add asset to default collection
                addAssetsBlock(data, nil);
            }
        } failureBlock:failure];
    }
}

- (void)saveVideo:(NSURL *)videoUrl
          toAlbum:(NSString *)albumName
       completion:(void(^)(BOOL success))completion
          failure:(void(^)(NSError *error))failure
{
    if (UsePhotoKit) {
        //  find album
        PHAssetCollection *savedAssetCollection = nil;
        for (PHFetchResult *fetchResult in self.fetchResults){
            if (savedAssetCollection) {
                break;
            }
            
            for (PHAssetCollection *assetCollection in fetchResult){
                // Compare the names of the albums
                if ([albumName compare:assetCollection.localizedTitle] == NSOrderedSame) {
                    
                    // Target album is found
                    savedAssetCollection = assetCollection;
                    break;
                }
            }
        }
        
        //  a block to add assets to a album
        AddVideoToCollectionBlock addVideoBlock = [self _addVideoBlockWithCompletion:completion failure:failure];
        
        if (savedAssetCollection) {
            //  add asset
            addVideoBlock(videoUrl, savedAssetCollection);
        }else{
            //  create a new album
            [self createAlbumWithName:albumName resultBlock:^(DLPhotoCollection *collection) {
                if (collection) {
                    //  add asset
                    addVideoBlock(videoUrl, collection.assetCollection);
                }
            } failureBlock:failure];
        }
    }else{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        [self.assetsLibrary writeVideoAtPathToSavedPhotosAlbum:videoUrl
                                               completionBlock:[self _resultBlockOfAddingToAlbum:albumName
                                                                                      completion:completion
                                                                                         failure:failure]];
#pragma clang diagnostic pop
    }
}

- (void)removeAsset:(NSArray<DLPhotoAsset *> *)photoAssets
         completion:(void(^)(BOOL success))completion
            failure:(void(^)(NSError *error))failure
{
    if (UsePhotoKit) {
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            NSMutableArray *deleteAssets = [NSMutableArray arrayWithCapacity:photoAssets.count];
            for (DLPhotoAsset *asset in photoAssets) {
                [deleteAssets addObject:asset.phAsset];
            }
            [PHAssetChangeRequest deleteAssets:deleteAssets];
        } completionHandler:^(BOOL success, NSError *error){
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) {
                    if (success) {
                        completion(YES);
                    }else{
                        completion(NO);
                    }
                }
                
                if (error && failure) {
                    failure(error);
                }
            });
        }];
    }else{
        /**
         *  can not work
         */

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        [self removeAssetURL:photoAssets resultBlock:completion failureBlock:failure];
#pragma clang diagnostic pop
    }
}

- (void)saveImageData:(NSData *)imageData
              toAlbum:(NSString *)albumName
             metadata:(NSDictionary *)metadata
           completion:(void(^)(BOOL success))completion
              failure:(void(^)(NSError *error))failure
{
    if (UsePhotoKit) {
        //  find album
        BOOL albumWasFound = NO;
        PHAssetCollection *savedAssetCollection = nil;
        for (PHFetchResult *fetchResult in self.fetchResults){
            if (albumWasFound) {
                break;
            }
            
            for (PHAssetCollection *assetCollection in fetchResult){
                // Compare the names of the albums
                if ([albumName compare:assetCollection.localizedTitle] == NSOrderedSame) {
                    
                    // Target album is found
                    albumWasFound = YES;
                    savedAssetCollection = assetCollection;
                    break;
                }
            }
        }
        
        //  a block to add assets to a album
        AddImageToCollectionBlock addAssetsBlock = [self _addImageBlockWithCompletion:completion failure:failure];
        
        UIImage *image = [UIImage imageWithData:imageData];
        if (albumWasFound) {
            //  add asset
            addAssetsBlock(image, savedAssetCollection);
        }else{
            //  create a new album
            [self createAlbumWithName:albumName resultBlock:^(DLPhotoCollection *collection) {
                if (collection) {
                    //  add asset
                    addAssetsBlock(image, collection.assetCollection);
                }
            } failureBlock:failure];
        }
    }else{
        [self.assetsLibrary writeImageDataToSavedPhotosAlbum:imageData
                                                    metadata:metadata
                                             completionBlock:[self _resultBlockOfAddingToAlbum:albumName
                                                                                    completion:completion
                                                                                       failure:failure]];
    }
}

- (void)addAssetURL:(NSURL *)assetUrl
            toAlbum:(NSString *)albumName
        resultBlock:(void(^)(BOOL success))completion
       failureBlock:(void(^)(NSError *error))failure
{
    if (UsePhotoKit) {
        //  do nothing
    }else{
        
        typeof(self) __weak weakSelf = self;
        __block BOOL albumWasFound = NO;
        
        //search all photo albums in the library
        [self.assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupAlbum usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
            // Compare the names of the albums
            if ([albumName compare: [group valueForProperty:ALAssetsGroupPropertyName]] == NSOrderedSame) {
                
                // Target album is found
                albumWasFound = YES;
                
                ALAssetsLibraryAssetForURLResultBlock assetForURLResultBlock =
                [weakSelf _addAssetUrlBlockWithGroup:group
                                            assetURL:assetUrl
                                          completion:completion
                                             failure:failure];
                
                //get a hold of the photo's asset instance
                [self.assetsLibrary assetForURL:assetUrl
                                    resultBlock:assetForURLResultBlock
                                   failureBlock:failure];
                
                
                // Album was found, bail out of the method
                *stop = YES;
            }
            
            //如果不存在该相册创建
            if (group == nil && albumWasFound == NO){
                typeof(self) __strong strongSelf = weakSelf;
                
                // code that always creates an album on iOS 7.x.x but fails
                // in certain situations such as if album has been deleted
                // previously on iOS 8.x.
                [strongSelf.assetsLibrary addAssetsGroupAlbumWithName:albumName resultBlock:^(ALAssetsGroup *group){
                     
                    ALAssetsLibraryAssetForURLResultBlock assetForURLResultBlock =
                    [weakSelf _addAssetUrlBlockWithGroup:group assetURL:assetUrl completion:completion failure:failure];
                    
                    //get a hold of the photo's asset instance
                    [self.assetsLibrary assetForURL:assetUrl
                                        resultBlock:assetForURLResultBlock
                                       failureBlock:failure];
                     
                 } failureBlock:failure];
            }
        } failureBlock:failure];
    }
}

//  can not work
- (void)removeAssetURL:(NSArray<DLPhotoAsset *> *)photoAssets
        resultBlock:(void(^)(BOOL success))completion
       failureBlock:(void(^)(NSError *error))failure
{
    if (UsePhotoKit) {
        //  do nothing
    }else{
        for (DLPhotoAsset *asset in photoAssets) {
            ALAssetsLibraryAssetForURLResultBlock assetForURLResultBlock =
            [self _removeAssetUrlBlockWithAssetURL:asset.url completion:completion failure:failure];
            [self.assetsLibrary assetForURL:asset.url
                                resultBlock:assetForURLResultBlock
                               failureBlock:failure];
        }
    }
}

#pragma mark - Block

- (AddImageToCollectionBlock)_addImageBlockWithCompletion:(void(^)(BOOL))completion
                                                  failure:(void(^)(NSError *))failure
{
    return ^(UIImage *image, PHAssetCollection *assetCollection){
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            if (assetCollection) {
                // saved to assetCollection and CameraRoll
                PHAssetChangeRequest *assetChangeRequest = [PHAssetChangeRequest creationRequestForAssetFromImage:image];
                PHAssetCollectionChangeRequest *assetCollectionChangeRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:assetCollection];
                [assetCollectionChangeRequest addAssets:@[assetChangeRequest.placeholderForCreatedAsset]];
            }else{
                // only saved to CameraRoll
                [PHAssetChangeRequest creationRequestForAssetFromImage:image];
            }
            
        } completionHandler:^(BOOL success, NSError * _Nullable error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) {
                    if (success) {
                        completion(YES);
                    }else{
                        completion(NO);
                    }
                }
                
                if (error && failure) {
                    failure(error);
                }
            });
        }];
    };
}

- (AddImageDataToCollectionBlock)_addImageDataBlockWithCompletion:(void(^)(BOOL))completion
                                                          failure:(void(^)(NSError *))failure
{
    return ^(NSData *data, PHAssetCollection *assetCollection){
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            if (assetCollection) {
                // saved to assetCollection and CameraRoll
                //PHAssetChangeRequest *assetChangeRequest = [PHAssetChangeRequest creationRequestForAssetFromImage:image];
                
                PHAssetResourceRequestOptions *options = [PHAssetResourceRequestOptions new];
                PHAssetCreationRequest *request = [PHAssetCreationRequest creationRequestForAsset];
                [request addResourceWithType:PHAssetResourceTypePhoto data:data options:options];
                
                PHAssetCollectionChangeRequest *assetCollectionChangeRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:assetCollection];
                [assetCollectionChangeRequest addAssets:@[request.placeholderForCreatedAsset]];
                
            }else{
                // only saved to CameraRoll
//                [PHAssetChangeRequest creationRequestForAssetFromImage:image];
                PHAssetResourceCreationOptions *options = [PHAssetResourceCreationOptions new];
                [[PHAssetCreationRequest creationRequestForAsset] addResourceWithType:PHAssetResourceTypePhoto data:data options:options];
            }
            
        } completionHandler:^(BOOL success, NSError * _Nullable error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) {
                    if (success) {
                        completion(YES);
                    }else{
                        completion(NO);
                    }
                }
                
                if (error && failure) {
                    failure(error);
                }
            });
        }];
    };
}

- (AddVideoToCollectionBlock)_addVideoBlockWithCompletion:(void(^)(BOOL))completion
                                                  failure:(void(^)(NSError *))failure
{
    return ^(NSURL *videoUrl, PHAssetCollection *assetCollection){
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            
            PHAssetChangeRequest *assetChangeRequest = [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:videoUrl];
            PHAssetCollectionChangeRequest *assetCollectionChangeRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:assetCollection];
            [assetCollectionChangeRequest addAssets:@[assetChangeRequest.placeholderForCreatedAsset]];
            
        } completionHandler:^(BOOL success, NSError * _Nullable error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) {
                    if (success) {
                        completion(YES);
                    }else{
                        completion(NO);
                    }
                }
                
                if (error && failure) {
                    failure(error);
                }
            });
        }];
    };
}

- (ALAssetsLibraryAssetForURLResultBlock)_addAssetUrlBlockWithGroup:(ALAssetsGroup *)group
                                                           assetURL:(NSURL *)assetUrl
                                                         completion:(void(^)(BOOL success))completion
                                                            failure:(void(^)(NSError *error))failure
{
    return ^(ALAsset *asset) {
        // Add photo to the target album
        if ([group addAsset:asset]) {
            // Run the completion block if the asset was added successfully
            if (completion) {
                completion(YES);
            }
        }
        
        // |-addAsset:| may fail (return NO) if the group is not editable,
        //   or if the asset could not be added to the group.
        else {
            NSString *message = [NSString stringWithFormat:@"ALAssetsGroup failed to add asset: %@.", asset];
            if (failure) {
                failure([NSError errorWithDomain:@"ALAssetsLibrary"
                                            code:0
                                        userInfo:@{NSLocalizedDescriptionKey : message}]);
            }
        }
    };
}

- (ALAssetsLibraryAssetForURLResultBlock)_removeAssetUrlBlockWithAssetURL:(NSURL *)assetUrl
                                                               completion:(void(^)(BOOL success))completion
                                                                  failure:(void(^)(NSError *error))failure
{
    return ^(ALAsset *asset) {
        if(asset.isEditable) {
            [asset setImageData:nil metadata:nil completionBlock:^(NSURL *assetUrl, NSError *error) {
                if (assetUrl && completion) {
                    completion(YES);
                }
                if (error && failure) {
                    failure(error);
                }
            }];
        }else{
            NSString *message = [NSString stringWithFormat:@"ALAssetsGroup failed to remove asset: %@.", asset];
            if (failure) {
                failure([NSError errorWithDomain:@"ALAsset"
                                            code:0
                                        userInfo:@{NSLocalizedDescriptionKey : message}]);
            }
        }
    };
}

- (ALAssetsLibraryWriteImageCompletionBlock)_resultBlockOfAddingToAlbum:(NSString *)albumName
                                                             completion:(void(^)(BOOL success))completion
                                                                failure:(void(^)(NSError *error))failure
{
    return ^(NSURL *assetURL, NSError *error) {
        // Run the completion block for writing image to saved
        //   photos album
        //if (completion) completion(assetURL, error);
        
        // If an error occured, do not try to add the asset to
        //   the custom photo album
        if (error != nil) {
            if (failure) failure(error);
            return;
        }
        
        if (albumName == nil) {
            if (completion) completion(YES);
            return;
        }
        
        // Add the asset to the custom photo album
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        [self addAssetURL:assetURL toAlbum:albumName resultBlock:completion failureBlock:failure];
#pragma clang diagnostic pop
    };
}

#pragma mark - Photo Edit
- (void)requestContentEditing:(DLPhotoAsset *)asset
                   completion:(void (^)(UIImage *image, PHContentEditingInput *contentEditingInput, NSDictionary *info))completion
{
    if ([asset.phAsset canPerformEditOperation:PHAssetEditOperationContent] &&
        !(asset.phAsset.mediaSubtypes & PHAssetMediaSubtypePhotoLive))
    {
        PHContentEditingInputRequestOptions *options = [[PHContentEditingInputRequestOptions alloc] init];
        [options setNetworkAccessAllowed:YES];
        [options setCanHandleAdjustmentData:^BOOL(PHAdjustmentData *adjustmentData) {
            //  origin image
            return [adjustmentData.formatIdentifier isEqualToString:AdjustmentFormatIdentifier] && [adjustmentData.formatVersion isEqualToString:AdjustmentFormatVersion];
        }];
        
        [asset.phAsset requestContentEditingInputWithOptions:options completionHandler:^(PHContentEditingInput *contentEditingInput, NSDictionary *info) {
            
            //CIImage *fullImage = [CIImage imageWithContentsOfURL:contentEditingInput.fullSizeImageURL];
            //NSLog(@"%@", fullImage.properties.description);
            
            NSURL *url = [contentEditingInput fullSizeImageURL];
            UIImage *image = [[UIImage alloc] initWithContentsOfFile:url.path];
            //UIImage *image = contentEditingInput.displaySizeImage;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) {
                    completion(image, contentEditingInput, info);
                }
            });
        }];
    }
}

- (void)saveContentEditing:(DLPhotoAsset *)asset
                     image:(UIImage *)image
       contentEditingInput:(PHContentEditingInput *)contentEditingInput
     adjustmentDescription:(NSData *)adjustmentDescription
{
    /*
     *  Edit the origin image
     */
    PHAdjustmentData *adjustmentData =
    [[PHAdjustmentData alloc] initWithFormatIdentifier:AdjustmentFormatIdentifier formatVersion:AdjustmentFormatVersion data:adjustmentDescription];
    
    // Create a PHContentEditingOutput object and write a JPEG representation of the edited object to the renderedContentURL.
    PHContentEditingOutput *contentEditingOutput = [[PHContentEditingOutput alloc] initWithContentEditingInput:contentEditingInput];
    
    //NSData *imageData = UIImagePNGRepresentation(image);//not work
    NSData *imageData = UIImageJPEGRepresentation(image, 1.0f);
    [imageData writeToURL:[contentEditingOutput renderedContentURL] atomically:YES];
    [contentEditingOutput setAdjustmentData:adjustmentData];
    
    // Ask the shared PHPhotoLinrary to perform the changes.
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        PHAssetChangeRequest *request = [PHAssetChangeRequest changeRequestForAsset:asset.phAsset];
        request.contentEditingOutput = contentEditingOutput;
    } completionHandler:^(BOOL success, NSError *error) {
        if (!success) {
            NSLog(@">>> PHContentEditingInputRequest Error: %@", error);
        }else{
            /*
             *  use method -photoLibraryDidChange: instead
             */
            //[[self itemViewController] assetDidChanded:self.asset];
        }
    }];
}

#pragma mark - fetch album
- (void)fetchPhotoCollection:(void(^)(BOOL success))completion
{
    self.fetchCollectionCompletion = completion;
    if (UsePhotoKit) {
        [self getAlbumsFromDevice];
    }
    else{
        [self getAlbumsFromDevice_BeforeiOS8];
    }
}

- (void)getAlbumsFromDevice
{
    PHFetchResult *fetchResult = [PHAsset fetchAssetsWithOptions:self.assetsFetchOptions];
    if (fetchResult.count <= 0) {
        [self showNoAssets];
        return;
    }
    
    NSMutableArray *fetchResults = [NSMutableArray new];
    
    for (NSNumber *subtypeNumber in self.assetCollectionSubtypes)
    {
        PHAssetCollectionSubtype subtype = subtypeNumber.integerValue;
        PHAssetCollectionType type = [self __assetCollectionTypeOfSubtype:subtype];
        
        PHFetchResult *fetchResult =
        [PHAssetCollection fetchAssetCollectionsWithType:type
                                                 subtype:subtype
                                                 options:self.assetCollectionFetchOptions];
        
        [fetchResults addObject:fetchResult];
    }
    
    self.fetchResults = fetchResults;
    
    if (fetchResults.count > 0) {
        [self getAlbumsCompletion:YES];
    }else{
        [self getAlbumsCompletion:NO];
    }
}

- (void)getAlbumsFromDevice_BeforeiOS8
{
    NSMutableArray *albumsArray = [[NSMutableArray alloc] init];
    __weak typeof(self) weakSelf = self;
    [_assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (group) {
            /**
             *  allPhotos: Get all photos assets in the assets group.
             *  allVideos: Get all video assets in the assets group.
             *  allAssets: Get all assets in the group.
             */
            [group setAssetsFilter:[ALAssetsFilter allAssets]];
            
            if (!strongSelf.showsEmptyAlbums && group.numberOfAssets <= 0) {
                ;
            }else{
                DLPhotoCollection *collection = [[DLPhotoCollection alloc] initWithAssetCollection:group];
                NSInteger groupType = [[group valueForProperty:ALAssetsGroupPropertyType] integerValue];
                if(groupType == ALAssetsGroupSavedPhotos){
                    [albumsArray insertObject:collection atIndex:0];
                }
                else{
                    [albumsArray addObject:collection];
                }
            }
            
        } else {
            if ([albumsArray count] > 0) {
                strongSelf.photoCollections = [NSMutableArray arrayWithArray:albumsArray];
                // 把所有的相册储存完毕，可以展示相册列表
                [strongSelf getAlbumsCompletion:YES];
            } else {
                // 没有任何有资源的相册，输出提示
                [strongSelf showNoAssets];
            }
        }
    } failureBlock:^(NSError *error) {
        NSLog(@">>>Asset group not found!\n");
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf getAlbumsCompletion:NO];
    }];
}

#pragma mark - fetch asset
- (NSArray *)assetsForPhotoCollection:(DLPhotoCollection *)photoCollection
{
    NSMutableArray *photoAssets = [[NSMutableArray alloc] initWithCapacity:photoCollection.count];
    
    if (UsePhotoKit) {
        PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:photoCollection.assetCollection
                                                                   options:self.assetsFetchOptions];
        
        for (PHAsset *asset in fetchResult) {
            DLPhotoAsset *phAsset = [[DLPhotoAsset alloc] initWithAsset:asset];
            [photoAssets addObject:phAsset];
        }
        
        photoCollection.fetchResult = fetchResult;
    }
    else{
        /*
         __block NSUInteger photoCount = 0;
         __block NSUInteger videoCount = 0;
         */
        
        ALAssetsGroup *assetGroup = photoCollection.assetGroup;
        if (assetGroup) {
            [assetGroup enumerateAssetsWithOptions:NSEnumerationConcurrent usingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
                if (result) {
                    /*
                     NSString *type = [result valueForProperty:ALAssetPropertyType];
                     if ([type isEqualToString:ALAssetTypePhoto]){
                     photoCount++;
                     }else if ([type isEqualToString:ALAssetTypeVideo] ){
                     videoCount++;
                     }
                     */
                    DLPhotoAsset *asset = [[DLPhotoAsset alloc] initWithAsset:result];
                    // Add @synchronized to fix a crash bug
                    @synchronized(photoAssets) {
                        [photoAssets addObject:asset];
                    }
                } else {
                    // finished
                    
                    [photoAssets sortUsingComparator:^NSComparisonResult(DLPhotoAsset *obj1, DLPhotoAsset *obj2) {
                        return [obj1.createDate compare:obj2.createDate];
                    }];
                }
            }];
        }
    }
    return photoAssets;
}

- (NSUInteger)assetCountOfPhotoCollection:(DLPhotoCollection *)photoCollection
{
    if (UsePhotoKit) {
        return [[PHAsset fetchAssetsInAssetCollection:photoCollection.assetCollection options:self.assetsFetchOptions] count];
    }else{
        [photoCollection.assetGroup setAssetsFilter:[ALAssetsFilter allAssets]];
        return photoCollection.assetGroup.numberOfAssets;
    }
}

#pragma mark - poster images
- (NSArray *)posterImagesForPhotoCollection:(DLPhotoCollection *)photoCollection
                              thumbnailSize:(CGSize)thumbnailSize
                                      count:(NSUInteger)count
{
    if (UsePhotoKit) {
        PHFetchOptions *options = [PHFetchOptions new];
        options.predicate       = self.assetsFetchOptions.predicate; // aligned specified predicate
        options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES]];
        
        PHFetchResult *result   = [PHAsset fetchKeyAssetsInAssetCollection:photoCollection.assetCollection options:options];
        
        NSUInteger location     = 0;
        NSUInteger length       = (result.count < count) ? result.count : count;
        NSArray *assets         = [self __itemsFromFetchResult:result range:NSMakeRange(location, length)];
        
        NSMutableArray *images  = [NSMutableArray arrayWithCapacity:length];
        
        for (PHAsset *asset in assets) {
            DLPhotoAsset *photoAsset = [[DLPhotoAsset alloc] initWithAsset:asset];
            [photoAsset requestThumbnailImageWithSize:thumbnailSize completion:^(UIImage *image, NSDictionary *info) {
                if (image) {
                    [images addObject:image];
                }
            }];
        }
        return images;
    }
    else{
        NSMutableArray *images = [NSMutableArray array];
        CGImageRef cgPosterImage = photoCollection.assetGroup.posterImage;
        if (cgPosterImage) {
            UIImage *posterImage = [[UIImage alloc] initWithCGImage:cgPosterImage];
            
            if (posterImage) {
                [images addObject:posterImage];
            }
        }
        return images;
    }
    
    return nil;
}

- (NSArray *)posterAssetsForPhotoCollection:(DLPhotoCollection *)photoCollection count:(NSUInteger)count
{
    if (UsePhotoKit) {
        PHFetchOptions *options = [PHFetchOptions new];
        options.predicate       = self.assetsFetchOptions.predicate; // aligned specified predicate
        options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES]];
        
        PHFetchResult *result   = [PHAsset fetchKeyAssetsInAssetCollection:photoCollection.assetCollection options:options];
        
        NSUInteger location     = 0;
        NSUInteger length       = (result.count < count) ? result.count : count;
        NSArray *assets         = [self __itemsFromFetchResult:result range:NSMakeRange(location, length)];
        
        NSMutableArray *photoAssets = [NSMutableArray arrayWithCapacity:length];
        for (PHAsset *asset in assets) {
            DLPhotoAsset *phAsset = [[DLPhotoAsset alloc] initWithAsset:asset];
            [photoAssets addObject:phAsset];
        }
        
        return photoAssets;
    }
    else{
        __block NSUInteger length = (photoCollection.count < count) ? photoCollection.count : count;
        NSMutableArray *photoAssets = [NSMutableArray arrayWithCapacity:length];
        [photoCollection.assetGroup enumerateAssetsWithOptions:NSEnumerationReverse
                                                    usingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
                                                        if (result) {
                                                            length--;
                                                            DLPhotoAsset *asset = [[DLPhotoAsset alloc] initWithAsset:result];
                                                            [photoAssets addObject:asset];
                                                        }
                                                        
                                                        if (length == 0) {
                                                            *stop = YES;
                                                        }
                                                    }];
        return photoAssets;
    }
    
    return nil;
}

#pragma mark - register change observer
- (void)registerChangeObserver:(id<PHPhotoLibraryChangeObserver,ALAssetsLibraryChangeObserver>)observer
{
    if (UsePhotoKit) {
        [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:observer];
    }else{
        [[NSNotificationCenter defaultCenter] addObserver:observer
                                                 selector:@selector(assetsLibraryChanged:)
                                                     name:ALAssetsLibraryChangedNotification
                                                   object:nil];
    }
}

- (void)unregisterChangeObserver:(id<PHPhotoLibraryChangeObserver,ALAssetsLibraryChangeObserver>)observer
{
    if (UsePhotoKit) {
        [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:observer];
    }else{
        [[NSNotificationCenter defaultCenter] removeObserver:observer name:ALAssetsLibraryChangedNotification object:nil];
    }
}


#pragma mark - caching images (iOS 8 or later)
- (void)startCachingImagesForAssets:(DLPhotoAsset *)asset targetSize:(CGSize)targetSize
{
    if (UsePhotoKit) {
        [self.phCachingImageManager startCachingImagesForAssets:@[asset.phAsset]
                                                     targetSize:targetSize
                                                    contentMode:PHImageContentModeAspectFill
                                                        options:self.thumbnailRequestOptions];
    }else{
        
    }
}

- (void)stopCachingImagesForAssets:(DLPhotoAsset *)asset targetSize:(CGSize)targetSize
{
    if (UsePhotoKit) {
        [self.phCachingImageManager stopCachingImagesForAssets:@[asset.phAsset]
                                                    targetSize:targetSize
                                                   contentMode:PHImageContentModeAspectFill
                                                       options:self.thumbnailRequestOptions];
    }else{
        
    }
}

- (void)stopCachingImagesForAllAssets
{
    if (UsePhotoKit) {
        [self.phCachingImageManager stopCachingImagesForAllAssets];
    }else{
        
    }
}

#pragma mark - Private Method
- (void)__updateAssetCollections
{
    NSMutableArray *assetCollections = [NSMutableArray new];
    
    for (PHFetchResult *fetchResult in self.fetchResults)
    {
        for (PHAssetCollection *assetCollection in fetchResult)
        {
            BOOL showsAssetCollection = YES;
            
            if (!self.showsEmptyAlbums){
                PHFetchOptions *options = [PHFetchOptions new];
                options.predicate = self.assetsFetchOptions.predicate;
                
                if ([options respondsToSelector:@selector(setFetchLimit:)]){
                    options.fetchLimit = 1;
                }
                
                NSInteger count = [self __countOfAssetsForCollection:assetCollection FetchedWithOptions:options];
                
                showsAssetCollection = (count > 0);
            }
            
            if (showsAssetCollection){
                DLPhotoCollection *photoCollection = [[DLPhotoCollection alloc] initWithAssetCollection:assetCollection];
                photoCollection.fetchResult = fetchResult;
                [assetCollections addObject:photoCollection];
            }
        }
    }
    
    self.photoCollections = [NSMutableArray arrayWithArray:assetCollections];
}

- (NSArray *)__itemsFromFetchResult:(PHFetchResult *)result range:(NSRange)range
{
    if (result.count == 0)
        return nil;
    
    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:range];
    NSArray *array = [result objectsAtIndexes:indexSet];
    
    return array;
}

- (PHAssetCollectionType)__assetCollectionTypeOfSubtype:(PHAssetCollectionSubtype)subtype
{
    return (subtype >= PHAssetCollectionSubtypeSmartAlbumGeneric) ? PHAssetCollectionTypeSmartAlbum : PHAssetCollectionTypeAlbum;
}

- (NSUInteger)__countOfAssetsForCollection:(PHAssetCollection *)phAssetCollection FetchedWithOptions:(PHFetchOptions *)fetchOptions
{
    PHFetchResult *result = [PHAsset fetchAssetsInAssetCollection:phAssetCollection options:fetchOptions];
    return result.count;
}

- (UIImage *)originImage:(DLPhotoAsset *)photoAsset
{
    @autoreleasepool {
        __block UIImage *resultImage;
        
        if (UsePhotoKit) {
            
            @autoreleasepool {
                
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
                
                [[[DLPhotoManager sharedInstance] phCachingImageManager] requestImageForAsset:photoAsset.phAsset
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
            }
            
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
            
        } else {
            
            CGImageRef fullResolutionImageRef = [[photoAsset.alAsset defaultRepresentation] fullResolutionImage];
            /*
             *通过 fullResolutionImage 获取到的的高清图实际上并不带上在照片应用中使用“编辑”处理的效果，
             *需要额外在 AlAssetRepresentation 中获取这些信息
             */
            NSString *adjustment = [[[photoAsset.alAsset defaultRepresentation] metadata] objectForKey:@"AdjustmentXMP"];
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
            resultImage = [UIImage imageWithCGImage:fullResolutionImageRef scale:[[photoAsset.alAsset defaultRepresentation] scale] orientation:(UIImageOrientation)[[photoAsset.alAsset defaultRepresentation] orientation]];
        }
        
        //return resultImage ? resultImage : [self originImage:photoAsset];
        return resultImage;
    }
}
@end
