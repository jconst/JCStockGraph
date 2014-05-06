//
//  NSDate+YQL.m
//  Pods
//
//  Created by Joseph Constantakis on 5/4/14.
//
//

#import "NSDate+YQL.h"
#import "NSDate+MTDates.h"

@implementation NSDate (YQL)

- (NSString *)yqlStartString {
    return [NSString stringWithFormat:@"a=%u&b=%lu&c=%lu", [self mt_monthOfYear]-1,
                                                           (unsigned long)[self mt_dayOfMonth],
                                                           (unsigned long)[self mt_year]];
}

- (NSString *)yqlEndString {
    return [NSString stringWithFormat:@"d=%u&e=%lu&f=%lu", [self mt_monthOfYear]-1,
                                                           (unsigned long)[self mt_dayOfMonth],
                                                           (unsigned long)[self mt_year]];
}

@end
