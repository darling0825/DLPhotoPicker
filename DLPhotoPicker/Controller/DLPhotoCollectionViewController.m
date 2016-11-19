//
//  DLPhotoCollectionViewController.m
//  DLPhotoPicker
//
//  Created by 沧海无际 on 16/2/20.
//  Copyright © 2016年 darling0825. All rights reserved.
//

#import "DLPhotoCollectionViewController.h"
#import "DLPhotoPickerViewController.h"
#import "DLPhotoCollectionViewCell.h"
#import "DLPhotoCollectionViewLayout.h"
#import "DLPhotoCollectionViewFooter.h"
#import "DLPhotoManager.h"
#import "DLPhotoPickerNoAssetsView.h"
#import "DLPhotoBackgroundView.h"
#import "DLPhotoPickerDefines.h"
#import "NSBundle+DLPhotoPicker.h"
#import "UIImage+DLPhotoPicker.h"
#import "NSNumberFormatter+DLPhotoPicker.h"
#import "NSIndexSet+DLPhotoPicker.h"
#import "UICollectionView+DLPhotoPicker.h"
#import "DLPhotoPageViewController.h"
#import "DLPhotoItemViewController.h"
#import "AssetActivityProvider.h"
#import "DLProgressHud.h"

NSString * const DLPhotoCollectionViewCellIdentifier = @"DLPhotoCollectionViewCellIdentifier";
NSString * const DLPhotoCollectionViewFooterIdentifier = @"DLPhotoCollectionViewFooterIdentifier";


@interface DLPhotoCollectionViewController ()
<PHPhotoLibraryChangeObserver, ALAssetsLibraryChangeObserver>

@property (nonatomic, strong) NSMutableArray *assets;
@property (nonatomic, assign) BOOL didLoadAssets;

@property (nonatomic, strong) DLPhotoCollectionViewFooter *footer;
@property (nonatomic, strong) DLPhotoPickerNoAssetsView *noAssetsView;

@property (nonatomic, strong) DLPhotoPageViewController *pageViewController;

@property (nonatomic, assign) CGRect previousPreheatRect;
@property (nonatomic, assign) CGRect previousBounds;
@property (nonatomic, assign) BOOL didLayoutSubviews;

@property (nonatomic, strong) UIBarButtonItem *selectButton;
@property (nonatomic, strong) UIBarButtonItem *confirmButton;

@property (nonatomic, strong) UIActivityViewController *activityVC;
@property (nonatomic, strong) UIPopoverController *popoverController;

@end

@implementation DLPhotoCollectionViewController

- (instancetype)init
{
    DLPhotoCollectionViewLayout *layout = [DLPhotoCollectionViewLayout new];
    
    if (self = [super initWithCollectionViewLayout:layout]){
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupViews];
    [self setupButtons];
    
    [self setEditingStatus];
    
    [self updateNavigationTitle];
    
    [self registerChangeObserver];
    [self addNotificationObserver];
    
    [self resetCachedAssetImages];
    
    [self resetAssetsAndReload];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.picker.pickerType == DLPhotoPickerTypeDisplay){
        if (self.isEditing) {
            [self editAction:nil];
        }
    }
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self updateCachedAssetImages];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.navigationController setToolbarHidden:YES animated:YES];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
    if (!CGRectEqualToRect(self.view.bounds, self.previousBounds))
    {
        [self updateCollectionViewLayout];
        self.previousBounds = self.view.bounds;
    }
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    if (!self.didLayoutSubviews && self.assets.count > 0)
    {
        [self scrollToBottomIfNeeded];
        self.didLayoutSubviews = YES;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    _activityVC = nil;
    _popoverController = nil;
}

- (void)dealloc
{
    [self unregisterChangeObserver];
    [self removeNotificationObserver];
}

#pragma mark
- (void)setupViews
{
    //self.extendedLayoutIncludesOpaqueBars = YES;
    
    self.collectionView.backgroundColor = DLPhotoCollectionViewBackgroundColor;
    
    if (self.picker.pickerType == DLPhotoPickerTypePicker) {
        self.collectionView.allowsMultipleSelection = YES;
    }
    
    [self.collectionView registerClass:DLPhotoCollectionViewCell.class
            forCellWithReuseIdentifier:DLPhotoCollectionViewCellIdentifier];
    
    [self.collectionView registerClass:DLPhotoCollectionViewFooter.class
            forSupplementaryViewOfKind:UICollectionElementKindSectionFooter
                   withReuseIdentifier:DLPhotoCollectionViewFooterIdentifier];
    
    DLPhotoBackgroundView *CollectionView = [DLPhotoBackgroundView new];
    [self.view insertSubview:CollectionView atIndex:0];
    [self.view setNeedsUpdateConstraints];
}

