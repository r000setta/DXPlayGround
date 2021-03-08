#pragma once
#include "d3dUtil.h"

class JProperty;
class JRtti
{
public:
	JRtti(const TCHAR* pRttiName, JRtti* pBase);
	~JRtti();

	const std::string& GetName() const { return mRttiName; }
	bool isSameType(const JRtti& type) const { return this == &type; }
	bool isDerived(const JRtti& type) const;
	JRtti* GetBaseType() const { return mpBase; }

	JProperty* GetProperty(UINT idx) const;

private:
	std::string mRttiName;
	JRtti* mpBase;
	std::vector<JProperty*> mPropertyArray;
};