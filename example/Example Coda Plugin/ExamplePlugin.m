#import "ExamplePlugin.h"
#import "CodaPlugInsController.h"


@implementation ExamplePlugin

//2.0 and lower
- (id)initWithPlugInController:(CodaPlugInsController*)aController bundle:(NSBundle*)aBundle
{
    return [self initWithController:aController];
}


//2.0.1 and higher
- (id)initWithPlugInController:(CodaPlugInsController*)aController plugInBundle:(NSObject <CodaPlugInBundle> *)plugInBundle
{
    return [self initWithController:aController];
}


- (id)initWithController:(CodaPlugInsController*)inController
{
	if ( (self = [super init]) != nil )
	{
		self.controller = inController;
        [self.controller registerActionWithTitle:@"Perform Action" underSubmenuWithTitle:nil target:self selector:@selector(exampleAction) representedObject:nil keyEquivalent:nil pluginName:[self name]];
        
	}
    NSLog(@"Your plugin loaded!");
	return self;
}


- (NSString*)name
{
	return @"Example Plugin";
}

-(void) exampleAction
{
    NSLog(@"You fired an example action! Great Job!");
}

@end
