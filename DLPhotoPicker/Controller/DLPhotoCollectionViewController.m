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
#import "NSNumberFormatter+DLPhotoPicker.h"

NSString * const DLPhotoCollectionViewCellIdentifier = @"DLPhotoCollectionViewCellIdentifier";
NSString * const DLPhotoCollectionViewFooterIdentifier = @"DLPhotoCollectionViewFooterIdentifier";


@interface DLPhotoCollectionViewController ()

@property (nonatomic, strong) NSArray *assets;

@property (nonatomic, strong) DLPhotoCollectionViewFooter *footer;
@property (nonatomic, strong) DLPhotoPickerNoAssetsView *noAssetsView;

@property (nonatomic, assign) CGRect previousBounds;
@property (nonatomic, assign) BOOL didLayoutSubviews;

@property (nonatomic, strong) UIBarButtonItem *selectButton;

@end

@implementation DLPhotoCollectionViewController

- (instancetype)init
{
    DLPhotoCollectionViewLayout *layout = [DLPhotoCollectionViewLayout new];
    
    if (self = [super initWithCollectionViewLayout:layout]){
        _selectedAssets = [@[] mutableCopy];
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupViews];
    [self updateNavigationTitle];
    [self createEditButton];
    [self addKeyValueObserver];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self setupAssets];
}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    [self removeKeyValueObserver];
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
}

#pragma mark
- (void)setupViews
{
    self.extendedLayoutIncludesOpaqueBars = YES;
    
    self.collectionView.backgroundColor = DLPhotoCollectionViewBackgroundColor;
    self.collectionView.allowsMultipleSelection = YES;
    
    [self.collectionView registerClass:DLPhotoCollectionViewCell.class
            forCellWithReuseIdentifier:DLPhotoCollectionViewCellIdentifier];
    
    [self.collectionView registerClass:DLPhotoCollectionViewFooter.class
            forSupplementaryViewOfKind:UICollectionElementKindSectionFooter
                   withReuseIdentifier:DLPhotoCollectionViewFooterIdentifier];
    
    DLPhotoBackgroundView *CollectionView = [DLPhotoBackgroundView new];
    [self.view insertSubview:CollectionView atIndex:0];
    [self.view setNeedsUpdateConstraints];
}

- (void)setupAssets
{
    self.assets = [[DLPhotoManager sharedInstance] assetsForPhotoCollection:self.photoCollection];
    
    [self reloadData];
}

- (DLPhotoAsset *)assetAtIndexPath:(NSIndexPath *)indexPath
{
    return (self.assets.count > 0) ? self.assets[indexPath.row] : nil;
}

#pragma mark - Collection view layout
- (void)updateCollectionViewLayout
{
    UITraitCollection *trait = self.traitCollection;
    CGSize contentSize = self.view.bounds.size;
    UICollectionViewLayout *layout = [[DLPhotoCollectionViewLayout alloc] initWithContentSize:contentSize traitCollection:trait];
    
    if ([self.picker.delegate respondsToSelector:@selector(pickerController:collectionViewLayoutForContentSize:traitCollection:)]) {
        layout = [self.picker.delegate pickerController:self.picker collectionViewLayoutForContentSize:contentSize traitCollection:trait];
    } else {
        layout = [[DLPhotoCollectionViewLayout alloc] initWithContentSize:contentSize traitCollection:trait];
    }
    
    __weak DLPhotoCollectionViewController *weakSelf = self;
    
    [self.collectionView setCollectionViewLayout:layout animated:NO completion:^(BOOL finished){
        [weakSelf.collectionView reloadItemsAtIndexPaths:[weakSelf.collectionView indexPathsForVisibleItems]];
    }];
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
    
    if (shouldScrollToBottom){
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
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(editAction)];
}

- (void)createSelectButton{
    _selectButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Select All",nil) style:UIBarButtonItemStylePlain target:self action:@selector(selectAction:)];
    self.navigationItem.leftBarButtonItem = _selectButton;
}

- (void)createCancelButton{
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelAction)];
}

- (void)createToolBar{
    UIBarButtonItem *leftSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    UIBarButtonItem *copyButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Copy to",nil) style:UIBarButtonItemStylePlain target:self action:@selector(copyAction:)];
    copyButton.enabled = NO;
    
    UIBarButtonItem *rightSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    self.toolbarItems = @[leftSpace,copyButton,rightSpace];
    [self setToolbarItems:self.toolbarItems animated:YES];
}

#pragma mark - Navigation Action
- (void)editAction{
    self.modifying = YES;
    [self createCancelButton];
    [self createSelectButton];
    
    //TabBar
//    [self.rdv_tabBarController setTabBarHidden:YES animated:YES];
    
    //ToolBar
    [self.navigationController setToolbarHidden:NO animated:YES];
    [self createToolBar];
    [self updateEditToolBarStatus];
    
    [self reloadData];
}

- (void)cancelAction{
    self.modifying = NO;
    
    // Unselect all
    [self setAssetSelected:NO];
    
    [self createEditButton];
    [self updateNavigationTitle];
    
    self.navigationItem.leftBarButtonItem = nil;
    
    //TabBar
//    [self.rdv_tabBarController setTabBarHidden:NO animated:YES];
    
    //ToolBar
    [self.navigationController setToolbarHidden:YES animated:YES];
    
    [self reloadData];
}

