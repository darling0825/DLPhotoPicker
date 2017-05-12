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
#import "DLPhotoScrollView.h"
#import "DLPhotoPlayButton.h"
#import "DLPhotoAsset.h"
#import "NSBundle+DLPhotoPicker.h"
#import "UIImage+DLPhotoPicker.h"
#import "DLTiledImageView.h"

NSString * const DLPhotoScrollViewDidTapNotification = @"DLPhotoScrollViewDidTapNotification";
NSString * const DLPhotoScrollViewPlayerWillPlayNotification = @"DLPhotoScrollViewPlayerWillPlayNotification";
NSString * const DLPhotoScrollViewPlayerWillPauseNotification = @"DLPhotoScrollViewPlayerWillPauseNotification";
NSString * const DLPhotoScrollViewDidZoomNotification = @"DLPhotoScrollViewDidZoomNotification";



@interface DLPhotoScrollView ()
<UIScrollViewDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, strong) DLPhotoAsset *asset;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) AVPlayer *player;

@property (nonatomic, assign) BOOL didLoadPlayerItem;

@property (nonatomic, assign) CGFloat perspectiveZoomScale;
@property (nonatomic, assign) CGFloat initialScale;

@property (nonatomic, strong) DLTiledImageView *imageView;
@property (nonatomic, strong) UIImageView *bgImageView;

@property (nonatomic, strong) UIProgressView *progressView;
@property (nonatomic, strong) UIActivityIndicatorView *activityView;
@property (nonatomic, strong) DLPhotoPlayButton *playButton;
@property (nonatomic, strong) DLPhotoBarButtonItem *selectionButton;

@property (nonatomic, assign) BOOL isFirstZoom;
@property (nonatomic, assign) BOOL didSetupConstraints;

@end



@implementation DLPhotoScrollView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self)
    {
        self.isFirstZoom                    = YES;
        self.allowsSelection                = NO;
        self.showsVerticalScrollIndicator   = YES;
        self.showsHorizontalScrollIndicator = YES;
        self.bouncesZoom                    = YES;
        self.decelerationRate               = UIScrollViewDecelerationRateFast;
        self.delegate                       = self;
        
        [self setupViews];
        [self addGestureRecognizers];
    }
    
    return self;
}

- (void)dealloc
{
    [self removePlayerNotificationObserver];
    [self removePlayerLoadedTimeRangesObserver];
    [self removePlayerRateObserver];
}

