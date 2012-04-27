//
//  Copyright CELLANT Corp. All rights reserved.
//

#import <sqlite3.h>

#import <Foundation/Foundation.h>

@interface FBSQLiteStatement : NSObject {
    
    int bidx_;
}
@property (nonatomic, assign, readonly) sqlite3_stmt* stmt;
@property (nonatomic, assign, readonly) NSDictionary* columns;

// API (Factory)
+ (FBSQLiteStatement*)sqliteStatementWithStmt:(sqlite3_stmt*)stmt;

// API (Bindings)
- (void)bindText:(NSString*)textString;
- (void)bindInt:(int)intValue;
- (void)bindInt64:(int64_t)int64Value;
- (void)bindDouble:(double)doubleValue;
- (void)bindDate:(NSDate*)date;
- (void)bindStringArray:(NSArray*)stringArray;

// API (Columns)
- (int)indexForColumn:(NSString*)column;

// API (Accessors)
- (NSString*)stringForColumn:(NSString*)column;
- (int)intForColumn:(NSString*)column;
- (int64_t)int64ForColumn:(NSString*)column;
- (double)doubleForColumn:(NSString*)column;
- (NSDate*)dateForColumn:(NSString*)column;
- (NSArray*)arrayForColumn:(NSString*)column;

@end
