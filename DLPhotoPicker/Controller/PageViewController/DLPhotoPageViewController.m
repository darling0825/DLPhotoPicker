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
#import "NSBundle+DLPhotoPicker.h"
#import "UIImage+DLPhotoPicker.h"
#import "NSNumberFormatter+DLPhotoPicker.h"
#import "DLPhotoPickerDefines.h"
#import "DLPhotoAsset.h"
#import "DLPhotoManager.h"
#import "DLPhotoPickerViewController.h"
#import "MBProgressHUD.h"
#import "AssetActivityProvider.h"
#import "TOCropViewController.h"
#import "SVProgressHUD.h"


@interface DLPhotoPageViewController ()
<UIPageViewControllerDataSource, UIPageViewControllerDelegate, PHPhotoLibraryChangeObserver, ALAssetsLibraryChangeObserver, TOCropViewControllerDelegate>

@property (nonatomic, assign, getter = isStatusBarHidden) BOOL statusBarHidden;

@property (nonatomic, strong) NSMutableArray *assets;
@property (nonatomic, strong) DLPhotoAsset *asset;

@property (nonatomic, strong) DLPhotoPageView *pageView;
@property (nonatomic, strong) MBProgressHUD *progressHUD;

@property (nonatomic, strong) UIBarButtonItem *playButton;
@property (nonatomic, strong) UIBarButtonItem *pauseButton;
@property (nonatomic, strong) UIBarButtonItem *actionButton;
//@property (nonatomic, strong) UIBarButtonItem *infoButton;
@property (nonatomic, strong) UIBarButtonItem *favoriteButton;
@property (nonatomic, strong) UIBarButtonItem *deleteButton;
@property (nonatomic, strong) UIBarButtonItem *editButton;

@property (nonatomic, strong)PHContentEditingInput *contentEditingInput;

@property (nonatomic, strong) UIActivityViewController *activityVC;
@property (nonatomic, strong) UIPopoverController *popoverController;


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
        self.allowsSelection = NO;
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
    if (self.asset.mediaType == DLPhotoMediaTypeImage) {
        UIBarButtonItem *editButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(photoEditAction:)];
        self.navigationItem.rightBarButtonItem = editButton;
    }
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
            [[self itemViewController] assetDidChanded:self.asset];
        }
        
        //  update toolbar
        [self updateToolbar];
    });
}

- (void)assetsLibraryChanged:(NSNotification *)notification
{
    // do nothing
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
    AssetActivityProvider *assetProvider = [[AssetActivityProvider alloc] initWithAsset:self.asset];
    self.activityVC =
    [[UIActivityViewController alloc] initWithActivityItems:@[assetProvider] applicationActivities:nil];
    
    typeof(self) __weak weakSelf = self;
    if (DLiOS_8_OR_LATER) {
        self.activityVC.completionWithItemsHandler = ^(UIActivityType __nullable activityType, BOOL completed, NSArray * __nullable returnedItems, NSError * __nullable activityError){
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
            
            [assetProvider cleanup];
            [strongSelf hideProgressHUD:YES];
        };
    }
    else {
        [self.activityVC setCompletionHandler:^(NSString *activityType, BOOL completed) {
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
            
            [assetProvider cleanup];
            [strongSelf hideProgressHUD:YES];
        }];
    }
    
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
        if (DLiOS_8_OR_LATER) {
            self.activityVC.popoverPresentationController.barButtonItem = sender;
            [self presentViewController:self.activityVC animated:YES completion:^{
                self.activityVC.excludedActivityTypes = nil;
                self.activityVC = nil;}
             ];
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
            self.activityVC = nil;}
         ];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^(void){
        [self showProgressHUDWithMessage:nil];
    });
}

- (void)photoInfoAction:(UIBarButtonItem *)sender
{
    
}

