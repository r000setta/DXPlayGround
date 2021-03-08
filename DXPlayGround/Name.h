#pragma once
#include "d3dUtil.h"

class JObject;

class JName
{
public:
	~JName();

	JName(const std::string& name, UINT id);

private:
	UINT muiID;
	std::string mStr;
};