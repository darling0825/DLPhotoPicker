//
//  DLTiledImageView.m
//  DLPhotoPickerDemo
//
//  Created by 沧海无际 on 2017/5/7.
//  Copyright © 2017年 darling0825. All rights reserved.
//

#import "DLTiledImageView.h"
#import "DLTiledLayer.h"

@interface DLTiledImageView()
@property (nonatomic, strong) UIImage *tiledImage;
@end

@implementation DLTiledImageView

+ (Class)layerClass {
    return [DLTiledLayer class];
}

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        
        self.backgroundColor = [UIColor clearColor];

        DLTiledLayer *layer = (DLTiledLayer *)self.layer;
        DLTiledLayer.fadeDuration = 1.0;
        layer.levelsOfDetail = 4;
        layer.levelsOfDetailBias = 5;
        layer.tileSize = CGSizeMake(256, 256);

        layer.delegate = self;
    }
    return self;
}

- (UIImage *)image {
    return _tiledImage;
}

- (void)setImage:(UIImage *)image {
    _tiledImage = image;

    [self setNeedsDisplay];
}

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx {
    if (self.image) {

        /*
        __block CGRect rect = CGRectZero;
        if (![NSThread isMainThread]) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                rect = self.bounds;
            });
        }else {
            rect = self.bounds;
        }
         */

        CGRect rect = layer.bounds;

        //
        //CGContextRef ctx = UIGraphicsGetCurrentContext();
        CGContextSaveGState(ctx);
        CGContextTranslateCTM(ctx, rect.origin.x, rect.origin.y);
        CGContextTranslateCTM(ctx, 0.0, rect.size.height);
        CGContextScaleCTM(ctx, 1.0, -1.0);
        CGContextTranslateCTM(ctx, -rect.origin.x, -rect.origin.y);
        CGContextDrawImage(ctx, rect, self.image.CGImage);
        CGContextRestoreGState(ctx);
    }
}

@end
