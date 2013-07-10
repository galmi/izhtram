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
#import "galmisearchField.h"

#define CENTER_LAT 56.85000001
#define CENTER_LON 53.216666676667

@interface galmiViewController : UIViewController<MKMapViewDelegate>{
    MKMapView           *_mapView;
	MKPolyline          *_routeLine;
	MKPolylineView      *_routeLineView;
    galmiSearchField    *_fromField;
    galmiSearchField    *_tillField;

    NSMutableDictionary *points;        //все точки из JSON файла
    NSMutableArray      *routes;        //данные  маршрутах
    NSMutableDictionary *neighbors;     //соседи
    NSArray             *activeRoutes;  //активные маршруты
    NSMutableArray      *activePoints;  //активные точки на карте
    NSMutableDictionary *searchStops;         //остановки для поиска
    NSMutableArray      *openSet;
    NSMutableArray      *closedSet;
    NSMutableDictionary *pathPoints;    //все точки для построения пути
    int from_id, till_id;
    NSDictionary *fromPoint;
    NSDictionary *toPoint;
    
    NSMutableArray *overlay1;
    id overlay2;
}

@property (nonatomic, retain) IBOutlet MKMapView *mapView;
@property (nonatomic, retain) IBOutlet galmiSearchField *fromField;
@property (nonatomic, retain) IBOutlet galmiSearchField *tillField;
@property (nonatomic, retain) MKPolyline* routeLine;
@property (nonatomic, retain) MKPolylineView* routeLineView;

- (IBAction)didBeginEditing:(id)sender;
- (IBAction)didEndEditing:(id)sender;
- (IBAction)fromButtonClick:(id)sender;
- (IBAction)tillButtonClick:(id)sender;

@end
