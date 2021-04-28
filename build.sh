#!/bin/bash

CMD=$1
BUILD=$2
VSCODE=$3
OPTIONS=$4

cwd=${PWD##*/}

export GCC_COLORS="error=01;31:warning=01;33:note=01;36:locus=00;34"

#==============================================================================
# Function declarations

display_styled_symbol() {
	printf "\033[1;$1m$2  $3\033[0m\n"
}

build_success() {
	printf '\n'
	display_styled_symbol 32 "✔" "Succeeded!"
	printf '\n'
}

launch() {
	display_styled_symbol 32 " " "Launching bin/$BUILD/$NAME"
	printf '\n'
}

build_success_launch() {
	printf '\n'
	display_styled_symbol 32 "✔" "Succeeded!"
	launch
}

build_fail() {
	printf '\n'
	display_styled_symbol 31 "✘" "Failed!"
	display_styled_symbol 31 " " "Review the compile errors above."
	printf '\n'
	printf '\033[0m'
	exit 1
}

build_prod_error() {
	printf '\n'
	display_styled_symbol 31 "⭙" "Error: buildprod must be run on Release build."
	printf '\033[0m'
	exit 1
}

profiler_done() {
	printf '\n'
	display_styled_symbol 35 "⯌" "Profiler Completed: View $PROF_ANALYSIS_FILE for details"
	printf '\n'
}

profiler_error() {
	printf '\n'
	display_styled_symbol 31 "⭙" "Error: Profiler must be run on Debug build."
	printf '\033[0m'
	exit 1
}

profiler_osx() {
	display_styled_symbol 31 "⭙" "Error: Profiling (with gprof) is not supported on Mac OSX."
	printf '\033[0m'
	exit 1
}

cmd_buildrun() {
	display_styled_symbol 33 "⬤" "Build & Run: $BUILD (target: $NAME)"
	printf '\n'
	BLD=$BUILD
	if [[ $BUILD == 'Tests' && $1 != 'main' ]]; then
		BLD=Release
	fi
	if $MAKE_EXEC BUILD=$BLD; then
		build_success_launch
		if [[ $BUILD == 'Tests' ]]; then
			bin/Release/$NAME $OPTIONS
		else
			bin/$BUILD/$NAME $OPTIONS
		fi
	else
		build_fail
	fi
}

cmd_build() {
	display_styled_symbol 33 "⬤" "Build: $BUILD (target: $NAME)"
	printf '\n'
	BLD=$BUILD
	if [[ $BUILD == 'Tests' && $1 != 'main' ]]; then
		BLD=Release
	fi
	if $MAKE_EXEC BUILD=$BLD; then
		build_success
	else
		build_fail
	fi
}

cmd_rebuild() {
	display_styled_symbol 33 "⬤" "Rebuild: $BUILD (target: $NAME)"
	printf '\n'
	BLD=$BUILD
	if [[ $BUILD == 'Tests' && $1 != 'main' ]]; then
		BLD=Release
	fi
	if $MAKE_EXEC BUILD=$BLD rebuild; then
		build_success
	else
		build_fail
	fi
}

cmd_run() {
	display_styled_symbol 33 "⬤" "Run: $BUILD (target: $NAME)"
	printf '\n'
	launch
	if [[ $BUILD == 'Tests' ]]; then
		bin/Release/$NAME $OPTIONS
	else
		bin/$BUILD/$NAME $OPTIONS
	fi
}

cmd_buildprod() {
	display_styled_symbol 33 "⬤" "Production Build: $BUILD (target: $NAME)"
	printf '\n'
	if [[ $BUILD == 'Release' ]]; then
		RECIPE=buildprod
		if [[ $1 != 'main' ]]; then
			RECIPE=
		fi
		if $MAKE_EXEC BUILD=$BUILD $RECIPE; then
			build_success
		else
			build_fail
		fi
	else
		build_prod_error
	fi
}

cmd_profile() {
	display_styled_symbol 33 "⬤" "Profile: $BUILD (target: $NAME)"
	printf '\n'
	if [[ $PLATFORM == 'osx' ]]; then
		profiler_osx
	elif [[ $BUILD == 'Debug' ]]; then
		if $MAKE_EXEC BUILD=$BUILD; then
			build_success_launch
			printf '\033[0m'
			bin/$BUILD/$NAME
			printf '\033[0;34m'
			gprof bin/Debug/$NAME gmon.out > $PROF_ANALYSIS_FILE 2> /dev/null
			profiler_done
		else
			build_fail
		fi
	else
		profiler_error
	fi
}

#==============================================================================
# Environment

if [[ $CMD == '' ]]; then
	CMD=buildprod
fi
if [[ $BUILD == '' ]]; then
	BUILD=Release
fi

if [[ $OSTYPE == 'linux-gnu'* || $OSTYPE == 'cygwin'* ]]; then
	if [[ $OSTYPE == 'linux-gnueabihf' ]]; then
		export PLATFORM=rpi
	else
		export PLATFORM=linux
	fi
elif [[ $OSTYPE == 'darwin'* ]]; then
	export PLATFORM=osx
elif [[ $OSTYPE == 'msys' || $OSTYPE == 'win32' ]]; then
	export PLATFORM=windows
fi


if [[ $VSCODE != 'vscode' ]]; then
	export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
	if [[ $PLATFORM == 'windows' ]]; then
		export PATH="/c/SFML-2.5.1/bin:/c/mingw32/bin:$PATH"
	else
		if [[ $PLATFORM == 'rpi' ]]; then
			export PATH="/usr/local/gcc-8.1.0/bin:$PATH"
		fi
	fi
	printf "\nbuild.sh PATH=$PATH\n"
fi

export MAKE_EXEC=make
if [[ $PLATFORM == 'windows' ]]; then
	if [ $(type -P "mingw32-make.exe") ]; then
		export MAKE_EXEC=mingw32-make.exe
	elif [ $(type -P "make.exe") ]; then
		export MAKE_EXEC=make.exe
	fi
fi

if [[ $BUILD != "Release" && $BUILD != 'Debug' && $BUILD != 'Tests' ]]; then
	BUILD=Release
fi

PROF_EXEC=gprof
PROF_ANALYSIS_FILE=profiler_analysis.stats

#==============================================================================
# Main script

if [[ $BUILD_TARGETS == '' ]]; then
	BUILD_TARGETS=main
	NO_SRC_TARGET=1
fi

for target in $BUILD_TARGETS; do
	if [[ $PLATFORM == 'windows' ]]; then
		if [[ $target == 'main' ]]; then
			export NAME=$cwd.exe
			if [[ $BUILD == 'Tests' ]]; then
				NAME=tests_$NAME
			fi
		else
			if [[ $BUILD == 'Debug' ]]; then
				export NAME=lib$target-d.dll
			else
				export NAME=lib$target.dll
			fi
		fi
	else
		if [[ $PLATFORM == 'osx' ]]; then
			if [[ $target == 'main' ]]; then
				export NAME=$cwd
				if [[ $BUILD == 'Tests' ]]; then
					NAME=tests_$NAME
				fi
			else
				if [[ $BUILD == 'Debug' ]]; then
					export NAME=lib$target-d.dylib
				else
					export NAME=lib$target.dylib
				fi
			fi
		else
			if [[ $target == 'main' ]]; then
				export NAME=$cwd
				if [[ $BUILD == 'Tests' ]]; then
					NAME=tests_$NAME
				fi
			else
				if [[ $BUILD == 'Debug' ]]; then
					export NAME=lib$target-d.so
				else
					export NAME=lib$target.so
				fi
			fi
		fi
	fi

	if [[ $NO_SRC_TARGET != 1 ]]; then
		export SRC_TARGET=$target
	fi

	if [[ ($CMD == 'run' || $CMD == 'profile') && $target != 'main' ]]; then
		continue
	fi

	CHILD_CMD="cmd_$CMD $target"
	if [[ $CMD == 'buildrun' && $target != 'main' ]]; then
		CHILD_CMD="cmd_build"
	fi


	printf '\033[0;34m'
	if $CHILD_CMD ; then
		printf '\033[0m'
	else
		printf "\033[1;31mError: Command \"$CHILD_CMD\" not recognized.\033[0m"
		exit 1
	fi

	RESULT=$?
	if [[ $RESULT != 0 ]]; then
		break
	fi

done

printf '\033[0m\n'

exit 0
