//
//  StockPriceStore.h
//  CorePlotDemo
//
//  Created by Steve Baranski on 5/4/12.
//  Copyright (c) 2012 komorka technology, llc. All rights reserved.
//

#import "CorePlot-CocoaTouch.h"

@interface JCStockPriceStore : NSObject

+ (JCStockPriceStore *)sharedInstance;

///@return YES if we loaded data from the cache/memory, NO if we made a request for the data
- (BOOL)getDataForTicker:(NSString *)ticker withProgress:(void (^)(double progress))progBlock completion:(void (^)(NSArray *points))block;

@property (nonatomic) BOOL diskCachingEnabled;
@property (nonatomic) BOOL memoryCachingEnabled;

@end
