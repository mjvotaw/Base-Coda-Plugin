#import <Cocoa/Cocoa.h>
#import "CodaPluginsController.h"
#import "BaseCodaPlugin.h"

@class CodaPlugInsController;

@interface ExamplePlugin : BaseCodaPlugin <CodaPlugIn, NSUserNotificationCenterDelegate, NSWindowDelegate>
{
}

@end
