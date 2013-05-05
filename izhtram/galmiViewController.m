//
//  galmiViewController.m
//  izhtram
//
//  Created by Ильдар on 04.05.13.
//  Copyright (c) 2013 Ильдар. All rights reserved.
//

#import "galmiViewController.h"

@interface galmiViewController ()

@end

@implementation galmiViewController

@synthesize mapView = _mapView;
@synthesize routeLine = _routeLine;
@synthesize routeLineView = _routeLineView;
@synthesize fromField = _fromField;
@synthesize tillField = _tillField;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    //активные маршруты
    active = [[NSArray alloc]initWithObjects:@"21",@"22",@"23",@"24",@"25",@"26",@"27",@"28",@"29",@"30",@"31",@"32", nil];
    //активные точки
    activePoints = [[NSMutableArray alloc]initWithObjects:nil];
    NSPredicate *intersectPredicate = [NSPredicate predicateWithFormat:@"SELF IN %@", active];
    points = [[NSMutableDictionary alloc]initWithObjectsAndKeys:nil];
    int zoomLevel = 12;
    CLLocationCoordinate2D center = CLLocationCoordinate2DMake(CENTER_LAT, CENTER_LON);
    MKCoordinateSpan span = MKCoordinateSpanMake(0, 360/pow(2, zoomLevel)*self.view.frame.size.width/256);
    [self.mapView setRegion:MKCoordinateRegionMake(center, span)];
    
    // остановки
    NSString* filePath = [[NSBundle mainBundle] pathForResource:@"stops" ofType:@"json"];
    NSData *data =  [NSData dataWithContentsOfFile:filePath];
    NSError *e = nil;
    NSDictionary *stops = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&e];
    
    for(NSDictionary *row in stops)
    {
        [points setValue:row forKey:[NSString stringWithFormat:@"%@", [row valueForKey:@"id"]]];
    }

    filePath = [[NSBundle mainBundle] pathForResource:@"routes" ofType:@"json"];
    data = [NSData dataWithContentsOfFile:filePath];
    NSDictionary *routes = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&e];
    
    for(NSDictionary *row in routes)
    {
        NSArray *fullPath = [[row valueForKey:@"full_path"]componentsSeparatedByString:@";"];
        NSArray *routesFilter = [[row valueForKey:@"routes"]componentsSeparatedByString:@","];
        if ([[routesFilter filteredArrayUsingPredicate:intersectPredicate]count]==0) {
            continue;
        }
        int fullPathSize = [fullPath count]/2;
        int i = 0;
        CLLocationCoordinate2D coordinates[fullPathSize+2];
        //начальная остановка
        NSArray *stop1 = [points valueForKey:[NSString stringWithFormat:@"%@", [row valueForKey:@"stop1_id"]]];
        if (stop1!=nil) {
            CLLocationCoordinate2D location = CLLocationCoordinate2DMake([[points valueForKey:@"lat"] doubleValue], [[points valueForKey:@"lng"] doubleValue]);
            coordinates[i] = location;
        }
        i = i+1;
        //промежуточные точки пути
        for (i = i; i<=fullPathSize; i=i+1) {
            CLLocationCoordinate2D location = CLLocationCoordinate2DMake([[fullPath objectAtIndex:((i-1)*2+1)] doubleValue], [[fullPath objectAtIndex:(i-1)*2] doubleValue]);
            coordinates[i-1] = location;
        }
        //конечная остановка
        NSArray *stop2 = [points valueForKey:[NSString stringWithFormat:@"%@", [row valueForKey:@"stop2_id"]]];
        if (stop2!=nil) {
            CLLocationCoordinate2D location = CLLocationCoordinate2DMake([[points valueForKey:@"lat"] doubleValue], [[points valueForKey:@"lng"] doubleValue]);
            coordinates[i] = location;
        }

        [activePoints addObject:[row valueForKey:@"stop1_id"]];
        [activePoints addObject:[row valueForKey:@"stop2_id"]];

        MKPolyline *polyLine = [MKPolyline polylineWithCoordinates:coordinates count:fullPathSize];
        [self.mapView addOverlay:polyLine];
    }

    //Показываем оставшиеся точки
    for(NSDictionary *row in stops)
    {
        if ([[row valueForKey:@"v"]boolValue] && [activePoints containsObject:[row valueForKey:@"id"]])
        {
            CLLocationCoordinate2D location = CLLocationCoordinate2DMake([[row objectForKey:@"lat"] doubleValue], [[row valueForKey:@"lng"] doubleValue]);
            NSString *title = [row valueForKey:@"name"];
            galmiMapViewAnnotation *annotation = [[galmiMapViewAnnotation alloc]initWithTitle:title andCoordinate:location];
            [self.mapView addAnnotation:annotation];
        }
    }

}

- (MKAnnotationView *)mapView:(MKMapView *)map viewForAnnotation:(id <MKAnnotation>)annotation
{
    // If you are showing the users location on the map you don't want to change it
    MKAnnotationView *view = nil;
    if (annotation != self.mapView.userLocation) {
        // This is not the users location indicator (the blue dot)
        view = [self.mapView dequeueReusableAnnotationViewWithIdentifier:@"myAnnotationIdentifier"];
        if (!view) {
            // Creating a new annotation view
            view = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"myAnnotationIdentifier"];
            // This will rescale the annotation view to fit the image
            view.image = [UIImage imageNamed:@"marker"];
            view.canShowCallout = YES;
        }
    }
    return view;
}

- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id )overlay
{
    MKPolylineView *overlayView = [[MKPolylineView alloc] initWithPolyline:overlay];
    overlayView.fillColor = [UIColor redColor];
    overlayView.strokeColor = [UIColor redColor];
    overlayView.lineWidth = 3;
    return overlayView;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
}

@end
