/*
 
 File: SFExportController.m
 
 Version: 1.0
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the
 following terms, and your use, installation, modification or
 redistribution of this Apple software constitutes acceptance of these
 terms.  If you do not agree with these terms, please do not use,
 install, modify or redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc.
 may be used to endorse or promote products derived from the Apple
 Software without specific prior written permission from Apple.  Except
 as expressly stated in this notice, no other rights or licenses, express
 or implied, are granted by Apple herein, including but not limited to
 any patent rights that may be infringed by your derivative works or by
 other works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright © 2007 Apple Inc. All Rights Reserved
 
 */

#import "SFExportController.h"
#import <QuickTime/QuickTime.h>

@implementation SFExportController

- (void)awakeFromNib
{
	[mSizePopUp selectItemWithTag:3];
	[mQualityPopUp selectItemWithTag:3];
	[mMetadataButton setState:NSOnState];
    [mLogin setTitle:@"Log out"];
}

- (id)initWithExportImageObj:(id <ExportImageProtocol>)obj
{
	if(self = [super init])
	{
		mExportMgr = obj;
		mProgress.message = nil;
		mProgressLock = [[NSLock alloc] init];
	}
	return self;
}

- (void)dealloc
{
	[mExportDir release];
	[mProgressLock release];
	[mProgress.message release];
	
	[super dealloc];
}

// getters/setters
- (NSString *)exportDir
{
	return mExportDir;
}

- (void)setExportDir:(NSString *)dir
{
	[mExportDir release];
	mExportDir = [dir retain];
}

- (int)size
{
	return mSize;
}

- (void)setSize:(int)size
{
	mSize = size;
}

- (int)quality
{
	return mQuality;
}

- (void)setQuality:(int)quality
{
	mQuality = quality;
}

- (int)metadata
{
	return mMetadata;
}

- (void)setMetadata:(int)metadata
{
	mMetadata = metadata;
}

// protocol implementation
- (NSView <ExportPluginBoxProtocol> *)settingsView
{
	return mSettingsBox;
}

- (NSView *)firstView
{
	return mFirstView;
}

- (void)viewWillBeActivated
{
    
}

- (void)viewWillBeDeactivated
{
    
}

- (NSString *)requiredFileType
{
	if([mExportMgr imageCount] > 1)
		return @"";
	else
		return @"jpg";
}

- (BOOL)wantsDestinationPrompt
{
	return NO;
}

- (NSString*)getDestinationPath
{
    // should return the path to the temp folder
	return @"~/Pictures/";
}

- (NSString *)defaultFileName
{
	if([mExportMgr imageCount] > 1)
		return @"";
	else
		return @"trovebox-0";
}

- (NSString *)defaultDirectory
{
	return @"~/Pictures/";
}

- (BOOL)treatSingleSelectionDifferently
{
	return YES;
}

- (BOOL)handlesMovieFiles
{
	return NO;
}

- (BOOL)validateUserCreatedPath:(NSString*)path
{
	return NO;
}

- (void)clickExport
{
	[mExportMgr clickExport];
}

- (void)startExport:(NSString *)path
{
	NSFileManager *fileMgr = [NSFileManager defaultManager];
	
	[self setSize:[mSizePopUp selectedTag]];
	[self setQuality:[mQualityPopUp selectedTag]];
	[self setMetadata:[mMetadataButton state]];
	
	int count = [mExportMgr imageCount];
	
	// check for conflicting file names
	if(count == 1)
		[mExportMgr startExport];
	else
	{
		int i;
		for(i=0; i<count; i++)
		{
			NSString *fileName = [NSString stringWithFormat:@"trovebox-%d.jpg",i];
			if([fileMgr fileExistsAtPath:[path stringByAppendingPathComponent:fileName]])
				break;
		}
		if(i != count)
		{
			if (NSRunCriticalAlertPanel(@"File exists", @"One or more images already exist in directory.",
										@"Replace", nil, @"Cancel") == NSAlertDefaultReturn)
				[mExportMgr startExport];
			else
				return;
		}
		else
			[mExportMgr startExport];
	}
}

