#pragma once

#include "targetver.h"

#include <stdio.h>
#include <tchar.h>
#include <string.h>
#include <math.h>
#include <stdlib.h>

#include <locale>
#include <codecvt>
#include <string>
#include <iostream>
#include <vector>

#if defined(_MSC_VER)
#define strtoll _strtoi64
#endif