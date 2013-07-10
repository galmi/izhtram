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

    //обработанные вершины
    closedSet = [[NSMutableArray alloc]initWithObjects:nil];
    //необработанные вершины
    openSet = [[NSMutableArray alloc]initWithObjects:nil];

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
    routes = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&e];
    NSMutableArray *tmpRoutes = [[NSMutableArray alloc]initWithObjects:nil];
    neighbors = [[NSMutableDictionary alloc]initWithObjectsAndKeys:nil];
    NSString *key = @"";
    overlay1 = [[NSMutableArray alloc]initWithObjects:nil];
    for(NSDictionary *row in routes)
    {
        NSArray *fullPath = [[row valueForKey:@"full_path"]componentsSeparatedByString:@";"];
        NSArray *routesFilter = [[row valueForKey:@"routes"]componentsSeparatedByString:@","];
        //рисовать будем только маршруты разрешенного транспорта
        if ([[routesFilter filteredArrayUsingPredicate:intersectPredicate]count]==0) {
            continue;
        }
        //добавляем к остановке соседа
        NSMutableArray *nrow = [[NSMutableArray alloc]initWithObjects:nil];
        key = [NSString stringWithFormat:@"%@", [row valueForKey:@"stop1_id"]];
        if ([neighbors valueForKey:key]!=nil)
        {
            nrow = [NSMutableArray arrayWithArray:[neighbors valueForKey:key]];
        }
        [nrow addObject:[row valueForKey:@"stop2_id"]];
        [neighbors setValue:nrow forKey:key];
        key = [NSString stringWithFormat:@"%@", [row valueForKey:@"stop2_id"]];
        nrow = [NSMutableArray arrayWithObjects:nil];
        if ([neighbors valueForKey:key]!=nil)
        {
            nrow = [NSMutableArray arrayWithArray:[neighbors valueForKey:key]];
        }
        [nrow addObject:[row valueForKey:@"stop1_id"]];
        [neighbors setValue:nrow forKey:key];
        
        [tmpRoutes addObject:row];
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
        [overlay1 addObject:polyLine];
        [self.mapView addOverlay:polyLine];
    }
    routes = [NSMutableArray arrayWithArray:tmpRoutes];
    [tmpRoutes removeAllObjects];
    NSMutableDictionary *tmpPoints = [[NSMutableDictionary alloc]initWithObjectsAndKeys:nil];
    for(NSNumber *id in activePoints)
    {
        NSString *key = [NSString stringWithFormat:@"%@",id];
        [tmpPoints setValue:[points valueForKey:key] forKey:key];
    }
    points = [NSDictionary dictionaryWithDictionary:tmpPoints];
    [tmpPoints removeAllObjects];

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
    if ([overlay1 containsObject:overlay]) {
        overlayView.fillColor = [UIColor blackColor];
        overlayView.strokeColor = [UIColor blackColor];
    } else if(overlay==overlay2) {
        overlayView.fillColor = [UIColor redColor];
        overlayView.strokeColor = [UIColor redColor];
        overlayView.tag = 555;
    }
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
    fromPoint = [points valueForKey:[NSString stringWithFormat:@"%d", from_id]];
    view = [self.view viewWithTag:from_id];
    if ([view class]==[MKAnnotationView class])
        view.image = [UIImage imageNamed:@"marker_selected"];
    self.fromField.text = [fromPoint valueForKey:@"name"];
    self.fromField.gps = true;
    [self closeAnnotations];
    [self makePath];
}

//Нажатие кнопки Куда
- (IBAction)tillButtonClick:(id)sender {
    UIButton *m = sender;
    galmiMapViewAnnotation *view;
    view = [self.view viewWithTag:till_id];
    if ([view class]==[MKAnnotationView class])
        view.image = [UIImage imageNamed:@"marker"];
    till_id = [[m titleForState:UIControlStateNormal]intValue];
    toPoint = [points valueForKey:[NSString stringWithFormat:@"%d", till_id]];
    view = [self.view viewWithTag:till_id];
    if ([view class]==[MKAnnotationView class])
        view.image = [UIImage imageNamed:@"marker_selected"];
    self.tillField.text = [toPoint valueForKey:@"name"];
    [self closeAnnotations];
    [self makePath];
}

