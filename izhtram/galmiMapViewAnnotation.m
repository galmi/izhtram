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

- (id)initWithTitle:(NSString *)title andCoordinate:(CLLocationCoordinate2D)c2d {
	self.title = title;
	coordinate = c2d;
	return self;
}

@end
