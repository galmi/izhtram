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

    //активные маршруты
    activeRoutes = [[NSArray alloc]initWithObjects:@"21",@"22",@"23",@"24",@"25",@"26",@"27",@"28",@"29",@"30",@"31",@"32", nil];
    //активные точки
    activePoints = [[NSMutableArray alloc]initWithObjects:nil];
    //массив для фильтрации точек на карте
    NSPredicate *intersectPredicate = [NSPredicate predicateWithFormat:@"SELF IN %@", activeRoutes];
    
    points = [[NSMutableDictionary alloc]initWithObjectsAndKeys:nil];
    //инициализация карты
    int zoomLevel = 12;
    CLLocationCoordinate2D center = CLLocationCoordinate2DMake(CENTER_LAT, CENTER_LON);
    MKCoordinateSpan span = MKCoordinateSpanMake(0, 360/pow(2, zoomLevel)*self.view.frame.size.width/256);
    [self.mapView setRegion:MKCoordinateRegionMake(center, span)];
    
    // обработка JSON данных об остановках
    NSString* filePath = [[NSBundle mainBundle] pathForResource:@"stops" ofType:@"json"];
    NSData *data =  [NSData dataWithContentsOfFile:filePath];
    NSError *e = nil;
    NSDictionary *stops = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&e];
    //заполняем словарь остановками
    for(NSDictionary *row in stops)
    {
        [points setValue:row forKey:[NSString stringWithFormat:@"%@", [row valueForKey:@"id"]]];
    }
    //Обрабатываем JSON данные о роутах между остановками
    filePath = [[NSBundle mainBundle] pathForResource:@"routes" ofType:@"json"];
    data = [NSData dataWithContentsOfFile:filePath];
    NSDictionary *routes = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&e];
    for(NSDictionary *row in routes)
    {
        NSArray *fullPath = [[row valueForKey:@"full_path"]componentsSeparatedByString:@";"];
        NSArray *routesFilter = [[row valueForKey:@"routes"]componentsSeparatedByString:@","];
        //рисовать будем только маршруты разрешенного транспорта
        if ([[routesFilter filteredArrayUsingPredicate:intersectPredicate]count]==0) {
            continue;
        }
        int fullPathSize = [fullPath count]/2;
        int i = 0;
        CLLocationCoordinate2D coordinates[fullPathSize+2];
        //начинаем маршрут с начальной остановки
        NSArray *stop1 = [points valueForKey:[NSString stringWithFormat:@"%@", [row valueForKey:@"stop1_id"]]];
        if (stop1!=nil) {
            CLLocationCoordinate2D location = CLLocationCoordinate2DMake([[points valueForKey:@"lat"] doubleValue], [[points valueForKey:@"lng"] doubleValue]);
            coordinates[i] = location;
        }
        i = i+1;
        //добавляем в маршрут промежуточные точки
        for (i = i; i<=fullPathSize; i=i+1) {
            CLLocationCoordinate2D location = CLLocationCoordinate2DMake([[fullPath objectAtIndex:((i-1)*2+1)] doubleValue], [[fullPath objectAtIndex:(i-1)*2] doubleValue]);
            coordinates[i-1] = location;
        }
        //заканчиваем маршрут конечной остановкой
        NSArray *stop2 = [points valueForKey:[NSString stringWithFormat:@"%@", [row valueForKey:@"stop2_id"]]];
        if (stop2!=nil) {
            CLLocationCoordinate2D location = CLLocationCoordinate2DMake([[points valueForKey:@"lat"] doubleValue], [[points valueForKey:@"lng"] doubleValue]);
            coordinates[i] = location;
        }
        //добавляем id остановки для отображения на карте
        [activePoints addObject:[row valueForKey:@"stop1_id"]];
        [activePoints addObject:[row valueForKey:@"stop2_id"]];
        //рисуем маршрут между соседними остановками
        MKPolyline *polyLine = [MKPolyline polylineWithCoordinates:coordinates count:fullPathSize];
        [self.mapView addOverlay:polyLine];
    }

    //Показываем разрешенные остановки на карте
    for(NSDictionary *row in stops)
    {
        if ([[row valueForKey:@"v"]boolValue] && [activePoints containsObject:[row valueForKey:@"id"]])
        {
            CLLocationCoordinate2D location = CLLocationCoordinate2DMake([[row objectForKey:@"lat"] doubleValue], [[row valueForKey:@"lng"] doubleValue]);
            NSString *title = [row valueForKey:@"name"];
            //galmiMapViewAnnotation *annotation = [[galmiMapViewAnnotation alloc]initWithTitle:title andCoordinate:location];
            galmiMapViewAnnotation *annotation = [[galmiMapViewAnnotation alloc]initWithCoordinate:location title:title icon:[UIImage imageNamed:@"marker"] uniqueKey:[row valueForKey:@"id"]];
            [self.mapView addAnnotation:annotation];
        }
    }

    //Заполняем остановки для поиска
    searchStops = [[NSMutableDictionary alloc]initWithObjectsAndKeys:nil];
    for(NSString *index in activePoints)
    {
        [searchStops setValue:[points valueForKey:[NSString stringWithFormat:@"%@",index]] forKey:[NSString stringWithFormat:@"%@",index]];
    }
    
}

