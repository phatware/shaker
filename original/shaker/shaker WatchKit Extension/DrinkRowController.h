

@import WatchKit;

@interface DrinkRowController : NSObject

@property (weak, nonatomic) IBOutlet WKInterfaceLabel * name;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel * rate;

@property (nonatomic) NSInteger tag;

@end
