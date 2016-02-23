//
//  DLPhotoManager.h
//  DLPhotoPicker
//
//  Created by 沧海无际 on 16/2/20.
//  Copyright © 2016年 darling0825. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Photos/Photos.h>
#import "DLPhotoCollection.h"
#import "DLPhotoAsset.h"

@protocol DLPhotoManagerDelegate <NSObject>

@optional
- (void)accessDenied;
- (void)haveNonePhotoCollection;
- (void)getAlbumsSuccess;

@end

@interface DLPhotoManager : NSObject

@property (nonatomic, copy) NSArray *assetCollections;

+ (instancetype)sharedInstance;


/**
 *  The assets picker’s delegate object.
 */
@property (nonatomic, weak) id <DLPhotoManagerDelegate> delegate;

/**
 *  Set the `assetCollectionSubtypes` to specify which asset collections (albums) to be shown in the picker.
 *
 *  You can specify which albums and their order to be shown in the picker by creating an `NSArray` of `NSNumber`
 *  that containing the value of `PHAssetCollectionSubtype`.
 */
@property (nonatomic, copy) NSArray *assetCollectionSubtypes;

/**
 *  Set the `PHFetchOptions` to specify options when fetching asset collections (albums).
 *
 *  @see assetsFetchOptions
 */
@property (nonatomic, strong) PHFetchOptions *assetCollectionFetchOptions;

/**
 *  Set the `PHFetchOptions` to specify options when fetching assets.
 *
 *  @see assetCollectionFetchOptions
 */
@property (nonatomic, strong) PHFetchOptions *assetsFetchOptions;

/**
 *  Determines whether or not the empty albums is shown in the album list.
 *
 *  All albums are visible by default. To hide albums without assets matched with `assetsFetchOptions`,
 *  set this property’s value to `NO`.
 *
 *  @see assetsFetchOptions
 */
@property (nonatomic, assign) BOOL showsEmptyAlbums;


@property (nonatomic, assign) CGSize assetCollectionThumbnailSize;
@property (nonatomic, strong) PHImageRequestOptions *thumbnailRequestOptions;

/**
 *  checkAuthorizationStatus
 */
- (void)checkAuthorizationStatus;

/**
 *  requestAuthorization
 */
- (void)requestAuthorization;
- (NSArray *)assetsForPhotoCollection:(DLPhotoCollection *)photoCollection;
- (NSUInteger)assetCountOfCollection:(DLPhotoCollection *)collection;
- (NSArray *)posterAssetsFromAssetCollection:(DLPhotoCollection *)collection count:(NSUInteger)count;
- (void)requestThumbnailsForPhotoAsset:(DLPhotoAsset *)photoAsset containerSize:(CGSize)containerSize completion:(void (^)(UIImage *thumbnail))completion;

@end
