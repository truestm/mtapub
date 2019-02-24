local bzc = {1000,1000,
	{
		{"path2985",-43691,-16777216,10.6211,1,
			{
				{true,131.739,134.476,868.842,736.88,{131.739,369.654,131.739,516.512,175.561,585.045,333.321,511.617,491.081,438.188,521.756,403.921,688.28,589.941,854.804,775.96,898.626,834.703,850.422,467.559,802.218,100.415,846.04,501.826,718.956,443.083,591.871,384.34,732.102,139.577,543.667,134.682,355.232,129.787,574.343,213.006,534.903,315.806,495.463,418.607,355.232,575.255,311.41,423.502,267.588,271.749,193.09,281.539,131.739,369.654,131.739,369.654,131.739,369.654,131.739,369.654}}
			}
		},
		{"rect2987",-16711681,-16777216,10.6211,1,
			{
				{true,228.148,487.14,618.165,687.846,{228.148,487.14,358.153,487.14,488.159,487.14,618.165,487.14,618.165,554.042,618.165,620.944,618.165,687.846,488.159,687.846,358.153,687.846,228.148,687.846,228.148,620.944,228.148,554.042,228.148,487.14}}
			}
		},
		{"path3008",-16711681,0,1,1,
			{
				{true,288.571,165.714,402.857,342.857,{402.857,254.286,402.857,285.929,391.966,315.169,374.286,330.991,356.606,346.813,334.823,346.813,317.143,330.991,299.463,315.169,288.571,285.929,288.571,254.286,288.571,222.642,299.463,193.402,317.143,177.581,334.823,161.759,356.606,161.759,374.286,177.581,391.966,193.402,402.857,222.642,402.857,254.286,402.857,254.286,402.857,254.286,402.857,254.286}}
			}
		},
		{"rect3010",-16711936,0,1,1,
			{
				{true,560.082,658.726,931.347,886.988,{595.303,746.073,680.258,717.837,765.212,689.601,850.166,661.365,877.12,652.406,906.232,666.994,915.191,693.948,919.696,707.504,924.202,721.061,928.708,734.617,937.666,761.571,923.079,790.683,896.125,799.641,811.171,827.877,726.216,856.113,641.262,884.349,614.309,893.308,585.196,878.72,576.238,851.767,571.732,838.21,567.226,824.654,562.721,811.097,553.762,784.143,568.35,755.031,595.303,746.073,595.303,746.073,595.303,746.073,595.303,746.073}}
			}
		},
		{"path3038",-16711936,0,1,1,
			{
				{true,145.714,122.826,254.286,231.46,{254.286,177.143,254.295,196.549,243.95,214.481,227.149,224.184,210.348,233.886,189.646,233.885,172.846,224.18,156.046,214.476,145.703,196.543,145.714,177.141,145.705,157.737,156.05,139.805,172.851,130.102,189.652,120.399,210.354,120.401,227.154,130.105,243.954,139.81,254.297,157.743,254.286,177.144,254.286,177.144,254.286,177.143,254.286,177.143}}
			}
		}
	}
}

local function distPtSeg(x, y, px, py, qx, qy)
	local pqx, pqy, dx, dy, d, t
	pqx = qx-px
	pqy = qy-py
	dx = x-px
	dy = y-py
	d = pqx*pqx + pqy*pqy
	t = pqx*dx + pqy*dy
	if d > 0 then 
		t = t / d 
	end
	if t < 0 then 
		t = 0	
	elseif t > 1 then 
		t = 1
	end
	dx = px + t*pqx - x
	dy = py + t*pqy - y
	return dx*dx + dy*dy
end

function cubicBez( x1, y1, x2, y2, x3, y3, x4, y4, tol, level, vertexes, color )
	if level > 12 then return end

	local x12 = (x1+x2)*0.5
	local y12 = (y1+y2)*0.5
	local x23 = (x2+x3)*0.5
	local y23 = (y2+y3)*0.5
	local x34 = (x3+x4)*0.5
	local y34 = (y3+y4)*0.5
	local x123 = (x12+x23)*0.5
	local y123 = (y12+y23)*0.5
	local x234 = (x23+x34)*0.5
	local y234 = (y23+y34)*0.5
	local x1234 = (x123+x234)*0.5
	local y1234 = (y123+y234)*0.5

	local d = distPtSeg(x1234, y1234, x1,y1, x4,y4)
	if d > tol*tol then
		cubicBez(x1,y1, x12,y12, x123,y123, x1234,y1234, tol, level+1, vertexes, color ); 
		cubicBez(x1234,y1234, x234,y234, x34,y34, x4,y4, tol, level+1, vertexes, color ); 
	else
		vertexes[#vertexes + 1] = { x4, y4, color }
	end
end

function drawPath( path, tol, fill, stroke, width, opacity )
	local closed,lx,ly,hx,hy,points = unpack(path)
	local vertexes = { { ( lx + hx ) * 0.5, ( ly + hy ) * 0.5, fill } }
	local size = #points - 2
	local i = 0
	while i < size do
		cubicBez( points[i + 1], points[i + 2], 
			points[i + 3], points[i + 4], 
			points[i + 5], points[i + 6], 
			points[i + 7], points[i + 8], tol, 0, vertexes, fill )
		i = i + 6
	end
	
	if closed then
		vertexes[#vertexes + 1] = vertexes[2]
		dxDrawPrimitive( "trianglefan", true, unpack(vertexes) )
	end
	
	local x,y = vertexes[2][1], vertexes[2][2]
	
	for i = 3,#vertexes do
		dxDrawLine( x, y, vertexes[i][1], vertexes[i][2], stroke, width, true )
		x, y = vertexes[i][1], vertexes[i][2]
	end
end

function drawShape( shape, tol )
	local name,fill,stroke,width,opacity,paths = unpack(shape)
	for _,path in ipairs(paths) do
		drawPath( path, tol, fill, stroke, width, opacity )
	end
end

function drawBzc( bzc, tol )
	for _,shape in ipairs(bzc[3]) do
		drawShape( shape, tol )
	end
end

addEventHandler("onClientRender", root, 
function()
	drawBzc( bzc, 0.5 )
end)
