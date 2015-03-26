
function getMirroredRecipes(force)
  local mirrored = {}
  for i,recipe in pairs(force.recipes) do
    if  (type(recipe.ingredients) == "table" and recipe.ingredients[1] and recipe.ingredients[1].type) or
      (type(recipe.products) == "table" and recipe.products[1] and recipe.products[1].type) then
      local keysIng = {}
      local keysRes = {}
      if recipe.ingredients and recipe.ingredients[1].type then
        for j, ingredient in pairs(recipe.ingredients) do
          if ingredient.type == 1 then
            table.insert(keysIng, j)
          end
        end
      end
      if recipe.products and recipe.products[1].type then
        for j, result in pairs(recipe.products) do
          if result.type == 1 then
            table.insert(keysRes, j)
          end
        end
      end
      if #keysIng > 1 or #keysRes > 1 then
        mirrored[recipe.name] = true
      end
    end
  end
  return mirrored
end

function endsWith(s, e)
  return e=='' or string.sub(s,-string.len(e))==e
end

for _, force in pairs(game.forces) do
  force.resetrecipes()
  force.resettechnologies()
  local recipes = getMirroredRecipes(force)
  for k,r in pairs(recipes) do
    if not endsWith(k,"-mirrored") then
      if force.recipes[k].enabled then
        force.recipes[k.."-mirrored"].enabled = true
      end
    end
  end 
end