- (void)selectAction:(UIBarButtonItem *)sender{
    NSInteger selectedCount = self.selectedAssets.count;
    NSInteger numberOfAsset = self.assets.count;
    if (selectedCount == numberOfAsset) {
        [self setAssetSelected: NO];
    }else{
        [self setAssetSelected: YES];
    }
    
    [self updateEditToolBarStatus];
    [self updateNavigationTitle];
    
    [self reloadData];
}

- (void)copyAction:(UIBarButtonItem *)sender{

}

- (void)updateEditToolBarStatus
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
    self.toolbarItems[1].enabled = selectedCount > 0;
    [self setToolbarItems:self.toolbarItems animated:YES];
}

- (void)updateNavigationTitle
{
    if (self.selectedAssets.count > 0) {
        self.title = [self selectedAssetsString];
    }else {
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
    
    if (photoSelected && videoSelected)
        format = DLPhotoPickerLocalizedString(@"%@ Items Selected", nil);
    
    else if (photoSelected)
        format = (self.selectedAssets.count > 1) ?
        DLPhotoPickerLocalizedString(@"%@ Photos Selected", nil) :
        DLPhotoPickerLocalizedString(@"%@ Photo Selected", nil);
    
    else if (videoSelected)
        format = (self.selectedAssets.count > 1) ?
        DLPhotoPickerLocalizedString(@"%@ Videos Selected", nil) :
        DLPhotoPickerLocalizedString(@"%@ Video Selected", nil);
    
    NSNumberFormatter *nf = [NSNumberFormatter new];
    
    return [NSString stringWithFormat:format, [nf ctassetsPickerStringFromAssetsCount:self.selectedAssets.count]];
}

- (NSPredicate *)predicateOfMediaType:(DLPhotoMediaType)type
{
    return [NSPredicate predicateWithBlock:^BOOL(DLPhotoAsset *asset, NSDictionary *bindings) {
        return (asset.mediaType == type);
    }];
}

- (void)setAssetSelected:(BOOL)selectAll
{
    [self.selectedAssets removeAllObjects];
    
    if (selectAll) {
        for (DLPhotoAsset *asset in self.assets) {
            [self.selectedAssets addObject:asset];
        }
    }
}

#pragma mark - Add/Remove selectedAsset
- (void)selectAsset:(DLPhotoAsset *)asset
{
    [self insertObject:asset inSelectedAssetsAtIndex:self.selectedAssets.count];
}

- (void)deselectAsset:(DLPhotoAsset *)asset
{
    [self removeObjectFromSelectedAssetsAtIndex:[self.selectedAssets indexOfObject:asset]];
}

#pragma mark - Key-Value observer
- (void)addKeyValueObserver
{
    [self addObserver:self
           forKeyPath:@"selectedAssets"
              options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
              context:nil];
}

- (void)removeKeyValueObserver
{
    @try {
        [self removeObserver:self forKeyPath:@"selectedAssets"];
    }
    @catch (NSException *exception) {
        // do nothing
    }
}

#pragma mark - Key-Value changed
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqual:@"selectedAssets"]){
        [self updateEditToolBarStatus];
        [self updateNavigationTitle];
    }
}

#pragma mark - KVO Implementation For NSArray
- (void)insertObject:(id)object inSelectedAssetsAtIndex:(NSUInteger)index
{
    [self.selectedAssets insertObject:object atIndex:index];
}

- (void)removeObjectFromSelectedAssetsAtIndex:(NSUInteger)index
{
    [self.selectedAssets removeObjectAtIndex:index];
}

- (void)replaceObjectInSelectedAssetsAtIndex:(NSUInteger)index withObject:(DLPhotoAsset *)object
{
    [self.selectedAssets replaceObjectAtIndex:index withObject:object];
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
    
    BOOL isSelected = [self.selectedAssets containsObject:asset];
    
    if (self.isModifying) {
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
    [[DLPhotoManager sharedInstance] requestThumbnailsForPhotoAsset:asset containerSize:attributes.size completion:^(UIImage *thumbnailImage) {
        if (cell.tag == tag){
            [(DLPhotoThumbnailView *)cell.backgroundView bind:thumbnailImage asset:asset];
        }
    }];
    
    return cell;
}

- (CGSize)imageSizeForContainerSize:(CGSize)size
{
    CGFloat scale = UIScreen.mainScreen.scale;
    return CGSizeMake(size.width * scale, size.height * scale);
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
    
    if (self.isModifying) {
        [self selectAsset:asset];
        [self.collectionView reloadItemsAtIndexPaths:@[indexPath]];
    }
    
    if ([self.picker.delegate respondsToSelector:@selector(pickerController:didSelectAsset:)]){
        [self.picker.delegate pickerController:self.picker didSelectAsset:asset];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    DLPhotoAsset *asset = [self assetAtIndexPath:indexPath];
    
    if (self.isModifying) {
        [self deselectAsset:asset];
        [self.collectionView reloadItemsAtIndexPaths:@[indexPath]];
    }
    
    if ([self.picker.delegate respondsToSelector:@selector(pickerController:didDeselectAsset:)]){
        [self.picker.delegate pickerController:self.picker didDeselectAsset:asset];
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
