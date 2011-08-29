//
//  Copyright CELLANT Corp. All rights reserved.
//

#import "FBSQLiteManager.h"
#import "FBSQLiteStatement.h"

static FBSQLiteManager* sharedManager_;

@interface FBSQLiteManager()
@property (nonatomic, copy) NSString* dbName;
@property (nonatomic, copy) NSString* dbPath;
@end

// prototype definition
int _countTableCallback(void* arg, int size, char** values, char** columns);


@implementation FBSQLiteManager

@synthesize dbName = dbName_;
@synthesize dbPath = dbPath_;

#pragma mark -
#pragma mark Utilities
- (BOOL)_copyDBFromTemplateFilePath:(NSString*)templateFilePath
{
    BOOL result = NO;
    NSError* error = nil;
    NSFileManager* fileManager = [NSFileManager defaultManager];
    
    if (templateFilePath == nil) {
        NSLog(@"[ERROR] Didn't exist the template db '%@'", self.dbName);
    } else {
        if ([fileManager copyItemAtPath:templateFilePath toPath:self.dbPath error:&error]) {
            NSLog(@"%s|%@", __PRETTY_FUNCTION__, @"copied");
            result = YES;
            
        } else {
            NSLog(@"[ERROR] Can't copy the template db '%@'|%@", templateFilePath, error);
        }
    }
    return result;
}

- (BOOL)_setupDBWithTemplateFilePath:(NSString*)templateName
{
    BOOL result = NO;

    NSLog(@"dbPath: %@", self.dbPath);

    NSFileManager* fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:self.dbPath]) {

        NSString* templateFilePath = [[NSBundle mainBundle] pathForResource:templateName
                                                                     ofType:nil];
        NSLog(@"template: %@", templateFilePath);
        if (templateFilePath) {
            result = [self _copyDBFromTemplateFilePath:templateFilePath];
        } else {
            result = YES;
        }
    }
    return result;
}


#pragma mark -
#pragma mark Initialization and deallocation

- (id)initWithDBName:(NSString*)dbName templateName:(NSString*)templateName
{
    self = [super init];
    if (self) {
        self.dbName = dbName;
        NSString* basePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
        self.dbPath = [basePath stringByAppendingPathComponent:self.dbName];

        [self _setupDBWithTemplateFilePath:templateName];
    }
    return self;
}

- (void)dealloc {
    if (db_) {
        sqlite3_close(db_);
    }
    self.dbName = nil;
    self.dbPath = nil;
    [super dealloc];
}


+ (FBSQLiteManager*)sharedManager
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager_ = [[FBSQLiteManager alloc] init];
    });
    return sharedManager_;
}

#pragma mark -
#pragma mark API

- (sqlite3*)open
{
    if (db_ == NULL) {
        if (sqlite3_open([self.dbPath UTF8String], &db_) == SQLITE_OK) {
            
        } else {
            NSLog(@"[ERROR] Can't open sqlite3 db '%@'", self.dbPath);
            db_ = NULL;
        }
    }
    return db_;
}

- (void)close
{
    if (db_) {
        sqlite3_close(db_);
        db_ = NULL;
    } else {
        NSLog(@"[WARN] The db has already been closed", nil);
    }
}

- (void)_beginTransaction
{
    if (db_) {
        sqlite3_exec(db_, "BEGIN TRANSACTION", NULL, NULL, NULL);
    } else {
        NSLog(@"[WARN] The db is closed", nil);
    }
}
- (void)_rollbackTransaction
{
    if(db_) {
        sqlite3_exec(db_, "ROLLBACK TRANSACTION", NULL, NULL, NULL);            
    } else {
        NSLog(@"[WARN] The db is closed", nil);
    }
}

- (void)_commitTransaction
{
    if (db_) {
        sqlite3_exec(db_, "COMMIT TRANSACTION", NULL, NULL, NULL);
    } else {
        NSLog(@"[WARN] The db is closed", nil);
    }
}


