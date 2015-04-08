#import "BaseCodaPlugin.h"

@interface BaseCodaPlugin ()

- (id)initWithController:(CodaPlugInsController*)inController;

@end


@implementation BaseCodaPlugin

//2.0 and lower
- (id)initWithPlugInController:(CodaPlugInsController*)aController bundle:(NSBundle*)aBundle
{
    return [self initWithController:aController];
}


//2.0.1 and higher
- (id)initWithPlugInController:(CodaPlugInsController*)aController plugInBundle:(NSObject <CodaPlugInBundle> *)p
{
    return [self initWithController:aController andPlugInBundle:p];
}

- (id)initWithController:(CodaPlugInsController*)inController andPlugInBundle:(NSObject <CodaPlugInBundle> *)p
{
    if ( (self = [super init]) != nil )
	{
		_controller = inController;
	}
    _pluginBundle = p;
    _bundle = [NSBundle bundleWithIdentifier:[p bundleIdentifier]];
    currentSiteUUID = @"*";
	return self;
}

- (id)initWithController:(CodaPlugInsController*)inController
{
	if ( (self = [super init]) != nil )
	{
		_controller = inController;
	}
	return self;
}


-(BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    return true;
}


#pragma mark - Site methods

- (void)didLoadSiteNamed:(NSString*)name
{
    
    currentSiteUUID = [self getCurrentSiteUUID];
    
    if(currentSiteUUID == nil)
    {
        currentSiteUUID = @"*";
    }
}

#pragma mark - Menu methods

/** Opens a File prompt for the user to select a file to open.

Returns an NSURL * to the chosen file, or nil.
 
 @returns NSURL * chosenFile
 */

-(NSURL *) getFileNameFromUser
{
    NSURL * chosenFile = nil;
    // Create the File Open Dialog class.
    NSOpenPanel* openDlg = [NSOpenPanel openPanel];
    
    if([_controller respondsToSelector:@selector(siteLocalPath)])   //Coda 2.5
    {
    	[openDlg setDirectoryURL: [NSURL fileURLWithPath:[_controller siteLocalPath] ]];
    }
    else if([_controller respondsToSelector:@selector(focusedTextView:)] && [_controller focusedTextView:nil] != nil)    //Coda 2.0
    {
        [openDlg setDirectoryURL: [NSURL fileURLWithPath:[[_controller focusedTextView:nil] siteLocalPath] ]];
    }
    // Enable the selection of files in the dialog.
    [openDlg setCanChooseFiles:YES];
    
    // Multiple files not allowed
    [openDlg setAllowsMultipleSelection:NO];
    
    // Can't select a directory
    [openDlg setCanChooseDirectories:NO];
    
    // Display the dialog. If the OK button was pressed,
    // process the files.
    if ( [openDlg runModal] == NSModalResponseOK )
    {
        // Get an array containing the full filenames of all
        // files and directories selected.
        NSArray* files = [openDlg URLs];
        
        // Loop through all the files and process them.
        for(NSURL * url in files)
        {
            chosenFile = url;
        }
    }
    return chosenFile;
}

/** Opens a Save file prompt for the user to select a file.
 
 Returns an NSURL * to the chosen file, or nil.
 
 @returns NSURL * chosenFile
 */

-(NSURL *) getSaveNameFromUser
{
    NSURL * chosenFile = nil;
    // Create the File Save Dialog class.
    NSSavePanel* saveDlg = [NSSavePanel savePanel];
    
    if([_controller respondsToSelector:@selector(siteLocalPath)])   //Coda 2.5
    {
        [saveDlg setDirectoryURL: [NSURL fileURLWithPath:[_controller siteLocalPath] ]];
    }
    else if([_controller respondsToSelector:@selector(focusedTextView:)] && [_controller focusedTextView:nil] != nil) //Coda 2.0
    {
        [saveDlg setDirectoryURL: [NSURL fileURLWithPath:[[_controller focusedTextView:nil] siteLocalPath] ]];
    }
    
    [saveDlg setCanCreateDirectories:TRUE];
    
    if ( [saveDlg runModal] == NSModalResponseOK )
    {
        chosenFile = [saveDlg URL];
    }
    return chosenFile;
}


#pragma mark - persistant storage methods
/* These methods can be used to store files in NSHomeDirectory(), to protect these files from being deleted when plugins or Coda are updated.
 */