//отображение кастомной точки на карте
- (MKAnnotationView *)mapView:(MKMapView *)map viewForAnnotation:(id <MKAnnotation>)annotation
{
    MKAnnotationView *view = nil;
    //для точки, обозначающей текущее местоположение, вид не меняем
    if (annotation != self.mapView.userLocation) {
        view = [self.mapView dequeueReusableAnnotationViewWithIdentifier:@"myAnnotationIdentifier"];
        if (!view) {
            galmiMapViewAnnotation *m = (galmiMapViewAnnotation *)annotation;
            view = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"myAnnotationIdentifier"];
            view.image = m.image;
            view.tag = [m.key intValue];
            view.canShowCallout = YES;
            
            // Create a UIButton object to add on the
            UIButton *leftButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
            [leftButton setTitle:annotation.title forState:UIControlStateNormal];
            [leftButton addTarget:self action:@selector(fromButtonClick:) forControlEvents:UIControlEventTouchUpInside];
            [leftButton setTitle:[NSString stringWithFormat:@"%@",m.key] forState:UIControlStateNormal];
            [view setLeftCalloutAccessoryView:leftButton];

            UIButton *rightButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
            [rightButton setTitle:annotation.title forState:UIControlStateNormal];
            [rightButton addTarget:self action:@selector(tillButtonClick:) forControlEvents:UIControlEventTouchUpInside];
            [rightButton setTitle:[NSString stringWithFormat:@"%@",m.key] forState:UIControlStateNormal];
            [view setRightCalloutAccessoryView:rightButton];
        }
    }
    return view;
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    //определяем ближайшую остановку
    [self nearestStop];
}

//параметры отображения линии маршрута
- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id )overlay
{
    MKPolylineView *overlayView = [[MKPolylineView alloc] initWithPolyline:overlay];
    overlayView.fillColor = [UIColor blackColor];
    overlayView.strokeColor = [UIColor blackColor];
    overlayView.lineWidth = 3;
    return overlayView;
}

//определение ближайшей остановки пользователя
-(void)nearestStop
{
    if (self.fromField.gps==true)
    {
        return;
    }
    int i, id;
    CLLocationDistance min;
    CLLocationCoordinate2D userCoordinate = self.mapView.userLocation.coordinate;
    CLLocation *userLocation = [[CLLocation alloc]initWithLatitude:userCoordinate.latitude longitude:userCoordinate.longitude];
    i = 0;
    for(NSNumber *index in searchStops)
    {
        NSDictionary *row = [searchStops valueForKey:[NSString stringWithFormat:@"%@",index]];

        CLLocation *pointLocation = [[CLLocation alloc]initWithLatitude:[[row valueForKey:@"lat"]doubleValue] longitude:[[row valueForKey:@"lng"]doubleValue]];
        CLLocationDistance dist = [userLocation distanceFromLocation:pointLocation];
        if (i==0 || min>dist)
        {
            min = dist;
            id = [[row valueForKey:@"id"]intValue];
        }
        i = i + 1;
    }
    if (from_id!=id)
    {
        galmiMapViewAnnotation *view;
        view = [self.view viewWithTag:from_id];
        if ([view class]==[MKAnnotationView class])
            view.image = [UIImage imageNamed:@"marker"];
        from_id = id;
        NSDictionary *stop = [points valueForKey:[NSString stringWithFormat:@"%d", from_id]];
        view = [self.view viewWithTag:from_id];
        if ([view class]==[MKAnnotationView class])
            view.image = [UIImage imageNamed:@"marker_selected"];
        self.fromField.text = [stop valueForKey:@"name"];
    }
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    [textField resignFirstResponder];
    return YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
}

- (IBAction)didBeginEditing:(id)sender {

}

- (IBAction)didEndEditing:(id)sender {

}

//Нажатие кнопки Откуда
- (IBAction)fromButtonClick:(id)sender {
    UIButton *m = sender;
    galmiMapViewAnnotation *view;
    view = [self.view viewWithTag:from_id];
    if ([view class]==[MKAnnotationView class])
        view.image = [UIImage imageNamed:@"marker"];
    from_id = [[m titleForState:UIControlStateNormal]intValue];
    NSDictionary *stop = [points valueForKey:[NSString stringWithFormat:@"%d", from_id]];
    view = [self.view viewWithTag:from_id];
    if ([view class]==[MKAnnotationView class])
        view.image = [UIImage imageNamed:@"marker_selected"];
    self.fromField.text = [stop valueForKey:@"name"];
    self.fromField.gps = true;
    [self closeAnnotations];
}

//Нажатие кнопки Куда
- (IBAction)tillButtonClick:(id)sender {
    UIButton *m = sender;
    galmiMapViewAnnotation *view;
    view = [self.view viewWithTag:till_id];
    if ([view class]==[MKAnnotationView class])
        view.image = [UIImage imageNamed:@"marker"];
    till_id = [[m titleForState:UIControlStateNormal]intValue];
    NSDictionary *stop = [points valueForKey:[NSString stringWithFormat:@"%d", till_id]];
    view = [self.view viewWithTag:till_id];
    if ([view class]==[MKAnnotationView class])
        view.image = [UIImage imageNamed:@"marker_selected"];
    self.tillField.text = [stop valueForKey:@"name"];
    [self closeAnnotations];
}

-(void)closeAnnotations
{
    for (id<MKAnnotation> ann in self.mapView.selectedAnnotations) {
        [self.mapView deselectAnnotation:ann animated:YES];
    }
}

@end