- (void)setupButtons
{
    if (self.picker.pickerType == DLPhotoPickerTypePicker) {
        [self createCancelPickButton];
        [self createPickerToolBar];
    }else if (self.picker.pickerType == DLPhotoPickerTypeDisplay){
        [self createEditButton];
        [self createBackButton];
    }else{
    }
}

- (void)setEditingStatus
{
    if (self.picker.pickerType == DLPhotoPickerTypePicker) {
        [self setEditing:YES animated:YES];
    }else if (self.picker.pickerType == DLPhotoPickerTypeDisplay){
        [self setEditing:NO animated:YES];
    }else{
    }
}

- (void)resetAssetsAndReload
{
    [DLProgressHud showActivity];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        self.assets = [[[DLPhotoManager sharedInstance] assetsForPhotoCollection:self.photoCollection] mutableCopy];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self reloadData];
            
            [DLProgressHud dismiss];
            
            self.didLoadAssets = YES;
        });
        
    });
}

- (DLPhotoAsset *)assetAtIndexPath:(NSIndexPath *)indexPath
{
    return (self.assets.count > 0) ? self.assets[indexPath.row] : nil;
}

- (NSIndexPath *)indexPathForAsset:(DLPhotoAsset *)asset
{
    if (asset) {
        NSUInteger index = [self.assets indexOfObject:asset];
        if (index < self.assets.count) {
            return [NSIndexPath indexPathForRow:index inSection:0];
        }
    }
    
    return nil;
}

- (NSArray *)selectedAssets
{
    return self.picker.selectedAssets;
}

#pragma mark - Notifications

- (void)addNotificationObserver
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];

    [center addObserver:self
               selector:@selector(photoPickerSelectedAssetsDidChange:)
                   name:DLPhotoPickerSelectedAssetsDidChangeNotification
                 object:nil];
    
    [center addObserver:self
               selector:@selector(photoPickerEnterEditMode:)
                   name:DLPhotoPickerDidEnterSelectModeNotification
                 object:nil];
    
    [center addObserver:self
               selector:@selector(photoPickerExitEditMode:)
                   name:DLPhotoPickerDidExitSelectModeNotification
                 object:nil];
    
}

- (void)removeNotificationObserver
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    
    [center removeObserver:self name:DLPhotoPickerSelectedAssetsDidChangeNotification object:nil];
    [center removeObserver:self name:DLPhotoPickerDidEnterSelectModeNotification object:nil];
    [center removeObserver:self name:DLPhotoPickerDidExitSelectModeNotification object:nil];
}

#pragma mark - Photo library change observer
- (void)registerChangeObserver
{
    [[DLPhotoManager sharedInstance] registerChangeObserver:self];
}

- (void)unregisterChangeObserver
{
    [[DLPhotoManager sharedInstance] unregisterChangeObserver:self];
}

#pragma mark - Photo library changed
- (void)photoLibraryDidChange:(PHChange *)changeInstance
{
    // Call might come on any background queue. Re-dispatch to the main queue to handle it.
    dispatch_async(dispatch_get_main_queue(), ^{
        
        PHFetchResultChangeDetails *changeDetails = [changeInstance changeDetailsForFetchResult:self.photoCollection.fetchResult];
        
        if (changeDetails)
        {
            PHFetchResult *fetchResult = [changeDetails fetchResultAfterChanges];
            self.photoCollection.fetchResult = fetchResult;
            
            UICollectionView *collectionView = self.collectionView;
            
            //  Only has moves
            if (![changeDetails hasIncrementalChanges] || [changeDetails hasMoves]){
                [collectionView reloadData];
                [self resetCachedAssetImages];
            }
            else{
                NSIndexSet *removedIndexes = [changeDetails removedIndexes];
                NSArray *removedPaths = [removedIndexes indexPathsFromIndexesWithSection:0];
                
                NSIndexSet *insertedIndexes = [changeDetails insertedIndexes];
                NSArray *insertedPaths = [insertedIndexes indexPathsFromIndexesWithSection:0];
                
                NSIndexSet *changedIndexes = [changeDetails changedIndexes];
                NSArray *changedPaths = [changedIndexes indexPathsFromIndexesWithSection:0];
                
                BOOL shouldReload = NO;
                
                //  Has removed
//                if (changedPaths != nil && removedPaths != nil)
//                {
//                    for (NSIndexPath *changedPath in changedPaths)
//                    {
//                        if ([removedPaths containsObject:changedPath])
//                        {
//                            shouldReload = YES;
//                            break;
//                        }
//                    }
//                }
//                
//                //
//                if (removedPaths.lastObject && ((NSIndexPath *)removedPaths.lastObject).item >= self.photoCollection.fetchResult.count)
//                {
//                    shouldReload = YES;
//                }
                
                if (shouldReload){
                    [self reloadData];
                }
                else{
                    // if we have incremental diffs, tell the collection view to animate insertions and deletions
                    [collectionView performBatchUpdates:^{
                        if ([removedPaths count]){
                            [self.assets removeObjectsAtIndexes:removedIndexes];
                            [collectionView deleteItemsAtIndexPaths:removedPaths];
                        }
                        
                        if ([insertedPaths count]){
                            NSMutableArray *insertAssets = [NSMutableArray arrayWithCapacity:insertedIndexes.count];
                            for (NSIndexPath *indexPath in insertedPaths) {
                                [insertAssets addObject:[[DLPhotoAsset alloc] initWithAsset:fetchResult[indexPath.row]]];
                            }
                            [self.assets insertObjects:insertAssets atIndexes:insertedIndexes];
                            [collectionView insertItemsAtIndexPaths:insertedPaths];
                        }
                        
                        if ([changedPaths count]){
                            NSMutableArray *changedAssets = [NSMutableArray arrayWithCapacity:changedIndexes.count];
                            for (NSIndexPath *indexPath in changedPaths) {
                                [changedAssets addObject:[[DLPhotoAsset alloc] initWithAsset:fetchResult[indexPath.row]]];
                            }
                            [self.assets replaceObjectsAtIndexes:changedIndexes withObjects:changedAssets];
                            [collectionView reloadItemsAtIndexPaths:changedPaths];
                        }
                    } completion:^(BOOL finished){
                        if (finished){
                            [self resetCachedAssetImages];
                            [self updateToolBarStatus];
                        }
                    }];
                }
            }
            
            [self.footer bind:self.photoCollection];
            
            if (fetchResult.count == 0){
                [self showNoAssets];
            }
            else{
                [self hideNoAssets];
            }
        }
        
        if ([self.delegate respondsToSelector:@selector(collectionViewController:photoLibraryDidChangeForPhotoCollection:)]){
            [self.delegate collectionViewController:self photoLibraryDidChangeForPhotoCollection:self.photoCollection];
        }
    });
}

