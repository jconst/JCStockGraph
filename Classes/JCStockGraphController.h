//
//  StockPriceGraphController.h
//  Benzinga
//
//  Created by Joseph Constantakis on 8/10/13.
//  Copyright (c) 2013 Benzinga. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CorePlot-CocoaTouch.h"

typedef enum {
    kGraphRange1Week = 0,
    kGraphRange1Month,
    kGraphRange3Month,
    kGraphRange1Year,
    kGraphRange5Year,
    kGraphRangeCount
} JCStockGraphRange;

typedef enum {
    kGraphOptionNone           = 0,
    kGraphOptionInteractive    = 1,
    kGraphOptionHideXAxis      = 1 << 1,
    kGraphOptionHideYAxis      = 1 << 2,
    kGraphOptionHideGrid       = 1 << 3,
    kGraphOptionHideRangeLabel = 1 << 4,
    kGraphOptionSmoothGraph    = 1 << 5
} StockPriceGraphOption;

typedef NSInteger JCStockGraphOptionMask;

@class JCStockGraphView;

@interface JCStockGraphController : UIViewController <CPTPlotDataSource, CPTAxisDelegate>

@property (nonatomic) JCStockGraphOptionMask graphOptions;
@property (nonatomic) JCStockGraphRange range;
@property (nonatomic) CGPoint graphOffset;
@property (nonatomic) CGSize graphSize;
@property (nonatomic) id parentPage;

@property (strong, nonatomic) NSString *ticker;
@property (strong, nonatomic) JCStockGraphView *graphView;

- (id)initWithTicker:(NSString *)ticker parent:(id)qParent;
- (void)loadDataWithCompletion:(void (^)())completion;
- (void)reloadGraph;

- (void)releaseGraph;

@end
