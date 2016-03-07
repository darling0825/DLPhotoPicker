/*
 
 MIT License (MIT)
 
 Copyright (c) 2016 DarlingCoder
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 
 */

#import "DLPhotoPageViewController.h"
#import "DLPhotoPageView.h"
#import "DLPhotoItemViewController.h"
#import "DLPhotoScrollView.h"
#import "NSNumberFormatter+DLPhotoPicker.h"
#import "NSBundle+DLPhotoPicker.h"
#import "UIImage+DLPhotoPicker.h"
#import "DLPhotoPickerDefines.h"
#import "DLPhotoAsset.h"
#import "DLPhotoManager.h"
#import "DLPhotoBarButtonItem.h"
#import "DLPhotoPickerViewController.h"

@interface DLPhotoPageViewController ()
<UIPageViewControllerDataSource, UIPageViewControllerDelegate, PHPhotoLibraryChangeObserver, ALAssetsLibraryChangeObserver>

@property (nonatomic, assign, getter = isStatusBarHidden) BOOL statusBarHidden;

@property (nonatomic, strong) NSMutableArray *assets;
@property (nonatomic, strong) DLPhotoAsset *asset;

@property (nonatomic, strong) DLPhotoPageView *pageView;

@property (nonatomic, strong) UIBarButtonItem *playButton;
@property (nonatomic, strong) UIBarButtonItem *pauseButton;
@property (nonatomic, strong) UIBarButtonItem *actionButton;
//@property (nonatomic, strong) UIBarButtonItem *infoButton;
@property (nonatomic, strong) UIBarButtonItem *favoriteButton;
@property (nonatomic, strong) UIBarButtonItem *deleteButton;
@property (nonatomic, strong) DLPhotoBarButtonItem *selectionButton;

@end

@implementation DLPhotoPageViewController

- (instancetype)initWithAssets:(NSArray *)assets
{
    //初始化
    //transitionStyle:转换样式，有PageCurl和Scroll两种
    //navigationOrientation:导航方向，有Horizontal和Vertical两种
    //options: UIPageViewControllerOptionSpineLocationKey---书脊的位置
    //         UIPageViewControllerOptionInterPageSpacingKey---每页的间距
    self = [super initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll
                    navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal
                                  options:@{UIPageViewControllerOptionInterPageSpacingKey:@30.f}];
    
    if (self)
    {
        self.assets          = [NSMutableArray arrayWithArray:assets];
        self.dataSource      = self;
        self.delegate        = self;
        self.allowsSelection = YES;
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupViews];
    [self setupButtons];
    [self registerChangeObserver];
    [self addNotificationObserver];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.navigationController setToolbarHidden:NO animated:YES];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.navigationController setToolbarHidden:YES animated:YES];
}

- (void)dealloc
{
    [self unregisterChangeObserver];
    [self removeNotificationObserver];
}

- (BOOL)prefersStatusBarHidden
{
    return self.isStatusBarHidden;
}


#pragma mark - Setup
- (void)setupViews
{
    self.pageView = [DLPhotoPageView new];
    [self.view insertSubview:self.pageView atIndex:0];
    [self.view setNeedsUpdateConstraints];
}

