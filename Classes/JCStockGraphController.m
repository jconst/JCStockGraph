//
//  StockPriceGraphController.h.m
//  Benzinga
//
//  Created by Joseph Constantakis on 8/10/13.
//  Copyright (c) 2013 Benzinga. All rights reserved.
//

#import "JCStockGraphController.h"
#import "FIIconView.h"
#import "FIEntypoIcon.h"
#import "NSDate+MTDates.h"

#import "MBProgressHUD+Customizations.h"
#import "UIView+FrameAccessor.h"
#import "JCPriceDataPoint.h"
#import "JCStockGraphView.h"
#import "JCStockPriceStore.h"

@interface JCStockGraphController () {
    NSArray *points;
    BOOL loaded;
    BOOL hasSetSize;
    UITapGestureRecognizer *tapRecognizer;
}
@end


@implementation JCStockGraphController

- (id)initWithTicker:(NSString *)ticker
{
    self = [super init];
    if (self) {
        self.ticker       = ticker;
        self.graphOptions = kGraphOptionNone;
        self.range        = kGraphRange5Year;
        self.graphOffset  = CGPointZero;
        self.graphSize    = CGSizeZero;
    }
    return self;
}

- (void)setGraphSize:(CGSize)graphSize
{
    _graphSize = graphSize;
    hasSetSize = YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self loadDataWithCompletion:nil];
}

- (void)loadDataWithCompletion:(void (^)())completion
{
    if (loaded) return;
    loaded = YES;
    
    MBProgressHUD *hud           = [[MBProgressHUD alloc] initWithView:self.view];
    hud.color                    = [UIColor clearColor];
    hud.mode                     = MBProgressHUDModeDeterminate;
    hud.labelText                = @"Loading Graph...";
    hud.textColor                = [UIColor grayColor];
    hud.indicatorBackgroundColor = [UIColor grayColor];
    hud.indicatorSize            = CGSizeMake(50, 50);
    
	[self.view addSubview:hud];
	[hud show:YES];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

        [[JCStockPriceStore sharedInstance] getDataForTicker:self.ticker withProgress:^(double progress) {
             hud.progress = progress;
            
        } completion:^(NSArray *newPoints) {
             
             if (newPoints) {
                 NSDate *startDate = [self startDateForGraphRange:self.range];
                 points = [self pointsInArray:newPoints afterDate:startDate];
                 if (self.graphOptions & kGraphOptionSmoothGraph)
                     points = [self thinPoints:points];

                 dispatch_async(dispatch_get_main_queue(), ^{
                     [self loadGraph];
                     [hud hide:YES];
                     if (completion) completion();
                 });
             }
        }];
    });
}

-(void)loadGraph
{
    self.graphView = [[JCStockGraphView alloc] initWithFrame:self.view.bounds];
    self.graphView.origin = self.graphOffset;
    if (hasSetSize) self.graphView.size = self.graphSize;
    self.graphView.range = self.range;
    [self.graphView configureHost];
    [self.graphView configureGraph];
    [self.graphView configurePlotWithDataSource:self];
    (self.graphOptions & kGraphOptionHideXAxis) ? [self.graphView hideXAxis] : [self.graphView configureXAxisWithPoints:points delegate:self];
    (self.graphOptions & kGraphOptionHideYAxis) ? [self.graphView hideYAxis] : [self.graphView configureYAxisWithPoints:points];
    if (!(self.graphOptions & kGraphOptionHideGrid)) [self.graphView configureGridLines];
    if (!(self.graphOptions & kGraphOptionHideRangeLabel)) [self.graphView addRangeLabel];
    self.graphView.userInteractionEnabled = (self.graphOptions & kGraphOptionInteractive);
    
    [self.view addSubview:self.graphView];
}

- (void)reloadGraph
{    
    self.graphView.frame = self.view.bounds;
    self.graphView.range = self.range;
    [self.graphView reloadGraph];
}

- (NSArray *)thinPoints:(NSArray *)fullPoints
{
    //Make graph look smoother by thinning out the number of data points
    long pointMax = self.view.width / 4.0;
    if (fullPoints.count < pointMax)
        return fullPoints;
    else {
        NSMutableArray *ret = [[NSMutableArray alloc] initWithCapacity:pointMax];
        long divisor = fullPoints.count/pointMax;
        for (int i = 1; i < fullPoints.count; i++) {
            if (i % divisor == 0)
                [ret addObject:fullPoints[i]];
        }
        return ret;
    }
}

