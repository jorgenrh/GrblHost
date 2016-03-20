//
//  GHCommon.h
//  GrblHost
//
//  Created by JRH on 30.09.12.
//  Copyright (c) 2012 JRH. All rights reserved.
//

#ifndef GrblHost_GHCommon_h
#define GrblHost_GHCommon_h

//#define GHDEBUG 1

#ifdef GHDEBUG
#   define DLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
#else
#   define DLog(...)
#endif

// ALog always displays output regardless of the DEBUG setting
#define ALog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);


#endif
