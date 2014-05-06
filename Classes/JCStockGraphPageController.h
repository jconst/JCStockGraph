//
//  StockPriceGraphPageController.h
//  Benzinga
//
//  Created by Joseph Constantakis on 8/12/13.
//  Copyright (c) 2013 Benzinga. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JCStockGraphController.h"
#import "MHPagingScrollView.h"

@interface JCStockGraphPageController : UIViewController <MHPagingScrollViewDelegate, UIScrollViewDelegate>

@property (nonatomic) JCStockGraphOptionMask graphOptions;
@property (nonatomic) BOOL shouldAutoscroll;
@property (nonatomic) BOOL shouldShowRotateHint;

@property (nonatomic) CGPoint graphOffset;
@property (nonatomic) CGSize graphSize;
@property (strong, nonatomic) NSString *ticker;

- (id)initWithTicker:(NSString *)ticker;
- (void)reloadViews;
- (void)scrollToRange:(JCStockGraphRange)newRange;

@end