/** Creates a directory in NSHomeDirectory() (usually /Users/[current user name]) based on the plugin's name (taken from [self name]).
 
    For example, a plugin with the name Capitalize would created a directory called ~/.Capitalize
 
    @returns NSError * any error when creating directory, or nil if directory created successfully.
 */

-(NSError *) createPersistantStorageDirectory
{
    NSError * error;
    NSURL * url = [self urlForPeristantFilePath:@""];
    NSFileManager* fileManager = [NSFileManager defaultManager];
    [fileManager createDirectoryAtURL:url withIntermediateDirectories:NO attributes:nil error:&error];
    return error;
}

/** Checks if the given filename or relative filepath exists inside the Persistant directory.
 
 @returns BOOL fileExists
 */

-(BOOL) doesPersistantFileExist:(NSString *)path
{
    NSFileManager* fileManager = [NSFileManager defaultManager];
	NSURL * url = [self urlForPeristantFilePath:path];
    return  [fileManager fileExistsAtPath:[url path]];
}

/** Checks if a persistant directory for the given plugin has been creates.
 
 @returns BOOL persistantFileExists
 */

-(BOOL) doesPersistantStorageDirectoryExist
{
    return [self doesPersistantFileExist:@""];
}

/** Returns an NSURL to the given filename or relative path within the plugin's persistant storage directory.
 
 Note that this method does not actually check for the existance of the filepath.
 
 @returns NSURL filepath
 */

-(NSURL *) urlForPeristantFilePath:(NSString *)path
{
    NSURL * url = [NSURL fileURLWithPath:NSHomeDirectory()];
    url = [url URLByAppendingPathComponent:[NSString stringWithFormat:@".%@/%@", [self name], path]];
    return url;
}


/** Copies the content at the given filepath to the plugin's persistant storage directory.

Files will be given the same filenames.
 
 @param NSString * path: a path to a filename.
 
 @returns NSError * any errors thrown while copying files, or nil if success.
 */

-(NSError *) copyFileToPersistantStorage:(NSString *)path
{
    NSError * error = nil;
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSString * filename = [path lastPathComponent];
    NSURL * url = [self urlForPeristantFilePath: filename];
    if(![self doesPersistantStorageDirectoryExist])
    {
        error = [self createPersistantStorageDirectory];
        if(error != nil)
        {
            return error;
        }
    }
    if([self doesPersistantFileExist:filename])
    {
        [fileManager moveItemAtPath:[url path] toPath:[[self urlForPeristantFilePath:[NSString stringWithFormat:@"%@.%ld", filename, time(nil)]] path] error:&error];
        if(error != nil)
        {
            return error;
        }
    }
    
    [fileManager copyItemAtPath:path toPath: [url path] error:&error];
    return error;
}


#pragma mark - url/path helper methods


/** Normalizes paths.
 
 For example, /Volumes/Macintosh HD/Users/michael/Documents and /Users/michael/Documents both point to the same directory, but their paths are slightly different. This method normalizes each,  and in this case would return "/Users/michael/Documents" for both.
 
 @param NSString * path: a filepath to be resolved.
 
 @returns NSString * newPath: a resolved path.
 
 */

-(NSString *) getResolvedPathForPath:(NSString *)path
{
    NSURL * url = [NSURL fileURLWithPath:path];
    url = [NSURL URLWithString:[url absoluteString]];	//absoluteString returns path in file:// format
	NSString * newPath = [[url URLByResolvingSymlinksInPath] path];	//URLByResolvingSymlinksInPath expects file:// format for link, then resolves all symlinks
    return newPath;
}

#pragma mark - NSUserNotification

/** Creates a notification with the given title and message. If NSUserNotification is not present, it will fall back to Growl.
 
    @param NSString * title
    @param NSString * message
 */

-(void) sendUserNotificationWithTitle:(NSString *)title andMessage:(NSString *)message
{
    if(NSClassFromString(@"NSUserNotification"))
    {
		[self sendUserNotificationWithTitle:title sound:nil andMessage:message];
    }
    else
    {
    	[GrowlApplicationBridge notifyWithTitle:title description:message notificationName:@"GrowlCompleteUpload" iconData:nil priority:0 isSticky:false clickContext:nil];
    }
}

