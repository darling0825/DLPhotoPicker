//
//  PhotoViewController.m
//  DLPhotoPickerDemo
//
//  Created by 沧海无际 on 16/2/23.
//  Copyright © 2016年 darling0825. All rights reserved.
//

#import "PhotoViewController.h"
#import <DLPhotoPicker/DLPhotoPicker.h>
#import "PhotoPickerViewController.h"

@interface PhotoViewController ()<DLPhotoPickerViewControllerDelegate>
@property (nonatomic, copy) NSArray *assets;
@end

@implementation PhotoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)clickPhotoDisplayAction:(id)sender {
    DLPhotoPickerViewController *pickerController = [[DLPhotoPickerViewController alloc] init];
    pickerController.delegate = self;
    pickerController.navigationTitle = NSLocalizedString(@"Photo Library", nil);
    pickerController.pickerType = DLPhotoPickerTypeDisplay;
    [self presentViewController:pickerController animated:YES completion:nil];
}

- (IBAction)clickPhotoPickerAction:(id)sender {
    PhotoPickerViewController *pickerController = [[PhotoPickerViewController alloc] init];
    [self.navigationController pushViewController:pickerController animated:YES];
}

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
@end
