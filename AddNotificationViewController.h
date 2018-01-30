//
//  AddNotificationViewController.h 


#import <UIKit/UIKit.h>
#import "Notification.h"

@import MapKit;

@protocol AddNotificationsViewControllerDelegate ;

@interface AddNotificationViewController : UITableViewController

@property (nonatomic, strong) id <AddNotificationsViewControllerDelegate > delegate;

@end

@protocol AddNotificationsViewControllerDelegate  <NSObject>

- (void)addGeotificationViewController:(AddNotificationViewController *)controller didAddCoordinate:(CLLocationCoordinate2D)coordinate radius:(CGFloat)radius identifier:(NSString *)identifier note:(NSString *)note eventType:(EventType)eventType;

@end