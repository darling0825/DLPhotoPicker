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


#import <PureLayout/PureLayout.h>
#import "DLPhotoPickerViewController.h"
#import "DLPhotoItemViewController.h"
#import "DLPhotoScrollView.h"
#import "NSBundle+DLPhotoPicker.h"
#import "DLPhotoPickerDefines.h"
#import "DLPhotoAsset.h"
#import "DLPhotoManager.h"


NSString * const DLPhotoPickerDidEnterEditModeNotification = @"DLPhotoPickerDidEnterEditModeNotification";
NSString * const DLPhotoPickerDidExitEditModeNotification = @"DLPhotoPickerDidExitEditModeNotification";


@interface DLPhotoItemViewController ()

@property (nonatomic, strong) DLPhotoScrollView *scrollView;
@property (nonatomic, assign) BOOL didSetupConstraints;

@end


@implementation DLPhotoItemViewController

+ (DLPhotoItemViewController *)assetItemViewControllerForAsset:(DLPhotoAsset *)asset
{
    return [[self alloc] initWithAsset:asset];
}

- (instancetype)initWithAsset:(DLPhotoAsset *)asset
{
    if (self = [super init])
    {
        self.asset = asset;
        self.allowsSelection = YES;
    }
    
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupViews];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self setupScrollViewButtons];
    [self requestAssetImage];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self pauseAsset:self.view];
    [self cancelRequestAsset];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self.scrollView updateZoomScalesAndZoom:YES];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
    [self.scrollView setNeedsUpdateConstraints];
    [self.scrollView updateConstraintsIfNeeded];
}

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_8_0
// iOS >= 8
- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];

    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self.scrollView updateZoomScalesAndZoom:YES];
    } completion:nil];
}

#elif __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_6_0
// iOS <= 7
- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
    [self.scrollView updateZoomScalesAndZoom:YES];
}

#endif

#pragma mark - Setup

- (void)setupViews
{
    DLPhotoScrollView *scrollView = [DLPhotoScrollView newAutoLayoutView];
    scrollView.allowsSelection = self.allowsSelection;
    
    self.scrollView = scrollView;
    
    [self.view addSubview:scrollView];
    [self.view layoutIfNeeded];
}

- (void)setupScrollViewButtons
{
    DLPhotoPlayButton *playButton = self.scrollView.playButton;
    [playButton addTarget:self action:@selector(playAsset:) forControlEvents:UIControlEventTouchUpInside];
}


#pragma mark - Cancel request

- (void)cancelRequestAsset
{
    [self cancelRequestImage];
    [self cancelRequestVideo];
}

- (void)cancelRequestImage
{
    if ([self.asset cancelRequestImage]){
        [self.scrollView setProgress:1];
    }
}

- (void)cancelRequestVideo
{
    if ([self.asset cancelRequestVideo]){
        [self.scrollView stopActivityAnimating];
    }
}

#pragma mark - Request image
- (void)requestAssetImage
{
    [self.scrollView setProgress:0];
    
    [self.asset requestPreviewImageWithCompletion:^(UIImage *image, NSDictionary *info) {
        NSError *error = [info objectForKey:PHImageErrorKey];
        if (error){
            [self showRequestImageError:error title:nil];
        }
        else{
            [self.scrollView bind:self.asset image:image requestInfo:info];
        }
    } withProgressHandler:^(double progress, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.scrollView setProgress:progress];
        });
    }];
}

#pragma mark - Request player item

- (void)requestAssetPlayerItem:(id)sender
{
    [self.scrollView startActivityAnimating];
    
    [self.asset requestOriginAVAssetWithCompletion:^(AVAsset *asset, AVAudioMix *audioMix, NSDictionary *info) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSError *error   = [info objectForKey:PHImageErrorKey];
            NSString *title = DLPhotoPickerLocalizedString(@"Cannot Play Stream Video", nil);
            if (error){
                [self showRequestVideoError:error title:title];
            }
            else{
                [self.scrollView bind:asset requestInfo:info];
            }
        });
    } withProgressHandler:^(double progress, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
        dispatch_async(dispatch_get_main_queue(), ^{
            //do nothing
        });
    }];
}

#pragma mark - Request error

- (void)showRequestImageError:(NSError *)error title:(NSString *)title
{
    [self.scrollView setProgress:1];
    [self showRequestError:error title:title];
}

- (void)showRequestVideoError:(NSError *)error title:(NSString *)title
{
    [self.scrollView stopActivityAnimating];
    [self showRequestError:error title:title];
}

- (void)showRequestError:(NSError *)error title:(NSString *)title
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:error.localizedDescription
                                                   delegate:nil
                                          cancelButtonTitle:DLPhotoPickerLocalizedString(@"OK", nil)
                                          otherButtonTitles:nil];
    
    [alert show];
}


#pragma mark - Playback

- (void)playAsset:(id)sender
{
    if (!self.scrollView.player)
        [self requestAssetPlayerItem:sender];
    else
        [self.scrollView playVideo];
}

- (void)pauseAsset:(id)sender
{
    if (!self.scrollView.player)
        [self cancelRequestVideo];
    else
        [self.scrollView pauseVideo];
}

@end
