#pragma once

#include "Object.h"
#include "GPUResource.h"

class DescriptorHeapAllocation;
class DescriptorHeap;

class IDescriptorAllocator
{
public:
	virtual DescriptorHeapAllocation Allocate(uint32_t count) = 0;
	virtual void Free(DescriptorHeapAllocation&& allocation, UINT64 commandQueueMask) = 0;
	virtual uint32_t GetDescriptorSize() = 0;
};

class DescriptorHeapAllocation
{
public:
	DescriptorHeapAllocation() {}

private:
	D3D12_CPU_DESCRIPTOR_HANDLE mFirstCpuHandle = { 0 };
	D3D12_GPU_DESCRIPTOR_HANDLE mFirstGpuHandle = { 0 };
	IDescriptorAllocator* mpAllocator = nullptr;
	DescriptorHeap* mpDescriptorHeap = nullptr;
	UINT32 mNumHandles = 0;
	UINT16 mAllocationManagerId = static_cast<UINT16>(-1);
	UINT16 mDescriptorSize = 0;
};

class DescriptorHeapAllocationManager
{
public:
	DescriptorHeapAllocationManager() {}

private:
	IDescriptorAllocator* mParentAllocator;
};

class DescriptorHeap
{
public:

	DescriptorHeap(ID3D12Device* device, D3D12_DESCRIPTOR_HEAP_TYPE type, 
		UINT numDescriptors, bool visibility = D3D12_DESCRIPTOR_HEAP_FLAG_SHADER_VISIBLE);
	void CreateSRV(ID3D12Device* device, const GPUResource* pResource, 
		const D3D12_SHADER_RESOURCE_VIEW_DESC* pDesc, UINT idx);
	void CreateDSV(ID3D12Device* device, const GPUResource* pResource, 
		UINT depthSlice, UINT mipCount, const D3D12_DEPTH_STENCIL_VIEW_DESC* pDesc, UINT idx);
	void CreateRTV(ID3D12Device* device, const GPUResource* pResource,
		UINT depthSlice, UINT mipCount, const D3D12_RENDER_TARGET_VIEW_DESC* pDesc, UINT idx);
	void CreateUAV(ID3D12Device* device, const GPUResource* pResource,
		const D3D12_UNORDERED_ACCESS_VIEW_DESC* pDesc, UINT idx);

	ID3D12DescriptorHeap* GetDescriptorHeap() const { return mDescriptorHeap.Get(); }

	CD3DX12_CPU_DESCRIPTOR_HANDLE GetCpuHeap(UINT idx) const
	{
		auto h = CD3DX12_CPU_DESCRIPTOR_HANDLE(mDescriptorHeap->GetCPUDescriptorHandleForHeapStart());
		h.Offset(idx, mDescriptorSize);
		return h;
	}

	CD3DX12_GPU_DESCRIPTOR_HANDLE GetGpuHeap(UINT idx) const
	{
		auto h = CD3DX12_GPU_DESCRIPTOR_HANDLE(mDescriptorHeap->GetGPUDescriptorHandleForHeapStart());
		h.Offset(idx, mDescriptorSize);
		return h;
	}

private:
	enum class BindType :int
	{
		SRV = 0,
		UAV,
		RTV,
		DSV,
		COUNT
	};

	ComPtr<ID3D12DescriptorHeap> mDescriptorHeap;

	CD3DX12_CPU_DESCRIPTOR_HANDLE mCpuHeapStart;
	CD3DX12_GPU_DESCRIPTOR_HANDLE mGpuHeapStart;
	UINT mDescriptorSize;
};