-(void)closeAnnotations
{
    for (id<MKAnnotation> ann in self.mapView.selectedAnnotations) {
        [self.mapView deselectAnnotation:ann animated:YES];
    }
}

-(void)makePath
{
    if (fromPoint!=nil && toPoint!=nil)
    {
        NSArray *path = [self astarWithStart:[fromPoint valueForKey:@"id"] andGoal:[toPoint valueForKey:@"id"]];
        CLLocationCoordinate2D coordinates[[path count]];
        int i=0;
        for(NSDictionary *row in path)
        {
            CLLocationCoordinate2D location = CLLocationCoordinate2DMake([[row valueForKey:@"lat"]doubleValue], [[row valueForKey:@"lng"]doubleValue]);
            coordinates[i]=location;
            i++;
        }
        //рисуем маршрут между соседними остановками
        UIView *tmp = [self.view.window viewWithTag:555];
        [tmp removeFromSuperview];

        MKPolyline *polyLine = [MKPolyline polylineWithCoordinates:coordinates count:[path count]];
        overlay2 = polyLine;
        [self.mapView addOverlay:polyLine];
    }
}

-(NSArray *)astarWithStart:(NSNumber *)startId andGoal:(NSNumber *)goalId
{
    pathPoints = nil;
    pathPoints = [[NSMutableDictionary alloc]initWithDictionary:points copyItems:YES];
    [openSet removeAllObjects];
    [closedSet removeAllObjects];
    NSMutableDictionary *start = [[NSMutableDictionary alloc]initWithDictionary:[pathPoints valueForKey:[NSString stringWithFormat:@"%@",startId]]];
    NSMutableDictionary *goal = [pathPoints valueForKey:[NSString stringWithFormat:@"%@", goalId]];
    //заполняем свойства вершины Start
    NSNumber *g = @0;
    NSNumber *h = [self costEstimateFrom:start andTill:[pathPoints valueForKey:[NSString stringWithFormat:@"%@", goalId]]];
    NSNumber *f = [NSNumber numberWithDouble: ([g doubleValue] + [h doubleValue])];
    [start setValue:g forKey:@"g"];
    [start setValue:h forKey:@"h"];
    [start setValue:f forKey:@"f"];
    [pathPoints setValue:start forKey:[NSString stringWithFormat:@"%@",startId]];
    [openSet addObject:start];
    NSDictionary *x = [[NSDictionary alloc]initWithObjectsAndKeys:nil];
    NSArray *neighborNodes = [[NSArray alloc]initWithObjects:nil];
    NSString *key = @"";
//    NSMutableDictionary *yPoint = [[NSMutableDictionary alloc]initWithDictionary:nil];
    while ([openSet count]>0)
    {
        x = [self minF:openSet];
        NSMutableDictionary *xCheck = [[NSMutableDictionary alloc]initWithDictionary:x];
        [xCheck removeObjectsForKeys:[NSArray arrayWithObjects:@"g", @"h", @"f", @"came_from", nil]];
        if ([xCheck isEqualToDictionary:goal])
        {
            NSArray *result = [[NSArray alloc]initWithArray:[self reconstructPathStart:start andTill:[pathPoints valueForKey:[NSString stringWithFormat:@"%@", goalId]]]];
            return result; //заполняем карту path_map
        }
        [openSet removeObjectIdenticalTo:x]; // Вершина x пошла на обработку, а значит её следует удалить из очереди на обработку
        [closedSet addObject:x]; // И добавить в список уже обработанных
        neighborNodes = [[NSArray alloc] initWithArray:[self neighborFor:x]];
        for (NSNumber *y in neighborNodes) // Проверяем каждого соседа x
        {
//            [yPoint removeAllObjects];
            NSMutableDictionary *yPoint = [[NSMutableDictionary alloc]initWithDictionary: [pathPoints valueForKey:[NSString stringWithFormat:@"%@", y]]];
            key = [NSString stringWithFormat:@"%@", y];
            if ([closedSet containsObject:[pathPoints valueForKey:key]]) // Пропускаем соседей из закрытого списка
            {
                continue;
            }
            BOOL tentative_is_better = NO;
            float tentative_g_score = [[x valueForKey:@"g"]floatValue] + [[self costEstimateFrom:x andTill:yPoint]floatValue]; // Вычисляем g(x) для обрабатываемого соседа
            if (![openSet containsObject:yPoint]) // Если сосед x ещё не в открытом списке - добавим его туда
            {
                tentative_is_better = YES;
            } else { // Сосед был в открытом списке, а значит мы уже знаем его g(x), h(x) и f(x)
                if (tentative_g_score < [[yPoint valueForKey:@"g"]floatValue])
                {
                    // Вычисленная g(x) оказалась меньше, а значит нужно будет обновить  g(x), h(x), f(x)
                    tentative_is_better = YES;
                } else {
                    // Вычисленная g(x) оказалась больше, чем имеющаяся в openset.
                    // Это означает, что из вершины x путь через этого соседа дороже
                    // т.е. существует менее дорогой маршрут, пролегающий через этого соседа (из какой-то другой вершины, не из x)
                    // Поэтому данного соседа мы игнорируем
                    tentative_is_better = NO;
                }
            }
            if (tentative_is_better==YES)
            {
                [yPoint setValue:[x valueForKey:@"id"] forKey:@"came_from"];
                [yPoint setValue:[NSNumber numberWithFloat:tentative_g_score] forKey:@"g"];
                [yPoint setValue:[self costEstimateFrom:yPoint andTill:[pathPoints valueForKey:[NSString stringWithFormat:@"%@", goalId]]] forKey:@"h"];
                float f = [[yPoint valueForKey:@"g"]floatValue] + [[yPoint valueForKey:@"h"]floatValue];
                [yPoint setValue:[NSNumber numberWithFloat:f] forKey:@"f"];
                [pathPoints setValue:yPoint forKey:[NSString stringWithFormat:@"%@", y]];
                [openSet addObject:yPoint];
            }
        }
    }
    return nil;
}

