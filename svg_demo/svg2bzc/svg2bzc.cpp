#include "stdafx.h"

#define NANOSVG_ALL_COLOR_KEYWORDS	// Include full list of color keywords.
#define NANOSVG_IMPLEMENTATION		// Expands implementation
#include "nanosvg/src/nanosvg.h"

int convert_color( unsigned int color )
{
	return static_cast<int>( ( color & 0xff00ff00 ) | ( ( color & 0x000000ff ) << 16 ) | ( ( color & 0x00ff0000 ) >> 16 ) );
}

void endl( std::vector<int> & level, bool nl )
{
	if( nl )
	{
		std::cout << std::endl;

		for( auto i = 0; i < level.size(); ++ i )
			std::cout << "\t";
	}
}

void begin( std::vector<int> & level, bool nl = true )
{
	if( !level.empty() && level.back() > 0 )
	{
		std::cout << ",";
	}

	if( !level.empty() )
		++ level.back();

	endl( level, nl );

	std::cout << "{";

	level.push_back(0);
}

std::ostream & out( std::vector<int> & level, bool nl = false )
{
	if( !level.empty() && level.back() > 0 )
	{
		std::cout << ",";
	}

	endl( level, nl );

	if( !level.empty() )
		++ level.back();

	return std::cout;
}

void end( std::vector<int> & level, bool nl = true )
{
	level.pop_back();

	endl( level, nl );

	std::cout << "}";
}

int _tmain(int argc, _TCHAR* argv[])
{
	std::wstring_convert<std::codecvt_utf8_utf16<wchar_t>> convert;
	auto filename = convert.to_bytes(argv[1]);

	struct NSVGimage* image;

	image = nsvgParseFromFile(filename.c_str(), "px", 96);

	std::vector<int> level;
	begin( level );
	out( level ) << image->width;
	out( level ) << image->height;
	
	begin( level );

	for( auto shape = image->shapes; shape != NULL; shape = shape->next )
	{
		begin( level );
		out( level ) << "\"" << shape->id << "\"";
		out( level ) << convert_color( shape->fill.color );
		out( level ) << convert_color( shape->stroke.color );
		out( level ) << shape->strokeWidth;
		out( level ) << shape->opacity;

		begin( level );

		for( auto path = shape->paths; path != NULL; path = path->next )
		{
			begin( level );

			out( level ) << ( path->closed ? "true" : "false" );

			for( auto i = 0; i < 4; ++ i )
			{
				out( level ) << path->bounds[i];
			}
			
			begin( level, false );

			for( auto i = 0; i < path->npts; ++ i )
			{
				out( level ) << path->pts[i * 2];
				out( level ) << path->pts[i * 2 + 1];
			}

			end( level, false );

			end( level, false );
		}

		end( level );

		end( level );
	}
	
	end( level );

	end( level );

	nsvgDelete(image);
	return 0;
}

