//
//  ViewController.m
//  DLPhotoPickerDemo
//
//  Created by 沧海无际 on 16/2/23.
//  Copyright © 2016年 darling0825. All rights reserved.
//

#import "ViewController.h"
#import <DLPhotoPicker/DLPhotoPicker.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)clickStartAction:(id)sender {
    DLPhotoPickerViewController *pickerController = [[DLPhotoPickerViewController alloc] init];
    pickerController.navigationTitle = @"Photo Library";
    //    [self.navigationController pushViewController:pickerController animated:YES];
    [self presentViewController:pickerController animated:YES completion:nil];
}

@end
