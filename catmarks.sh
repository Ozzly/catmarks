#!/usr/bin/env bash

shopt -s globstar nullglob

base_dir="$HOME/catmarks"
current_dir="$base_dir"
auto_download_thumbnails=1
rofi_new_bookmark_option=1
rofi_new_category_option=1
notifications=1

while [[ $# -gt 0 ]]; do
        case $1 in
                --base-directory | -f) base_dir="$2"; shift 2 ;;
                --disable-download-thumbnails | -d) auto_download_thumbnails=0; shift ;;
                --custom-rofi-path | -r) custom_rofi_path="$2"; shift 2 ;;
                --disable-rofi-new-bookmark-option | -b) rofi_new_bookmark_option=0; shift ;;
                --disable-rofi-new-category-option | -c) rofi_new_category_option=0; shift ;;
                --disable-notifications | -n) notifications=0; shift ;;
        esac
done


image_downloader(){
	url=$1
	name=$2
	save_location=$3

	# Youtube doesn't require the bypass method to download thumbnails
	if [[ "$url" == *"youtube.com"* ]]; then
		video_id=$(echo "$url" | sed -nE 's#.*(v=|youtu\.be/)([A-Za-z0-9_-]{11}).*#\2#p') # Sed expression generated with AI, don't ask me
		curl "i.ytimg.com/vi/$video_id/maxresdefault.jpg" -o "$save_location/$name.jpg"

	else # Use the internet archive to bypass bot restrictions on websites
		response=$(curl -sI "https://web.archive.org/save/$url")

		response_status=$(echo "$response" | grep 'HTTP/2' | tail -c +8 | tr -d '\r')
		if [ "$response_status" -eq 302 ]; then # Successfull archive response

			# Obtain original image URL
			archive_url=$(echo "$response" | grep '^location:' | tail -c +11 | tr -d '\r')
			webpage=$(curl "$archive_url")
			
			if [[ "$url" == *"etsy.com"* ]]; then
				img_archive_src=$(echo "$webpage" | grep "main-product-image" | sed -n 's/.*data-src-zoom-image="\([^"]*\)".*/\1/p')
				img_src=$(echo "$img_archive_src" | sed 's|https://web.archive.org/.*\(https://i.etsystatic.com/.*\)|\1|')
				img_ext="${img_src##*.}"

			elif [[ "$url" == *"ebay.co.uk"* ]]; then
                                img_src=$(echo "$webpage" | grep "window.heroImg =" | sed -E 's|.*"(https://web.archive.org/.*/(https://i\.ebayimg\.com[^"]+))".*|\2|') # Also AI regex for sed
				img_ext="${img_src##*.}"
				
			else
				[[ "$notifications" -eq 1 ]] && notify-send "Website not yet supported"
				break
			fi
			
			# Download image
			curl "$img_src" -o "$save_location/$name.$img_ext"
			# Convert image format if needed	
			if [[ -n "$img_ext" ]] && [[ "$img_ext" != "png" ]] && [[ "$img_ext" != "jpg" ]]; then
				magick "$save_location/$name.$img_ext" "$save_location/$name.png"
			fi

		else # Failed to archive page
			[[ "$notifications" -eq 1 ]] && notify-send "Bad response from archive.org"
		fi

	fi

}


# Create base directory if nonexistent
if [ ! -d "$base_dir" ]; then
	mkdir "$base_dir"
fi


while true; do
        rofi_cmd=(rofi -dmenu)
        text_with_icons=""

        # Building the rofi command based on theme settings
        if [[ -n "$custom_rofi_path" && -f "$custom_rofi_path" ]]; then
                rofi_cmd+=(-theme "$custom_rofi_path")

	elif find "$current_dir" -maxdepth 1 -name "rofi_theme.rasi" -print -quit | grep -q .; then
                rofi_cmd+=(-show-icons -theme "$current_dir/rofi_theme.rasi")
        fi


        # Generate rofi input
        [[ "$rofi_new_bookmark_option" -eq 1 ]] && text_with_icons+="New Bookmark\0icon\x1f$base_dir/plus_icon.png\n"

	for file in "$current_dir"/*; do
		[ -e "$file" ] || continue
                name_ext=$(basename "$file")
                name="${name_ext%.*}"

		if [ -d "$file" ]; then
                        child_image=$(find "$file" -maxdepth 2 -iregex ".*\.\(jpg\|png\)" -print -quit)
                        [[ -e "$child_image" ]] && text_with_icons+="$name\0icon\x1fthumbnail://$child_image\n"

                elif [[ "$file" == *.txt ]]; then # Bookmark
			if [ -e "$current_dir/$name.png" ]; then  
				text_with_icons+="$name\0icon\x1fthumbnail://$current_dir/$name.png\n" 
			elif [ -e "$current_dir/$name.jpg" ]; then  
				text_with_icons+="$name\0icon\x1fthumbnail://$current_dir/$name.jpg\n" 
			else 
				text_with_icons+="$name\n"
			fi
		fi
	done

	[[ "$rofi_new_category_option" -eq 1 ]] && text_with_icons+="Create New Category\0icon\x1f$base_dir/add_directory.png"


	# Display rofi prompt, get exit code for keybind responses
        selection=$(echo -en "$text_with_icons" | "${rofi_cmd[@]}" )
	exit_code=$?

	# Exit the script
	if [ "$exit_code" -eq 1 ]; then
		break

	# Select entry
	elif [ "$exit_code" -eq 0 ]; then
		if [ "$selection" == "New Bookmark" ]; then
			# Add new item
			new_bookmark_url=$(rofi -dmenu -p "Enter bookmark URL")
			new_bookmark_name=$(rofi -dmenu -p "Enter bookmark Name")
			if [ -n "$new_bookmark_url" ] && [ -n "$new_bookmark_name" ]; then
                                [[ "$auto_download_thumbnails" -eq 1 ]] && image_downloader "$new_bookmark_url" "$new_bookmark_name" "$current_dir" &
				echo "$new_bookmark_url" >> "$current_dir/$new_bookmark_name.txt"
			else
				[[ "$notifications" -eq 1 ]] && notify-send "Input fields left blank"
			fi
			break

		elif [ "$selection" == "Create New Category" ]; then
			# Create new category (directory)
			new_category_name=$(rofi -dmenu -p "New Category Name")
			new_category_path="$current_dir/$new_category_name"
			if [ -n "$new_category_name" ] && [ ! -d "$new_category_path" ]; then
				mkdir "$new_category_path"
				current_dir="$new_category_path"
			else
				[[ "$notifications" -eq 1 ]] && notify-send "Failed to create new category"
			fi

		elif [ -d "$current_dir/$selection" ]; then
			# Open selected directory
			current_dir="$current_dir/$selection"

		else 
			# Open bookmark in the default browser
			xdg-open "$(cat "$current_dir/$selection.txt")"
			break;
		fi
	else
                [[ "$notifications" -eq 1 ]] && notify-send "Invalid exit code"
                break;
        fi
done