- (NSArray *)pointsInArray:(NSArray *)array afterDate:(NSDate *)date {
    for (int i = 0; i < array.count; ++i) {
        NSDate *pointDate = [array[i] date];
        if ([pointDate mt_isAfter:date])
            return [array subarrayWithRange:NSMakeRange(i, array.count-i)];
    }
    return @[];
}

- (NSDate *)startDateForGraphRange:(JCStockGraphRange)graphRange {
    switch (graphRange) {
        default:
        case kGraphRange5Year:
            return [[NSDate date] mt_dateYearsBefore:5];
        case kGraphRange1Year:
            return [[NSDate date] mt_dateYearsBefore:1];
        case kGraphRange3Month:
            return [[NSDate date] mt_dateMonthsBefore:3];
        case kGraphRange1Month:
            return [[NSDate date] mt_dateMonthsBefore:1];
        case kGraphRange1Week:
            return [[NSDate date] mt_dateDaysBefore:8];
    }
}

#pragma mark - CPTPlotDataSource methods

- (NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot
{
    return points.count;
}

- (NSNumber *)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index
{
    JCPriceDataPoint *point = points[index];
    
    if (fieldEnum == CPTScatterPlotFieldX)
        return [NSDecimalNumber numberWithInteger:(NSInteger)index];
    else
        return [NSDecimalNumber numberWithDouble:point.closePrice];
}

#pragma mark - CPTAxisDelegate

- (BOOL)axisShouldRelabel:(CPTAxis *)axis
{
    return YES;
}

- (BOOL)axis:(CPTAxis *)axis shouldUpdateAxisLabelsAtLocations:(NSSet *)locations
{        
    NSMutableSet *labels = [NSMutableSet setWithCapacity:points.count];
    JCPriceDataPoint *prevPoint;
    NSDateFormatter *dateFormatter;
    
    NSSortDescriptor *desc   = [NSSortDescriptor sortDescriptorWithKey:@"floatValue" ascending:YES];
    NSArray *sortedLocations = [locations sortedArrayUsingDescriptors:@[desc]];
    
    for (NSNumber *location in sortedLocations) {
        int index = [location intValue];
        
        NSString *text;
        if (index < 0 || index >= points.count) {
            text = @"";
        } else {
            
            JCPriceDataPoint *point = points[index];
            dateFormatter = [self dateFormatterForDate:point.date previousDate:prevPoint.date];
            text = [dateFormatter stringFromDate:point.date];
            prevPoint = point;
        }

        static CPTTextStyle *labelStyle = nil;
        if (!labelStyle) {
            CPTMutableTextStyle *newLabelStyle = [axis.labelTextStyle mutableCopy];
            newLabelStyle.color = [CPTColor darkGrayColor];
            newLabelStyle.fontName = @"Helvetica";
            labelStyle = newLabelStyle;
        }
        
        CPTTextLayer *newLabelLayer = [[CPTTextLayer alloc] initWithText:text style:labelStyle];
        CPTAxisLabel *label = [[CPTAxisLabel alloc] initWithContentLayer:newLabelLayer];
        label.tickLocation = location.decimalValue;
        label.offset = 5.0;
        [labels addObject:label];
    }
    
    axis.axisLabels = labels;
    return NO;
}

- (NSDateFormatter *)dateFormatterForDate:(NSDate *)date previousDate:(NSDate *)prevDate
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSDate *today = [NSDate date];
    
    if ([date mt_isWithinSameWeek:today])
        dateFormatter.dateFormat = @"E";
    
    else if (prevDate && date) {
        if ([date mt_isWithinSameMonth:prevDate])
            dateFormatter.dateFormat = @"d";
        else if ([date mt_year] == [prevDate mt_year])
            dateFormatter.dateFormat = @"d MMM";
        else
            dateFormatter.dateFormat = @"MMM yyyy";
    } else {
        if ([date mt_year] == [today mt_year])
            dateFormatter.dateFormat = @"d MMM";
        else
            dateFormatter.dateFormat = @"MMM yyyy";
    }

    return dateFormatter;
}

@end
