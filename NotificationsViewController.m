//
//  NotificationsViewController .m
//


#import "NotificationsViewController.h"
#import "AddNotificationViewController.h"

#import "Notification.h"
#import "Utilities.h"

@import MapKit;

@interface NotificationsViewController () <MKMapViewDelegate, AddNotificationsViewControllerDelegate , CLLocationManagerDelegate>

@property (weak, nonatomic) IBOutlet MKMapView *mapView;

@property (nonatomic, strong) NSMutableArray *geotifications;
@property (nonatomic, strong) CLLocationManager *locationManager;

@end

@implementation NotificationsViewController 

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.locationManager = [CLLocationManager new];
    [self.locationManager setDelegate:self];
    [self.locationManager requestAlwaysAuthorization];
    
    [self loadAllGeoNotifications];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Loading and saving functions

- (void)loadAllGeoNotifications{
    self.geotifications = [NSMutableArray array];
    
    NSArray *savedItems = [[NSUserDefaults standardUserDefaults] arrayForKey:kSavedItemsKey];
    if (savedItems) {
        for (id savedItem in savedItems) {
            Notification *geotification = [NSKeyedUnarchiver unarchiveObjectWithData:savedItem];
            if ([geotification isKindOfClass:[Notification class]]) {
                [self addGeoNotification:geotification];
            }
        }
    }
}


