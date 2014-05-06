//
//  StockPriceDataPoint.m
//  Benzinga
//
//  Created by Joseph Constantakis on 7/25/13.
//  Copyright (c) 2013 Benzinga. All rights reserved.
//

#import "JCPriceDataPoint.h"
#import "NSDate+YQL.h"

@implementation JCPriceDataPoint

- (id)initWithCoder:(NSCoder *)coder {
    self = [self init];
    if (self) {
        self.closePrice = [coder decodeDoubleForKey:@"closePrice"] ;
        self.date       = [coder decodeObjectForKey:@"date"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    if (self.closePrice >= 0) [coder encodeDouble:self.closePrice forKey:@"closePrice"];
    if (self.date != nil)     [coder encodeObject:self.date forKey:@"date"];
}

@end
