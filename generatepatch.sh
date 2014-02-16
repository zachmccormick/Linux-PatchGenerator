#!/bin/bash
if [ $# -ne 2 ]; then
	cat <<'EOF'
usage: ./generatepatch.sh vanilla_root_folder modified_root_folder

This will generate a single patch, called finishedpatch.sh that will
patch both ascii files and binary files using diff and tar.

The patch requires bash, patch, and tar when executing.
EOF
	exit 1
fi

# make sure paths have ending slashes
ORIG=$1
NEW=$2
[[ $ORIG != */ ]] && ORIG="$ORIG"/
[[ $NEW != */ ]] && NEW="$NEW"/
# now we know ORIG and NEW end in slashes

let "ORIGSLASHES= `grep -o "/" <<<"$ORIG" | wc -l`"
let "NEWSLASHES= `grep -o "/" <<<"$NEW" | wc -l`"

# make the patch
diff --ignore-all-space -rupNB -x "\.*" -x "vendor" -x "docs" $1 $2 > optio.patch

# get rid of the "no newline at end of file" alerts that break patch
sed -i '/^\\/d' optio.patch

# compress the binaries
cat temporary.patch | grep "Binary files" | awk '{print $5;}' | tar cfz patch.tgz -T -

cat > patchtemplate.sh <<'EOF2'
#!/bin/bash
echo ""
echo "Optio Labs self extracting patcher"
echo ""

THIS=`pwd`/$0
SKIP=`awk '/^__TARFILE_FOLLOWS__/ { print NR + 1; exit 0; }' $0`

cat > temporary.patch <<'EOF0'
PATCHGOESHERE
EOF0

if [ "$1" == "--revert" ]; then
	echo "Attempting to reverse the patch"
	echo "Testing a dry run into `pwd`"
	patch -R --dry-run --strip ORIGSLASHES < temporary.patch > error.log
	if [ $? -eq 0 ]; then
		echo "Dry run succeeded, doing a real patch reverse..."
		rm error.log
	else
		echo "Dry run was unsuccessful.  See error.log for details."
		rm temporary.patch
		exit 1
	fi
	#silent patch since we know it works...
	patch -R -s --strip ORIGSLASHES < temporary.patch

	rm temporary.patch
	echo "Patch reversal complete, reversing binaries..."

	# get tar to list the files with relative paths then try to restore originals
	tail -n +$SKIP $THIS | tar -zt | cut -d"/" -f NEWSLASHES- | awk '{system("rm "$1"");
	if ( system("[ -e "$1".orig ]") == 0 )
	{
		system("mv "$1".orig "$1"");
	}}'


	echo "Finished!"
	exit 0
else	
	echo "Testing a dry run into `pwd`"
	patch --dry-run --strip ORIGSLASHES < temporary.patch > error.log
	if [ $? -eq 0 ]; then
		echo "Dry run succeeded, doing a real patch..."
		rm error.log
	else
		echo "Dry run was unsuccessful.  See error.log for details."
		rm temporary.patch
		exit 1
	fi

	#silent patch since we know it works...
	patch -s --strip ORIGSLASHES < temporary.patch

	rm temporary.patch
	echo "Patch complete, extracting binaries..."

	# take the tarfile and pipe it into tar
	# strip components needs to be changed depending on where you're generating this
	tail -n +$SKIP $THIS | tar -zt | cut -d"/" -f NEWSLASHES- | awk '{
	if ( system("[ -e "$1" ]") == 0 )
	{
		system("mv "$1" "$1".orig");
	}}'
	
	tail -n +$SKIP $THIS | tar -xz --strip-components NEWSLASHESMINUS1

	echo "Finished!"
	exit 0
fi
# NOTE: Don't place any newline characters after the last line below.
__TARFILE_FOLLOWS__
EOF2

# inject the tar strip components number
let "NEWSLASHESMINUS1 = $NEWSLASHES - 1"
sed -i "s/NEWSLASHESMINUS1/$NEWSLASHESMINUS1/g" patchtemplate.sh
# do NEWSLASHES next (otherwise you'll get something like 6MINUS1 if the next one came first)
sed -i "s/NEWSLASHES/$NEWSLASHES/g" patchtemplate.sh

# inject the patch strip number
sed -i "s/ORIGSLASHES/$ORIGSLASHES/g" patchtemplate.sh

# inject the patch
sed -e '/PATCHGOESHERE/ {
r temporary.patch
d }' < patchtemplate.sh > partialpatch.sh

# append the binaries
cat partialpatch.sh patch.tgz > patch.sh
chmod a+x patch.sh
rm partialpatch.sh
rm temporary.patch
rm patchtemplate.sh
rm patch.tgz

echo "Patch generation successful"
exit 0