- (void)layoutSubviews {
    [super layoutSubviews];

    [self updateImageViewConstraints];

    if (!self.didSetupConstraints) {
        [self autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
        [self updateProgressConstraints];
        [self updateActivityConstraints];
        [self updateButtonsConstraints];
        [self updateSelectionButtonIfNeeded];

        self.didSetupConstraints = YES;
    }
}

#pragma mark - Setup

- (void)setupViews
{
    UIImageView *bgImageView = [[UIImageView alloc] initWithFrame:self.bounds];
    bgImageView.contentMode = UIViewContentModeScaleAspectFit;
    bgImageView.backgroundColor = [UIColor clearColor];
    self.bgImageView = bgImageView;
    [self addSubview:bgImageView];
    [self sendSubviewToBack:bgImageView];


    DLTiledImageView *imageView = [DLTiledImageView new];
    imageView.isAccessibilityElement    = YES;
    imageView.accessibilityTraits       = UIAccessibilityTraitImage;
    imageView.contentMode               = UIViewContentModeScaleAspectFit;
    self.imageView = imageView;
    [self addSubview:imageView];


    UIProgressView *progressView =
    [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    self.progressView = progressView;
    [self addSubview:self.progressView];
    
    UIActivityIndicatorView *activityView =
    [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    self.activityView = activityView;
    [self addSubview:self.activityView];
    
    
    DLPhotoPlayButton *playButton = [DLPhotoPlayButton newAutoLayoutView];
    playButton.hidden = YES;
    self.playButton = playButton;
    [self addSubview:self.playButton];
    
    
    DLPhotoBarButtonItem *selectionButton = [DLPhotoBarButtonItem newAutoLayoutView];
    selectionButton.frame = CGRectMake(0, 0, 80.0, 80.0);
    selectionButton.isLeftButton = NO;
    UIImage *checkmarkImage = [UIImage assetImageNamed:@"SelectButtonChecked"];
    UIImage *uncheckmarkImage = [UIImage assetImageNamed:@"SelectButtonUnchecked"];
    [selectionButton setImage:uncheckmarkImage forState:UIControlStateNormal];
    [selectionButton setImage:checkmarkImage forState:UIControlStateSelected];
    self.selectionButton = selectionButton;
    [self addSubview:self.selectionButton];
}

#pragma mark - 编辑之后重新读取
- (void)reloadView
{
    self.image = nil;
    self.imageView.image = nil;
    self.bgImageView.image = nil;
}

#pragma mark - 旋转后更新
- (void)updateViewAfterRotate {
    CGSize imageSize = self.assetSize;

    [self updateZoomScales: imageSize];
    [self zoomToInitialScale];
}

#pragma mark - Update auto layout constraints

- (void)updateImageViewConstraints {

    if (self.asset == nil) {
        return;
    }

    // center the image as it becomes smaller than the size of the screen
    CGSize boundsSize = self.bounds.size;
    CGSize imageSize = self.assetSize;

    CGRect frameToCenter = CGRectMake(0.0, 0.0,
                                      imageSize.width * self.zoomScale,
                                      imageSize.height * self.zoomScale);

    // center vertically
    frameToCenter.origin.y = CGRectGetHeight(frameToCenter) < boundsSize.height ? (boundsSize.height - CGRectGetHeight(frameToCenter)) / 2 : 0;

    // center horizontally
    frameToCenter.origin.x = CGRectGetWidth(frameToCenter) < boundsSize.width ? (boundsSize.width - CGRectGetWidth(frameToCenter)) / 2 : 0;

    self.bgImageView.frame = frameToCenter;
    self.imageView.frame = frameToCenter;

    // to handle the interaction between CATiledLayer and high resolution screens, we need to manually set the
    // tiling view's contentScaleFactor to 1.0. (If we omitted this, it would be 2.0 on high resolution screens,
    // which would cause the CATiledLayer to ask us for tiles of the wrong scales.)
    self.imageView.contentScaleFactor = 1.0;
}

- (void)updateSelectionButtonIfNeeded
{
    if (!self.allowsSelection)
    {
        [self.selectionButton removeFromSuperview];
        self.selectionButton = nil;
    }
}

- (void)updateProgressConstraints
{
    [NSLayoutConstraint autoSetPriority:UILayoutPriorityDefaultLow forConstraints:^{
        [self.progressView autoConstrainAttribute:ALAttributeLeading toAttribute:ALAttributeLeading ofView:self.superview withMultiplier:1 relation:NSLayoutRelationEqual];
        [self.progressView autoConstrainAttribute:ALAttributeTrailing toAttribute:ALAttributeTrailing ofView:self.superview withMultiplier:1 relation:NSLayoutRelationEqual];
        [self.progressView autoConstrainAttribute:ALAttributeBottom toAttribute:ALAttributeBottom ofView:self.superview withMultiplier:1 relation:NSLayoutRelationEqual];
    }];
}

- (void)updateActivityConstraints
{
    [self.activityView autoAlignAxis:ALAxisVertical toSameAxisOfView:self.superview];
    [self.activityView autoAlignAxis:ALAxisHorizontal toSameAxisOfView:self.superview];
}

- (void)updateButtonsConstraints
{
    [self.playButton autoAlignAxis:ALAxisVertical toSameAxisOfView:self.superview];
    [self.playButton autoAlignAxis:ALAxisHorizontal toSameAxisOfView:self.superview];
    
    CGFloat padding = 20;
    CGFloat navBarHeight = 44;
    [NSLayoutConstraint autoSetPriority:UILayoutPriorityDefaultLow forConstraints:^{
        [self.selectionButton autoConstrainAttribute:ALAttributeTrailing toAttribute:ALAttributeTrailing ofView:self.superview withOffset:-(self.layoutMargins.right + padding) relation:NSLayoutRelationEqual];
        [self.selectionButton autoConstrainAttribute:ALAttributeTop toAttribute:ALAttributeTop ofView:self.superview withOffset:(self.layoutMargins.top + padding + navBarHeight) relation:NSLayoutRelationEqual];
    }];
}

#pragma mark - Start/stop loading animation

- (void)startActivityAnimating
{
    [self.playButton setHidden:YES];
    [self.activityView startAnimating];
    [self postPlayerWillPlayNotification];
}

- (void)stopActivityAnimating
{
    [self.playButton setHidden:NO];
    [self.activityView stopAnimating];
    [self postPlayerWillPauseNotification];
}

#pragma mark - Set progress

- (void)setProgress:(CGFloat)progress
{
#if !defined(CT_APP_EXTENSIONS)
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:(progress < 1)];
#endif
    [self.progressView setProgress:progress animated:(progress < 1)];
    [self.progressView setHidden:(progress == 1)];
}

// To mimic image downloading progress
// as PHImageRequestOptions does not work as expected
- (void)mimicProgress
{
    CGFloat progress = self.progressView.progress;

    if (progress < 0.95)
    {
        int lowerbound = progress * 100 + 1;
        int upperbound = 95;
        
        int random = lowerbound + arc4random() % (upperbound - lowerbound);
        CGFloat randomProgress = random / 100.0f;

        [self setProgress:randomProgress];
        
        NSInteger randomDelay = 1 + arc4random() % (3 - 1);
        [self performSelector:@selector(mimicProgress) withObject:nil afterDelay:randomDelay];
    }
}


#pragma mark - asset size

- (CGSize)assetSize
{
    return self.asset.assetdimensions;
}

#pragma mark - Bind asset image

- (void)bind:(DLPhotoAsset *)asset image:(UIImage *)image isDegraded:(BOOL)isDegraded
{
    //
    self.asset = asset;
    self.image = image;

    //fix bug: 正在播放视频时, 会有请求的预览图生成, 会再次执行到这里, 导致playButton显示
    if (self.player) {
        self.playButton.hidden = YES;
    }else {
        self.playButton.hidden = !asset.isVideo;
    }

    // get scale
    [self updateZoomScales:self.assetSize];

    __block CGRect imageRect = CGRectMake(0, 0,
                                  self.assetSize.width * self.initialScale,
                                  self.assetSize.height * self.initialScale);

    //
    __weak typeof(self) weakself = self;

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

        __strong __typeof(weakself) strongSelf = weakself;
        
        UIImage *bgImage = nil;
        /*
         * Degraded 图片大小与imageView 大小不符, 加载也会很慢
         * 所有图片都经处理后再加载
         */
        //if (!isDegraded) {
            UIGraphicsBeginImageContext(imageRect.size);
            CGContextRef ctx = UIGraphicsGetCurrentContext();
            CGContextSaveGState(ctx);

            CGContextTranslateCTM(ctx, imageRect.origin.x, imageRect.origin.y);
            CGContextTranslateCTM(ctx, 0.0, imageRect.size.height);
            CGContextScaleCTM(ctx, 1.0, -1.0);
            CGContextTranslateCTM(ctx, -imageRect.origin.x, -imageRect.origin.y);
            CGContextDrawImage(ctx, imageRect, image.CGImage);
            CGContextRestoreGState(ctx);

            bgImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
        //}

        CGSize boundsSize = strongSelf.bounds.size;

        // center vertically
        imageRect.origin.y = CGRectGetHeight(imageRect) < boundsSize.height ?
        (boundsSize.height - CGRectGetHeight(imageRect)) / 2 : 0;

        // center horizontally
        imageRect.origin.x = CGRectGetWidth(imageRect) < boundsSize.width ?
        (boundsSize.width - CGRectGetWidth(imageRect)) / 2 : 0;

        dispatch_async(dispatch_get_main_queue(), ^{

            strongSelf.bgImageView.frame = imageRect;
            strongSelf.bgImageView.image = bgImage;

            if (isDegraded) {
                [strongSelf mimicProgress];
            }else {
                [strongSelf setProgress:1];

                strongSelf.imageView.frame = imageRect;
                strongSelf.imageView.image = image;
            }
            
            [strongSelf zoomToInitialScale];

            //fix bug: 某些图片缩放不正常, 导致加载缓慢
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                [strongSelf zoomToInitialScale];
            });
        });
    });
}


