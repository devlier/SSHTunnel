//Copyright (C) 2008  Antoine Mercadal
//
//This program is free software; you can redistribute it and/or
//modify it under the terms of the GNU General Public License
//as published by the Free Software Foundation; either version 2
//of the License, or (at your option) any later version.
//
//This program is distributed in the hope that it will be useful,
//but WITHOUT ANY WARRANTY; without even the implied warranty of
//MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//GNU General Public License for more details.
//
//You should have received a copy of the GNU General Public License
//along with this program; if not, write to the Free Software
//Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

#import "MyAppController.h"
#include <unistd.h>

@implementation MyAppController
@synthesize hostName;

- (id) init
{
	self = [super init];
	
	NSFileManager *f = [NSFileManager defaultManager];
	NSString *saveFolder	=  @"~/Library/Application Support/SSHTunnel/";
	
	if ([f fileExistsAtPath:[saveFolder stringByExpandingTildeInPath]] == NO)
		[f createDirectoryAtPath:[saveFolder stringByExpandingTildeInPath] attributes:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(performInfoMessage:) 
												 name:@"AMNewGeneralMessage" 
											   object:nil];
	return self;
}


- (void) awakeFromNib
{	
	[[mainApplicationWindow contentView] addSubview:sessionView];
	[self setHostName:[[NSHost currentHost] name]];
}

/**
 * Here are the IBAction of the interface
 **/
- (IBAction)toggleTunnel:(id)sender 
{
	AMSession	*currentSession = [sessionController getSelectedSession];
	if ([currentSession connected] == NO)
		[currentSession closeTunnel];
	else
		[currentSession openTunnel];
}

- (IBAction) killAllSSH:(id)sender
{
	[mainApplicationWindow runSheetAlertTitle:NSLocalizedString(@"KILLALLSSH_TITLE", nil) 
									  message:NSLocalizedString(@"KILLALLSSH_MESSAGE", nil)
								  firstButton:NSLocalizedString(@"OK", nil)
								 secondButton:NSLocalizedString(@"CANCEL", nil)
										 from:self
									 selector:(@"executeKillAllSSH:returnCode:contextInfo:")];
}

- (void) executeKillAllSSH:(NSAlert *)alert returnCode:(int)returnCode
				   contextInfo:(void *)contextInfo;
{
	// Do not ask me why NSAlertDefaultReturn doesn't work...
	if (returnCode ==  1000)
	{
		NSTask *t = [[NSTask alloc] init];
		[t setLaunchPath:@"/usr/bin/killall"];
		[t setArguments:[NSArray arrayWithObject:@"ssh"]];
		[t launch];
	}
}

- (IBAction) openAllSession:(id)sender
{
	for (AMSession *o in [sessionController sessions])
	{
		if ([o connected] == NO)
			[o openTunnel];
	}
}

- (IBAction) closeAllSession:(id)sender
{
	for (AMSession *o in [sessionController sessions])
	{
		if ([o connected] == YES)
			[o closeTunnel];
	}
}









/**
 * This part is for the delegation of the NSTableView to
 * enable instant save when modified.
 **/
- (void) performInfoMessage:(NSNotification*)notif
{
	[self errorPanelDisplaywithMessage: (NSString*)[notif object]];
}
- (void) errorPanelDisplaywithMessage:(NSString *)theMessage
{
	if (timer != nil)
		[timer invalidate];
	
	NSRect rect = [errorPanel frame];
	rect.origin.y = 0;
	[errorMessage setStringValue:theMessage];
	[[errorPanel animator] setFrame:rect];
	
	timer = [NSTimer scheduledTimerWithTimeInterval:2.5 target:self selector:@selector(errorPanelClose:) userInfo:NULL repeats:NO];
}
- (void) errorPanelClose:(NSTimer *)theTimer
{
	NSRect rect = [errorPanel frame];
	rect.origin.y = -60;
	[[errorPanel animator] setFrame:rect];
}



 




