//
//  FMDatabase+PlainObject.h
//  Demo
//
//  Created by chendailong2014@126.com on 14-4-17.
//  Copyright (c) 2014年 chendailong2014@126.com. All rights reserved.
//

#import "FMDatabase.h"

@interface FMDatabase (PlainObject)
- (BOOL)createTable:(Class)class withKeys:(NSArray *)keys;
- (BOOL)listObjects:(Class)class block:(BOOL(^)(id object))block withParams:(NSDictionary *)params;
- (BOOL)insertObject:(id)object;
- (BOOL)updateObject:(id)object withParams:(NSDictionary *)params;
- (BOOL)deleteObject:(Class)class withParams:(NSDictionary *)params;
@end


@interface FMDatabase (Identifier)
- (BOOL)createTable:(Class)class;
- (id)listObject:(Class)class withIdentifier:(NSString *)identifier;
- (BOOL)updateObject:(id)object;
- (BOOL)deleteObject:(Class)class withIdentifier:(NSString *)identifier;
@end