- (void)assetsLibraryChanged:(NSNotification *)notification
{
    /*
     *
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong typeof(self) strongSelf = weakSelf;

        NSDictionary *info = [notification userInfo];
        NSSet *updatedAssets = [info objectForKey:ALAssetLibraryUpdatedAssetsKey];
        NSSet *updatedAssetGroup = [info objectForKey:ALAssetLibraryUpdatedAssetGroupsKey];
        NSSet *deletedAssetGroup = [info objectForKey:ALAssetLibraryDeletedAssetGroupsKey];
        NSSet *insertedAssetGroup = [info objectForKey:ALAssetLibraryInsertedAssetGroupsKey];
        
         NSLog(@"---------------------");
         NSLog(@"      updated assets:%@", updatedAssets);
         NSLog(@" updated asset group:%@", updatedAssetGroup);
         NSLog(@" deleted asset group:%@", deletedAssetGroup);
         NSLog(@"inserted asset group:%@", insertedAssetGroup);
         NSLog(@"---------------------");
         
        if(info == nil){
            //All Clear
            [strongSelf setupAssets];
            return;
        }
        
        if(info.count == 0){
            return;
        }
        
        if (updatedAssets.count >0){
            for (NSURL *assetUrl in updatedAssets) {
                [[[DLPhotoManager sharedInstance] assetsLibrary] assetForURL:assetUrl resultBlock:^(ALAsset *asset) {
                    if (asset) {
                        DLPhotoAsset *newAsset = [[DLPhotoAsset alloc] initWithAsset:asset];
                        NSUInteger index = [strongSelf indexOfAsset:newAsset inAssets:strongSelf.assets];
                        if (index < self.assets.count) {
                            [strongSelf.assets replaceObjectAtIndex:index withObject:newAsset];
                        }
                    }
                } failureBlock:^(NSError *error) {
                    NSLog(@">>> %@",error);
                }];
            }
        }
    });
     */
}

/*
#pragma mark - Helper methods
- (NSDictionary *)queryStringToDictionaryOfNSURL:(NSURL *)url
{
    NSArray *urlComponents = [url.query componentsSeparatedByString:@"&"];
    if (urlComponents.count <= 0)
    {
        return nil;
    }
    NSMutableDictionary *queryDict = [NSMutableDictionary dictionary];
    for (NSString *keyValuePair in urlComponents)
    {
        NSArray *pairComponents = [keyValuePair componentsSeparatedByString:@"="];
        [queryDict setObject:pairComponents[1] forKey:pairComponents[0]];
    }
    return [queryDict copy];
}

- (NSUInteger)indexOfAsset:(DLPhotoAsset *)asset inAssets:(NSArray *)groups
{
    NSString *targetAssetId = [self queryStringToDictionaryOfNSURL:asset.url][@"id"];
    __block NSUInteger index = NSNotFound;
    [groups enumerateObjectsUsingBlock:^(DLPhotoAsset *obj, NSUInteger idx, BOOL *stop) {
        NSString *id = [self queryStringToDictionaryOfNSURL:obj.url][@"id"];
        if ([id isEqualToString:targetAssetId]){
            index = idx;
            *stop = YES;
        }
    }];
    return index;
}
*/

