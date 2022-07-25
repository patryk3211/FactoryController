local module = {}

local recipes = {}

function module.load()
    local files = fs.list(shell.resolve("recipes"))
    for i, file in ipairs(files) do
        print("Loading recipe '"..file.."'")

        local id = file:match("([%w_]+)%.%a+")
        local recipe = { name = id, actions = {} }
        for line in io.lines(shell.resolve("recipes/"..file)) do
            local key, value = string.match(line, "([%w_]+)=([%w_]+)")
            if key ~= nil then
                -- Special entry
                recipe[key] = value
            else
                recipe.actions[#recipe.actions+1] = line
            end
        end

        recipes[id] = recipe
    end
end

function module.recipes()
    return recipes
end

return module
