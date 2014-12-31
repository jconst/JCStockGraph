//
//  NSDate+YQL.h
//  Pods
//
//  Created by Joseph Constantakis on 5/4/14.
//
//
#ifndef NSDate_YQL_h
#define NSDate_YQL_h

#import <Foundation/Foundation.h>

#define kDateFormatYahooAPI @"yyyy-MM-dd"


@interface NSDate (YQL)

- (NSString *)yqlStartString;
- (NSString *)yqlEndString;

@end

#endif