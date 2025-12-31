/*
  Multi-Format Exporter 1.0

  Copyright (C) 2025 Andrzej Chomiak

  ZLIB License

  This software is provided 'as-is', without any express or implied
  warranty. In no event will the authors be held liable for any damages
  arising from the use of this software.

  Permission is granted to anyone to use this software for any purpose,
  including commercial applications, and to alter it and redistribute it
  freely, subject to the following restrictions:

  1. The origin of this software must not be misrepresented; you must not
     claim that you wrote the original software. If you use this software
     in a product, an acknowledgment in the product documentation would be
     appreciated but is not required.
  2. Altered source versions must be plainly marked as such, and must not be
     misrepresented as being the original software.
  3. This notice may not be removed or altered from any source distribution.
*/

-- MFE_Options.ms


MFE_FileFormat_X = 1
MFE_FileFormat_Obj = 2
MFE_FileFormat_Dae = 3

MFE_FileVariant_StaticMesh = 1
MFE_FileVariant_AnimatedMesh = 2
MFE_FileVariant_AnimatedMeshOnly = 3
MFE_FileVariant_AnimationOnly = 4

MFE_Units_Inches = 1
MFE_Units_Feet = 2
MFE_Units_Miles = 3
MFE_Units_Millimeters = 4
MFE_Units_Centimeters = 5
MFE_Units_Decimeters = 6
MFE_Units_Meters = 7
MFE_Units_Kilometers = 8


function MFE_unitsID type = 
(
	case type of
	(
		#Inches: MFE_Units_Inches
		#Feet: MFE_Units_Feet
		#Miles: MFE_Units_Miles
		#Millimeters: MFE_Units_Millimeters
		#Centimeters: MFE_Units_Centimeters
		#Meters: MFE_Units_Meters
		#Kilometers: MFE_Units_Kilometers
	)
)


struct MFE_Options
(
	exportYUp = true,
	exportUnits = MFE_unitsID units.SystemType,
	exportScale = units.SystemScale,
	fileFormat = MFE_FileFormat_X,
	fileVariant = MFE_FileVariant_AnimatedMesh,
	flipFlippedFaces = true,
	maxBonesPerVertex = 4,
	poseFrame = 0,
	enableNormals = true,
	enableTangents = false,
	enableColors = false,
	maxTexCoordSets = 1,
	changeBitmapPath = false,
	changeBitmapExt = false,
	newBitmapPath = "",
	newBitmapExt = "",
	reduceFrames = true,
	separateTransforms = true,
	animations = #()
)


-- MFE_MeshData.ms


struct MFE_ElementSet
(
	list,
	hashSize,
	elements,

	function init numHashKeys = 
	(
		list = #()
		list.count = numHashKeys * 2
		hashSize = numHashKeys
		elements = #()
	),

	function size = 
	(
		elements.count
	),

	function insert element = 
	(
		local hashValue = (mod (abs (getHashValue (element * 2654435769) 0)) hashSize) as integer
		local listPos = (hashValue + 1) * 2
		local index = list[listPos - 1]

		while index != undefined and elements[index] != element do
		(
			local nextPos = list[listPos]

			if nextPos != undefined then
			(
				listPos = nextPos
				index = list[listPos - 1]
			)
			else
			(
				nextPos = list.count + 2
				list[listPos] = nextPos
				list.count = nextPos
				listPos = nextPos
				index = undefined
			)
		)

		if index == undefined then
		(
			index = elements.count + 1
			list[listPos - 1] = index
			elements[index] = element
		)

		index
	)
)


struct MFE_ComposedSet
(
	list,
	hashSize,
	components,

	function init numHashKeys numComponents = 
	(
		list = #()
		list.count = numHashKeys * 2
		hashSize = numHashKeys
		components = #()
		components.count = numComponents
		for i = 1 to numComponents do components[i] = #()
	),

	function size = 
	(
		components[1].count
	),

	function insert element = 
	(
		local hashValue = 0
		local numComponents = components.count

		for i = 1 to numComponents where element[i] != undefined do
		(
			hashValue = getHashValue (element[i] * 2654435769) hashValue
		)

		hashValue = (mod (abs hashValue) hashSize) as integer

		local listPos = (hashValue + 1) * 2
		local index = list[listPos - 1]

		while index != undefined and not (
			local r = true
			for i = 1 to numComponents where r do r = components[i][index] == element[i]
			r) do
		(
			local nextPos = list[listPos]

			if nextPos != undefined then
			(
				listPos = nextPos
				index = list[listPos - 1]
			)
			else
			(
				nextPos = list.count + 2
				list[listPos] = nextPos
				list.count = nextPos
				listPos = nextPos
				index = undefined
			)
		)

		if index == undefined then
		(
			index = components[1].count + 1
			list[listPos - 1] = index
			for i = 1 to numComponents do components[i][index] = element[i]
		)

		index
	)
)


struct MFE_VertexComponents
(
	enableNormals = true,
	enableTangents = false,
	enableColors = false,
	maxTexCoordSets = 1
)


struct MFE_BoneData
(
	boneID,
	boneObj,
	weights,
	indices
)


