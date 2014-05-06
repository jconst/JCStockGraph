//
//  StockPriceDataPoint.h
//  Benzinga
//
//  Created by Joseph Constantakis on 7/25/13.
//  Copyright (c) 2013 Benzinga. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JCPriceDataPoint : NSObject <NSCoding>

@property (nonatomic) double closePrice;
@property (strong, nonatomic) NSDate *date;

@end