-(NSNumber *)costEstimateFrom:(NSDictionary *)start andTill:(NSDictionary *)goal
{
    CLLocation *startLocation = [[CLLocation alloc]initWithLatitude:[[start valueForKey:@"lat"]doubleValue] longitude:[[start valueForKey:@"lng"]doubleValue]];
    CLLocation *goalLocation = [[CLLocation alloc]initWithLatitude:[[goal valueForKey:@"lat"]doubleValue] longitude:[[goal valueForKey:@"lng"]doubleValue]];
    
    CLLocationDistance dist = [goalLocation distanceFromLocation:startLocation];
    return [NSNumber numberWithDouble:dist];
}

-(NSDictionary *)minF:(NSArray *)from
{
    NSUInteger index = 0;
    double min;
    int i;
    for (i=0;i<[from count];i++)
    {
        double test = [[[from objectAtIndex:i] valueForKey:@"f"] doubleValue];
        if (index==0 || min<test)
        {
            min = test;
            index = i;
        }
    }
    return [from objectAtIndex:index];
}

-(NSArray *)reconstructPathStart:(NSDictionary *)start andTill:(NSDictionary *)goal
{
    //карта пройденных вершин
    NSMutableArray *pathMap = [[NSMutableArray alloc]initWithObjects:nil];
    NSDictionary *current_node = [[NSDictionary alloc]initWithDictionary:goal];
    while (current_node!=nil) {
        [pathMap addObject:current_node];
        current_node = [pathPoints valueForKey:[NSString stringWithFormat:@"%@", [current_node valueForKey:@"came_from"]]];
    }
    return pathMap;
}

-(NSArray *)neighborFor:(NSDictionary*)x
{
    NSString *key = [NSString stringWithFormat:@"%@",[x valueForKey:@"id"]];
    return [neighbors valueForKey:key];
}

@end
