//
//  galmiViewController.h
//  izhtram
//
//  Created by Ильдар on 04.05.13.
//  Copyright (c) 2013 Ильдар. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "galmiMapViewAnnotation.h"

#define CENTER_LAT 56.85000001
#define CENTER_LON 53.216666676667

@interface galmiViewController : UIViewController<MKMapViewDelegate>{
    MKMapView *_mapView;
	MKPolyline* _routeLine;
	MKPolylineView* _routeLineView;
    UITextField *_fromField;
    UITextField *_tillField;
    NSMutableDictionary *points;
    NSArray *active;
    NSMutableArray *activePoints;
    dispatch_queue_t queue;
}

@property (nonatomic, retain) IBOutlet MKMapView *mapView;
@property (nonatomic, retain) IBOutlet UITextField *fromField;
@property (nonatomic, retain) IBOutlet UITextField *tillField;
@property (nonatomic, retain) MKPolyline* routeLine;
@property (nonatomic, retain) MKPolylineView* routeLineView;

@end
