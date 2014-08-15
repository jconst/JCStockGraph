//
//  StockPriceStore.m
//  CorePlotDemo
//
//  NB: Price data obtained from Yahoo! Finance:
//  http://finance.yahoo.com/q/hp?s=AAPL
//  http://finance.yahoo.com/q/hp?s=GOOG
//  http://finance.yahoo.com/q/hp?s=MSFT
//
//  Created by Steve Baranski on 5/4/12.
//  Copyright (c) 2012 komorka technology, llc. All rights reserved.
//

#import "JCStockPriceStore.h"

#import "AFNetworking.h"
#import "NSDate+MTDates.h"

#import "JCStockGraphController.h"
#import "JCPriceDataPoint.h"
#import "NSDate+YQL.h"

@interface JCStockPriceStore () {
    NSMutableDictionary *inMemCache;
}

@end

@implementation JCStockPriceStore

static JCStockPriceStore *sharedInstance;
+ (JCStockPriceStore *)sharedInstance
{
    if (!sharedInstance) {
        sharedInstance = [[JCStockPriceStore alloc] init];
    }
    return sharedInstance;
}

- (void)mergePoints:(NSArray *)points todayPoints:(NSArray *)today_points completion:(void (^)(NSArray *points))comp
{
    if (!comp) return;
    if (!points) return;
    
    NSMutableArray *newArray = [[NSMutableArray alloc] init];
    [newArray addObjectsFromArray:points];
    JCPriceDataPoint *point = [newArray lastObject];
    if (today_points && [today_points count]>0)
    {
        JCPriceDataPoint *tPoint = [today_points objectAtIndex:0];
        if ([point.date isEqual:tPoint.date]==NO)
            [newArray addObjectsFromArray:today_points];
    }
    comp(newArray);
    
}


- (void)getTodayStockPrice:(NSString *)ticker longPoints:(NSArray *)points todayPoints:(NSArray *)today_points withProgress:(void (^)(double progress))progBlock completion:(void (^)(NSArray *points))comp
{
    // Request current price..
    // http://download.finance.yahoo.com/d/quotes.csv?s=AAPL&f=d1o0h0g0l1v0l1
    NSString *urlString = [NSString stringWithFormat:@"http://download.finance.yahoo.com/d/quotes.csv?s=%@&f=d1o0h0g0l1v0l1", ticker];
    
    // escape for ^IXIC, ^INX
    NSURL *url = [NSURL URLWithString:[urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    AFHTTPRequestOperation *operation2 = [[AFHTTPRequestOperation alloc] initWithRequest:[NSURLRequest requestWithURL:url]];
    [operation2 setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject)
     {
         NSMutableArray *today_points = [[NSMutableArray alloc] init];
         
         NSString *csvString = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
         
         // reformat the date string
         NSMutableString *csvString_tmp = [csvString mutableCopy];
         NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern: @"\"([0-9]{1,2})/([0-9]{1,2})/([0-9]{4})\"" options:0 error:nil];
         [regex replaceMatchesInString:csvString_tmp options:0 range:NSMakeRange(0, [csvString_tmp length]) withTemplate:@"$3-$1-$2"];
         regex = [NSRegularExpression regularExpressionWithPattern: @"-([0-9]{1})-" options:0 error:nil];
         [regex replaceMatchesInString:csvString_tmp options:0 range:NSMakeRange(0, [csvString_tmp length]) withTemplate:@"-0$1-"];
         regex = [NSRegularExpression regularExpressionWithPattern: @"-([0-9]{1})$" options:0 error:nil];
         [regex replaceMatchesInString:csvString_tmp options:0 range:NSMakeRange(0, [csvString_tmp length]) withTemplate:@"-0$1"];
         csvString = [NSString stringWithFormat:@"FIRST_LINE_FOR_SKIPED\n%@", csvString_tmp];
         
         
         NSArray *newPoints  = [self dataPointsForCSVString:csvString];
         [today_points addObjectsFromArray:newPoints];
         

         [self cachePoints:points  todayPoints:today_points forTicker:ticker];
         [self mergePoints:points todayPoints:today_points completion:comp];
         
     } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
         [self mergePoints:points todayPoints:today_points completion:comp];
         NSLog(@"CSV request failure: %@", error);
     }];

    // Dowload Progress
    [operation2 setDownloadProgressBlock:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
        long long expected = totalBytesExpectedToRead;
        if (expected == -1)
            expected = 75000;   //A bit more than average
        double prog = MIN((double)totalBytesRead/(double)expected, 1.0);
        if (progBlock) progBlock(prog);
    }];

    [operation2 start];
}

