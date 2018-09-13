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
    _showsEmptyAlbums               = YES;
    
    _semaphore = dispatch_semaphore_create(1);
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
          [NSNumber numberWithInt:PHAssetCollectionSubtypeSmartAlbumRecentlyAdded],
          [NSNumber numberWithInt:PHAssetCollectionSubtypeSmartAlbumFavorites],
          [NSNumber numberWithInt:PHAssetCollectionSubtypeSmartAlbumPanoramas],
          [NSNumber numberWithInt:PHAssetCollectionSubtypeSmartAlbumVideos],
          [NSNumber numberWithInt:PHAssetCollectionSubtypeSmartAlbumSlomoVideos],
          [NSNumber numberWithInt:PHAssetCollectionSubtypeSmartAlbumTimelapses],
          [NSNumber numberWithInt:PHAssetCollectionSubtypeSmartAlbumBursts],
          [NSNumber numberWithInt:PHAssetCollectionSubtypeSmartAlbumAllHidden],
          [NSNumber numberWithInt:PHAssetCollectionSubtypeSmartAlbumGeneric],
          [NSNumber numberWithInt:PHAssetCollectionSubtypeAlbumSyncedEvent],
          [NSNumber numberWithInt:PHAssetCollectionSubtypeAlbumSyncedFaces],
          [NSNumber numberWithInt:PHAssetCollectionSubtypeAlbumImported],
          [NSNumber numberWithInt:PHAssetCollectionSubtypeAlbumRegular],
          [NSNumber numberWithInt:PHAssetCollectionSubtypeAlbumMyPhotoStream],
          [NSNumber numberWithInt:PHAssetCollectionSubtypeAlbumSyncedAlbum],
          [NSNumber numberWithInt:PHAssetCollectionSubtypeAlbumCloudShared]];


        // Add others
        NSMutableArray *subtypes = [NSMutableArray arrayWithArray:_assetCollectionSubtypes];

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
        if (@available(iOS 10.0, *)) {
            /*『最近删除』相册*/
            //[subtypes addObject:[NSNumber numberWithInt:1000000201]];
        }
#endif

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_9_0
        if ([[PHAsset new] respondsToSelector:@selector(sourceType)])
        {
            if (@available(iOS 9.0, *)) {
                [subtypes insertObject:[NSNumber numberWithInt:PHAssetCollectionSubtypeSmartAlbumSelfPortraits] atIndex:4];
                [subtypes insertObject:[NSNumber numberWithInt:PHAssetCollectionSubtypeSmartAlbumScreenshots] atIndex:7];
            }
        }
#endif

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_2
        if (@available(iOS 10.2, *)) {
            [subtypes insertObject:[NSNumber numberWithInt:PHAssetCollectionSubtypeSmartAlbumDepthEffect] atIndex:8];
        }
#endif

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_3
        if (@available(iOS 10.3, *)) {
            [subtypes insertObject:[NSNumber numberWithInt:PHAssetCollectionSubtypeSmartAlbumLivePhotos] atIndex:5];
        }
#endif

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_11_0
        if (@available(iOS 11.0, *)) {
            [subtypes insertObject:[NSNumber numberWithInt:PHAssetCollectionSubtypeSmartAlbumAnimated] atIndex:6];
        }
#endif

        _assetCollectionSubtypes = [NSArray arrayWithArray:subtypes];

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
    [self checkAuthorizationStatus_AfteriOS8];
}

- (void)requestAuthorization
{
    [self requestAuthorizationStatus_AfteriOS8];
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
}

#pragma mark - create album
- (void)createAlbumWithName:(NSString *)albumName
                resultBlock:(void(^)(DLPhotoCollection *collection))completion
               failureBlock:(void(^)(NSError *error))failure
{
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
}

