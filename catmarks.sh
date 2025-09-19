#!/usr/bin/env bash

base_dir="$HOME/catmarks"
current_dir="$base_dir"


archive_downloader(){
	url=$1
	name=$2
	save_location=$3
	response=$(curl -sI "https://web.archive.org/save/$url")

	echo "$response" >> log.txt
	echo "-------------------------------" >> log.txt

	response_status=$(echo "$response" | grep 'HTTP/2' | tail -c +8 | tr -d '\r')
	if [ "$response_status" -eq 302 ]; then # Successfull archive response

		# Obtain original image URL
		archive_url=$(echo "$response" | grep '^location:' | tail -c +11 | tr -d '\r')
		webpage=$(curl "$archive_url")
		img_archive_src=$(echo "$webpage" | grep "main-product-image" | sed -n 's/.*data-src-zoom-image="\([^"]*\)".*/\1/p')
		img_org_src=$(echo "$img_archive_src" | sed 's|https://web.archive.org/.*\(https://i.etsystatic.com/.*\)|\1|')
		img_ext="${img_org_src##*.}"

		curl "$img_org_src" -o "$save_location/$name.$img_ext"

		# Convert image format if needed	
		if [[ "$img_ext" != "png" ]] && [[ "$img_ext" != "jpg" ]]; then
			magick "$save_location/$name.$img_ext" "$save_location/$name.png"
		fi

	else # Failed to archive page
		notify-send "Bad response from archive.org"
	fi
}


if [ ! -d "$base_dir" ]; then
	mkdir "$base_dir"
fi


while true; do
	
	text_with_icons="Add New\0icon\x1f$base_dir/plus_icon.png\n"
	

	if find "$current_dir" -maxdepth 1 -name "rofi_theme.rasi" -print -quit | grep -q .; then
    		ROFI_THEME="custom"
	else
    		ROFI_THEME="system"
	fi


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
	
	text_with_icons+="Create New Category\0icon\x1f$base_dir/add_directory.png"


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
		if [ "$selection" == "Add New" ]; then
			# Add new item
			new_bookmark_url=$(rofi -dmenu -p "Enter bookmark URL")
			new_bookmark_name=$(rofi -dmenu -p "Enter bookmark Name")
			if [ -n "$new_bookmark_url" ] && [ -n "$new_bookmark_name" ]; then
				archive_downloader "$new_bookmark_url" "$new_bookmark_name" "$current_dir" &
				echo "$new_bookmark_url" >> "$current_dir/$new_bookmark_name.txt"
			else
				notify-send "Input fields left blank"
			fi

		elif [ "$selection" == "Create New Category" ]; then
			# Create new category (directory)
			new_category_name=$(rofi -dmenu -p "New Category Name")
			new_category_path="$current_dir/$new_category_name"
			if [ -n "$new_category_name" ] && [ ! -d "$new_category_path" ]; then
				mkdir "$new_category_path"
				current_dir="$new_category_path"
			else
				notify-send "Failed to create new category"
			fi

		elif [ -d "$current_dir/$selection" ]; then
			# Open selected directory
			current_dir="$current_dir/$selection"

		else 
			# Open bookmark in the default browser
			xdg-open $(cat "$current_dir/$selection.txt")
			break;
		fi
	fi
done
