/*
 
 MIT License (MIT)
 
 Copyright (c) 2013 Clement CN Tsang
 
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
#import "DLPhotoCollectionSelectedView.h"
#import "DLPhotoCheckmark.h"


@interface DLPhotoCollectionSelectedView ()

@property (nonatomic, strong) DLPhotoCheckmark *checkmark;

@end


@implementation DLPhotoCollectionSelectedView

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
    self.backgroundColor = DLPhotoCollectionSelectedViewBackgroundColor;
    self.layer.borderColor = DLPhotoCollectionSelectedViewTintColor.CGColor;
    
    DLPhotoCheckmark *checkmark = [DLPhotoCheckmark newAutoLayoutView];
    self.checkmark = checkmark;
    [self addSubview:checkmark];
}

#pragma mark - Apperance

- (UIColor *)selectedBackgroundColor
{
    return self.backgroundColor;
}

- (void)setSelectedBackgroundColor:(UIColor *)backgroundColor
{
    UIColor *color = (backgroundColor) ? backgroundColor : DLPhotoCollectionSelectedViewBackgroundColor;
    self.backgroundColor = color;
}

- (CGFloat)borderWidth
{
    return self.layer.borderWidth;
}

- (void)setBorderWidth:(CGFloat)borderWidth
{
    self.layer.borderWidth = borderWidth;
}

- (void)setTintColor:(UIColor *)tintColor
{
    UIColor *color = (tintColor) ? tintColor : DLPhotoCollectionSelectedViewTintColor;
    self.layer.borderColor = color.CGColor;
}

@end
