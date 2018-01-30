//
//  Utilities.h
//

#import <Foundation/Foundation.h>

@import UIKit;
@import MapKit;

@interface Utilities : NSObject

+ (void)showSimpleAlertWithTitle:(NSString *)title message:(NSString *)message viewController:(UIViewController *)viewController;

+ (void)zoomToUserLocationInMapView:(MKMapView *)mapView;

@end
