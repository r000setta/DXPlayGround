#include "Object.h"

JObject::JObject(const JObject& object)
{
	
}

JFastObjectManager::JFastObjectManager()
{
}

JFastObjectManager::~JFastObjectManager()
{
}

UINT JFastObjectManager::AddObject(JObject* p)
{
	assert(mFreeTable.size() > 0);
	UINT id = mFreeTable.back();
	mObjectArray[id] = p;
	return id;
}

void JFastObjectManager::DeleteObject(JObject* p)
{
	if (mObjectArray[p->GetInstanceID()])
	{
		mFreeTable.emplace_back(p->GetInstanceID());
		mObjectArray[p->GetInstanceID()] = nullptr;
		p->clearID();
	}
}

UINT JFastObjectManager::GetObjectNum()
{
	return MAX_OBJECT_NUM - mFreeTable.size();
}
