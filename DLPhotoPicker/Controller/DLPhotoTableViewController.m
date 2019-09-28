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
#import "DLPhotoManager.h"
#import "NSBundle+DLPhotoPicker.h"
#import "DLProgressHud.h"

static NSString *cellIdentifier = @"CellIdentifier";

@interface DLPhotoTableViewController ()
<PHPhotoLibraryChangeObserver, UIAlertViewDelegate, UITextFieldDelegate, DLPhotoCollectionViewControllerDelegate>

@property (nonatomic, strong)DLPhotoCollection *selectedPhotoCollection;
@property (nonatomic, weak)DLPhotoCollectionViewController *photoCollectionViewController;
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
    [self setupButtons];

    [self fetchPhotoCollectionAndReload];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillEnterForeground:)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];

    [self registerChangeObserver];
    [self addKeyValueObserver];

    [self setupPhotoCollection];
    [self.tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [self unregisterChangeObserver];
    [self removeKeyValueObserver];
}

- (void)applicationWillEnterForeground:(NSNotification *)notification {
    [self fetchPhotoCollectionAndReload];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    self.photoCollections = nil;
    self.selectedPhotoCollection = nil;
    self.photoCollectionViewController = nil;
}

#pragma mark -
- (void)setupViews
{
    self.tableView.backgroundColor = DLPhotoTableViewBackgroundColor;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = DLPhotoCollectionThumbnailSize.height + self.tableView.layoutMargins.top + self.tableView.layoutMargins.bottom;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.cellLayoutMarginsFollowReadableWidth = NO;
    
    [self.tableView registerClass:[DLPhotoTableViewCell class] forCellReuseIdentifier:cellIdentifier];
}

- (void)setupButtons
{
    if (self.picker.pickerType == DLPhotoPickerTypePicker) {
        self.navigationItem.rightBarButtonItem =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                      target:self
                                                      action:@selector(clickCancelSelectAction:)];
    }else if (self.picker.pickerType == DLPhotoPickerTypeDisplay){
        if (self.showsLeftCancelButton) {
            UIBarButtonItem *add =
            [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                          target:self
                                                          action:@selector(clickAddAlbumAction:)];
            
            UIBarButtonItem *edit =
            [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit
                                                          target:self
                                                          action:@selector(clickEditAlbumAction:)];
            self.navigationItem.rightBarButtonItems = @[add, edit];
            
            self.navigationItem.leftBarButtonItem =
            [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                          target:self
                                                          action:@selector(clickLeftCancelAction:)];
        }else {
            self.navigationItem.leftBarButtonItem =
            [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                          target:self
                                                          action:@selector(clickAddAlbumAction:)];
            
            self.navigationItem.rightBarButtonItem =
            [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit
                                                          target:self
                                                          action:@selector(clickEditAlbumAction:)];
        }
    }else{
    }
}

#pragma mark -
- (void)fetchPhotoCollectionAndReload
{
    [DLProgressHud showActivity];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[DLPhotoManager sharedInstance] fetchPhotoCollection:^(BOOL success) {
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [DLProgressHud dismiss];
                
                if (success) {
                    [self setupPhotoCollection];
                    [self.tableView reloadData];
                }else{
                    NSLog(@">>> Fetch photo collection failed!");
                }
            });
        }];
    });
}

- (void)setupPhotoCollection
{
    self.photoCollections = [NSMutableArray arrayWithArray:[[DLPhotoManager sharedInstance] photoCollections]];
}

#pragma mark -
- (NSIndexPath *)indexPathForPhotoCollection:(DLPhotoCollection *)photoCollection
{
    NSInteger row = [self.photoCollections indexOfObject:photoCollection];
    
    if (row != NSNotFound)
        return [NSIndexPath indexPathForRow:row inSection:0];
    else
        return nil;
}

#pragma mark - Photo library change observer
- (void)registerChangeObserver
{
    [[DLPhotoManager sharedInstance] registerChangeObserver:self];
}

- (void)unregisterChangeObserver
{
    [[DLPhotoManager sharedInstance] unregisterChangeObserver:self];
}

