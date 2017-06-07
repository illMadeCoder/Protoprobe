pico-8 cartridge // http://www.pico-8.com
version 8
__lua__
framerate = 60
bullet_color = {}
bullet_color["a"] = 12
bullet_color["b"] = 9
bullet_color["c"] = 11
bullet_color.complement = {}
bullet_color.complement["a"] = 13
bullet_color.complement["b"] = 4
bullet_color.complement["c"] = 3
--[[
btn (i (p))
  get button i state for player p (default 0)
  i: 0..5: left right up down button_o button_x
  p: player index 0..7

  if no parameters supplied, returns a bitfield of all 12 button states for player 0 & 1
    // p0: bits 0..5  p1: bits 8..13

  default keyboard mappings to player buttons:
    player 0: cursors, z,x / c,v / n,m
    player 1: esdf, lshift,a / tab,q,e


colours indexes:
--color
  	 0  black   1  dark_blue   2  dark_purple   3  dark_green
  	 4  brown   5  dark_gray   6  light_gray    7  white
  	 8  red     9  orange     10  yellow       11  green
  	12  blue   13  indigo     14  pink         15  peach
]]--
--helpers
function empty()
end
function ceil(_x)
  if _x % 1 == 0 then
    return _x
  end
  return flr(_x+1)
end
function sign(_x)
  return _x > 0 and 1 or _x < 0 and -1 or 0
end
function round(_x)
  if _x % 1 == 0 then
    return _x
  elseif _x % 1 >= .5 then
    return sign(_x) == 1 and ceil(_x) or flr(_x)
  else
    return sign(_x) == 1 and flr(_x) or ceil(_x)
  end
end
function bool_to_str(_bool)
  return _bool and "true" or "false"
end
function str_to_num(_str)
  return _str + 0
end
function stringify_table(_table,_tab)
  local function num_to_tab(_num)
    local ret = ""
    for i=1,_num do
      ret = ret .. "    "
    end
    return ret
  end
  _table = _table or {}
  _tab = _tab or 0
  local ret = "\n" .. num_to_tab(_tab) .. "{\n"
  for k,v in pairs(_table) do
    if type(v) == "function" then
      ret = ret .. num_to_tab(_tab) .. k .. "=" .. k .. "()" .. '\n'
    elseif type(v) == "table" then
      ret = ret .. num_to_tab(_tab) .. k .. "=" .. stringify_table(v,_tab+1) .. '\n'
    elseif type(v) == "boolean" then
      ret = ret .. num_to_tab(_tab) .. k .. "=" .. bool_to_str(v) .. '\n'
    else
      ret = ret .. num_to_tab(_tab) .. k .. "=" .. v .. '\n'
    end
  end
  return ret .. num_to_tab(_tab) .. "}\n"
end
function split(_string,_split)
  --on empty strings return empty object
  if _string == "" or not _string then
    return {}
  end
  local ret = {}
  local cur = ""
  for i=1,#_string do
    local char = sub(_string,i,i)
    if char == _split then
      add(ret,cur)
      cur = ""
    else
      cur = cur .. char
    end
  end
  add(ret,cur)
  return ret
end
function cut(_string,_cut)
  local ret = ""
  local split = split(_string,_cut)
  for i=1,#split do
    ret = ret .. split[i]
  end
  return ret
