#!/bin/bash

program_name="md_tree_parser"
program_desc="Generate a html tree from a markdown tree"
#    Copyright (C) 2020 A.G. Tony Barletta
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version. 
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details. 
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <https://www.gnu.org/licenses/>.

verbose=0
silent=0
example_argument_a="default_a"
source_dir="source"
dest_dir="dest"
static_dir=""
example_argument_b=0
example_mandatory_positional_argument="default_c"
example_argument_opt=0

usage(){
	cat <<END_USAGE
	usage: 
	  ./$program_name.sh [-v|--verbose] [-s|--silent] [-h|--help] [--static <static_dir>] <source_dir> <dest_dir>

	options:
	  -v --verbose 					turn on verbose output
	  -s --silent 					turn off all output
	  -h --help 					show help
	  -a --example_argument_a 		a variable with string value
	  --static 						static directory, containing style, fonts, js etc
	  -b 							a variable with number value
	  -o --example_argument_opt		a variable with no value
END_USAGE
}
help(){
	cat <<END_HELP
	$program_name 
	$program_desc
	Copyright (C) 2020 A.G. Tony Barletta
	This program comes with ABSOLUTELY NO WARRANTY; 
	This is free software, and you are welcome to redistribute it
	under certain conditions;
END_HELP
	usage
}



msgv(){
	[ $verbose == 1 ] && echo "DBG: " $*
}

msg(){
	[ $silent != 1 ] && echo $*
}
msge(){
	>&2 echo "ERR: " $*
}

if [[ ${@: -1} =~ ^-h|--help$ ]] ; then
	help
	exit 0
fi
# 2 mandatory argument
if [[ $# -lt 2 ]]; then
	msge mandatory arguments needed
	usage
	exit 0
fi


dest_dir=${@: -1}
#remove parsed mandatory arguments
set -- "${@:1:$#-1}"
source_dir=${@: -1}
set -- "${@:1:$#-1}"



while [[ $# -gt 0 ]]; do
	opt=$1
	value=$2
    case $opt in
		-h|--help)
			help
			exit 0
			;;
		-v|--verbose)
			verbose=1
			shift 1
			;;
		-s|--silent)
			silent=1
			shift 1
			;;
		--static)
			static_dir=$value
			shift 2
			;;
		-a|--example_argument_a)
			example_argument_a=$value
			shift 2
			;;
		-b)
			example_argument_b=$value
			shift 2
			;;
		-o|--example_argument_opt)
			example_argument_opt=1
			shift 1
			;;
		*)
			msg Unknow argument $opt
			usage
			exit 1
			;;
	esac
done



msgv 	argument passed:
msgv 	verbose: $verbose
msgv 	silent: $silent
msgv 	"source directory:" $source_dir
msgv 	destination directory: $dest_dir
msgv	static_dir: $static_dir
#msgv 	example_argument_a: $example_argument_a
#msgv 	example_argument_b: $example_argument_b
#msgv 	example_argument_opt: $example_argument_opt
#msgv 	example_mandatory_positional_argument: $example_mandatory_positional_argument


#	     _             _   
#	 ___| |_ __ _ _ __| |_ 
#	/ __| __/ _` | '__| __|
#	\__ \ || (_| | |  | |_ 
#	|___/\__\__,_|_|   \__|


# substitute <!--TAG--> from source file with content
# arg1 source
# arg2 tag
# arg3 content
substitute_tag(){
	source=$1
	tag=$2
	content=$3
	sed "s/<\!--$tag-->/$content/g" -i $source	
}

# get title from md file
# arg1 md_file
get_tiltle_md(){
	md_file=$1
	sed -e 's/^#\s\(.*\)$/\1/;t;d' $md_file
}

# transform single file from md to html
# arg1: source file
# arg2: source dir
# arg3: dest dir
# arg4: header
# arg5: tail

transform_file(){
	msgv "--->" in transform_file
	msgv source file: $1
	msgv source dir: $2
	msgv dest dir: $3
	msgv header: $4
	msgv tail: $5
	
	filename=${1##*/}
	filename_no_extension=${filename%%.*}
	msgv filename: $filename
	msgv filename_no_extension: $filename_no_extension
	# tranfrom basic md fil
	pandoc -o tmp.html $1
	dest_file=$3/$filename_no_extension.html
	cat $4 tmp.html $5> $dest_file

	# substitute tags in head and tail
	title=$(get_tiltle_md $1)
	msgv title $title
	substitute_tag $dest_file TITLE "$title"	

	msgv

}

# recursevely tranfrom  all file from source dir to dest dir
rec_transform_dir() {
	msgv "--->" in rec_transform_dir
	msgv source_dir: $1
	msgv dest_dir: $2
	msgv header: $3
	msgv tail: $4

	list_files=$(find $1/*.md -maxdepth 1 -not -type d )

	for f in $list_files; do
		msgv transforming file: $f
		transform_file $f $1 $2 $3 $4
	done;

	#copy all files
	#list_files=$(find $1/* -maxdepth 1 -not -type d )
	cp $1/* $2

	list_dir=$(find $1/* -maxdepth 1 -type d)
	for d in $list_dir; do
		len_char_source=${#1}
		dir_without_source=${d:$len_char_source}
		msgv parsing directory $dir_without_source
		mkdir $2/$dir_without_source
		rec_transform_dir $d $2/$dir_without_source $3 $4
	done;

	msgv 
}

msgv "check source directory"
if ! [ -d $source_dir ]; then
	msge "source directory " $source_dir "doesn't exist"
	exit -1
fi;

msgv "check destination directory"
if ! [ -d $dest_dir ]; then
	msgv "creating destination directory"
	mkdir $dest_dir || ( msge "cannot create destination directory " $dest_dir && exit -1 )
else 
	msgv "destination dir exists"
	content=$( ls -l $dest_dir | wc -l )
	if [ $content -gt 1 ]; then
		msge "destination directory not empty";
		exit -1;
	fi
	msgv "destination directory empty; using it"
fi;

# copy static files
if [ "$static_dir" != "" ]; then
	msgv static dir initalize, copying ...
	msgv copy $static_dir in $dest_dir
	cp -r $static_dir $dest_dir
	msgv static dir copied
fi


#transform_file source/index.md source dest head.html tail.html
rec_transform_dir $source_dir $dest_dir head.html tail.html
