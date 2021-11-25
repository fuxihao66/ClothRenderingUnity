#include "pch.h"
#include "framework.h"
#include "BCCRead.h"
#include <cstdio>
#include <vector>
typedef unsigned long long uint64_t;
struct FVector3 {
    float x;
    float y;
    float z;
};
// 这是导出函数的一个示例。
extern "C" {
    struct BCCHeader
    {
        char sign[3];
        unsigned char byteCount;
        char curveType[2];
        char dimensions;
        char upDimension;
        uint64_t curveCount;
        uint64_t totalControlPointCount;
        char fileInfo[40];
    };
    BCCREAD_API int ReadBCCFile(const char* bccFilePath, unsigned char* vertexBuffer,  unsigned int * indicesBuffer, unsigned int& vertexNum, unsigned int& indexNum)
    {
            BCCHeader header;
            FILE* pFile = fopen(bccFilePath, "rb");
            fread(&header, sizeof(header), 1, pFile);

            if (header.sign[0] != 'B') return false; // Invalid file signature
            if (header.sign[1] != 'C') return false; // Invalid file signature
            if (header.sign[2] != 'C') return false; // Invalid file signature
            if (header.byteCount != 0x44) return false; // Only supporting 4-byte integers and floats


            if (header.curveType[0] != 'C') return -1; // Not a Catmull-Rom curve
            if (header.curveType[1] != '0') return -1; // Not uniform parameterization
            if (header.dimensions != 3) return -1; // Only curves in 3D

            // TODO: CONTROLPOINTS的第四个分量存这个点属于哪个yarn
            // 用于索引R和theta

            vertexNum = header.totalControlPointCount;

            std::vector<FVector3> controlPoints(header.totalControlPointCount);
            std::vector<int> firstControlPoint(header.curveCount + 1);
            std::vector<char> isCurveLoop(header.curveCount);
            FVector3* cp = controlPoints.data();
            int prevCP = 0;
            for (uint64_t i = 0; i < header.curveCount; i++)
            {
                int curveControlPointCount;
                fread(&curveControlPointCount, sizeof(int), 1, pFile);
                isCurveLoop[i] = curveControlPointCount < 0;
                if (curveControlPointCount < 0) curveControlPointCount = -curveControlPointCount;

                fread(cp, sizeof(FVector3), curveControlPointCount, pFile);

                cp += curveControlPointCount;
                firstControlPoint[i] = prevCP;
                prevCP += curveControlPointCount;
            }
            firstControlPoint[header.curveCount] = prevCP;

            // TODO: LOOP
            std::vector<unsigned int> indices;
            for (int i = 0; i < header.curveCount; i++)
            {
                int curveControlPointNum = firstControlPoint[i + 1] - firstControlPoint[i];
                int startIndex = indices.size();
                indices.resize(indices.size() + (curveControlPointNum - 3) * 4);
                for (int j = 0; j < (curveControlPointNum - 3); j++)
                {
                    indices[startIndex++] = firstControlPoint[i] + j;
                    indices[startIndex++] = firstControlPoint[i] + j + 1;
                    indices[startIndex++] = firstControlPoint[i] + j + 2;
                    indices[startIndex++] = firstControlPoint[i] + j + 3;
                }
            }

            indexNum = indices.size();

            memcpy(vertexBuffer, controlPoints.data(), header.totalControlPointCount * sizeof(FVector3));
            memcpy(indicesBuffer, indices.data(), indexNum * sizeof(unsigned int));

        return 0;
    }
}
