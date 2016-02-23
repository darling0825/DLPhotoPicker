//
//  DLPhotoPickerViewController.m
//  DLPhotoPicker
//
//  Created by 沧海无际 on 16/2/20.
//  Copyright © 2016年 darling0825. All rights reserved.
//

#import "DLPhotoPickerViewController.h"
#import "DLPhotoPickerDefines.h"
#import "DLPhotoManager.h"
#import "DLPhotoPickerAccessDeniedView.h"
#import "DLPhotoPickerNoAssetsView.h"
#import "DLPhotoTableViewController.h"

@interface DLPhotoPickerViewController ()<DLPhotoManagerDelegate>


@end

@implementation DLPhotoPickerViewController

-(instancetype)init
{
    self = [super init];
    if (self) {
        _showsNumberOfAssets = YES;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = DLPhotoWhiteBackgroundColor;
    
    [self showPhotoCollection];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)showPhotoCollection
{
    DLPhotoManager *photoManager = [DLPhotoManager sharedInstance];
    photoManager.delegate = self;
    [photoManager checkAuthorizationStatus];
}

#pragma mark - DLPhotoManagerDelegate
- (void)accessDenied
{
    [self showOtherView:[DLPhotoPickerAccessDeniedView new]];
}

- (void)haveNonePhotoCollection
{
    [self showOtherView:[DLPhotoPickerNoAssetsView new]];
}

- (void)getAlbumsSuccess
{
    DLPhotoTableViewController *albumTableViewController = [[DLPhotoTableViewController alloc] init];
    albumTableViewController.picker = self;
    albumTableViewController.assetCollections = [NSArray arrayWithArray:[DLPhotoManager sharedInstance].assetCollections];
    albumTableViewController.navigationItem.title = self.navigationTitle;;
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:albumTableViewController];
    
    [nav willMoveToParentViewController:self];
    [nav.view setFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    [self.view addSubview:nav.view];
    [self addChildViewController:nav];
    [nav didMoveToParentViewController:self];
}

#pragma mark - Show view
- (void)showOtherView:(UIView *)view
{
    [self removeChildViewController];
    
    UIViewController *vc = [self emptyViewController];
    
    [vc.view addSubview:view];
    [view setNeedsUpdateConstraints];
    [view updateConstraintsIfNeeded];
    
    [self setupChildViewController:vc];
}

#pragma mark - Setup view controllers
- (UIViewController *)emptyViewController
{
    UIViewController *vc                = [UIViewController new];
    vc.view.backgroundColor             = [UIColor whiteColor];
    vc.navigationItem.hidesBackButton   = YES;
    
    return vc;
}

- (void)setupChildViewController:(UIViewController *)vc
{
    [vc willMoveToParentViewController:self];
    [vc.view setFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    [self.view addSubview:vc.view];
    [self addChildViewController:vc];
    [vc didMoveToParentViewController:self];
}

- (void)removeChildViewController
{
    UIViewController *vc = self.childViewControllers.firstObject;
    [vc.view removeFromSuperview];
    [vc removeFromParentViewController];
}

@end