- (BOOL)getDataForTicker:(NSString *)ticker withProgress:(void (^)(double progress))progBlock completion:(void (^)(NSArray *points))comp
{
    NSAssert(ticker, @"tried to get historical data for null ticker");
    if (!ticker && comp) comp(nil);
    
    __block NSMutableArray *points = [[NSMutableArray alloc] init];
    __block NSMutableArray *today_points = [[NSMutableArray alloc] init];
    
    //Set time period:
    NSDate *endDate = [NSDate date];
    NSDate *startDate = [endDate mt_dateYearsBefore:5];
    
    //Check for previously cached data:
    BOOL needUpdateLong = NO;
    BOOL needUpdateTotday = NO;
    NSDictionary *cacheDict = [self loadCacheForTicker:ticker];
    if (cacheDict)
    {
        //Found a cache; load it into our points array
        [points addObjectsFromArray:cacheDict[@"data"]]; // long term data...
        NSDate *cacheDate = cacheDict[@"cacheDate"];
        if ([cacheDate mt_isWithinSameDay:endDate]==NO
            || [points  count]<50 // abnormal case..
            )
        {
//            startDate = cacheDate;
            needUpdateTotday = YES;
            needUpdateLong = YES;
        } else {
            // check short term data..
            [today_points addObjectsFromArray:cacheDict[@"today_data"]];
            cacheDate = cacheDict[@"cacheTodayDate"];
            if (
                [cacheDate mt_isWithinSameHour:endDate]==NO
                || [cacheDate mt_isWithinSameDay:endDate]==NO
                || [today_points count]>1
                )

            {
                needUpdateTotday = YES;
            }
        }
    } else {
        needUpdateLong = YES;
        needUpdateTotday = YES;
    }
    
    
    if (needUpdateLong)
    {
        //Build URL:
        NSString *urlString = [NSString stringWithFormat:@"http://ichart.finance.yahoo.com/table.csv?s=%@&%@&%@", ticker, [startDate yqlStartString], [endDate yqlEndString]];
        
        // escape characters, ex. ^IXIC, ^INX
        NSURL *url = [NSURL URLWithString:[urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        
        //Create Request:
        AFHTTPRequestOperation *operation    = [[AFHTTPRequestOperation alloc] initWithRequest:[NSURLRequest requestWithURL:url]];
        [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject)
         {
             NSString *csvString = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
             NSArray *newPoints  = [self dataPointsForCSVString:csvString];
             [points removeAllObjects];
             [points addObjectsFromArray:newPoints];
             
    
             [self getTodayStockPrice:ticker longPoints:points todayPoints:today_points withProgress:progBlock completion:comp];
             
         } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             // still try today stock price...
             [self getTodayStockPrice:ticker longPoints:points todayPoints:today_points withProgress:progBlock completion:comp];
             NSLog(@"CSV request failure: %@", error);
         }];
        
        // Dowload Progress
        [operation setDownloadProgressBlock:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
            long long expected = totalBytesExpectedToRead;
            if (expected == -1)
                expected = 75000;   //A bit more than average
            double prog = MIN((double)totalBytesRead/(double)expected, 1.0);
            if (progBlock) progBlock(prog);
        }];
        
        [operation start];

    }
    else if (needUpdateTotday)
    {
        [self getTodayStockPrice:ticker longPoints:points todayPoints:today_points withProgress:progBlock completion:comp];

    } else {
        [self mergePoints:points todayPoints:today_points completion:comp];
    }
    
    return NO;
}

