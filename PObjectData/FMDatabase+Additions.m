//
//  FMDatabase+PlainObject.m
//  Demo
//
//  Created by chendailong2014@126.com on 14-4-17.
//  Copyright (c) 2014年 chendailong2014@126.com. All rights reserved.
//

#import "FMDatabase+Additions.h"
#import "JSONKit.h"
#import "ClassProperty.h"
#import "ClassObject.h"
#import "NSObject+Primitive.h"

#define SQL_MAX_LENGTH 1024

@implementation FMDatabase (PlainObject)
- (id)unbindObject:(id)object classObject:(ClassObject *)classObject
{
    if ([classObject testClass:[NSArray class]] || [classObject testClass:[NSDictionary class]])
    {
        object = [object objectFromJSONString];
    }
    
    return object;
}

- (id)bindObject:(id)object classObject:(ClassObject *)classObject
{
    if ([classObject testClass:[NSArray class]] || [classObject testClass:[NSDictionary class]])
    {
        return [object JSONString];
    }
    
    return object;
}

- (NSDictionary *)argumentsWithObject:(id)object
{
    NSDictionary *primitive = [object primitiveObject];
    if (primitive)
    {
        NSMutableDictionary *arguments = [NSMutableDictionary dictionaryWithDictionary:primitive];
        NSArray *keys = arguments.allKeys;
        for (NSString *key in keys)
        {
            id value = arguments[key];
            ClassObject *classObject = [ClassObject classObjectWithObject:value];
            value = [self bindObject:value classObject:classObject];
            if (value)
            {
                arguments[key] = value;
            }
        }
        
        return arguments;
    }
    
    return nil;
}

- (NSString *)databaseTypeWithClassObject:(ClassObject *)classObject
{
    NSString *databaseType = @"TEXT";
    if ([classObject testClass:[NSString class]] || [classObject testClass:[NSArray class]]  || [classObject testClass:[NSDictionary class]])
    {
        databaseType = @"TEXT";
    } else if ([classObject testClass:[NSNumber class]]) {
        databaseType = @"NUMERIC";
    } else if ([classObject testClass:[NSData class]]) {
        databaseType = @"BLOB";
    } else if ([classObject testClass:[NSDate class]]) {
        databaseType = @"TIMESTAMP";
    }
    
    return databaseType;
}

- (BOOL)createTable:(Class)class withKeys:(NSArray *)keys
{
    ClassObject *classObject = [ClassObject classObjectWithNativeClass:class];
    
    NSMutableString *tableString = [NSMutableString stringWithCapacity:SQL_MAX_LENGTH];
    NSArray *classPropertys = classObject.propertys;
    for (ClassProperty *classProperty in classPropertys)
    {
        NSString *propertyName = classProperty.name;
        NSString *databaseType = [self databaseTypeWithClassObject:classProperty.class];
        if ([keys containsObject:propertyName])
        {
            [tableString appendFormat:@",%@ %@ NOT NULL",propertyName,databaseType,nil];
        } else {
            [tableString appendFormat:@",%@ %@",propertyName,databaseType,nil];
        }
    }
    
    NSMutableString *keyString = [NSMutableString stringWithCapacity:SQL_MAX_LENGTH];
    for (NSString *key in keys)
    {
        [keyString appendFormat:@",%@",key,nil];
    }
    
    if (keyString.length > 0)
    {
        [keyString deleteCharactersInRange:NSMakeRange(0, 1)];
        [keyString insertString:@",PRIMARY KEY (" atIndex:0];
        [keyString appendString:@")"];
    }
    
    if (tableString.length > 0)
    {
        [tableString deleteCharactersInRange:NSMakeRange(0, 1)];
        [tableString appendString:@",ext0 TEXT"];
        [tableString appendString:@",ext1 TEXT"];
        [tableString appendString:@",ext2 TEXT"];
        [tableString appendString:@",ext3 TEXT"];
        [tableString appendString:@",ext4 TEXT"];
    }
    
    NSString *sql = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@(%@%@)",classObject.name,tableString,keyString,nil];
    return [self executeUpdate:sql,nil];

}

- (id)valueForClassProperty:(ClassProperty *)classProperty inResultSet:(FMResultSet *)resultSet
{
    id value = nil;
    if ([classProperty.class testClass:[NSDate class]])
    {
        value = [resultSet dateForColumn:classProperty.name];
    } else if ([classProperty.class testClass:[NSData class]]) {
        value = [resultSet dataForColumn:classProperty.name];
    } else {
        value = resultSet[classProperty.name];
    }
    
    return value;
}

- (NSString *)whereString:(NSDictionary *)params
{
    NSMutableString *whereString = [NSMutableString stringWithCapacity:SQL_MAX_LENGTH];
    NSArray *keys = params.allKeys;
    for (NSString *key in keys)
    {
        [whereString appendFormat:@",%@ = :_%@",key,key,nil];
    }
    
    if (whereString.length > 0)
    {
        [whereString deleteCharactersInRange:NSMakeRange(0, 1)];
        [whereString insertString:@"AND " atIndex:0];
    }
    
    return whereString;
}

