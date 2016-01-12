#!/bin/sh

# -p stops errors if the directory already exists
#mkdir -p source

# Grab everything after the '=' character
DOWNLOAD_TOOLKIT_URL=$(grep -i TOOLKIT_SOURCE_URL $CONFIG/config | cut -f2 -d'=')

if [ -n "$DOWNLOAD_TOOLKIT_URL" ]; then
	echo # Grab everything after the last '/' character
	ARCHIVE_TOOLKIT_FILE=${DOWNLOAD_TOOLKIT_URL##*/}

	# Delete folder with previously extracted kernel
	rm -rf tools
	mkdir tools

	cd tools

	# Downloading kernel file
	# -c option allows the download to resume
	wget -c $DOWNLOAD_TOOLKIT_URL

	#extract 
	tar -xvf $ARCHIVE_TOOLKIT_FILE #-C ../work/kernel
	cd ..
fi

# Grab everything after the '=' character
DOWNLOAD_KERNEL_URL=$(grep -i KERNEL_SOURCE_URL $CONFIG/config | cut -f2 -d'=')

if [ -z "$DOWNLOAD_KERNEL_URL" ]; then
	# Grab everything after the last '/' character
	ARCHIVE_FILE=${DOWNLOAD_KERNEL_URL##*/}

	cd source

	# Downloading kernel file
	# -c option allows the download to resume
	wget -c $DOWNLOAD_KERNEL_URL

	# Delete folder with previously extracted kernel
	#rm -rf ../work/kernel
	#mkdir ../work/kernel

	# Extract kernel to folder 'work/kernel'
	# Full path will be something like 'work/kernel/linux-3.16.1'
	#tar -xvf $ARCHIVE_FILE -C ../work/kernel
fi
