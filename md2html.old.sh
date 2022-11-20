#!/bin/bash

#    md2html.sh conver markdown files to html web pages
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
program_name="md2html"
dir="./"
head=./head.html
tail=./tail.html
static=./static
output=./www
clean=0

show_help(){
	echo 
	echo \
"$program_name conver markdown files to html web pages
Copyright (C) 2021 A.G. Tony Barletta
This program comes with ABSOLUTELY NO WARRANTY; 
This is free software, and you are welcome to redistribute it
under certain conditions;
"
	echo usage: 
	echo "  ./$program_name.sh [-h,--help] [-v,--verbose] [ --head head.html ] [ --tail tail.html ] [ --clean ] dir"
	echo 
	echo "  dir                              directory to transfor ( ./ default ) (string)"
	echo options:
	echo "  -v, --verbose                    verbose"
	echo "  -h, --help                       help"
	echo "  --head                           head html file ( default ./head.html  ) (string)"
	echo "  --tail                           tail html file ( default ./tail.html  ) (string)"
	echo "  --static                         static directory ( default ./static ) (string)"
	echo "  --output                         output directory ( default ./www ) (string)"
	echo "  --clean                          clean the target directory from previously"
	echo "                                       generated html files (skips .part.html)"
}

output_verbose(){
	[ $verbose == 1 ] && echo $1
	
}

options=$(getopt -l "help,verbose,vv,dir:,head:,tail:,static:,output:,clean" -o "hvd:" -a -- "$@")

eval set -- "$options"

while true
do
case $1 in
-h|--help) 
    show_help
    exit 0
    ;;
-v|--verbose)
    export verbose=1
    ;;
--vv)
    export verbose=1
    set -xv  # Set xtrace and verbose mode.
    ;;
--head)
	shift
    export head=$1
    ;;
--tail)
	shift
    export tail=$1
    ;;
--static)
	shift
    export static=$1
    ;;
--output)
	shift
    export output=$1
    ;;
--clean)
	export clean=1
	;;
--)
    shift
	export dir=$1
    break;;
esac
shift
done


################## SCRIPT ####################à

output_verbose "dir: $dir" 
output_verbose "head: $head" 
output_verbose "tail: $tail" 
output_verbose "static: $static" 
output_verbose "output: $output" 
output_verbose "clean: $clean" 

single_file(){
	full_path=$1
	dir=${full_path%/*}
	file=${full_path##*/}
	filename=${file%.*}
	body_html=$dir/$filename.tmp.html
	titled_head_html=$dir/$filename.tmp.head.html
	full_path_html=$dir/$filename.html
	# extract key words
	# put keywords in head
	output_verbose "full_path $full_path"
	output_verbose "dir $dir"
	output_verbose "file $file"
	output_verbose "filename $filename"
	output_verbose "body_html $body_html"
	output_verbose "titled_head_html $titled_head_html"
	output_verbose "full_path_html $full_path_html"

	TITLE=$(sed -e 's/^#\s\(.*\)$/\1/;t;d' $full_path)
	sed "s/<\!--TITLE-->/$TITLE/g" $head > $titled_head_html
	pandoc -o $body_html $full_path 
	cat $titled_head_html $body_html $tail > $full_path_html
	substitute_embed $full_path_html
	rm $body_html
	rm $titled_head_html
}

substitute_embed(){

	for i in $(sed -n 's/^.*<embed src=\"\(.*\)".*$/\1/p' $1); do
		echo $i
		full_path=$(dirname "$1")"/"$(basename "$i")
		echo $full_path
		inj_line=$(grep -n "<embed src=\"$i\"" $1 | cut -d ":" -f 1)
		lines=$(wc -l $1 | cut -d " " -f 1)
		tail_lines=$(( $lines - $inj_line ))
		echo $lines
		echo $inj_line
		echo $tail_lines
		echo -------
		tmp=$(dirname "$1")"/tmp.html"
		touch $tmp
		head -n $inj_line $1 > $tmp
		cat $full_path >> $tmp
		tail -n $tail_lines $1 >> $tmp
		mv $tmp $1
	done ;
	sed -i 's/^.*<embed src=\".*".*$//g' $1
}

if [ $clean == 1 ]; then
	for f in $dir $(find $dir -type f); do
		if [[ $f =~ ^.*\.html$ ]] && [[ ! $f =~ ^.*\.part\.html$ ]]; then
			rm $f
			output_verbose "removing $f"
		fi;
	done;
	exit 0
fi


for curr_dir in $dir $(find $dir -type d); do
	echo $curr_dir
	ls $curr_dir/*.md || continue;
	output_verbose "ls-ing curr_dir $curr_dir/.*md"
	output_verbose "$(ls $curr_dir/*.md)"
	for i in $(ls $curr_dir/*.md); do
		output_verbose "i $i"
		output_verbose "paring $i"
		single_file $i
	done;
done;

