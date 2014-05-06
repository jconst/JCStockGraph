//
//  StockPriceGraphView.m
//  BenzingaNews
//
//  Created by Joseph Constantakis on 7/11/13.
//  Copyright (c) 2013 Benzinga. All rights reserved.
//

#import "JCStockGraphView.h"

#import "NSDate+MTDates.h"
#import "MBProgressHUD.h"
#import "CorePlot-CocoaTouch.h"

#import "UIView+FrameAccessor.h"
#import "JCPriceDataPoint.h"
#import "JCStockPriceStore.h"

@implementation JCStockGraphView

- (void)reloadGraph
{
    [self.hostView.hostedGraph reloadData];
}

#pragma mark - Chart behavior

-(void)configureHost
{
	self.hostView = [(CPTGraphHostingView *) [CPTGraphHostingView alloc] initWithFrame:self.bounds];
    self.hostView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	self.hostView.allowPinchScaling = YES;
	[self addSubview:self.hostView];
}

-(void)configureGraph
{
	// 1 - Create the graph
	CPTGraph *graph = [[CPTXYGraph alloc] initWithFrame:self.hostView.bounds];
	self.hostView.hostedGraph = graph;
    self.hostView.allowPinchScaling = YES;
    
    graph.paddingLeft = 0;
    graph.paddingTop = 0;
    graph.paddingRight = 0;
    graph.paddingBottom = 0;
}

-(void)configurePlotWithDataSource:(id<CPTPlotDataSource>)dataSource
{
	// 1 - Get graph and plot space
    CPTGraph *graph                 = self.hostView.hostedGraph;
    CPTXYPlotSpace *plotSpace       = (CPTXYPlotSpace *) graph.defaultPlotSpace;
    plotSpace.allowsUserInteraction = YES;

	// 2 - Create the plot
    CPTScatterPlot *plot = [[CPTScatterPlot alloc] init];
    plot.dataSource      = dataSource;
    plot.delegate        = dataSource;
    plot.identifier      = self.ticker;
	[graph addPlot:plot toPlotSpace:plotSpace];
    
	// 3 - Set up plot space
	[plotSpace scaleToFitPlots:@[plot]];
    
	CPTMutablePlotRange *yRange = [plotSpace.yRange mutableCopy];
	[yRange expandRangeByFactor:CPTDecimalFromCGFloat(1.2f)];
    
    plotSpace.yRange = yRange;
    
	// 4 - Create line style
    CPTMutableLineStyle *lineStyle = [plot.dataLineStyle mutableCopy];
    lineStyle.lineWidth            = 1.5f;
    lineStyle.lineColor            = [CPTColor colorWithComponentRed:0/255.f green:48/255.f blue:66/255.f alpha:1.0];
    plot.dataLineStyle             = lineStyle;
    
    //plot.interpolation = CPTScatterPlotInterpolationCurved;
    
    //plot.areaFill = [CPTFill fillWithColor:kColorGraphFill];
    //plot.areaBaseValue = CPTDecimalFromInteger(0);
}

- (void)configureXAxisWithPoints:(NSArray *)points delegate:(id<CPTAxisDelegate>)delegate
{
    // 0 - increase padding to make room for axis labels
    self.hostView.hostedGraph.plotAreaFrame.paddingBottom = 24;
    
	// 1 - Get axis set
	CPTXYAxisSet *axisSet = (CPTXYAxisSet *) self.hostView.hostedGraph.axisSet;
    
	// 2 - Configure x-axis
    CPTXYAxis *x         = axisSet.xAxis;
    x.delegate           = delegate;
    x.axisConstraints    = [CPTConstraints constraintWithLowerOffset:0];
    x.tickDirection      = CPTSignNegative;
    x.axisLineStyle      = nil;
    x.majorTickLineStyle = nil;
    x.minorTickLineStyle = nil;
    
    // 3 - Configure Labels
    x.labelingPolicy = CPTAxisLabelingPolicyAutomatic;
    x.preferredNumberOfMajorTicks = 5;
}

