//
//  galmiMapViewAnnotation.m
//  izhtram
//
//  Created by Ильдар on 05.05.13.
//  Copyright (c) 2013 Ильдар. All rights reserved.
//

#import "galmiMapViewAnnotation.h"

@implementation galmiMapViewAnnotation

@synthesize title, coordinate;

@synthesize image, key;

-(id) initWithCoordinate:(CLLocationCoordinate2D)location
                   title:(NSString *)ttl
                    icon:(UIImage*) icon
                uniqueKey:(NSString*) uniqueKey
{
    self = [super init];
	self.title = ttl;
    coordinate = location;
    [self setImage:icon];
    [self setKey:uniqueKey];
    
    return self;
}

- (id)initWithTitle:(NSString *)ttl andCoordinate:(CLLocationCoordinate2D)c2d {
	self.title = ttl;
	coordinate = c2d;
	return self;
}

@end
