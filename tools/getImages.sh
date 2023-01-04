#!/bin/bash

mkdir -p images

cfiles=("C10W.png" "C11W.png" "C12W.png" "C13.png" "C14.png" "C14W.png" "C15.png" "C16W.png" "C17W.png" "C18W.png" "C19W.png" "C1W.png" "C20W.png" "C21.png" "C22W.png" "C23W.png" "C24W.png" "C25W.png" "C26W.png" "C27W.png" "C28W.png" "C29W.png" "C2W.png" "C3.png" "C4.png" "C5W.png" "C6W.png" "C7W.png" "C8.png" "C9W.png")
dfiles=("D1.png" "D10.png" "D11.png" "D13.png" "D14.png" "D15.png" "D16.png" "D17.png" "D18.png" "D19.png" "D2.png" "D20.png" "D21.png" "D22.png" "D24.png" "D25.png" "D3.png" "D4.png" "D5.png" "D6.png" "D7.png" "D9.png")

echo "Downloading files....."
for file in "${cfiles[@]}" "${dfiles[@]}"
do
    out="${file//W}"
    if [ ! -f "images/${out}" ]
    then
        url="https://github.com/s-macke/VoxelSpace/raw/master/maps/${file}"
        echo "   downloading ${file}"
        curl -LsSs "${url}" -o "images/${out}"
    fi
done

# Some files are shared so just copy them
cp images/D6.png images/D8.png
cp images/D11.png images/D12.png
cp images/D21.png images/D23.png
cp images/D18.png images/D26.png
cp images/D15.png images/D27.png
cp images/D25.png images/D28.png
cp images/D16.png images/D29.png

echo "Converting to size"
sips -Z 1024 images/*.png > /dev/null 2>&1

echo "Copying to Assets.XCAssets..."
for file in images/*; do 
    source="${file/images\/}"
    source="${source/.png}"

    assetFolder="../Voxel/Assets.xcassets/${source}.imageset"
    if [ ! -d "${assetFolder}" ]
    then
        mkdir "${assetFolder}"
        cp "${file}" "${assetFolder}/${source}.png"

        cat <<EOT >> "${assetFolder}/Contents.json"
{
  "images" : [
    {
      "filename" : "${source}.png",
      "idiom" : "universal",
      "scale" : "1x"
    },
    {
      "idiom" : "universal",
      "scale" : "2x"
    },
    {
      "idiom" : "universal",
      "scale" : "3x"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOT

    fi

done


