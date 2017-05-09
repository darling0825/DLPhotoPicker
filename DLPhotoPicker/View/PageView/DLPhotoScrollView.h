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

#import <UIKit/UIKit.h>
#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>
#import "DLPhotoPlayButton.h"
#import "DLPhotoBarButtonItem.h"

extern NSString * const DLPhotoScrollViewDidTapNotification;
extern NSString * const DLPhotoScrollViewPlayerWillPlayNotification;
extern NSString * const DLPhotoScrollViewPlayerWillPauseNotification;
extern NSString * const DLPhotoScrollViewDidZoomNotification;


@class DLPhotoAsset;
@class DLTiledImageView;

@interface DLPhotoScrollView : UIScrollView

@property (nonatomic, assign) BOOL allowsSelection;

@property (nonatomic, strong, readonly) UIImage *image;
@property (nonatomic, strong, readonly) AVPlayer *player;

@property (nonatomic, strong, readonly) DLTiledImageView *imageView;
@property (nonatomic, strong, readonly) DLPhotoPlayButton *playButton;
@property (nonatomic, strong, readonly) DLPhotoBarButtonItem *selectionButton;

- (void)startActivityAnimating;
- (void)stopActivityAnimating;

//
- (void)setProgress:(CGFloat)progress;

//
- (void)reloadView;

//旋转后更新
- (void)updateViewAfterRotate;

//
- (void)bind:(DLPhotoAsset *)asset image:(UIImage *)image isDegraded:(BOOL)isDegraded;
- (void)bind:(AVAsset *)asset;


//
- (void)playVideo;
- (void)pauseVideo;

@end
