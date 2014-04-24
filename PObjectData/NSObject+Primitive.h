//
//  NSObject+Primitive.h
//  Demo
//
//  Created by chendailong2014@126.com on 14-4-17.
//  Copyright (c) 2014年 chendailong2014@126.com. All rights reserved.
//

#import <Foundation/Foundation.h>

//Primitive
//@String,@Number,@Date,NSData,NSArray,NSDictionary,Plain old Object
@interface NSObject (Primitive)
- (id)primitiveObject;
- (id)objectFromPrimitive;
@end
