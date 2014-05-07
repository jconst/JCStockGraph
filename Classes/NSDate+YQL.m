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
    return [NSString stringWithFormat:@"a=%lu&b=%lu&c=%lu", (unsigned long)[self mt_monthOfYear]-1,
                                                           (unsigned long)[self mt_dayOfMonth],
                                                           (unsigned long)[self mt_year]];
}

- (NSString *)yqlEndString {
    return [NSString stringWithFormat:@"d=%lu&e=%lu&f=%lu", (unsigned long)[self mt_monthOfYear]-1,
                                                           (unsigned long)[self mt_dayOfMonth],
                                                           (unsigned long)[self mt_year]];
}

@end
