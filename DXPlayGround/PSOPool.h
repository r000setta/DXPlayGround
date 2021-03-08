#pragma once
#include "d3dUtil.h"
#include <unordered_map>
#include "Shader.h"

struct PSODescriptor
{
	const std::unique_ptr<Shader> ShaderPtr;
	D3D12_PRIMITIVE_TOPOLOGY_TYPE Topology;


	PSODescriptor() :
		Topology(D3D12_PRIMITIVE_TOPOLOGY_TYPE_TRIANGLE)
	{}
};

class PSODescriptorPool
{
private:
	std::unordered_map<std::pair<UINT, PSODescriptor>, ComPtr<ID3D12PipelineState>> mAllPSOs;

public:
	PSODescriptorPool() {}
};