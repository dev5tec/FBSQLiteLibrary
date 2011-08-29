//
//  Copyright CELLANT Corp. All rights reserved.
//

#import <sqlite3.h>

#import <Foundation/Foundation.h>

@interface FBSQLiteStatement : NSObject {
    
    int idx_;
    sqlite3_stmt* stmt_;

}
@property (nonatomic, assign, readonly) sqlite3_stmt* stmt;

+ (FBSQLiteStatement*)sqliteStatementWithStmt:(sqlite3_stmt*)stmt;
- (void)bindText:(NSString*)textString;
- (void)bindInt:(int)intValue;
- (void)bindInt64:(int64_t)int64Value;
- (void)bindDouble:(double)doubleValue;

- (NSString*)stringForColumnAt:(NSUInteger)index;
- (int64_t)int64ForColumnAt:(NSUInteger)index;

@end