#pragma mark - Photo library changed
// >= iOS 8
- (void)photoLibraryDidChange:(PHChange *)changeInstance
{
    // Call might come on any background queue. Re-dispatch to the main queue to handle it.
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong typeof(self) strongSelf = weakSelf;
        
        __block BOOL partialReloadRequired = NO;
        NSArray *fetchResults = [[[DLPhotoManager sharedInstance] fetchResults] copy];
        NSMutableArray *updatedFetchResults = [fetchResults mutableCopy];
        
        // Loop through the section fetch results, replacing any fetch results that have been updated.
        [fetchResults enumerateObjectsUsingBlock:^(PHFetchResult *collectionsFetchResult, NSUInteger index, BOOL *stop) {
            PHFetchResultChangeDetails *changeDetails = [changeInstance changeDetailsForFetchResult:collectionsFetchResult];
            
            if (changeDetails != nil) {
                [updatedFetchResults replaceObjectAtIndex:index withObject:[changeDetails fetchResultAfterChanges]];
                partialReloadRequired = YES;
            }
        }];
        
        if (partialReloadRequired){
            //  Call setFetchResults will reset photoCollections of DLPhotoManager
            [[DLPhotoManager sharedInstance] setFetchResults:updatedFetchResults];
            
            //  Need reset self.photoCollections
            [self setupPhotoCollection];
            
            [self.tableView reloadData];
        }else{
            /** 
             *  Fix Bug:
             *  This method -changeDetailsForFetchResult always returns nil,
             *  when taking a screenshot using the Home- and the Lock-Button of the iDevice.
             *  http://stackoverflow.com/questions/32948744/phchange-changedetailsforfetchresult-always-returns-nil
             */
            [self fetchPhotoCollectionAndReload];
        }
        
        
        __block BOOL selectedPhotoCollectionIsExist = NO;
        NSArray *collections = [NSArray arrayWithArray:self.photoCollections];
        [collections enumerateObjectsUsingBlock:^(DLPhotoCollection *obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([strongSelf.selectedPhotoCollection isEqual:obj]) {
                selectedPhotoCollectionIsExist = YES;
                *stop = YES;
            }
        }];
        
        if (strongSelf.photoCollectionViewController &&
            (!selectedPhotoCollectionIsExist || strongSelf.selectedPhotoCollection.count == 0)){
            //back to tableview
            [strongSelf.navigationController popViewControllerAnimated:YES];
        }
        else{
        }
    });
}

#pragma mark - Helper methods
- (NSDictionary *)queryStringToDictionaryOfNSURL:(NSURL *)url
{
    NSArray *urlComponents = [url.query componentsSeparatedByString:@"&"];
    if (urlComponents.count <= 0)
    {
        return nil;
    }
    NSMutableDictionary *queryDict = [NSMutableDictionary dictionary];
    for (NSString *keyValuePair in urlComponents)
    {
        NSArray *pairComponents = [keyValuePair componentsSeparatedByString:@"="];
        [queryDict setObject:pairComponents[1] forKey:pairComponents[0]];
    }
    return [queryDict copy];
}


#pragma mark - Key-Value observer
- (void)addKeyValueObserver
{
    [self addObserver:self
           forKeyPath:@"photoCollections"
              options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
              context:nil];
}

- (void)removeKeyValueObserver
{
    @try {
        [self removeObserver:self forKeyPath:@"photoCollections"];
    }
    @catch (NSException *exception) {
        // do nothing
    }
}

#pragma mark - Key-Value changed
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqual:@"photoCollections"]){
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    }
}

#pragma mark - KVO Implementation For NSArray
- (void)insertObject:(id)object inPhotoCollectionsAtIndex:(NSUInteger)index
{
    [self.photoCollections insertObject:object atIndex:index];
}

- (void)removeObjectFromPhotoCollectionsAtIndex:(NSUInteger)index
{
    [self.photoCollections removeObjectAtIndex:index];
}

- (void)replaceObjectInPhotoCollectionsAtIndex:(NSUInteger)index withObject:(DLPhotoCollection *)object
{
    [self.photoCollections replaceObjectAtIndex:index withObject:object];
}

#pragma mark - Button Action
-(void)clickLeftCancelAction:(UIBarButtonItem *)sender
{
    [self.picker dismissViewControllerAnimated:YES completion:nil];
}

-(void)clickCancelSelectAction:(UIBarButtonItem *)sender
{
    if ([self.picker.delegate respondsToSelector:@selector(pickerControllerDidCancel:)]){
        [self.picker.delegate pickerControllerDidCancel:self.picker];
    }
}

