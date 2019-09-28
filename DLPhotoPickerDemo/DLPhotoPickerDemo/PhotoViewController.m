//
//  PhotoViewController.m
//  DLPhotoPickerDemo
//
//  Created by 沧海无际 on 16/2/23.
//  Copyright © 2016年 darling0825. All rights reserved.
//

#import "PhotoViewController.h"
#import "DLPhotoPicker.h"
#import "PhotoPickerViewController.h"

@interface PhotoViewController ()<UINavigationControllerDelegate,DLPhotoPickerViewControllerDelegate>
@property (nonatomic, copy) NSArray *assets;

@property (nonatomic, strong) UIColor *color1;
@property (nonatomic, strong) UIColor *color2;
@property (nonatomic, strong) UIColor *color3;
@property (nonatomic, strong) UIFont *font;
@end

@implementation PhotoViewController

/*
 *  appearance
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // set appearance
    // for demo purpose. you might put the code in app delegate's application:didFinishLaunchingWithOptions: method
    self.color1 = [UIColor colorWithRed:102.0/255.0 green:161.0/255.0 blue:130.0/255.0 alpha:1];
    self.color2 = [UIColor colorWithRed:60.0/255.0 green:71.0/255.0 blue:75.0/255.0 alpha:1];
    self.color3 = [UIColor colorWithWhite:0.9 alpha:1];
    self.font   = [UIFont fontWithName:@"Futura-Medium" size:22.0];
    
    // Navigation Bar apperance
    UINavigationBar *navBar = [UINavigationBar appearanceWhenContainedIn:[DLPhotoPickerViewController class], nil];
    
    // set nav bar style to black to force light content status bar style
    navBar.barStyle = UIBarStyleBlack;
    
    // bar tint color
    navBar.barTintColor = self.color1;
    
    // tint color
    navBar.tintColor = self.color2;
    
    // title
    navBar.titleTextAttributes =
    @{NSForegroundColorAttributeName: self.color2,
      NSFontAttributeName : self.font};
    
    // bar button item appearance
    UIBarButtonItem *barButtonItem = [UIBarButtonItem appearanceWhenContainedIn:[DLPhotoPickerViewController class], nil];
    [barButtonItem setTitleTextAttributes:@{NSFontAttributeName : [self.font fontWithSize:18.0]}
                                 forState:UIControlStateNormal];
    
    // albums view
    UITableView *assetCollectionView = [UITableView appearanceWhenContainedIn:[DLPhotoPickerViewController class], nil];
    assetCollectionView.backgroundColor = self.color2;
    
    // asset collection appearance
    DLPhotoCollectionViewCell *assetCollectionViewCell = [DLPhotoCollectionViewCell appearance];

    assetCollectionViewCell.backgroundColor = self.color3;
    
    // grid view
    DLPhotoBackgroundView *assetsGridView = [DLPhotoBackgroundView appearance];
    assetsGridView.gridBackgroundColor = self.color3;
    
    // assets grid footer apperance
    DLPhotoCollectionViewFooter *assetsGridViewFooter = [DLPhotoCollectionViewFooter appearance];
    assetsGridViewFooter.font = [self.font fontWithSize:16.0];
    assetsGridViewFooter.textColor = self.color2;
    
    // grid view cell
    DLPhotoCollectionViewCell *assetsGridViewCell = [DLPhotoCollectionViewCell appearance];
    assetsGridViewCell.highlightedColor = [UIColor colorWithWhite:1 alpha:0.3];
    
    // selected grid view
    DLPhotoCollectionSelectedView *assetsGridSelectedView = [DLPhotoCollectionSelectedView appearance];
    assetsGridSelectedView.selectedBackgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
    assetsGridSelectedView.tintColor = self.color1;
    assetsGridSelectedView.borderWidth = 3.0;
    
    // check mark
    DLPhotoCheckmark *checkmark = [DLPhotoCheckmark appearance];
    checkmark.tintColor = self.color1;
    [checkmark setMargin:0.0 forVerticalEdge:NSLayoutAttributeRight horizontalEdge:NSLayoutAttributeTop];
    
    // page view (preview)
    DLPhotoPageView *assetsPageView = [DLPhotoPageView appearance];
    assetsPageView.pageBackgroundColor = self.color3;
    assetsPageView.fullscreenBackgroundColor = self.color2;
    
    // progress view
    [UIProgressView appearanceWhenContainedIn:[DLPhotoPickerViewController class], nil].tintColor = self.color1;
    
}

- (void)dealloc
{
    // reset appearance
    // for demo purpose. it is not necessary to reset appearance in real case.
    UINavigationBar *navBar = [UINavigationBar appearanceWhenContainedIn:[DLPhotoPickerViewController class], nil];
    
    navBar.barStyle = UIBarStyleDefault;
    navBar.barTintColor = nil;
    navBar.tintColor = nil;
    navBar.titleTextAttributes = nil;
    
    UIBarButtonItem *barButtonItem = [UIBarButtonItem appearanceWhenContainedIn:[DLPhotoPickerViewController class], nil];
    [barButtonItem setTitleTextAttributes:nil
                                 forState:UIControlStateNormal];
    
    UITableView *assetCollectionView = [UITableView appearanceWhenContainedIn:[DLPhotoPickerViewController class], nil];
    assetCollectionView.backgroundColor = [UIColor whiteColor];
    
    DLPhotoCollectionViewCell *assetCollectionViewCell = [DLPhotoCollectionViewCell appearance];
    assetCollectionViewCell.backgroundColor = nil;
    
    DLPhotoBackgroundView *assetsGridView = [DLPhotoBackgroundView appearance];
    assetsGridView.gridBackgroundColor = nil;
    
    DLPhotoCollectionViewFooter *assetsGridViewFooter = [DLPhotoCollectionViewFooter appearance];
    assetsGridViewFooter.font = nil;
    assetsGridViewFooter.textColor = nil;
    
    DLPhotoCollectionViewCell *assetsGridViewCell = [DLPhotoCollectionViewCell appearance];
    assetsGridViewCell.highlightedColor = nil;
    
    DLPhotoCollectionSelectedView *assetsGridSelectedView = [DLPhotoCollectionSelectedView appearance];
    assetsGridSelectedView.selectedBackgroundColor = nil;
    assetsGridSelectedView.tintColor = nil;
    assetsGridSelectedView.borderWidth = 0.0;
    
    DLPhotoCheckmark *checkmark = [DLPhotoCheckmark appearance];
    checkmark.tintColor = nil;
    [checkmark setMargin:0.0 forVerticalEdge:NSLayoutAttributeRight horizontalEdge:NSLayoutAttributeBottom];
    
    DLPhotoPageView *assetsPageView = [DLPhotoPageView appearance];
    assetsPageView.pageBackgroundColor = nil;
    assetsPageView.fullscreenBackgroundColor = nil;
    
    [UIProgressView appearanceWhenContainedIn:[DLPhotoPickerViewController class], nil].tintColor = nil;
}
*/


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)clickPhotoDisplayAction:(id)sender {
    DLPhotoPickerViewController *picker = [[DLPhotoPickerViewController alloc] init];
    picker.delegate = self;
    picker.showsLeftCancelButton = YES;
    picker.showsNumberOfAssets = YES;
    picker.navigationTitle = NSLocalizedString(@"Albums", nil);
    picker.pickerType = DLPhotoPickerTypeDisplay;
    picker.showsEmptyAlbums = NO;
    
    
    
    // only show certain albums (iCloud shared photo stream)
    /*
    picker.assetCollectionSubtypes =
    @[[NSNumber numberWithInt:PHAssetCollectionSubtypeAlbumCloudShared]];
    
    // create options for fetching asset collection (sort by asset count)
    PHFetchOptions *fetchOptions = [PHFetchOptions new];
    fetchOptions.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"estimatedAssetCount" ascending:NO]];
    
    // assign options
    picker.assetCollectionFetchOptions = fetchOptions;
    */
    
    
    
    // create options for fetching slo-mo videos only
    /*
    PHFetchOptions *assetsFetchOptions = [PHFetchOptions new];
    assetsFetchOptions.predicate = [NSPredicate predicateWithFormat:@"(mediaSubtype & %d) != 0", PHAssetMediaSubtypeVideoHighFrameRate];
    
    // assign options
    picker.assetsFetchOptions = assetsFetchOptions;
    */
    
    
    
    // create NSDate of last week
    /*
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:[NSDate date]];
    components.day -= 7;
    NSDate *lastWeek  = [calendar dateFromComponents:components];
    
    // create options for fetching assets taken within this week
    PHFetchOptions *fetchOptions = [PHFetchOptions new];
    fetchOptions.predicate = [NSPredicate predicateWithFormat:@"(creationDate >= %@)", lastWeek];
    
    // assign options
    picker.assetsFetchOptions = fetchOptions;
    */
    
    
    
    // create options for fetching photo only
    /*
    PHFetchOptions *fetchOptions = [PHFetchOptions new];
    fetchOptions.predicate = [NSPredicate predicateWithFormat:@"mediaType == %d", PHAssetMediaTypeImage];
    
    // assign options
    picker.assetsFetchOptions = fetchOptions;
    */
    
    
    
    // create options for fetching assets collection (sort by date desendingly)
    /*
    PHFetchOptions *fetchOptions = [PHFetchOptions new];
    fetchOptions.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
    
    // assign options
    picker.assetsFetchOptions = fetchOptions;
    */

    
    [self presentViewController:picker animated:YES completion:nil];
}

