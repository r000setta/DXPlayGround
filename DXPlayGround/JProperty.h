#pragma once
#include "JRtti.h"

class JProperty
{
private:
	enum class PropertyType
	{
		PT_VALUE,
		PT_ARRAY,
		PT_COUNT
	};

	enum class PropertyFlag
	{
		F_NONE,
		F_SAVE_LOAD,
		F_COUNT
	};

protected:
	JRtti* mpRttiOwner;

};