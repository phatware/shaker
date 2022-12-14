/*

File: Reachability.h
Abstract: SystemConfiguration framework wrapper.

*/

#import <UIKit/UIKit.h>
#import <SystemConfiguration/SystemConfiguration.h>

@class Reachability;

@interface Reachability : NSObject 
{
    
@private
	BOOL _networkStatusNotificationsEnabled;
	
	NSString *_hostName;
	NSString *_address;
}

/*
 An enumeration that defines the return values of the network state
 of the device.
 */
typedef enum {
	NotReachable = 0,
	ReachableViaCellularDataNetwork,
	ReachableViaWiFiNetwork,
	NotConnectedToWiFi
} NetworkStatus;


// Set to YES to register for changes in network status. Otherwise reachability queries
// will be handled synchronously.
@property BOOL networkStatusNotificationsEnabled;
// The remote host whose reachability will be queried.
// Either this or 'addressName' must be set.
@property (nonatomic, retain) NSString *hostName;
// The IP address of the remote host whose reachability will be queried.
// Either this or 'hostName' must be set.
@property (nonatomic, retain) NSString *address;
// A cache of ReachabilityQuery objects, which encapsulate SCNetworkReachabilityRef, a host or address, and a run loop. The keys are host names or addresses.
@property (nonatomic, retain) NSMutableDictionary *reachabilityQueries;

// This class is meant be used as a singleton.
+ (Reachability *)sharedReachability;

+ (NetworkStatus) IsWiFiEnabled;

+ (NetworkStatus) IsInternetAvaialble;

// Is self.hostName is not nil, determines its reachability.
// If self.hostName is nil and self.address is not nil, determines the reachability of self.address.
- (NetworkStatus)remoteHostStatus;
// Is the device able to communicate with Internet hosts? If so, through which network interface?
- (NetworkStatus)internetConnectionStatus;
// Is the device able to communicate with hosts on the local WiFi network? (Typically these are Bonjour hosts).
- (NetworkStatus)localWiFiConnectionStatus;

- (BOOL)remoteHostReachable:(NSString*)hostname;

/*
 When reachability change notifications are posted, the callback method 'ReachabilityCallback' is called
 and posts a notification that the client application can observe to learn about changes.
 */
// static void ReachabilityCallback(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void *info);

@end

@interface ReachabilityQuery : NSObject
{
@private
	SCNetworkReachabilityRef _reachabilityRef;
	CFMutableArrayRef _runLoops;
	NSString *_hostNameOrAddress;
}
// Keep around each network reachability query object so that we can
// register for updates.
@property (nonatomic) SCNetworkReachabilityRef reachabilityRef;
@property (nonatomic, retain) NSString *hostNameOrAddress;
@property (nonatomic) CFMutableArrayRef runLoops;

- (void)scheduleOnRunLoop:(NSRunLoop *)inRunLoop;

@end

