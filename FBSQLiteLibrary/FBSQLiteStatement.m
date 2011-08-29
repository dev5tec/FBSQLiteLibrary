//
//  Copyright CELLANT Corp. All rights reserved.
//

#import "FBSQLiteStatement.h"

@interface FBSQLiteStatement()
@property (nonatomic, assign) sqlite3_stmt* stmt;
@end

@implementation FBSQLiteStatement

@synthesize stmt = stmt_;

- (id)initWithStmt:(sqlite3_stmt *)stmt {
    self = [super init];
    if (self) {
        self.stmt = stmt;
        idx_ = 1;
    }
    return self;
}
+ (FBSQLiteStatement*)sqliteStatementWithStmt:(sqlite3_stmt*)stmt
{
    return [[[self alloc] initWithStmt:stmt] autorelease];
}


- (void)bindText:(NSString*)textString;
{
    sqlite3_bind_text(stmt_, idx_, [textString UTF8String], -1, SQLITE_TRANSIENT);
    idx_++;
}
- (void)bindInt:(int)intValue
{
    sqlite3_bind_int(stmt_, idx_, intValue);
    idx_++;
}
- (void)bindInt64:(int64_t)int64Value
{
    sqlite3_bind_int64(stmt_, idx_, int64Value);    
    idx_++;
}
- (void)bindDouble:(double)doubleValue
{
    sqlite3_bind_double(stmt_, idx_, doubleValue);
    idx_++;
}

- (NSString*)stringForColumnAt:(NSUInteger)index
{
    const char* value = (const char*)sqlite3_column_text(self.stmt, index);
    return [NSString stringWithUTF8String:value];
}
- (int64_t)int64ForColumnAt:(NSUInteger)index
{
    return sqlite3_column_int64(self.stmt, index);
}


@end