- (void)configureYAxisWithPoints:(NSArray *)points
{
    // 0 - increase padding to make room for axis labels
    self.hostView.hostedGraph.plotAreaFrame.paddingLeft = 36;
    
	// 1 - Get axis set
	CPTXYAxisSet *axisSet = (CPTXYAxisSet *) self.hostView.hostedGraph.axisSet;

    // 2 - Configure y-axis
    NSNumberFormatter *priceFormatter       = [[NSNumberFormatter alloc] init];
    priceFormatter.numberStyle              = kCFNumberFormatterCurrencyStyle;
    priceFormatter.maximumSignificantDigits = 3;
    priceFormatter.usesSignificantDigits    = YES;
    
    CPTXYAxis *y         = axisSet.yAxis;
    y.axisConstraints    = [CPTConstraints constraintWithLowerOffset:0];
    y.labelFormatter     = priceFormatter;
    y.tickDirection      = CPTSignNegative;
    y.axisLineStyle      = nil;
    y.majorTickLineStyle = nil;
    y.minorTickLineStyle = nil;
    
    CPTMutableTextStyle *yLabel = [y.labelTextStyle mutableCopy];
    yLabel.color                = [CPTColor darkGrayColor];
    yLabel.fontName             = @"OpenSans";
    y.labelTextStyle            = yLabel;
    y.labelingPolicy            = CPTAxisLabelingPolicyAutomatic;
    y.labelOffset               = -5.0;
}

- (void)configureGridLines
{
    // 1 - Get axis set
    CPTXYAxisSet *axisSet = (CPTXYAxisSet *) self.hostView.hostedGraph.axisSet;
    CPTAxis *y            = axisSet.yAxis;
    CPTAxis *x            = axisSet.xAxis;

    // 2 - Fix title offsets to make room for lines
    x.labelOffset = 0;
    y.labelOffset = 0;
    
    // 3 - Configure axis lines (at left and bottom edges)
    CPTMutableLineStyle *axisLineStyle = [CPTMutableLineStyle lineStyle];
    axisLineStyle.lineWidth            = 2.0f;
    axisLineStyle.lineColor            = [CPTColor lightGrayColor];
    x.axisLineStyle                    = axisLineStyle;
    y.axisLineStyle                    = axisLineStyle;
    
    // 4 - Configure ticks and grid lines
    x.majorTickLineStyle = axisLineStyle;
    y.majorTickLineStyle = axisLineStyle;
    x.majorTickLength    = 4.0f;
    y.majorTickLength    = 4.0f;
    
    CPTMutableLineStyle *gridLineStyle = [CPTMutableLineStyle lineStyle];
    gridLineStyle.lineColor            = [CPTColor lightGrayColor];
    gridLineStyle.lineWidth            = 1.0f;
    
    x.majorGridLineStyle = gridLineStyle;
    y.majorGridLineStyle = gridLineStyle;
}

- (void)hideAxes
{    
    [self hideXAxis];
    [self hideYAxis];
}

- (void)hideXAxis
{
    CPTXYAxisSet *axisSet        = (CPTXYAxisSet *) self.hostView.hostedGraph.axisSet;
    axisSet.xAxis.labelingPolicy = CPTAxisLabelingPolicyNone;
    axisSet.xAxis.hidden         = YES;
}

- (void)hideYAxis
{
    CPTXYAxisSet *axisSet        = (CPTXYAxisSet *) self.hostView.hostedGraph.axisSet;
    axisSet.yAxis.labelingPolicy = CPTAxisLabelingPolicyNone;
    axisSet.yAxis.hidden         = YES;
}

- (void)addRangeLabel
{
    UILabel *rangeLabel         = [[UILabel alloc] init];
    rangeLabel.text             = [self textForGraphRange:self.range];
    rangeLabel.font             = [UIFont fontWithName:@"Helvetica-Bold" size:11.0];
    rangeLabel.textColor        = [UIColor whiteColor];
    rangeLabel.textAlignment    = NSTextAlignmentCenter;
    rangeLabel.backgroundColor  = [UIColor colorWithWhite:0.0 alpha:0.4];
    [rangeLabel sizeToFit];
    rangeLabel.width            += 8;
    rangeLabel.y                = self.height - rangeLabel.height;
    rangeLabel.right            = self.right;
    rangeLabel.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin;
    [self addSubview:rangeLabel];
}

- (NSString *)textForGraphRange:(JCStockGraphRange)graphRange
{
    switch (graphRange) {
        default:
        case kGraphRange5Year:
            return @"5 Year";
        case kGraphRange1Year:
            return @"1 Year";
        case kGraphRange3Month:
            return @"3 Month";
        case kGraphRange1Month:
            return @"1 Month";
        case kGraphRange1Week:
            return @"1 Week";
    }
}

@end
