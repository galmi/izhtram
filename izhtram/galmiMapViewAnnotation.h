//
//  galmiMapViewAnnotation.h
//  izhtram
//
//  Created by Ильдар on 05.05.13.
//  Copyright (c) 2013 Ильдар. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MapKit/MapKit.h"

@interface galmiMapViewAnnotation : NSObject<MKAnnotation>
{
    NSString *title;
    CLLocationCoordinate2D coordinate;
}

@property (nonatomic, copy) NSString *title;
@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;

- (id)initWithTitle:(NSString *)title andCoordinate:(CLLocationCoordinate2D)c2d;

@end