#pragma mark - Asset images caching
- (void)resetCachedAssetImages
{
    [[DLPhotoManager sharedInstance] stopCachingImagesForAllAssets];
    self.previousPreheatRect = CGRectZero;
}

- (void)updateCachedAssetImages
{
    BOOL isViewVisible = [self isViewLoaded] && [[self view] window] != nil;
    
    if (!isViewVisible)
        return;
    
    // The preheat window is twice the height of the visible rect
    CGRect preheatRect = self.collectionView.bounds;
    preheatRect = CGRectInset(preheatRect, 0.0f, -0.5f * CGRectGetHeight(preheatRect));
    
    // If scrolled by a "reasonable" amount...
    CGFloat delta = ABS(CGRectGetMidY(preheatRect) - CGRectGetMidY(self.previousPreheatRect));
    
    if (delta > CGRectGetHeight(self.collectionView.bounds) / 3.0f)
    {
        // Compute the assets to start caching and to stop caching.
        NSMutableArray *addedIndexPaths = [NSMutableArray array];
        NSMutableArray *removedIndexPaths = [NSMutableArray array];
        
        [self computeDifferenceBetweenRect:self.previousPreheatRect
                                   andRect:preheatRect
                            removedHandler:^(CGRect removedRect) {
                                NSArray *indexPaths = [self.collectionView indexPathsForElementsInRect:removedRect];
                                [removedIndexPaths addObjectsFromArray:indexPaths];
                            } addedHandler:^(CGRect addedRect) {
                                NSArray *indexPaths = [self.collectionView indexPathsForElementsInRect:addedRect];
                                [addedIndexPaths addObjectsFromArray:indexPaths];
                            }];
        
        [self startCachingThumbnailsForIndexPaths:addedIndexPaths];
        [self stopCachingThumbnailsForIndexPaths:removedIndexPaths];
        
        self.previousPreheatRect = preheatRect;
    }
}

- (void)startCachingThumbnailsForIndexPaths:(NSArray *)indexPaths
{
    for (NSIndexPath *indexPath in indexPaths)
    {
        DLPhotoAsset *asset = [self assetAtIndexPath:indexPath];
        
        if (!asset) break;
        
        UICollectionViewLayoutAttributes *attributes =
        [self.collectionView.collectionViewLayout layoutAttributesForItemAtIndexPath:indexPath];
        
        CGSize targetSize = CGSizeMake(attributes.size.width * ScreenScale, attributes.size.height * ScreenScale);
        
        [[DLPhotoManager sharedInstance] startCachingImagesForAssets:asset targetSize:targetSize];
    }
}

- (void)stopCachingThumbnailsForIndexPaths:(NSArray *)indexPaths
{
    for (NSIndexPath *indexPath in indexPaths)
    {
        DLPhotoAsset *asset = [self assetAtIndexPath:indexPath];
        
        if (!asset) break;

        UICollectionViewLayoutAttributes *attributes =
        [self.collectionView.collectionViewLayout layoutAttributesForItemAtIndexPath:indexPath];
        
        CGSize targetSize = CGSizeMake(attributes.size.width * ScreenScale, attributes.size.height * ScreenScale);
        
        [[DLPhotoManager sharedInstance] stopCachingImagesForAssets:asset targetSize:targetSize];
    }
}

- (void)computeDifferenceBetweenRect:(CGRect)oldRect andRect:(CGRect)newRect removedHandler:(void (^)(CGRect removedRect))removedHandler addedHandler:(void (^)(CGRect addedRect))addedHandler
{
    if (CGRectIntersectsRect(newRect, oldRect)) {
        CGFloat oldMaxY = CGRectGetMaxY(oldRect);
        CGFloat oldMinY = CGRectGetMinY(oldRect);
        CGFloat newMaxY = CGRectGetMaxY(newRect);
        CGFloat newMinY = CGRectGetMinY(newRect);
        if (newMaxY > oldMaxY) {
            CGRect rectToAdd = CGRectMake(newRect.origin.x, oldMaxY, newRect.size.width, (newMaxY - oldMaxY));
            addedHandler(rectToAdd);
        }
        if (oldMinY > newMinY) {
            CGRect rectToAdd = CGRectMake(newRect.origin.x, newMinY, newRect.size.width, (oldMinY - newMinY));
            addedHandler(rectToAdd);
        }
        if (newMaxY < oldMaxY) {
            CGRect rectToRemove = CGRectMake(newRect.origin.x, newMaxY, newRect.size.width, (oldMaxY - newMaxY));
            removedHandler(rectToRemove);
        }
        if (oldMinY < newMinY) {
            CGRect rectToRemove = CGRectMake(newRect.origin.x, oldMinY, newRect.size.width, (newMinY - oldMinY));
            removedHandler(rectToRemove);
        }
    } else {
        addedHandler(newRect);
        removedHandler(oldRect);
    }
}

