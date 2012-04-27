//
//  Copyright CELLANT Corp. All rights reserved.
//

#import <sqlite3.h>

#import <Foundation/Foundation.h>

@class FBSQLiteStatement;
@interface FBSQLiteManager : NSObject {
    
    NSString* dbName_;
    NSString* dbPath_;
    sqlite3* db_;
}

- (id)initWithDBName:(NSString*)dbName templateName:(NSString*)templateName;

@property (nonatomic, copy, readonly) NSString* dbName;

// API
- (sqlite3*)open;
- (void)close;

- (BOOL)insertSQL:(NSString*)sql bindBlock:(void(^)(FBSQLiteStatement* statement))bindBlock;
- (NSUInteger)selectSQL:(NSString*)sql bindBlock:(void(^)(FBSQLiteStatement* statement))bindBlock rowBlock:(void(^)(FBSQLiteStatement* statement))rowBlock;
- (BOOL)executeSQL:(NSString*)sql changes:(int*)changes;
- (BOOL)executeSQL:(NSString*)sql;
- (BOOL)hasExistedTable:(NSString*)tableName;

- (int)countTable:(NSString*)tableName;

- (int64_t)lastInsertId;

@end
