#!/bin/bash

export CVSROOT=/cvs-repo
#export CVSROOT=~/cvs-repo2

[ "$1" == "" ] && echo -e "Usage: verify [PROJECTNAME] \n[PROJECTNAME] is the name of the module in CVS. \n\nThis script verifies the outcome of migrate-cvs2git.sh so assumes there is a Git repo in the dir PROJECTNAME.git.bare" &&  exit;
PROJECT=$1
MODULE=$2	# Only specified when migrating subdir of a module. Otherwise PROJECT is a module
PROJECT_CVS=$PROJECT.cvs.diff
PROJECT_GIT=$PROJECT.git.diff

if [ ! -d "$PROJECT" ]; then
	if [ "$MODULE" ]; then
		echo "Checking out $MODULE/$PROJECT from CVS"
		cvs -Q co $MODULE/$PROJECT
		mv $MODULE/$PROJECT .
		rm -r $MODULE
	else
		echo "Checking out $PROJECT from CVS"
		cvs -Q co $PROJECT
	fi
fi

if [ ! -d "$PROJECT_CVS" ]; then
	echo "Copying CVS project and remove files which we ignore during comparison"
	cp -r $PROJECT $PROJECT_CVS
	## Delete files we can ignore during comparison
	find $PROJECT_CVS -type d -mindepth 1 -name CVS -exec rm -r {} \; &> /dev/null
	## Git does not support empty directories
	find $PROJECT_CVS -type d -mindepth 1 -empty -delete &> /dev/null 
fi

## Clone bare git project
if [ ! -d "$PROJECT_GIT" ]; then
	echo "Cloning bare Git project"
	git clone $PROJECT.git.bare $PROJECT_GIT
fi
 

##  -rq shows only the files which differ, -r shows diff inside files as well
diff -rq --exclude=".git" \
	--ignore-matching-lines=" * @version.*\\$\Revision" --ignore-matching-lines="* \\$\Id" \
	$PROJECT_GIT $PROJECT_CVS

RESULT=$?
if [ $RESULT -eq 0 ]; then
  echo "Git repo is equal to the CVS repo! \o/"
else
  echo -e "Differences between repo's! \nFor detailed differences do: "
  echo "diff -r --exclude='.git' --ignore-matching-lines=\" * @version.*\\$\Revision\" --ignore-matching-lines=\"* \\$\Id\" $PROJECT_GIT $PROJECT_CVS"
fi

echo -e "To cleanup perform: \nrm -r $PROJECT $PROJECT_CVS $PROJECT_GIT *.dat cvs2svn-tmp"
exit $RESULT;