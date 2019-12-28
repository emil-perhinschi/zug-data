import std.stdio;

import gtk.MainWindow;
import gtk.Main;
import gtk.Widget;
import gtk.Box;
import cairo.Context;
import gtk.DrawingArea;
import gdk.Pixbuf;
import gdkpixbuf.Pixbuf;
import gdkpixbuf.c.types : GdkColorspace;
import gtk.Image;

import zug.matrix;
import zug.dumper;

void main(string[] args)
{
	import std.conv: to;

	Main.init(args);
	MainWindow app = new MainWindow("Matrix to images");
	app.setSizeRequest(640, 360);
	app.addOnDestroy(delegate void(Widget w) { quitApp(); });

	writeln("starting ...");
	auto image_versions = new Box(Orientation.VERTICAL, 10);
	auto app_box = new Box(Orientation.HORIZONTAL, 10);
	app.add(image_versions);
	image_versions.add(app_box);

	auto greyscale_imgs = new Box(Orientation.HORIZONTAL,10);
	image_versions.add(greyscale_imgs);

	auto left_image_data  = read_bmp("tests/left_2.bmp");
	writeln(left_image_data.get(1000));
	auto right_image_data = read_bmp("tests/right_2.bmp");

	size_t sample_size = 20;
	int scale = 20;
	size_t center_top_x = (left_image_data.width/2) - (sample_size/2);
	size_t center_top_y = (left_image_data.height/2) - (sample_size/2);
	auto offset = Offset(center_top_x, center_top_y);
	Matrix!(DataPoint!ubyte) left_center = left_image_data.dice!(DataPoint!ubyte)(offset, sample_size, sample_size);
	Matrix!(DataPoint!ubyte) left_center_zoomed = left_center.enlarge(scale,scale);
	Pixbuf left_center_zoomed_pixbuf 
		= left_center_zoomed
			.to_grayscale_values()
			.to_pixbuf();


	ulong min_diff = 99999999;
	size_t index_min_diff = 0;
	Matrix!(DataPoint!ubyte) found_dice;
	Offset found_offset;
	for (size_t i = 0; i< center_top_x; i++) 
	{
		auto right_offset = Offset(center_top_x - i, center_top_y);
		auto right_sample = right_image_data.dice(right_offset, sample_size, sample_size);
		auto this_difference = left_center.difference(right_sample);
		if (min_diff > this_difference) {
			min_diff = this_difference;
			index_min_diff = i;
			found_dice = right_sample;
			found_offset = right_offset;
		}
	}

	writeln("difference: ", min_diff, " found offset: ", found_offset);

	DataPoint!ubyte red_point = DataPoint!ubyte(255, 0, 0, 255);
	writeln(red_point);
	auto left_image_data_framed = left_image_data.add_frame(offset, sample_size, sample_size, red_point);
	auto right_image_data_framed = right_image_data.add_frame(found_offset, sample_size, sample_size, red_point);

	auto left_image = new Image(left_image_data_framed.to_pixbuf);
	app_box.add(left_image);
	auto right_image = new Image( right_image_data_framed.to_pixbuf);
	app_box.add(right_image);
	

	app.showAll();
	Main.run();
}

ulong difference(T)(Matrix!(DataPoint!T) left, Matrix!(DataPoint!T) right)
{
	import std.conv: to;
	import std.math: abs;

	assert(
		( 
			left.width == right.width 
			&& left.height == right.height 
		)
		, "matrices must have the same size"
	);

	long result = 0;
	for (size_t i = 0; i < left.data_length; i++) {
		// using greyscale values
		long grey_left = left.get(i).to_grayscale.red.to!long;
		long grey_right = right.get(i).to_grayscale.red.to!long;
		result += (grey_left - grey_right).abs();
	}

	return result;
}



Pixbuf to_pixbuf(Matrix!(DataPoint!ubyte) matrix ) 
{
	import std.conv: to;

	return new Pixbuf(
		matrix.data_matrix_to_pixmap,
		GdkColorspace.RGB,
		true, // has alpha
		8, // color depth
		matrix.width.to!int, matrix.height.to!int,
		(matrix.width*4).to!int, // rowstride: how many bytes is the length of a row of RGBA pixels
		null,null // cleanup functions
	);
}