- (NSArray *)dataPointsForCSVString:(NSString *)csvString
{
    NSArray *lines        = [csvString componentsSeparatedByString:@"\n"];
    NSArray *columnNames  = [lines[0] componentsSeparatedByString:@","];
    NSArray *data         = [lines subarrayWithRange:NSMakeRange(1, [lines count]-2)];
    NSUInteger dateIndex  = 0;
    NSUInteger closeIndex = 4;
    
    for (int i = 0; i < columnNames.count; ++i) {
        if ([columnNames[i] isEqualToString:@"Close"])
            closeIndex = i;
        else if ([columnNames[i] isEqualToString:@"Date"])
            dateIndex = i;
    }
    
    NSMutableArray *points = [[NSMutableArray alloc] initWithCapacity:data.count];
    NSNumberFormatter *nf  = [[NSNumberFormatter alloc] init];
    
    data = [data sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    
    NSDate *lastDate=nil;
    for (NSString *rowString in data) {
        
        NSArray *row            = [rowString componentsSeparatedByString:@","];

        JCPriceDataPoint *point = [[JCPriceDataPoint alloc] init];
        point.date              = [NSDate mt_dateFromString:row[dateIndex] usingFormat:kDateFormatYahooAPI];
        if ([point.date isEqual:lastDate]) continue;
        
        NSString *closeString   = row[closeIndex];
        point.closePrice        = [[nf numberFromString:closeString] doubleValue];
        [points addObject:point];
        
        lastDate = point.date;
    }
    return points;
}

#pragma mark - Caching

- (NSString *)cachePathForTicker:(NSString *)ticker
{
    NSArray *paths           = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cacheDirectory = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"GraphData"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:cacheDirectory])
        [[NSFileManager defaultManager] createDirectoryAtPath:cacheDirectory withIntermediateDirectories:NO attributes:nil error:nil];
    return [cacheDirectory stringByAppendingPathComponent:ticker];
}

- (NSDictionary *)loadCacheForTicker:(NSString *)ticker
{
    NSDictionary *ret = inMemCache[ticker];
    if (!ret && self.diskCachingEnabled) {
        NSString *cachePath = [self cachePathForTicker:ticker];
        @try {
            ret = [NSKeyedUnarchiver unarchiveObjectWithFile:cachePath];
        } @catch (...) {
            ret = nil;
        }
    }
    return ret;
}

- (BOOL)cachePoints:(NSArray *)points todayPoints:(NSArray *)today_points forTicker:(NSString *)ticker
{
    NSDictionary *cacheDict = @{@"cacheDate": [NSDate date], @"data": points, @"cacheTodayDate": [NSDate date], @"today_data": today_points};
    inMemCache[ticker] = cacheDict;
    
    if (self.diskCachingEnabled) {
        NSString *cachePath = [self cachePathForTicker:ticker];
        return [NSKeyedArchiver archiveRootObject:cacheDict toFile:cachePath];
    }
    return NO;
}

- (BOOL)cacheTodayPoints:(NSArray *)points forTicker:(NSString *)ticker
{
    NSDictionary *cacheDict = @{@"cacheTodayDate": [NSDate date], @"today_data": points};
    inMemCache[ticker] = cacheDict;
    
    if (self.diskCachingEnabled) {
        NSString *cachePath = [self cachePathForTicker:ticker];
        return [NSKeyedArchiver archiveRootObject:cacheDict toFile:cachePath];
    }
    return NO;
}

- (void)setMemoryCachingEnabled:(BOOL)inMemoryCachingEnabled
{
    inMemCache = nil;
    if (inMemoryCachingEnabled)
        inMemCache = [[NSMutableDictionary alloc] init];
}

- (id)init
{
    self = [super init];
    if (self) {
        self.memoryCachingEnabled = YES;
        self.diskCachingEnabled = YES;
        inMemCache = [[NSMutableDictionary alloc] init];
    }
    return self;
}

@end
