#!/usr/bin/env bash

base_dir="$HOME/catmarks"
current_dir="$base_dir"


archive_downloader(){
	notify-send "triggered archive_downloader"
	url=$1
	name=$2
	save_location=$3
	response=$(curl -sI "https://web.archive.org/save/$url")
	echo "$response" >> $HOME/.dotfiles/scripts/log.txt
	echo "-------------------------------" >> $HOME/.dotfiles/scripts/log.txt
	notify-send "got a response"
	archive_url=$(echo "$response" | grep '^location:' | tail -c +11 | tr -d '\r')
	echo "$archive_url" >> $HOME/.dotfiles/scripts/log.txt
	echo "-------------------------------" >> $HOME/.dotfiles/scripts/log.txt
	notify-send "archive_url $archive_url"
	webpage=$(curl "$archive_url")
	img_archive_src=$(echo "$webpage" | grep "main-product-image" | sed -n 's/.*data-src-zoom-image="\([^"]*\)".*/\1/p')
	img_org_src=$(echo "$img_archive_src" | sed 's|https://web.archive.org/.*\(https://i.etsystatic.com/.*\)|\1|')
	notify-send "img_org_src $img_org_src"
	img_ext="${img_org_src##*.}"

	
	curl "$img_org_src" -o "$save_location/$name.$img_ext"
	
	if [[ "$img_ext" != "png" ]] && [[ "$img_ext" != "jpg" ]]; then
		magick "$save_location/$name.$img_ext" "$save_location/$name.png"
		notify-send "Image wasn't a png or jpg, might need to be converted?"
	else
		notify-send "image was a png or jpg, doing nothing extra"
	fi
}



while true; do

	



	files=($(ls -a "$current_dir"))
	text_with_icons=""

	inarray=$(echo ${files[@]} | grep -ow "rofi_theme.rasi" | wc -w)
	[ "$inarray" -eq 1 ] && ROFI_THEME="custom" || ROFI_THEME="system"


	#selection=$(ls "$current_dir" | rofi -dmenu -kb-custom-1 "Alt+a" -theme ./icon-theme.rasi -show-icons)
	for file in "$current_dir"/*; do
		[ -e "$file" ] || continue
		if [ -d "$file" ] || [[ "$file" == *.txt ]]; then
			name_ext=$(basename "$file")
			name="${name_ext%.*}"
			if [ -e "$current_dir/$name.png" ]; then  
				text_with_icons+="$name\0icon\x1fthumbnail://$current_dir/$name.png\n" 
			elif [ -e "$current_dir/$name.jpg" ]; then  
				text_with_icons+="$name\0icon\x1fthumbnail://$current_dir/$name.jpg\n" 
			else 
				text_with_icons+="$name\n"
			fi
		fi
		
	done
	
	# [ "$base_dir" != "$current_dir" ] && text_with_icons+="Return" 
	# text_with_icons+="New Entry\0icon\x1fthumbnail://$HOME/catmarks/catppuccin--folder.png\n"
	# text_with_icons+="New Group\n"


	if [[ "$ROFI_THEME" == "system" ]]; then
		selection=$(echo -en "$text_with_icons" | rofi -dmenu -kb-custom-1 "Alt+a" -kb-custom-2 "Alt+d")
	else
		selection=$(echo -en "$text_with_icons" | rofi -dmenu -show-icons -kb-custom-1 "Alt+a" -kb-custom-2 "Alt+d" -theme "$current_dir/rofi_theme.rasi")
	fi
	exit_code=$?

	# Exit the script
	if [ "$exit_code" -eq 1 ]; then
		break

	# Opening an entry (Pressing Enter)
	elif [ "$exit_code" -eq 0 ]; then
		[ "$selection" == "Return" ] && current_dir=$(dirname "$current_dir") || current_dir="$current_dir/$selection"

	# Adding a new item entry
	elif [ "$exit_code" -eq 10 ]; then # Will cause problems as can't properly quit halfway through
		new_url=$(rofi -dmenu -p "Enter the URL")
		new_name=$(rofi -dmenu -p "Enter the Name")
		archive_downloader "$new_url" "$new_name" "$current_dir" &
		echo "$new_url" >> "$current_dir/$new_name.txt"

	elif [ "$exit_code" -eq 11 ]; then
		new_dir=$(rofi -dmenu -p "Enter the category name")
		mkdir "$current_dir/$new_dir"
		current_dir="$current_dir/$new_dir"

	fi

done
