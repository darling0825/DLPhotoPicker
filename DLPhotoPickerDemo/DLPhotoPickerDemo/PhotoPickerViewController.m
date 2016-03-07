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

#import "PhotoPickerViewController.h"


#define TableViewRowHeight 120.0f


@implementation PhotoPickerViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIBarButtonItem *clearButton =
    [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Clear", nil)
                                     style:UIBarButtonItemStylePlain
                                    target:self
                                    action:@selector(clearAssets:)];
    
    
    UIBarButtonItem *addButton =
    [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Pick", nil)
                                     style:UIBarButtonItemStylePlain
                                    target:self
                                    action:@selector(pickAssets:)];
    
    UIBarButtonItem *space =
    [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    self.toolbarItems = @[clearButton, space, addButton];
    self.tableView.rowHeight = TableViewRowHeight;
    
    
    // init properties
    self.assets = [[NSMutableArray alloc] init];

    self.dateFormatter = [[NSDateFormatter alloc] init];
    self.dateFormatter.dateStyle = NSDateFormatterMediumStyle;
    self.dateFormatter.timeStyle = NSDateFormatterMediumStyle;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setToolbarHidden:NO animated:YES];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.navigationController setToolbarHidden:YES animated:YES];
}

- (void)clearAssets:(id)sender
{
    self.assets = [[NSMutableArray alloc] init];
    [self.tableView reloadData];
}

- (void)pickAssets:(id)sender
{
    DLPhotoPickerViewController *picker = [[DLPhotoPickerViewController alloc] init];
    picker.delegate = self;
    picker.pickerType = DLPhotoPickerTypePicker;
    picker.navigationTitle = NSLocalizedString(@"Albums", nil);
    
//    // create options for fetching slo-mo videos only
//    PHFetchOptions *assetsFetchOptions = [PHFetchOptions new];
//    assetsFetchOptions.predicate = [NSPredicate predicateWithFormat:@"(mediaSubtype & %d) != 0", PHAssetMediaSubtypeVideoHighFrameRate];
//    // assign options
//    picker.assetsFetchOptions = assetsFetchOptions;
    
    [self presentViewController:picker animated:YES completion:nil];
}

#pragma mark - DLPhotoPickerViewControllerDelegate
- (void)pickerControllerDidCancel:(DLPhotoPickerViewController *)picker
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)pickerController:(DLPhotoPickerViewController *)picker didFinishPickingAssets:(NSArray *)assets
{
    [self dismissViewControllerAnimated:YES completion:nil];
    
    self.assets = [NSArray arrayWithArray:assets];
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.assets.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    
    if (cell == nil)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Cell"];

    DLPhotoAsset *asset                         = [self.assets objectAtIndex:indexPath.row];
    cell.textLabel.numberOfLines                = 0;
    cell.textLabel.text                         = asset.fileName;
    cell.textLabel.font                         = [UIFont systemFontOfSize:11.0];
    cell.textLabel.textColor                    = [UIColor redColor];
    NSString *fileSizeStr = [NSByteCountFormatter stringFromByteCount:asset.fileSize
                                                           countStyle:NSByteCountFormatterCountStyleFile];
    cell.detailTextLabel.numberOfLines              = 0;
    cell.detailTextLabel.font                       = [UIFont systemFontOfSize:9.0];
    cell.detailTextLabel.text   = [NSString stringWithFormat:@"%d X %d  %@\n%@\n%@",
                                   (int)asset.assetdimensions.width,
                                   (int)asset.assetdimensions.height,
                                   fileSizeStr,
                                   [self.dateFormatter stringFromDate:asset.createDate],
                                   asset.url];
    
    cell.accessoryType          = UITableViewCellAccessoryDisclosureIndicator;
    cell.clipsToBounds          = YES;

    CGFloat scale = UIScreen.mainScreen.scale;
    CGSize targetSize = CGSizeMake(TableViewRowHeight/2 * scale, TableViewRowHeight/2 * scale);

    [asset requestThumbnailImageWithSize:targetSize completion:^(UIImage *image, NSDictionary *info) {
        cell.imageView.image = image;
        [cell setNeedsLayout];
        [cell layoutIfNeeded];
    }];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    DLPhotoPageViewController *vc = [[DLPhotoPageViewController alloc] initWithAssets:self.assets];
    vc.pageIndex = indexPath.row;
    
    [self.navigationController pushViewController:vc animated:YES];
}


#pragma mark - Assets Picker Delegate

- (void)assetsPickerController:(DLPhotoPickerViewController *)picker didFinishPickingAssets:(NSArray *)assets
{
    [picker dismissViewControllerAnimated:YES completion:nil];

    self.assets = [NSMutableArray arrayWithArray:assets];
    [self.tableView reloadData];
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