- (void)saveAllGeoNotifications{
    NSMutableArray *items = [NSMutableArray array];
    for (Notification *geotification in self.geotifications) {
        id item = [NSKeyedArchiver archivedDataWithRootObject:geotification];
        [items addObject:item];
    }
    [[NSUserDefaults standardUserDefaults] setObject:items forKey:kSavedItemsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - Functions that update the model/associated views with geotification changes

- (void)addGeoNotification:(Notification *)geotification{
    [self.geotifications addObject:geotification];
    [self.mapView addAnnotation:geotification];
    [self addRadiusOverlayForGeotification:geotification];
    [self updateGeoNotificationsCount];
}

- (void)removeGeoNotification:(Notification *)geotification{
    [self.geotifications removeObject:geotification];
    
    [self.mapView removeAnnotation:geotification];
    [self removeRadiusOverlayForGeotification:geotification];
    [self updateGeoNotificationsCount];
}

- (void)updateGeoNotificationsCount{
    self.title = [NSString stringWithFormat:@"Notifications (%lu)", (unsigned long)self.geotifications.count];
    [self.navigationItem.rightBarButtonItem setEnabled:self.geotifications.count<20];
}

#pragma mark - AddGeotificationViewControllerDelegate

- (void)addGeotificationViewController:(AddNotificationViewController *)controller didAddCoordinate:(CLLocationCoordinate2D)coordinate radius:(CGFloat)radius identifier:(NSString *)identifier note:(NSString *)note eventType:(EventType)eventType{
    [controller dismissViewControllerAnimated:YES completion:nil];
    
    CGFloat clampedRadius = (radius > self.locationManager.maximumRegionMonitoringDistance)?self.locationManager.maximumRegionMonitoringDistance : radius;
    Notification *geotification = [[Notification alloc] initWithCoordinate:coordinate radius:clampedRadius identifier:identifier note:note eventType:eventType];
    [self addGeoNotification:geotification];
    [self startMonitoringGeoNotification:geotification];
    
    [self saveAllGeoNotifications];
}

#pragma mark - MKMapViewDelegate

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation{
    static NSString *identifier = @"myGeotification";
    if ([annotation isKindOfClass:[Notification class]]) {
        MKPinAnnotationView *annotationView = (MKPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:identifier];
        if (![annotation isKindOfClass:[MKPinAnnotationView class]] || annotationView == nil) {
            annotationView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:identifier];
            [annotationView setCanShowCallout:YES];
            
            UIButton *removeButton = [UIButton buttonWithType:UIButtonTypeCustom];
            removeButton.frame = CGRectMake(.0f, .0f, 23.0f, 23.0f);
            [removeButton setImage:[UIImage imageNamed:@"DeleteGeotification"] forState:UIControlStateNormal];
            [annotationView setLeftCalloutAccessoryView:removeButton];
        } else {
            annotationView.annotation = annotation;
        }
        return annotationView;
    }
    return nil;
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay{
    if ([overlay isKindOfClass:[MKCircle class]]) {
        MKCircleRenderer *circleRenderer = [[MKCircleRenderer alloc] initWithOverlay:overlay];
        circleRenderer.lineWidth = 1.0f;
        circleRenderer.strokeColor = [UIColor purpleColor];
        circleRenderer.fillColor = [[UIColor purpleColor] colorWithAlphaComponent:.4f];
        return circleRenderer;
    }
    return nil;
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control{
    Notification *geotification = (Notification *) view.annotation;
    [self stopMonitoringGeoNotification:geotification];
    [self removeGeoNotification:geotification];
    [self saveAllGeoNotifications];
}

#pragma mark - Map overlay functions

- (void)addRadiusOverlayForGeotification:(Notification *)geotification{
    if (self.mapView) [self.mapView addOverlay:[MKCircle circleWithCenterCoordinate:geotification.coordinate radius:geotification.radius]];
}

- (void)removeRadiusOverlayForGeotification:(Notification *)geotification{
    if (self.mapView){
        NSArray *overlays = self.mapView.overlays;
        for (MKCircle *circleOverlay in overlays) {
            if ([circleOverlay isKindOfClass:[MKCircle class]]) {
                CLLocationCoordinate2D coordinate = circleOverlay.coordinate;
                if (coordinate.latitude == geotification.coordinate.latitude && coordinate.longitude == geotification.coordinate.longitude && circleOverlay.radius == geotification.radius) {
                    [self.mapView removeOverlay:circleOverlay];
                    break;
                }
            }
        }
    }
}

#pragma mark - Other mapview functions

- (IBAction)zoomToCurrentLocation:(id)sender{
    [Utilities zoomToUserLocationInMapView:self.mapView];
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status{
    [self.mapView setShowsUserLocation:status==kCLAuthorizationStatusAuthorizedAlways];
}

- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error{
    NSLog(@"Monitoring failed for region with identifer: %@", region.identifier);
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error{
    NSLog(@"Location Manager failed with the following error: %@", error);
}

#pragma mark - Geotifications

- (CLCircularRegion *)regionWithGeoNotification:(Notification *)geotification{
    CLCircularRegion *region = [[CLCircularRegion alloc] initWithCenter:geotification.coordinate radius:geotification.radius identifier:geotification.identifier];
    [region setNotifyOnEntry:geotification.eventType==OnEntry];
    [region setNotifyOnExit:!region.notifyOnEntry];
    
    return region;
}

- (void)startMonitoringGeoNotification:(Notification *)geotification{
    if (![CLLocationManager isMonitoringAvailableForClass:[CLCircularRegion class]]) {
        [Utilities showSimpleAlertWithTitle:@"Error" message:@"Geofencing is not supported on this device!" viewController:self];
        return;
    }
    
    if ([CLLocationManager authorizationStatus] != kCLAuthorizationStatusAuthorizedAlways) {
        [Utilities showSimpleAlertWithTitle:@"Warning" message:@"Your notification is saved but will only be activated once you grant App permission to access the device location." viewController:self];
    }
    
    CLCircularRegion *region = [self regionWithGeoNotification:geotification];
    [self.locationManager startMonitoringForRegion:region];
}

- (void)stopMonitoringGeoNotification:(Notification *)geotification{
    for (CLCircularRegion *circularRegion in self.locationManager.monitoredRegions) {
        if ([circularRegion isKindOfClass:[CLCircularRegion class]]) {
            if ([circularRegion.identifier isEqualToString:geotification.identifier]) {
                [self.locationManager stopMonitoringForRegion:circularRegion];
            }
        }
    }
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"addGeotification"]) {
        UINavigationController *navigationController = segue.destinationViewController;
        AddNotificationViewController *vc = navigationController.viewControllers.firstObject;
        [vc setDelegate:self];
    }
}

@end
