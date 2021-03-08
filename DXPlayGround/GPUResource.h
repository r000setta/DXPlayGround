#pragma once
#include "Object.h"

class GPUResource :public JObject
{
protected:
	ComPtr<ID3D12Resource> mResource;

public:

	virtual ~GPUResource() {}
	ID3D12Resource* GetResource() const { return mResource.Get(); }

	const ComPtr<ID3D12Resource>& GetResourcePtr() const { return mResource; }
};