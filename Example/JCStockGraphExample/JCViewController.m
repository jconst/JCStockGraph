//
//  JCViewController.m
//  JCStockGraphExample
//
//  Created by Joseph Constantakis on 5/4/14.
//  Copyright (c) 2014 Joseph Constan. All rights reserved.
//

#import "JCViewController.h"
#import "JCStockGraphPageController.h"

@interface JCViewController ()

@property (strong, nonatomic) JCStockGraphPageController *graphPageController;

@end

@implementation JCViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    self.graphPageController = [[JCStockGraphPageController alloc] initWithTicker:@"AAPL"];

    self.graphPageController.view.frame           = CGRectMake(0, 100, 320, 100);
    self.graphPageController.graphOffset          = CGPointMake(8, 0);
    self.graphPageController.graphSize            = CGSizeMake(290, 90);
    self.graphPageController.graphOptions         = kGraphOptionSmoothGraph | kGraphOptionHideXAxis | kGraphOptionHideGrid;
    self.graphPageController.shouldAutoscroll     = YES;
    self.graphPageController.shouldShowRotateHint = NO;
    
    [self.view addSubview:self.graphPageController.view];
}

@end
