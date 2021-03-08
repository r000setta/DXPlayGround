#include "JRtti.h"
#include "JProperty.h"

JRtti::JRtti(const TCHAR* pRttiName, JRtti* pBase)
{
}

JRtti::~JRtti()
{
	mpBase = nullptr;
}

JProperty* JRtti::GetProperty(UINT idx) const
{
	if (idx >= mPropertyArray.size()) return nullptr;
	return mPropertyArray[idx];
}