end
function print_center(str,x,y,col)
  print(str,x+((4-#str*4)/2),y,col)
end
function exists(obj,search)
  for v in all(obj) do
    if v == search then
      return true
    end
  end
  return false
end
function in_range(_x,_a,_b)
  return _x >= _a and _x <= _b
end
function clamp(_x,_a,_b)
  return _x <= _a and _a or _x >= _b and _b or _x
end
function norm(_x,_min,_max)
  return (_x-_min)/(_max-_min)
end
function center(_start,_width)
  return _start-(_width/2)
end
--linear interporlation
function lerp(_min,_max,_t)
  return (_max-_min)*(_t <= 1 and _t or 1)+_min
end
--sin interporlation
function serp(_min,_max,_t)
  local sqt = t*t
  return lerp(_min,_max,sqt / (2 * (sqt - t) + 1))
end
function interval_intersect(_x1,_x2,_y1,_y2)
  return max(_x1,_y1) <= min(_x2,_y2)
end
function rect_intersect(_x1,_y1,_width1,_height1,_x2,_y2,_width2,_height2)
  return interval_intersect(_x1,_x1+_width1,_x2,_x2+_width2) and
  interval_intersect(_y1,_y1+_height1,_y2,_y2+_height2)
end
function set_to(_tablea,_tableb)
  --test
  for k,v in pairs(_tablea) do
    if type(_tableb[k]) != "table" then
      _tablea[k] = _tableb[k]
    else
      set_to(_tablea[k],_tableb[k])
    end
  end
end
--types
--rect
function new_rect(_x,_y,_width,_height)
  return {x=_x,y=_y,width=_width,height=_height}
end
--2d vector
vector = {}
vector.metatable = {}
function new_vector(_x,_y)
  local ret = {x=_x or 0,y=_y or 0}
  setmetatable(ret,vector.metatable)
  return ret
end
vector.metatable.__index = function(_table,_key)
  return vector.metatable[_key]
end
vector.metatable.__add = function(_a,_b)
  return new_vector(_a.x+_b.x,_a.y+_b.y)
end
vector.metatable.__sub = function(_a,_b)
  return new_vector(_a.x-_b.x,_a.y-_b.y)
end
vector.metatable.copy = function(_self)
  return new_vector(_self.x,_self.y)
end
vector.metatable.set = function(_self,_x,_y)
  _self.x,_self.y = _x or 0, _y or 0
end
vector.metatable.setto = function(_self,_other)
  _self:set(_other.x,_other.y)
end
vector.metatable.towhole = function(_self)
  _self:set(round(_self.x),round(_self.y))
end
vector.metatable.ceil = function(_self)
  _self:set(ceil(_self.x),ceil(_self.y))
end
vector.metatable.lerp = function(_self,_start,_end,_t)
  --linear interporlate between two points by some fraction _t, 0==_start,.5==vector between _start,_end,1==_end
  _self:set(lerp(_start.x,_end.x,_t),lerp(_start.y,_end.y,_t))
end
vector.metatable.movetowards = function(_self,_to,_speed)
  --moves a vector _self in the direction towards _to, _speed pixels
  _speed = _speed or 1
  if vector.approxequal(_self,_to,_speed) then
    _self:setto(_to)
  else
    _self:setto(_self + vector.scalarmult(vector.unit_towards(_self,_to),_speed))
  end
end
vector.animation = {}
vector.animation.movetoinframes = function(_self,_end,_framestoreachtarget)
  --linear interporlate between two points givin some count of frames
  local start,tick = new_vector(_self.x,_self.y),0

  local function update (_offset)
    _end += _offset or zero
    while tick/_framestoreachtarget < 1 do
      tick += 1
      _self:lerp(start,_end,tick/_framestoreachtarget)
      _end += yield() or zero
    end
  end

  return cocreate(update)
end
vector.animation.circularmotion = function(_self,_center,_speed)
  --[[
  circularmotion takes a position a center and a speed,
  given the position and center, find a vector dif from center to start_vec,
  use the magnitude of dif to find the circle radius, use the angle between the components of dif to find the start location on the circle,
  set the step to the appropriate starting location
  ]]--
  local dif = _center - _self
  local radius,step = vector.magnitude(dif), atan2(dif.x,dif.y)*framerate/_speed

  local function update(_end)
    while not _end do
      step += 1
      _self:set(-cos((step/framerate)*_speed)*radius + _center.x,-sin((step/framerate)*_speed)*radius + _center.y)
      _end = yield()
    end
  end

  return cocreate(update)
end

vector.scalarmult = function(_vec,_scalar)
  return new_vector(_vec.x*_scalar,_vec.y*_scalar)
end
vector.normalize = function(_vec)
  return new_vector(_vec.x/vector.magnitude(_vec),_vec.y/vector.magnitude(_vec))
end
vector.dot = function(_a,_b)
  return _a.x*_b.x+_a.y*_b.y
end
vector.inv = function(_a)
  return vector.scalarmult(_a,-1)
end
vector.magnitude = function(_vec)
  return sqrt(_vec.x*_vec.x + _vec.y*_vec.y)
end
vector.unit_towards = function(_from,_to)
  return vector.normalize(_to-_from)
end
vector.scale = function(_veca,_vecb)
  return new_vector(_veca.x*_vecb.x,_veca.y*_vecb.y)
end
vector.distance = function(_veca,_vecb)
  return vector.magnitude(_veca-_vecb)
end
vector.approxequal = function (_a,_b,_thresh)
  _thresh = _thresh or 1
  local dif = _a-_b
  return in_range(dif.x,-_thresh,_thresh) and in_range(dif.y,-_thresh,_thresh)
end
up = new_vector(0,-1)
down = new_vector(0,1)
left = new_vector(-1,0)
right = new_vector(1,0)
zero = new_vector(0,0)
--sprite
sprite = {}
sprite.metatable = {}
sprite.metatable.draw = function (_sprite,_position)
  spr(_sprite.n,_position.x+_sprite.x,_position.y+_sprite.y,_sprite.width,_sprite.height,_sprite.flipx,_sprite.flipy)
end
sprite.metatable.__index = function (_table,_key)
  return sprite.metatable[_key]
end
function new_sprite(n,x,y,width,height,flipx,flipy)
  local ret = {n=n or 0,x=x or 0, y = y or 0, width = width or 0, height = height or 0, flipx = flipx or false, flipy = flipy or false}
  setmetatable(ret,sprite.metatable)
  return ret
end

--hitbox/body
function new_hitbox(_x,_y,_width,_height,_name,_immaterial)
  return {
    x=_x or 0,
    y=_y or 0,
    width=_width or 0,
    height=_height or 0,
    name=_name or "",
    immaterial=_immaterial or false,
    collisions={}
  }
end
body = {}
body.metatable = {}
function new_body(_hitboxes,_collision)
  local ret = {hitboxes=_hitboxes or {},collision=_collision or empty}
  setmetatable(ret,body.metatable)
  return ret
end
body.metatable.draw = function(_self,_entity)
  for hitbox in all(_self.hitboxes) do
    if hitbox.width > 0 and hitbox.height > 0 then
      rect(_entity.position.x+hitbox.x,_entity.position.y+hitbox.y,_entity.position.x+hitbox.x+hitbox.width,_entity.position.y+hitbox.y+hitbox.height,11)
    end
  end
end
body.metatable.get_collisions = function(_self)
  local ret = {}
  for hitbox in all(_self.hitboxes) do
    if #hitbox.collision > 0 then
      add(ret,hitbox)
    end
  end
  return ret
end
body.metatable.clear_collisions = function(_self)
  for hitbox in all(_self.hitboxes) do
    hitbox.collisions = {}
  end
end
body.metatable.locate_hitbox = function(_self,_name)
  local ret = {}
  for hitbox in all(_self.hitboxes) do
    if hitbox.name == _name then
      add(ret,hitbox)
    end
  end
  return ret
end
body.metatable.__index = function(_table,_key)
  return body.metatable[_key]
end
--parse animation
function parse_sprite_frames(_comp_sprite_frames)
  --sprite frame format "n,x,y,w,h,flipx,flipy|...|n,x,y,w,h,flipx,flipy" all numbers
  local sprite_frames = {}
  local comp_sprites = split(_comp_sprite_frames,"|")
  for i=1,#comp_sprites do
    local sprite = split(comp_sprites[i],",")
    add(sprite_frames,new_sprite(sprite[1],sprite[2],sprite[3],sprite[4],sprite[5],sprite[6] == "1" and true or false,sprite[7] == "1" and true or false))
  end
  return sprite_frames
end
function parse_hitbox_frames(_comp_hitbox_frames)
  --hitbox frame format "x,y,w,h,name|..|x,y,w,h,name" all numbers
  local hitbox_frames = {}
  local comp_hitboxes = split(_comp_hitbox_frames,"|")
  for i=1,#comp_hitboxes do
    local hitbox = split(comp_hitboxes[i],",")
    add(hitbox_frames,new_hitbox(hitbox[1],hitbox[2],hitbox[3],hitbox[4],hitbox[5]))
  end
  return hitbox_frames
end
function parse_displacement_frames(_comp_displacement_frames)
  --format "x,y|..|x,y"
  local displacement_frames = {}
  local comp_displacements = split(_comp_displacement_frames,"|")
  for i=1,#comp_displacements do
    local displacement = split(comp_displacements[i],",")
    add(displacement_frames,new_vector(displacement[1],displacement[2]))
  end
  return displacement_frames
end
function new_frame(_sprite,_hitbox,_displacement)
  return {sprite=_sprite,hitbox=_hitbox,displacement=_displacement}
end
function parse_compressed_frame(_compressed_string)
  --format: "compressed_sprite_frames/compressed_hitbox_frames/compressed_displacement_frames"
  local compressed_frames = split(_compressed_string,"/")
  return {parse_sprite_frames(compressed_frames[1]),parse_hitbox_frames(compressed_frames[2]),parse_displacement_frames(compressed_frames[3])}
end
function new_clip(_compressed_frames,_sample_rate,_callback,_length)
  --[[
  --clip consists of frames, who are built via parse_compressed_frame
  --and contain compressed_sprite frames, compressed_hitbox frames, and compressed displacement frames
  --a frame then contains the raw sprite,hitbox,and displacement which will be sampled
  --finally a clip may contain a _callback function that way on each sample frame a function can be called
  ]]--
  local parsed_frames = parse_compressed_frame(_compressed_frames)
  local frames,
  sprite_frames,
  hitbox_frames,
  displacement_frames =
  {},
  parsed_frames[1],
  parsed_frames[2],
  parsed_frames[3]

  local length = _length or max(max(#sprite_frames,#hitbox_frames),#displacement_frames)
  for i=1,length do
    add(frames,new_frame(sprite_frames[i],hitbox_frames[i],displacement_frames[i]))
  end
  return {frames=frames,sample_rate=_sample_rate,callback=_callback,length=length}
end
--animation
function new_animation(_clip,_sprite,_hitbox,_position,_callback_arg)
  --todo cleanup parse format, reduce tokens, make defaultable animation stuff
  local frame = _clip.sample_rate --frame must start on sample rate for animation to begin on frame 1
  local sample = 1

  local anim = function (_loop)
    while sample <= _clip.length do
      if sample % 1 == 0 then
        if _clip.frames[sample].sprite and _sprite then
          set_to(_sprite,_clip.frames[sample].sprite)
        end
        if _clip.frames[sample].hitbox and _hitbox then
          set_to(_hitbox,_clip.frames[sample].hitbox)
        end
        if _clip.frames[sample].displacement and _position then
          set_to(_position,new_vector(_position.x+_clip.frames[sample].displacement.x,_position.y+_clip.frames[sample].displacement.y))
        end
        if _clip.callback then
          _clip.callback(sample,_callback_arg)
        end
      end
      frame += 1
      sample = frame/_clip.sample_rate
      if sample >= _clip.length and _loop then
        frame = 0
      end
      yield()
    end
  end
  return cocreate(anim)
end

--entity
function new_entity(_name,_tag,_position,_update,_draw,_body,_model,_z)
  --[[an entity is a data structure meant to be used by the game to create some effect
  --an entity is defined by the following:
  --name is a string to identify the object in memory
  --vector is an object of the new_vector function to provide a spatial vector to the object
  --update is a function to be called each frame
  --draw is a function to be called each render
  --model is a table container for an entity's state
  --z is the z index to be drawn

  --if you want a 'start' function, a function to be called on the first frame of the entity's existense,
  --do a if (entity.frame == 0) check
  --]]
  return {
          name=_name or "noname",
          tag=_tag or {},
          position=_position or new_vector(),
          update=_update or empty,
          draw=_draw or empty,
          body=_body or new_body(),
          model=_model or {},
          z=_z or 0,
          frame=0
        }
end
function new_scene(_starting,_ending,_update,_draw,_late_update,_model)
--[[
--a scene is a manager for any particular segments of a game and should be used as a tool
--to control game state. each game runs an initial scene, and then from there a scene may
--transition via game.switch_scene(scene) where first the ending function of a scene will be called
--followed then by the new scene's starting() function.
-- game.active_scene is the current running scene
]]--
  return {
        starting=_starting or empty,
        ending=_ending or empty,
        update=_update or empty,
        draw=_draw  or empty,
        late_update=_late_update or empty,
        model=_model or {},
        frame=0
      }
end
--game
function new_game(_starting_scene)
    --sorry this looks bad, token saver.
    local
    active_scene, --_starting_scene
    entities, --{}
    game_camera, --{x=0,y=0,width=128,height=128}
    settings, --{show_hitboxes=true,entities_active=true}
    frame, --0
    started =  --false
    _starting_scene,
    {},
    {x=0,y=0,width=128,height=128},
    {show_hitboxes=false,entities_active=true,update_frame = 1},
    0,
    false

    local function entity_collision(_fentity,_sentity)
      for _fhitbox in all(_fentity.body.hitboxes) do
        for _shitbox in all(_sentity.body.hitboxes) do
          if not _fhitbox.immaterial and not _shitbox.immaterial and
          rect_intersect(_fentity.position.x+_fhitbox.x,_fentity.position.y+_fhitbox.y,_fhitbox.width,_fhitbox.height,_sentity.position.x+_shitbox.x,_sentity.position.y+_shitbox.y,_shitbox.width,_shitbox.height)
           then
            _fentity.body.collision(_fentity,_sentity,_fhitbox,_shitbox)
            _sentity.body.collision(_sentity,_fentity,_shitbox,_fhitbox)
            add(_fhitbox.collisions,{entity=_sentity,hitbox=_shitbox})
            add(_shitbox.collisions,{entity=_fentity,hitbox=_fhitbox})
          end
        end
      end
    end

    local function exists_in_camera(_vec,_thresh)
      --test
      _thresh = _thresh or 0
      return _vec.x+_thresh >= game_camera.x and _vec.x <= game_camera.x+game_camera.width+_thresh and
              _vec.y+_thresh >= game_camera.y and _vec.y <= game_camera.y+game_camera.height+_thresh
    end

    local function collision_update(_entities)
      for i=1,#_entities do
        _entities[i].body:clear_collisions()
        for j=i+1,#_entities do
          entity_collision(_entities[i],_entities[j])
        end
      end
    end

    local function rectcast(_rect)
      local ret = {}
      for entity in all(entities) do
        for hitbox in all(entity.body.hitboxes) do
          if rect_intersect(_rect, new_rect(entity.position.x+hitbox.x,entity.position.y+hitbox.y,hitbox.width,hitbox.height)) then
            add(ret,entity)
          end
        end
      end
      return ret
    end

    local function get_entities_on_camera(_thresh)
      local ret = {}
      _thresh = _thresh or 0
      for entity in all(entities) do
        if exists_in_camera(entity.position,_thresh) then
          add(ret,entity)
        end
      end
      return ret
    end
    --entity api
    local function add_entity(_entity)
      if type(_entity) == "table" and _entity.name != nil then
        add(entities,_entity)
      end
      return _entity
    end
    local function remove_entity(_entity)
      del(entities,_entity)
    end
    local function empty_entities()
      for k,v in pairs(entities) do entities[k] = nil end
      entities = {}
    end
    local function locate_entity_name(_name)
      local ret = {}
      for entity in all(entities) do
        if entity.name == _name then
          add(ret,entity)
        end
      end
      return ret
    end
    local function locate_entity_tag(_tag)
      local ret = {}
      for entity in all(entities) do
        if exists(entity.tags,_tag) then
          add(ret,entity)
        end
      end
      return ret
    end
    local function get_entities()
      return entities
    end
    --frame api
    local function update()
      --update scene
      active_scene.update()
      active_scene.frame += 1
      if settings.entities_active and frame % settings.update_frame == 0 then
        collision_update(entities)
        --update entities
        for entity in all(entities) do
          entity.update(entity)
          entity.frame += 1
        end
      end
      frame += 1
    end
    local function draw ()
      if frame % settings.update_frame == 0 then
        cls()
        camera(-game_camera.x,-game_camera.y)
        active_scene.draw()
        local function z_indexed()
          --test
          local ret,z_ordered,z_low,z_high = {},{},0,0
          for entity in all(entities) do
            if entity.z < z_low then
              z_low = entity.z
            end
            if entity.z > z_high then
              z_high = entity.z
            end
            if z_ordered[entity.z] == nil then
              z_ordered[entity.z] = {}
            end
            add(z_ordered[entity.z],entity)
          end
          for i=z_low,z_high do
            for entity in all(z_ordered[i]) do
              add(ret,entity)
            end
          end
          return ret
        end
        for entity in all(z_indexed()) do
          entity.draw(entity)
          if settings.show_hitboxes == true then
            entity.body:draw(entity)
          end
        end
      end
    end
    return {
            get_frame = function()
              return frame
            end,
            start = function()
              if started == false then
                active_scene.starting()
                started = true
              end
            end,
            update=update,
            draw=draw,
            switch_scene=function(scene)
              active_scene.ending()
              active_scene = scene
              active_scene.starting()
            end,
            add_entity=add_entity,
            remove_entity=remove_entity,
            empty_entities=empty_entities,
            rectcast=rectcast,
            locate_entity_name=locate_entity_name,
            locate_entity_tag=locate_entity_tag,
            get_entities=get_entities,
            get_entities_on_camera=get_entities_on_camera,
            exists_in_camera=exists_in_camera,
            camera=game_camera,
            active_scene=active_scene,
            pause = function()
              settings.entities_active = false
            end,
            unpause = function()
              settings.entities_active = true
            end
            }
end

entity_table = {}
--bullet_manager
entity_table.bullet_manager =
function (_rails,_comp_bullet_pattern,_player)
  local bullet_pool,tempo,speed = {},8,1
  local sprites = {a=64,b=80,c=96}
  local w,h = 8,6
  local parsed_bullet_pattern = split(_comp_bullet_pattern,',')
  local running_distance = 0
  local endings = {new_vector(_rails[1].position.x,126),new_vector(_rails[2].position.x,126)}
  --parse bullet string to objects
  for i=1,#parsed_bullet_pattern do
    local row = parsed_bullet_pattern[i]
    local split = split(parsed_bullet_pattern[i],"|")
    if sub(row,1,1) == ">" then
      --tempo set
      tempo = cut(split[1],">")
      speed = split[2]
    else
      --bullet row
      for j=1, #split do
        if split[j] != "" then
          local x = flr((_rails[1].position.x-_rails[2].position.x)/2)
          if j == 1 then
            x = _rails[1].position.x
          elseif j == 3 then
            x = _rails[2].position.x
          end
          add(bullet_pool,new_hitbox(x-flr(w/2),running_distance,w-1,h-1,split[j]))
        end
      end
      running_distance -= str_to_num(tempo)
    end
  end
  local gib_pool = {}
  local gib_anim = function(_position,_end_position,_color,_comp_color,_capture)
    local frame = 0
    local start = new_vector(_position.x,_position.y)
    local size = 4
    local anim = function ()
      while frame <= 10 do
        if _capture then
          _position:lerp(start,_end_position,frame/10)
          circfill(_position.x+w/2,_position.y+h/2,size-lerp(0,size,frame/10),_color)
          circfill(_position.x+w/2,_position.y+h/2,size/2-lerp(0,size/2,frame/10),7)
          circ(_position.x+w/2,_position.y+h/2,size-lerp(0,size,frame/10),_comp_color)
        else 
          circfill(_position.x+w/2,_position.y+h/2,size+lerp(0,size,frame/10),_color)
          circfill(_position.x+w/2,_position.y+h/2,size/2+lerp(0,size/2,frame/10),7)
          circ(_position.x+w/2,_position.y+h/2,size+lerp(0,size,frame/10),_comp_color)
        end
        frame += 1
        yield()
      end
    end
    
    return cocreate(anim)
  end

  return new_entity("bullet_manager",
        {"manager"},
        new_vector(),
        function (entity)
          for i=1,#bullet_pool do
            bullet_pool[i].y += speed * (bullet_pool[i].y >= _player.position.y+10 and 6 or bullet_pool[i].y <= 4 and bullet_pool[i].y >= 0 and 4 or 1)
          end
        end,
        function (entity)
          for i=1,#gib_pool do
            if gib_pool[i] and costatus(gib_pool[i]) != "dead" then
              coresume(gib_pool[i])
            else
              del(gib_pool,gib_pool[i])
            end
          end
          for i=1,#bullet_pool do
            spr(sprites[bullet_pool[i].name],bullet_pool[i].x,bullet_pool[i].y)
          end
          for i=1,#endings do
            spr(63,endings[i].x-4,endings[i].y)
          end
        end,
        new_body(bullet_pool,
        function (entity,coll,e_hitbox,coll_hitbox)
          if coll.name == "player" then
            if coll_hitbox.name == "shield" and coll.model.defense_type == e_hitbox.name then
              add(gib_pool,gib_anim(new_vector(e_hitbox.x,e_hitbox.y),coll.position,bullet_color[e_hitbox.name],bullet_color.complement[e_hitbox.name],true))
              del(bullet_pool,e_hitbox)
            elseif coll_hitbox.name == "chassis" and coll.model.defense_type != e_hitbox.name then
              add(gib_pool,gib_anim(new_vector(e_hitbox.x,e_hitbox.y),coll.position,bullet_color[e_hitbox.name],bullet_color.complement[e_hitbox.name],false))
              del(bullet_pool,e_hitbox)
            end
          end
        end),
        {},
        2
        )
  end
entity_table.segments = 
function(_rect)
  local seglength = round(_rect.height/3)
  local segments = {new_hitbox(_rect.x,_rect.y,_rect.x+_rect.width,_rect.height-seglength*2,"seg1",false),
                    new_hitbox(_rect.x,_rect.y+seglength,_rect.x+_rect.width,_rect.height-seglength*2,"seg2",false),
                    new_hitbox(_rect.x,_rect.y+seglength*2,_rect.x+_rect.width,_rect.height-seglength*2,"seg3",false)}
  
  return new_entity("segments", {"segments"}, new_vector(),
          function (entity)
          end,
          function (entity) 
          end,
          new_body(segments, 
          function (entity,coll,segment) 
          end),
          {},
          -1)
end
--rails
entity_table.rail = 
function(_rail_count,_spatial_difference,_even)
  local mid_point = 64
  local y_offset = 15
  local size = 128-y_offset
  local width = 1
  local spot = mid_point-_spatial_difference/2 + (_rail_count-1)*_spatial_difference
  if not _even then
    spot = mid_point-_spatial_difference + (_rail_count-1)*_spatial_difference
  end
  local position = new_vector(spot,y_offset)
  return new_entity("rail",
  {"rail"},
  position,
  function (entity)
  end,
  function (entity)
    local p = entity.position
    rectfill(p.x-1,p.y,p.x+width-1,p.y+size,7)
  end,
  new_body(),
  {},
  -1)
end

--player
entity_table.player =
function(_rails,_segments)
  local w,h = 10,13
  local sprite = new_sprite(0,0,0,2,2)
  local speed = 1
  local min_rail = 1
  local max_rail = #_rails
  local cur_rail = round(max_rail/2)
  local position = new_vector(center(_rails[cur_rail].position.x,w),120-h)
  local shield = new_hitbox(0,0,w-1,h-1,"shield")
  local chassis = new_hitbox(3,4,3,3,"chassis")
  local rail_transition = nil
  local side_flame_anim = nil
  local transition_speed = 7
  local transition_offset = 0
  local bounce_transition = nil
  local bounce_speed = 4
  local bounce_distance = 4
  local bounce_thresh = 0
  local energy = 0 
  local hitback_anim = nil
  local hitback_start = nil
  local hitback_distance = 30
  local state = "free"
  --[[
  States:
  hold
  free
  hitstun
  ]]--
  local last_btn = ""
  local input = ""
  local btn_frame = 0
  local btn_delay = 3
  return new_entity("player",
        {"player"},
        position,
        function (entity)
          local state = entity.model.state
          if state == "hold" then
            --nothing
          elseif state == "free" then
            local cur_btn = ""
            if btn(4) and not btn(5) then
              cur_btn = "z"
            elseif btn(5) and not btn(4) then
              cur_btn = "x"
            end
            
            --[[
              if the current input is the last input, the button has been held another frame,
              if the btn_frame has reached the button delay, the input is changed.
            ]]--
            if cur_btn == last_btn then
              btn_frame += 1
            else
              btn_frame = 0
            end
            
            if btn_frame >= btn_delay then
              input = cur_btn
              btn_frame = 0
            end
            
            last_btn = cur_btn

            if input == "z" then
              sprite.n = 2
              entity.model.defense_type = "b"
            elseif input == "x" then
              sprite.n = 4
              entity.model.defense_type = "c"
            elseif input == "" then
              sprite.n = 0
              entity.model.defense_type = "a"
            end
            
            --left transition
            if btn(0) and not btn(1) and cur_rail-1 >= min_rail and not rail_transition then
              cur_rail -= 1
              rail_transition = vector.animation.movetoinframes(entity.position,new_vector(center(_rails[cur_rail].position.x,w),entity.position.y),transition_speed)
              side_flame_anim = new_animation(new_clip("",1,
                function (_sample)
                  local x0,x1,y = entity.position.x-sin(_sample/20)*8+w,entity.position.x+w-2,entity.position.y
                  local c 
                  if entity.model.defense_type == "a" then
                    c = _sample <= 5 and 12 or 2
                  elseif entity.model.defense_type == "b" then
                    c = _sample <= 5 and 9 or 2
                  else
                    c = _sample <= 5 and 11 or 2
                  end
                  rectfill(x0,y+1,x1,y+11,c)
                end, 10))
            end
            --right transition
            if btn(1) and not btn(0) and cur_rail+1 <= max_rail and not rail_transition then
              cur_rail += 1
              rail_transition = vector.animation.movetoinframes(entity.position,new_vector(center(_rails[cur_rail].position.x,w),entity.position.y),transition_speed)
              side_flame_anim = new_animation(new_clip("",1,
                function (_sample) 
                  local x0,x1,y = entity.position.x+sin(_sample/20)*8,entity.position.x+2,entity.position.y
                  local c 
                  if entity.model.defense_type == "a" then
                    c = _sample <= 5 and 12 or 2
                  elseif entity.model.defense_type == "b" then
                    c = _sample <= 5 and 9 or 2
                  else
                    c = _sample <= 5 and 11 or 2
                  end
                  rectfill(x0,y+1,x1,y+11,c)
                end, 10))
            end
            --up
            if btn(2) and not bounce_transition then
              entity.position.y -= speed
              transition_offset = new_vector(0,-speed)
            end
            --down
            if btn(3) and not bounce_transition then
              entity.position.y += speed
              transition_offset = new_vector(0,speed)
            end
            --bounce
            if entity.position.y >= 128+bounce_thresh-h then
              bounce_transition = vector.animation.movetoinframes(entity.position,new_vector(entity.position.x,128-bounce_distance-h),bounce_speed)
            end
            --bounce animation
            if bounce_transition then
              coresume(bounce_transition,transition_offset)
              if costatus(bounce_transition) == "dead" then 
                bounce_transition = nil
              end
            end
            --transition animation
            if rail_transition then
              coresume(rail_transition,transition_offset)
              if costatus(rail_transition) == "dead" then 
                rail_transition = nil
              end
            end
            transition_offset = zero
          elseif state == "hitstun" then
            if hitback_anim then
            --hitback_anim
              coresume(hitback_anim,zero)
              if costatus(hitback_anim) == "dead" then 
                hitback_anim = nil
                entity.model.state = "free"
              end
            end
          else 
            printh("Error Bad Player State")
          end
        end,
        function (entity)
          if side_flame_anim then
            coresume(side_flame_anim)
          end
          sprite:draw(entity.position)
        end,
        new_body({shield,chassis},
        function (entity,coll,e_hitbox,coll_hitbox)
          if coll.name == "bullet_manager" then
            if e_hitbox.name == "shield" then
              energy += 1
            elseif e_hitbox.name == "chassis" then
              hitback_anim = vector.animation.movetoinframes(entity.position,new_vector(center(_rails[cur_rail].position.x,w),entity.position.y + hitback_distance),5)
              rail_transition = nil
              entity.model.state = "hitstun"
            end
          end
        end),
        {defense_type="a",h=h,w=h,state=state},
        1
        )
  end
--enemy
entity_table.enemy =
function()
  local w,h = 16,16
  local sprite = new_sprite(128,0,0,2,2)
  local position = new_vector(center(64,w),-h/2+10)
  local start_position = new_vector(position.x,position.y)
  local hitbox = new_hitbox(0,0,w-1,h-1)
  local bottom_sway = position.y + h/4
  local top_sway = position.y-2
  local sway_t = 0
  local sway_down = true
  return new_entity("enemy",
        {"enemy"},
        position,
        function (entity)
          if sway_down then
            position:lerp(start_position,new_vector(position.x,bottom_sway),sway_t)
          else
            position:lerp(start_position,new_vector(position.x,top_sway),sway_t)
          end
          sway_t += .01
          if sway_t >= 1 then
            sway_t = 0
            sway_down = not sway_down
            start_position = new_vector(position.x,position.y)
          end
        end,
        function (entity)
          sprite:draw(entity.position)
        end,
        new_body({hitbox},
        function (entity,coll,e_hitbox,coll_hitbox)
        end),
        {},
        1
        )
  end
--scenes
scene_table = {}
scene_table.init =
function ()
  return new_scene(function ()
                    local bullet_pattern = 
                    'a||,||,b||,||,c||,||,||,||,||b,||,||a,||,||c,||,||,||,c||,||,b||,||,a||'

                    local segments = game.add_entity(entity_table.segments(new_rect(0,15,127,127-17)))
                    local rails = {}
                    for i=1,2 do
                      add(rails,game.add_entity(entity_table.rail(i,32,true)))
                    end
                    local player = game.add_entity(entity_table.player(rails,segments))
                    game.add_entity(entity_table.bullet_manager(rails,bullet_pattern,player))
                    game.add_entity(entity_table.enemy())
                  end,
                  nil,
                  function ()

                  end,
                  nil,
                  nil)
end

extensions = {}
--pico
function _init()
  --initialize three global objects
  --data: object which contains entity, scene, and starting_scene.
  --extensions: object which contains singular services to be called on
  --new_game: object which operates the game
  game = new_game(scene_table.init())
  game.start()
end
function _update60()
  game.update()
end
function _draw()
  game.draw()
end

__gfx__
000cccc0000000000009999000000000000bbbb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00cc77cc00000000009977990000000000bb77bb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0ce7cc7ec000000009e7997e900000000be7bb7eb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0ce2dd2ec000000009e4dd4e900000000be3dd3eb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ccedccdecc00000099ed99de99000000bbedbbdebb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c72dccd27c000000974d99d479000000b73dbbd37b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c7cdccdc7c000000979d99d979000000b7bdbbdb7b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c72dccd27c000000974d99d479000000b73dbbd37b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cce2dd2ecc00000099e4dd4e99000000bbe3dd3ebb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0ce7cc7ec000000009e7997e900000000be7bb7eb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0ccc77ccc000000009997799900000000bbb77bbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00cccccc00000000009999990000000000bbbbbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000cccc0000000000009999000000000000bbbb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000e00e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00881188000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08e1cc1e800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
e81cccc18e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
181c55c1810000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01c5555c100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011c55c1100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01cccccc100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
181cccc18100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d111111d
e81cccc18e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006dd11dd6
08e1111e8000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000666dd666
00800008000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000066666666
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000066666666
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000066666666
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000066666666
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000066666666
00dccd00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0dccccd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0cc77cc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0cc77cc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0dccccd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00dccd00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
04994000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
49999400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
99779900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
99779900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
49999400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
04994000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0003bb30000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
003bbbb3000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00bb77bb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00bb77bb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
003bbbb3000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0003bb30000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077777777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00777770077777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07777700007777700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07700770077007700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07000077770000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07700777777007700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07777777777777700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07777700007777700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07777777777777700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07777000000777700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07777777777777700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07770000000077700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00777777777777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077777777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344