/** Creats a notification with the given title, sound, and message. If NSUserNotification is not present, it will fall back to Growl.
 
 @param NSString * title
 @param NSString * sound path to a sound to play (or nil). NSUserNotificationDefaultSoundName will play a default sound
 @param NSString * message

*/

-(void) sendUserNotificationWithTitle:(NSString *)title sound:(NSString *)sound andMessage:(NSString * ) message
{
    NSUserNotification *notification = [[NSUserNotification alloc] init];
    notification.title = title;
    notification.informativeText = message;
    notification.soundName = sound;
    
	if([[NSUserNotificationCenter defaultUserNotificationCenter] delegate] == nil)
    {
        [[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate:self];
    }
    
    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
}

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification{
    return YES;
}


#pragma mark - Growl delegate

-(NSDictionary *)registrationDictionaryForGrowl
{
    NSDictionary * dictionary = @{GROWL_APP_NAME: @"Coda 2", GROWL_NOTIFICATIONS_ALL: @[@"CodaPluginNotification"], GROWL_NOTIFICATIONS_DEFAULT: @[@"CodaPluginNotification"]};
    
    return dictionary;
}

#pragma mark - OS X compatability methods

/** A convenience method for loading nib, returning the desired nibClass.
 
    @param NSString * nibName
    @param Class nibClass
 
 @returns id the nib Class, or nil if not found
 
 */

-(id) getNibNamed:(NSString *)nibName forClass:(Class)nibClass
{
    NSArray * nibObjects = [self loadNibNamed:nibName];
    for(id o in nibObjects)
    {
        if([o isKindOfClass:nibClass])
        {
            return o;
        }
    }
    return nil;
}

/** A single method for loading nib files on 10.7 or 10.8+ 
    
    @param NSString * nibName
 
    @returns NSArray * nibObjects loaded by bundle.
 */

-(NSArray *) loadNibNamed:(NSString *)nibName
{
    NSMutableArray * nibObjects = [NSMutableArray array];
    if([_bundle respondsToSelector:@selector(loadNibNamed:owner:topLevelObjects:)]) //10.8+
    {

        [_bundle loadNibNamed:nibName owner:self topLevelObjects:&nibObjects];
    }
    else if([_bundle respondsToSelector:@selector(loadNibFile:externalNameTable:withZone:)]) //10.7
    {
		NSDictionary * nameTable = @{NSNibOwner:self, NSNibTopLevelObjects: nibObjects};
        [_bundle loadNibFile:nibName externalNameTable:nameTable withZone:nil];
    }
    
    return nibObjects;
}


#pragma mark - other compatability helpers


/** A convenience method to determine if a site is currently open, supports both Coda 2.0 and 2.5
 
    @returns BOOL isSiteOpen
 */
-(BOOL) isSiteOpen
{
    BOOL isSiteOpen = false;
    if([_controller respondsToSelector:@selector(siteUUID)]) //Coda 2.5+
    {
        isSiteOpen = [_controller siteUUID] != nil;
    }
	else if([_controller respondsToSelector:@selector(focusedTextView:)]) //Coda 2.0
    {
        isSiteOpen = [_controller focusedTextView:nil] != nil && [[_controller focusedTextView:nil] siteNickname] != nil;
    }
    
    return isSiteOpen;
}

/** Gets current siteUUID. In Coda 2.0, siteNickname will be used instead of siteUUID.
 
    @returns NSString * siteUUID, or nil if no site is open.
 */

-(NSString *) getCurrentSiteUUID
{
    if([_controller respondsToSelector:@selector(siteUUID)]) //Coda 2.5+
    {
        return [_controller siteUUID];
    }
	else if([_controller respondsToSelector:@selector(focusedTextView:)] && [_controller focusedTextView:nil] != nil) //Coda 2.0
    {
        return [[_controller focusedTextView:nil] siteNickname];
    }
    
	return nil;
}



-(NSString *) updateCurrentSiteUUID;
{
    //if siteUUID is not available, that means that this is Coda 2.0
    //so we have to make sure that the currentSiteUUID is set to at least something
    currentSiteUUID = [self getCurrentSiteUUID];
    if(currentSiteUUID == nil)
    {
        currentSiteUUID = @"*";
    }
    
    return currentSiteUUID;
}

@end
