#define PI						3.1415
#define SPEED_OF_LIGHT			3e8		//not exact but hey!
#define SPEED_OF_LIGHT_SQ		9e+16
#define INFINITY				1e31	//closer then enough

#define SHORT_REAL_LIMIT 16777216

//"fancy" math for calculating time in ms from tick_usage percentage and the length of ticks
//percent_of_tick_used * (ticklag * 100(to convert to ms)) / 100(percent ratio)
//collapsed to percent_of_tick_used * tick_lag
#define TICK_DELTA_TO_MS(percent_of_tick_used) ((percent_of_tick_used) * world.tick_lag)
#define TICK_USAGE_TO_MS(starting_tickusage) (TICK_DELTA_TO_MS(world.tick_usage-starting_tickusage))

#define PERCENT(val) (round(val*100, 0.1))
#define CLAMP01(x) (clamp(x, 0, 1))

//time of day but automatically adjusts to the server going into the next day within the same round.
//for when you need a reliable time number that doesn't depend on byond time.
#define REALTIMEOFDAY (world.timeofday + (MIDNIGHT_ROLLOVER * MIDNIGHT_ROLLOVER_CHECK))
#define MIDNIGHT_ROLLOVER_CHECK ( GLOB.rollovercheck_last_timeofday != world.timeofday ? update_midnight_rollover() : GLOB.midnight_rollovers )

#define CLAMP(CLVALUE,CLMIN,CLMAX) ( max( (CLMIN), min((CLVALUE), (CLMAX)) ) )

// Credits to Nickr5 for the useful procs I've taken from his library resource.
// This file is quadruple wrapped for your pleasure
// (

#define NUM_E 2.71828183

#define SYSTEM_TYPE_INFINITY					1.#INF //only for isinf check

#define SIGN(x) ( (x)!=0 ? (x) / abs(x) : 0 )

#define CEILING(x, y) ( -round(-(x) / (y)) * (y) )

/// `round()` acts like `floor(x, 1)` by default but can't handle other values
#define FLOOR(x, y) ( round((x) / (y)) * (y) )

/// Similar to clamp but the bottom rolls around to the top and vice versa. min is inclusive, max is exclusive
#define WRAP(val, min, max) ( min == max ? min : (val) - (round(((val) - (min))/((max) - (min))) * ((max) - (min))) )

/// Real modulus that handles decimals
#define MODULUS(x, y) ( (x) - (y) * round((x) / (y)) )

/// Tangent
#define TAN(x) tan(x)

/// Cotangent
#define COT(x) (1 / TAN(x))

/// Secant
#define SEC(x) (1 / cos(x))

/// Cosecant
#define CSC(x) (1 / sin(x))

#define ATAN2(x, y) arctan(x, y)

#define INVERSE(x) ( 1/(x) )

#define ISABOUTEQUAL(a, b, deviation) (deviation ? abs((a) - (b)) <= deviation : abs((a) - (b)) <= 0.1)

#define ISEVEN(x) (x % 2 == 0)

#define ISODD(x) (x % 2 != 0)

/// Returns true if val is from min to max, inclusive.
#define ISINRANGE(val, min, max) (min <= val && val <= max)

// Same as above, exclusive.
#define ISINRANGE_EX(val, min, max) (min < val && val < max)

#define ISINTEGER(x) (round(x) == x)

#define ISMULTIPLE(x, y) ((x) % (y) == 0)

// Performs a linear interpolation between a and b.
// Note that amount=0 returns a, amount=1 returns b, and
// amount=0.5 returns the mean of a and b.
#define LERP(a, b, amount) ( amount ? ((a) + ((b) - (a)) * (amount)) : a )

/// Returns the nth root of x.
#define ROOT(n, x) ((x) ** (1 / (n)))

/// Low-pass filter a value to smooth out high frequent peaks. This can be thought of as a moving average filter as well.
/// delta_time is how many seconds since we last ran this command. RC is the filter constant, high RC means more smoothing
/// See https://en.wikipedia.org/wiki/Low-pass_filter#Simple_infinite_impulse_response_filter for the maths
#define LPFILTER(memory, signal, delta_time, RC) (delta_time / (RC + delta_time)) * signal + (1 - delta_time / (RC + delta_time)) * memory

#define TODEGREES(radians) ((radians) * 57.2957795)

