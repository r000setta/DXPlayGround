#pragma once
#include "GPUResource.h"

enum class TextureViewDimension :int
{
	Tex2D = 0,
	Tex3D,
	CubeMap,
	Count
};

class JTexture :public GPUResource
{
protected:
	DXGI_FORMAT format;
	uint64_t resourceSize = 0;
	JTexture() {}
	UINT mWidth = 0;
	UINT mHeight = 0;
	UINT mMipCount = 1;
	TextureViewDimension dimension;
	UINT srvID = 0;

public:
	virtual ~JTexture() {}

	uint64_t GetResourceSize() const { return resourceSize; }
	TextureViewDimension GetDimension() const { return dimension; }
	DXGI_FORMAT GetFormat() const { return format; }
	UINT GetWidth() const { return mWidth; }
	UINT GetHeight() const { return mHeight; }
	UINT GetMipCount() const { return mMipCount; }
};