- (void)setupButtons
{
    DLPhotoBarButtonItem *selectionButton = [DLPhotoBarButtonItem buttonWithType:UIButtonTypeCustom];
    selectionButton.frame = CGRectMake(0, 0, 44.0, 44.0);
    selectionButton.isLeftButton = NO;
    UIImage *checkmarkImage = [UIImage assetImageNamed:@"SelectButtonChecked"];
    UIImage *uncheckmarkImage = [UIImage assetImageNamed:@"SelectButtonUnchecked"];
    [selectionButton setImage:uncheckmarkImage forState:UIControlStateNormal];
    [selectionButton setImage:checkmarkImage forState:UIControlStateSelected];
    [selectionButton addTarget:self action:@selector(selectionButtonTouchDown:) forControlEvents:UIControlEventTouchDown];
    [selectionButton addTarget:self action:@selector(selectionButtonTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];
    _selectionButton = selectionButton;
    
    UIBarButtonItem *checkButton = [[UIBarButtonItem alloc] initWithCustomView:selectionButton];
    self.navigationItem.rightBarButtonItem = checkButton;
}

- (void)selectionButtonTouchDown:(id)sender
{
    DLPhotoAsset *asset = self.asset;
    
    if ([self pageViewController:self shouldHighlightAsset:asset]){
        [self pageViewController:self didHighlightAsset:asset];
    }
}

- (void)selectionButtonTouchUpInside:(id)sender
{
    DLPhotoAsset *asset = self.asset;
    
    if (!self.selectionButton.selected){
        if ([self pageViewController:self shouldSelectAsset:asset]){
            [self.picker selectAsset:asset];
            [self.selectionButton setSelected:YES];
            [self pageViewController:self didSelectAsset:asset];
            [self postEnterEditModeNotification:asset];
        }
        
    }else{
        if ([self pageViewController:self shouldDeselectAsset:asset]){
            [self.picker deselectAsset:asset];
            [self.selectionButton setSelected:NO];
            [self pageViewController:self didDeselectAsset:asset];
            [self postExitEditModeNotification:asset];
        }
    }
    
    [self pageViewController:self didUnhighlightAsset:self.asset];
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
        // Check if there are changes to the asset we're displaying.
        PHObjectChangeDetails *changeDetails = [changeInstance changeDetailsForObject:self.asset.phAsset];
        if (changeDetails == nil) {
            return;
        }
        
        // back to collection view
        if (changeDetails.objectWasDeleted) {
            [self.navigationController popViewControllerAnimated:YES];
            return;
        }
        
        // Get the updated asset.
        PHAsset *phAsset = [changeDetails objectAfterChanges];
        if (phAsset) {
            DLPhotoAsset *newAsset = [[DLPhotoAsset alloc] initWithAsset:phAsset];
            NSUInteger index = [self.assets indexOfObject:self.asset];
            [self.assets replaceObjectAtIndex:index withObject:newAsset];
            self.asset = newAsset;
        }
        
        // If the asset's content changed, update the image and stop any video playback.
        if ([changeDetails assetContentChanged]) {

        }
        
        //  update toolbar
        [self updateToolbar];
    });
}

#pragma mark - Update title
- (void)updateTitle:(NSInteger)index
{
    NSNumberFormatter *nf = [NSNumberFormatter new];

    NSInteger count = self.assets.count;
    self.title      = [NSString stringWithFormat:DLPhotoPickerLocalizedString(@"%@ of %@", nil),
                       [nf assetStringFromAssetCount:index],
                       [nf assetStringFromAssetCount:count]];
}

#pragma mark - Update toolbar/navigationbat
- (void)updateNavigationBarItem
{
    BOOL isSelected = [self.picker isSelectedForAsset:self.asset];
    [self.selectionButton setSelected:isSelected];
}

- (void)updateToolbar
{
    if (!self.playButton){
        UIImage *playImage = [UIImage assetImageNamed:@"PlayButton"];
        playImage = [playImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        
        self.playButton =
        [[UIBarButtonItem alloc] initWithImage:playImage style:UIBarButtonItemStyleDone target:self action:@selector(playAsset:)];
    }
    
    if (!self.pauseButton){
        UIImage *pasueImage = [UIImage assetImageNamed:@"PauseButton"];
        pasueImage = [pasueImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        
        self.pauseButton =
        [[UIBarButtonItem alloc] initWithImage:pasueImage style:UIBarButtonItemStylePlain target:self action:@selector(pauseAsset:)];
    }
    
    if (!self.actionButton) {
        self.actionButton =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(photoShareAction:)];
    }
    
    self.favoriteButton = [self createFavoriteButton];
    
//    if (!self.infoButton) {
//        UIImage *infoImage = [UIImage assetImageNamed:@"Info"];
//        infoImage = [infoImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
//        self.infoButton =
//        [[UIBarButtonItem alloc] initWithImage:infoImage style:UIBarButtonItemStylePlain target:self action:@selector(photoInfoAction:)];
//    }
    
    if (!self.deleteButton) {
        self.deleteButton =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(photoDeleteAction:)];
    }   
    
    UIBarButtonItem *space = [self toolbarSpace];
//    if(self.asset.editable){
//        self.toolbarItems = @[self.actionButton, space, self.infoButton, space, self.favoriteButton, space, self.deleteButton];
//    }else{
//        self.toolbarItems = @[self.actionButton, space, self.infoButton, space, self.deleteButton];
//    }
    
    if(self.asset.editable){
        self.toolbarItems = @[self.actionButton, space, self.favoriteButton, space, self.deleteButton];
    }else{
        self.toolbarItems = @[self.actionButton, space, self.deleteButton];
    }
}

- (void)replaceToolbarButton:(UIBarButtonItem *)button
{
    if (button)
    {
        UIBarButtonItem *space = [self toolbarSpace];
        self.toolbarItems = @[space, button, space];
    }
}

