require "defines"

function initGlob()
  glob.settings = glob.settings or {}
  for _, player in pairs(game.players) do
    initGui(player, false)
  end
end

function initGui(player)
  if glob.settings[player.name] == nil then
    glob.settings[player.name] = true
  end
  if not player.force.technologies["automated-construction"].researched then
    return
  end

  if not player.gui.top["blueprintMirror-button"] and glob.settings[player.name] then
    player.gui.top.add{type="button", name="blueprintMirror-button", caption="BPmirror"}
  end
end

function expandGui(player)
  local frame = player.gui.left["blueprintMirror"];
  if (frame) then
    frame.destroy();
  else
    frame = player.gui.left.add{type="frame", name="blueprintMirror"}
    frame.add{type="button", name="blueprintMirror-mirror", caption={"text-mirror"}}
    local tbl = frame.add{type="table", name="tbl", colspan=3}
    tbl.add{type="label", caption={"text-search"}}
    tbl.add{type="label", caption=" "}
    tbl.add{type="label", caption={"text-replace"}}
    for i=1,5 do
      tbl.add{type="label", name="bpm-search"..i, caption="click with item"}
      tbl.add{type="label", caption=" "}
      tbl.add{type="label", name="bpm-replace"..i,  caption="click with item"}
    end
    tbl.add{type="button", name="blueprintMirror-replaceBtn", caption={"text-replace"}}
  end
end

game.oninit(function()
  initGlob()
end)

game.onload(function()
  initGlob()
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

  findSetupBlueprintInHotbar = function(player)
    local blueprints = BpMirror.findBlueprintsInHotbar(player)
    if blueprints ~= nil then
      for i, blueprint in ipairs(blueprints) do
        if blueprint.isblueprintsetup() then
          return blueprint
        end
      end
    end
  end,

  findEmptyBlueprintInHotbar = function(player)
    local blueprints = BpMirror.findBlueprintsInHotbar(player)
    if blueprints ~= nil then
      for i, blueprint in ipairs(blueprints) do
        if not blueprint.isblueprintsetup() then
          return blueprint
        end
      end
    end
  end
}

game.onevent(defines.events.onguiclick, function(event)
  local player = game.players[event.element.playerindex]
  local element = event.element
  if element.name == "blueprintMirror-mirror" then
    remote.call("bpmirror", "mirror", player.name)
    expandGui(player)
  elseif startsWith(element.name, "bpm-search") or startsWith(element.name, "bpm-replace") then
    local item = player.cursorstack and player.cursorstack.name or false
    if item then
      element.caption = item
    else
      element.caption = "click with item"
    end
    return
  elseif element.name == "blueprintMirror-replaceBtn" then
    local rep = {}
    local tbl = player.gui.left.blueprintMirror.tbl
    local bp = BpMirror.findSetupBlueprintInHotbar(player)
    local bpEmpty = BpMirror.findEmptyBlueprintInHotbar(player)
    if bp and bpEmpty then
      local ent = bp.getblueprintentities()
      for i=1,5 do
        local s = "-search"..i
        local r = "-replace"..i
        local tmp = {}
        for _,name in pairs(tbl.childrennames) do
          if name ~= "" and startsWith(name, "bpm-search") or startsWith(name, "bpm-replace") then
            local child = tbl[name]
            if endsWith(name, s)  and child.caption ~= "click with item" then
              tmp.s = child.caption
            end
            if endsWith(name, r) and child.caption ~= "click with item" then
              tmp.r = child.caption
            end
          end
        end
        if tmp.s and tmp.r then
          rep[i] = {s=tmp.s, r=tmp.r}
        end
      end
      for type, list in pairs(rep) do
        ent = replaceRaw(ent,list.s,list.r)
        --debugDump({game.localise(list.s),game.getlocalisedentityname(list.r)},true)
        --local txt = {"", }
        --player.print("Replaced "..game.localise(game.getlocalisedentityname(list.r)[1]))
      end
      bpEmpty.setblueprintentities(ent)
      bpEmpty.blueprinticons = bp.blueprinticons
      --debugDump(rep,true)
      player.print("Replaced entities")
      expandGui(player)
      return
    else
      if not bp then
        player.print("No blueprint found")
        return
      end
      if not bpEmpty then
        player.print("No empty blueprint found")
        return
      end
    end
  elseif element.name == "blueprintMirror-button" then
    expandGui(player)
  else
    debugDump(element.name,true)
  end
end)

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

function replaceRaw(entities, s, r)
  for _,ent in pairs(entities) do
    if ent.name == s then
      ent.name = r
    end
  end
  return entities
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
  return replaceRaw(entities,s,r)
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

function startsWith(s, e)
  return e == string.sub(s, 1, string.len(e))
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
    createLocale = function()
      local rec = {}
      local str = "[recipe-name]\n"
      for _,force in pairs(game.forces) do
        local r = getMirroredRecipes(force)
        for name, v in pairs(r) do
          if endsWith(name, "-mirrored") then
            rec[name] = game.localise(string.sub(name,1,string.len(name)-9))
          end
        end
      end
      debugDump(rec,true)
    end,

    mirror = function(name)
      local player = getPlayerByName(name)
      if player then
        local force = player.force
        local bp = BpMirror.findSetupBlueprintInHotbar(player)
        if bp then
          local mir = mirror(bp.getblueprintentities(), "x")
          mir = mirrorRecipes(mir, getMirroredRecipes(force))
          bp.setblueprintentities(mir)
        else
          player.print("No blueprint found")
        end
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

    toggleUI = function(name)
      local player = getPlayerByName(name)
      if glob.settings[player.name] == nil then
        glob.settings[player.name] = true
      end
      glob.settings[player.name] = not glob.settings[player.name]
      if not glob.settings[player.name] then
        local topui = player.gui.top["blueprintMirror-button"]
        local leftui = player.gui.left.blueprintMirror
        if leftui then
          leftui.destroy()
        end
        if topui then
          topui.destroy()
        end
        player.print("UI disabled")
      else
        player.print("UI enabled")
      end
      initGui(player)
    end,

    saveBP = function(name)
      local player = getPlayerByName(name)
      saveVar(BpMirror.findSetupBlueprintInHotbar(player).getblueprintentities())
    end
  })
