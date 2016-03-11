//
//  AssetActivityProvider.h
//  AssetActivityProvider
//
//  Created by 沧海无际 on 16/3/8.
//  Copyright © 2016年 darling0825. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DLPhotoAsset.h"

@interface AssetActivityProvider : NSObject <UIActivityItemSource>//UIActivityItemProvider
- (id)initWithAsset:(DLPhotoAsset *)asset;
- (void)cleanup;
@end