- (void)performExport:(NSString *)path
{
	NSLog(@"performExport path: %@", path);
	int count = [mExportMgr imageCount];
	BOOL succeeded = YES;
	mCancelExport = NO;
	
	[self setExportDir:path];
	
	// set export options
	ImageExportOptions imageOptions;
	imageOptions.format = kUTTypeJPEG;
	switch([self quality])
	{
		case 0: imageOptions.quality = EQualityLow; break;
		case 1: imageOptions.quality = EQualityMed; break;
		case 2: imageOptions.quality = EQualityHigh; break;
		case 3: imageOptions.quality = EQualityMax; break;
		default: imageOptions.quality = EQualityHigh; break;
	}
	imageOptions.rotation = 0.0;
	switch([self size])
	{
		case 0:
			imageOptions.width = 320;
			imageOptions.height = 320;
			break;
		case 1:
			imageOptions.width = 640;
			imageOptions.height = 640;
			break;
		case 2:
			imageOptions.width = 1280;
			imageOptions.height = 1280;
			break;
		case 3:
			imageOptions.width = 99999;
			imageOptions.height = 99999;
			break;
		default:
			imageOptions.width = 1280;
			imageOptions.height = 1280;
			break;
	}
	if([self metadata] == NSOnState)
		imageOptions.metadata = EMBoth;
	else
		imageOptions.metadata = NO;
	
	// Do the export
	[self lockProgress];
	mProgress.indeterminateProgress = NO;
	mProgress.totalItems = count - 1;
	[mProgress.message autorelease];
	mProgress.message = @"Exporting";
	[self unlockProgress];
	
	NSString *dest;
	
	if(count > 1)
	{
		int i;
		for(i=0; mCancelExport==NO && succeeded==YES && i<count; i++)
		{
			[self lockProgress];
			mProgress.currentItem = i;
			[mProgress.message autorelease];
			mProgress.message = [[NSString stringWithFormat:@"Image %d of %d",
                                  i + 1, count] retain];
			[self unlockProgress];
			
			dest = [[self exportDir] stringByAppendingPathComponent:
                    [NSString stringWithFormat:@"Trovebox-%d.jpg", i]];
			
			succeeded = [mExportMgr exportImageAtIndex:i dest:dest options:&imageOptions];
            
            if (succeeded){
                
                // send to openphoto the image saved in dest
                
                // after finished delete the image
            }
		}
	}
	else
	{
		[self lockProgress];
		mProgress.currentItem = 0;
		[mProgress.message autorelease];
		mProgress.message = @"Image 1 of 1";
		[self unlockProgress];
		
		dest = [self exportDir];
		succeeded = [mExportMgr exportImageAtIndex:0 dest:dest options:&imageOptions];
	}
	
	// Handle failure
	if (!succeeded) {
		[self lockProgress];
		[mProgress.message autorelease];
		mProgress.message = [[NSString stringWithFormat:@"Unable to create %@", dest] retain];
		[self cancelExport];
		mProgress.shouldCancel = YES;
		[self unlockProgress];
		return;
	}
	
	// close the progress panel when done
	[self lockProgress];
	[mProgress.message autorelease];
	mProgress.message = nil;
	mProgress.shouldStop = YES;
	[self unlockProgress];
}

- (ExportPluginProgress *)progress
{
	return &mProgress;
}

- (void)lockProgress
{
	[mProgressLock lock];
}

- (void)unlockProgress
{
	[mProgressLock unlock];
}

- (void)cancelExport
{
	mCancelExport = YES;
}

- (NSString *)name
{
	return @"OpenPhoto Exporter";
}


- (IBAction)loginButtonClicked:(id)sender {
    
    [NSApp beginSheet: passwordSheet
	   modalForWindow: [mSettingsBox window]
		modalDelegate: self
	   didEndSelector: nil
		  contextInfo: nil];
	
    [credentialsPassword setStringValue:@""];
    [credentialsEmail setStringValue:@""];
	
	[NSApp runModalForWindow: passwordSheet];
	// Sheet is up here.
	
	[NSApp endSheet: passwordSheet];
	[passwordSheet orderOut: [mSettingsBox window]];
    
    
    if ([mLogin.title isEqualToString:@"Log out"] ){
        [mLogin setTitle:@"Log in"];
    }else{
        [mLogin setTitle:@"Log out"];
    }
}

- (IBAction)cancelPasswordSheet:(id)sender
{
	[NSApp stopModal];
}

- (IBAction)savePasswordSheet:(id)sender
{
    /*
	NSDictionary *weblog = [self currentWeblog];
	if (![[tempPasswordSecureTextField stringValue] isEqualToString:@""]) {
		[self setPassword:[tempPasswordSecureTextField stringValue]];
		
		if ((![[weblog stringForKey:@"userName"] isEqual:@""]) && ([weblog integerForKey:@"storePasswordInKeychain"] > 0)) {
			PTWKeychain *keychain = [[PTWKeychain alloc] init];
			// Add or replace the existing keychain password.
			[keychain addGenericPassword:[tempPasswordSecureTextField stringValue] forAccount:[weblog stringForKey:@"userName"] forService:[NSString stringWithFormat:@"Photon: %@", [weblog stringForKey:@"weblogURL"]] replaceExisting:YES];
			[keychain release];
		}
	}
	
     */
	[NSApp stopModal];
	//[self savePreferences];
}

@end