#pragma mark - Bind player item

- (void)bind:(AVAsset *)asset
{
    [self unbindPlayerItem];
    
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:asset];
    AVPlayer *player = [AVPlayer playerWithPlayerItem:playerItem];
    AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:player];
    playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;

    CALayer *layer = self.imageView.layer;
    [layer addSublayer:playerLayer];
    [playerLayer setFrame:layer.bounds];
    
    self.player = player;

    [self addPlayerNotificationObserver];
    [self addPlayerLoadedTimeRangesObserver];
}

- (void)unbindPlayerItem
{
    [self removePlayerNotificationObserver];
    [self removePlayerLoadedTimeRangesObserver];

    for (CALayer *layer in self.imageView.layer.sublayers)
        [layer removeFromSuperlayer];
    
    self.player = nil;
}

#pragma mark - Upate zoom scales
- (void)updateZoomScales:(CGSize)imageSize {

    CGSize assetSize    = imageSize;
    CGSize boundsSize   = self.bounds.size;

    /**
     *  Fix bug: Do not get assetSize.
     */
    if (CGSizeEqualToSize(assetSize, CGSizeZero)) {
        assetSize = boundsSize;
    }

    CGFloat xScale = boundsSize.width / assetSize.width;    //scale needed to perfectly fit the image width-wise
    CGFloat yScale = boundsSize.height / assetSize.height;  //scale needed to perfectly fit the image height-wise


    /*
     xScale < yScale : 宽图
     xScale > yScale : 长图
     min(xScale, yScale) : 全部显示
     max(xScale, yScale) : 全屏显示, 原图大小
     perspectiveZoomScale: 全屏显示, 原图大小
     */
    CGFloat minScale = MIN(xScale, yScale); //全部显示
    CGFloat maxScale = 5.0 * MAX(xScale, yScale); //原图的5倍

    // update perspective zoom scale
    self.perspectiveZoomScale = MAX(xScale, yScale);
 
    //
    if (xScale >= 2.6 * yScale) {
        maxScale = xScale * 0.99;//竖长图
    }else if (yScale >= 5.0 * xScale){
        maxScale = yScale * 0.99;//横长图
    }

    if (self.asset.mediaType == DLPhotoMediaTypeVideo)
    {
        self.minimumZoomScale = minScale;
        self.maximumZoomScale = minScale;
    }
    else
    {
        self.minimumZoomScale = minScale;
        self.maximumZoomScale = maxScale;
    }

    // image sacle
    self.initialScale = minScale;
    if ([self canPerspectiveZoom]) {
        self.initialScale = self.perspectiveZoomScale;
    }
}


