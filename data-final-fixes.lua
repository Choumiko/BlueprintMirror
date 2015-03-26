
function reverseTable(t)
  local rev = {}
  for i=#t,1,-1 do
    table.insert(rev, t[i])
  end
  return rev
end

function inTable(s, t)
  for k, v in pairs(t) do
    if v == s then
      return k
    end
  end
  return false
end

data:extend({
{
  type = "item-subgroup",
  name = "mirrored",
  group = "other",
  order = "x"
}
})

local mirrored = {}
local original = {}

for i,recipe in pairs(data.raw["recipe"]) do
    if  (type(recipe.ingredients) == "table" and recipe.ingredients[1] and recipe.ingredients[1].type) or 
        (type(recipe.results) == "table" and recipe.results[1] and recipe.results[1].type) then 
      local keysIng = {}
      local keysRes = {}
      if recipe.ingredients and recipe.ingredients[1].type then
        for j, ingredient in pairs(recipe.ingredients) do
          if ingredient.type == "fluid" then
            table.insert(keysIng, j)
          end
        end
      end
      if recipe.results and recipe.results[1].type then
        for j, result in pairs(recipe.results) do
          if result.type == "fluid" then
            table.insert(keysRes, j)
          end
        end
      end
      if #keysIng > 1 or #keysRes > 1 then
        local mirroredRecipe = util.table.deepcopy(recipe)
        table.insert(original, recipe.name)
        mirroredRecipe.name = mirroredRecipe.name.."-mirrored"
        mirroredRecipe.subgroup = "mirrored"
        if #keysIng > 1 then
          mirroredRecipe.ingredients = reverseTable(mirroredRecipe.ingredients)
        end
        if #keysRes > 1 then
          mirroredRecipe.results = reverseTable(mirroredRecipe.results)
        end
        table.insert(mirrored, mirroredRecipe)
      end
    end
end

data:extend(mirrored)

for i, tech in pairs(data.raw["technology"]) do
  if type(tech.effects) == "table" then
    local add = {}
    for _, eff in pairs(tech.effects) do
      local k = inTable(eff.recipe,original)
      if eff.type == "unlock-recipe" and k then
        table.insert(add, {type="unlock-recipe", recipe=eff.recipe.."-mirrored"})
      end
    end
    for _, eff in pairs(add) do
      table.insert(tech.effects, eff)
    end
  end
end