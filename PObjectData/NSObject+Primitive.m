//
//  NSObject+Primitive.m
//  Demo
//
//  Created by chendailong2014@126.com on 14-4-17.
//  Copyright (c) 2014年 chendailong2014@126.com. All rights reserved.
//

#import "NSObject+Primitive.h"
#import "ClassObject.h"
#import "ClassProperty.h"

@implementation NSObject (Primitive)
- (id)primitiveObject
{
    ClassObject *classObject = [ClassObject classObjectWithObject:self];

    if([classObject testClass:[NSString class]] ||
       [classObject testClass:[NSNumber class]] ||
       [classObject testClass:[NSData class]]   ||
       [classObject testClass:[NSDate class]])
    {
        return self;
    }
    
    if ([classObject testClass:[NSArray class]])
    {
        NSArray *array = (NSArray *)self;
        NSMutableArray *resultArray = [NSMutableArray arrayWithCapacity:array.count];
        for (id value in array)
        {
            id primitive = [value primitiveObject];
            if (primitive)
            {
                [resultArray addObject:primitive];
            }
        }
        return resultArray;
    }
    
    if ([classObject testClass:[NSDictionary class]])
    {
        NSDictionary *dictionary = (NSDictionary *)self;
        NSMutableDictionary *resultDictionary = [NSMutableDictionary dictionaryWithCapacity:dictionary.count];
        NSArray *keys = [dictionary allKeys];
        for (NSString *key in keys)
        {
            id value = dictionary[key];
            id primitive = [value primitiveObject];
            if (primitive)
            {
                resultDictionary[key] = primitive;
            }
        }
        return resultDictionary;
    }
    
    NSArray *classPropertys = classObject.propertys;
    
    NSMutableDictionary *resultDictionary = [NSMutableDictionary dictionaryWithCapacity:classPropertys.count];
    for (ClassProperty *classProperty in classPropertys)
    {
        id value = [self valueForKey:classProperty.name];
        if (value != nil)
        {
            id primitive = [value primitiveObject];
            if (primitive)
            {
                resultDictionary[classProperty.name] = primitive;
            }
        }
    }
    
    resultDictionary[@"class"] = classObject.name;
    
    return resultDictionary;
}

- (id)objectFromPrimitive
{
    ClassObject *classObject = [ClassObject classObjectWithObject:self];
    
    if([classObject testClass:[NSString class]] ||
       [classObject testClass:[NSNumber class]] ||
       [classObject testClass:[NSData class]]   ||
       [classObject testClass:[NSDate class]])
    {
        return self;
    }
    
    if ([classObject testClass:[NSArray class]])
    {
        NSArray *array = (NSArray *)self;
        NSMutableArray *resultArray = [NSMutableArray arrayWithCapacity:array.count];
        for (id value in array)
        {
            id object = [value objectFromPrimitive];
            if (object)
            {
                [resultArray addObject:object];
            }
        }
        return resultArray;
    }
    
    if ([classObject testClass:[NSDictionary class]])
    {
        NSDictionary *dictionary = (NSDictionary *)self;
        NSString *className = dictionary[@"class"];
        if (className)
        {
            ClassObject *objectClass = [ClassObject classObjectWithName:className];
            if (objectClass)
            {
                id newObject = [objectClass newObject];
                NSArray *classPropertys = objectClass.propertys;
                for (ClassProperty *classProperty in classPropertys)
                {
                    id value  = dictionary[classProperty.name];
                    id object = [value objectFromPrimitive];
                    if (object)
                    {
                        [newObject setValue:object forKey:classProperty.name];
                    }
                }
                
                return [newObject autorelease];
            }
        } else {
            NSMutableDictionary *resultDictionary = [NSMutableDictionary dictionaryWithCapacity:dictionary.count];
            NSArray *keys = [dictionary allKeys];
            for (NSString *key in keys)
            {
                id value  = dictionary[key];
                id object = [value objectFromPrimitive];
                if (object)
                {
                    resultDictionary[key] = object;
                }
            }
            return resultDictionary;
        }
    }
    
    return nil;

}

@end