#pragma mark - Zoom

- (void)zoomToInitialScale
{
    [self setZoomScale:self.initialScale animated:NO];
}

- (void)zoomToMinimumZoomScaleAnimated:(BOOL)animated
{
    [self setZoomScale:self.minimumZoomScale animated:animated];
}

- (void)zoomToPerspectiveZoomScaleAnimated:(BOOL)animated;
{
    [self setZoomScale:self.perspectiveZoomScale animated:animated];
}

- (void)zoomToMaximumZoomScaleWithGestureRecognizer:(UITapGestureRecognizer *)recognizer
{
    CGRect zoomRect = [self zoomRectWithScale:self.maximumZoomScale withCenter:[recognizer locationInView:recognizer.view]];

    [UIView animateWithDuration:0.3 animations:^{
        [self zoomToRect:zoomRect animated:NO];
    }];
}

#pragma mark - Perspective zoom
- (BOOL)canPerspectiveZoom
{
    CGSize assetSize    = [self assetSize];
    CGSize boundsSize   = self.bounds.size;
    
    CGFloat assetRatio  = assetSize.width / assetSize.height;
    CGFloat boundsRatio = boundsSize.width / boundsSize.height;
    
    // can perform perspective zoom when the difference of aspect ratios is smaller than 20%
    return (fabs( (assetRatio - boundsRatio) / boundsRatio ) < 0.2f);
}

