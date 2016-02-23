//
//  DLPhotoCollectionViewCell.m
//  DLPhotoPicker
//
//  Created by 沧海无际 on 16/2/21.
//  Copyright © 2016年 darling0825. All rights reserved.
//

#import "DLPhotoCollectionViewCell.h"
#import <PureLayout/PureLayout.h>
#import "DLPhotoPickerDefines.h"
#import "DLPhotoCollectionSelectedView.h"
#import "PHAsset+DLPhotoPicker.h"
#import "NSDateFormatter+DLPhotoPicker.h"
#import "UIImage+DLPhotoPicker.h"

@interface DLPhotoCollectionViewCell()

@property (nonatomic, strong) DLPhotoAsset *asset;

@property (nonatomic, strong) UIImageView *disabledImageView;
@property (nonatomic, strong) UIView *disabledView;
@property (nonatomic, strong) UIView *highlightedView;
@property (nonatomic, strong) DLPhotoCollectionSelectedView *selectedView;

@property (nonatomic, assign) BOOL didSetupConstraints;

@end

@implementation DLPhotoCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        self.opaque                 = YES;
        self.isAccessibilityElement = YES;
        self.accessibilityTraits    = UIAccessibilityTraitImage;
        self.enabled                = YES;
        
        [self setupViews];
    }
    
    return self;
}


#pragma mark - Setup

- (void)setupViews
{
    DLPhotoThumbnailView *thumbnailView = [DLPhotoThumbnailView newAutoLayoutView];
    self.backgroundView = thumbnailView;
    
    UIImage *disabledImage = [UIImage ctassetsPickerImageNamed:@"GridDisabledAsset"];
    disabledImage = [disabledImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    UIImageView *disabledImageView = [[UIImageView alloc] initWithImage:disabledImage];
    disabledImageView.tintColor = DLPhotoPickerThumbnailTintColor;
    self.disabledImageView = disabledImageView;
    
    UIView *disabledView = [UIView newAutoLayoutView];
    disabledView.backgroundColor = DLPhotoCollectionViewCellDisabledColor;
    disabledView.hidden = YES;
    [disabledView addSubview:self.disabledImageView];
    self.disabledView = disabledView;
    [self addSubview:self.disabledView];
    
    UIView *highlightedView = [UIView newAutoLayoutView];
    highlightedView.backgroundColor = DLPhotoCollectionViewCellHighlightedColor;
    highlightedView.hidden = YES;
    self.highlightedView = highlightedView;
    [self addSubview:self.highlightedView];
    
    DLPhotoCollectionSelectedView *selectedView = [DLPhotoCollectionSelectedView newAutoLayoutView];
    selectedView.hidden = YES;
    self.selectedView = selectedView;
    [self addSubview:self.selectedView];
}

#pragma mark - Apperance

- (UIColor *)disabledColor
{
    return self.disabledView.backgroundColor;
}

- (void)setDisabledColor:(UIColor *)disabledColor
{
    UIColor *color = (disabledColor) ? disabledColor : DLPhotoCollectionViewCellDisabledColor;
    self.disabledView.backgroundColor = color;
}

- (UIColor *)highlightedColor
{
    return self.highlightedView.backgroundColor;
}

- (void)setHighlightedColor:(UIColor *)highlightedColor
{
    UIColor *color = (highlightedColor) ? highlightedColor : DLPhotoCollectionViewCellHighlightedColor;
    self.highlightedView.backgroundColor = color;
}


#pragma mark - Accessors

- (void)setEnabled:(BOOL)enabled
{
    _enabled = enabled;
    self.disabledView.hidden = enabled;
}

- (void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];
    self.highlightedView.hidden = !highlighted;
}

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    self.selectedView.hidden = !(selected && self.isShowCheckMark);
}

#pragma mark - Update auto layout constraints

- (void)updateConstraints
{
    if (!self.didSetupConstraints)
    {
        [NSLayoutConstraint autoSetPriority:UILayoutPriorityRequired forConstraints:^{
            [self.backgroundView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
            [self.disabledView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
            [self.highlightedView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
            [self.selectedView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
        }];
        
        [self.disabledImageView autoCenterInSuperview];
        
        self.didSetupConstraints = YES;
    }
    
    [super updateConstraints];
}

- (void)bind:(DLPhotoAsset *)asset
{
    self.asset = asset;
    
    [self setNeedsUpdateConstraints];
    [self updateConstraintsIfNeeded];
}

#pragma mark - Accessibility Label

- (NSString *)accessibilityLabel
{
    if (self.selectedView.accessibilityLabel)
        return [NSString stringWithFormat:@"%@, %@", self.selectedView.accessibilityLabel, self.asset.accessibilityLabel];
    else
        return self.asset.accessibilityLabel;
}
@end