- (NSMutableDictionary *)whereParmas:(NSDictionary *)params
{
    NSMutableDictionary *whereParams = [NSMutableDictionary dictionaryWithCapacity:params.count];
    [params enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        whereParams[[@"_" stringByAppendingString:key]] = obj;
    }];
    
    return whereParams;
}

- (BOOL)listObjects:(Class)class block:(BOOL(^)(id object))block withParams:(NSDictionary *)params
{
    ClassObject *classObject = [ClassObject classObjectWithNativeClass:class];
    
    NSArray *classPropertys = classObject.propertys;

    NSMutableDictionary *primitiveDictionary = [NSMutableDictionary dictionaryWithCapacity:classPropertys.count];
    primitiveDictionary[@"class"] = classObject.name;
    NSString *sql = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE 1=1 %@",classObject.name,[self whereString:params],nil];
    FMResultSet *resultSet = [self executeQuery:sql withParameterDictionary:[self whereParmas:params]];
    while ([resultSet next])
    {
        @autoreleasepool {
            for (ClassProperty *classProperty in classPropertys)
            {
                NSString *propertyName = classProperty.name;
                id value = [self valueForClassProperty:classProperty inResultSet:resultSet];
                if (value)
                {
                    value = [self unbindObject:value classObject:classProperty.class];
                    if (value)
                    {
                        primitiveDictionary[propertyName] = value;
                    }
                }
            }
            
            id object = [primitiveDictionary objectFromPrimitive];
            if (block)
            {
                if (!block(object))
                {
                    break;
                }
            }
        }
    }
    
    [resultSet close];
    
    return YES;
}

- (BOOL)insertObject:(id)object
{
    ClassObject *classObject = [ClassObject classObjectWithObject:object];

    NSMutableString *intoString   = [NSMutableString stringWithCapacity:SQL_MAX_LENGTH];
    NSMutableString *valuesString = [NSMutableString stringWithCapacity:SQL_MAX_LENGTH];
    NSArray *classPropertys = classObject.propertys;
    for (ClassProperty *classProperty in classPropertys)
    {
        [intoString appendFormat:@",%@",classProperty.name,nil];
        [valuesString appendFormat:@",:%@",classProperty.name,nil];
    }
    
    if (intoString.length > 0)
    {
        [intoString deleteCharactersInRange:NSMakeRange(0, 1)];
        [valuesString deleteCharactersInRange:NSMakeRange(0, 1)];
    }
    
    NSString *sql = [NSString stringWithFormat:@"INSERT INTO %@(%@) VALUES(%@)",classObject.name,intoString,valuesString,nil];
    NSDictionary *arguments = [self argumentsWithObject:object];
    return [self executeUpdate:sql withParameterDictionary:arguments];
}

- (BOOL)updateObject:(id)object withParams:(NSDictionary *)params
{
    assert(params);
    
    ClassObject *classObject = [ClassObject classObjectWithObject:object];
    
    NSMutableString *setString   = [NSMutableString stringWithCapacity:SQL_MAX_LENGTH];
    NSArray *classPropertys = classObject.propertys;
    for (ClassProperty *classProperty in classPropertys)
    {
        [setString appendFormat:@",%@ = :%@",classProperty.name,classProperty.name,nil];
    }
    
    if (setString.length > 0)
    {
        [setString deleteCharactersInRange:NSMakeRange(0, 1)];
    }
    
    NSString *sql = [NSString stringWithFormat:@"UPDATE %@ SET %@ WHERE 1 = 1 %@",classObject.name,setString,[self whereString:params],nil];
    NSDictionary *arguments = [self argumentsWithObject:object];
    NSMutableDictionary *whereParams = [self whereParmas:params];
    [whereParams addEntriesFromDictionary:arguments];
    return [self executeUpdate:sql withParameterDictionary:whereParams];
}

- (BOOL)deleteObject:(Class)class withParams:(NSDictionary *)params
{
    assert(params);

    ClassObject *classObject = [ClassObject classObjectWithNativeClass:class];

    NSString *sql = [NSString stringWithFormat:@"DELETE FROM %@ WHERE 1=1 %@",classObject.name,[self whereString:params],nil];
    return [self executeUpdate:sql withParameterDictionary:[self whereParmas:params]];
}
@end

@implementation FMDatabase (Identifier)

- (BOOL)createTable:(Class)class
{
    return [self createTable:class withKeys:@[@"identifier"]];
}

- (id)listObject:(Class)class withIdentifier:(NSString *)identifier
{
    __block id result = nil;
    [self listObjects:class block:^BOOL(id object) {
        result = object;
        return NO;
    } withParams:@{@"identifier":identifier}];
    
    return result;
}

- (BOOL)updateObject:(id)object
{
    NSString *identifier = [object valueForKey:@"identifier"];
    assert(identifier);
    return [self updateObject:object withParams:@{@"identifier":identifier}];
}

- (BOOL)deleteObject:(Class)class withIdentifier:(NSString *)identifier
{
    assert(identifier);
    return [self deleteObject:class withParams:@{@"identifier":identifier}];
}

@end