-(void)clickAddAlbumAction:(UIBarButtonItem *)sender
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:DLPhotoPickerLocalizedString(@"New Album",nil)
                                                        message:DLPhotoPickerLocalizedString(@"Enter a name for this album.",nil)
                                                       delegate:self
                                              cancelButtonTitle:DLPhotoPickerLocalizedString(@"Cancel",nil)
                                              otherButtonTitles:DLPhotoPickerLocalizedString(@"OK",nil), nil];
    alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    UITextField *textField = [alertView textFieldAtIndex:0];
    textField.placeholder = DLPhotoPickerLocalizedString(@"Title",nil);
    textField.delegate = self;
    [alertView show];
}

-(void)clickEditAlbumAction:(UIBarButtonItem *)sender
{
    
    [self.tableView setEditing:YES animated:YES];
    
    self.navigationItem.rightBarButtonItem =
    [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                  target:self
                                                  action:@selector(clickCancelEditAlbumAction:)];
}

-(void)clickCancelEditAlbumAction:(UIBarButtonItem *)sender
{
    [self.tableView setEditing:NO animated:YES];
    
    self.navigationItem.rightBarButtonItem =
    [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit
                                                  target:self
                                                  action:@selector(clickEditAlbumAction:)];
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        UITextField *textField = [alertView textFieldAtIndex:0];
        if (textField.text.length) {
            
            void (^completion)(NSError *) = ^(NSError *error){
                NSString *message = nil;
                if (error) {
                    message = [NSString stringWithFormat:@"%@",error];
                }
                
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:DLPhotoPickerLocalizedString(@"Create album failed!",nil)
                                                                    message:message
                                                                   delegate:nil
                                                          cancelButtonTitle:DLPhotoPickerLocalizedString(@"OK",nil)
                                                          otherButtonTitles:nil];
                [alertView show];
            };
            
            [[DLPhotoManager sharedInstance] createAlbumWithName:textField.text resultBlock:^(DLPhotoCollection *collection) {
                if (!collection) {
                    completion(nil);
                }
            } failureBlock:^(NSError *error) {
                if (error) {
                    completion(error);
                }
            }];
        }
    }
}

-(BOOL)alertViewShouldEnableFirstOtherButton:(UIAlertView *)alertView
{
    UITextField *textField = [alertView textFieldAtIndex:0];
    if (textField.text.length) {
        return YES;
    }
    return NO;
}

#pragma mark - DLPhotoCollectionViewControllerDelegate
- (void)collectionViewController:(DLPhotoCollectionViewController *)controller photoLibraryDidChangeForPhotoCollection:(DLPhotoCollection *)photoCollection
{
    NSIndexPath *indexPath = [self indexPathForPhotoCollection:photoCollection];
    
    if (indexPath){
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
        [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    }
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.photoCollections count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    DLPhotoCollection *collection = self.photoCollections[indexPath.row];
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
    DLPhotoCollection *collection = self.photoCollections[indexPath.row];
    
    if (collection) {
        DLPhotoCollectionViewController *photoCollectionViewController = [[DLPhotoCollectionViewController alloc] init];
        photoCollectionViewController.delegate = self;
        photoCollectionViewController.photoCollection = collection;
        photoCollectionViewController.hidesBottomBarWhenPushed = self.picker.hidesBottomBarWhenPushedInAssetView;
        
        self.photoCollectionViewController = photoCollectionViewController;
        self.selectedPhotoCollection = collection;
        
        [self.navigationController pushViewController:photoCollectionViewController animated:YES];
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    DLPhotoCollection *collection = self.photoCollections[indexPath.row];
    if (collection.deletable) {
        return UITableViewCellEditingStyleDelete;
    }
    return UITableViewCellEditingStyleNone;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        void (^completion)(NSError *) = ^(NSError *error){
            NSString *message = nil;
            if (error) {
                message = [NSString stringWithFormat:@"%@",error];
            }
            
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:DLPhotoPickerLocalizedString(@"Remove album failed!",nil)
                                                                message:message
                                                               delegate:nil
                                                      cancelButtonTitle:DLPhotoPickerLocalizedString(@"OK",nil)
                                                      otherButtonTitles:nil];
            [alertView show];
        };
        
        DLPhotoCollection *collection = self.photoCollections[indexPath.row];
        [[DLPhotoManager sharedInstance] removeAlbum:collection resultBlock:^(BOOL success) {
            if (success) {
                [self.photoCollections removeObjectAtIndex:indexPath.row];
                [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            }else{
                if (completion) {
                    completion(nil);
                }
            }
        } failureBlock:^(NSError *error) {
            if (completion) {
                completion(error);
            }
        }];
    }
}
@end
