//
//  MyDB.h
//  Ottawa Basketball Courts
//
//  Created by Peckford on 2017-06-03.
//  Copyright © 2017 JsonTextfield. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <sqlite3.h>
@interface CamDB : NSObject {
    sqlite3* _database;
}

+ (CamDB*) database;
- (NSArray*) cameras;
@end