// Image left = read_image_grayscaled("tests/bla1.bmp");
// Image right = read_image_grayscaled("tests/bla2.bmp");
Image read_image_grayscaled(string file_path)
{
	int color_depth = 8;
	int width     = 640;
	int height    = 480;
	int rowstride = width * 4;
	bool has_alpha = true;

	auto matrix = read_bmp(file_path);
	auto matrix_grayscale = matrix.to_grayscale_values!(DataPoint!ubyte)();
	// auto matrix_grayscale = matrix.filter!(DataPoint!ubyte)( in => in.to_grayscale );
	auto bitmapped = matrix_grayscale.data_matrix_to_pixmap();

	Pixbuf pixbuf = new Pixbuf(
		bitmapped, 
		GdkColorspace.RGB, 
		has_alpha,
		color_depth,
		width, height, 
		rowstride, 
		null, null
	);

	return new Image(pixbuf);
}

Image read_image_averaged(string file_path)
{
	int color_depth = 8;
	int width     = 640;
	int height    = 480;
	int rowstride = width * 4;
	bool has_alpha = true;

	auto matrix = read_bmp(file_path);
	auto matrix_grayscale = matrix.to_average_values!(DataPoint!ubyte)();
	// auto matrix_grayscale = matrix.filter!(DataPoint!ubyte)( in => in.to_grayscale );
	auto bitmapped = matrix_grayscale.data_matrix_to_pixmap();

	Pixbuf pixbuf = new Pixbuf(
		bitmapped, 
		GdkColorspace.RGB, 
		has_alpha,
		color_depth,
		width, height, 
		rowstride, 
		null, null
	);

	return new Image(pixbuf);
}


struct DataPoint(T) 
{
	private: 
	T red;
	T green;
	T blue;
	T alpha;

	public: 
	T[4] to_array() 
	{
		return [ this.red, this.green, this.blue, this.alpha ];
	}
}

DataPoint!T to_average(T)(DataPoint!T point) 
{
	import std.algorithm.iteration: mean;

	T average = (point.red + point.green + point.blue)/3;
	return DataPoint!T(average, average, average, point.alpha);
}

DataPoint!ubyte to_grayscale(DataPoint!ubyte orig) 
{
	import std.conv: to;

	float greyscaled = 0.2989*orig.red.to!float + 0.5870*orig.green.to!float + 0.1140*orig.blue.to!float;
	ubyte computed = greyscaled.to!ubyte;
	return DataPoint!ubyte(computed, computed, computed, orig.alpha);
}


Matrix!(DataPoint!ubyte) read_bmp(string file_path) 
{
	import arsd.bmp;
	import zug.matrix;
	import arsd.color;

	auto test = readBmp(file_path);
	writeln("width ", test.width, " height ", test.height);
	auto bla = cast(TrueColorImage) test;
	
	// writeln(bla.imageData.bytes);
	ubyte[] data = bla.imageData.bytes;
	auto height = bla.height;
	auto width  = bla.width;
	int pixel_count = height*width;
	auto matrix = Matrix!(DataPoint!ubyte)(width, height);
	
	for (int i = 0; i < pixel_count; i++) 
	{
		auto point = DataPoint!ubyte(data[i*4], data[i*4+1], data[i*4+2], data[i*4+3]);
		matrix.set(i, point);
	}
	writeln(matrix.height, " ", matrix.width, " ", matrix.data_length);
	// dbg(matrix);
	return matrix;
}

char[] data_matrix_to_pixmap(P)(Matrix!P matrix) 
{
	import std.conv: to;

	char[] result;
	foreach(P point; matrix.data)
	{
		result ~= cast(char[]) point.to_array();
	}

	return result;
}



Matrix!T to_grayscale_values(T)(Matrix!T matrix) {

	size_t width = matrix.width;
	T[] result = new T[matrix.data_length];
	for (size_t i = 0; i < matrix.data_length; i++) {
		auto old = matrix.get(i);
		result[i] = old.to_grayscale();
	}
	return Matrix!T(result, matrix.width);
}

Matrix!T to_average_values(T)(Matrix!T matrix) {

	size_t width = matrix.width;
	auto result = new T[matrix.data_length];
	for (size_t i = 0; i < matrix.data_length; i++) {
		auto old = matrix.get(i);
		result[i] = old.to_average!(ubyte)();
	}
	return Matrix!T(result, matrix.width);
}