#pragma mark - Zoom with gesture recognizer

- (void)zoomWithGestureRecognizer:(UITapGestureRecognizer *)recognizer
{
    if (self.minimumZoomScale == self.maximumZoomScale){
        return;
    }
    
    if ([self canPerspectiveZoom]){
        /*
        if ((self.zoomScale >= self.minimumZoomScale && self.zoomScale < self.perspectiveZoomScale) ||
            (self.zoomScale <= self.maximumZoomScale && self.zoomScale > self.perspectiveZoomScale)){
            [self zoomToPerspectiveZoomScaleAnimated:YES];
        }
        else{
            [self zoomToMaximumZoomScaleWithGestureRecognizer:recognizer];
        }
         */
        if (self.zoomScale <= self.perspectiveZoomScale) {
            [self zoomToMaximumZoomScaleWithGestureRecognizer:recognizer];
        }else{
            [self zoomToMinimumZoomScaleAnimated:YES];
        }
    }else{
        if (self.zoomScale < self.maximumZoomScale / 2){
            [self zoomToMaximumZoomScaleWithGestureRecognizer:recognizer];
        }else{
            [self zoomToMinimumZoomScaleAnimated:YES];
        }
    }
}

- (CGRect)zoomRectWithScale:(CGFloat)scale withCenter:(CGPoint)center
{
    center = [self.imageView convertPoint:center fromView:self];
    
    CGRect zoomRect;
    
    zoomRect.size.height = self.frame.size.height / scale;
    zoomRect.size.width  = self.frame.size.width  / scale;
    
    zoomRect.origin.x    = center.x - ((zoomRect.size.width / 2.0));
    zoomRect.origin.y    = center.y - ((zoomRect.size.height / 2.0));
    
    return zoomRect;
}

//- (CGRect)zoomRectWithScale:(CGFloat)scale
//{
//    CGSize targetSize;
//    targetSize.width    = self.bounds.size.width / scale;
//    targetSize.height   = self.bounds.size.height / scale;
//    
//    CGPoint targetOrigin;
//    targetOrigin.x      = (self.assetSize.width - targetSize.width) / 2.0;
//    targetOrigin.y      = (self.assetSize.height - targetSize.height) / 2.0;
//    
//    CGRect zoomRect;
//    zoomRect.origin = targetOrigin;
//    zoomRect.size   = targetSize;
//    
//    return zoomRect;
//}

#pragma mark - Gesture recognizers

- (void)addGestureRecognizers
{
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapping:)];
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapping:)];
    
    [doubleTap setNumberOfTapsRequired:2.0];
    [singleTap requireGestureRecognizerToFail:doubleTap];
    
    [singleTap setDelegate:self];
    [doubleTap setDelegate:self];
    
    [self addGestureRecognizer:singleTap];
    [self addGestureRecognizer:doubleTap];
}


#pragma mark - Handle tappings

- (void)handleTapping:(UITapGestureRecognizer *)recognizer
{
    [[NSNotificationCenter defaultCenter] postNotificationName:DLPhotoScrollViewDidTapNotification object:recognizer];
    
    if (recognizer.numberOfTapsRequired == 2){
        [self zoomWithGestureRecognizer:recognizer];
    }
}


#pragma mark - Scroll view delegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.imageView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
    if (self.isFirstZoom) {
        self.isFirstZoom = NO;
    }else {
        [[NSNotificationCenter defaultCenter] postNotificationName:DLPhotoScrollViewDidZoomNotification object:nil];
    }
    
    [self setScrollEnabled:(self.zoomScale != self.perspectiveZoomScale)];

    /**
     *  set the photo in the middle of screen
     */
    [self setNeedsLayout];
    [self layoutIfNeeded];
}


