//
//  DLPhotoBarButtonItem.m
//  DLPhotoPicker
//
//

#import "DLPhotoBarButtonItem.h"

@implementation DLPhotoBarButtonItem

- (instancetype)initWithFrame:(CGRect)frame{
    if(self = [super initWithFrame:frame]){
        [self setup];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder{
    if(self = [super initWithCoder:aDecoder]){
        [self setup];
    }
    return self;
}

- (void)setup{
    self.layer.masksToBounds = YES;
}

- (UIEdgeInsets)alignmentRectInsets
{
    UIEdgeInsets insets;
    if([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0){
        if([self isLeftButton]){
            insets = UIEdgeInsetsMake(0, 13, 0, 0);
        }else{
            insets = UIEdgeInsetsMake(0, 0, 0, 13);
        }
    }else{
        insets = UIEdgeInsetsZero;
    }
    return insets;
}

- (void)setHighlighted:(BOOL)highlighted{
    if(highlighted){
        self.alpha = 0.5;
    }else{
        self.alpha = 1.0;
    }
    
    [super setHighlighted:highlighted];
}

- (void)setEnabled:(BOOL)enabled{
    if(enabled){
        self.alpha = 1.0;
    }else{
        self.alpha = 0.5;
    }
    [super setEnabled:enabled];
}

- (void)setSelected:(BOOL)selected{
    if(selected != self.isSelected){
        [super setSelected:selected];
    
        if(selected && [self imageForState:UIControlStateSelected] != nil){
            [self executeAnimationWithDuration:0.25];
        }
    }
}

- (void)executeAnimationWithDuration:(CFTimeInterval)duration{
    [self.layer removeAnimationForKey:@"AnimationForTransform"];
    CAKeyframeAnimation *keyframeAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
    NSValue *value0 = [NSValue valueWithCATransform3D:CATransform3DMakeScale(1.0, 1.0, 1.0)];
    NSValue *value1 = [NSValue valueWithCATransform3D:CATransform3DMakeScale(1.3, 1.3, 1.3)];
    NSValue *value2 = [NSValue valueWithCATransform3D:CATransform3DMakeScale(1.0, 1.0, 1.0)];
    NSArray *values = @[value0, value1, value2];
    keyframeAnimation.values = values;
    keyframeAnimation.duration = duration;
    keyframeAnimation.repeatCount = 0;
    [self.layer addAnimation:keyframeAnimation forKey:@"AnimationForTransform"];
}

@end