- (UIBarButtonItem *)toolbarSpace
{
    return [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
}

- (UIBarButtonItem *)createFavoriteButton
{
    UIBarButtonItem *favoriteButton = nil;
    if (self.asset.phAsset.favorite) {
        favoriteButton = [[UIBarButtonItem alloc] initWithImage:[UIImage assetImageNamed:@"favorite"]
                                                          style:UIBarButtonItemStylePlain
                                                         target:self
                                                         action:@selector(photoFavoriteAction:)];
    }else{
        favoriteButton = [[UIBarButtonItem alloc] initWithImage:[UIImage assetImageNamed:@"favoriteoutline"]
                                                          style:UIBarButtonItemStylePlain
                                                         target:self
                                                         action:@selector(photoFavoriteAction:)];
    }
    return favoriteButton;
}

#pragma mark - Button Action
- (void)photoShareAction:(UIBarButtonItem *)sender
{
    UIImage *image = self.asset.originImage;

    UIActivityViewController *activityVC =
    [[UIActivityViewController alloc] initWithActivityItems:@[image] applicationActivities:nil];
    
    [self presentViewController:activityVC animated:YES completion:nil];
}

- (void)photoInfoAction:(UIBarButtonItem *)sender
{
    
}

- (void)photoFavoriteAction:(UIBarButtonItem *)sender
{
    if (self.asset.editable) {
        [[DLPhotoManager sharedInstance] favoriteAsset:self.asset completion:^(BOOL success, NSError *error) {
            /**
             *  Use photoLibraryDidChange: instead
            if (success) {
                [self updateToolbar];
            }
             */
        }];
    }
}

- (void)photoDeleteAction:(UIBarButtonItem *)sender
{
    [[DLPhotoManager sharedInstance] removeAsset:@[self.asset] completion:^(BOOL success) {
        /*
         *  Use photoLibraryDidChange: instead
        if (success) {
            [self.navigationController popViewControllerAnimated:YES];
        }
         */
    } failure:^(NSError *error) {
        NSLog(@">>> %@",error);
    }];
}

#pragma mark - Accessors
- (NSInteger)pageIndex
{
    return [self.assets indexOfObject:self.asset];
}

- (void)setPageIndex:(NSInteger)pageIndex
{
    NSInteger count = self.assets.count;
    
    if (pageIndex >= 0 && pageIndex < count){
        
        self.asset = [self.assets objectAtIndex:pageIndex];
        
        DLPhotoItemViewController *page = [DLPhotoItemViewController assetItemViewControllerForAsset:self.asset];
        page.allowsSelection = self.allowsSelection;
        
        [self setViewControllers:@[page]
                       direction:UIPageViewControllerNavigationDirectionForward
                        animated:NO
                      completion:NULL];
        
        [self updateTitle:pageIndex + 1];
        [self updateToolbar];
    }
}

#pragma mark -
/**
- (DLPhotoAsset *)asset
{
    return ((DLPhotoItemViewController *)self.viewControllers[0]).asset;
}

- (DLPhotoItemViewController *)itemViewController
{
    return (DLPhotoItemViewController *)self.viewControllers[0];
}
*/

- (DLPhotoItemViewController *)viewControllerAtIndex:(NSUInteger)index
{
    // Return the data view controller for the given index.
    if (([self.assets count] == 0) || (index >= [self.assets count])) {
        return nil;
    }
    
    // Create a new view controller and pass suitable data.
    DLPhotoItemViewController *itemViewController =
    [DLPhotoItemViewController assetItemViewControllerForAsset:[self.assets objectAtIndex:index]];
    itemViewController.allowsSelection = self.allowsSelection;
    
    return itemViewController;
}

- (NSUInteger)indexOfViewController:(DLPhotoItemViewController *)viewController
{
    return [self.assets indexOfObject:viewController.asset];
}

#pragma mark - Page view controller data source
- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    DLPhotoAsset *asset = ((DLPhotoItemViewController *)viewController).asset;
    NSInteger index = [self.assets indexOfObject:asset];
    return [self viewControllerAtIndex:index - 1];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    DLPhotoAsset *asset = ((DLPhotoItemViewController *)viewController).asset;
    NSInteger index = [self.assets indexOfObject:asset];
    return [self viewControllerAtIndex:index + 1];
}

/**
- (NSInteger)presentationCountForPageViewController:(UIPageViewController *)pageViewController
{
    return [self.assets count];
}

- (NSInteger)presentationIndexForPageViewController:(UIPageViewController *)pageViewController
{
    return 0;
}
*/

#pragma mark - Page view controller delegate

- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed
{
    if (completed)
    {
        DLPhotoItemViewController *vc = (DLPhotoItemViewController *)pageViewController.viewControllers[0];
        
        /**
         *  Fix bug
         *  vc.asset maybe changed, we must get the new object. If not, the asset status will wrong.
         */
        DLPhotoAsset *oldAsset = vc.asset;
        NSInteger index = [self.assets indexOfObject:oldAsset]; //isEqual
        DLPhotoAsset *newAsset = [self.assets objectAtIndex:index];
        
        self.asset = newAsset;
        
        [self updateTitle:index + 1];
        [self updateToolbar];
        [self updateNavigationBarItem];
    }
}

- (void)pageViewController:(UIPageViewController *)pageViewController willTransitionToViewControllers:(NSArray *)pendingViewControllers
{
    //[self.navigationController setToolbarHidden:NO animated:YES];
}

/**
- (UIPageViewControllerSpineLocation)pageViewController:(UIPageViewController *)pageViewController spineLocationForInterfaceOrientation:(UIInterfaceOrientation)orientation
{
    return UIPageViewControllerSpineLocationMax;
}

- (UIInterfaceOrientationMask)pageViewControllerSupportedInterfaceOrientations:(UIPageViewController *)pageViewController
{
    return UIInterfaceOrientationMaskAllButUpsideDown;
}

- (UIInterfaceOrientation)pageViewControllerPreferredInterfaceOrientationForPresentation:(UIPageViewController *)pageViewController
{
    return UIInterfaceOrientationLandscapeLeft;
}
*/

#pragma mark - Notification observer

- (void)addNotificationObserver
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    
    [center addObserver:self
               selector:@selector(assetScrollViewDidTap:)
                   name:DLPhotoScrollViewDidTapNotification
                 object:nil];
    
    [center addObserver:self
               selector:@selector(assetScrollViewPlayerDidPlayToEnd:)
                   name:AVPlayerItemDidPlayToEndTimeNotification
                 object:nil];    
    
    [center addObserver:self
               selector:@selector(assetScrollViewPlayerWillPlay:)
                   name:DLPhotoScrollViewPlayerWillPlayNotification
                 object:nil];
    
    [center addObserver:self
               selector:@selector(assetScrollViewPlayerWillPause:)
                   name:DLPhotoScrollViewPlayerWillPauseNotification
                 object:nil];
    
    [center addObserver:self
               selector:@selector(assetScrollViewDidZoom:)
                   name:DLPhotoScrollViewDidZoomNotification
                 object:nil];
}

- (void)removeNotificationObserver
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    
    [center removeObserver:self name:DLPhotoScrollViewDidTapNotification object:nil];
    [center removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    [center removeObserver:self name:DLPhotoScrollViewPlayerWillPlayNotification object:nil];
    [center removeObserver:self name:DLPhotoScrollViewPlayerWillPauseNotification object:nil];
    [center removeObserver:self name:DLPhotoScrollViewDidZoomNotification object:nil];
}


#pragma mark - Notification events

- (void)assetScrollViewDidTap:(NSNotification *)notification
{
    UITapGestureRecognizer *gesture = (UITapGestureRecognizer *)notification.object;
    
    if (gesture.numberOfTapsRequired == 1){
        [self toggleFullscreen:gesture];
    }
}

- (void)assetScrollViewPlayerDidPlayToEnd:(NSNotification *)notification
{
//     self.toolbarItems = @[self.actionButton, self.toolbarSpace, self.infoButton, self.toolbarSpace, self.favoriteButton, self.toolbarSpace, self.deleteButton];
    self.toolbarItems = @[self.actionButton, self.toolbarSpace, self.favoriteButton, self.toolbarSpace, self.deleteButton];
    [self setFullscreen:NO];
}

- (void)assetScrollViewPlayerWillPlay:(NSNotification *)notification
{
    [self replaceToolbarButton:self.pauseButton];
    [self setFullscreen:YES];
}

- (void)assetScrollViewPlayerWillPause:(NSNotification *)notification
{
    [self replaceToolbarButton:self.playButton];
}

- (void)assetScrollViewDidZoom:(NSNotification *)notification
{
    [self setFullscreen:YES];
}


#pragma mark - Toggle fullscreen

- (void)toggleFullscreen:(id)sender
{
    [self setFullscreen:!self.isStatusBarHidden];
}

- (void)setFullscreen:(BOOL)fullscreen
{
    if (fullscreen)
    {
        [self.pageView enterFullscreen];
        [self fadeAwayControls:self.navigationController];
    }
    else
    {
        [self.pageView exitFullscreen];
        [self fadeInControls:self.navigationController];
    }
    
}