/**
 * This part is for the delegation of the NSApplication to
 * allow closing all ssh session before terminating
 **/
- (void) applicationWillTerminate: (NSNotification *) notification
{
	for (int i = 0; i < [[sessionController sessions] count]; i++)
		[[[sessionController sessions] objectAtIndex:i] closeTunnel];
	[serverController performSaveProcess:nil];
	[sessionController performSaveProcess:nil];
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag
{
	[self openMainWindow:nil];    
	return YES;
}

- (void)animateWindow:(NSWindow*)win effect:(CGSTransitionType)fx direction:(CGSTransitionOption)dir duration:(float)dur
{
	int handle;
	CGSTransitionSpec spec;
	

	handle = -1;
	
	spec.unknown1=0;
	spec.type=fx;
	spec.option=dir;
	spec.option |= (1<<7);
	spec.backColour=NULL;
	spec.wid=[win windowNumber];
	
	
	CGSConnection cgs= _CGSDefaultConnection();
	CGSNewTransition(cgs, &spec, &handle);
	
	[win display];
	
	if (fx == CGSNone)
		dur = 0.f; // if no transition effect, no need to have a duration, (it would be strange to wait for nothin') -> je n'te l'fai pas dire mec
	
	CGSInvokeTransition(cgs, handle, dur);
	usleep((useconds_t)(dur * 1000000));
	CGSReleaseTransition(cgs, handle);
	handle=0;
}

- (IBAction) displaySessionView:(id)sender
{
	if (![[[mainApplicationWindow contentView] subviews] containsObject:sessionView])
	{
		NSView *currentView = [[[mainApplicationWindow contentView] subviews] objectAtIndex:0];
		[[mainApplicationWindow contentView] replaceSubview:currentView with:sessionView];
		[self animateWindow:mainApplicationWindow effect:CGSCube direction:CGSLeft duration:0.2];
	}
}

- (IBAction) displayServerView:(id)sender
{
	if (![[[mainApplicationWindow contentView] subviews] containsObject:serverView])
	{
		NSView *currentView = [[[mainApplicationWindow contentView] subviews] objectAtIndex:0];
		[[mainApplicationWindow contentView] replaceSubview:currentView with:serverView];
		[self animateWindow:mainApplicationWindow effect:CGSCube direction:CGSLeft duration:0.2];
		
		/*
		[tunnelHost setStringValue:(NSString *)[[servers objectAtIndex:0] host]];
		[tunnelPort setStringValue:(NSString *)[[servers objectAtIndex:0] port]];
		[userName setStringValue:[[servers objectAtIndex:0] username]];
		[password setStringValue:[[servers objectAtIndex:0] password]];
		 */
	}
}

- (IBAction) displayAboutView:(id)sender
{
	if (![[[mainApplicationWindow contentView] subviews] containsObject:aboutView])
	{
		NSView *currentView = [[[mainApplicationWindow contentView] subviews] objectAtIndex:0];
		[[mainApplicationWindow contentView] replaceSubview:currentView with:aboutView];
		[self animateWindow:mainApplicationWindow effect:CGSCube direction:CGSLeft duration:0.2];
	}
}

- (IBAction) displayRegisterView:(id)sender
{
	if (![[[mainApplicationWindow contentView] subviews] containsObject:registerView])
	{
		NSView *currentView = [[[mainApplicationWindow contentView] subviews] objectAtIndex:0];
		[[mainApplicationWindow contentView] replaceSubview:currentView with:registerView];
		[self animateWindow:mainApplicationWindow effect:CGSCube direction:CGSLeft duration:0.2];
	}
}

- (IBAction) openMainWindow:(id)sender
{
	[mainApplicationWindow makeKeyAndOrderFront:nil];
}

- (IBAction) closeMainWindow:(id)sender
{
	[mainApplicationWindow orderOut:nil];
}


@end