#pragma mark - Gesture recognizer delegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    return !([touch.view isDescendantOfView:self.playButton]);
}


#pragma mark - Notification observer

- (void)addPlayerNotificationObserver
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    
    [center addObserver:self
               selector:@selector(applicationWillResignActive:)
                   name:UIApplicationWillResignActiveNotification
                 object:nil];
}

- (void)removePlayerNotificationObserver
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];

    [center removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
}



#pragma mark - Video player item key-value observer

- (void)addPlayerLoadedTimeRangesObserver
{
    [self.player addObserver:self
                  forKeyPath:@"currentItem.loadedTimeRanges"
                     options:NSKeyValueObservingOptionNew
                     context:nil];
}

- (void)removePlayerLoadedTimeRangesObserver
{
    @try {
        [self.player removeObserver:self forKeyPath:@"currentItem.loadedTimeRanges"];
    }
    @catch (NSException *exception) {
        // do nothing
    }
}

- (void)addPlayerRateObserver
{
    [self.player addObserver:self
                  forKeyPath:@"rate"
                     options:NSKeyValueObservingOptionNew
                     context:nil];
}

- (void)removePlayerRateObserver
{
    @try {
        [self.player removeObserver:self forKeyPath:@"rate"];
    }
    @catch (NSException *exception) {
        // do nothing
    }    
}


#pragma mark - Video playback Key-Value changed

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == self.player && [keyPath isEqual:@"currentItem.loadedTimeRanges"])
    {
        NSArray *timeRanges = [change objectForKey:NSKeyValueChangeNewKey];

        if (timeRanges && [timeRanges count])
        {
            CMTimeRange timeRange = [timeRanges.firstObject CMTimeRangeValue];
            
            if (CMTIME_COMPARE_INLINE(timeRange.duration, ==, self.player.currentItem.duration))
                [self performSelector:@selector(playerDidLoadItem:) withObject:object];
        }
    }
    
    if (object == self.player && [keyPath isEqual:@"rate"])
    {
        CGFloat rate = [[change valueForKey:NSKeyValueChangeNewKey] floatValue];
        
        if (rate > 0)
            [self performSelector:@selector(playerDidPlay:) withObject:object];
        
        if (rate == 0)
            [self performSelector:@selector(playerDidPause:) withObject:object];
    }
}



#pragma mark - Notifications

- (void)postPlayerWillPlayNotification
{
    [[NSNotificationCenter defaultCenter] postNotificationName:DLPhotoScrollViewPlayerWillPlayNotification object:nil];
}

- (void)postPlayerWillPauseNotification
{
    [[NSNotificationCenter defaultCenter] postNotificationName:DLPhotoScrollViewPlayerWillPauseNotification object:nil];
}


#pragma mark - Playback events

- (void)applicationWillResignActive:(NSNotification *)notification
{
    [self pauseVideo];
}


- (void)playerDidPlay:(id)sender
{
    [self setProgress:1];
    [self.playButton setHidden:YES];
    [self.selectionButton setHidden:YES];
    [self.activityView stopAnimating];
}


- (void)playerDidPause:(id)sender
{
    [self.playButton setHidden:NO];
    [self.selectionButton setHidden:NO];
}

- (void)playerDidLoadItem:(id)sender
{
    if (!self.didLoadPlayerItem)
    {
        [self setDidLoadPlayerItem:YES];
        [self addPlayerRateObserver];
        
        [self.activityView stopAnimating];
        [self playVideo];
    }
}


#pragma mark - Playback

- (void)playVideo
{
    if (self.didLoadPlayerItem)
    {
        if (CMTIME_COMPARE_INLINE(self.player.currentTime, == , self.player.currentItem.duration))
            [self.player seekToTime:kCMTimeZero];
        
        [self postPlayerWillPlayNotification];
        [self.player play];
    }
}

- (void)pauseVideo
{
    if (self.didLoadPlayerItem)
    {
        [self postPlayerWillPauseNotification];
        [self.player pause];
    }
    else
    {
        [self stopActivityAnimating];
        [self unbindPlayerItem];
    }
}


@end