- (void)fadeInControls:(UINavigationController *)nav
{
    self.statusBarHidden = NO;
    
    [nav setNavigationBarHidden:NO animated:YES];
    [nav setToolbarHidden:NO animated:YES];
    [nav.navigationBar setAlpha:0.0f];
    [nav.toolbar setAlpha:0.0f];
    
    
    [UIView animateWithDuration:0.2
                     animations:^{
                         [self setNeedsStatusBarAppearanceUpdate];
                         [nav.navigationBar setAlpha:1.0f];
                         
                         [nav.toolbar setAlpha:1.0f];
                     }];
}

- (void)fadeAwayControls:(UINavigationController *)nav
{
    self.statusBarHidden = YES;
    
    [UIView animateWithDuration:0.2
                     animations:^{
                         [self setNeedsStatusBarAppearanceUpdate];
                         
                         [nav setNavigationBarHidden:YES animated:NO];
                         [nav setToolbarHidden:YES animated:YES];
                         [nav.navigationBar setAlpha:0.0f];
                         [nav.toolbar setAlpha:0.0f];
                     }];
}


#pragma mark - Playback

- (void)playAsset:(id)sender
{
    [((DLPhotoItemViewController *)self.viewControllers[0]) playAsset:sender];
}

- (void)pauseAsset:(id)sender
{
    [((DLPhotoItemViewController *)self.viewControllers[0]) pauseAsset:sender];
}


#pragma mark - Post notifications
- (void)postEnterEditModeNotification:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:DLPhotoPickerDidEnterEditModeNotification
                                                        object:sender];
}

- (void)postExitEditModeNotification:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:DLPhotoPickerDidExitEditModeNotification
                                                        object:sender];
}

#pragma mark - Asset scrollView delegate

- (BOOL)pageViewController:(DLPhotoPageViewController *)pageViewController shouldEnableAsset:(DLPhotoAsset *)asset
{
    if ([self.picker.delegate respondsToSelector:@selector(pickerController:shouldEnableAsset:)])
        return [self.picker.delegate pickerController:self.picker shouldEnableAsset:asset];
    else
        return YES;
}

- (BOOL)pageViewController:(DLPhotoPageViewController *)pageViewController shouldSelectAsset:(DLPhotoAsset *)asset
{
    if ([self.picker.delegate respondsToSelector:@selector(pickerController:shouldSelectAsset:)])
        return [self.picker.delegate pickerController:self.picker shouldSelectAsset:asset];
    else
        return YES;
}

- (void)pageViewController:(DLPhotoPageViewController *)pageViewController didSelectAsset:(DLPhotoAsset *)asset
{
    if ([self.picker.delegate respondsToSelector:@selector(pickerController:didSelectAsset:)])
        [self.picker.delegate pickerController:self.picker didSelectAsset:asset];
}

- (BOOL)pageViewController:(DLPhotoPageViewController *)pageViewController shouldDeselectAsset:(DLPhotoAsset *)asset
{
    if ([self.picker.delegate respondsToSelector:@selector(pickerController:shouldDeselectAsset:)])
        return [self.picker.delegate pickerController:self.picker shouldDeselectAsset:asset];
    else
        return YES;
}

- (void)pageViewController:(DLPhotoPageViewController *)pageViewController didDeselectAsset:(DLPhotoAsset *)asset
{
    if ([self.picker.delegate respondsToSelector:@selector(pickerController:didDeselectAsset:)])
        [self.picker.delegate pickerController:self.picker didDeselectAsset:asset];
}

- (BOOL)pageViewController:(DLPhotoPageViewController *)pageViewController shouldHighlightAsset:(DLPhotoAsset *)asset
{
    if ([self.picker.delegate respondsToSelector:@selector(pickerController:shouldHighlightAsset:)])
        return [self.picker.delegate pickerController:self.picker shouldHighlightAsset:asset];
    else
        return YES;
}

- (void)pageViewController:(DLPhotoPageViewController *)pageViewController didHighlightAsset:(DLPhotoAsset *)asset
{
    if ([self.picker.delegate respondsToSelector:@selector(pickerController:didHighlightAsset:)])
        [self.picker.delegate pickerController:self.picker didHighlightAsset:asset];
}

- (void)pageViewController:(DLPhotoPageViewController *)pageViewController didUnhighlightAsset:(DLPhotoAsset *)asset
{
    if ([self.picker.delegate respondsToSelector:@selector(pickerController:didUnhighlightAsset:)])
        [self.picker.delegate pickerController:self.picker didUnhighlightAsset:asset];
}

@end
