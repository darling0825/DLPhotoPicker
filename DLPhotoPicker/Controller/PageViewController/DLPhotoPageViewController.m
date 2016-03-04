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
<UIPageViewControllerDataSource, UIPageViewControllerDelegate>

@property (nonatomic, assign, getter = isStatusBarHidden) BOOL statusBarHidden;

@property (nonatomic, copy) NSArray *assets;
@property (nonatomic, strong, readonly) DLPhotoAsset *asset;

@property (nonatomic, strong) DLPhotoPageView *pageView;

@property (nonatomic, strong) UIBarButtonItem *playButton;
@property (nonatomic, strong) UIBarButtonItem *pauseButton;
@property (nonatomic, strong) UIBarButtonItem *actionButton;
@property (nonatomic, strong) UIBarButtonItem *favoriteButton;
@property (nonatomic, strong) UIBarButtonItem *deleteButton;
@property (nonatomic, strong) DLPhotoBarButtonItem *selectionButton;

@end

@implementation DLPhotoPageViewController

- (instancetype)initWithAssets:(NSArray *)assets
{
    self = [super initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll
                    navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal
                                  options:@{UIPageViewControllerOptionInterPageSpacingKey:@30.f}];
    
    if (self)
    {
        self.assets          = assets;
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
//    DLPhotoBarButtonItem *selectionButton = [DLPhotoBarButtonItem buttonWithType:UIButtonTypeCustom];
//    selectionButton.frame = CGRectMake(0, 0, 40.0, 40.0);
//    selectionButton.backgroundColor = [UIColor redColor];
//    [selectionButton setImage:[UIImage assetImageNamed:@"SelectButtonUnchecked"] forState:UIControlStateNormal];
//    [selectionButton setImage:[UIImage assetImageNamed:@"SelectButtonChecked"] forState:UIControlStateSelected];
//    [selectionButton addTarget:self action:@selector(selectionButtonTouchDown:) forControlEvents:UIControlEventTouchDown];
//    [selectionButton addTarget:self action:@selector(selectionButtonTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];
//    _selectionButton = selectionButton;
    
    UIImage *image = [UIImage assetImageNamed:@"SelectButtonChecked"];
    UIBarButtonItem *selectionButton = [[UIBarButtonItem alloc] initWithImage:[UIImage assetImageNamed:@"SelectButtonChecked"]
                                                                        style:UIBarButtonItemStylePlain
                                                                       target:self
                                                                       action:@selector(selectionButtonTouchUpInside:)];
    self.navigationItem.rightBarButtonItems = @[selectionButton];
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


#pragma mark - Update title

- (void)updateTitle:(NSInteger)index
{
    NSNumberFormatter *nf = [NSNumberFormatter new];

    NSInteger count = self.assets.count;
    self.title      = [NSString stringWithFormat:DLPhotoPickerLocalizedString(@"%@ of %@", nil),
                       [nf assetStringFromAssetCount:index],
                       [nf assetStringFromAssetCount:count]];
}

#pragma mark - Update toolbar
- (void)updateToolbar
{
    if (!self.playButton){
        UIImage *playImage = [UIImage assetImageNamed:@"PlayButton"];
        playImage = [playImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        
        UIBarButtonItem *playButton =
        [[UIBarButtonItem alloc] initWithImage:playImage style:UIBarButtonItemStyleDone target:self action:@selector(playAsset:)];
        
        self.playButton = playButton;
    }
    
    if (!self.pauseButton){
        UIImage *pasueImage = [UIImage assetImageNamed:@"PauseButton"];
        pasueImage = [pasueImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        
        UIBarButtonItem *pauseButton = [[UIBarButtonItem alloc] initWithImage:pasueImage
                                                                        style:UIBarButtonItemStylePlain
                                                                       target:self
                                                                       action:@selector(pauseAsset:)];
        self.pauseButton = pauseButton;
    }
    
    if (!self.actionButton) {
        self.actionButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                                          target:self
                                                                          action:@selector(photoShareAction:)];
    }
    
    if (!self.favoriteButton) {
        self.favoriteButton = [[UIBarButtonItem alloc] initWithImage:[UIImage assetImageNamed:@"BadgeFavorites"]
                                                               style:UIBarButtonItemStylePlain
                                                              target:self
                                                              action:@selector(photoFavoriteAction:)];
    }
    
    if (!self.deleteButton) {
        self.deleteButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash
                                                                          target:self
                                                                          action:@selector(photoDeleteAction:)];
    }   
    
    self.toolbarItems = @[self.actionButton, self.toolbarSpace, self.favoriteButton, self.toolbarSpace, self.deleteButton];
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

- (void)photoShareAction:(UIBarButtonItem *)sender
{
    
}

- (void)photoFavoriteAction:(UIBarButtonItem *)sender
{
    
}

- (void)photoDeleteAction:(UIBarButtonItem *)sender
{
    [[DLPhotoManager sharedInstance] removeAsset:@[self.asset] completion:^(BOOL success) {
        //  Back
        if (success) {
            [self.navigationController popViewControllerAnimated:YES];
        }
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
        
        DLPhotoAsset *asset = [self.assets objectAtIndex:pageIndex];
        
        DLPhotoItemViewController *page = [DLPhotoItemViewController assetItemViewControllerForAsset:asset];
        page.allowsSelection = self.allowsSelection;
        
        [self setViewControllers:@[page]
                       direction:UIPageViewControllerNavigationDirectionForward
                        animated:NO
                      completion:NULL];
        
        [self updateTitle:pageIndex + 1];
        [self updateToolbar];
    }
}

- (DLPhotoAsset *)asset
{
    return ((DLPhotoItemViewController *)self.viewControllers[0]).asset;
}

- (DLPhotoItemViewController *)itemViewController
{
    return (DLPhotoItemViewController *)self.viewControllers[0];
}


#pragma mark - Page view controller data source

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    DLPhotoAsset *asset = ((DLPhotoItemViewController *)viewController).asset;
    NSInteger index = [self.assets indexOfObject:asset];
    
    if (index > 0){
        DLPhotoAsset *beforeAsset = [self.assets objectAtIndex:(index - 1)];
        DLPhotoItemViewController *page = [DLPhotoItemViewController assetItemViewControllerForAsset:beforeAsset];
        page.allowsSelection = self.allowsSelection;
        
        return page;
    }

    return nil;
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    DLPhotoAsset *asset  = ((DLPhotoItemViewController *)viewController).asset;
    NSInteger index = [self.assets indexOfObject:asset];
    NSInteger count = self.assets.count;
    
    if (index < count - 1)
    {
        DLPhotoAsset *afterAsset = [self.assets objectAtIndex:(index + 1)];
        DLPhotoItemViewController *page = [DLPhotoItemViewController assetItemViewControllerForAsset:afterAsset];
        page.allowsSelection = self.allowsSelection;
        
        return page;
    }
    
    return nil;
}


#pragma mark - Page view controller delegate

- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed
{
    if (completed)
    {
        DLPhotoItemViewController *vc = (DLPhotoItemViewController *)pageViewController.viewControllers[0];
        NSInteger index = [self.assets indexOfObject:vc.asset] + 1;
        
        [self updateTitle:index];
        [self updateToolbar];
    }
}

- (void)pageViewController:(UIPageViewController *)pageViewController willTransitionToViewControllers:(NSArray *)pendingViewControllers
{
    //[self.navigationController setToolbarHidden:NO animated:YES];
}


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
