//
//  AppDelegate.mm
//  NewtRuntime
//
//  Created by Steven Frank on 3/9/20.
//  Copyright © 2020 Steven Frank. All rights reserved.
//

#import "AppDelegate.h"

#include "NewtEnv.h"
#include "NewtErrs.h"
#include "NewtFns.h"
#include "NewtObj.h"
#include "NewtPrint.h"
#include "NewtVM.h"

@interface AppDelegate ()

@property (strong) NSFileHandle *stderrPipeReadHandle;
@property (strong) NSFileHandle *stdoutPipeReadHandle;

@property (weak) IBOutlet NSTextField *replInputTextField;
@property (weak) IBOutlet NSTextView *outputTextView;

@property (weak) IBOutlet NSWindow *window;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
	NSAssert(self.replInputTextField != nil, @"outlet not connected in xib");
	NSAssert(self.outputTextView != nil, @"outlet not connected in xib");
	NSAssert(self.window != nil, @"outlet not connected in xib");

	[self captureStderr];
	[self captureStdout];
	
	NewtInit(0, NULL, 0);
	
	[self interpretInput:@"print(\"Hello from NewtonScript\\n\")"];
}

- (void)appendOutputString:(NSString *)string withAttributes:(NSDictionary *)attributes
{
	// Append a string to the output textview, using the given attributes
	
	NSAttributedString *stringToAppend = [[NSAttributedString alloc] initWithString:string attributes:attributes];
	
	[self.outputTextView.textStorage appendAttributedString:stringToAppend];
	[self.outputTextView scrollRangeToVisible:NSMakeRange([self.outputTextView.string length], 0)];
}

- (void)captureStderr
{
	// Capture stderr so we can read from it
	
	NSPipe *stderrPipe = [NSPipe pipe];
	self.stderrPipeReadHandle = [stderrPipe fileHandleForReading];
	
	if ( ::dup2([[stderrPipe fileHandleForWriting] fileDescriptor], ::fileno(stderr)) != -1 )
	{
		[[stderrPipe fileHandleForWriting] closeFile];
	
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveDataOnStderrPipeReadHandle:) name: NSFileHandleReadCompletionNotification object:self.stderrPipeReadHandle];
	
		[self.stderrPipeReadHandle readInBackgroundAndNotify];
	}
}

- (void)captureStdout
{
	// Capture stdout so we can read from it
	
	NSPipe *stdoutPipe = [NSPipe pipe];
	self.stdoutPipeReadHandle = [stdoutPipe fileHandleForReading];
	
	if ( ::dup2([[stdoutPipe fileHandleForWriting] fileDescriptor], ::fileno(stdout)) != -1 )
	{
		[[stdoutPipe fileHandleForWriting] closeFile];
	
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveDataOnStdoutPipeReadHandle:) name: NSFileHandleReadCompletionNotification object:self.stdoutPipeReadHandle];
	
		[self.stdoutPipeReadHandle readInBackgroundAndNotify];
	}
}

- (void)controlTextDidEndEditing:(NSNotification *)notification
{
	// Called when the input text field ends editing (by pressing return, losing focus, etc)
	
	if ( [[[notification userInfo] objectForKey:NSTextMovementUserInfoKey] intValue] != NSTextMovementReturn )
	{
		// Only perform action if editing ended by pressing return
        return;
	}
	
	[self interpretInput:self.replInputTextField.stringValue];
}

- (void)didReceiveDataOnStderrPipeReadHandle:(NSNotification *)notification
{
	// Data came in on stderr from newt, so append it in red font
	
	NSString *string = [[NSString alloc] initWithData:[[notification userInfo] objectForKey:NSFileHandleNotificationDataItem] encoding:NSUTF8StringEncoding];
	
	[self appendOutputString:[string stringByAppendingString:@"\n"] withAttributes:@{
		NSForegroundColorAttributeName: NSColor.redColor,
		NSFontAttributeName: [NSFont systemFontOfSize:13.0]
	}];

	// Resume reading
	
	[self.stderrPipeReadHandle readInBackgroundAndNotify];
}

- (void)didReceiveDataOnStdoutPipeReadHandle:(NSNotification *)notification
{
	// Data came in on stdout from newt, so append it in normal font

	NSString *string = [[NSString alloc] initWithData:[[notification userInfo] objectForKey:NSFileHandleNotificationDataItem] encoding:NSUTF8StringEncoding];
	
	[self appendOutputString:[string stringByAppendingString:@"\n"] withAttributes:@{
			NSFontAttributeName: [NSFont systemFontOfSize:13.0]
	}];

	// Resume reading

	[self.stdoutPipeReadHandle readInBackgroundAndNotify];
}

- (void)interpretInput:(NSString *)string
{
	// Called when user input is received

	// Append what the user typed to the output view
	
	[self appendOutputString:[string stringByAppendingString:@"\n"] withAttributes:@{
			NSFontAttributeName: [NSFont boldSystemFontOfSize:13.0]
	}];

	// Pass user input to the newt VM

	newtErr	err;
	newtRefVar result;
	
	result = NVMInterpretStr([string cStringUsingEncoding:NSUTF8StringEncoding], &err);

    if ( err != kNErrNone )
	{
        NewtErrMessage(err);
	}
}

@end
