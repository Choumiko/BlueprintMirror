require "defines"

replaceableEntities = {
  inserter = {
    basic = "basic-inserter",
    fast  = "fast-inserter",
    smart = "smart-inserter",
    long = "long-handed-inserter"
  },
  assembler = {
    am1 = "assembling-machine-1",
    am2 = "assembling-machine-2",
    am3 = "assembling-machine-3"
  },
  belt = {
    basic = "basic-transport-belt",
    fast = "fast-transport-belt",
    express = "express-transport-belt"
  },
  underground = {
    basic = "basic-transport-belt-to-ground",
    fast = "fast-transport-belt-to-ground",
    express = "express-transport-belt-to-ground"
  },
  splitter = {
    basic = "basic-splitter",
    fast = "fast-splitter",
    express = "express-splitter"
  }
}
function initGui(player)
  if not player.force.technologies["automated-construction"].researched then
    return
  end

  if not player.gui.top["blueprintMirror-button"] then
    player.gui.top.add{type="button", name="blueprintMirror-button", caption="BPmirror"}
  end
end
function expandGui(player)
  local frame = player.gui.left["blueprintMirror"];
  if (frame) then
    frame.destroy();
  else
    frame = player.gui.left.add{type="frame", name="blueprintMirror"}
    frame.add{type="button", name="blueprintMirror-h", caption="horizontal"}
    frame.add{type="button", name="blueprintMirror-v", caption="vertical"}
  end
end
game.oninit(function()
  for _, player in pairs(game.players) do
    initGui(player, false)
  end
end)
game.onload(function()
  for _, player in pairs(game.players) do
    initGui(player, false)
  end
end)

game.onevent(defines.events.onplayercreated, function(event)
  initGui(game.players[event.playerindex], false)
end)

game.onevent(defines.events.onresearchfinished, function(event)
  if (event.research == "automated-construction") then
    for _, player in pairs(game.players) do
      initGui(player, true)
    end
  end
end)

game.onevent(defines.events.onguiclick, function(event) 
  local player = game.players[event.element.playerindex]
  if (event.element.name == "blueprintMirror-h") then
    remote.call("bpmirror", "mirrorH", player.name)
  elseif (event.element.name == "blueprintMirror-v") then
    remote.call("bpmirror", "mirrorV", player.name)
  elseif (event.element.name == "blueprintMirror-button") then
    expandGui(player)
  end
end)

BpMirror = {
  findBlueprintsInHotbar = function(player)
    local blueprints = {}
    if player ~= nil then
      local hotbar = player.getinventory(1)
      if hotbar ~= nil then
        local i = 1
        while (i < 30) do
          local itemStack
          if pcall(function () itemStack = hotbar[i] end) then
            if itemStack ~= nil and itemStack.type == "blueprint" then
              table.insert(blueprints, itemStack)
            end
            i = i + 1
          else
            i = 100
          end
        end
      end
    end
    return blueprints
  end,

  findSetupBlueprintInHotbar = function(name)
    local player = getPlayerByName(name)
    local blueprints = BpMirror.findBlueprintsInHotbar(player)
    if blueprints ~= nil then
      for i, blueprint in ipairs(blueprints) do
        if blueprint.isblueprintsetup() then
          return blueprint
        end
      end
    end
  end,
}

function debugDump(var, force)
  if false or force then
    for i,player in ipairs(game.players) do
      local msg
      if type(var) == "string" then
        msg = var
      else
        msg = serpent.dump(var, {name="var", comment=false, sparse=false, sortkeys=true})
      end
      player.print(msg)
    end
  end
end
function saveVar(var, name)
  local var = var or glob
  local n = name or ""
  game.makefile("bp/bp"..n..".lua", serpent.block(var, {name="glob"}))
  --game.makefile("farl/loco"..n..".lua", serpent.block(findAllEntitiesByType("locomotive")))
end

function mirror(entities, axis)
  local dirs = {x ={0,4},y={2,6}}
  for _,ent in pairs(entities) do
    ent.position[axis] = -1 * ent.position[axis]
    if ent.direction and ent.direction ~= dirs[axis][1] and ent.direction ~= dirs[axis][2] then
      ent.direction = (ent.direction+4)%8
    end
  end
  return entities
end

function getPlayerByName(name)
  if not name and #game.players > 1 then
    for id, player in pairs(game.players) do
      player.print("Use /c remote.call(\"bpmirror\", \"mirrorV\", \""..player.name.."\")")
    end
    return false
  end
  local id = 1
  if name then
    for pid, player in pairs(game.players) do
      if name == player.name then
        id = pid
        break
      end
    end
  end
  return game.players[id]
end

