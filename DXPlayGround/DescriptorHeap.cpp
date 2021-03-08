#include "DescriptorHeap.h"

DescriptorHeap::DescriptorHeap(ID3D12Device* device, D3D12_DESCRIPTOR_HEAP_TYPE type, UINT numDescriptors, bool visibility)
{

}

void DescriptorHeap::CreateSRV(ID3D12Device* device, const GPUResource* pResource, const D3D12_SHADER_RESOURCE_VIEW_DESC* pDesc, UINT idx)
{

}

void DescriptorHeap::CreateDSV(ID3D12Device* device, const GPUResource* pResource, UINT depthSlice, UINT mipCount, const D3D12_DEPTH_STENCIL_VIEW_DESC* pDesc, UINT idx)
{

}

void DescriptorHeap::CreateRTV(ID3D12Device* device, const GPUResource* pResource, UINT depthSlice, UINT mipCount, const D3D12_RENDER_TARGET_VIEW_DESC* pDesc, UINT idx)
{
}

void DescriptorHeap::CreateUAV(ID3D12Device* device, const GPUResource* pResource, const D3D12_UNORDERED_ACCESS_VIEW_DESC* pDesc, UINT idx)
{
}