#define TORADIANS(degrees) ((degrees) * 0.0174532925)

/// Gets shift x that would be required the bitflag (1<<x)
#define TOBITSHIFT(bit) ( log(2, bit) )

// Will filter out extra rotations and negative rotations
// E.g: 540 becomes 180. -180 becomes 180.
#define SIMPLIFY_DEGREES(degrees) (MODULUS((degrees), 360))

#define GET_ANGLE_OF_INCIDENCE(face, input) (MODULUS((face) - (input), 360))

/// Finds the shortest angle that angle A has to change to get to angle B. Aka, whether to move clock or counterclockwise.
/proc/closer_angle_difference(a, b)
	if(!isnum_safe(a) || !isnum_safe(b))
		return
	a = SIMPLIFY_DEGREES(a)
	b = SIMPLIFY_DEGREES(b)
	var/inc = b - a
	if(inc < 0)
		inc += 360
	var/dec = a - b
	if(dec < 0)
		dec += 360
	. = inc > dec? -dec : inc

/// A logarithm that converts an integer to a number scaled between 0 and 1. Currently, this is used for hydroponics-produce sprite transforming, but could be useful for other transform functions.
#define TRANSFORM_USING_VARIABLE(input, max) ( sin((90*(input))/(max))**2 )

/// Returns a list where [1] is all x values and [2] is all y values that overlap between the given pair of rectangles
/proc/get_overlap(x1, y1, x2, y2, x3, y3, x4, y4)
	var/list/region_x1 = list()
	var/list/region_y1 = list()
	var/list/region_x2 = list()
	var/list/region_y2 = list()

	// These loops create loops filled with x/y values that the boundaries inhabit
	// ex: list(5, 6, 7, 8, 9)
	for(var/i in min(x1, x2) to max(x1, x2))
		region_x1["[i]"] = TRUE
	for(var/i in min(y1, y2) to max(y1, y2))
		region_y1["[i]"] = TRUE
	for(var/i in min(x3, x4) to max(x3, x4))
		region_x2["[i]"] = TRUE
	for(var/i in min(y3, y4) to max(y3, y4))
		region_y2["[i]"] = TRUE

	return list(region_x1 & region_x2, region_y1 & region_y2)

#define EXP_DISTRIBUTION(desired_mean) ( -(1/(1/desired_mean)) * log(rand(1, 1000) * 0.001) )

#define LORENTZ_DISTRIBUTION(x, s) ( s*TAN(TODEGREES(PI*(rand()-0.5))) + x )
#define LORENTZ_CUMULATIVE_DISTRIBUTION(x, y, s) ( (1/PI)*TORADIANS(arctan((x-y)/s)) + 1/2 )

#define RULE_OF_THREE(a, b, x) ((a*x)/b)

/// Converts a probability/second chance to probability/delta_time chance
/// For example, if you want an event to happen with a 10% per second chance, but your proc only runs every 5 seconds, do `if(prob(100*DT_PROB_RATE(0.1, 5)))`
#define DT_PROB_RATE(prob_per_second, delta_time) (1 - (1 - (prob_per_second)) ** delta_time)

/// Like DT_PROB_RATE but easier to use, simply put `if(DT_PROB(10, 5))`
#define DT_PROB(prob_per_second_percent, delta_time) (prob(100*DT_PROB_RATE((prob_per_second_percent)/100, delta_time)))
// )

/// Taxicab distance--gets you the **actual** time it takes to get from one turf to another due to how we calculate diagonal movement
#define MANHATTAN_DISTANCE(a, b) (abs(a.x - b.x) + abs(a.y - b.y))
// )

/// A function that exponentially approaches a maximum value of L
/// k is the rate at which is approaches L, x_0 is the point where the function = 0
#define LOGISTIC_FUNCTION(L,k,x,x_0) (L/(1+(NUM_E**(-k*(x-x_0)))))

// )
/// Make sure something is a boolean TRUE/FALSE 1/0 value, since things like bitfield & bitflag doesn't always give 1s and 0s.
#define FORCE_BOOLEAN(x) ((x)? TRUE : FALSE)

// )
/// Gives the number of pixels in an orthogonal line of tiles.
#define TILES_TO_PIXELS(tiles)			(tiles * PIXELS)
// )