- (IBAction)clickPhotoPickerAction:(id)sender {
    PhotoPickerViewController *picker = [[PhotoPickerViewController alloc] init];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:picker];
    [self presentViewController:nav animated:NO completion:nil];
}



/*
- (UICollectionViewLayout *)pickerController:(DLPhotoPickerViewController *)picker collectionViewLayoutForContentSize:(CGSize)contentSize traitCollection:(UITraitCollection *)trait
{
    UICollectionViewFlowLayout *layout = [UICollectionViewFlowLayout new];
    layout.itemSize = CGSizeMake(175, 175);
    layout.minimumInteritemSpacing = 8;
    layout.minimumLineSpacing = 8;
    layout.sectionInset = UIEdgeInsetsMake(8, 8, 8, 8);
    
    layout.footerReferenceSize = CGSizeMake(contentSize.width, 60);
    
    return (UICollectionViewLayout *)layout;
}
*/


-(void)pickerController:(DLPhotoPickerViewController *)picker didFinishPickingAssets:(NSArray *)assets
{
    [self dismissViewControllerAnimated:YES completion:nil];
    
    self.assets = [NSArray arrayWithArray:assets];
    
    // to operation with 'self.assets'
}

- (BOOL)pickerController:(DLPhotoPickerViewController *)picker shouldScrollToBottomForPhotoCollection:(DLPhotoCollection *)assetCollection;
{
    return YES;
}

