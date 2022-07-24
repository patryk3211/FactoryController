echo "local files = {" > install_full.lua

for f in $(find src -type f); do
    printf "    %s = \"%s\",\n" $(basename $f .lua) $(base64 $f | tr -d '\n') >> install_full.lua
done

echo "}" >> install_full.lua

cat install.lua >> install_full.lua
