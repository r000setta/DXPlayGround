#pragma once
#include "d3dApp.h"
#include "MathHelper.h"
#include "UploadBuffer.h"
#include "GeometryGenerator.h"
#include "Camera.h"
#include "FrameResource.h"

struct CameraData {
	DirectX::XMFLOAT4X4 MVP;
	DirectX::XMFLOAT4X4 InvPV;
	DirectX::XMFLOAT3 CamPos;
};
struct LightData {
	DirectX::XMFLOAT3 pos;
};

class DeferRendererApp : public D3DApp
{
public:
	void ApplyGBufferPSO(bool bSetPSO = false);
	void ApplyLightingPSO(bool bSetPSO = false);

	void UpdateConstantBuffer(CameraData& camData, LightData& ligData);

	virtual void CreateRtvAndDsvDescriptorHeaps();

private:
	const static int numRTV = 3;
	ComPtr<ID3D12DescriptorHeap> mCbvSrvHeap;
	ComPtr<ID3D12RootSignature> mRootSignature;
	ComPtr<ID3D12Resource> mRtvTexture[numRTV];
	ComPtr<ID3D12Resource> mDepthTexture;
	ComPtr<ID3D12PipelineState> mLightPso;

	ComPtr<ID3D12Resource> mViewCB;
	ComPtr<ID3D12Resource> mLightCB;

	float mClearColor[4] = { 0.0f,0.0f,0.0f,1.0f };
	DXGI_FORMAT mDsvFormat = DXGI_FORMAT_D24_UNORM_S8_UINT;
	DXGI_FORMAT mRtvFormat[3] = { DXGI_FORMAT_R11G11B10_FLOAT,DXGI_FORMAT_R8G8B8A8_SNORM,DXGI_FORMAT_R8G8B8A8_UNORM };
};