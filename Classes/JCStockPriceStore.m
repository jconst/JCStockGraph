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

- (BOOL)getDataForTicker:(NSString *)ticker withProgress:(void (^)(double progress))progBlock completion:(void (^)(NSArray *points))comp
{
    NSAssert(ticker, @"tried to get historical data for null ticker");
    if (!ticker && comp) comp(nil);
    
    __block NSMutableArray *points = [[NSMutableArray alloc] init];
    
    //Set time period:
    NSDate *endDate = [NSDate date];
    NSDate *startDate = [endDate mt_dateYearsBefore:5];
    
    //Check for previously cached data:
    NSDictionary *cacheDict = [self loadCacheForTicker:ticker];
    if (cacheDict) {
        //Found a cache; load it into our points array
        [points addObjectsFromArray:cacheDict[@"data"]];
        NSDate *cacheDate = cacheDict[@"cacheDate"];
        if ([cacheDate mt_isWithinSameDay:endDate]) {
            if (comp) comp(points);
            return YES;
        } else {
            startDate = cacheDate;
        }
    }
    
    //Build URL:
    NSString *urlString = [NSString stringWithFormat:@"http://ichart.finance.yahoo.com/table.csv?s=%@&%@&%@",
                           ticker, [startDate yqlStartString], [endDate yqlEndString]];
    NSURL *url = [NSURL URLWithString:urlString];
    
    //Create Request:
    AFHTTPRequestOperation *operation    = [[AFHTTPRequestOperation alloc] initWithRequest:[NSURLRequest requestWithURL:url]];
    AFHTTPResponseSerializer *serializer = [AFHTTPResponseSerializer serializer];
    serializer.acceptableContentTypes    = [serializer.acceptableContentTypes setByAddingObject:@"text/csv"];
    operation.responseSerializer         = serializer;
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSString *csvString = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
        NSArray *newPoints  = [self dataPointsForCSVString:csvString];
        [points addObjectsFromArray:newPoints];
        
        if (comp) comp(points);
        
        [self cachePoints:points forTicker:ticker];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (comp) comp(nil);
        NSLog(@"CSV request failure: %@", error);
    }];
    
    [operation setDownloadProgressBlock:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
        long long expected = totalBytesExpectedToRead;
        if (expected == -1)
            expected = 75000;   //A bit more than average
        double prog = MIN((double)totalBytesRead/(double)expected, 1.0);
        if (progBlock) progBlock(prog);
    }];
    
    [operation start];
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
    
    for (NSString *rowString in [data reverseObjectEnumerator]) {
        
        NSArray *row            = [rowString componentsSeparatedByString:@","];

        JCPriceDataPoint *point = [[JCPriceDataPoint alloc] init];
        point.date              = [NSDate mt_dateFromString:row[dateIndex] usingFormat:kDateFormatYahooAPI];

        NSString *closeString   = row[closeIndex];
        point.closePrice        = [[nf numberFromString:closeString] doubleValue];
        [points addObject:point];
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

- (BOOL)cachePoints:(NSArray *)points forTicker:(NSString *)ticker
{
    NSDictionary *cacheDict = @{@"cacheDate": [NSDate date], @"data": points};
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