#pragma mark - Collection view layout
- (void)updateCollectionViewLayout
{
    UITraitCollection *trait = self.traitCollection;
    CGSize contentSize = self.view.bounds.size;
    UICollectionViewLayout *layout = [[DLPhotoCollectionViewLayout alloc] initWithContentSize:contentSize traitCollection:trait];
    
    if ([self.picker.delegate respondsToSelector:@selector(pickerController:collectionViewLayoutForContentSize:traitCollection:)]) {
        layout = [self.picker.delegate pickerController:self.picker collectionViewLayoutForContentSize:contentSize traitCollection:trait];
    }
    
    __weak DLPhotoCollectionViewController *weakSelf = self;
    
    [self.collectionView setCollectionViewLayout:layout animated:NO completion:^(BOOL finished){
        [weakSelf.collectionView reloadItemsAtIndexPaths:[weakSelf.collectionView indexPathsForVisibleItems]];
    }];
}

#pragma mark - Scroll view delegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self updateCachedAssetImages];
}

#pragma mark - Scroll to bottom
- (void)scrollToBottomIfNeeded
{
    BOOL shouldScrollToBottom = YES;
    
    if ([self.picker.delegate respondsToSelector:
         @selector(pickerController:shouldScrollToBottomForPhotoCollection:)]){
        shouldScrollToBottom = [self.picker.delegate pickerController:self.picker shouldScrollToBottomForPhotoCollection:self.photoCollection];
    }else{
        shouldScrollToBottom = YES;
    }
    
    if (shouldScrollToBottom && self.assets.count > 0){
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:self.assets.count-1 inSection:0];
        [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionTop animated:NO];
    }
}

#pragma mark - Reload data
- (void)reloadData
{
    if (self.assets.count > 0){
        [self hideNoAssets];
        [self.collectionView reloadData];
    }else{
        [self showNoAssets];
    }
}

#pragma mark - Navigation Item
- (void)createEditButton{
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(editAction:)];
}

- (void)createBackButton{
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
}

- (void)createSelectButton{
    self.selectButton = [[UIBarButtonItem alloc] initWithTitle:DLPhotoPickerLocalizedString(@"Select All",nil) style:UIBarButtonItemStylePlain target:self action:@selector(selectAction:)];
    self.navigationItem.leftBarButtonItem = self.selectButton;
}

- (void)createCancelEditButton{
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelEditAction:)];
}

- (void)createCancelPickButton{
    self.navigationItem.rightBarButtonItem =
    [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                  target:self
                                                  action:@selector(cancelPickAction:)];
}

- (void)createDisplayToolBar{
    UIBarButtonItem *shareButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(photoShareAction:)];
    
    UIBarButtonItem *toCopyButton = [[UIBarButtonItem alloc] initWithTitle:DLPhotoPickerLocalizedString(@"Copy to",nil) style:UIBarButtonItemStylePlain target:self action:@selector(finishPickAction:)];
    
    UIBarButtonItem *deleteButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(photoDeleteAction:)];
    
    NSArray *toolItems = @[shareButton, self.toolbarSpace, toCopyButton, self.toolbarSpace, deleteButton];
    if (!(UsePhotoKit)) {
        toolItems = @[shareButton, self.toolbarSpace, toCopyButton];
    }
    
    for (UITabBarItem *item in toolItems) {
        item.enabled = NO;
    }
    
    [self.navigationController setToolbarHidden:NO animated:YES];
    self.toolbarItems = toolItems;
    [self setToolbarItems:self.toolbarItems animated:YES];
}

- (void)createPickerToolBar{
    self.selectButton = [[UIBarButtonItem alloc] initWithTitle:DLPhotoPickerLocalizedString(@"Select All",nil) style:UIBarButtonItemStylePlain target:self action:@selector(selectAction:)];

    self.confirmButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(finishPickAction:)];
    
    [self.navigationController setToolbarHidden:NO animated:YES];
    
    self.toolbarItems = @[self.selectButton, self.toolbarSpace, self.confirmButton];
    [self setToolbarItems:self.toolbarItems animated:YES];
}

