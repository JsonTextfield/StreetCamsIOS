//
//  MyDB.m
//  Ottawa Basketball Courts
//
//  Created by Peckford on 2017-06-03.
//  Copyright © 2017 JsonTextfield. All rights reserved.
//


#import "CamDB.h"
#import "Ottawa_Street_Cameras-Swift.h"
@implementation CamDB

static CamDB* _database;

+ (CamDB*) database {
    if (_database == nil) {
        _database = [[CamDB alloc] init];
    }
    return _database;
}
- (id)init {
    if ((self = [super init])) {
        NSString *sqLiteDb = [[NSBundle mainBundle] pathForResource:@"camera_list" ofType:@"db"];
        
        if (sqlite3_open([sqLiteDb UTF8String], &_database) != SQLITE_OK) {
            NSLog(@"Failed to open database!");
        }
    }
    return self;
}

- (void)dealloc {
    sqlite3_close(_database);
}

- (int) mycallback{
    
    return 0;
}

- (NSArray *)cameras {
    
    
    
    NSMutableArray* list = [[NSMutableArray alloc] init];
    NSString *query = @"select * from cameras";
    sqlite3_stmt *statement;
    if (sqlite3_prepare_v2(_database, [query UTF8String], -1, &statement, nil) == SQLITE_OK) {
        
        while (sqlite3_step(statement) == SQLITE_ROW) {
            
            int id = sqlite3_column_int(statement, 0);
            int num = sqlite3_column_int(statement, 1);
            char *nameChars = (char *) sqlite3_column_text(statement, 2);
            char *nameFrChars = (char *) sqlite3_column_text(statement, 3);
            char *ownerChars = (char *) sqlite3_column_text(statement, 4);
            double lat = sqlite3_column_double(statement, 5);
            double lng = sqlite3_column_double(statement, 6);
            
            NSString *name = [[NSString alloc] initWithUTF8String:nameChars];
            NSString *nameFr = [[NSString alloc] initWithUTF8String:nameFrChars];
            NSString *owner = [[NSString alloc] initWithUTF8String:ownerChars];
            if([owner isEqualToString:@"MTO"]){
                num += 2000;
            }
            
            Camera* cam = [[Camera alloc] init];
            cam.name = name;
            cam.nameFr = nameFr;
            cam.id = id;
            cam.num = num;
            cam.lat = lat;
            cam.lng= lng;
            cam.owner = owner;
            [list addObject:cam];
        }
        
        sqlite3_finalize(statement);
    }
    else{
        NSLog(@"%s", sqlite3_errmsg(_database));
    }
    
    return list;
    
}
@end
