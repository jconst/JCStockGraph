//
//  StockPriceGraphPageController.m
//  Benzinga
//
//  Created by Joseph Constantakis on 8/12/13.
//  Copyright (c) 2013 Benzinga. All rights reserved.
//

#import "JCStockGraphPageController.h"
#import "MBProgressHUD.h"
#import "FIEntypoIcon.h"
#import "FIIconView.h"
#import "UIView+FrameAccessor.h"

@interface JCStockGraphPageController () {
    MHPagingScrollView *pagingScrollView;
    NSMutableArray *graphControllers;
    NSTimer *autoscrollTimer;
}

@end

@implementation JCStockGraphPageController

- (id)initWithTicker:(NSString *)ticker
{
    self = [super init];
    if (self) {
        self.ticker = ticker;
        graphControllers  = [[NSMutableArray alloc] initWithCapacity:kGraphRangeCount];
        self.graphOptions = kGraphOptionNone;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self reloadViews];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self reloadViews];
}

- (void)reloadViews
{
    if (pagingScrollView) {
        [pagingScrollView removeFromSuperview];
    }
    pagingScrollView                = [[MHPagingScrollView alloc] initWithFrame:self.view.bounds];
    pagingScrollView.delegate       = self;
    pagingScrollView.pagingDelegate = self;
    pagingScrollView.scrollEnabled  = !(self.graphOptions & kGraphOptionInteractive);
    [self.view addSubview:pagingScrollView];
    
    for (JCStockGraphController *gc in graphControllers) {
        [gc removeFromParentViewController];
    }
    [graphControllers removeAllObjects];
    [self loadRemainingPages];
    [pagingScrollView reloadPages];
    
    if (self.shouldShowRotateHint)
        [self setupGestureRecognizers];
}

//recursive function that loads each page one after another
- (void)loadRemainingPages
{
    if (graphControllers.count >= kGraphRangeCount) {
        if (self.shouldAutoscroll)
            [self startAutoscroll];
        return;
    }
    
    JCStockGraphController *graphController = [[JCStockGraphController alloc] initWithTicker:self.ticker];
    //graphController.view.frame            = self.view.bounds;
    graphController.graphOffset             = self.graphOffset;
    graphController.graphSize               = self.graphSize;
    graphController.range                   = (JCStockGraphRange)graphControllers.count;
    graphController.graphOptions            = self.graphOptions;

    [self addChildViewController:graphController];
    [graphController didMoveToParentViewController:self];
    [graphControllers addObject:graphController];
    
    [graphController loadDataWithCompletion:^{
        [pagingScrollView reloadPages];
        [self loadRemainingPages];
    }];
}

- (void)setupGestureRecognizers
{
    //If the user does anything that makes us think "Yeahhhh, this guy has no idea what he's doing",
    //we hint at them that they can rotate to get a bigger, zoomable graph
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showRotateHint)];
    [self.view addGestureRecognizer:tapRecognizer];
    
    UIPinchGestureRecognizer *pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(showRotateHint)];
    [self.view addGestureRecognizer:pinchRecognizer];
    
    UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(showRotateHint)];
    panRecognizer.minimumNumberOfTouches  = 2;
    [self.view addGestureRecognizer:panRecognizer];
    
    UISwipeGestureRecognizer *swipeRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(showRotateHint)];
    swipeRecognizer.numberOfTouchesRequired   = 2;
    [self.view addGestureRecognizer:swipeRecognizer];
}

- (void)showRotateHint
{
    MBProgressHUD *hud       = [[MBProgressHUD alloc] initWithView:self.view];
    hud.mode                 = MBProgressHUDModeCustomView;
    hud.labelText            = @"Rotate to zoom";

    FIIconView *iconView     = [[FIIconView alloc] initWithFrame:CGRectMake(0, 0, 28, 28)];
    iconView.backgroundColor = [UIColor clearColor];
    iconView.icon            = [FIEntypoIcon cwIcon];
    iconView.iconColor       = [UIColor whiteColor];
    hud.customView           = iconView;

    [self.view addSubview:hud];
    [hud show:YES];
    [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(hideRotateHintTimerFired:)
                                   userInfo:@{@"hud": hud} repeats:NO];
}

- (void)hideRotateHintTimerFired:(NSTimer *)timer
{
    MBProgressHUD *hud = timer.userInfo[@"hud"];
    [hud hide:YES];
}

- (void)startAutoscroll
{
    [autoscrollTimer invalidate];
    
    autoscrollTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self
                                                     selector:@selector(autoscrollTimerFired:)
                                                     userInfo:nil repeats:YES];
}

- (void)autoscrollTimerFired:(NSTimer *)timer
{
    NSUInteger scrollToIndex = [pagingScrollView indexOfSelectedPage] + 1;
    if (scrollToIndex >= kGraphRangeCount) {
        scrollToIndex = 0;
        //Now's not a bad time to inform the user they can rotate for a fullscreen graph
        if (self.shouldShowRotateHint)
            [self showRotateHint];
    }
    [pagingScrollView selectPageAtIndex:scrollToIndex animated:YES];
}

- (void)scrollToRange:(JCStockGraphRange)newRange
{
    [pagingScrollView selectPageAtIndex:newRange animated:YES];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)theScrollView
{
	[pagingScrollView scrollViewDidScroll];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    //disable autoscroll after user started interacting with graphs
    [autoscrollTimer invalidate];
}

#pragma mark - MHPagingScrollViewDelegate

- (NSUInteger)numberOfPagesInPagingScrollView:(MHPagingScrollView *)pagingScrollView
{
	return graphControllers.count;
}

- (UIView *)pagingScrollView:(MHPagingScrollView *)thePagingScrollView pageForIndex:(NSUInteger)index
{
	return [graphControllers[index] view];
}

@end