- (void)photoEditAction:(UIBarButtonItem *)sender
{
    if (UsePhotoKit) {
        
        [[DLPhotoManager sharedInstance] requestContentEditing:self.asset completion:^(UIImage *image, PHContentEditingInput *contentEditingInput, NSDictionary *info) {
            
            if (image) {
                self.contentEditingInput = contentEditingInput;
                
                TOCropViewController *cropController = [[TOCropViewController alloc] initWithImage:image];
                cropController.delegate = self;
                
                // Uncomment this to test out locked aspect ratio sizes
                // cropController.defaultAspectRatio = TOCropViewControllerAspectRatioSquare;
                // cropController.aspectRatioLocked = YES;
                
                // Uncomment this to place the toolbar at the top of the view controller
                // cropController.toolbarPosition = TOCropViewControllerToolbarPositionTop;
                
                [self.navigationController presentViewController:cropController animated:YES completion:nil];
            }
        }];
        
    }else{
        UIImage *image = [self.asset originImage];
        TOCropViewController *cropController = [[TOCropViewController alloc] initWithImage:image];
        cropController.delegate = self;
        [self.navigationController presentViewController:cropController animated:YES completion:nil];
    }
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

- (DLPhotoItemViewController *)itemViewController
{
    return (DLPhotoItemViewController *)self.viewControllers[0];
}

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

#pragma mark - Cropper Delegate
- (void)cropViewController:(TOCropViewController *)cropViewController didCropToImage:(UIImage *)image withRect:(CGRect)cropRect angle:(NSInteger)angle
{
    
    CGRect viewFrame = [self.view convertRect:CGRectZero toView:self.navigationController.view];
    
    //  dismiss crop View
    [cropViewController dismissAnimatedFromParentViewController:self withCroppedImage:image toView:nil toFrame:viewFrame setup:nil completion:^{

        if (UsePhotoKit) {
            // Create a PHAdjustmentData object that describes the filter that was applied.
            NSData *data =
            [[NSString stringWithFormat:@"%@-%ld",NSStringFromCGRect(cropRect),(long)angle] dataUsingEncoding:NSUTF8StringEncoding];
            
            [[DLPhotoManager sharedInstance] saveContentEditing:self.asset
                                                          image:image
                                            contentEditingInput:self.contentEditingInput
                                          adjustmentDescription:data];
        }else{
            
            //  Saved to default album
            [[DLPhotoManager sharedInstance] saveImage:image toAlbum:nil completion:^(BOOL success) {
                
                [SVProgressHUD setBackgroundColor:[UIColor blackColor]];
                [SVProgressHUD setForegroundColor:[UIColor whiteColor]];
                [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeBlack];
                [SVProgressHUD showSuccessWithStatus:DLPhotoPickerLocalizedString(@"Saved to default album.",nil)];
                
                //  dismiss after 2 second
                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC);
                dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                    [SVProgressHUD dismiss];
                });
            } failure:^(NSError *error) {
                
            }];
        }
    }];
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
    
    [nav setNavigationBarHidden:YES animated:YES];
    [nav setToolbarHidden:YES animated:YES];
    
    [UIView animateWithDuration:0.2
                     animations:^{
                         [self setNeedsStatusBarAppearanceUpdate];
                         
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


#pragma mark - Action Progress

- (MBProgressHUD *)progressHUD {
    if (!_progressHUD) {
        _progressHUD = [[MBProgressHUD alloc] initWithView:self.view];
        _progressHUD.minSize = CGSizeMake(120, 120);
        _progressHUD.minShowTime = 1;
        [self.view addSubview:_progressHUD];
    }
    return _progressHUD;
}

- (void)showProgressHUDWithMessage:(NSString *)message {
    self.progressHUD.label.text = message;
    self.progressHUD.mode = MBProgressHUDModeIndeterminate;
    [self.progressHUD showAnimated:YES];
    self.navigationController.navigationBar.userInteractionEnabled = NO;
}

- (void)hideProgressHUD:(BOOL)animated {
    [self.progressHUD hideAnimated:animated];
    self.navigationController.navigationBar.userInteractionEnabled = YES;
}
@end
