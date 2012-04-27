//
//  Copyright CELLANT Corp. All rights reserved.
//

#import "FBSQLiteStatement.h"

@interface FBSQLiteStatement()
@property (nonatomic, assign) sqlite3_stmt* stmt;
@end

#define FB_SQLITE_STRINGARRAY_SEPARATOR @"\\___\\"


@implementation FBSQLiteStatement

@synthesize stmt = stmt_;
@synthesize columns = columns_;

#pragma mark -
#pragma mark Privates


#pragma mark -
#pragma mark Basics

- (id)initWithStmt:(sqlite3_stmt *)stmt {
    self = [super init];
    if (self) {
        self.stmt = stmt;
        bidx_ = 1;
        
        NSMutableDictionary* columns = [NSMutableDictionary dictionary];

        for (int i=0; i < sqlite3_column_count(stmt); i++) {
            const char* nameCString = sqlite3_column_name(stmt, i);
            [columns setObject:[NSNumber numberWithInt:i]
                        forKey:[NSString stringWithCString:nameCString encoding:NSUTF8StringEncoding]];
        }
        // TODO: cache column names

        columns_ = [columns retain];
    }
    return self;
}

- (void)dealloc {
    self.stmt = nil;
    [columns_ release];
    columns_ = nil;

    [super dealloc];
}


#pragma mark -
#pragma mark API (Factory)

+ (FBSQLiteStatement*)sqliteStatementWithStmt:(sqlite3_stmt*)stmt
{
    return [[[self alloc] initWithStmt:stmt] autorelease];
}


#pragma mark -
#pragma mark API (Bindings)

- (void)bindText:(NSString*)textString;
{
    sqlite3_bind_text(stmt_, bidx_, [textString UTF8String], -1, SQLITE_TRANSIENT);
    bidx_++;
}
- (void)bindInt:(int)intValue
{
    sqlite3_bind_int(stmt_, bidx_, intValue);
    bidx_++;
}
- (void)bindInt64:(int64_t)int64Value
{
    sqlite3_bind_int64(stmt_, bidx_, int64Value);    
    bidx_++;
}
- (void)bindDouble:(double)doubleValue
{
    sqlite3_bind_double(stmt_, bidx_, doubleValue);
    bidx_++;
}

- (void)bindDate:(NSDate*)date
{
    [self bindDouble:[date timeIntervalSince1970]];
}

- (void)bindStringArray:(NSArray*)stringArray
{
    [self bindText:[stringArray componentsJoinedByString:FB_SQLITE_STRINGARRAY_SEPARATOR]];
}


#pragma mark -
#pragma mark API (Columns)
- (int)indexForColumn:(NSString*)column
{
    return [[self.columns objectForKey:column] intValue];
}



#pragma mark -
#pragma mark Accsessors
- (NSString*)stringForColumn:(NSString*)column
{
    const char* value = (const char*)sqlite3_column_text(self.stmt, [self indexForColumn:column]);
    if (value) {
        return [NSString stringWithUTF8String:value];
    } else {
        return nil;
    }
    
}

- (int)intForColumn:(NSString*)column
{
    return sqlite3_column_int(self.stmt, [self indexForColumn:column]);    
}

- (int64_t)int64ForColumn:(NSString*)column
{
    return sqlite3_column_int64(self.stmt, [self indexForColumn:column]);    
}

- (double)doubleForColumn:(NSString*)column
{
    return sqlite3_column_double(self.stmt, [self indexForColumn:column]);
}

- (NSDate*)dateForColumn:(NSString*)column
{
    double timeInterval = sqlite3_column_double(self.stmt, [self indexForColumn:column]);
    if (timeInterval) {
        return [NSDate dateWithTimeIntervalSince1970:timeInterval];
    } else {
        return nil;
    }
}

- (NSArray*)arrayForColumn:(NSString*)column
{
    NSString* arrayString = [self stringForColumn:column];
    if (arrayString == nil || [arrayString length] == 0) {
        return [NSArray array];
    } else {
        return [arrayString componentsSeparatedByString:FB_SQLITE_STRINGARRAY_SEPARATOR];
    }
}



@end
