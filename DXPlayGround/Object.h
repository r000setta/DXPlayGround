#pragma once
#include "d3dUtil.h"
#include <atomic>

constexpr int MAX_OBJECT_NUM = 10000;

class JObject;

class JFastObjectManager
{
public:

	JFastObjectManager();
	~JFastObjectManager();

	UINT AddObject(JObject* p);
	void DeleteObject(JObject* p);
	bool IsEmpty() {}

	UINT GetObjectNum();

protected:
	JObject* mObjectArray[MAX_OBJECT_NUM];
	std::vector<UINT> mFreeTable;
};

class JObject
{
private:
	uint32_t instanceID;

public:
	uint32_t GetInstanceID() const { return instanceID; }
	void clearID()  { instanceID = -1; }

	virtual ~JObject() = 0;
	JObject(const JObject& object);
	JObject& operator=(const JObject& object) {}
	JObject() = default;

public:

};