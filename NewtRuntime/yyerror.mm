//
//  yyerror.mm
//  NewtRuntime
//
//  Created by Steven Frank on 3/9/20.
//  Copyright © 2020 Steven Frank. All rights reserved.
//

#include "NewtParser.h"

extern "C"
{
	void yyerror(char * s)
	{
		if ( s[0] && s[1] == ':' )
			NPSErrorStr(*s, s + 2);
		else
			NPSErrorStr('E', s);
	}
}