- (BOOL)pickerController:(DLPhotoPickerViewController *)picker shouldEnableAsset:(DLPhotoAsset *)asset
{
    return YES;
}

- (BOOL)pickerController:(DLPhotoPickerViewController *)picker shouldSelectAsset:(DLPhotoAsset *)asset
{
    /*
    NSInteger max = 3;
    
    // show alert gracefully
    if (picker.selectedAssets.count >= max)
    {
        UIAlertController *alert =
        [UIAlertController alertControllerWithTitle:@"Attention"
                                            message:[NSString stringWithFormat:@"Please select not more than %ld assets", (long)max]
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *action =
        [UIAlertAction actionWithTitle:@"OK"
                                 style:UIAlertActionStyleDefault
                               handler:nil];
        
        [alert addAction:action];
        
        [picker presentViewController:alert animated:YES completion:nil];
    }
    
    // limit selection to max
    return (picker.selectedAssets.count < max);
     */
    
    return YES;
}

- (void)pickerController:(DLPhotoPickerViewController *)picker didSelectAsset:(DLPhotoAsset *)asset
{
    
}

- (BOOL)pickerController:(DLPhotoPickerViewController *)picker shouldDeselectAsset:(DLPhotoAsset *)asset
{
    return YES;
}

- (void)pickerController:(DLPhotoPickerViewController *)picker didDeselectAsset:(DLPhotoAsset *)asset
{
    
}

- (BOOL)pickerController:(DLPhotoPickerViewController *)picker shouldHighlightAsset:(DLPhotoAsset *)asset
{
    return YES;
}

- (void)pickerController:(DLPhotoPickerViewController *)picker didHighlightAsset:(DLPhotoAsset *)asset
{
    
}
@end
