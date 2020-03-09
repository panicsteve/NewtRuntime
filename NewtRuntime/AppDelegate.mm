//
//  AppDelegate.m
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
#include "NewtVM.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	NewtInit(0, NULL, 0);

	newtErr	err;
	newtRefVar result;

	result = NVMInterpretStr("print(\"Hello from NewtonScript\n\")", &err);

    if ( err != kNErrNone )
        NewtErrMessage(err);

	result = NVMInterpretStr("print(1 + 2)", &err);

    if ( err != kNErrNone )
        NewtErrMessage(err);

	NewtCleanup();
}

@end
