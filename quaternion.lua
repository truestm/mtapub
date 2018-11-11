function quaternion_multiply(x1,y1,z1,w1, x2,y2,z2,w2)
	return
		w1*x2 + x1*w2 + y1*z2 - z1*y2,
		w1*y2 - x1*z2 + y1*w2 + z1*x2,
		w1*z2 + x1*y2 - y1*x2 + z1*w2,
		w1*w2 - x1*x2 - y1*y2 - z1*z2
--[[
	local A = (w1 + x1) * (w2 + x2)
	local B = (z1 - y1) * (y2 - z2)
	local C = (x1 - w1) * (y2 + z2)
	local D = (y1 + z1) * (x2 - w2)
	local E = (x1 + z1) * (x2 + y2)
	local F = (x1 - z1) * (x2 - y2)
	local G = (w1 + y1) * (w2 - z2)
	local H = (w1 - y1) * (w2 + z2)
	local w = B + ( -E - F + G + H ) * 0.5
	local x = A - ( E + F + G + H ) * 0.5
	local y = -C + ( E - F + G - H ) * 0.5
	local z = -D + ( E - F - G + H ) * 0.5
	return x,y,z,w
]]
end

function quaternion_to_xyz( x, y, z, w )
	return  math.deg( math.atan2( 2 * ( y*w - x*z ), 1 - 2*y*y - 2*z*z ) ),
	math.deg( math.asin( 2 * ( x*y + z*w ) ) ),
	math.deg( math.atan2( 2*x*w - 2*y*z, 1 - 2*x*x - 2*z*z ) )
end

local function cos_sin_half_angle( a )
	local h = math.rad(a) * 0.5
	return math.cos(h), math.sin(h)
end

function quaternion_from_angle( a, x, y, z )
	local h = math.rad( a * 0.5 )
	local cos = math.cos( h )
	local sin = math.sin( h )
	return sin * x, sin * y, sin * z, cos
end

function quaternion_from_angle_z( a, l )
	return quaternion_from_angle( a, 0, 0, l or 1 )
end

function quaternion_from_angle_y( a, l )
	return quaternion_from_angle( a, 0, l or 1, 0 )
end

function quaternion_from_angle_x( a, l )
	return quaternion_from_angle( a, l or 1, 0, 0 )
end

function quaternion_from_xyz( x, y, z )
	local c1 = math.cos(math.rad(x / 2))
	local c2 = math.cos(math.rad(y / 2))
	local c3 = math.cos(math.rad(z / 2))
	local s1 = math.sin(math.rad(x / 2))
	local s2 = math.sin(math.rad(y / 2))
	local s3 = math.sin(math.rad(z / 2))

	return
		(s1 * s2 * c3) + (c1 * c2 * s3),
		(s1 * c2 * c3) + (c1 * s2 * s3),
		(c1 * s2 * c3) - (s1 * c2 * s3),
		(c1 * c2 * c3) - (s1 * s2 * s3)
--[[
	local cos_x, sin_x = cos_sin_half_angle( x )
	local cos_y, sin_y = cos_sin_half_angle( y )
	local cos_z, sin_z = cos_sin_half_angle( z )
	
	local cos_x_cos_y = cos_x * cos_y
	local sin_x_sin_y = sin_x * sin_y
	local sin_x_cos_y = sin_x * cos_y
	local cos_x_sin_y = cos_x * sin_y
	
	local qw = cos_x_cos_y * cos_z - sin_x_sin_y * sin_z 
	local qx = sin_x_sin_y * cos_z + cos_x_cos_y * sin_z 
	local qy = sin_x_cos_y * cos_z + cos_x_sin_y * sin_z
	local qz = cos_x_sin_y * cos_z - sin_x_cos_y * sin_z 	
	
	return qx, qy, qz, qw
]]
end

function quaternion_conjugate( x, y, z, w )
	return -x, -y, -z, w
end

function quaternion_inverse( x, y, z, w )
	local qx, qy, qz, qw = quaternion_conjugate( x,y,z,w )
	local norm = 1 / ( x*x + y*y + z*z + w*w )
	return qx * norm, qy * norm, qz * norm, qw * norm
end

function quaternion_transform( x, y, z, w, vx, vy, vz )
	local qx, qy, qz, qw = quaternion_multiply( x,y,z,w, vx,vy,vz,0 )
	return quaternion_multiply( qx,qy,qz,qw, quaternion_inverse( x,y,z,w ) )
end
