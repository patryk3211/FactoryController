printf "local files = {" > install_full.lua

for f in $(find src -type f); do
    printf "    %s = \"%s\"," $(basename $f .lua) $(base64 $f | tr -d '\n') >> install_full.lua
done

printf "}" >> install_full.lua

cat install_nohttp.lua | tr '\n' ' ' >> install_full.lua
