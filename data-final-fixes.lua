--for name,list in pairs(data.raw) do
--  for index,item in pairs(list) do
--    if item.max_health then
--      if type(item.attack_reaction) ~= "table" then
--        item.attack_reaction = {damage_trigger, attacker_trigger}
--      else
--        table.insert(item.attack_reaction, damage_trigger)
--        table.insert(item.attack_reaction, attacker_trigger)
--      end
--    end
--  end
--end
local mirrored = {}
for i,list in pairs(data.raw) do
  for name, recipe in pairs(list) do
    if recipe.type == "recipe" and (recipe.ingredients and recipe.ingredients[1].type) or (recipe.results and recipe.results[1].type) then 
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
        mirroredRecipe.name = mirroredRecipe.name.."-mirrored"
        mirroredRecipe.enabled = "true"
        if #keysIng > 1 then
          local ing = {}
          for m=#mirroredRecipe.ingredients,1,-1 do
            table.insert(ing, mirroredRecipe.ingredients[m])
          end
          mirroredRecipe.ingredients = ing
        end
        if #keysRes > 1 then
          local res = {}
          for m=#mirroredRecipe.results,1,-1 do
            table.insert(res, mirroredRecipe.results[m])
          end
          mirroredRecipe.results = res
        end
        --error(serpent.dump(mirroredRecipe))
        table.insert(mirrored, mirroredRecipe)
      end
    end
  end
end
data:extend(mirrored)