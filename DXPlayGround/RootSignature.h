#pragma once

#include "d3dUtil.h"

using Microsoft::WRL::ComPtr;

class RootParameter
{
public:
	void InitAsDescriptorTable(UINT rangeCount, CD3DX12_DESCRIPTOR_RANGE* range, D3D12_SHADER_VISIBILITY visibility = D3D12_SHADER_VISIBILITY_ALL)
	{
		rootParameter.InitAsDescriptorTable(rangeCount, range, visibility);
	}

	void InitAsConstantBufferView(UINT shaderRegister,
		UINT registerSpace = 0,
		D3D12_SHADER_VISIBILITY visibility = D3D12_SHADER_VISIBILITY_ALL)
	{
		rootParameter.InitAsConstantBufferView(shaderRegister, registerSpace, visibility);
	}

	void InitAsShaderResourceView(
		UINT shaderRegister,
		UINT registerSpace = 0,
		D3D12_SHADER_VISIBILITY visibility = D3D12_SHADER_VISIBILITY_ALL)
	{
		rootParameter.InitAsShaderResourceView(shaderRegister, registerSpace, visibility);
	}

	const CD3DX12_ROOT_PARAMETER& operator()(void) const
	{
		return rootParameter;
	}
protected:
	CD3DX12_ROOT_PARAMETER rootParameter;
};

class RootSignature
{
public:
	ID3D12RootSignature* GetSignature() const { return mRootSignature.Get(); }

	RootSignature(UINT paramsNum = 0, UINT samplersNum = 0)
		:mParamsNum(paramsNum), mSamplersNum(samplersNum)
	{

	}

	void Reset(UINT paramsNum = 0, UINT samplersNum = 0);

	RootParameter& operator[](size_t idx)
	{
		return mParamArray[idx];
	}

	const RootParameter& operator[](size_t idx) const
	{
		return mParamArray[idx];
	}

protected:
	UINT mParamsNum;
	UINT mSamplersNum;
	std::unique_ptr<RootParameter[]> mParamArray;
	std::unique_ptr<CD3DX12_STATIC_SAMPLER_DESC[]> mSamplerArray;
	ComPtr<ID3D12RootSignature> mRootSignature;
};