//
//  DLPhotoTableViewController.m
//  DLPhotoPicker
//
//  Created by 沧海无际 on 16/2/20.
//  Copyright © 2016年 darling0825. All rights reserved.
//

#import "DLPhotoTableViewController.h"
#import "DLPhotoTableViewCell.h"
#import "DLPhotoPickerViewController.h"
#import "DLPhotoCollectionViewController.h"
#import "DLPhotoCollection.h"
#import "DLPhotoPickerDefines.h"

static NSString *cellIdentifier = @"CellIdentifier";

@interface DLPhotoTableViewController ()

@end


@implementation DLPhotoTableViewController

- (instancetype)init
{
    if (self = [super initWithStyle:UITableViewStylePlain]){
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self setupViews];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)setupViews
{
    self.tableView.backgroundColor = DLPhotoTableViewBackgroundColor;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = DLPhotoCollectionThumbnailSize.height + self.tableView.layoutMargins.top + self.tableView.layoutMargins.bottom;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    [self.tableView registerClass:[DLPhotoTableViewCell class] forCellReuseIdentifier:cellIdentifier];
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.assetCollections count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    DLPhotoCollection *collection = self.assetCollections[indexPath.row];
    NSUInteger count = 0;
    
    if (self.picker.showsNumberOfAssets)
        count = collection.count;
    else
        count = NSNotFound;

    DLPhotoTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    [cell bind:collection count:count];
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    DLPhotoCollection *collection = self.assetCollections[indexPath.row];
    DLPhotoCollectionViewController *photoCollectionViewController = [[DLPhotoCollectionViewController alloc] init];
    photoCollectionViewController.picker = self.picker;
    photoCollectionViewController.photoCollection = collection;
    
    [self.navigationController pushViewController:photoCollectionViewController animated:YES];
}


@end
