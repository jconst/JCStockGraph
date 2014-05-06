//
//  StockPriceGraphView.h
//  BenzingaNews
//
//  Created by Joseph Constantakis on 7/11/13.
//  Copyright (c) 2013 Benzinga. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CorePlot/CorePlot-CocoaTouch.h"
#import "JCStockGraphController.h"

@class JCStockPriceStore;

@interface JCStockGraphView : UIView

@property (strong, nonatomic) NSString *ticker;
@property (strong, nonatomic) CPTGraphHostingView *hostView;
@property (nonatomic) JCStockGraphRange range;

- (void)reloadGraph;
- (void)configureHost;
- (void)configureGraph;
- (void)configurePlotWithDataSource:(id<CPTPlotDataSource>)dataSource;
- (void)configureXAxisWithPoints:(NSArray *)points delegate:(id<CPTAxisDelegate>)delegate;
- (void)configureYAxisWithPoints:(NSArray *)points;
- (void)configureGridLines;
- (void)hideAxes;
- (void)hideXAxis;
- (void)hideYAxis;
- (void)addRangeLabel;

@end
