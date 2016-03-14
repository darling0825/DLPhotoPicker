//
//  DLPhotoPickerViewController.m
//  DLPhotoPicker
//
//  Created by 沧海无际 on 16/2/20.
//  Copyright © 2016年 darling0825. All rights reserved.
//

#import <objc/runtime.h>
#import "DLPhotoPickerViewController.h"
#import "DLPhotoPickerDefines.h"
#import "DLPhotoManager.h"
#import "DLPhotoPickerAccessDeniedView.h"
#import "DLPhotoPickerNoAssetsView.h"
#import "DLPhotoTableViewController.h"
#import "NSBundle+DLPhotoPicker.h"

NSString * const DLPhotoPickerSelectedAssetsDidChangeNotification = @"DLPhotoPickerSelectedAssetsDidChangeNotification";

@interface DLPhotoPickerViewController ()
@end

@implementation DLPhotoPickerViewController
@synthesize delegate;

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setupInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setupInit];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = DLPhotoWhiteBackgroundColor;
    
    [self setupDefaults];
    [self addKeyValueObserver];
    [self checkAuthorizationStatus];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)dealloc
{
    [self removeKeyValueObserver];
}

- (void)setupInit
{
    _showsNumberOfAssets                    = YES;
    _showsCancelButton                      = YES;
    _hidesBottomBarWhenPushedInAssetView    = YES;
    _selectedAssets                         = [@[] mutableCopy];
    _maxNumberOfSelectedToShare             = 30;
}

- (void)setupDefaults
{
    DLPhotoManager *photoManager = [DLPhotoManager sharedInstance];
    if (self.assetCollectionSubtypes) {
        photoManager.assetCollectionSubtypes = self.assetCollectionSubtypes;
    }
    
    if (self.assetCollectionFetchOptions) {
        photoManager.assetCollectionFetchOptions = self.assetCollectionFetchOptions;
    }
    
    if (self.assetsFetchOptions) {
        photoManager.assetsFetchOptions = self.assetsFetchOptions;
    }
    
    if (self.thumbnailRequestOptions) {
        photoManager.thumbnailRequestOptions = self.thumbnailRequestOptions;
    }
}

- (void)checkAuthorizationStatus
{
    [[DLPhotoManager sharedInstance] checkAuthorizationStatus:^(DLAuthorizationStatus status) {
        switch (status) {
            case DLAuthorizationStatusSuccess:
                [self getAlbumsSuccess];
                break;
            case DLAuthorizationStatusAccessDenied:
                [self showAuxiliaryView:[DLPhotoPickerAccessDeniedView new]];
                break;
            case DLAuthorizationStatusNoAssets:
                [self showAuxiliaryView:[DLPhotoPickerNoAssetsView new]];
                break;
            default:
                break;
        }
    }];
}

#pragma mark - Post notifications
- (void)postSelectedAssetsDidChangeNotification:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:DLPhotoPickerSelectedAssetsDidChangeNotification
                                                        object:sender];
}

#pragma mark - Add/Remove selectedAsset
- (BOOL)isSelectedForAsset:(DLPhotoAsset *)asset
{
    return [self.selectedAssets containsObject:asset];
}

- (void)selectAsset:(DLPhotoAsset *)asset
{
    [self insertObject:asset inSelectedAssetsAtIndex:self.selectedAssets.count];
    //[self postDidSelectAssetNotification:asset];
}

- (void)deselectAsset:(DLPhotoAsset *)asset
{
    [self removeObjectFromSelectedAssetsAtIndex:[self.selectedAssets indexOfObject:asset]];
    //[self postDidDeselectAssetNotification:asset];
}

- (void)removeAllSelectedAssets
{
    [self.selectedAssets removeAllObjects];
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
        [self postSelectedAssetsDidChangeNotification:[object valueForKey:keyPath]];
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

#pragma mark - DLPhotoManagerDelegate
- (void)getAlbumsSuccess
{
    DLPhotoTableViewController *albumTableViewController = [[DLPhotoTableViewController alloc] init];
    albumTableViewController.navigationItem.title = self.navigationTitle;;

    [self pushViewController:albumTableViewController animated:NO];

//    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:albumTableViewController];
//    [self addChildViewController:nav];
//    [nav.view setFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
//    [self.view addSubview:nav.view];
//    [nav didMoveToParentViewController:self];
}

#pragma mark - Show view
- (void)showAuxiliaryView:(UIView *)view
{
    [self removeChildViewController];
    
    UIViewController *vc = [self emptyViewController];
    if (self.showsCancelButton) {
        vc.navigationItem.rightBarButtonItem =
        [[UIBarButtonItem alloc] initWithTitle:DLPhotoPickerLocalizedString(@"Cancel", nil)
                                         style:UIBarButtonItemStylePlain
                                        target:self
                                        action:@selector(dismiss:)];
    }
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    
    [vc.view addSubview:view];
    [view setNeedsUpdateConstraints];
    [view updateConstraintsIfNeeded];
    
    [self setupChildViewController:nav];
}

- (void)dismiss:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(pickerControllerDidCancel:)]){
        [self.delegate pickerControllerDidCancel:self];
    }else{
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark - Setup view controllers
- (UIViewController *)emptyViewController
{
    UIViewController *vc                = [UIViewController new];
    vc.view.backgroundColor             = [UIColor whiteColor];
    vc.navigationItem.hidesBackButton   = YES;
    
    return vc;
}

- (void)setupChildViewController:(UIViewController *)vc
{
    [self addChildViewController:vc];
    [vc.view setFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    [self.view addSubview:vc.view];
    [vc didMoveToParentViewController:self];
}

- (void)removeChildViewController
{
    UIViewController *vc = self.childViewControllers.firstObject;
    [vc willMoveToParentViewController:nil];
    [vc.view removeFromSuperview];
    [vc removeFromParentViewController];
}
@end



@implementation UIViewController (DLPhotoPickerViewController)

- (DLPhotoPickerViewController *)picker
{
    DLPhotoPickerViewController *picker = nil;
    if ([self isKindOfClass:[DLPhotoPickerViewController class]]) {
        picker = (DLPhotoPickerViewController *)self;
    }
    
    if (!picker && self.parentViewController) {
        picker = [self.parentViewController picker];
    }
    return picker;
}

@end