struct MFE_MeshData
(
	positions,
	normals,
	tangents,
	bitangents,
	colors,
	texCoordSets,
	faces,
	normalFaces,
	tangentFaces,
	bitangentFaces,
	colorFaces,
	texCoordSetFaces,
	submeshIDs,
	submeshIDToMDIndex,
	submeshIDGroups,
	mapChannels,
	numOriginalVertices,
	newIndexToOldIndex,
	maxBonesPerVertex,
	maxBonesPerFace,
	deformBones,
	allBoneNodes,
	rootBoneNodes,
	unweightedVertices,

	function sortValidFacesByMDIndex faceIndices matIDToMDIndex meshObj = 
	(
		struct Submesh
		(
			faces = #(),
			submeshIDs = #(),
			faceIndices = #()
		)

		local maxMatID = matIDToMDIndex.count
		local submeshes = #()
		submeshes.count = maxMatID

		for submeshIndex = 1 to submeshes.count do
		(
			submeshes[submeshIndex] = Submesh()
		)

		local numVerts = meshObj.numVerts
		local numFaces = meshObj.numFaces
		local verts = meshObj.verts

		local vSet = MFE_ElementSet()
		local fSet = MFE_ElementSet()
		local mSet = MFE_ElementSet()
		local indexUsed = #{}

		vSet.init numVerts
		fSet.init numFaces
		mSet.init maxMatID
		indexUsed.count = numFaces

		for faceIndex = 1 to numFaces do
		(
			local face = getFace meshObj faceIndex
			local i0 = vSet.insert verts[face.x as integer].pos
			local i1 = vSet.insert verts[face.y as integer].pos
			local i2 = vSet.insert verts[face.z as integer].pos

			if i0 != i1 and i0 != i2 and i1 != i2 then
			(
				local newFace = Point3 i0 i1 i2
				local newFaceIndex = fSet.insert newFace

				if not indexUsed[newFaceIndex] then
				(
					indexUsed[newFaceIndex] = true

					local matID = getFaceMatID meshObj faceIndex
					local wrappedMatID = ((mod (matID - 1) maxMatID) + 1) as integer
					local submeshIndex = mSet.insert matIDToMDIndex[wrappedMatID]

					append submeshes[submeshIndex].faces newFace
					append submeshes[submeshIndex].submeshIDs submeshIndex
					append submeshes[submeshIndex].faceIndices faceIndex
				)
			)
		)

		submeshes.count = mSet.elements.count

		faces = #()
		submeshIDs = #()
		submeshIDGroups = #()
		faceIndices.count = 0

		for i = 1 to submeshes.count do
		(
			local firstFaceIndex = faces.count + 1

			join faces submeshes[i].faces
			join submeshIDs submeshes[i].submeshIDs
			join faceIndices submeshes[i].faceIndices

			local lastFaceIndex = faces.count

			submeshIDGroups[i] = Point2 firstFaceIndex lastFaceIndex
		)

		positions = vSet.elements

		mSet.elements
	),

	function registerFaceIndex facesPerVertex vertexIndex faceIndex = 
	(
		local listPos = vertexIndex * 2
		local index = facesPerVertex[listPos - 1]

		if index != undefined then
		(
			local nextPos = facesPerVertex[listPos]

			local newNodePos = facesPerVertex.count + 2
			facesPerVertex.count = newNodePos

			facesPerVertex[newNodePos - 1] = index
			facesPerVertex[newNodePos] = nextPos

			facesPerVertex[listPos - 1] = undefined
			facesPerVertex[listPos] = newNodePos
		)

		facesPerVertex[listPos - 1] = faceIndex
	),

	function calcVertexAngle vertexIndex face = 
	(
		local p0, p1, p2

		if (face.x as integer) == vertexIndex then
		(
			p0 = positions[face.z as integer]
			p1 = positions[face.x as integer]
			p2 = positions[face.y as integer]
		)
		else if (face.y as integer) == vertexIndex then
		(
			p0 = positions[face.x as integer]
			p1 = positions[face.y as integer]
			p2 = positions[face.z as integer]
		)
		else
		(
			p0 = positions[face.y as integer]
			p1 = positions[face.z as integer]
			p2 = positions[face.x as integer]
		)

		local v0 = p2 - p1
		local v1 = p0 - p1

		if (length v0) > 0.0 and (length v1) > 0.0 then
		(
			local d = dot (normalize v0) (normalize v1)
			if d < -1.0 then d = -1.0 else if d > 1.0 then d = 1.0
			acos d
		)
		else
		(
			0.0
		)
	),

	function calcVertexNormal vertexIndex faceIndex faceNormals faceSmGroups facesPerVertex = 
	(
		local normal = Point3 0 0 0
		local smGroup = faceSmGroups[faceIndex]

		if smGroup == 0 then
		(
			normal = faceNormals[faceIndex]
		)
		else
		(
			local listPos = vertexIndex * 2
			local index = facesPerVertex[listPos - 1]

			while index != undefined do
			(
				if (bit.and smGroup faceSmGroups[index]) != 0 then
				(
					normal += faceNormals[index] * (calcVertexAngle vertexIndex faces[index])
				)

				listPos = facesPerVertex[listPos]

				if listPos != undefined then
				(
					index = facesPerVertex[listPos - 1]
				)
				else
				(
					index = undefined
				)
			)
		)

		normalize normal
	),

	function addNormals faceIndices meshObj = 
	(
		local faceNormals = #()
		local faceSmGroups = #()
		local facesPerVertex = #()
		facesPerVertex.count = positions.count * 2

		for i = 1 to faces.count do
		(
			local face = faces[i]
			local oldFaceIndex = faceIndices[i]

			append faceNormals (normalize (getFaceNormal meshObj oldFaceIndex))
			append faceSmGroups (getFaceSmoothGroup meshObj oldFaceIndex)

			registerFaceIndex facesPerVertex (face.x as integer) i
			registerFaceIndex facesPerVertex (face.y as integer) i
			registerFaceIndex facesPerVertex (face.z as integer) i
		)

		local nSet = MFE_ElementSet()
		nSet.init positions.count

		normalFaces = #()

		for i = 1 to faces.count do
		(
			local face = faces[i]
			local i0 = nSet.insert (calcVertexNormal (face.x as integer) i faceNormals faceSmGroups facesPerVertex)
			local i1 = nSet.insert (calcVertexNormal (face.y as integer) i faceNormals faceSmGroups facesPerVertex)
			local i2 = nSet.insert (calcVertexNormal (face.z as integer) i faceNormals faceSmGroups facesPerVertex)

			append normalFaces (Point3 i0 i1 i2)
		)

		normals = nSet.elements
	),

	function addColors faceIndices meshObj = 
	(
		local hasVertexColors = meshop.getMapSupport meshObj 0
		local hasVertexAlpha = meshop.getMapSupport meshObj -2
		local getMapFace = meshop.getMapFace
		local getMapVert = meshop.getMapVert

		local cSet = MFE_ElementSet()
		cSet.init positions.count

		colorFaces = #()

		for i = 1 to faces.count do
		(
			local oldFaceIndex = faceIndices[i]
			local c0, c1, c2

			if hasVertexColors then
			(
				local mapFace = getMapFace meshObj 0 oldFaceIndex
				local t0 = getMapVert meshObj 0 (mapFace.x as integer)
				local t1 = getMapVert meshObj 0 (mapFace.y as integer)
				local t2 = getMapVert meshObj 0 (mapFace.z as integer)

				t0 *= 255.0
				t1 *= 255.0
				t2 *= 255.0

				c0 = t0 as color
				c1 = t1 as color
				c2 = t2 as color
			)
			else
			(
				c0 = white
				c1 = white
				c2 = white
			)

			if hasVertexAlpha then
			(
				local mapFace = getMapFace meshObj -2 oldFaceIndex
				local t0 = getMapVert meshObj -2 (mapFace.x as integer)
				local t1 = getMapVert meshObj -2 (mapFace.y as integer)
				local t2 = getMapVert meshObj -2 (mapFace.z as integer)

				c0.a = t0.x * 255.0
				c1.a = t1.x * 255.0
				c2.a = t2.x * 255.0
			)

			append colorFaces (Point3 (cSet.insert c0) (cSet.insert c1) (cSet.insert c2))
		)

		colors = cSet.elements
	),

	function addTexCoords faceIndices meshObj = 
	(
		local numMapChannels = mapChannels.count
		local getMapFace = meshop.getMapFace
		local getMapVert = meshop.getMapVert

		local sets = #()
		sets.count = numMapChannels

		for i = 1 to numMapChannels do
		(
			sets[i] = MFE_ElementSet()
			sets[i].init positions.count
		)

		texCoordSetFaces = #()
		texCoordSetFaces.count = numMapChannels

		for i = 1 to numMapChannels do
		(
			texCoordSetFaces[i] = #()
		)

		for i = 1 to faces.count do
		(
			local oldFaceIndex = faceIndices[i]

			for j = 1 to numMapChannels do
			(
				local mapChannel = mapChannels[j]
				local mapFace = getMapFace meshObj mapChannel oldFaceIndex
				local t0 = getMapVert meshObj mapChannel (mapFace.x as integer)
				local t1 = getMapVert meshObj mapChannel (mapFace.y as integer)
				local t2 = getMapVert meshObj mapChannel (mapFace.z as integer)
				local tSet = sets[j]

				t0.z = 0.0
				t1.z = 0.0
				t2.z = 0.0

				append texCoordSetFaces[j] (Point3 (tSet.insert t0) (tSet.insert t1) (tSet.insert t2))
			)
		)

		texCoordSets = #()
		texCoordSets.count = numMapChannels

		for i = 1 to numMapChannels do
		(
			texCoordSets[i] = sets[i].elements
		)
	),

	function registerFaceData facesPerVertexKey vertexKey faceData = 
	(
		-- faceData.x = edge start (vertex key)
		-- faceData.y = edge end (vertex key)
		-- faceData.z = faceIndex * 4 + corner

		local listPos = vertexKey * 2
		local data = facesPerVertexKey[listPos - 1]

		while data != undefined do
		(
			local nextPos = facesPerVertexKey[listPos]

			if data.x == faceData.y then -- insert before
			(
				local newNodePos = facesPerVertexKey.count + 2
				facesPerVertexKey.count = newNodePos

				facesPerVertexKey[newNodePos - 1] = data
				facesPerVertexKey[newNodePos] = nextPos

				facesPerVertexKey[listPos - 1] = undefined
				facesPerVertexKey[listPos] = newNodePos

				data = undefined
			)
			else if data.y == faceData.x or nextPos == undefined then -- insert after
			(
				local newNodePos = facesPerVertexKey.count + 2
				facesPerVertexKey.count = newNodePos

				facesPerVertexKey[newNodePos - 1] = undefined
				facesPerVertexKey[newNodePos] = nextPos

				facesPerVertexKey[listPos] = newNodePos
				listPos = newNodePos

				data = undefined
			)
			else
			(
				listPos = nextPos
				data = facesPerVertexKey[listPos - 1]
			)
		)

		facesPerVertexKey[listPos - 1] = faceData
	),

	function calcVertexTangent vertexKey vertexNormal faceIndex faceTangents facesPerVertexKey = 
	(
		local listPos = vertexKey * 2
		local data = facesPerVertexKey[listPos - 1]
		local groupPos1 = undefined
		local groupPos2 = undefined
		local currentGroupPos = listPos

		while data != undefined do
		(
			if (data.z as integer / 4) == faceIndex then
			(
				groupPos1 = currentGroupPos
			)

			listPos = facesPerVertexKey[listPos]

			if listPos != undefined then
			(
				local edgeEnd = data.y

				data = facesPerVertexKey[listPos - 1]

				if edgeEnd != data.x then
				(
					currentGroupPos = listPos
				)
			)
			else
			(
				listPos = vertexKey * 2

				if groupPos1 != listPos then
				(
					if data.y == facesPerVertexKey[listPos - 1].x and groupPos1 == currentGroupPos then
					(
						groupPos2 = listPos
					)
				)
				else
				(
					if data.y == facesPerVertexKey[listPos - 1].x and groupPos1 != currentGroupPos then
					(
						groupPos2 = currentGroupPos
					)
				)

				data = undefined
			)
		)

		if groupPos2 != undefined and groupPos2 < groupPos1 then
		(
			swap groupPos1 groupPos2
		)

		listPos = groupPos1

		local vertexTangent = Point3 0 0 0

		do
		(
			data = facesPerVertexKey[listPos - 1]

			while data != undefined do
			(
				local index = data.z as integer / 4
				local corner = bit.and (data.z as integer) 3
				local face = faces[index]
				local angle = calcVertexAngle face[corner] face

				vertexTangent += (normalize (faceTangents[index] - vertexNormal * (dot vertexNormal faceTangents[index]))) * angle

				listPos = facesPerVertexKey[listPos]

				if listPos != undefined then
				(
					local edgeEnd = data.y

					data = facesPerVertexKey[listPos - 1]

					if edgeEnd != data.x then
					(
						data = undefined
					)
				)
				else
				(
					data = undefined
				)
			)

			listPos = groupPos2
			groupPos2 = undefined
		)
		while (listPos != undefined)

		normalize vertexTangent
	),

	function addTangents faceIndices meshObj = 
	(
		local vertexKeyFaces = #()
		local faceTangents = #()
		local facesPerVertexKey = #()
		facesPerVertexKey.count = faces.count * 3 * 2

		local kSet = MFE_ElementSet()
		kSet.init (positions.count * 2)

		local texCoords = texCoordSets[1]
		local texCoordFaces = texCoordSetFaces[1]

		for i = 1 to faces.count do
		(
			local face = faces[i]
			local nFace = normalFaces[i]
			local tFace = texCoordFaces[i]

			local t0 = texCoords[tFace.x as integer]
			local t1 = texCoords[tFace.y as integer]
			local t2 = texCoords[tFace.z as integer]
			local du1 = t1.x - t0.x
			local dv1 = t1.y - t0.y
			local du2 = t2.x - t0.x
			local dv2 = t2.y - t0.y
			local areax2 = du1 * dv2 - du2 * dv1
			local orient = 1.0

			if areax2 < 0.0 then
			(
				orient *= -1.0
				tFace *= -1.0
			)

			local k0 = kSet.insert (Point3 face.x nFace.x tFace.x)
			local k1 = kSet.insert (Point3 face.y nFace.y tFace.y)
			local k2 = kSet.insert (Point3 face.z nFace.z tFace.z)
			append vertexKeyFaces (Point3 k0 k1 k2)

			registerFaceData facesPerVertexKey k0 (Point3 k1 k2 (i * 4 + 1))
			registerFaceData facesPerVertexKey k1 (Point3 k2 k0 (i * 4 + 2))
			registerFaceData facesPerVertexKey k2 (Point3 k0 k1 (i * 4 + 3))

			local p0 = positions[face.x as integer]
			local p1 = positions[face.y as integer]
			local p2 = positions[face.z as integer]
			local e1 = p1 - p0
			local e2 = p2 - p0
			local faceTangent = (normalize (e1 * dv2 - e2 * dv1)) * orient

			append faceTangents faceTangent
		)

		local vertexKeys = kSet.elements
		local gSet = MFE_ElementSet()
		local bSet = MFE_ElementSet()
		gSet.init positions.count
		bSet.init positions.count

		tangentFaces = #()
		bitangentFaces = #()

		for i = 1 to faces.count do
		(
			local nFace = normalFaces[i]
			local n0 = normals[nFace.x as integer]
			local n1 = normals[nFace.y as integer]
			local n2 = normals[nFace.z as integer]

			local kFace = vertexKeyFaces[i]
			local g0 = calcVertexTangent (kFace.x as integer) n0 i faceTangents facesPerVertexKey
			local g1 = calcVertexTangent (kFace.y as integer) n1 i faceTangents facesPerVertexKey
			local g2 = calcVertexTangent (kFace.z as integer) n2 i faceTangents facesPerVertexKey

			local b0 = cross n0 g0
			local b1 = cross n1 g1
			local b2 = cross n2 g2

			if vertexKeys[kFace.x as integer].z < 0 then -- orient
			(
				b0 *= -1.0
				b1 *= -1.0
				b2 *= -1.0
			)

			append tangentFaces (Point3 (gSet.insert g0) (gSet.insert g1) (gSet.insert g2))
			append bitangentFaces (Point3 (bSet.insert b0) (bSet.insert b1) (bSet.insert b2))
		)

		tangents = gSet.elements
		bitangents = bSet.elements
	),

	function pack faceIndices meshObj = 
	(
		local numComponents = 0
		local numTexCoordSets = texCoordSets.count

		numComponents += 1 -- submeshID
		numComponents += 1 -- position
		numComponents += 1 -- normal
		numComponents += 1 -- tangent
		numComponents += 1 -- bitangent
		numComponents += 1 -- color
		numComponents += numTexCoordSets

		local vSet = MFE_ComposedSet()
		local v0 = #()
		local v1 = #()
		local v2 = #()

		vSet.init (positions.count * 2) numComponents
		v0.count = numComponents
		v1.count = numComponents
		v2.count = numComponents

		local newFaces = #()

		for i = 1 to faces.count do
		(
			v0[1] = submeshIDs[i]
			v1[1] = submeshIDs[i]
			v2[1] = submeshIDs[i]

			local face = faces[i]
			v0[2] = positions[face.x as integer]
			v1[2] = positions[face.y as integer]
			v2[2] = positions[face.z as integer]

			if normals != undefined then
			(
				local nFace = normalFaces[i]
				v0[3] = normals[nFace.x as integer]
				v1[3] = normals[nFace.y as integer]
				v2[3] = normals[nFace.z as integer]
			)

			if tangents != undefined then
			(
				local gFace = tangentFaces[i]
				v0[4] = tangents[gFace.x as integer]
				v1[4] = tangents[gFace.y as integer]
				v2[4] = tangents[gFace.z as integer]

				local bFace = bitangentFaces[i]
				v0[5] = bitangents[bFace.x as integer]
				v1[5] = bitangents[bFace.y as integer]
				v2[5] = bitangents[bFace.z as integer]
			)

			if colors != undefined then
			(
				local cFace = colorFaces[i]
				v0[6] = colors[cFace.x as integer]
				v1[6] = colors[cFace.y as integer]
				v2[6] = colors[cFace.z as integer]
			)

			for j = 1 to numTexCoordSets do
			(
				local tFace = texCoordSetFaces[j][i]
				v0[6 + j] = texCoordSets[j][tFace.x as integer]
				v1[6 + j] = texCoordSets[j][tFace.y as integer]
				v2[6 + j] = texCoordSets[j][tFace.z as integer]
			)

			local i0 = vSet.insert v0
			local i1 = vSet.insert v1
			local i2 = vSet.insert v2

			append newFaces (Point3 i0 i1 i2)
		)

		positions = vSet.components[2]
		if normals != undefined then normals = vSet.components[3]
		if tangents != undefgined then tangents = vSet.components[4]
		if bitangents != undefined then bitangents = vSet.components[5]
		if colors != undefined then colors = vSet.components[6]
		for j = 1 to numTexCoordSets do texCoordSets[j] = vSet.components[6 + j]

		faces = newFaces
		if normalFaces != undeifned then normalFaces = newFaces
		if tangentFaces != undefined then tangentFaces = newFaces
		if bitangentFaces != undefined then bitangentFaces = newFaces
		if colorFaces != undefined then colorFaces = newFaces
		for j = 1 to numTexCoordSets do texCoordSetFaces[j] = newFaces
	),

	function registerBones skinMod vertexIndex newVertexIndex bonesPerVertexLimit = 
	(
		struct BoneWeight
		(
			boneID,
			weight,
			index
		)

		local numVertexWeights = skinOps.getVertexWeightCount skinMod vertexIndex
		local weights = #()

		for i = 1 to numVertexWeights do
		(
			local bw = BoneWeight()

			bw.boneID = skinOps.getVertexWeightBoneID skinMod vertexIndex i
			bw.weight = skinOps.getVertexWeight skinMod vertexIndex i
			bw.index = newVertexIndex

			for j = 1 to weights.count where bw != undefined do
			(
				if weights[j].boneID == bw.boneID then
				(
					bw = undefined
				)
				else if weights[j].weight < bw.weight then
				(
					insertItem bw weights j
					bw = undefined
				)
			)

			if bw != undefined then
			(
				append weights bw
			)
		)

		if bonesPerVertexLimit != undefined and weights.count > bonesPerVertexLimit then
		(
			weights.count = bonesPerVertexLimit
		)

		if maxBonesPerVertex < weights.count then
		(
			maxBonesPerVertex = weights.count
			maxBonesPerFace = maxBonesPerVertex * 3
		)

		local scale = 0

		for bw in weights do
		(
			scale += bw.weight
		)

		if scale != 0 and scale != 1 then
		(
			for bw in weights do
			(
				bw.weight /= scale
			)
		)

		for bw in weights do
		(
			local boneIndex = 1

			while boneIndex <= deformBones.count and deformBones[boneIndex].boneID != bw.boneID do
			(
				boneIndex = boneIndex + 1
			)

			if deformBones[boneIndex] == undefined then
			(
				local boneName = skinOps.getBoneName skinMod bw.boneID 0
				local boneObj = getNodeByName boneName

				deformBones[boneIndex] = MFE_BoneData()
				deformBones[boneIndex].boneID = bw.boneID
				deformBones[boneIndex].boneObj = boneObj
				deformBones[boneIndex].weights = #()
				deformBones[boneIndex].indices = #()
			)

			append deformBones[boneIndex].weights bw.weight
			append deformBones[boneIndex].indices bw.index
		)

		if weights.count == 0 then
		(
			append unweightedVertices newVertexIndex
		)
	),

	function processSkinData nodeObj bonesPerVertexLimit = 
	(
		local skinMod = nodeObj.modifiers[#skin]

		if skinMod != undefined then
		(
			undo off
			(
				local selSet = selection as array

				max modify mode
				select nodeObj

				for newIndex = 1 to newIndexToOldIndex.count do
				(
					registerBones skinMod newIndexToOldIndex[newIndex] newIndex bonesPerVertexLimit
				)

				local numBones = skinOps.getNumberBones skinMod

				for boneID = 1 to numBones do
				(
					local boneName = skinOps.getBoneName skinMod boneID 0
					local boneObj = getNodeByName boneName

					append allBoneNodes boneObj
				)

				for boneObj in allBoneNodes do
				(
					local p = boneObj
					local r = boneObj

					while p.parent != undefined do
					(
						p = p.parent

						if findItem allBoneNodes p != 0 then
						(
							r = p
						)
					)

					if findItem rootBoneNodes r == 0 then
					(
						append rootBoneNodes r
					)
				)

				select selSet
			)
		)
	),

	function init nodeObj matIDToMDIndex vertexComponents meshTM:(matrix3 1) separateVertexComponents:true assignUnweightedVertices:true bonesPerVertexLimit:undefined = 
	(
		local meshObj = snapshotAsMesh nodeObj
		transform meshObj meshTM

		local hasVertexColors = meshop.getMapSupport meshObj 0
		local hasVertexAlpha = meshop.getMapSupport meshObj -2
		local maxMapChannels = meshop.getNumMaps meshObj

		mapChannels = for i = 1 to maxMapChannels where meshop.getMapSupport meshObj i collect i

		if mapChannels.count > vertexComponents.maxTexCoordSets then
		(
			mapChannels.count = vertexComponents.maxTexCoordSets
		)

		local faceIndices = #()
		submeshIDToMDIndex = sortValidFacesByMDIndex faceIndices matIDToMDIndex meshObj

		if vertexComponents.enableNormals then
		(
			addNormals faceIndices meshObj
		)
		else
		(
			normals = undefined
			normalFaces = undefined
		)

		if vertexComponents.enableColors and (hasVertexColors or hasVertexAlpha) then
		(
			addColors faceIndices meshObj
		)
		else
		(
			colors = undefined
			colorFaces = undefined
		)

		if mapChannels.count != 0 then
		(
			addTexCoords faceIndices meshObj
		)
		else
		(
			texCoordSets = #()
			texCoordSetFaces = #()
		)

		if vertexComponents.enableNormals and vertexComponents.enableTangents and mapChannels.count != 0 then
		(
			addTangents faceIndices meshObj
		)
		else
		(
			tangents = undefined
			tangentFaces = undefined
			bitangents = undefined
			bitangentFaces = undefined
		)

		if not separateVertexComponents then
		(
			pack faceIndices meshObj
		)

		numOriginalVertices = meshObj.numVerts
		newIndexToOldIndex = #()

		for i = 1 to faces.count do
		(
			local oldFaceIndex = faceIndices[i]
			local oldFace = getFace meshObj oldFaceIndex
			local face = faces[i]

			newIndexToOldIndex[face.x as integer] = oldFace.x as integer
			newIndexToOldIndex[face.y as integer] = oldFace.y as integer
			newIndexToOldIndex[face.z as integer] = oldFace.z as integer
		)

		maxBonesPerVertex = 0
		maxBonesPerFace = 0
		deformBones = #()
		allBoneNodes = #()
		rootBoneNodes = #()
		unweightedVertices = #()

		processSkinData nodeObj bonesPerVertexLimit

		if unweightedVertices.count != 0 and assignUnweightedVertices then
		(
			for bd in deformBones where bd.boneObj == rootBoneNodes[1] do
			(
				local weights = for v in unweightedVertices collect 1.0

				join bd.weights weights
				join bd.indices unweightedVertices

				unweightedVertices = #()
			)
		)
	),

	function flipFaces = 
	(
		for i = 1 to faces.count do swap faces[i].y faces[i].z

		if normalFaces != undefined and normalFaces != faces then
		(
			for i = 1 to normalFaces.count do swap normalFaces[i].y normalFaces[i].z
		)

		if tangentFaces != undefined and tangentFaces != faces then
		(
			for i = 1 to tangentFaces.count do swap tangentFaces[i].y tangentFaces[i].z
		)

		if bitangentFaces != undefined and bitangentFaces != faces then
		(
			for i = 1 to bitangentFaces.count do swap bitangentFaces[i].y bitangentFaces[i].z
		)

		if colorFaces != undefined and colorFaces != faces then
		(
			for i = 1 to colorFaces.count do swap colorFaces[i].y colorFaces[i].z
		)

		for j = 1 to texCoordSetFaces.count do
		(
			local texCoordFaces = texCoordSetFaces[j]

			if texCoordFaces != faces then
			(
				for i = 1 to texCoordFaces.count do swap texCoordFaces[i].y texCoordFaces[i].z
			)
		)
	),

	function flipNormals = 
	(
		if normals != undefined then
		(
			for i = 1 to normals.count do
			(
				normals[i] = -normals[i]
			)
		)
	),

	function flipZCoords = 
	(
		for i = 1 to positions.count do
		(
			local p = positions[i]

			positions[i] = Point3 p.x p.y -p.z
		)

		if normals != undefined then
		(
			for i = 1 to normals.count do
			(
				local n = normals[i]

				normals[i] = Point3 n.x n.y -n.z
			)
		)

		if tangents != undefined then
		(
			for i = 1 to tangents.count do
			(
				local g = tangents[i]

				tangents[i] = Point3 g.x g.y -g.z
			)
		)

		if bitangents != undefined then
		(
			for i = 1 to bitangents.count do
			(
				local b = bitangents[i]

				bitangents[i] = Point3 b.x b.y -b.z
			)
		)
	),

	function flipVCoords = 
	(
		for j = 1 to texCoordSets.count do
		(
			local texCoords = texCoordSets[j]

			for i = 1 to texCoords.count do
			(
				local t = texCoords[i]

				texCoords[i] = Point3 t.x (1.0 - t.y) t.z
			)
		)

		if bitangents != undefined then
		(
			for i = 1 to bitangents.count do
			(
				bitangents[i] = -bitangents[i]
			)
		)
	)
)


-- MFE_MaterialData.ms


struct MFE_TextureData
(
	fileName,
	mapChannel,

	function init mapObj = 
	(
		if classOf mapObj == Bitmaptexture then
		(
			fileName = mapObj.fileName
			mapChannel = if mapObj.coords.mappingType == 0 and mapObj.coords.mapping == 0 then mapObj.coords.mapChannel else 1
		)
		else
		(
			fileName = ""
			mapChannel = 1
		)
	),

	function equals other = 
	(
		fileName == other.fileName and mapChannel == other.mapChannel
	)
)


struct MFE_MaterialData
(
	name,
	ambientColor,
	diffuseColor,
	emissiveColor,
	specularColor,
	glossiness,
	opacity,
	diffuseTexture = MFE_TextureData(),
	emissiveTexture = MFE_TextureData(),
	specularTexture = MFE_TextureData(),
	bumpTexture = MFE_TextureData(),
	twoSided,

	function init matObj nodeObj = 
	(
		if classOf matObj == StandardMaterial then
		(
			name = matObj.name
			ambientColor = matObj.ambient
			diffuseColor = matObj.diffuse
			emissiveColor = if matObj.useSelfIllumColor then matObj.selfIllumColor else matObj.diffuse * (matObj.selfIllumAmount / 100.0)
			emissiveColor.a = 255.0
			specularColor = matObj.specular * (matObj.specularLevel / 100.0)
			specularColor.a = 255.0
			glossiness = matObj.glossiness
			opacity = matObj.opacity
			diffuseTexture.init (if matObj.diffuseMapEnable then matObj.diffuseMap else undefined)
			emissiveTexture.init (if matObj.selfIllumMapEnable then matObj.selfIllumMap else undefined)
			specularTexture.init (if matObj.specularMapEnable then matObj.specularMap else undefined)
			bumpTexture.init (if matObj.bumpMapEnable then matObj.bumpMap else undefined)
			twoSided = matObj.twoSided
		)
		else
		(
			name = "Mtl " + nodeObj.name
			ambientColor = black
			diffuseColor = nodeObj.wireColor
			emissiveColor = black
			specularColor = color 229.5 229.5 229.5 255.0
			glossiness = 10.0
			opacity = 100.0
			diffuseTexture.init undefined
			emissiveTexture.init undefined
			specularTexture.init undefined
			bumpTexture.init undefined
			twoSided = false
		)
	),

	function equals other = 
	(
		name == other.name and 
		ambientColor == other.ambientColor and 
		diffuseColor == other.diffuseColor and 
		emissiveColor == other.emissiveColor and 
		specularColor == other.specularColor and 
		glossiness == other.glossiness and 
		opacity == other.opacity and 
		diffuseTexture.equals other.diffuseTexture and 
		emissiveTexture.equals other.emissiveTexture and 
		specularTexture.equals other.specularTexture and 
		bumpTexture.equals other.bumpTexture and 
		twoSided == other.twoSided
	)
)


function MFE_registerMaterial materials matObj nodeObj matID = 
(
	if classOf matObj == Multimaterial then
	(
		MFE_registerMaterial materials matObj[matID] nodeObj matID
	)
	else
	(
		local matData = MFE_MaterialData()

		matData.init matObj nodeObj

		for mdIndex = 1 to materials.count do
		(
			if materials[mdIndex].equals matData then
			(
				return mdIndex
			)
		)

		append materials matData

		materials.count
	)
)


function MFE_registerNodeMaterials materials nodeObj = 
(
	local matObj = nodeObj.material
	local matIDToMDIndex = #()

	if classOf matObj == Multimaterial then
	(
		for matID = 1 to matObj.numSubs do
		(
			matIDToMDIndex[matID] = MFE_registerMaterial materials matObj[matID] nodeObj matID
		)
	)
	else
	(
		matIDToMDIndex[1] = MFE_registerMaterial materials matObj nodeObj 1
	)

	matIDToMDIndex
)


-- MFE_NodeUtil.ms


struct MFE_NodeUtil
(
	exportRotTM = matrix3 1,
	exportScaleTM = matrix3 1,
	exportCoordSysTM = matrix3 [1,0,0] [0,1,0] [0,0,-1] [0,0,0],
	convertCoordSys = false,

	function init options rightHanded:true = 
	(
		exportRotTM = if options.exportyUp then rotateXMatrix -90 else matrix3 1
		exportScaleTM = scaleMatrix (Point3 options.exportScale options.exportScale options.exportScale)
		convertCoordSys = not rightHanded
	),

	function getWorldTM nodeObj = 
	(
		local tm

		if nodeObj == rootNode then
		(
			tm = matrix3 1
		)
		else
		(
			if convertCoordSys then
			(
				tm = exportCoordSysTM * nodeObj.transform * exportRotTM * exportCoordSysTM
			)
			else
			(
				tm = nodeObj.transform * exportRotTM
			)

			tm.translation *= exportScaleTM
		)

		tm
	),

	function getLocalTM nodeObj = 
	(
		local tm

		if nodeObj == rootNode then
		(
			tm = matrix3 1
		)
		else
		(
			if nodeObj.parent == undefined then
			(
				tm = getWorldTM nodeObj
			)
			else
			(
				tm = (getWorldTM nodeObj) * (inverse (getWorldTM nodeObj.parent))
			)
		)

		tm
	),

	function sampleNodeAnimation keyValues keyTimes nodeObj animStart animEnd samplingRate = 
	(
		local start = animStart as integer
		local end = animEnd as integer
		local step = (4800 / samplingRate) as integer
		local maxKeyTime = end - start
		local numKeys = (maxKeyTime / step) + 1

		if (numKeys - 1) * step < maxKeyTime then
		(
			numKeys = numKeys + 1
		)

		keyValues.count = numKeys
		keyTimes.count = numKeys

		for i = 1 to numKeys do
		(
			local keyTime = (i - 1) * step

			if i == numKeys then
			(
				keyTime = maxKeyTime
			)

			local timeVal = 0f
			timeVal.ticks = start + keyTime

			keyValues[i] = at time timeVal (getLocalTM nodeObj)
			keyTimes[i] = keyTime
		)

		numKeys
	)
)


function MFE_reduceKeys keyValues keyTimes = 
(
	local srcValues = #()
	local srcTimes = #()

	join srcValues keyValues
	join srcTimes keyTimes

	keyValues.count = 0
	keyTimes.count = 0

	local a, b, c

	for i = 1 to srcValues.count do
	(
		if i == 1 or i == srcValues.count then
		(
			a = srcValues[i] as string
			b = srcValues[i + 1] as string

			append keyValues srcValues[i]
			append keyTimes srcTimes[i]
		)
		else
		(
			c = srcValues[i + 1] as string

			if a != b or b != c then
			(
				a = b

				append keyValues srcValues[i]
				append keyTimes srcTimes[i]
			)

			b = c
		)
	)

	keyValues.count
)


function MFE_getPosKeys posKeyValues posKeyTimes keyValues keyTimes = 
(
	posKeyValues.count = 0
	posKeyTimes.count = 0

	for i = 1 to keyValues.count do
	(
		local tm = keyValues[i], t

		if tm.determinantSign > 0 then
		(
			t = tm.translationpart
		)
		else
		(
			t = ((scaleMatrix (Point3 1 1 -1)) * tm).translationpart
		)

		append posKeyValues t
		append posKeyTimes keyTimes[i]
	)
)


function MFE_getRotKeys rotKeyValues rotKeyTimes keyValues keyTimes = 
(
	rotKeyValues.count = 0
	rotKeyTimes.count = 0

	local p, q

	for i = 1 to keyValues.count do
	(
		local tm = keyValues[i]

		if tm.determinantSign > 0 then
		(
			q = tm.rotationpart
		)
		else
		(
			q = ((scaleMatrix (Point3 1 1 -1)) * tm).rotationpart
		)

		q = normalize q

		if i != 1 and p.x * q.x + p.y * q.y + p.z * q.z + p.w * q.w < 0 then
		(
			q = -q
		)

		p = q

		append rotKeyValues q
		append rotKeyTimes keyTimes[i]
	)
)


function MFE_getScaleKeys scaleKeyValues scaleKeyTimes keyValues keyTimes = 
(
	scaleKeyValues.count = 0
	scaleKeyTimes.count = 0

	for i = 1 to keyValues.count do
	(
		local tm = keyValues[i], s

		if tm.determinantSign > 0 then
		(
			s = tm.scalepart
		)
		else
		(
			s = ((scaleMatrix (Point3 1 1 -1)) * tm).scalepart
			s.z = -s.z
		)

		append scaleKeyValues s
		append scaleKeyTimes keyTimes[i]
	)
)


struct MFE_IDGen
(
	values = #(),
	names = #(),
	ids = #(),
	link = "_",

	function isAlpha str index = 
	(
		str.count >= index and ((str[index] >= "A" and str[index] <= "Z") or (str[index] >= "a" and str[index] <= "z"))
	),

	function isDigit str index = 
	(
		str.count >= index and str[index] >= "0" and str[index] <= "9"
	),

	function validNameFromString str = 
	(
		local s = ""

		if not isAlpha str 1 then
		(
			s += "L"
			s += link
		)

		for i = 1 to str.count do
		(
			if (isAlpha str i) or (isDigit str i) then
			(
				s += str[i]
			)
			else
			(
				s += link
			)
		)

		s
	),

	function getID value name = 
	(
		local i = findItem values value

		if i == 0 then
		(
			if name == "" then name = "Unnamed"

			name = validNameFromString name

			local k = 1

			for j = 1 to names.count where names[j] == name do
			(
				k += 1
			)

			i = values.count + 1
			values[i] = value
			names[i] = name
			ids[i] = if k == 1 then name else name + link + (k as string)
		)

		ids[i]
	),

	function getValue id = 
	(
		local i = findItem ids id

		if i == 0 then undefined else values[i]
	)
)


function MFE_isVisibleGeomNode nodeObj = 
(
	nodeObj.renderable and not nodeObj.isHidden and 
	superClassOf nodeObj == GeometryClass and classOf nodeObj != TargetObject
)


function MFE_getDeformBones nodeObj = 
(
	local skinMod = nodeObj.modifiers[#skin]
	local deformBones = #()

	if skinMod != undefined then
	(
		undo off
		(
			local selSet = selection as array

			max modify mode
			select nodeObj

			local numVertices = skinOps.GetNumberVertices skinMod

			for vertexIndex = 1 to numVertices do
			(
				local numVertexWeights = skinOps.getVertexWeightCount skinMod vertexIndex

				for i = 1 to numVertexWeights do
				(
					local boneID = skinOps.getVertexWeightBoneID skinMod vertexIndex i
					local boneName = skinOps.getBoneName skinMod boneID 0
					local boneObj = getNodeByName boneName

					if findItem deformBones boneObj == 0 then
					(
						append deformBones boneObj
					)
				)
			)

			select selSet
		)
	)

	deformBones
)


function MFE_registerNodesOnPath levels nodeObj = 
(
	local i = 1
	local p = nodeObj.parent

	while p != undefined do
	(
		i += 1
		p = p.parent
	)

	p = nodeObj

	while p != undefined do
	(
		if levels[i] == undefined then
		(
			levels[i] = #(p)
		)
		else if findItem levels[i] p == 0 then
		(
			append levels[i] p
		)

		i -= 1
		p = p.parent
	)
)


function MFE_registerNodePaths levels nodes includeBones:true = 
(
	for nodeObj in nodes do
	(
		MFE_registerNodesOnPath levels nodeObj

		if includeBones then
		(
			local deformBones = MFE_getDeformBones nodeObj

			for boneObj in deformBones do
			(
				MFE_registerNodesOnPath levels boneObj
			)
		)
	)
)


function MFE_isNodeRegistered levels nodeObj = 
(
	local i = 1
	local p = nodeObj.parent

	while p != undefined do
	(
		i += 1
		p = p.parent
	)

	i <= levels.count and findItem levels[i] nodeObj != 0
)


-- MFE_ObjFileWriter.ms


function MFE_replaceSpaces str = 
(
	local s = ""

	for i = 1 to str.count do
	(
		s += if str[i] == " " then "_" else str[i]
	)

	s
)


function MFE_changeBitmapPath fileName options = 
(
	local path = if options.changeBitmapPath then options.newBitmapPath else getFilenamePath fileName
	local file = getFilenameFile fileName
	local type = if options.changeBitmapExt then options.newBitmapExt else getFilenameType fileName

	if path.count > 0 and path[path.count] != "\\" and path[path.count] != "/" then
	(
		path = path + "\\"
	)

	if type.count > 0 and type[1] != "." then
	(
		type = "." + type
	)

	path + file + type
)


function MFE_writeObjFile nodes objFileName objFile mtlFileName mtlFile options = 
(
	local idGen = MFE_IDGen()
	local materials = #()

	if nodes.count != 0 then
	(
		local nodeUtil = MFE_NodeUtil()
		nodeUtil.init options

		format "mtllib %\n" mtlFileName to:objFile

		local positionIndex = 0
		local normalIndex = 0
		local texCoordIndex = 0

		for nodeObj in nodes do
		(
			if MFE_isVisibleGeomNode nodeObj then
			(
				local md = MFE_MeshData()
				local vc = MFE_VertexComponents()
				local tm = nodeUtil.exportRotTM * nodeUtil.exportScaleTM

				vc.enableNormals = options.enableNormals
				vc.enableTangents = false
				vc.enableColors = false
				vc.maxTexCoordSets = if options.maxTexCoordSets < 1 then 0 else 1

				md.init nodeObj (MFE_registerNodeMaterials materials nodeObj) vc meshTM:tm

				if nodeObj.transform.determinantSign < 0 then
				(
					if options.flipFlippedFaces then md.flipFaces()
					md.flipNormals()
				)

				local positions = md.positions
				local normals = md.normals
				local texCoords = md.texCoordSets[1]
				local faces = md.faces
				local normalFaces = md.normalFaces
				local texCoordFaces = md.texCoordSetFaces[1]
				local submeshIDs = md.submeshIDs

				local hasNormals = normals != undefined
				local hasTexCoords = texCoords != undefined

				format "o %\n" (MFE_replaceSpaces nodeObj.name) to:objFile

				for i = 1 to positions.count do
				(
					format "v % % %\n" positions[i].x positions[i].y positions[i].z to:objFile
				)

				if hasTexCoords then
				(
					for i = 1 to texCoords.count do
					(
						format "vt % %\n" texCoords[i].x texCoords[i].y to:objFile
					)
				)

				if hasNormals then
				(
					for i = 1 to normals.count do
					(
						format "vn % % %\n" normals[i].x normals[i].y normals[i].z to:objFile
					)
				)

				local lastSubmeshID = 0

				for i = 1 to faces.count do
				(
					if lastSubmeshID != submeshIDs[i] then
					(
						lastSubmeshID = submeshIDs[i]

						local matData = materials[md.submeshIDToMDIndex[lastSubmeshID]]

						format "usemtl %\n" (idGen.getID matData matData.name) to:objFile
					)

					local p0 = positionIndex + (faces[i].x as integer)
					local p1 = positionIndex + (faces[i].y as integer)
					local p2 = positionIndex + (faces[i].z as integer)

					if hasNormals and hasTexCoords then
					(
						local n0 = normalIndex + (normalFaces[i].x as integer)
						local n1 = normalIndex + (normalFaces[i].y as integer)
						local n2 = normalIndex + (normalFaces[i].z as integer)

						local t0 = texCoordIndex + (texCoordFaces[i].x as integer)
						local t1 = texCoordIndex + (texCoordFaces[i].y as integer)
						local t2 = texCoordIndex + (texCoordFaces[i].z as integer)

						format "f %/%/% %/%/% %/%/%\n" p0 t0 n0 p1 t1 n1 p2 t2 n2 to:objFile
					)
					else if hasNormals then
					(
						local n0 = normalIndex + (normalFaces[i].x as integer)
						local n1 = normalIndex + (normalFaces[i].y as integer)
						local n2 = normalIndex + (normalFaces[i].z as integer)

						format "f %//% %//% %//%\n" p0 n0 p1 n1 p2 n2 to:objFile
					)
					else if hasTexCoords then
					(
						local t0 = texCoordIndex + (texCoordFaces[i].x as integer)
						local t1 = texCoordIndex + (texCoordFaces[i].y as integer)
						local t2 = texCoordIndex + (texCoordFaces[i].z as integer)

						format "f %/% %/% %/%\n" p0 t0 p1 t1 p2 t2 to:objFile
					)
					else
					(
						format "f % % %\n" p0 p1 p2 to:objFile
					)
				)

				positionIndex += positions.count

				if hasNormals then normalIndex += normals.count
				if hasTexCoords then texCoordIndex += texCoords.count
			)
		)
	)

	if materials.count != 0 then
	(
		for matData in materials do
		(
			format "newmtl %\n" (idGen.getID matData matData.name) to:mtlFile

			local ka = (Point3 matData.ambientColor.r matData.ambientColor.g matData.ambientColor.b) / 255.0
			local kd = (Point3 matData.diffuseColor.r matData.diffuseColor.g matData.diffuseColor.b) / 255.0
			local ke = (Point3 matData.emissiveColor.r matData.emissiveColor.g matData.emissiveColor.b) / 255.0
			local ks = (Point3 matData.specularColor.r matData.specularColor.g matData.specularColor.b) / 255.0
			local ns = matData.glossiness * 10.0
			local d = matData.opacity / 100.0

			format "Ka % % %\n" ka.x ka.y ka.z to:mtlFile

			if matData.diffuseTexture.fileName != "" then
			(
				format "map_Kd %\n" (MFE_changeBitmapPath matData.diffuseTexture.fileName options) to:mtlFile
			)
			else
			(
				format "Kd % % %\n" kd.x kd.y kd.z to:mtlFile
			)

			format "Ke % % %\n" ke.x ke.y ke.z to:mtlFile
			format "Ks % % %\n" ks.x ks.y ks.z to:mtlFile
			format "Ns %\n" ns to:mtlFile
			format "illum 2\n" to:mtlFile

			if d != 1.0 then
			(
				format "d %\n" d to:mtlFile
			)
		)
	)
)


-- MFE_XFileWriter.ms


MFE_intMin = -2147483647 - 1
MFE_unsignedBase = (MFE_intMin / 10) * 10 - 10
MFE_unsignedTens = MFE_unsignedBase / 10 + 1


function MFE_uintTens x = 
(
	if x >= 0 then
	(
		x / 10
	)
	else
	(
		x += MFE_unsignedBase
		if x < 0 then x -= 10
		MFE_unsignedTens + x / 10
	)
)


function MFE_uintUnits x = 
(
	if x < 0 then
	(
		x += MFE_unsignedBase
		if x < 0 then x += 10
	)

	x - (x / 10) * 10
)


function MFE_floatAsInt x = 
(
	x = x as float

	if not (x != 0.0) then -- NaN, 0.0
	(
		0
	)
	else
	(
		local s = 0 -- sign bit 0

		if x < 0 then
		(
			s = MFE_intMin -- sign bit 1
			x = -x
		)

		if x >= 1.175494351e-38 then -- float min
		(
			if x <= 3.402823466e+38 then -- float max
			(
				local e = floor ((log x) / 6.931472e-01)
				local p = pow 2.0 e

				if p * 2.0 <= x then
				(
					e += 1.0
					p = pow 2.0 e
				)
				else if p > x then
				(
					e -= 1.0
					p = pow 2.0 e
				)

				e += 126.0
				x /= p / 8388608.0

				s + (e as integer) * 8388608 + (x as integer)
			)
			else
			(
				s + 2139095040 -- Inf
			)
		)
		else -- subnormal as 0
		(
			0
		)
	)
)


struct MFE_XFileWriter
(
xTemplates = "template XSkinMeshHeader {
 <3cf169ce-ff7c-44ab-93c0-f78f62d172e2>
 WORD nMaxSkinWeightsPerVertex;
 WORD nMaxSkinWeightsPerFace;
 WORD nBones;
}

template VertexDuplicationIndices {
 <b8d65549-d7c9-4995-89cf-53a9a8b031e3>
 DWORD nIndices;
 DWORD nOriginalVertices;
 array DWORD indices[nIndices];
}

template SkinWeights {
 <6f0d123b-bad2-4167-a0d0-80224f25fabb>
 STRING transformNodeName;
 DWORD nWeights;
 array DWORD vertexIndices[nWeights];
 array FLOAT weights[nWeights];
 Matrix4x4 matrixOffset;
}

template AnimTicksPerSecond {
 <9e415a43-7ba6-4a73-8743-b73d47e88476>
 DWORD AnimTicksPerSecond;
}

template VertexElement {
 <f752461c-1e23-48f6-b9f8-8350850f336f>
 DWORD Type;
 DWORD Method;
 DWORD Usage;
 DWORD UsageIndex;
}

template DeclData {
 <bf22e553-292c-4781-9fea-62bd554bdd93>
 DWORD nElements;
 array VertexElement Elements[nElements];
 DWORD nDWords;
 array DWORD data[nDWords];
}",

	file = undefined,
	options = undefined,
	nodeUtil = MFE_NodeUtil(),
	selectedNodes = #(),
	requiredNodes = #(),
	idGen = MFE_IDGen(),
	materials = #(),
	indent = "",

	function isSelectedNode nodeObj = 
	(
		findItem selectedNodes nodeObj != 0
	),

	function isRequiredNode nodeObj = 
	(
		MFE_isNodeRegistered requiredNodes nodeObj
	),

	function vectorString v = 
	(
		local s = stringStream ""

		format "%,%,%;" v.x v.y v.z to:s

		s as string
	),

	function quatString q = 
	(
		local s = stringStream ""

		format "%,%,%,%;" q.w q.x q.y q.z to:s

		s as string
	),

	function matrixString tm = 
	(
		local s = stringStream ""

		format "%,%,%,0.0," tm[1][1] tm[1][2] tm[1][3] to:s
		format "%,%,%,0.0," tm[2][1] tm[2][2] tm[2][3] to:s
		format "%,%,%,0.0," tm[3][1] tm[3][2] tm[3][3] to:s
		format "%,%,%,1.0;" tm[4][1] tm[4][2] tm[4][3] to:s

		s as string
	),

	function filenameString fileName = 
	(
		local s = stringStream ""

		for i = 1 to fileName.count do
		(
			format "%" (if fileName[i] == "\\" then "\\\\" else fileName[i]) to:s
		)

		s as string
	),

	function beginSection sectionName objectID = 
	(
		format "\n%%%% {\n" indent sectionName (if objectID == "" then "" else " ") objectID to:file

		indent += " "

		true
	),

	function endSection = 
	(
		indent = substring indent 1 (indent.count - 1)

		format "%}\n" indent to:file
	),

	function writeMaterial matData = 
	(
		if beginSection "Material" (idGen.getID matData matData.name) then
		(
			local kd = Point3 1 1 1
			local ke = Point3 0 0 0
			local ks = Point3 0 0 0
			local ns = 0.0
			local d = 1.0

			if matData.diffuseTexture.fileName == "" then
			(
				kd = (Point3 matData.diffuseColor.r matData.diffuseColor.g matData.diffuseColor.b) / 255.0
				ke = (Point3 matData.emissiveColor.r matData.emissiveColor.g matData.emissiveColor.b) / 255.0
				ks = (Point3 matData.specularColor.r matData.specularColor.g matData.specularColor.b) / 255.0
				ns = matData.glossiness
				d = matData.opacity / 100.0
			)

			format "%%;%;%;%;;\n" indent kd.x kd.y kd.z d to:file
			format "%%;\n" indent ns to:file
			format "%%;%;%;;\n" indent ks.x ks.y ks.z to:file
			format "%%;%;%;;\n" indent ke.x ke.y ke.z to:file

			if matData.diffuseTexture.fileName != "" and (beginSection "TextureFilename" "") then
			(
				format "%\"%\";\n" indent (filenameString (MFE_changeBitmapPath matData.diffuseTexture.fileName options)) to:file

				endSection()
			)

			endSection()
		)
	),

	dataCount = 0,
	dataFormatI = "",
	dataFormatN = "",

	function initFormatString indent numElements elementFormat = 
	(
		dataCount = numElements
		dataFormatI = indent + elementFormat + ",\n"
		dataFormatN = indent + elementFormat + ";\n"
	),

	function getFormatString index = 
	(
		if index < dataCount then dataFormatI else dataFormatN
	),

	function writeMeshNormals md = 
	(
		if beginSection "MeshNormals" "" then
		(
			local normals = md.normals
			local normalFaces = md.normalFaces

			format "%%;\n" indent normals.count to:file

			initFormatString indent normals.count "%;%;%;"

			for i = 1 to normals.count do
			(
				local n = normals[i]

				format (getFormatString i) n.x n.y n.z to:file
			)

			format "%%;\n" indent normalFaces.count to:file

			initFormatString indent normalFaces.count "3;%,%,%;"

			for i = 1 to normalFaces.count do
			(
				local nFace = normalFaces[i]
				local i0 = nFace.x as integer - 1
				local i1 = nFace.y as integer - 1
				local i2 = nFace.z as integer - 1

				format (getFormatString i) i0 i1 i2 to:file
			)

			endSection()
		)
	),

	function writeMeshTextureCoords md = 
	(
		if beginSection "MeshTextureCoords" "" then
		(
			local texCoords = md.texCoordSets[1]

			format "%%;\n" indent texCoords.count to:file

			initFormatString indent texCoords.count "%;%;"

			for i = 1 to texCoords.count do
			(
				local t = texCoords[i]

				format (getFormatString i) t.x t.y to:file
			)

			endSection()
		)
	),

	function writeMeshVertexColors md = 
	(
		if beginSection "MeshVertexColors" "" then
		(
			local colors = md.colors

			format "%%;\n" indent colors.count to:file

			initFormatString indent colors.count "%;%;%;%;%;;"

			for i = 1 to colors.count do
			(
				local c = colors[i]
				local r = c.r / 255.0
				local g = c.g / 255.0
				local b = c.b / 255.0
				local a = c.a / 255.0

				format (getFormatString i) (i - 1) r g b a to:file
			)

			endSection()
		)
	),

	function writeMeshVertexData md = 
	(
		if beginSection "DeclData" "" then
		(
			local hasTangents = md.tangents != undefined
			local numTexCoordSets = if md.texCoordSets.count != 1 then md.texCoordSets.count else 0
			local numVertexComponents = numTexCoordSets + (if hasTangents then 2 else 0)
			local numVertexDWords = 2 * numTexCoordSets + (if hasTangents then 6 else 0)

			format "%%;\n" indent numVertexComponents to:file

			initFormatString indent numVertexComponents "%;%;%;%;"

			for i = 1 to numTexCoordSets do
			(
				local usageIndex = i - 1

				format (getFormatString i) 1 0 5 usageIndex to:file
			)

			for i = numTexCoordSets + 1 to numVertexComponents do
			(
				local usage = if i < numVertexComponents then 6 else 7

				format (getFormatString i) 2 0 usage 0 to:file
			)

			local numVertices = md.positions.count
			local numDWords = numVertexDWords * numVertices

			format "%%;\n" indent numDWords to:file

			initFormatString indent numDWords "%%"

			local tangents = md.tangents
			local bitangents = md.bitangents
			local texCoordSets = md.texCoordSets
			local zero = ""
			local dwordIndex = 1

			for i = 1 to numVertices do
			(
				for j = 1 to numTexCoordSets do
				(
					local t = texCoordSets[j][i]

					for k = 1 to 2 do
					(
						local n = MFE_floatAsInt t[k]
						local tens, units

						if n >= 0 then
						(
							tens = zero
							units = n
						)
						else
						(
							tens = MFE_uintTens n
							units = MFE_uintUnits n
						)

						format (getFormatString dwordIndex) tens units to:file
						dwordIndex += 1
					)
				)

				if hasTangents then
				(
					local g = tangents[i]

					for k = 1 to 3 do
					(
						local n = MFE_floatAsInt g[k]
						local tens, units

						if n >= 0 then
						(
							tens = zero
							units = n
						)
						else
						(
							tens = MFE_uintTens n
							units = MFE_uintUnits n
						)

						format (getFormatString dwordIndex) tens units to:file
						dwordIndex += 1
					)

					local b = bitangents[i]

					for k = 1 to 3 do
					(
						local n = MFE_floatAsInt b[k]
						local tens, units

						if n >= 0 then
						(
							tens = zero
							units = n
						)
						else
						(
							tens = MFE_uintTens n
							units = MFE_uintUnits n
						)

						format (getFormatString dwordIndex) tens units to:file
						dwordIndex += 1
					)
				)
			)

			endSection()
		)
	),

	function writeMeshMaterialList md = 
	(
		if beginSection "MeshMaterialList" "" then
		(
			local submeshIDs = md.submeshIDs

			format "%%;\n" indent md.submeshIDToMDIndex.count to:file
			format "%%;\n" indent submeshIDs.count to:file

			initFormatString indent submeshIDs.count "%"

			for i = 1 to submeshIDs.count do
			(
				local submeshID = submeshIDs[i] - 1

				format (getFormatString i) submeshID to:file
			)

			for i = 1 to md.submeshIDToMDIndex.count do
			(
				local matData = materials[md.submeshIDToMDIndex[i]]

				format "%{ % }\n" indent (idGen.getID matData matData.name) to:file
			)

			endSection()
		)
	),

	function writeVertexDuplicationIndices md = 
	(
		if beginSection "VertexDuplicationIndices" "" then
		(
			local duplications = #()
			local oldIndices = #()

			duplications.count = md.newIndexToOldIndex.count
			oldIndices.count = md.numOriginalVertices

			for newIndex = 1 to md.newIndexToOldIndex.count do
			(
				local oldIndex = md.newIndexToOldIndex[newIndex]

				if oldIndices[oldIndex] == undefined then
				(
					oldIndices[oldIndex] = newIndex
				)

				duplications[newIndex] = oldIndices[oldIndex]
			)

			format "%%;\n" indent duplications.count to:file
			format "%%;\n" indent oldIndices.count to:file

			initFormatString indent duplications.count "%"

			for i = 1 to duplications.count do
			(
				local index = duplications[i] - 1

				format (getFormatString i) index to:file
			)

			endSection()
		)
	),

	function writeSkinData nodeObj md = 
	(
		if beginSection "XSkinMeshHeader" "" then
		(
			format "%%;\n" indent md.maxBonesPerVertex to:file
			format "%%;\n" indent md.maxBonesPerFace to:file
			format "%%;\n" indent md.deformBones.count to:file

			endSection()
		)

		for bd in md.deformBones do
		(
			if beginSection "SkinWeights" "" then
			(
				local boneName = idGen.getID bd.boneObj bd.boneObj.name
				local offsetTM = (nodeUtil.getWorldTM nodeObj) * (inverse (nodeUtil.getWorldTM bd.boneObj))

				format "%\"%\";\n" indent boneName to:file
				format "%%;\n" indent bd.indices.count to:file

				initFormatString indent bd.indices.count "%"

				for j = 1 to bd.indices.count do
				(
					local index = bd.indices[j] - 1

					format (getFormatString j) index to:file
				)

				initFormatString indent bd.weights.count "%"

				for j = 1 to bd.weights.count do
				(
					local weight = bd.weights[j]

					format (getFormatString j) weight to:file
				)

				format "%%;\n" indent (matrixString offsetTM) to:file

				endSection()
			)
		)
	),

	function writeMesh nodeObj insideFrame:true = 
	(
		if beginSection "Mesh" (if insideFrame then "" else idGen.getID nodeObj nodeObj.name) then
		(
			local md = MFE_MeshData()
			local vc = MFE_VertexComponents()
			local tm = (if insideFrame then inverse nodeObj.transform else nodeUtil.exportRotTM) * nodeUtil.exportScaleTM

			vc.enableNormals = options.enableNormals
			vc.enableTangents = options.enableTangents
			vc.enableColors = options.enableColors
			vc.maxTexCoordSets = if options.maxTexCoordSets <= 8 then options.maxTexCoordSets else 8

			md.init nodeObj (MFE_registerNodeMaterials materials nodeObj) vc meshTM:tm separateVertexComponents:false bonesPerVertexLimit:options.maxBonesPerVertex

			if nodeObj.transform.determinantSign < 0 then
			(
				if insideFrame then
				(
					if options.flipFlippedFaces then md.flipFaces()
				)
				else
				(
					if options.flipFlippedFaces then md.flipFaces()
					md.flipNormals()
				)
			)

			if nodeUtil.convertCoordSys then
			(
				md.flipFaces()
				md.flipZCoords()
			)

			md.flipVCoords()

			local positions = md.positions
			local faces = md.faces

			format "%%;\n" indent positions.count to:file

			initFormatString indent positions.count "%;%;%;"

			for i = 1 to positions.count do
			(
				local p = positions[i]

				format (getFormatString i) p.x p.y p.z to:file
			)

			format "%%;\n" indent faces.count to:file

			initFormatString indent faces.count "3;%,%,%;"

			for i = 1 to faces.count do
			(
				local face = faces[i]
				local i0 = face.x as integer - 1
				local i1 = face.y as integer - 1
				local i2 = face.z as integer - 1

				format (getFormatString i) i0 i1 i2 to:file
			)

			if md.normals != undefined then
			(
				writeMeshNormals md
			)

			if md.texCoordSets.count == 1 then
			(
				writeMeshTextureCoords md
			)

			if md.colors != undefined then
			(
				writeMeshVertexColors md
			)

			if md.texCoordSets.count >= 2 or md.tangents != undefined then
			(
				writeMeshVertexData md
			)

			writeMeshMaterialList md

			writeVertexDuplicationIndices md

			if insideFrame and md.deformBones.count != 0 then
			(
				writeSkinData nodeObj md
			)

			endSection()
		)
	),

	function writeFrameR nodeObj = 
	(
		if beginSection "Frame" (idGen.getID nodeObj nodeObj.name) then
		(
			if beginSection "FrameTransformMatrix" "" then
			(
				format "%%;\n" indent (matrixString (nodeUtil.getLocalTM nodeObj)) to:file

				endSection()
			)

			if (isSelectedNode nodeObj) and (MFE_isVisibleGeomNode nodeObj) then
			(
				writeMesh nodeObj insideFrame:true
			)

			for childObj in nodeObj.children where isRequiredNode childObj do
			(
				writeFrameR childObj
			)

			endSection()
		)
	),

	function writeAnimationTrack keyValues keyTimes keyType = 
	(
		if beginSection "AnimationKey" "" then
		(
			local numKeys = keyValues.count

			format "%%;\n" indent keyType to:file
			format "%%;\n" indent numKeys to:file

			if keyType == 0 then
			(
				initFormatString indent numKeys "%;4;%;"

				for i = 1 to numKeys do
				(
					format (getFormatString i) keyTimes[i] (quatString keyValues[i]) to:file
				)
			)
			else if keyType == 1 or keyType == 2 then
			(
				initFormatString indent numKeys "%;3;%;"

				for i = 1 to numKeys do
				(
					format (getFormatString i) keyTimes[i] (vectorString keyValues[i]) to:file
				)
			)
			else
			(
				initFormatString indent numKeys "%;16;%;"

				for i = 1 to numKeys do
				(
					format (getFormatString i) keyTimes[i] (matrixString keyValues[i]) to:file
				)
			)

			endSection()
		)
	),

	function writeAnimationR nodeObj animStart animEnd samplingRate = 
	(
		if beginSection "Animation" "" then
		(
			local keyValues = #()
			local keyTimes = #()

			nodeUtil.sampleNodeAnimation keyValues keyTimes nodeObj animStart animEnd samplingRate

			if options.separateTransforms then
			(
				local rotKeyValues = #()
				local rotKeyTimes = #()
				local scaleKeyValues = #()
				local scaleKeyTimes = #()
				local posKeyValues = #()
				local posKeyTimes = #()

				MFE_getRotKeys rotKeyValues rotKeyTimes keyValues keyTimes
				MFE_getScaleKeys scaleKeyValues scaleKeyTimes keyValues keyTimes
				MFE_getPosKeys posKeyValues posKeyTimes keyValues keyTimes

				if options.reduceFrames then
				(
					MFE_reduceKeys rotKeyValues rotKeyTimes
					MFE_reduceKeys scaleKeyValues scaleKeyTimes
					MFE_reduceKeys posKeyValues posKeyTimes
				)

				writeAnimationTrack rotKeyValues rotKeyTimes 0
				writeAnimationTrack scaleKeyValues scaleKeyTimes 1
				writeAnimationTrack posKeyValues posKeyTimes 2
			)
			else
			(
				if options.reduceFrames then
				(
					MFE_reduceKeys keyValues keyTimes
				)

				writeAnimationTrack keyValues keyTimes 4
			)

			format "%{ % }\n" indent (idGen.getID nodeObj nodeObj.name) to:file

			endSection()
		)

		for childObj in nodeObj.children where isRequiredNode childObj do
		(
			writeAnimationR childObj animStart animEnd samplingRate
		)
	),

	function writeAnimationSet animName animStart animEnd samplingRate = 
	(
		if beginSection "AnimationSet" (idGen.validNameFromString animName) then
		(
			writeAnimationR rootNode animStart animEnd samplingRate

			endSection()
		)
	),

	function write nodes _file _options = 
	(
		file = _file
		options = _options
		nodeUtil.init options rightHanded:false

		selectedNodes = nodes
		MFE_registerNodePaths requiredNodes selectedNodes includeBones:(options.fileVariant != MFE_FileVariant_StaticMesh)

		if options.fileVariant != MFE_FileVariant_AnimationOnly then
		(
			for nodeObj in selectedNodes where MFE_isVisibleGeomNode nodeObj do
			(
				MFE_registerNodeMaterials materials nodeObj
			)
		)

		format "xof 0303txt 0032\n" to:file
		format "%\n" xTemplates to:file

		for matData in materials do
		(
			writeMaterial matData
		)

		if options.fileVariant == MFE_FileVariant_StaticMesh then
		(
			for nodeObj in selectedNodes where MFE_isVisibleGeomNode nodeObj do
			(
				writeMesh nodeObj insideFrame:false
			)
		)
		else
		(
			if beginSection "AnimTicksPerSecond" "" then
			(
				format "%4800;\n" indent to:file

				endSection()
			)

			writeFrameR rootNode
		)

		if options.fileVariant == MFE_FileVariant_AnimatedMesh or options.fileVariant == MFE_FileVariant_AnimationOnly then
		(
			local animations = options.animations

			for i = 1 to animations.count by 4 do
			(
				local animName = animations[i]
				local startFrame = 0f
				local endFrame = 0f
				local samplingRate

				startFrame.frame = animations[i + 1] as integer
				endFrame.frame = animations[i + 2] as integer
				samplingRate = animations[i + 3] as integer

				writeAnimationSet animName startFrame endFrame samplingRate
			)
		)
	)
)


function MFE_writeXFile nodes fileName file options = 
(
	local x = MFE_XFileWriter()

	x.write nodes file options
)


-- MFE_DaeFileWriter.ms


struct MFE_DaeMesh
(
	meshName,
	submeshIDToMDIndex,
	mapChannels
)


struct MFE_DaeSkin
(
	meshName,
	skinName,
	bindShapeMatrix,
	joints,
	weights,
	invBindMatrices,
	vertexWeights,
	skeletonNodes,
	rootBoneNodes
)


struct MFE_DaeAnimation
(
	animName,
	startFrame,
	endFrame,
	samplingRate
)


struct MFE_DaeFileWriter
(
	file = undefined,
	options = undefined,
	nodeUtil = MFE_NodeUtil(),
	selectedNodes = #(),
	requiredNodes = #(),
	imageNames = MFE_IDGen(),
	materialNames = MFE_IDGen(),
	nodeNames = MFE_IDGen(),
	animationNames = MFE_IDGen(),
	materials = #(),
	meshes = #(),
	skins = #(),
	indent = "",

	function isSelectedNode nodeObj = 
	(
		findItem selectedNodes nodeObj != 0
	),

	function isRequiredNode nodeObj = 
	(
		MFE_isNodeRegistered requiredNodes nodeObj
	),

	function isSkeletonNode nodeObj = 
	(
		local r = false

		for ds in skins where not r do
		(
			r = findItem ds.skeletonNodes nodeObj != 0
		)

		r
	),

	function uniqueImageName fileName = 
	(
		imageNames.getID fileName (getFilenameFile fileName)
	),

	function uniqueMaterialName obj = 
	(
		materialNames.getID obj obj.name
	),

	function uniqueNodeName obj = 
	(
		nodeNames.getID obj obj.name
	),

	function uniqueAnimationName animNamePos = 
	(
		animationNames.getID animNamePos options.animations[animNamePos]
	),

	function colorString c = 
	(
		local s = stringStream ""

		format "% % % %" (c.r / 255.0) (c.g / 255.0) (c.b / 255.0) (c.a / 255.0) to:s

		s as string
	),

	function matrixString tm = 
	(
		local s = stringStream ""

		format "% % % % " tm[1][1] tm[2][1] tm[3][1] tm[4][1] to:s
		format "% % % % " tm[1][2] tm[2][2] tm[3][2] tm[4][2] to:s
		format "% % % % " tm[1][3] tm[2][3] tm[3][3] tm[4][3] to:s
		format "0.0 0.0 0.0 1.0" to:s

		s as string
	),

	function fileNameString fileName = 
	(
		local s = stringStream ""

		for i = 1 to fileName.count do
		(
			format "%" (if fileName[i] == "\\" then "/" else fileName[i]) to:s
		)

		s as string
	),

	function beginElement elementName names:undefined values:undefined = 
	(
		format "\n%<%" indent elementName to:file

		if names != undefined then
		(
			for i = 1 to names.count do
			(
				format " %=\"%\"" names[i] values[i] to:file
			)
		)

		format ">" to:file

		indent += "  "

		true
	),

	function leafElement elementName names:undefined values:undefined text:undefined = 
	(
		format "\n%<%" indent elementName to:file

		if names != undefined then
		(
			for i = 1 to names.count do
			(
				format " %=\"%\"" names[i] values[i] to:file
			)
		)

		if text != undefined then
		(
			format ">%</%>" text elementName to:file
		)
		else
		(
			format "/>" to:file
		)
	),

	function endElement elementName = 
	(
		indent = substring indent 1 (indent.count - 2)

		format "\n%</%>" indent elementName to:file
	),

	function writeAsset = 
	(
		if beginElement "asset" then
		(
			if beginElement "contributor" then
			(
				leafElement "authoring_tool" text:"Multi-Format Exporter"

				endELement "contributor"
			)

			local unit = "meter"
			local meter = 1.0

			case options.exportUnits of
			(
				MFE_Units_Inches:
				(
					unit = "inch"
					meter = 0.0254
				)
				MFE_Units_Feet:
				(
					unit = "feet"
					meter = 0.3048
				)
				MFE_Units_Miles:
				(
					unit = "mile"
					meter = 1609.344
				)
				MFE_Units_Millimeters:
				(
					unit = "millimeter"
					meter = 0.001
				)
				MFE_Units_Centimeters:
				(
					unit = "centimeter"
					meter = 0.01
				)
				MFE_Units_Decimeters:
				(
					unit = "decimeter"
					meter = 0.1
				)
				MFE_Units_Meters:
				(
					unit = "meter"
					meter = 1.0
				)
				MFE_Units_Kilometers:
				(
					unit = "kilometer"
					meter = 1000.0
				)
			)

			leafElement "unit" names:#("name", "meter") values:#(unit, meter)
			leafElement "up_axis" text:(if options.exportYUp then "Y_UP" else "Z_UP")

			endELement "asset"
		)
	),

	function writeImage imageName fileName = 
	(
		if beginElement "image" names:#("id") values:#(imageName + "-image") then
		(
			leafElement "init_from" text:(fileNameString (MFE_changeBitmapPath fileName options))

			endELement "image"
		)
	),

	function writeImages = 
	(
		if beginElement "library_images" then
		(
			for matData in materials do
			(
				if matData.diffuseTexture.fileName != "" then uniqueImageName matData.diffuseTexture.fileName
				if matData.emissiveTexture.fileName != "" then uniqueImageName matData.emissiveTexture.fileName
				if matData.specularTexture.fileName != "" then uniqueImageName matData.specularTexture.fileName
				if matData.bumpTexture.fileName != "" then uniqueImageName matData.bumpTexture.fileName
			)

			for i = 1 to imageNames.ids.count do
			(
				writeImage imageNames.ids[i] imageNames.values[i]
			)

			endELement "library_images"
		)
	),

	function writeTextureSampler textureFileName = 
	(
		local imageName = uniqueImageName textureFileName

		if beginElement "newparam" names:#("sid") values:#(imageName + "-surface") then
		(
			if beginElement "surface" names:#("type") values:#("2D") then
			(
				leafElement "init_from" text:(imageName + "-image")

				endELement "surface"
			)

			endELement "newparam"
		)

		if beginElement "newparam" names:#("sid") values:#(imageName + "-sampler") then
		(
			if beginElement "sampler2D" then
			(
				leafElement "source" text:(imageName + "-surface")

				endELement "sampler2D"
			)

			endELement "newparam"
		)
	),

	function writeColorOrTexture colorName colorValue textureFileName = 
	(
		if beginElement colorName then
		(
			if textureFileName == "" then
			(
				leafElement "color" text:(colorString colorValue)
			)
			else
			(
				leafElement "texture" names:#("texture", "texcoord") values:#((uniqueImageName textureFileName) + "-sampler", "CHANNEL1")
			)

			endELement colorName
		)
	),

	function writeFloat floatName floatValue = 
	(
		if beginElement floatName then
		(
			leafElement "float" text:(floatValue)

			endELement floatName
		)
	),

	function writeTransparent opacityValue = 
	(
		if beginElement "transparent" names:#("opaque") values:#(if opacityValue == 1.0 then "RGB_ZERO" else "A_ONE") then
		(
			leafElement "color" text:(colorString black)

			endELement "transparent"
		)
	),

	function writeEffect materialName matData = 
	(
		if beginElement "effect" names:#("id") values:#(materialName + "-effect") then
		(
			if beginElement "profile_COMMON" then
			(
				if beginElement "technique" names:#("sid") values:#("common") then
				(
					if matData.emissiveTexture.fileName != "" then
					(
						writeTextureSampler matData.emissiveTexture.fileName
					)

					if matData.diffuseTexture.fileName != "" then
					(
						writeTextureSampler matData.diffuseTexture.fileName
					)

					if matData.specularTexture.fileName != "" then
					(
						writeTextureSampler matData.specularTexture.fileName
					)

					if matData.bumpTexture.fileName != "" then
					(
						writeTextureSampler matData.bumpTexture.fileName
					)

					if beginElement "phong" then
					(
						writeColorOrTexture "emission" matData.emissiveColor matData.emissiveTexture.fileName
						writeColorOrTexture "ambient" matData.ambientColor ""
						writeColorOrTexture "diffuse" matData.diffuseColor matData.diffuseTexture.fileName
						writeColorOrTexture "specular" matData.specularColor matData.specularTexture.fileName
						writeFloat "shininess" matData.glossiness

						if matData.opacity != 100 then
						(
							writeTransparent (matData.opacity / 100.0)
							writeFloat "transparency" (matData.opacity / 100.0)
						)

						writeFloat "index_of_refraction" 1.0

						endELement "phong"
					)

					if beginElement "extra" then
					(
						if matData.bumpTexture.fileName != "" and beginElement "technique" names:#("profile") values:#("FCOLLADA") then
						(
							if beginElement "bump" names:#("bumptype") values:#("NORMALMAP") then
							(
								leafElement "texture" names:#("texture", "texcoord") values:#((uniqueImageName matData.bumpTexture.fileName) + "-sampler", "CHANNEL1")

								endELement "bump"
							)

							endELement "technique"
						)

						if beginElement "technique" names:#("profile") values:#("GOOGLEEARTH") then
						(
							leafElement "double_sided" text:(if matData.twoSided then 1 else 0)

							endELement "technique"
						)

						endELement "extra"
					)

					endELement "technique"
				)

				endELement "profile_COMMON"
			)

			endELement "effect"
		)
	),

	function writeEffects = 
	(
		if beginElement "library_effects" then
		(
			for matData in materials do
			(
				writeEffect (uniqueMaterialName matData) matData
			)

			endELement "library_effects"
		)
	),

	function writeMaterial materialName = 
	(
		if beginElement "material" names:#("id", "name") values:#(materialName + "-material", materialName) then
		(
			leafElement "instance_effect" names:#("url") values:#("#" + materialName + "-effect")

			endELement "material"
		)
	),

	function writeMaterials = 
	(
		if beginElement "library_materials" then
		(
			for matData in materials do
			(
				writeMaterial (uniqueMaterialName matData)
			)

			endELement "library_materials"
		)
	),

	function registerMesh nodeObj md = 
	(
		local dm = MFE_DaeMesh()

		dm.meshName = (uniqueNodeName nodeObj) + "-mesh"
		dm.submeshIDToMDIndex = md.submeshIDToMDIndex
		dm.mapChannels = md.mapChannels

		append meshes dm
	),

	function findMesh nodeObj = 
	(
		local meshName = (uniqueNodeName nodeObj) + "-mesh"
		local dm = undefined

		for i = 1 to meshes.count where dm == undefined do
		(
			if meshes[i].meshName == meshName then dm = meshes[i]
		)

		dm
	),

	function registerSkin nodeObj md = 
	(
		if options.fileVariant != MFE_FileVariant_StaticMesh and md.deformBones.count != 0 then
		(
			local wSet = MFE_ElementSet()

			wSet.init md.positions.count

			local ds = MFE_DaeSkin()

			ds.meshName = (uniqueNodeName nodeObj) + "-mesh"
			ds.skinName = (uniqueNodeName nodeObj) + "-skin"
			ds.bindShapeMatrix = nodeUtil.getWorldTM nodeObj
			ds.joints = #()
			ds.weights = wSet.elements
			ds.invBindMatrices = #()
			ds.vertexWeights = #()
			ds.vertexWeights.count = md.positions.count
			ds.skeletonNodes = #()
			ds.rootBoneNodes = md.rootBoneNodes

			for i = 1 to md.positions.count do
			(
				ds.vertexWeights[i] = #()
			)

			for bd in md.deformBones do
			(
				local boneName = uniqueNodeName bd.boneObj
				local offsetTM = inverse (nodeUtil.getWorldTM bd.boneObj)

				append ds.joints boneName
				append ds.invBindMatrices offsetTM

				local jointIndex = ds.joints.count
				local numWeights = bd.weights.count

				for i = 1 to numWeights do
				(
					local vertexIndex = bd.indices[i]
					local weightIndex = wSet.insert bd.weights[i]

					append ds.vertexWeights[vertexIndex] (Point2 jointIndex weightIndex)
				)
			)

			for vw in ds.vertexWeights do
			(
				if vw.count == 0 then
				(
					local jointIndex = 0
					local weightIndex = wSet.insert 1.0

					append vw (Point2 jointIndex weightIndex)
				)
			)

			join ds.skeletonNodes md.allBoneNodes

			for boneObj in md.allBoneNodes do
			(
				local p = boneObj
				local r = boneObj
				local s = #()

				while p.parent != undefined and r == boneObj do
				(
					p = p.parent

					for t in md.rootBoneNodes where p == t do
					(
						r = t

						for n in s where findItem ds.skeletonNodes n == 0 do
						(
							append ds.skeletonNodes n
						)
					)

					append s p
				)
			)

			append skins ds
		)
	),

	function findSkin nodeObj = 
	(
		local skinName = (uniqueNodeName nodeObj) + "-skin"
		local ds = undefined

		for i = 1 to skins.count where dm == undefined do
		(
			if skins[i].skinName == skinName then ds = skins[i]
		)

		ds
	),

	function writeFloatArray sourceName values accessor = 
	(
		if beginElement "source" names:#("id") values:#(sourceName) then
		(
			local stride

			if accessor == "WEIGHT" or accessor == "TIME" then
			(
				stride = 1
			)
			else if accessor == "ST" then
			(
				stride = 2
			)
			else if accessor == "XYZ" or accessor == "RGB" then
			(
				stride = 3
			)
			else if accessor == "TRANSFORM" then
			(
				stride = 16
			)

			if beginElement "float_array" names:#("id", "count") values:#(sourceName + "-array", values.count * stride) then
			(
				if accessor == "WEIGHT" then
				(
					local f = "\n" + indent + "%"

					for i = 1 to values.count do
					(
						format f values[i] to:file
					)
				)
				else if accessor == "TIME" then
				(
					local f = "\n" + indent + "%"

					for i = 1 to values.count do
					(
						format f (values[i] / 4800.0) to:file
					)
				)
				else if accessor == "ST" then
				(
					local f = "\n" + indent + "% %"

					for i = 1 to values.count do
					(
						format f values[i].x values[i].y to:file
					)
				)
				else if accessor == "XYZ" then
				(
					local f = "\n" + indent + "% % %"

					for i = 1 to values.count do
					(
						format f values[i].x values[i].y values[i].z to:file
					)
				)
				else if accessor == "RGB" then
				(
					local f = "\n" + indent + "% % %"

					for i = 1 to values.count do
					(
						format f (values[i].r / 255.0) (values[i].g / 255.0) (values[i].b / 255.0) to:file
					)
				)
				else if accessor == "TRANSFORM" then
				(
					local f = "\n" + indent + "% % % % % % % % % % % % 0.0 0.0 0.0 1.0"

					for i = 1 to values.count do
					(
						local tm = values[i]

						format f tm[1][1] tm[2][1] tm[3][1] tm[4][1] tm[1][2] tm[2][2] tm[3][2] tm[4][2] tm[1][3] tm[2][3] tm[3][3] tm[4][3] to:file
					)
				)

				endElement "float_array"
			)

			if beginElement "technique_common" then
			(
				if beginElement "accessor" names:#("source", "count", "stride") values:#("#" + sourceName + "-array", values.count, stride) then
				(
					if accessor == "WEIGHT" or accessor == "TIME" then
					(
						leafElement "param" names:#("name", "type") values:#(accessor, "float")
					)
					else if accessor == "ST" then
					(
						leafElement "param" names:#("name", "type") values:#(accessor[1], "float")
						leafElement "param" names:#("name", "type") values:#(accessor[2], "float")
					)
					else if accessor == "XYZ" or accessor == "RGB" then
					(
						leafElement "param" names:#("name", "type") values:#(accessor[1], "float")
						leafElement "param" names:#("name", "type") values:#(accessor[2], "float")
						leafElement "param" names:#("name", "type") values:#(accessor[3], "float")
					)
					else if accessor == "TRANSFORM" then
					(
						leafElement "param" names:#("name", "type") values:#(accessor, "float4x4")
					)

					endElement "accessor"
				)

				endElement "technique_common"
			)

			endElement "source"
		)
	),

	function writeNameArray sourceName values accessor = 
	(
		if beginElement "source" names:#("id") values:#(sourceName) then
		(
			if beginElement "Name_array" names:#("id", "count") values:#(sourceName + "-array", values.count) then
			(
				local f = "\n" + indent + "%"

				for i = 1 to values.count do
				(
					format f values[i] to:file
				)

				endElement "Name_array"
			)

			if beginElement "technique_common" then
			(
				if beginElement "accessor" names:#("source", "count", "stride") values:#("#" + sourceName + "-array", values.count, 1) then
				(
					leafElement "param" names:#("name", "type") values:#(accessor, "Name")

					endElement "accessor"
				)

				endElement "technique_common"
			)

			endElement "source"
		)
	),

	function writeMeshFaces meshName md submeshID = 
	(
		local firstFaceIndex = md.submeshIDGroups[submeshID].x as integer
		local lastFaceIndex = md.submeshIDGroups[submeshID].y as integer
		local numFaces = lastFaceIndex - firstFaceIndex + 1

		if beginElement "triangles" names:#("count", "material") values:#(numFaces, "submesh-" + (submeshID - 1) as string) then
		(
			local faces = md.faces
			local normalFaces = md.normalFaces
			local tangentFaces = md.tangentFaces
			local bitangentFaces = md.bitangentFaces
			local colorFaces = md.colorFaces
			local numTexCoordSets = md.texCoordSets.count

			leafElement "input" names:#("semantic", "source", "offset") values:#("VERTEX", "#" + meshName + "-vertices", 0)
			local offset = 1

			if normalFaces != undefined then
			(
				leafElement "input" names:#("semantic", "source", "offset") values:#("NORMAL", "#" + meshName + "-normals", offset)
				offset += 1
			)

			if tangentFaces != undefined then
			(
				leafElement "input" names:#("semantic", "source", "offset") values:#("TEXTANGENT", "#" + meshName + "-tangents", offset)
				offset += 1
			)

			if bitangentFaces != undefined then
			(
				leafElement "input" names:#("semantic", "source", "offset") values:#("TEXBINORMAL", "#" + meshName + "-bitangents", offset)
				offset += 1
			)

			if colorFaces != undefined then
			(
				leafElement "input" names:#("semantic", "source", "offset") values:#("COLOR", "#" + meshName + "-colors", offset)
				offset += 1
			)

			for setIndex = 1 to numTexCoordSets do
			(
				leafElement "input" names:#("semantic", "source", "offset", "set") values:#("TEXCOORD", "#" + meshName + "-texcoords-" + (setIndex - 1) as string, offset, setIndex - 1)
				offset += 1
			)

			if beginElement "p" then
			(
				local l = "\n" + indent + "%"
				local f = "  %"
				local s = " %"

 				for i = firstFaceIndex to lastFaceIndex do
				(
					format l (faces[i].x as integer - 1) to:file
					if normalFaces != undefined then format s (normalFaces[i].x as integer - 1) to:file
					if tangentFaces != undefined then format s (tangentFaces[i].x as integer - 1) to:file
					if bitangentFaces != undefined then format s (bitangentFaces[i].x as integer - 1) to:file
					if colorFaces != undefined then format s (colorFaces[i].x as integer - 1) to:file
					for texCoordFaces in md.texCoordSetFaces do format s (texCoordFaces[i].x as integer - 1) to:file

					format f (faces[i].y as integer - 1) to:file
					if normalFaces != undefined then format s (normalFaces[i].y as integer - 1) to:file
					if tangentFaces != undefined then format s (tangentFaces[i].y as integer - 1) to:file
					if bitangentFaces != undefined then format s (bitangentFaces[i].y as integer - 1) to:file
					if colorFaces != undefined then format s (colorFaces[i].y as integer - 1) to:file
					for texCoordFaces in md.texCoordSetFaces do format s (texCoordFaces[i].y as integer - 1) to:file

					format f (faces[i].z as integer - 1) to:file
					if normalFaces != undefined then format s (normalFaces[i].z as integer - 1) to:file
					if tangentFaces != undefined then format s (tangentFaces[i].z as integer - 1) to:file
					if bitangentFaces != undefined then format s (bitangentFaces[i].z as integer - 1) to:file
					if colorFaces != undefined then format s (colorFaces[i].z as integer - 1) to:file
					for texCoordFaces in md.texCoordSetFaces do format s (texCoordFaces[i].z as integer - 1) to:file
				)

				endElement "p"
			)

			endElement "triangles"
		)
	),

	function writeMesh meshName nodeObj = 
	(
		if beginElement "geometry" names:#("id") values:#(meshName) then
		(
			local md = MFE_MeshData()
			local vc = MFE_VertexComponents()
			local tm = (inverse nodeObj.transform) * nodeUtil.exportScaleTM

			vc.enableNormals = options.enableNormals
			vc.enableTangents = options.enableTangents
			vc.enableColors = options.enableColors
			vc.maxTexCoordSets = options.maxTexCoordSets

			md.init nodeObj (MFE_registerNodeMaterials materials nodeObj) vc meshTM:tm bonesPerVertexLimit:options.maxBonesPerVertex

			if nodeObj.transform.determinantSign < 0 then
			(
				if options.flipFlippedFaces then md.flipFaces()
			)

			if nodeUtil.convertCoordSys then
			(
				md.flipFaces()
				md.flipZCoords()
			)

			registerMesh nodeObj md
			registerSkin nodeObj md

			if beginElement "mesh" then
			(
				writeFloatArray (meshName + "-positions") md.positions "XYZ"

				if md.normals != undefined then
				(
					writeFloatArray (meshName + "-normals") md.normals "XYZ"
				)

				if md.tangents != undefined then
				(
					writeFloatArray (meshName + "-tangents") md.tangents "XYZ"
				)

				if md.bitangents != undefined then
				(
					writeFloatArray (meshName + "-bitangents") md.bitangents "XYZ"
				)

				if md.colors != undefined then
				(
					writeFloatArray (meshName + "-colors") md.colors "RGB"
				)

				for setIndex = 1 to md.texCoordSets.count do
				(
					writeFloatArray (meshName + "-texcoords-" + (setIndex - 1) as string) md.texCoordSets[setIndex] "ST"
				)

				if beginElement "vertices" names:#("id") values:#(meshName + "-vertices") then
				(
					leafElement "input" names:#("semantic", "source") values:#("POSITION", "#" + meshName + "-positions")

					endElement "vertices"
				)

				for submeshID = 1 to md.submeshIDGroups.count do
				(
					writeMeshFaces meshName md submeshID
				)

				endElement "mesh"
			)

			endElement "geometry"
		)
	),

	function writeGeometries = 
	(
		if beginElement "library_geometries" then
		(
			if options.fileVariant != MFE_FileVariant_AnimationOnly then
			(
				for nodeObj in selectedNodes where MFE_isVisibleGeomNode nodeObj do
				(
					writeMesh ((uniqueNodeName nodeObj) + "-mesh") nodeObj
				)
			)

			endELement "library_geometries"
		)
	),

	function writeSkinVertexWeights ds = 
	(
		if beginElement "vertex_weights" names:#("count") values:#(ds.vertexWeights.count) then
		(
			leafElement "input" names:#("semantic", "source", "offset") values:#("JOINT", "#" + ds.skinName + "-joints", 0)
			leafElement "input" names:#("semantic", "source", "offset") values:#("WEIGHT", "#" + ds.skinName + "-weights", 1)

			if beginElement "vcount" then
			(
				local f = "\n" + indent + "%"

				for vw in ds.vertexWeights do
				(
					format f vw.count to:file
				)

				endElement "vcount"
			)

			if beginElement "v" then
			(
				local l = "\n" + indent + "% %"
				local s = " % %"

				for vw in ds.vertexWeights do
				(
					local f = l

					for i = 1 to vw.count do
					(
						local jointIndex = (vw[i].x as integer) - 1
						local weightIndex = (vw[i].y as integer) - 1

						format f jointIndex weightIndex to:file

						f = s
					)
				)

				endElement "v"
			)

			endElement "vertex_weights"
		)
	),

	function writeSkin ds = 
	(
		if beginElement "controller" names:#("id") values:#(ds.skinName) then
		(
			if beginElement "skin" names:#("source") values:#("#" + ds.meshName) then
			(
				leafElement "bind_shape_matrix" text:(matrixString ds.bindShapeMatrix)

				writeNameArray (ds.skinName + "-joints") ds.joints "JOINT"
				writeFloatArray (ds.skinName + "-bind_poses") ds.invBindMatrices "TRANSFORM"
				writeFloatArray (ds.skinName + "-weights") ds.weights "WEIGHT"

				if beginElement "joints" then
				(
					leafElement "input" names:#("semantic", "source") values:#("JOINT", "#" + ds.skinName + "-joints")
					leafElement "input" names:#("semantic", "source") values:#("INV_BIND_MATRIX", "#" + ds.skinName + "-bind_poses")

					endElement "joints"
				)

				writeSkinVertexWeights ds

				endElement "skin"
			)

			endElement "controller"
		)
	),

	function writeControllers = 
	(
		if beginElement "library_controllers" then
		(
			for sd in skins do
			(
				writeSkin sd
			)

			endELement "library_controllers"
		)
	),

	function bindMaterial dm = 
	(
		if beginElement "bind_material" then
		(
			if beginElement "technique_common" then
			(
				for submeshID = 1 to dm.submeshIDToMDIndex.count do
				(
					local materialName = uniqueMaterialName materials[dm.submeshIDToMDIndex[submeshID]]

					leafElement "instance_material" names:#("symbol", "target") values:#("submesh-" + (submeshID - 1) as string, "#" + materialName + "-material")
				)

				endElement "technique_common"
			)

			endElement "bind_material"
		)
	),

	function writeNodeR nodeObj = 
	(
		local nodeName = uniqueNodeName nodeObj
		local nodeType = if isSkeletonNode nodeObj then  "JOINT" else "NODE"

		if beginElement "node" names:#("id", "sid", "name", "type") values:#(nodeName, nodeName, nodeName, nodeType) then
		(
			leafElement "matrix" names:#("sid") values:#("transform") text:(matrixString (nodeUtil.getLocalTM nodeObj))

			if (isSelectedNode nodeObj) and (MFE_isVisibleGeomNode nodeObj) then
			(
				local dm = findMesh nodeObj
				local ds = findSkin nodeObj

				if ds == undefined and dm != undefined then
				(
					if beginElement "instance_geometry" names:#("url") values:#("#" + dm.meshName) then
					(
						bindMaterial dm

						endElement "instance_geometry"
					)
				)

				if ds != undefined and dm != undefined then
				(
					if beginElement "instance_controller" names:#("url") values:#("#" + ds.skinName) then
					(
						for boneObj in ds.rootBoneNodes do
						(
							leafElement "skeleton" text:("#" + (uniqueNodeName boneObj))
						)

						bindMaterial dm

						endElement "instance_controller"
					)
				)
			)

			for childObj in nodeObj.children where isRequiredNode childObj do
			(
				writeNodeR childObj
			)

			endElement "node"
		)
	),

	function writeVisualScenes = 
	(
		if beginElement "library_visual_scenes" then
		(
			local sceneName = uniqueNodeName rootNode

			if beginElement "visual_scene" names:#("id", "name") values:#(sceneName, sceneName) then
			(
				for childObj in rootNode.children where isRequiredNode childObj do
				(
					writeNodeR childObj
				)

				if beginElement "extra" then
				(
					local samplingRate

					if options.animations.count != 0 then
					(
						local animNamePos = 1

						samplingRate = options.animations[animNamePos + 3] as integer
					)
					else
					(
						samplingRate = frameRate
					)

					if beginElement "technique" names:#("profile") values:#("MAX3D") then
					(
						leafElement "frame_rate" text:samplingRate

						endELement "technique"
					)

					endELement "extra"
				)

				endELement "visual_scene"
			)

			endELement "library_visual_scenes"
		)
	),

	function writeAnimationTrack animName trackName targetName keyValues keyTimes = 
	(
		if beginElement "animation" names:#("id", "name") values:#(trackName, animName) then
		(
			local linear = "LINEAR"
			local interp = for v in keyValues collect linear
			local inputID = trackName + "-input"
			local outputID = trackName + "-output"
			local interpID = trackName + "-interpolation"
			local samplerID = trackName + "-sampler"

			writeFloatArray inputID keyTimes "TIME"
			writeFloatArray outputID keyValues "TRANSFORM"
			writeNameArray interpID interp "INTERPOLATION"

			if beginElement "sampler" names:#("id") values:#(samplerID) then
			(
				leafElement "input" names:#("semantic", "source") values:#("INPUT", "#" + inputID)
				leafElement "input" names:#("semantic", "source") values:#("OUTPUT", "#" + outputID)
				leafElement "input" names:#("semantic", "source") values:#("INTERPOLATION", "#" + interpID)

				endELement "sampler"
			)

			leafElement "channel" names:#("source", "target") values:#("#" + samplerID, targetName)

			endELement "animation"
		)
	),

	function writeAnimationR nodeObj anim = 
	(
		local keyValues = #()
		local keyTimes = #()

		nodeUtil.sampleNodeAnimation keyValues keyTimes nodeObj anim.startFrame anim.endFrame anim.samplingRate

		if options.reduceFrames then
		(
			MFE_reduceKeys keyValues keyTimes
		)

		local nodeName = uniqueNodeName nodeObj
		local trackName = anim.animName + "-" + nodeName + "-transform"
		local targetName = nodeName + "/transform"

		writeAnimationTrack anim.animName trackName targetName keyValues keyTimes

		for childObj in nodeObj.children where isRequiredNode childObj do
		(
			writeAnimationR childObj anim
		)
	),

	function writeAnimationSet anim = 
	(
		if beginElement "animation" names:#("id", "name") values:#(anim.animName + "-anim", anim.animName) then
		(
			for childObj in rootNode.children where isRequiredNode childObj do
			(
				writeAnimationR childObj anim
			)

			endELement "animation"
		)
	),

	function writeAnimations = 
	(
		if beginElement "library_animations" then
		(
			for i = 1 to options.animations.count by 4 do
			(
				local anim = MFE_DaeAnimation()

				anim.animName = uniqueAnimationName i
				anim.startFrame = (options.animations[i + 1] as integer) as time
				anim.endFrame = (options.animations[i + 2] as integer) as time
				anim.samplingRate = options.animations[i + 3] as integer

				writeAnimationSet anim
			)

			endELement "library_animations"
		)
	),

	function writeScene = 
	(
		if beginElement "scene" then
		(
			local sceneName = uniqueNodeName rootNode

			leafElement "instance_visual_scene" names:#("url") values:#("#" + sceneName)

			endELement "scene"
		)
	),

	function write nodes _file _options = 
	(
		file = _file
		options = _options
		nodeUtil.init options

		selectedNodes = nodes
		MFE_registerNodePaths requiredNodes selectedNodes includeBones:(options.fileVariant != MFE_FileVariant_StaticMesh)

		if options.fileVariant != MFE_FileVariant_AnimationOnly then
		(
			for nodeObj in selectedNodes where MFE_isVisibleGeomNode nodeObj do
			(
				MFE_registerNodeMaterials materials nodeObj
			)
		)

		format "<?xml version=\"1.0\" encoding=\"utf-8\"?>" to:file

		if beginElement "COLLADA" names:#("xmlns", "version") values:#("http://www.collada.org/2005/11/COLLADASchema", "1.4.1") then
		(
			writeAsset()
			writeImages()
			writeEffects()
			writeMaterials()
			writeGeometries()
			writeControllers()
			writeVisualScenes()

			if options.fileVariant == MFE_FileVariant_AnimatedMesh or options.fileVariant == MFE_FileVariant_AnimationOnly then
			(
				writeAnimations()
			)

			writeScene()

			endElement "COLLADA"
		)
	)
)


function MFE_writeDaeFile nodes fileName file options = 
(
	local d = MFE_DaeFileWriter()

	d.write nodes file options
)


-- MFE_SceneFileHelper.ms


MFE_StrTab_Key = 1
MFE_StrTab_FileName = 2
MFE_StrTab_Type = 3
MFE_StrTab_Data = 4


function MFE_stringTabFromFile strTab fileName file = 
(
	strTab.count = 0

	seek file #eof

	if filePos file == 0 then
	(
		return strTab
	)

	seek file 0

	strTab[MFE_StrTab_Key] = "580132485aa5b1d9"
	strTab[MFE_StrTab_FileName] = fileName
	strTab[MFE_StrTab_Type] = "text"
	strTab[MFE_StrTab_Data] = ""

	local strIndex = MFE_StrTab_Data

	try
	(
		while not eof file do
		(
			strTab[strIndex] = readChars file 15000 errorAtEOF:false
			strIndex += 1
		)
	)
	catch
	(
		strTab.count = 0
		messageBox "Unable to store generated data."
	)
)


function MFE_stringTabToFile strTab fileName = 
(
	local file = createFile fileName

	if file != undefined then
	(
		for i = MFE_StrTabData to strTab.count do
		(
			format "%" strTab[i] to:file
		)

		close file
	)
)


plugin Helper MFE_SceneFileHelper name:"SceneFile" classID:#(0x9fd46b4f, 0xc57e114d) extends:Dummy
(
	parameters contents
	(
		fileData1 type:#stringTab tabSizeVariable:true animatable:false
		fileData2 type:#stringTab tabSizeVariable:true animatable:false
	)

	parameters options rollout:optionsUI
	(
		exportYUp type:#boolean default:true ui:cbExportYUp animatable:false
		exportUnits type:#integer default:(MFE_unitsID units.SystemType) ui:ddlExportUnits animatable:false
		exportScale type:#float default:units.SystemScale animatable:false
		fileFormat type:#integer default:MFE_FileFormat_X ui:ddlFileFormat animatable:false
		fileVariant type:#integer default:MFE_FileVariant_AnimatedMesh ui:rbsFileVariant animatable:false
		flipFlippedFaces type:#boolean default:true ui:cbFlipFlippedFaces animatable:false
		maxBonesPerVertex type:#integer default:4 ui:spMaxBonesPerVertex animatable:false
		poseFrame type:#time default:0 ui:spPoseFrame animatable:false
		enableNormals type:#boolean default:true ui:cbEnableNormals animatable:false
		enableTangents type:#boolean default:false ui:cbEnableTangents animatable:false
		enableColors type:#boolean default:false ui:cbEnableColors animatable:false
		maxTexCoordSets type:#integer default:1 ui:spMaxTexCoordSets animatable:false
		changeBitmapPath type:#boolean default:false ui:cbChangeBitmapPath animatable:false
		changeBitmapExt type:#boolean default:false ui:cbChangeBitmapExt animatable:false
		newBitmapPath type:#string default:"" ui:etNewBitmapPath animatable:false
		newBitmapExt type:#string default:"" ui:etNewBitmapExt animatable:false
		reduceFrames type:#boolean default:true ui:cbReduceFrames animatable:false
		separateTransforms type:#boolean default:true ui:cbSeparateTransforms animatable:false
		animations type:#stringTab tabSizeVariable:true animatable:false
		
		on exportScale set scale do
		(
			if scale <= 0.0 then
			(
				exportScale = 1.0
			)
		)	
	)

	rollout optionsUI "File Container"
	(
		group "Contents"
		(
			label fileInfo1 "" align:#left
			label fileInfo2 "" align:#left
			button btDelete "Delete" width:64 align:#left across:2 offset:[0,10]
			button btSave "Save..." width:64 align:#right offset:[0,10]
		)

		group "Export"
		(
			checkbox cbExportYUp "Y-Up" width:112 align:#center
			dropdownlist ddlExportUnits "Scale to Units:" items:#("Inches", "Feet", "Miles", "Millimeters", "Centimeters", "Decimeters", "Meters", "Kilometers") width:112 align:#center
			edittext etScaleText "" width:80 align:#center
			button btExportAddAll "Add All" width:112 offset:[0,10]
			button btExportAddSel "Select and Add" width:112
		)

		group "File Format"
		(
			dropdownlist ddlFileFormat items:#("DirectX (*.x)", "Object (*.obj)", "Collada (*.dae)")
			radiobuttons rbsFileVariant labels:#("Static mesh", "Animated mesh", "Animated mesh only", "Animation only")
		)

		group "Compatibility"
		(
			checkbox cbFlipFlippedFaces "Flip Flipped Faces"
			label lbMaxBonesPerVertex "Max Bones/Vertex:" align:#left
			spinner spMaxBonesPerVertex "" type:#integer range:[1,40,1]
		)

		group "Mesh"
		(
			spinner spPoseFrame "Pose Frame: " type:#integer range:[0,100000,1]
			checkbox cbEnableNormals "Vertex Normals"
			checkbox cbEnableTangents "Vertex Tangents"
			checkbox cbEnableColors "Vertex Colors"
			spinner spMaxTexCoordSets "Max UV Sets: " type:#integer range:[0,99,1]
		)

		group "Change Bitmap Paths"
		(
			checkbox cbChangeBitmapPath "Path:" across:2
			checkbox cbChangeBitmapExt "Extension:"
			edittext etNewBitmapPath "" across:2
			edittext etNewBitmapExt ""
		)

		group "Animation"
		(
			checkbox cbReduceFrames "Reduce Frames"
			checkbox cbSeparateTransforms "Separate Transforms"
		)

		group "Animation Clips"
		(
			dropdownlist ddlAnimList
			edittext etNewName "Rename:"
			spinner spStartFrame "Start Frame: " type:#integer range:[0,100000,1]
			spinner spEndFrame "End Frame: " type:#integer range:[0,100000,1]
			spinner spSamplingRate "FPS: " type:#integer range:[1,100,1]
			button btPrevAnim "<" width:24 align:#left across:3
			button btUpdateAnim "Update" width:64 align:#center
			button btNextAnim ">" width:24 align:#right
			label lbSelectedAnimInfo ""
			button btDeleteAnim "Delete" width:64 align:#left across:2
			button btAddNewAnim "Add New" width:64 align:#right
		)

		function updateFileInfo = 
		(
			fileInfo1.text = ""
			fileInfo2.text = ""

			if fileData1.count != 0 then
			(
				local fileSize1 = 0

				for i = MFE_StrTab_Data to fileData1.count do
				(
					fileSize1 += fileData1[i].count
				)

				fileInfo1.text = fileData1[MFE_StrTab_FileName] + ", " + fileSize1 as string + " bytes"
			)

			if fileData2.count != 0 then
			(
				local fileSize2 = 0

				for i = MFE_StrTab_Data to fileData2.count do
				(
					fileSize2 += fileData2[i].count
				)

				fileInfo2.text = fileData2[MFE_StrTab_FileName] + ", " + fileSize2 as string + " bytes"
			)

			btSave.enabled = fileData1.count != 0 or fileData2.count != 0
		)

		local nameOfNewAnimation = "Default"
		local selectedAnimIndex = 0

		function selectAnim animIndex = 
		(
			selectedAnimIndex = animIndex

			if selectedAnimIndex != 0 then
			(
				local i = 1 + (selectedAnimIndex - 1) * 4

				etNewName.enabled = true
				spStartFrame.enabled = true
				spEndFrame.enabled = true
				spSamplingRate.enabled = true

				etNewName.text = ""
				spStartFrame.value = animations[i + 1] as integer
				spEndFrame.value = animations[i + 2] as integer
				spSamplingRate.value = animations[i + 3] as integer

				local numAnims = animations.count / 4

				lbSelectedAnimInfo.text = selectedAnimIndex as string + "/" + numAnims as string
			)
			else
			(
				etNewName.enabled = false
				spStartFrame.enabled = false
				spEndFrame.enabled = false
				spSamplingRate.enabled = false

				etNewName.text = ""
				spStartFrame.value = 0
				spEndFrame.value = 0
				spSamplingRate.value = 0

				local numAnims = animations.count / 4

				lbSelectedAnimInfo.text = numAnims as string
			)
		)

		function updateSelectedAnim = 
		(
			if selectedAnimIndex != 0 then
			(
				local i = 1 + (selectedAnimIndex - 1) * 4

				local animName = if etNewName.text != "" then etNewName.text else animations[i]
				local startFrame = spStartFrame.value
				local endFrame = if spStartFrame.value <= spEndFrame.value then spEndFrame.value else spStartFrame.value
				local samplingRate = spSamplingRate.value

				animations[i] = animName
				animations[i + 1] = startFrame as string
				animations[i + 2] = endFrame as string
				animations[i + 3] = samplingRate as string

				if etNewName.text != "" then
				(
					ddlAnimList.selected = animName
					etNewName.text = ""
				)

				selectAnim selectedAnimIndex
			)
		)

		function addNewAnim = 
		(
			local i = 1 + selectedAnimIndex * 4

			for j = animations.count to i by -1 do
			(
				animations[j + 4] = animations[j]
			)

			local animName = nameOfNewAnimation
			local startFrame = animationRange.start.frame
			local endFrame = animationRange.end.frame
			local samplingRate = frameRate

			animations[i] = animName
			animations[i + 1] = startFrame as string
			animations[i + 2] = endFrame as string
			animations[i + 3] = samplingRate as string

			selectAnim (selectedAnimIndex + 1)
		)

		function deleteSelectedAnim = 
		(
			if selectedAnimIndex != 0 then
			(
				local i = 1 + selectedAnimIndex * 4

				for j = i to animations.count do
				(
					animations[j - 4] = animations[j]
				)

				animations.count = animations.count - 4

				local numAnims = animations.count / 4

				selectAnim (if selectedAnimIndex <= numAnims then selectedAnimIndex else selectedAnimIndex - 1)
			)
		)

		function updateAnimList = 
		(
			local animList = #()

			for i = 1 to animations.count by 4 do
			(
				append animList animations[i]
			)

			ddlAnimList.items = animList
			ddlAnimList.selection = selectedAnimIndex
		)

		function generateFile nodes = 
		(
			fileData1.count = 0
			fileData2.count = 0
			updateFileInfo()

			local helperName = if $ != undefined then $.name else "SceneFile"
			local options = MFE_Options()

			options.exportYUp = exportYUp
			options.exportUnits = exportUnits
			options.exportScale = exportScale
			options.fileFormat = fileFormat
			options.fileVariant = fileVariant
			options.flipFlippedFaces = flipFlippedFaces
			options.maxBonesPerVertex = maxBonesPerVertex
			options.poseFrame = poseFrame
			options.enableNormals = enableNormals
			options.enableTangents = enableTangents
			options.enableColors = enableColors
			options.maxTexCoordSets = maxTexCoordSets
			options.changeBitmapPath = changeBitmapPath
			options.changeBitmapExt = changeBitmapExt
			options.newBitmapPath = newBitmapPath
			options.newBitmapExt = newBitmapExt
			options.reduceFrames = reduceFrames
			options.separateTransforms = separateTransforms
			options.animations = animations

			fileInfo1.text = "Generating File..."

			if fileFormat == MFE_FileFormat_X then
			(
				local fileName = helperName + ".x"
				local file = stringStream ""

				at time poseFrame
				(
					MFE_writeXFile nodes fileName file options
				)

				MFE_stringTabFromFile fileData1 fileName file
			)
			else if fileFormat == MFE_FileFormat_Obj then
			(
				local objFileName = helperName + ".obj"
				local mtlFileName = helperName + ".mtl"
				local objFile = stringStream ""
				local mtlFile = stringStream ""

				at time poseFrame
				(
					MFE_writeObjFile nodes objFileName objFile mtlFileName mtlFile options
				)

				MFE_stringTabFromFile fileData1 objFileName objFile
				MFE_stringTabFromFile fileData2 mtlFileName mtlFile
			)
			else if fileFormat == MFE_FileFormat_Dae then
			(
				local fileName = helperName + ".dae"
				local file = stringStream ""

				at time poseFrame
				(
					MFE_writeDaeFile nodes fileName file options
				)

				MFE_stringTabFromFile fileData1 fileName file
			)

			updateFileInfo()
		)

		on btDelete pressed do
		(
			fileData1.count = 0
			fileData2.count = 0
			updateFileInfo()
		)

		on btSave pressed do
		(
			local version = maxVersion()

			if version[1] == 4200 then
			(
				messageBox "Feature not available: \"createFile\""
			)
			else
			(
				if fileData1.count != 0 then
				(
					local fileName = getSaveFileName filename:(maxFilePath + fileData1[MFE_StrTab_FileName])

					if fileName != undefined then MFE_stringTabToFile fileData1 fileName
				)

				if fileData2.count != 0 then
				(
					local fileName = getSaveFileName filename:(maxFilePath + fileData2[MFE_StrTab_FileName])

					if fileName != undefined then MFE_stringTabToFile fileData2 fileName
				)
			)
		)

		on ddlExportUnits selected unitsID do
		(
			local toMeters
			local fromMeters

			case units.SystemType of
			(
				#Inches: toMeters = 0.0254
				#Feet: toMeters = 0.3048
				#Miles: toMeters = 1609.344
				#Millimeters: toMeters = 0.001
				#Centimeters: toMeters = 0.01
				#Meters: toMeters = 1.0
				#Kilometers: toMeters = 1000.0
			)

			case unitsID of
			(
				MFE_Units_Inches: fromMeters = 0.0254
				MFE_Units_Feet: fromMeters = 0.3048
				MFE_Units_Miles: fromMeters = 1609.344
				MFE_Units_Millimeters: fromMeters = 0.001
				MFE_Units_Centimeters: fromMeters = 0.01
				MFE_Units_Decimeters: fromMeters = 0.1
				MFE_Units_Meters: fromMeters = 1.0
				MFE_Units_Kilometers: fromMeters = 1000.0
			)

			exportScale = units.SystemScale * toMeters / fromMeters
			etScaleText.text = exportScale as string
		)

		on etScaleText entered newScale do
		(
			newScale = newScale as float

			if newScale != undefined and not newScale <= 0.0 then
			(
				exportScale = newScale
			)

			etScaleText.text = exportScale as string
		)
		
		on btExportAddAll pressed do
		(
			generateFile (objects as array)
		)

		on btExportAddSel pressed do
		(
			nodes = selectByName buttonText:"Add"

			if nodes != undefined then
			(
				generateFile nodes
			)
		)

		on btPrevAnim pressed do
		(
			if selectedAnimIndex > 1 then
			(
				selectAnim (selectedAnimIndex - 1)
				ddlAnimList.selection = selectedAnimIndex
			)
		)

		on btNextAnim pressed do
		(
			if selectedAnimIndex < animations.count / 4 then
			(
				selectAnim (selectedAnimIndex + 1)
				ddlAnimList.selection = selectedAnimIndex
			)
		)

		on btUpdateAnim pressed do
		(
			updateSelectedAnim()
		)

		on btDeleteAnim pressed do
		(
			deleteSelectedAnim()
			updateAnimList()
		)

		on btAddNewAnim pressed do
		(
			addNewAnim()
			updateAnimList()
		)

		on ddlAnimList selected animIndex do
		(
			selectAnim animIndex
		)

		on optionsUI open do
		(
			etScaleText.text = exportScale as string

			if animations.count == 0 then
			(
				addNewAnim()
			)
			else if selectedAnimIndex == 0 then
			(
				selectedAnimIndex = 1
			)

			updateFileInfo()
			updateAnimList()
			selectAnim selectedAnimIndex
		)
	)

	rollout helpUI "Help"
	(
		group "Contents Unpack Option"
		(
			label lbHelpLine1 "Save the scene"
			label lbHelpLine2 "and use MaxUnpack.exe"
			label lbHelpLine3 "with the scene file."
		)

		group "About Multi-Format Exporter"
		(
			label lbAboutLine1 "(c) 2025 Andrzej Chomiak"
			label lbAboutLine2 "Version 1.0"
		)
	)
)