function replace(entities, type, s, r)
  local n = entities
  if not replaceableEntities[type] then
    return "Unknown type: "..type
  end
  if not replaceableEntities[type][s] then
    return "Unknown "..type.." "..s
  end
  if not replaceableEntities[type][r] then
    return "Unknown "..type.." "..r
  end
  local s = replaceableEntities[type][s]
  local r = replaceableEntities[type][r]
  for _,ent in pairs(n) do
    if ent.name == s then
      ent.name = r
    end
  end
  return n
end

function changeRecipe(entities, s, r)
  for _,ent in pairs(n) do
    if ent.recipe and ent.recipe == s then
      ent.recipe = r
    end
  end
  return n
end

function globalPrint(msg)
  for _,p in pairs(game.players) do
    p.print(msg)
  end
end

function printByName(name, msg)
  for _,p in pairs(game.players) do
    if p.name == name then
      p.print(msg)
      return
    end
  end
  game.players[1].print(msg)
end

function getMirroredRecipes(force)
  local mirrored = {}
  for i,recipe in pairs(force.recipes) do
    if  (type(recipe.ingredients) == "table" and recipe.ingredients[1] and recipe.ingredients[1].type) or
      (type(recipe.products) == "table" and recipe.products[1] and recipe.products[1].type) then
      local keysIng = {}
      local keysRes = {}
      if recipe.ingredients and recipe.ingredients[1].type then
        for j, ingredient in pairs(recipe.ingredients) do
          if ingredient.type == defines.recipe.materialtype.fluid then
            table.insert(keysIng, j)
          end
        end
      end
      if recipe.products and recipe.products[1].type then
        for j, result in pairs(recipe.products) do
          if result.type == defines.recipe.materialtype.fluid then
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

function mirrorRecipes(entities, recipes)
  for _, ent in pairs(entities) do
    if ent.recipe and recipes[ent.recipe] then
      if endsWith(ent.recipe, "-mirrored") then
        ent.recipe = string.sub(ent.recipe,1,string.len(ent.recipe)-9)
        --debugDump(ent.recipe,true)
      else
        ent.recipe = ent.recipe.."-mirrored"
      end
    end
  end
  return entities
end

remote.addinterface("bpmirror",
  {
    mirrorV = function(name)
      local player = getPlayerByName(name)
      if player then
        local force = player.force
        local bp = BpMirror.findSetupBlueprintInHotbar(name)
        if bp then
          local mir = mirror(bp.getblueprintentities(), "y")
          mir = mirrorRecipes(mir, getMirroredRecipes(force))
          bp.setblueprintentities(mir)
        end
      end
    end,

    mirrorH = function(name)
      local player = getPlayerByName(name)
      if player then
        local force = player.force
        local bp = BpMirror.findSetupBlueprintInHotbar(name)
        if bp then
          local mir = mirror(bp.getblueprintentities(), "x")
          mir = mirrorRecipes(mir, getMirroredRecipes(force))
          bp.setblueprintentities(mir)
        end
      end
    end,

    replaceBelts = function(s,r, name)
      local belts = {"belt", "underground", "splitter"}
      local bp = BpMirror.findSetupBlueprintInHotbar(name)
      if bp then
        local new = bp.getblueprintentities()
        for _,t in pairs(belts) do
          new = replace(new,t,s,r)
          if type(new) == "table" then
            bp.setblueprintentities(new)
          else
            printByName(name,new)
          end
        end
      else
        printByName(name,"No blueprint found")
      end
    end,

    replaceInserters = function(s,r,name)
      local bp = BpMirror.findSetupBlueprintInHotbar(name)
      local ent = bp.getblueprintentities()
      local new = replace(ent,"inserter",s,r)
      if type(new) == "table" then
        bp.setblueprintentities(new)
      else
        printByName(name,new)
      end
    end,

    replaceAssemblers = function(s,r,name)
      local bp = BpMirror.findSetupBlueprintInHotbar(name)
      local ent = bp.getblueprintentities()
      local new = replace(ent,"assembler",s,r)
      if type(new) == "table" then
        bp.setblueprintentities(new)
      else
        printByName(name,new)
      end
    end,

    addEntity = function(type, key, name)
      local reserved = {belt={"basic", "fast", "express"}}
      reserved.underground = reserved.belt
      reserved.splitter = reserved.belt
      reserved.assembler = {"am1", "am2", "am3"}
      reserved.inserter = {"basic", "fast", "smart", "long"}
      for _,k in pairs(reserved[type]) do
        if k == key then
          globalPrint(key.." is reserved for type "..type)
          return
        end
      end
      replaceableEntities[type][key] = name
    end,

    saveBP = function(name)
      saveVar(BpMirror.findSetupBlueprintInHotbar(name).getblueprintentities())
    end
  })
