#define DEBUG					//Enables byond profiling and full runtime logs - note, this may also be defined in your .dme file
								//Enables in-depth debug messages to runtime log (used for debugging)
//#define TESTING				//By using the testing("message") proc you can create debug-feedback for people with this
								//uncommented, but not visible in the release version)

#ifdef TESTING
//#define GC_FAILURE_HARD_LOOKUP	//makes paths that fail to GC call find_references before del'ing.
									//Also allows for recursive reference searching of datums.
									//Sets world.loop_checks to false and prevents find references from sleeping

#endif

#define BACKGROUND_ENABLED FALSE    // The default value for all uses of set background. Set background can cause gradual lag and is recommended you only turn this on if necessary.
								// 1 will enable set background. 0 will disable set background.

//Update this whenever you need to take advantage of more recent byond features
#define MIN_COMPILER_VERSION 514
#define MIN_COMPILER_BUILD 1556
#if (DM_VERSION < MIN_COMPILER_VERSION || DM_BUILD < MIN_COMPILER_BUILD) && !defined(SPACEMAN_DMM)
//Don't forget to update this part
#error Your version of BYOND is too out-of-date to compile this project. Go to https://secure.byond.com/download and update.
#error You need version 514.1556 or higher
#endif

#if (DM_VERSION == 514 && DM_BUILD > 1575 && DM_BUILD <= 1577)
#error Your version of BYOND currently has a crashing issue that will prevent you from running Dream Daemon test servers.
#error We require developers to test their content, so an inability to test means we cannot allow the compile.
#error Please consider downgrading to 514.1575 or lower.
#endif



//Additional code for the above flags.
#ifdef TESTING
#warn compiling in TESTING mode. testing() debug messages will be visible.
#endif

#ifdef CIBUILDING
#define UNIT_TESTS
#endif

#ifdef CITESTING
#define TESTING
#endif


#ifndef PRELOAD_RSC //set to:
#define PRELOAD_RSC 2 // 0 to allow using external resources or on-demand behaviour;
#endif // 1 to use the default behaviour;
								// 2 for preloading absolutely everything;

#ifdef TGS
// TGS performs its own build of dm.exe, but includes a prepended TGS define.
#define CBT
#endif

#if !defined(CBT) && !defined(SPACEMAN_DMM)
#warn Building with Dream Maker is no longer supported and will result in errors.
#warn In order to build, run BUILD.bat in the root directory.
#warn Consider switching to VSCode editor instead, where you can press Ctrl+Shift+B to build.
#endif