- (UIBarButtonItem *)toolbarSpace
{
    return [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
}

#pragma mark - Button Action
- (void)editAction:(UIBarButtonItem *)sender{
    
    self.collectionView.allowsMultipleSelection = YES;
    
    [self setEditing:YES animated:YES];
    
    //Nav Button
    [self createCancelEditButton];
    [self createSelectButton];
    [self updateNavigationTitle];
    
    //ToolBar
    [self createDisplayToolBar];
    [self updateToolBarStatus];
    
    [self reloadData];
}

- (void)cancelEditAction:(UIBarButtonItem *)sender{
    
    self.collectionView.allowsMultipleSelection = NO;
    
    [self setEditing:NO animated:YES];
    
    // Unselect all
    [self setAssetSelected:NO];
    
    [self createEditButton];
    [self updateNavigationTitle];
    
    self.navigationItem.leftBarButtonItem = nil;
    
    //ToolBar
    [self.navigationController setToolbarHidden:YES animated:YES];
    
    [self reloadData];
}

-(void)cancelPickAction:(UIBarButtonItem *)sender
{
    if ([self.picker.delegate respondsToSelector:@selector(pickerControllerDidCancel:)]){
        [self.picker.delegate pickerControllerDidCancel:self.picker];
    }
}

- (void)selectAction:(UIBarButtonItem *)sender{
    NSInteger selectedCount = self.selectedAssets.count;
    NSInteger numberOfAsset = self.assets.count;
    if (selectedCount == numberOfAsset) {
        [self setAssetSelected: NO];
    }else{
        [self setAssetSelected: YES];
    }
    
    [self updateToolBarStatus];
    [self updateNavigationTitle];
    
    [self reloadData];
}

- (void)finishPickAction:(UIBarButtonItem *)sender{
    if ([self.picker.delegate respondsToSelector:@selector(pickerController:didFinishPickingAssets:)]){
        [self.picker.delegate pickerController:self.picker didFinishPickingAssets:self.selectedAssets];
    }
    
    [self cancelEditAction: nil];
}
- (void)photoShareAction:(UIBarButtonItem *)sender{
    
    // more images maybe lead to memory leak.
    NSUInteger maxSelected = self.picker.maxNumberOfSelectedToShare;
    if (self.picker.selectedAssets.count > maxSelected) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:DLPhotoPickerLocalizedString(@"Attention",nil)
                                                        message:[NSString stringWithFormat:DLPhotoPickerLocalizedString(@"Please select not more than %lud items.",nil), maxSelected]
                                                       delegate:nil
                                              cancelButtonTitle:DLPhotoPickerLocalizedString(@"OK", nil)
                                              otherButtonTitles:nil];
        
        [alert show];
        return;
    }
    
    NSMutableArray *items = [NSMutableArray arrayWithCapacity:self.picker.selectedAssets.count];
    for (DLPhotoAsset *asset in self.picker.selectedAssets) {
        AssetActivityProvider *assetProvider = [[AssetActivityProvider alloc] initWithAsset:asset];
        [items addObject:assetProvider];
    }
    
    self.activityVC = [[UIActivityViewController alloc] initWithActivityItems:items applicationActivities:nil];
    
    typeof(self) __weak weakSelf = self;
    
    if (DLiOS_8_OR_LATER) {
        self.activityVC.completionWithItemsHandler = ^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError){
            typeof(self) __strong strongSelf = weakSelf;
            NSLog(@">>> Activity Type selected: %@", activityType);
            if (completed) {
                NSLog(@">>> Activity(%@) was performed.", activityType);
            } else {
                if (activityType == nil) {
                    NSLog(@">>> User dismissed the view controller without making a selection.");
                } else {
                    NSLog(@">>> Activity(%@) was not performed.", activityType);
                }
            }
            
            
            for (AssetActivityProvider *provider in items) {
                [provider cleanup];
            }
            [DLProgressHud dismiss];
            strongSelf.activityVC.completionWithItemsHandler = nil;
        };
    }
    else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        
        [self.activityVC setCompletionHandler:^(NSString *activityType, BOOL completed) {
            NSLog(@">>> Activity Type selected: %@", activityType);
            if (completed) {
                NSLog(@">>> Activity(%@) was performed.", activityType);
            } else {
                if (activityType == nil) {
                    NSLog(@">>> User dismissed the view controller without making a selection.");
                } else {
                    NSLog(@">>> Activity(%@) was not performed.", activityType);
                }
            }
            
            for (AssetActivityProvider *provider in items) {
                [provider cleanup];
            }
            [DLProgressHud dismiss];
        }];
#pragma clang diagnostic pop
    }
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
        if (DLiOS_8_OR_LATER) {
            self.activityVC.popoverPresentationController.barButtonItem = sender;
            [self presentViewController:self.activityVC animated:YES completion:^{
                self.activityVC.excludedActivityTypes = nil;
                self.activityVC = nil;
            }];
        }else{
            if ([self.popoverController isPopoverVisible]){
                [self.popoverController dismissPopoverAnimated:YES];
                self.popoverController = nil;
            }else{
                self.popoverController = [[UIPopoverController alloc]initWithContentViewController:self.activityVC];
                [self.popoverController presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
            }
        }
    }else{
        [self presentViewController:self.activityVC animated:YES completion:^{
            self.activityVC.excludedActivityTypes = nil;
            self.activityVC = nil;
        }];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^(void){
        [DLProgressHud showActivity];
    });
}

