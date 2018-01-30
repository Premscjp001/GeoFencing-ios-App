//
//  Notification.h

#import <Foundation/Foundation.h>

@import MapKit;
@import CoreLocation;

typedef enum : NSInteger {
    OnEntry = 0,
    OnExit
} EventType;

@interface Notification : NSObject <NSCoding, MKAnnotation>

@property (nonatomic, assign) CLLocationCoordinate2D coordinate;
@property (nonatomic, assign) CLLocationDistance radius;
@property (nonatomic, strong) NSString *identifier;
@property (nonatomic, strong) NSString *note;
@property (nonatomic, assign) EventType eventType;

- (instancetype)initWithCoordinate:(CLLocationCoordinate2D)coordinate radius:(CLLocationDistance)radius identifier:(NSString *)identifier note:(NSString *)note eventType:(EventType)eventType;

@end