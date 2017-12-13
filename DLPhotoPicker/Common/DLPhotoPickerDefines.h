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

#define dispatch_main_sync_safe(block)\
    if ([NSThread isMainThread]) {\
        block();\
    } else {\
        dispatch_sync(dispatch_get_main_queue(), block);\
    }

#define dispatch_main_async_safe(block)\
    if ([NSThread isMainThread]) {\
        block();\
    } else {\
        dispatch_async(dispatch_get_main_queue(), block);\
    }

/** NSLocalizedString alias*/
#define DLPhotoPickerLocalizedString(key, comment) \
NSLocalizedStringFromTableInBundle((key), @"DLPhotoPicker", [NSBundle assetPickerBundle], (comment))


/** 获取硬件信息*/
#define ScreenScale             UIScreen.mainScreen.scale
#define ScreenWidth             CGRectGetWidth(UIScreen.mainScreen.bounds)
#define ScreenHeight            CGRectGetWidth(UIScreen.mainScreen.bounds)

#define DLCurrentLanguage       ([[NSLocale preferredLanguages] objectAtIndex:0])
#define DLCurrentSystemVersion  [[[UIDevice currentDevice] systemVersion] floatValue]


/** 适配*/

#define DLiOS_5_OR_LATER        ([[[UIDevice currentDevice] systemVersion] floatValue] >= 5.0)
#define DLiOS_6_OR_LATER        ([[[UIDevice currentDevice] systemVersion] floatValue] >= 6.0)
#define DLiOS_7_OR_LATER        ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0)
#define DLiOS_8_OR_LATER        ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)
#define DLiOS_9_OR_LATER        ([[[UIDevice currentDevice] systemVersion] floatValue] >= 9.0)

#define DLiPhone4_OR_4s             (SXSCREEN_H == 480)
#define DLiPhone5_OR_5c_OR_5s       (SXSCREEN_H == 568)
#define DLiPhone6_OR_6s             (SXSCREEN_H == 667)
#define DLiPhone6Plus_OR_6sPlus     (SXSCREEN_H == 736)
#define DLiPad                      (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)


/** 弱指针*/
#define DLWeakSelf(weakSelf)    __weak __typeof(&*self)weakSelf = self;


/** 加载本地文件*/
#define DLLoadImage(file,type)  [UIImage imageWithContentsOfFile:[[NSBundle mainBundle]pathForResource:file ofType:type]]
#define DLLoadArray(file,type)  [UIImage arrayWithContentsOfFile:[[NSBundle mainBundle]pathForResource:file ofType:type]]
#define DLLoadDict(file,type)   [UIImage dictionaryWithContentsOfFile:[[NSBundle mainBundle]pathForResource:file ofType:type]]


/* Default size */
#define DLPhotoCollectionThumbnailLengh             70.0f
#define DLPhotoCollectionThumbnailSize              CGSizeMake(DLPhotoCollectionThumbnailLengh, DLPhotoCollectionThumbnailLengh)
#define DLPhotoPickerPopoverContentSize             CGSizeMake(695.0f, 580.0f)


/* Default appearance */
#define DLPhotoPickerAccessDeniedViewTextColor      [UIColor colorWithRed:129.0f/255.0f green:136.0f/255.0f blue:148.0f/255.0f alpha:1]
#define DLPhotoPickerNoAssetsViewTextColor          [UIColor colorWithRed:153.0f/255.0f green:153.0f/255.0f blue:153.0f/255.0f alpha:1]

#define DLPhotoPickerThumbnailTintColor             [UIColor colorWithRed:164.0f/255.0f green:164.0f/255.0f blue:164.0f/255.0f alpha:1]
#define DLPhotoPickerThumbnailBackgroundColor       [UIColor colorWithRed:235.0f/255.0f green:235.0f/255.0f blue:235.0f/255.0f alpha:1]

#define DLPhotoCollectionViewCellTitleFont          [UIFont preferredFontForTextStyle:UIFontTextStyleBody]
#define DLPhotoCollectionViewCellTitleTextColor     [UIColor darkTextColor]
#define DLPhotoCollectionViewCellCountFont          [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1]
#define DLPhotoCollectionViewCellCountTextColor     [UIColor darkTextColor]
#define DLPhotoCollectionViewCellAccessoryColor     [UIColor colorWithRed:187.0f/255.0f green:187.0f/255.0f blue:193.0f/255.0f alpha:1]

#define DLPhotoWhiteBackgroundColor                 [UIColor whiteColor]
#define DLPhotoCollectionViewBackgroundColor        [UIColor whiteColor]
#define DLPhotoTableViewBackgroundColor             [UIColor whiteColor]

#define DLPhotoCollectionViewCellDisabledColor           [UIColor colorWithWhite:1 alpha:0.8]
#define DLPhotoCollectionViewCellHighlightedColor        [UIColor colorWithWhite:0 alpha:0.5]

#define DLPhotoCollectionSelectedViewBackgroundColor     [UIColor colorWithWhite:1 alpha:0.3]
#define DLPhotoCollectionSelectedViewTintColor           [UIView new].tintColor

#define DLPhotoLabelSize                            CGSizeMake(25.0f, 25.0f)
#define DLPhotoLabelFont                            [UIFont preferredFontForTextStyle:UIFontTextStyleBody]
#define DLPhotoLabelTextColor                       [UIColor whiteColor]
#define DLPhotoLabelBackgroundColor                 [UIView new].tintColor
#define DLPhotoLabelBorderColor                     [UIColor whiteColor]

#define DLPhotoCollectionViewFooterFont             [UIFont preferredFontForTextStyle:UIFontTextStyleBody]
#define DLPhotoCollectionViewFooterTextColor        [UIColor darkTextColor]

#define DLPhotoPageViewPageBackgroundColor          [UIColor whiteColor]
#define DLPhotoPageViewFullscreenBackgroundColor    [UIColor blackColor]



/** end */