// class AppBox : Box
// {
// 	MyDrawingArea myDrawingArea;

// 	this()
// 	{
// 		super(Orientation.VERTICAL, 10);

// 		myDrawingArea = new MyDrawingArea();

// 		packStart(myDrawingArea, true, true, 0); // LEFT justify

// 	}
// }

// class MyDrawingArea : DrawingArea
// {
// 	GtkAllocation size; // the area assigned to the DrawingArea by its parent
// 	Pixbuf pixbuf; // an 8-bit/pixel image buffer
// 	string[] jpegOptions, jpegOptionValues;
// 	int xOffset = 0, yOffset = 0;

// 	this()
// 	{
// 		addOnDraw(&onDraw);
// 	}

// 	bool onDraw(Scoped!Context context, Widget w)
// 	{
// 		import gdkpixbuf.c.types: GdkColorspace;

// 		char[] data = [
// 			0,0,0,0, 55,155,255,1, 0,0,0,0, 
// 			0,0,0,0, 55,155,255,1, 0,0,0,0, 
// 			0,0,0,0, 55,155,255,1, 0,0,0,0, 
// 			0,0,0,0, 55,155,255,1, 0,0,0,0, 
// 		];

// 		pixbuf = new Pixbuf(data, GdkColorspace.RGB, false, 8, 3, 4, 12, null, null);

// 		return (true);
// 	}
// }

//dfmt off
	// char[] bitmapped = [
	// 	0,0,0,0, 55,155,255,1, 0,0,0,0, 0,0,0,0, 55,155,255,1, 0,0,0,0, 0,0,0,0, 55,155,255,1, 0,0,0,0,
	// 	0,0,0,0, 55,155,255,1, 0,0,0,0, 0,0,0,0, 55,155,255,1, 0,0,0,0, 0,0,0,0, 55,155,255,1, 0,0,0,0,
	// 	0,0,0,0, 55,155,255,1, 0,0,0,0, 0,0,0,0, 55,155,255,1, 0,0,0,0, 0,0,0,0, 55,155,255,1, 0,0,0,0,
	// 	0,0,0,0, 55,155,255,1, 0,0,0,0, 0,0,0,0, 55,155,255,1, 0,0,0,0, 0,0,0,0, 55,155,255,1, 0,0,0,0,
	// 	0,0,0,0, 55,155,255,1, 0,0,0,0, 0,0,0,0, 55,155,255,1, 0,0,0,0, 0,0,0,0, 55,155,255,1, 0,0,0,0,
	// 	0,0,0,0, 55,155,255,1, 0,0,0,0, 0,0,0,0, 55,155,255,1, 0,0,0,0, 0,0,0,0, 55,155,255,1, 0,0,0,0,
	// 	0,0,0,0, 55,155,255,1, 0,0,0,0, 0,0,0,0, 55,155,255,1, 0,0,0,0, 0,0,0,0, 55,155,255,1, 0,0,0,0,
	// 	0,0,0,0, 55,155,255,1, 0,0,0,0, 0,0,0,0, 55,155,255,1, 0,0,0,0, 0,0,0,0, 55,155,255,1, 0,0,0,0,
	// 	0,0,0,0, 55,155,255,1, 0,0,0,0, 0,0,0,0, 55,155,255,1, 0,0,0,0, 0,0,0,0, 55,155,255,1, 0,0,0,0,
	// 	0,0,0,0, 55,155,255,1, 0,0,0,0, 0,0,0,0, 55,155,255,1, 0,0,0,0, 0,0,0,0, 55,155,255,1, 0,0,0,0,
	// 	0,0,0,0, 55,155,255,1, 0,0,0,0, 0,0,0,0, 55,155,255,1, 0,0,0,0, 0,0,0,0, 55,155,255,1, 0,0,0,0,
	// 	0,0,0,0, 55,155,255,1, 0,0,0,0, 0,0,0,0, 55,155,255,1, 0,0,0,0, 0,0,0,0, 55,155,255,1, 0,0,0,0,				
	// ];
//dfmt on


void quitApp()
{
	// This exists in case we want to do anything
	// before exiting such as warn the user to
	// save work.
	writeln("Bye.");
	Main.quit();

}