- (void)photoDeleteAction:(UIBarButtonItem *)sender{
    [[DLPhotoManager sharedInstance] removeAsset:self.selectedAssets completion:^(BOOL success) {
        [self cancelEditAction:nil];
    } failure:^(NSError *error) {
        NSLog(@">>> %@",error);
    }];
}

#pragma mark - Update status
- (void)updateToolBarStatus
{
    NSInteger selectedCount = self.selectedAssets.count;
    NSInteger numberOfAsset = self.assets.count;
    
    //
    if (numberOfAsset == 0) {
        self.selectButton.enabled = NO;
    }
    else if (selectedCount == numberOfAsset) {
        self.selectButton.title = DLPhotoPickerLocalizedString(@"Deselect All", nil);
    }else{
        self.selectButton.title = DLPhotoPickerLocalizedString(@"Select All", nil);
    }
    
    //
    if (self.picker.pickerType == DLPhotoPickerTypeDisplay) {
        for (UITabBarItem *item in self.toolbarItems) {
            item.enabled = selectedCount > 0;
        }
    }else if (self.picker.pickerType == DLPhotoPickerTypePicker){
        self.confirmButton.enabled = selectedCount > 0;
    }else{
    }
}

- (void)updateNavigationTitle
{
    if (self.isEditing) {
        if (self.selectedAssets.count > 0) {
            self.title = [self selectedAssetsString];
        }else {
            self.title = DLPhotoPickerLocalizedString(@"Select Item", nil);
        }
    }else{
        self.title = self.photoCollection.title;
    }
}

- (NSString *)selectedAssetsString
{
    if (self.selectedAssets.count == 0) return nil;
    
    NSPredicate *photoPredicate = [self predicateOfMediaType:DLPhotoMediaTypeImage];
    NSPredicate *videoPredicate = [self predicateOfMediaType:DLPhotoMediaTypeVideo];
    
    BOOL photoSelected = ([self.selectedAssets filteredArrayUsingPredicate:photoPredicate].count > 0);
    BOOL videoSelected = ([self.selectedAssets filteredArrayUsingPredicate:videoPredicate].count > 0);
    
    NSString *format;
    
    if (photoSelected && videoSelected){
        format = DLPhotoPickerLocalizedString(@"%@ Items Selected", nil);
    }else if (photoSelected){
        format = (self.selectedAssets.count > 1) ?
        DLPhotoPickerLocalizedString(@"%@ Photos Selected", nil) :
        DLPhotoPickerLocalizedString(@"%@ Photo Selected", nil);
    }else if (videoSelected){
        format = (self.selectedAssets.count > 1) ?
        DLPhotoPickerLocalizedString(@"%@ Videos Selected", nil) :
        DLPhotoPickerLocalizedString(@"%@ Video Selected", nil);
    }
    
    NSNumberFormatter *nf = [NSNumberFormatter new];
    return [NSString stringWithFormat:format, [nf assetStringFromAssetCount:self.selectedAssets.count]];
}

- (NSPredicate *)predicateOfMediaType:(DLPhotoMediaType)type
{
    return [NSPredicate predicateWithBlock:^BOOL(DLPhotoAsset *asset, NSDictionary *bindings) {
        return (asset.mediaType == type);
    }];
}

- (void)setAssetSelected:(BOOL)selected
{
    [self.picker removeAllSelectedAssets];
    
    for (DLPhotoAsset *asset in self.assets) {
        if (selected) {
            [self.picker selectAsset:asset];
        }
    }
}

#pragma mark - Scroll view selected assets changed
- (void)photoPickerSelectedAssetsDidChange:(NSNotification *)notification
{
    //NSArray *selectedAssets = (NSArray *)notification.object;
    [self updateToolBarStatus];
    [self updateNavigationTitle];
}

- (void)photoPickerEnterEditMode:(NSNotification *)notification
{
    //Select mode
    if (!self.isEditing) {
        [self setEditing:YES];
    }
}

- (void)photoPickerExitEditMode:(NSNotification *)notification
{
    //Select mode
    if (self.isEditing) {
        [self setEditing:NO];
    }
}

#pragma mark - No assets
- (void)showNoAssets
{
    DLPhotoPickerNoAssetsView *view = [DLPhotoPickerNoAssetsView new];
    [self.view addSubview:view];
    [view setNeedsUpdateConstraints];
    [view updateConstraintsIfNeeded];
    
    self.noAssetsView = view;
}

- (void)hideNoAssets
{
    if (self.noAssetsView)
    {
        [self.noAssetsView removeFromSuperview];
        self.noAssetsView = nil;
    }
}

