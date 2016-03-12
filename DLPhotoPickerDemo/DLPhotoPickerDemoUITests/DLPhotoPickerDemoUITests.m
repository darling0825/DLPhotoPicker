//
//  DLPhotoPickerDemoUITests.m
//  DLPhotoPickerDemoUITests
//
//  Created by 沧海无际 on 16/3/12.
//  Copyright © 2016年 darling0825. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <UIKit/UIKit.h>
#import "PhotoPickerViewController.h"
#import "PhotoViewController.h"


@interface DLPhotoPickerDemoUITests : XCTestCase

@end

@implementation DLPhotoPickerDemoUITests

- (void)setUp {
    [super setUp];
    
    // Put setup code here. This method is called before the invocation of each test method in the class.
    
    // In UI tests it is usually best to stop immediately when a failure occurs.
    self.continueAfterFailure = YES;
    // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
    [[[XCUIApplication alloc] init] launch];
    
    // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    [XCUIDevice sharedDevice].orientation = UIDeviceOrientationPortrait;
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testDLPhotoPickerTypeDisplay {
    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app.buttons[@"Photo Display"] tap];
    XCTAssert(YES);
}

- (void)testDLPhotoPickerTypePicker {
    
    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app.buttons[@"Photo Picker"] tap];
    [app.toolbars.buttons[@"Pick"] tap];
    XCTAssert(YES);
}

@end