- (void)removeAlbum:(DLPhotoCollection *)photoCollection
        resultBlock:(void(^)(BOOL success))completion
       failureBlock:(void(^)(NSError *error))failure
{
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

    if (!albumName.length) {
        //  add asset to default collection
        addVideoBlock(videoUrl, nil);
    }
    else if (savedAssetCollection) {
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
}

- (void)removeAsset:(NSArray<DLPhotoAsset *> *)photoAssets
         completion:(void(^)(BOOL success))completion
            failure:(void(^)(NSError *error))failure
{
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
}

- (void)saveImageData:(NSData *)imageData
              toAlbum:(NSString *)albumName
             metadata:(NSDictionary *)metadata
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

        __block PHObjectPlaceholder *placeholderAsset = nil;

        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            if (assetCollection) {
                // saved to assetCollection
                PHAssetChangeRequest *assetChangeRequest = [PHAssetChangeRequest creationRequestForAssetFromImage:[UIImage imageWithData:data]];
                PHAssetCollectionChangeRequest *assetCollectionChangeRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:assetCollection];
                [assetCollectionChangeRequest addAssets:@[assetChangeRequest.placeholderForCreatedAsset]];

                /*
                PHAssetResourceCreationOptions *options = [PHAssetResourceCreationOptions new];
                PHAssetCreationRequest *request = [PHAssetCreationRequest creationRequestForAsset];
                [request addResourceWithType:PHAssetResourceTypePhoto data:data options:options];
                
                PHAssetCollectionChangeRequest *assetCollectionChangeRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:assetCollection];
                [assetCollectionChangeRequest addAssets:@[request.placeholderForCreatedAsset]];
                 */
            }else{
                // only saved to CameraRoll

                PHAssetChangeRequest *assetChangeRequest = [PHAssetChangeRequest creationRequestForAssetFromImage:[UIImage imageWithData:data]];
                placeholderAsset = assetChangeRequest.placeholderForCreatedAsset;
                /*
                PHAssetResourceCreationOptions *options = [PHAssetResourceCreationOptions new];
                [[PHAssetCreationRequest creationRequestForAsset] addResourceWithType:PHAssetResourceTypePhoto data:data options:options];
                 */
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

        __block PHObjectPlaceholder *placeholderAsset = nil;

        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            if (assetCollection) {
                // saved to assetCollection
                PHAssetChangeRequest *assetChangeRequest = [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:videoUrl];
                PHAssetCollectionChangeRequest *assetCollectionChangeRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:assetCollection];
                [assetCollectionChangeRequest addAssets:@[assetChangeRequest.placeholderForCreatedAsset]];
            }else {
                // only saved to CameraRoll
                PHAssetChangeRequest *assetChangeRequest = [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:videoUrl];
                placeholderAsset = assetChangeRequest.placeholderForCreatedAsset;
                /*
                PHAssetResourceCreationOptions *options = [PHAssetResourceCreationOptions new];
                [[PHAssetCreationRequest creationRequestForAsset] addResourceWithType:PHAssetResourceTypeVideo fileURL:videoUrl options:options];
                 */
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


#pragma mark - Photo Edit
- (void)requestContentEditing:(DLPhotoAsset *)asset
                   completion:(void (^)(UIImage *image, PHContentEditingInput *contentEditingInput, NSDictionary *info))completion
{
    BOOL canEdit = NO;
    if (@available(iOS 9.1, *)) {
        canEdit = [asset.phAsset canPerformEditOperation:PHAssetEditOperationContent] &&
        !(asset.phAsset.mediaSubtypes & PHAssetMediaSubtypePhotoLive);
    }else {
        canEdit = [asset.phAsset canPerformEditOperation:PHAssetEditOperationContent];
    }

    if (canEdit){
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
    [self getAlbumsFromDevice];
}

- (void)getAlbumsFromDevice
{
    PHFetchResult *fetchResult = [PHAsset fetchAssetsWithOptions:self.assetsFetchOptions];
    if (fetchResult.count <= 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showNoAssets];
            [self getAlbumsCompletion:NO];
        });
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
    
    [self getAlbumsCompletion:fetchResults.count > 0];
}


#pragma mark - fetch asset
- (NSArray *)assetsForPhotoCollection:(DLPhotoCollection *)photoCollection
{
    NSMutableArray *photoAssets = [[NSMutableArray alloc] initWithCapacity:photoCollection.count];
    
    PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:photoCollection.assetCollection
                                                               options:self.assetsFetchOptions];

    for (PHAsset *asset in fetchResult) {
        DLPhotoAsset *phAsset = [[DLPhotoAsset alloc] initWithAsset:asset];
        [photoAssets addObject:phAsset];
    }

    photoCollection.fetchResult = fetchResult;

    return photoAssets;
}

- (NSUInteger)assetCountOfPhotoCollection:(DLPhotoCollection *)photoCollection
{
    return [[PHAsset fetchAssetsInAssetCollection:photoCollection.assetCollection options:self.assetsFetchOptions] count];
}

#pragma mark - poster images
- (NSArray *)posterImagesForPhotoCollection:(DLPhotoCollection *)photoCollection
                              thumbnailSize:(CGSize)thumbnailSize
                                      count:(NSUInteger)count
{
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

- (NSArray *)posterAssetsForPhotoCollection:(DLPhotoCollection *)photoCollection count:(NSUInteger)count
{
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

#pragma mark - register change observer
- (void)registerChangeObserver:(id<PHPhotoLibraryChangeObserver>)observer
{
    [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:observer];
}

- (void)unregisterChangeObserver:(id<PHPhotoLibraryChangeObserver>)observer
{
    [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:observer];
}


#pragma mark - caching images
- (void)startCachingImagesForAssets:(DLPhotoAsset *)asset targetSize:(CGSize)targetSize
{
    [self.phCachingImageManager startCachingImagesForAssets:@[asset.phAsset]
                                                 targetSize:targetSize
                                                contentMode:PHImageContentModeAspectFill
                                                    options:self.thumbnailRequestOptions];
}

- (void)stopCachingImagesForAssets:(DLPhotoAsset *)asset targetSize:(CGSize)targetSize
{
    [self.phCachingImageManager stopCachingImagesForAssets:@[asset.phAsset]
                                                targetSize:targetSize
                                               contentMode:PHImageContentModeAspectFill
                                                   options:self.thumbnailRequestOptions];
}

- (void)stopCachingImagesForAllAssets
{
    [self.phCachingImageManager stopCachingImagesForAllAssets];
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

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_9_0
                if ([options respondsToSelector:@selector(setFetchLimit:)]){
                    if (@available(iOS 9.0, *)) {
                        options.fetchLimit = 1;
                    }
                }
#endif

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
    __block UIImage *resultImage;

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

    return resultImage;
}

@end