#pragma mark - CollectionView DataSource Methods
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.assets.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    DLPhotoCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:DLPhotoCollectionViewCellIdentifier forIndexPath:indexPath];

    DLPhotoAsset *asset = [self assetAtIndexPath:indexPath];
    if (asset == nil) {
        return cell;
    }
    
    //  object maybe different in selectedAssets, but they are same asset.
    BOOL isSelected = [self.selectedAssets containsObject:asset];
    
    if (self.isEditing) {
        [cell setShowCheckMark:YES];
        [cell setSelected:isSelected];
        
        if (isSelected) {
            [self.collectionView selectItemAtIndexPath:indexPath
                                              animated:NO
                                        scrollPosition:UICollectionViewScrollPositionNone];
        }else{
            [self.collectionView deselectItemAtIndexPath:indexPath animated:NO];
        }
    }else{
        [cell setShowCheckMark:NO];
    }
    
    if ([self.picker.delegate respondsToSelector:@selector(pickerController:shouldEnableAsset:)])
        cell.enabled = [self.picker.delegate pickerController:self.picker shouldEnableAsset:asset];
    else
        cell.enabled = YES;
    
    [cell bind:asset];
    
    NSInteger tag = cell.tag + 1;
    cell.tag = tag;
    UICollectionViewLayoutAttributes *attributes = [collectionView.collectionViewLayout layoutAttributesForItemAtIndexPath:indexPath];
    
    [asset requestThumbnailImageWithSize:attributes.size completion:^(UIImage *image, NSDictionary *info) {
        if (cell.tag == tag){
            [(DLPhotoThumbnailView *)cell.backgroundView bind:image asset:asset];
        }
    }];
    
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    DLPhotoCollectionViewFooter *footer =
    [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter
                                       withReuseIdentifier:DLPhotoCollectionViewFooterIdentifier
                                              forIndexPath:indexPath];
    [footer bind:self.photoCollection];
    
    self.footer = footer;
    
    return footer;
}

#pragma mark - CollectionView Delegate Methods

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    DLPhotoAsset *asset = [self assetAtIndexPath:indexPath];
    
    if (self.isEditing) {
        [self.picker selectAsset:asset];
        [self.collectionView reloadItemsAtIndexPaths:@[indexPath]];
        
        if ([self.picker.delegate respondsToSelector:@selector(pickerController:didSelectAsset:)]){
            [self.picker.delegate pickerController:self.picker didSelectAsset:asset];
        }
    }else{
        DLPhotoPageViewController *vc = [[DLPhotoPageViewController alloc] initWithAssets:self.assets];
        vc.allowsSelection          = YES;
        vc.pageIndex                = indexPath.row;
        vc.hidesBottomBarWhenPushed = YES;
        self.pageViewController     = vc;
        
        [self.navigationController pushViewController:vc animated:YES];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    DLPhotoAsset *asset = [self assetAtIndexPath:indexPath];
    
    if (self.isEditing) {
        [self.picker deselectAsset:asset];
        [self.collectionView reloadItemsAtIndexPaths:@[indexPath]];
        
        if ([self.picker.delegate respondsToSelector:@selector(pickerController:didDeselectAsset:)]){
            [self.picker.delegate pickerController:self.picker didDeselectAsset:asset];
        }
    }
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    DLPhotoAsset *asset = [self assetAtIndexPath:indexPath];
    DLPhotoCollectionViewCell *cell = (DLPhotoCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    
    if (!cell.isEnabled)
        return NO;
    else if ([self.picker.delegate respondsToSelector:@selector(pickerController:shouldSelectAsset:)])
        return [self.picker.delegate pickerController:self.picker shouldSelectAsset:asset];
    else
        return YES;
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    DLPhotoAsset *asset = [self assetAtIndexPath:indexPath];
    
    if ([self.picker.delegate respondsToSelector:@selector(pickerController:shouldDeselectAsset:)]){
        return [self.picker.delegate pickerController:self.picker shouldDeselectAsset:asset];
    }else{
        return YES;
    }
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath
{
    DLPhotoAsset *asset = [self assetAtIndexPath:indexPath];
    
    if ([self.picker.delegate respondsToSelector:@selector(pickerController:shouldHighlightAsset:)]){
        return [self.picker.delegate pickerController:self.picker shouldHighlightAsset:asset];
    }else{
        return YES;
    }
}

- (void)collectionView:(UICollectionView *)collectionView didHighlightItemAtIndexPath:(NSIndexPath *)indexPath
{
    DLPhotoAsset *asset = [self assetAtIndexPath:indexPath];
    
    if ([self.picker.delegate respondsToSelector:@selector(pickerController:didHighlightAsset:)]){
        [self.picker.delegate pickerController:self.picker didHighlightAsset:asset];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didUnhighlightItemAtIndexPath:(NSIndexPath *)indexPath
{
    DLPhotoAsset *asset = [self assetAtIndexPath:indexPath];
    
    if ([self.picker.delegate respondsToSelector:@selector(pickerController:didUnhighlightAsset:)]){
        [self.picker.delegate pickerController:self.picker didUnhighlightAsset:asset];
    }
}

@end