- (BOOL)insertSQL:(NSString*)sql bindBlock:(void(^)(FBSQLiteStatement* statement))bindBlock
{
    sqlite3_stmt* stmt = NULL;
    BOOL result = NO;
    
    int ret = sqlite3_prepare(db_, [sql UTF8String], -1, &stmt, NULL);

    if (ret == SQLITE_OK) {
        sqlite3_reset(stmt);
        sqlite3_clear_bindings(stmt);
        
        FBSQLiteStatement* statement = [FBSQLiteStatement sqliteStatementWithStmt:stmt];

        bindBlock(statement);

        [self _beginTransaction];
        
        ret = sqlite3_step(stmt);
        
        if (ret == SQLITE_DONE) {
            [self _commitTransaction];
            result = YES;
            // good job !
            
        } else {
        NSLog(@"[ERROR] Failed to insert: %@", sql);

            [self _rollbackTransaction];
            
        }
        sqlite3_finalize(stmt);

    } else {
        NSLog(@"[ERROR] Failed to prepare statement: %@", sql);
        [self _rollbackTransaction];
        
    }
    return result;
}

- (NSUInteger)selectSQL:(NSString*)sql bindBlock:(void(^)(FBSQLiteStatement* statement))bindBlock rowBlock:(void(^)(FBSQLiteStatement* statement))rowBlock
{
    sqlite3_stmt* stmt = NULL;
    NSUInteger rows = 0;
    
    int ret = sqlite3_prepare(db_, [sql UTF8String], -1, &stmt, NULL);
    
    if (ret == SQLITE_OK) {
        sqlite3_reset(stmt);
        sqlite3_clear_bindings(stmt);
        
        FBSQLiteStatement* statement = [FBSQLiteStatement sqliteStatementWithStmt:stmt];
        
        bindBlock(statement);

        while (sqlite3_step(stmt) == SQLITE_ROW) {
            rowBlock(statement);
            rows++;
        }

        sqlite3_finalize(stmt);
        
    } else {
        NSLog(@"[ERROR] Failed to prepare statement: %@", sql);
    }
    return rows;
    
}

- (BOOL)executeSQL:(NSString*)sql changes:(int*)changes
{
    char* errmsg = NULL;
    BOOL result = NO;
    
    if (sqlite3_exec(db_, [sql UTF8String], NULL, NULL, &errmsg) == SQLITE_OK) {
        result = YES;
    } else {
        NSLog(@"[ERROR] %s", errmsg);
    }
    if (changes) {
        *changes = sqlite3_changes(db_);
    }
    return result;
}
- (BOOL)executeSQL:(NSString*)sql
{
    return [self executeSQL:sql changes:NULL];
}

- (BOOL)hasExistedTable:(NSString*)tableName
{
    NSString* sql = @"SELECT 1 FROM sqlite_master "\
                    @" WHERE type='table' AND name=?";

    sqlite3_stmt* stmt = NULL;
    NSUInteger rows = 0;
    
    int ret = sqlite3_prepare(db_, [sql UTF8String], -1, &stmt, NULL);
    
    if (ret == SQLITE_OK) {
        sqlite3_reset(stmt);
        sqlite3_clear_bindings(stmt);
        
        FBSQLiteStatement* statement = [FBSQLiteStatement sqliteStatementWithStmt:stmt];
        [statement bindText:tableName];
        
        while (sqlite3_step(stmt) == SQLITE_ROW) {
            rows++;
        }
        
        sqlite3_finalize(stmt);

    } else {
        NSLog(@"[ERROR] Failed to prepare statement: %@", sql);
    }
    return (rows == 1);
}

int _countTableCallback(void* arg, int size, char** values, char** columns) {
    int* count = (int*)arg;
    *count = atoi(values[0]);
    return 0;
}

- (int)countTable:(NSString*)tableName
{
    char* errmsg = NULL;
    int count = 0;
    
    NSString* sql = [NSString stringWithFormat:@"SELECT COUNT(*) FROM %@", tableName];
    
    if (sqlite3_exec(db_, [sql UTF8String], _countTableCallback, &count, &errmsg) != SQLITE_OK) {
        NSLog(@"[ERROR] %s", errmsg);
    }
    return count;
}

@end
