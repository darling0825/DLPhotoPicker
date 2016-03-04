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
#import "DLPhotoPickerDefines.h"
#import "DLPhotoCollectionViewFooter.h"
#import "NSNumberFormatter+DLPhotoPicker.h"
#import "NSBundle+DLPhotoPicker.h"


@interface DLPhotoCollectionViewFooter ()

@property (nonatomic, strong) UILabel *label;

@property (nonatomic, assign) BOOL didSetupConstraints;

@end



@implementation DLPhotoCollectionViewFooter

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        [self setupViews];
    }
    
    return self;
}


#pragma mark - Setup

- (void)setupViews
{
    UILabel *label = [UILabel newAutoLayoutView];
    label.textAlignment = NSTextAlignmentCenter;
    label.font = DLPhotoCollectionViewFooterFont;
    label.textColor = DLPhotoCollectionViewFooterTextColor;
    
    self.label = label;
    [self addSubview:self.label];
}


#pragma mark - Appearance

- (UIFont *)font
{
    return self.label.font;
}

- (void)setFont:(UIFont *)font
{
    UIFont *labelFont = (font) ? font : DLPhotoCollectionViewFooterFont;
    self.label.font = labelFont;
}

- (UIColor *)textColor
{
    return self.label.textColor;
}

- (void)setTextColor:(UIColor *)textColor
{
    UIColor *color = (textColor) ? textColor : DLPhotoCollectionViewFooterTextColor;
    self.label.textColor = color;
}


#pragma mark - Update auto layout constraints

- (void)updateConstraints
{
    if (!self.didSetupConstraints)
    {
        [self.label autoPinEdgesToSuperviewMargins];
        
        self.didSetupConstraints = YES;
    }
    
    [super updateConstraints];
}

- (void)bind:(DLPhotoCollection *)photoCollection
{
    NSNumberFormatter *nf = [NSNumberFormatter new];
    
    NSString *numberOfVideos = @"";
    NSString *numberOfPhotos = @"";
    
    NSUInteger videoCount = photoCollection.countOfAssetsWithVideoType;
    NSUInteger photoCount = photoCollection.countOfAssetsWithImageType;
    
    if (videoCount > 0)
        numberOfVideos = [nf assetStringFromAssetCount:videoCount];
    
    if (photoCount > 0)
        numberOfPhotos = [nf assetStringFromAssetCount:photoCount];
    
    if (photoCount > 0 && videoCount > 0)
        self.label.text = [NSString stringWithFormat:DLPhotoPickerLocalizedString(@"%@ Photos, %@ Videos", nil), numberOfPhotos, numberOfVideos];
    else if (photoCount > 0 && videoCount <= 0)
        self.label.text = [NSString stringWithFormat:DLPhotoPickerLocalizedString(@"%@ Photos", nil), numberOfPhotos];
    else if (photoCount <= 0 && videoCount > 0)
        self.label.text = [NSString stringWithFormat:DLPhotoPickerLocalizedString(@"%@ Videos", nil), numberOfVideos];
    else
        self.label.text = @"";
    
    self.hidden = (photoCollection.count == 0);
    
    [self setNeedsUpdateConstraints];
    [self updateConstraintsIfNeeded];
}

@end