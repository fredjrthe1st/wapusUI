local defaultUIName = "Wapus.Shop" -- $$$
local connectionList = {} -- for unloading
local playerStatus = {}
local wapus

do -- Drawing Library 
    local drawing = {}
    local cache = {
        updates = {},
        instances = {},
        shapes = {}
    }

    local leftTriangleId = "http://www.roblox.com/asset/?id=18975909718" -- "http://www.roblox.com/asset/?id=17661400876" 2 
    local rightTriangleId = "http://www.roblox.com/asset/?id=18975907988" -- "http://www.roblox.com/asset/?id=17661399529" 1

    local folder = Instance.new("ScreenGui")
    local black = Color3.new(0, 0, 0)
    local v2 = Vector2
    local nv = v2.zero

    folder.Name = "Drawing API By iRay"
    folder.IgnoreGuiInset = true
    folder.Parent = game:GetService("CoreGui")

    local universal = {
        Visible = false,
        Transparency = 1,
        Color = black,
        ZIndex = 1
    }

    local defaults = { -- benefit of remaking it is to have a uniform drawing api across all executors because the wapus ui was originally made with krampus' drawing api
        Square = {
            Position = nv,
            Size = nv,
            Thickness = 1,
            Filled = false
        },
        Circle = {
            Position = nv,
            NumSides = 8,
            Radius = 200,
            Thickness = 1,
            Filled = false
        },
        Line = {
            From = nv,
            To = nv,
            Thickness = 1
        },
        Text = {
            Text = "",
            Size = 14,
            Center = false,
            Outline = false,
            OutlineColor = black,
            Position = nv,
            TextBounds = nv,
            Font = 0
        },
        Triangle = {
            Thickness = 1,
            PointA = nv,
            PointB = nv,
            PointC = nv,
            Filled = false
        },
        Image = {
            Position = nv,
            Size = nv,
            Data = ""
        },
        Quad = { -- why did i even do this
            Thickness = 1,
            PointA = nv,
            PointB = nv,
            PointC = nv,
            PointD = nv,
            Filled = false
        }
    }

    drawing.Fonts = {
        UI = 0,
        System = 1,
        Plex = 2,
        Monospace = 3
    }

    local fontIndexes = {
        [0] = Enum.Font.Legacy,
        [1] = Enum.Font.Ubuntu,
        [2] = Enum.Font.Code,
        [3] = Enum.Font.Jura
    }

    local newMetatable = {
        __index = function(self, index)
            if index == "TextBounds" and self._data.shape == "Text" then
                return self._data.drawings.label.TextBounds
            end

            return self._data[index]
        end,
        __newindex = function(self, index, value)
            if self._data[index] == nil then
                --warn("invalid shape property: '" .. tostring(index) .. "'")
            elseif self._data[index] ~= value then
                local shapeIndex = self._data.index

                if self._data.shape == "Text" then -- only putting this here to make TextBounds work better
                    if index == "Text" then
                        self._data.drawings.label.Text = value
                        self._data[index] = value
                        return
                    elseif index == "Font" then
                        self._data.drawings.label.Font = fontIndexes[value]
                        self._data[index] = value
                        return
                    elseif index == "Size" then
                        self._data.drawings.label.TextSize = value * 0.66
                        self._data[index] = value
                        return
                    end
                end

                if not cache.updates[shapeIndex] then
                    cache.updates[shapeIndex] = {}
                end

                if index == "Thickness" or index == "NumSides" then
                    value = math.max(math.abs(value), 1)
                end

                if index == "NumSides" then
                    value = math.min(value, 64)
                end

                cache.updates[shapeIndex][index] = value
                self._data[index] = value
            end
        end
    }

    local function destroyEntity(entity)
        if entity._data.shape == "Circle" or entity._data.shape == "Quad" then
            for _, object in entity._data.drawings.lines do
                object:Destroy()
            end
            
            for _, objects in entity._data.drawings.triangles do
                objects[1]:Destroy()
                objects[2]:Destroy()
            end
        else
            for _, object in entity._data.drawings do
                object:Destroy()
            end
        end
    end

    local function createEntity(shape)
        local entity = {}

        for ind, val in universal do
            entity[ind] = val
        end

        for ind, val in defaults[shape] do
            entity[ind] = val
        end

        return entity
    end

    local function newFrame()
        local frame = Instance.new("Frame", folder)
        frame.Visible = false
        frame.BorderSizePixel = 0
        frame.BackgroundColor3 = black
        return frame
    end

    local function newTriangle()
        local right = Instance.new("ImageLabel", folder)
        right.Image = rightTriangleId
        right.Visible = false
        right.BackgroundTransparency = 1
        right.AnchorPoint = v2.new(0.5, 0.5)
        right.ImageColor3 = black
        local left = Instance.new("ImageLabel", folder)
        left.Image = leftTriangleId
        left.Visible = false
        left.BackgroundTransparency = 1
        left.AnchorPoint = v2.new(0.5, 0.5)
        left.ImageColor3 = black
        return right, left
    end

    function drawing.new(shape)
        if shape == "Square" then
            local data = createEntity(shape)
            local square = {_data = data, Remove = destroyEntity, Destroy = destroyEntity}
            data.drawings = {box = newFrame(), line1 = newFrame(), line2 = newFrame(), line3 = newFrame(), line4 = newFrame()}
            data._data = data
            data.index = #cache.shapes + 1
            data.shape = shape
            cache.shapes[data.index] = square
            table.insert(cache.instances, data.drawings)
            return setmetatable(square, newMetatable)
        elseif shape == "Circle" then
            local data = createEntity(shape)
            local circle = {_data = data, Remove = destroyEntity, Destroy = destroyEntity}
            data.drawings = {lines = {}, triangles = {}}
            data._data = data
            data.index = #cache.shapes + 1
            data.shape = shape
            cache.shapes[data.index] = circle
            
            for i = 1, 8 do
                local newLine = newFrame()
                newLine.AnchorPoint = v2.new(0.5, 0.5)
                table.insert(data.drawings.lines, newLine)
            end
            
            for i = 1, 8 do
                table.insert(data.drawings.triangles, {newTriangle()})
            end
            
            table.insert(cache.instances, data.drawings)
            return setmetatable(circle, newMetatable)
        elseif shape == "Image" then
            local data = createEntity(shape)
            local image = {_data = data, Remove = destroyEntity, Destroy = destroyEntity}
            data.drawings = {image = Instance.new("ImageLabel", folder)}
            data._data = data
            data.index = #cache.shapes + 1
            data.shape = shape
            data.drawings.image.Image = ""
            data.drawings.image.Visible = false
            data.drawings.image.BackgroundTransparency = 1
            data.drawings.image.Size = UDim2.new(0, 0, 0, 0)
            cache.shapes[data.index] = image
            table.insert(cache.instances, data.drawings)
            return setmetatable(image, newMetatable)
        elseif shape == "Line" then
            local data = createEntity(shape)
            local line = {_data = data, Remove = destroyEntity, Destroy = destroyEntity}
            data.drawings = {line = newFrame()}
            data.drawings.line.AnchorPoint = v2.new(0.5, 0.5)
            data._data = data
            data.index = #cache.shapes + 1
            data.shape = shape
            cache.shapes[data.index] = line
            table.insert(cache.instances, data.drawings)
            return setmetatable(line, newMetatable)
        elseif shape == "Text" then
            local data = createEntity(shape)
            local text = {_data = data, Remove = destroyEntity, Destroy = destroyEntity}
            local label = Instance.new("TextLabel", folder)
            label.Text = ""
            label.TextColor3 = black
            label.BackgroundTransparency = 1
            label.AutomaticSize = Enum.AutomaticSize.XY
            label.Size = UDim2.new(0, 0, 0, 0)
            label.Font = fontIndexes[0]
            label.Visible = false
            data.drawings = {label = label}
            data._data = data
            data.index = #cache.shapes + 1
            data.shape = shape
            cache.shapes[data.index] = text
            table.insert(cache.instances, data.drawings)
            return setmetatable(text, newMetatable)
        elseif shape == "Triangle" then
            local data = createEntity(shape)
            local triangle = {_data = data, Remove = destroyEntity, Destroy = destroyEntity}
            local left, right = newTriangle()
            data.drawings = {left = left, right = right, a = newFrame(), b = newFrame(), c = newFrame()}
            data.drawings.a.AnchorPoint = v2.new(0.5, 0.5)
            data.drawings.b.AnchorPoint = v2.new(0.5, 0.5)
            data.drawings.c.AnchorPoint = v2.new(0.5, 0.5)
            data._data = data
            data.index = #cache.shapes + 1
            data.shape = shape
            cache.shapes[data.index] = triangle
            table.insert(cache.instances, data.drawings)
            return setmetatable(triangle, newMetatable)
        elseif shape == "Quad" then
            local data = createEntity(shape)
            local triangle = {_data = data, Remove = destroyEntity, Destroy = destroyEntity}
            local left, right = newTriangle()
            data.drawings = {lines = {}, triangles = {}}
            data._data = data
            data.index = #cache.shapes + 1
            data.shape = shape
            cache.shapes[data.index] = triangle

            for i = 1, 4 do
                local newLine = newFrame()
                newLine.AnchorPoint = v2.new(0.5, 0.5)
                table.insert(data.drawings.lines, newLine)
            end

            for i = 1, 2 do
                table.insert(data.drawings.triangles, {newTriangle()})
            end
            
            table.insert(cache.instances, data.drawings)
            return setmetatable(triangle, newMetatable)
        else
            --warn("invalid drawing shape: '" .. tostring(shape) .. "'")
        end
    end

    local function round(num)
        return math.floor(num + 0.5)
    end

    local function fixvec(vec)
        return v2.new(round(vec.X), round(vec.Y))
    end

    local function getPointOrder(a, b, c)
        local p0, p1, p2
        local d1, d2, d3 = (a - b).Magnitude, (c - b).Magnitude, (a - c).Magnitude
        local h1, h2, c0, h1d, h2d

        if d1 > d2 and d1 > d3 then
            h1 = a
            h2 = b
            c0 = c
            h1d = d3
            h2d = d2
        elseif d2 > d3 and d2 > d1 then
            h1 = c
            h2 = b
            c0 = a
            h1d = d3
            h2d = d1
        else
            h1 = c
            h2 = a
            c0 = b
            h1d = d2
            h2d = d1
        end

        if h1d < h2d then
            p0 = h1
            p1 = h2
            p2 = c0
        else
            p0 = h2
            p1 = h1
            p2 = c0
        end
        
        return p0, p1, p2
    end

    local function renderTriangle(leftSide, rightSide, p0, p1, p2) -- creates any triangle image by turning random triangles into 2 right triangles and using right triangle images
        local hmxo = p1.x - p0.x
        local hmyo = p1.y - p0.y
        local hm = (hmyo == 0 and 1 or hmyo) / (hmxo == 0 and 1 or hmxo)
        local hb = p0.y - hm * p0.x
        local lm = -1 / hm
        local lb = p2.y - lm * p2.x
        local sxo = (hm - lm)
        local sx = (lb - hb) / (sxo == 0 and 1 or sxo)
        local s = v2.new(sx, lm * sx + lb) -- point with right angle

        local ho = p2 - s
        local height = ho.Magnitude
        local b1o = p1 - s
        local base1 = b1o.Magnitude
        local b2o = p0 - s
        local base2 = b2o.Magnitude

        local m1 = s + ho * 0.5 + b1o * 0.5
        local m2 = s + ho * 0.5 + b2o * 0.5

        local d1 = p1 - p0
        local left, right = leftSide, rightSide
        local rotation = math.deg(math.atan2(d1.Y, d1.X))

        -- ty redpoint for these 12 lines (@418013390024474624)
        local horizontal_dot = b1o:Dot(v2.new(1, 0))
        local vertical_dot = ho:Dot(v2.new(0, -1))
        if horizontal_dot > 0 and vertical_dot < 0 or horizontal_dot < 0 and vertical_dot > 0 then
            if d1.X ~= 0 then
                left = rightSide
                right = leftSide
                rotation += math.deg(math.pi)
            end
        elseif d1.X == 0 then
            left = rightSide
            right = leftSide
            rotation += math.deg(math.pi)
        end

        left.Position = UDim2.new(0, m1.X, 0, m1.Y)
        left.Size = UDim2.new(0, base1, 0, height)
        left.Rotation = rotation
        right.Position = UDim2.new(0, m2.X, 0, m2.Y)
        right.Size = UDim2.new(0, base2, 0, height)
        right.Rotation = rotation
    end

    local function render()
        for shapeIndex, updateList in cache.updates do
            local shape = cache.shapes[shapeIndex]._data

            if shape.shape == "Line" then
                local line = shape.drawings.line

                if updateList.From or updateList.To then
                    local a = shape.From
                    local b = shape.To
                    local offset = b - a
                    local middle = a + offset * 0.5
                    local distance = offset.Magnitude
                    line.Position = UDim2.new(0, middle.X, 0, middle.Y) -- middle
                    line.Rotation = math.deg(math.atan(offset.Y / offset.X))
                    line.Size = UDim2.new(0, math.floor(distance + 0.5), 0, math.abs(shape.Thickness))
                end

                if updateList.Thickness then
                    local distance = (shape.From - shape.To).Magnitude
                    line.Size = UDim2.new(0, math.floor(distance + 0.5), 0, math.abs(updateList.Thickness))
                end

                if updateList.Color then
                    line.BackgroundColor3 = updateList.Color
                end

                if updateList.Visible ~= nil then
                    line.Visible = updateList.Visible
                end

                if updateList.Transparency then
                    line.Transparency = 1 - updateList.Transparency
                end

                if updateList.ZIndex then
                    line.ZIndex = updateList.ZIndex
                end
            elseif shape.shape == "Text" then
                local label = shape.drawings.label

                if updateList.Position then
                    label.Position = UDim2.new(0, updateList.Position.X, 0, updateList.Position.Y + 2)
                end

                if updateList.Center ~= nil then
                    label.AutomaticSize = updateList.Center and Enum.AutomaticSize.Y or Enum.AutomaticSize.XY
                end

                if updateList.Outline ~= nil then
                    label.TextStrokeTransparency = updateList.Outline and 0 or 1
                end

                if updateList.OutlineColor then
                    label.TextStrokeColor3 = updateList.OutlineColor
                end

                if updateList.Color then
                    label.TextColor3 = updateList.Color
                end

                if updateList.Visible ~= nil then
                    label.Visible = updateList.Visible
                end

                if updateList.Transparency then
                    label.TextTransparency = 1 - updateList.Transparency
                end

                if updateList.ZIndex then
                    label.ZIndex = updateList.ZIndex
                end
            elseif shape.shape == "Square" then
                local drawings = shape.drawings

                if updateList.Position or updateList.Thickness or updateList.Size then
                    local size = fixvec(shape.Size)
                    local position = shape.Position

                    if size.X < 0 then
                        size = v2.new(math.abs(size.X), size.Y)
                        position = v2.new(position.X - size.X, position.Y)
                    end

                    if size.Y < 0 then
                        size = v2.new(size.X, math.abs(size.Y))
                        position = v2.new(position.X, position.Y - size.Y)
                    end
                    
                    local realThick = shape.Thickness
                    local thick = realThick - 1
                    local thicknessOffset = math.floor(thick * 0.5 + 0.5)
                    local boxPos = fixvec(v2.new(position.X - thicknessOffset, position.Y - thicknessOffset))
                    drawings.box.Position = UDim2.new(0, boxPos.X, 0, boxPos.Y)
                    drawings.box.Size = UDim2.new(0, size.X + thick, 0, size.Y + thick)
                    drawings.line1.Position = drawings.box.Position
                    drawings.line2.Position = UDim2.new(0, boxPos.X + size.X - 1, 0, boxPos.Y + realThick)
                    drawings.line3.Position = UDim2.new(0, boxPos.X, 0, boxPos.Y + size.Y - 1)
                    drawings.line4.Position = UDim2.new(0, boxPos.X, 0, boxPos.Y + realThick)
                    drawings.line2.Size = UDim2.new(0, realThick, 0, size.Y - realThick - 1)
                    drawings.line1.Size = UDim2.new(0, size.X + thick, 0, realThick)
                    drawings.line4.Size = UDim2.new(0, realThick, 0, size.Y - realThick - 1)
                    drawings.line3.Size = UDim2.new(0, size.X + thick, 0, realThick)
                end

                if updateList.Filled ~= nil then
                    if shape.Visible then
                        drawings.box.Visible = updateList.Filled
                        drawings.line1.Visible = not updateList.Filled
                        drawings.line2.Visible = not updateList.Filled
                        drawings.line3.Visible = not updateList.Filled
                        drawings.line4.Visible = not updateList.Filled
                    end
                end

                if updateList.Visible ~= nil then
                    if shape.Filled then
                        drawings.box.Visible = updateList.Visible
                    else
                        drawings.line1.Visible = updateList.Visible
                        drawings.line2.Visible = updateList.Visible
                        drawings.line3.Visible = updateList.Visible
                        drawings.line4.Visible = updateList.Visible
                    end
                end

                if updateList.Transparency then
                    drawings.box.Transparency = 1 - updateList.Transparency
                    drawings.line1.Transparency = 1 - updateList.Transparency
                    drawings.line2.Transparency = 1 - updateList.Transparency
                    drawings.line3.Transparency = 1 - updateList.Transparency
                    drawings.line4.Transparency = 1 - updateList.Transparency
                end

                if updateList.Color then
                    for _, drawing in drawings do
                        drawing.BackgroundColor3 = updateList.Color
                    end
                end

                if updateList.ZIndex then
                    for _, drawing in drawings do
                        drawing.ZIndex = updateList.ZIndex
                    end
                end
            elseif shape.shape == "Image" then
                local image = shape.drawings.image

                if updateList.Position then
                    image.Position = UDim2.new(0, updateList.Position.X, 0, updateList.Position.Y)
                end

                if updateList.Size then
                    image.Size = UDim2.new(0, updateList.Size.X, 0, updateList.Size.Y)
                end

                if updateList.Data then
                    image.Image = updateList.Data
                end

                if updateList.Visible ~= nil then
                    image.Visible = updateList.Visible
                end

                if updateList.Transparency then
                    image.ImageTransparency = 1 - updateList.Transparency
                end

                if updateList.ZIndex then
                    image.ZIndex = updateList.ZIndex
                end
            elseif shape.shape == "Circle" then
                local drawings = shape.drawings
                
                if updateList.NumSides then
                    for _, triangle in drawings.triangles do
                        for _, drawing in triangle do
                            drawing:Destroy()
                        end
                    end

                    for _, drawing in drawings.lines do
                        drawing:Destroy()
                    end

                    drawings.lines = {}
                    drawings.triangles = {}
                    
                    for _ = 1, updateList.NumSides do
                        local newLine = newFrame()
                        newLine.AnchorPoint = v2.new(0.5, 0.5)
                        table.insert(drawings.lines, newLine)
                        table.insert(drawings.triangles, {newTriangle()})
                    end
                    
                    updateList.Filled = shape.Filled
                    updateList.Visible = shape.Visible
                    updateList.Transparency = shape.Transparency
                    updateList.Color = shape.Color
                    updateList.ZIndex = shape.ZIndex
                end
                
                if updateList.Position or updateList.Thickness or updateList.Radius or updateList.NumSides then
                    local position = shape.Position
                    local size = shape.Radius
                    local num = shape.NumSides
                    local interval = 2 * math.pi / num
                    
                    for lineIndex = 1, num do
                        local origin = (lineIndex - 1) * interval
                        local target = lineIndex * interval
                        local o0 = v2.new(math.cos(origin), math.sin(origin))
                        local o1 = v2.new(math.cos(target), math.sin(target))
                        local p0 = position + o0 * size
                        local p1 = position + o1 * size
                        local offset = p1 - p0
                        local middle = p0 + offset * 0.5
                        local distance = offset.Magnitude
                        local newSize = (middle - position).Magnitude
                        local line = drawings.lines[lineIndex]
                        local left = drawings.triangles[lineIndex][1]
                        local right = drawings.triangles[lineIndex][2]

                        line.Position = UDim2.new(0, middle.X, 0, middle.Y) -- middle
                        line.Rotation = math.deg(math.atan(offset.Y / offset.X))
                        line.Size = UDim2.new(0, math.floor(distance + 0.5), 0, math.abs(shape.Thickness))
                        
                        local rotation = math.deg((lineIndex - 0.5) * interval - (math.pi * 0.5))
                        local leftPosition = (lineIndex - 1) * interval
                        leftPosition = position + v2.new(math.cos(leftPosition), math.sin(leftPosition)) * size * 0.5
                        left.Position = UDim2.new(0, leftPosition.X, 0, leftPosition.Y)
                        left.Size = UDim2.new(0, distance * 0.5, 0, newSize)
                        left.Rotation = rotation
                        local rightPosition = (lineIndex - 0) * interval
                        rightPosition = position + v2.new(math.cos(rightPosition), math.sin(rightPosition)) * size * 0.5
                        right.Position = UDim2.new(0, rightPosition.X, 0, rightPosition.Y)
                        right.Size = UDim2.new(0, distance * 0.5, 0, newSize)
                        right.Rotation = rotation
                    end
                end

                if updateList.Filled ~= nil then
                    if shape.Visible then
                        for _, triangle in drawings.triangles do
                            for _, drawing in triangle do
                                drawing.Visible = updateList.Filled
                            end
                        end
                        
                        for _, drawing in drawings.lines do
                            drawing.Visible = not updateList.Filled
                        end
                    end
                end

                if updateList.Visible ~= nil then
                    if shape.Filled then
                        for _, triangle in drawings.triangles do
                            for _, drawing in triangle do
                                drawing.Visible = updateList.Visible
                            end
                        end
                    else
                        for _, drawing in drawings.lines do
                            drawing.Visible = updateList.Visible
                        end
                    end
                end

                if updateList.Transparency then
                    for _, drawing in drawings.lines do
                        drawing.Transparency = 1 - updateList.Transparency
                    end

                    for _, triangle in drawings.triangles do
                        for _, drawing in triangle do
                            drawing.ImageTransparency = 1 - updateList.Transparency
                        end
                    end
                end

                if updateList.Color then
                    for _, drawing in drawings.lines do
                        drawing.BackgroundColor3 = updateList.Color
                    end
                    
                    for _, triangle in drawings.triangles do
                        for _, drawing in triangle do
                            drawing.ImageColor3 = updateList.Color
                        end
                    end
                end

                if updateList.ZIndex then
                    for _, drawing in drawings.lines do
                        drawing.ZIndex = updateList.ZIndex
                    end

                    for _, triangle in drawings.triangles do
                        for _, drawing in triangle do
                            drawing.ZIndex = updateList.ZIndex
                        end
                    end
                end
            elseif shape.shape == "Triangle" then
                local drawings = shape.drawings

                if updateList.PointA or updateList.PointB or updateList.PointC or updateList.Thickness then
                    local a, b, c = shape.PointA, shape.PointB, shape.PointC
                    
                    if a and b and c and a ~= b and a ~= c and b ~= c then
                        local p0, p1, p2 = getPointOrder(a, b, c)
                        
                        local line1, line2, line3 = drawings.a, drawings.b, drawings.c
                        local d1 = p1 - p0
                        local mp1 = p0 + d1 * 0.5
                        line1.Position = UDim2.new(0, mp1.X, 0, mp1.Y)
                        line1.Rotation = math.deg(math.atan(d1.Y / d1.X))
                        line1.Size = UDim2.new(0, math.floor(d1.Magnitude + 0.5), 0, math.abs(shape.Thickness))

                        local d2 = p2 - p1
                        local mp2 = p1 + d2 * 0.5
                        line2.Position = UDim2.new(0, mp2.X, 0, mp2.Y)
                        line2.Rotation = math.deg(math.atan(d2.Y / d2.X))
                        line2.Size = UDim2.new(0, math.floor(d2.Magnitude + 0.5), 0, math.abs(shape.Thickness))

                        local d3 = p0 - p2
                        local mp3 = p2 + d3 * 0.5
                        line3.Position = UDim2.new(0, mp3.X, 0, mp3.Y)
                        line3.Rotation = math.deg(math.atan(d3.Y / d3.X))
                        line3.Size = UDim2.new(0, math.floor(d3.Magnitude + 0.5), 0, math.abs(shape.Thickness))

                        renderTriangle(drawings.left, drawings.right, p0, p1, p2)
                    end
                end

                if updateList.Filled ~= nil then
                    if shape.Visible then
                        drawings.left.Visible = updateList.Filled
                        drawings.right.Visible = updateList.Filled
                        drawings.a.Visible = not updateList.Filled
                        drawings.b.Visible = not updateList.Filled
                        drawings.c.Visible = not updateList.Filled
                    end
                end

                if updateList.Visible ~= nil then
                    if shape.Filled then
                        drawings.left.Visible = updateList.Visible
                        drawings.right.Visible = updateList.Visible
                    else
                        drawings.a.Visible = updateList.Visible
                        drawings.b.Visible = updateList.Visible
                        drawings.c.Visible = updateList.Visible
                    end
                end

                if updateList.Color then
                    drawings.left.ImageColor3 = updateList.Color
                    drawings.right.ImageColor3 = updateList.Color
                    drawings.a.BackgroundColor3 = updateList.Color
                    drawings.b.BackgroundColor3 = updateList.Color
                    drawings.c.BackgroundColor3 = updateList.Color
                end

                if updateList.Transparency then
                    drawings.left.ImageTransparency = 1 - updateList.Transparency
                    drawings.right.ImageTransparency = 1 - updateList.Transparency
                    drawings.a.Transparency = 1 - updateList.Transparency
                    drawings.b.Transparency = 1 - updateList.Transparency
                    drawings.c.Transparency = 1 - updateList.Transparency
                end

                if updateList.ZIndex then
                    for _, drawing in drawings do
                        drawing.ZIndex = updateList.ZIndex
                    end
                end
            elseif shape.shape == "Quad" then
                local drawings = shape.drawings
                
                if updateList.PointA or updateList.PointB or updateList.PointC or updateList.PointD or updateList.Thickness then
                    local p0 = shape.PointA
                    local p1 = shape.PointB
                    local p2 = shape.PointC
                    local p3 = shape.PointD
                    
                    if p0 and p1 and p2 and p3 and p0 ~= p1 and p0 ~= p2 and p0 ~= p3 and p1 ~= p2 and p1 ~= p3 and p2 ~= p3 then
                        local intersects = false
                        local intersection

                        local m1 = (p1.Y - p0.Y) / (p1.X - p0.X)
                        local m2 = (p2.Y - p1.Y) / (p2.X - p1.X)
                        local m3 = (p3.Y - p2.Y) / (p3.X - p2.X)
                        local m4 = (p0.Y - p3.Y) / (p0.X - p3.X)
                        local lines = {
                            {p0, p1, m1, p0.Y - m1 * p0.X},
                            {p1, p2, m2, p1.Y - m2 * p1.X},
                            {p2, p3, m3, p2.Y - m3 * p2.X},
                            {p3, p0, m4, p3.Y - m4 * p3.X}
                        }
                        
                        for lineIndex = 1, 2 do -- checking if lines in quad intersect
                            local lineData = lines[lineIndex]
                            local o1, t1, s1, b1 = table.unpack(lineData)
                            
                            if not intersects then
                                local opposite = lineIndex + 2
                                local o2, t2, s2, b2 = table.unpack(lines[opposite])
                                local ix = (b2 - b1) / (s1 - s2)
                                
                                local x11, x12 = o1.X, t1.X
                                if x11 > x12 then
                                    local temp = x11
                                    x11 = x12
                                    x12 = temp
                                end
                                        
                                local x21, x22 = o2.X, t2.X
                                if x21 > x22 then
                                    local temp = x21
                                    x21 = x22
                                    x22 = temp
                                end
                                        
                                if ix > x11 + 1 and ix < x12 - 1 and ix > x21 + 1 and ix < x22 - 1 then
                                    intersects = lineIndex + 1
                                    intersection = v2.new(ix, s2 * ix + b2)
                                end
                            end
                        end
                        
                        local obtuse
                        if not intersects then -- if not intersecting then gets the point with the biggest angle, 2 scalene triangles will share that point and the opposite point
                            local biggestAngle = 0
                            local biggestLine
                            local total = 0
                            
                            for lineIndex = 1, 4 do
                                local o0 = lines[(lineIndex == 1 and 4) or lineIndex - 1][1]
                                local o1, t1 = table.unpack(lines[lineIndex])
                                local supangle = (o0 - o1).Unit:Dot((t1 - o1).Unit)
                                local angle
                                
                                if supangle < 0 then
                                    angle = 2 + supangle
                                else
                                    angle = 1 - math.abs(supangle)
                                end
                                
                                total = total + angle
                                
                                if angle >= biggestAngle then
                                    biggestLine = lineIndex
                                    biggestAngle = angle
                                end
                            end
                            
                            obtuse = biggestLine
                        end
                        
                        for sideIndex = 1, 4 do
                            local line = drawings.lines[sideIndex]
                            local h1, h2, m, b = table.unpack(lines[sideIndex])
                            
                            local d = h2 - h1
                            local mp = h1 + d * 0.5
                            line.Position = UDim2.new(0, mp.X, 0, mp.Y) -- middle
                            line.Rotation = math.deg(math.atan(d.Y / d.X))
                            line.Size = UDim2.new(0, math.floor(d.Magnitude + 0.5), 0, math.abs(shape.Thickness))
                        end
                        
                        if intersects then
                            local l1 = lines[intersects]
                            local l2 = lines[intersects == 3 and 1 or 4]
                            local lt1, rt1 = table.unpack(drawings.triangles[1])
                            local lt2, rt2 = table.unpack(drawings.triangles[2])
                            local a1, b1, c1 = getPointOrder(intersection, l1[1], l1[2])
                            local a2, b2, c2 = getPointOrder(intersection, l2[1], l2[2])
                            renderTriangle(lt1, rt1, a1, b1, c1)
                            renderTriangle(lt2, rt2, a2, b2, c2)
                        else
                            local l0 = lines[(obtuse < 3 and obtuse + 2) or obtuse - 2]
                            local l1 = lines[obtuse]
                            local lt1, rt1 = table.unpack(drawings.triangles[1])
                            local lt2, rt2 = table.unpack(drawings.triangles[2])
                            local a1, b1, c1 = getPointOrder(l1[1], l1[2], l0[1])
                            local a2, b2, c2 = getPointOrder(l1[1], l0[2], l0[1])
                            renderTriangle(lt1, rt1, a1, b1, c1)
                            renderTriangle(lt2, rt2, a2, b2, c2)
                        end
                    end
                end

                if updateList.Filled ~= nil then
                    if shape.Visible then
                        for _, triangle in drawings.triangles do
                            for _, drawing in triangle do
                                drawing.Visible = updateList.Filled
                            end
                        end

                        for _, drawing in drawings.lines do
                            drawing.Visible = not updateList.Filled
                        end
                    end
                end

                if updateList.Visible ~= nil then
                    if shape.Filled then
                        for _, triangle in drawings.triangles do
                            for _, drawing in triangle do
                                drawing.Visible = updateList.Visible
                            end
                        end
                    else
                        for _, drawing in drawings.lines do
                            drawing.Visible = updateList.Visible
                        end
                    end
                end

                if updateList.Transparency then
                    for _, drawing in drawings.lines do
                        drawing.Transparency = 1 - updateList.Transparency
                    end

                    for _, triangle in drawings.triangles do
                        for _, drawing in triangle do
                            drawing.ImageTransparency = 1 - updateList.Transparency
                        end
                    end
                end

                if updateList.Color then
                    for _, drawing in drawings.lines do
                        drawing.BackgroundColor3 = updateList.Color
                    end

                    for _, triangle in drawings.triangles do
                        for _, drawing in triangle do
                            drawing.ImageColor3 = updateList.Color
                        end
                    end
                end

                if updateList.ZIndex then
                    for _, drawing in drawings.lines do
                        drawing.ZIndex = updateList.ZIndex
                    end

                    for _, triangle in drawings.triangles do
                        for _, drawing in triangle do
                            drawing.ZIndex = updateList.ZIndex
                        end
                    end
                end
            end
        end

        cache.updates = {}
    end

    local function cleardrawcache()
        for _, instanceList in cache.instances do
            for _, instance in instanceList do
                instance:Destroy()
            end
        end

        return
    end

    local function isrenderobj(obj)
        return table.find(cache.shapes, obj) ~= nil
    end

    local function getrenderproperty(obj, idx)
        return obj[idx]
    end

    local function setrenderproperty(obj, idx, val)
        obj[idx] = val
        return
    end

    local function getgui()
        return folder
    end

    --getgenv().Drawing = drawing -- this shit was actually causing the esp lag sorry throit for blaming u i didnt know until i switched the esp fr
    getgenv().drawing = drawing
    --getgenv().cleardrawcache = cleardrawcache
    --getgenv().isrenderobj = isrenderobj
    --getgenv().getrenderproperty = getrenderproperty
    --getgenv().setrenderproperty = setrenderproperty
    getgenv().getgui = getgui

    game:GetService("RunService").RenderStepped:Connect(render)
end

do -- UI Library
    local COLOR = 1
    local COLOR1 = 2
    local COLOR2 = 3
    local COMBOBOX = 4
    local TOGGLE = 5
    local KEYBIND = 6
    local DROPBOX = 7
    local COLORPICKER = 8
    local DOUBLE_COLORPICKERS = 9
    local SLIDER = 10
    local BUTTON = 11
    local LIST = 12
    local IMAGE = 13
    local TEXTBOX = 14
    --real

    wapus = {
        toggleKeybind = "RightShift",
        theme = {
            accent = Color3.fromRGB(127, 72, 163), -- Color3.fromRGB(23, 122, 179)
            text = Color3.fromRGB(255, 255, 255),
            background = Color3.fromRGB(35, 35, 35),
            lightbackground = Color3.fromRGB(50, 50, 50),
            hidden = Color3.fromRGB(26, 26, 26),
            hiddenText = Color3.fromRGB(200, 200, 200),
            outline = Color3.fromRGB(0, 0, 0),
            --fontData = game:HttpGet("https://get.fontspace.co/download/font/g0P4/YzVlMTg1YTgwOGNhNGQyYjljZDFiNmI0NjMxNGY0YzgudHRm/EpilepsySans-g0P4.ttf") -- miss krampus
        },
        menus = {},
        useCustomFont = false,
        open = true,
        GetValue = function() end
    }

    local hueData = "rbxassetid://18403604225"
    local valueData = "rbxassetid://18403602548"
    local blankData = "rbxassetid://18403600629"

    if unloadUI then unloadUI() end

    local runService = game:GetService("RunService")
    local userInputService = game:GetService("UserInputService")
    local middle = workspace.CurrentCamera.ViewportSize * 0.5
    local v2 = Vector2.new

    local insert = table.insert

    --local customFont = Drawing.new("Font", "EpilepsySans") -- cant find a free SpaceMace ttf file but thats what bbot v2 used origionally
    --customFont.Data = wapus.theme.fontData
    local defaultProperties = {
        Filled = true,
        Outline = true,
        Transparency = 1,
        NumSides = 64,
        Visible = false,
        Font = wapus.useCustomFont and customFont or nil
    }
    local themed = {
        accent = {},
        text = {},
        background = {},
        hidden = {},
        outline = {}
    }

    local black = Color3.new(0, 0, 0)
    local function darken(color, factor)
        return color:Lerp(black, factor)
    end

    local function modifyDrawing(drawing, properties)
        for property, value in properties do
            drawing[property] = value
        end

        return drawing
    end

    local allDrawCache = {}
    local function draw(self, shape, properties, theme)
        local drawing = drawing.new(shape)

        for property, value in defaultProperties do
            if value ~= nil then
                pcall(function()
                    drawing[property] = value
                end)
            end
        end

        modifyDrawing(drawing, properties)

        if theme and themed[theme] then
            insert(themed[theme], drawing)
        end

        insert(allDrawCache, drawing)

        if self.drawCache then
            insert(self.drawCache, drawing)
        end
        return drawing
    end

    local function gradient(self, colorList, breaks) -- now this is pro
        local pos = Vector2.zero
        local size = 0
        local squares = {}
        local colors = {}
        local new = {}
        local top, bottom

        if #colorList == 2 then
            top, bottom = table.unpack(colorList)
        end

        breaks = math.max(breaks, 2)
        local offsetAmount = 1 / (breaks - 1)
        for drawIdx = 1, breaks do
            local square = drawing.new("Square")
            square.Color = top and top:Lerp(bottom, (drawIdx - 1) * offsetAmount) or colorList[drawIdx]
            square.Filled = true
            colors[drawIdx] = square.Color
            squares[drawIdx] = square
            insert(allDrawCache, square)
            insert(self.drawCache, square)
        end

        return setmetatable({
            Remove = function(self0)
                for drawIdx = 1, breaks do
                    squares[drawIdx]:Remove()
                end
            end,
            SetColor = function(self0, newcolor)
                if type(newcolor) == "table" then
                    local newtop, newbottom

                    if #newcolor == 2 then
                        newtop, newbottom = table.unpack(newcolor)
                    end

                    for drawIdx = 1, breaks do
                        squares[drawIdx].Color = newtop and newtop:Lerp(newbottom, (drawIdx - 1) * offsetAmount) or newcolor[drawIdx]
                    end
                else
                    for drawIdx = 1, breaks do
                        squares[drawIdx].Color = newcolor or colors[drawIdx]
                    end
                end
            end
        }, {
            __index = function(self0, index)
                return squares[1][index]
            end,
            __newindex = function(self0, index, value)
                for drawIdx = 1, breaks do
                    if index == "Size" then
                        size = value.Y
                        local boxSize = size / breaks
                        squares[drawIdx][index] = v2(value.X, boxSize)
                        squares[drawIdx].Position = v2(pos.X, pos.Y + (drawIdx - 1) * boxSize)
                    elseif index == "Position" then
                        pos = value
                        squares[drawIdx].Position = v2(value.X, value.Y + (drawIdx - 1) * (size / breaks))
                    elseif index ~= "Color" then
                        squares[drawIdx][index] = value
                    end
                end
            end,
        })
    end

    local function updateTheme(self)
    end

    local function getValue(self, section, index)
        section = self.sectionIndexes[section]
        index = section and section.flags[index]
        return index and index.value
    end

    local function setValue(self, section, index, value)
        section = self.sectionIndexes[section]
        index = section and section.flags[index]
        return index and index:SetValue(value)
    end

    local function setTextValue(self, value)
        self.value = value
        self.valuetext.Text = value

        if self.callback then
            self.callback(value)
        end
    end

    local function addTextbox(self, text, default, callback, unsafe)
        local textbox = {}
        local visible = self.menu.open and self.tab.tabIndex == self.menu.tabIndex and self.index == 1
        local container = self.background.Position + self.bgOffset
        self.flags[text] = textbox
        textbox.type = "textbox"
        textbox.value = default or "jews"
        textbox.callback = callback
        textbox.SetValue = setTextValue
        textbox.height = 34
        textbox.buttonoutline = self.menu:draw("Square", {Position = container + v2(0, 15), Size = v2(213, 18), Color = wapus.theme.outline, Visible = visible}, "outline")
        textbox.button = modifyDrawing(self.menu:gradient({wapus.theme.lightbackground, wapus.theme.background}, 6), {Position = textbox.buttonoutline.Position + v2(1, 1), Size = v2(211, 16), Color = wapus.theme.background, Visible = visible})
        textbox.text = self.menu:draw("Text", {Position = textbox.buttonoutline.Position + v2(2, -16), Size = 14, Color = wapus.theme.text, Text = text, Visible = visible}, "text")
        textbox.valuetext = self.menu:draw("Text", {Position = textbox.button.Position + v2(6, 0), Size = 14, Color = wapus.theme.text, Text = textbox.value, Visible = visible}, "text")
        self.bgOffset += v2(0, textbox.height)
        insert(self.elements, textbox)
        return textbox
    end

    local function addButton(self, text, callback, unsafe)
        local button = {}
        local visible = self.menu.open and self.tab.tabIndex == self.menu.tabIndex and self.index == 1
        local container = self.background.Position + self.bgOffset
        button.type = "button"
        button.callback = callback
        button.height = 23
        button.buttonoutline = self.menu:draw("Square", {Position = container + v2(0, 3), Size = v2(213, 18), Color = wapus.theme.outline, Visible = visible}, "outline")
        button.button = modifyDrawing(self.menu:gradient({wapus.theme.lightbackground, wapus.theme.background}, 6), {Position = button.buttonoutline.Position + v2(1, 1), Size = v2(211, 16), Color = wapus.theme.background, Visible = visible})
        button.text = self.menu:draw("Text", {Position = button.button.Position + v2(106, 0), Center = true, Size = 14, Color = wapus.theme.text, Text = text, Visible = visible}, "text")
        self.bgOffset += v2(0, button.height)
        insert(self.elements, button)
        return button
    end

    local function setDropValue(self, value)
        self.value = value
        self.valuetext.Text = value

        if self.callback then
            self.callback(value)
        end
    end

    local function addDropdown(self, text, default, defaultoptions, callback, unsafe)
        local dropdown = {}
        local visible = self.menu.open and self.tab.tabIndex == self.menu.tabIndex and self.index == 1
        local container = self.background.Position + self.bgOffset
        self.flags[text] = dropdown
        dropdown.type = "dropdown"
        dropdown.value = default or "jews"
        dropdown.options = defaultoptions or {}
        dropdown.callback = callback
        dropdown.SetValue = setDropValue
        dropdown.height = 34
        dropdown.buttonoutline = self.menu:draw("Square", {Position = container + v2(0, 15), Size = v2(213, 18), Color = wapus.theme.outline, Visible = visible}, "outline")
        dropdown.button = modifyDrawing(self.menu:gradient({wapus.theme.lightbackground, wapus.theme.background}, 6), {Position = dropdown.buttonoutline.Position + v2(1, 1), Size = v2(211, 16), Color = wapus.theme.background, Visible = visible})
        dropdown.text = self.menu:draw("Text", {Position = dropdown.buttonoutline.Position + v2(2, -16), Size = 14, Color = wapus.theme.text, Text = text, Visible = visible}, "text")
        dropdown.valuetext = self.menu:draw("Text", {Position = dropdown.button.Position + v2(6, 0), Size = 14, Color = wapus.theme.text, Text = dropdown.value, Visible = visible}, "text")
        dropdown.droptext = self.menu:draw("Text", {Position = dropdown.button.Position + v2(200, 2), Size = 14, Color = wapus.theme.text, Text = "-", Visible = visible}, "text")
        self.bgOffset += v2(0, dropdown.height)
        insert(self.elements, dropdown)
        return dropdown
    end

    local function setSliderValue(self, value)
        self.valuetext.Text = tostring(value) .. self.suffix
        local ratio = (value - self.min) / (self.max - self.min)
        self.highlight.Size = Vector2.new(math.clamp(ratio * 211, 0, 211), 9)
        self.highlight.Position = self.buttonoutline.Position + v2(1, 1)

        if self.callback and value ~= self.value then
            self.callback(value)
        end

        self.value = value
    end

    local function addSlider(self, text, default, min, max, step, suffix, callback, unsafe)
        local slider = {}
        local visible = self.menu.open and self.tab.tabIndex == self.menu.tabIndex and self.index == 1
        local container = self.background.Position + self.bgOffset
        self.flags[text] = slider
        slider.default = default or 50
        slider.min = min or 0
        slider.max = max or 100
        slider.step = step or 1
        slider.suffix = suffix or ""
        slider.type = "slider"
        slider.height = 27
        slider.value = slider.default
        local ratio = (slider.default - slider.min) / (slider.max - slider.min)
        slider.buttonoutline = self.menu:draw("Square", {Position = container + v2(0, 16), Size = v2(213, 11), Color = wapus.theme.outline, Visible = visible}, "outline")
        slider.button = modifyDrawing(self.menu:gradient({wapus.theme.lightbackground, wapus.theme.background}, 3), {Position = slider.buttonoutline.Position + v2(1, 1), Size = v2(211, 9), Color = wapus.theme.background, Visible = visible})
        slider.highlight = modifyDrawing(self.menu:gradient({wapus.theme.accent, darken(wapus.theme.accent, 0.25)}, 3), {Position = slider.button.Position, Size = v2(math.clamp(ratio * 211, 0, 211), 9), Color = wapus.theme.accent, Visible = visible})
        slider.text = self.menu:draw("Text", {Position = slider.buttonoutline.Position + v2(2, -15), Size = 14, Color = wapus.theme.text, Text = text, Visible = visible}, "text")
        slider.valuetext = self.menu:draw("Text", {Position = slider.button.Position + v2(106, -3), Size = 14, Center = true, Color = wapus.theme.text, Text = tostring(default) .. slider.suffix, Visible = visible}, "text")
        slider.callback = callback
        slider.SetValue = setSliderValue
        self.bgOffset += v2(0, slider.height)
        insert(self.elements, slider)
        return slider
    end

    local function setColorValue(self, value)
        self.value = value
        self.button.Color = value
        self.buttonbackground.Color = darken(value, 0.4)

        if self.callback then
            self.callback(value)
        end
    end

    local function addKeybindToColor(self, default, name)
        self.toggle:AddKeyBind(default, name)
    end

    local function addColorToToggle(self, name, default, callback)
        self = self.type ~= "toggle" and self.toggle or self
        local color = {}
        local visible = self.menu.open and self.tab.tabIndex == self.menu.tabIndex and self.sectionIndex == 1
        if name then
            self.section.flags[name] = color
        end
        default = default or wapus.theme.accent
        color.name = name or "Color"
        color.callback = callback
        color.toggle = self
        color.value = default
        color.AddColorPicker = addColorToToggle
        color.buttonoutline = self.menu:draw("Square", {Position = self.buttonoutline.Position + v2(187 - self.additions, 1), Size = v2(26, 12), Color = wapus.theme.outline, Visible = visible}, "outline")
        color.buttonbackground = self.menu:draw("Square", {Position = color.buttonoutline.Position + v2(1, 1), Size = v2(24, 10), Color = darken(default, 0.4), Visible = visible}, "accent")
        color.button = self.menu:draw("Square", {Position = color.buttonoutline.Position + v2(3, 3), Size = v2(20, 6), Color = default, Visible = visible}, "accent")
        color.SetValue = setColorValue
        color.AddKeyBind = addKeybindToColor
        self.additions += 33
        insert(self.colors, color)
        return color
    end

    local function setKeybindValue(self, value)
        if value and value ~= "None" then
            self.text.Size = 14
            self.text.Text = value
            
            task.spawn(function()
                while self.text.TextBounds.X > self.button.Size.X do
                    self.text.Size = self.text.Size - 1
                    runService.RenderStepped:Wait()
                end
            end)

            if self.keyIndex then
                self.menu.keybinds[self.keyIndex][1] = value
            else
                self.keyIndex = #self.menu.keybinds + 1
                insert(self.menu.keybinds, self.keyIndex, {value, self})
            end
        else
            self.text.Size = 14
            self.text.Text = "None"
            
            if self.keyIndex then
                self.menu.keybinds[self.keyIndex] = nil
                self.keyIndex = nil
            end
        end
        
        if self.menu.UpdateKeyList then
            self.menu.UpdateKeyList()
        end
    end

    local function addKeybindToToggle(self, default, name)
        if not self.keybind then
            local keybind = {}
            local visible = self.menu.open and self.tab.tabIndex == self.menu.tabIndex and self.sectionIndex == 1
            if name then
                self.section.flags[name] = keybind
            end
            
            default = default ~= "" and default or "None"
            keybind.toggle = self
            keybind.value = default
            keybind.menu = self.menu
            keybind.AddColorPicker = addColorToToggle
            keybind.buttonoutline = self.menu:draw("Square", {Position = self.buttonoutline.Position + v2(171 - self.additions, 0), Size = v2(42, 14), Color = wapus.theme.outline, Visible = visible}, "outline")
            keybind.button = self.menu:draw("Square", {Position = keybind.buttonoutline.Position + v2(1, 1), Size = v2(40, 12), Color = wapus.theme.hidden, Visible = visible}, "hidden")
            keybind.text = self.menu:draw("Text", {Position = keybind.button.Position + v2(21, -2), Size = 14, Color = wapus.theme.text, Text = default, Center = true, Visible = visible}, "text")
            keybind.SetValue = setKeybindValue
            self.keybind = keybind
            self.additions += 49

            if default ~= "None" then
                keybind.keyIndex = #self.menu.keybinds + 1
                insert(self.menu.keybinds, keybind.keyIndex, {default, keybind})
            end

            return keybind
        end
    end

    local function setToggleValue(self, value)
        self.value = value
        self.button:SetColor(value and {wapus.theme.accent, darken(wapus.theme.accent, 0.25)} or {wapus.theme.lightbackground, wapus.theme.background})

        if self.callback then
            self.callback(value)
        end
        
        if self.menu.keys and self.menu.keys.updateList then
            self.menu.keys.updateList()
        end
    end

    local function addToggle(self, text, default, callback, unsafe)
        local toggle = {}
        local visible = self.menu.open and self.tab.tabIndex == self.menu.tabIndex and self.index == 1
        local container = self.background.Position + self.bgOffset
        self.flags[text] = toggle
        toggle.type = "toggle"
        toggle.name = text
        toggle.colors = {}
        toggle.tab = self.tab
        toggle.menu = self.menu
        toggle.sectionIndex = self.index
        toggle.section = self
        toggle.height = 15
        toggle.additions = 0
        toggle.value = default == true
        toggle.buttonoutline = self.menu:draw("Square", {Position = container + v2(0, 3), Size = v2(11, 11), Color = wapus.theme.outline, Visible = visible}, "outline")
        --toggle.button = self.menu:draw("Square", {Position = toggle.buttonoutline.Position + v2(1, 1), Size = v2(9, 9), Color = default and wapus.theme.accent or wapus.theme.background, Visible = visible}, "background")
        toggle.button = modifyDrawing(self.menu:gradient({wapus.theme.accent, darken(wapus.theme.accent, 0.25)}, 3), {Position = toggle.buttonoutline.Position + v2(1, 1), Size = v2(9, 9), Color = default and wapus.theme.accent or wapus.theme.background, Visible = visible})
        toggle.text = self.menu:draw("Text", {Position = toggle.buttonoutline.Position + v2(16, -2), Size = 14, Color = wapus.theme.text, Text = text, Visible = visible}, "text")
        toggle.AddKeyBind = addKeybindToToggle
        toggle.AddColorPicker = addColorToToggle
        toggle.callback = callback
        toggle.SetValue = setToggleValue
        self.bgOffset += v2(0, toggle.height)
        insert(self.elements, toggle)
        toggle.button:SetColor(not default and {wapus.theme.lightbackground, wapus.theme.background})
        return toggle
    end

    local function addSection(self, text)
        local section = {}
        local visible = self.menu.open and self.tab.tabIndex == self.menu.tabIndex
        local mainSection = self.sections[#self.sections]
        local lastButton = mainSection.button
        self.menu.sectionIndexes[text] = section
        section.background = mainSection.background
        section.index = #self.sections + 1
        section.buttonoutline = self.menu:draw("Square", {Position = lastButton.Position + v2(lastButton.Size.X + 1, 0), Color = wapus.theme.outline, Visible = visible}, "outline")
        section.button = self.menu:draw("Square", {Position = section.buttonoutline.Position + v2(0, 0), Color = wapus.theme.hidden, Visible = visible}, "hidden")
        section.text = self.menu:draw("Text", {Size = 14, Color = wapus.theme.hiddenText, Center = true, Text = text, Visible = visible}, "text")
        section.button.Size = v2(10 + section.text.TextBounds.X, 20)
        section.buttonoutline.Size = v2(11 + section.text.TextBounds.X, 21)
        section.text.Position = section.button.Position + v2(5 + section.text.TextBounds.X * 0.5, 4)
        section.text.ZIndex = 3
        section.tab = self.tab
        section.menu = self.menu
        section.name = text
        section.elements = {}
        section.flags = {}
        section.AddToggle = addToggle
        section.AddSlider = addSlider
        section.AddDropdown = addDropdown
        section.AddButton = addButton
        section.AddTextBox = addTextbox
        section.bgOffset = v2(8, 4)
        insert(self.sections, section)
        return section
    end

    local function createSection(self, text, right, height)
        local section = {}
        local visible = self.menu.open and self.tabIndex == self.menu.tabIndex
        local side = right and "right" or "left"
        self.menu.sectionIndexes[text] = section
        height = height == "half" and 257 or height == "whole" and 518 or height == "third" and 170 or height
        section.outline = self.menu:draw("Square", {Size = v2(231, height), Position = self.menu.sectionbg.Position + v2(7 + (right and 235 or 0), 3 + self[side]), Color = wapus.theme.outline, Visible = visible}, "outline")
        section.highlightoutline = self.menu:draw("Square", {Size = v2(229, 4), Position = section.outline.Position + v2(1, 1), Color = wapus.theme.outline, Visible = visible}, "outline")
        section.highlight = modifyDrawing(self.menu:gradient({wapus.theme.accent:Lerp(Color3.new(1, 1, 1), 0.1), wapus.theme.accent, darken(wapus.theme.accent, 0.4)}, 3), {Size = v2(229, 3), Position = section.highlightoutline.Position, Color = wapus.theme.accent, Visible = visible})
        section.buttons = self.menu:draw("Square", {Size = v2(229, 20), Position = section.highlightoutline.Position + v2(0, 4), Color = wapus.theme.hidden, Visible = visible}, "hidden")
        section.buttonoutline = self.menu:draw("Square", {Position = section.highlightoutline.Position + v2(0, 4), Color = wapus.theme.outline, Visible = visible}, "outline")
        section.button = self.menu:draw("Square", {Position = section.highlightoutline.Position + v2(0, 4), Color = wapus.theme.background, Visible = visible}, "background")
        section.buttonbackground = modifyDrawing(self.menu:gradient({wapus.theme.lightbackground, wapus.theme.background}, 8), {Position = section.highlightoutline.Position + v2(0, 4), Color = wapus.theme.background, Visible = visible})
        section.text = self.menu:draw("Text", {Size = 14, Color = wapus.theme.text, Center = true, Text = text, Visible = visible}, "text")
        section.button.Size = v2(10 + section.text.TextBounds.X, 21)
        section.buttonbackground.Size = section.button.Size
        section.buttonbackground.ZIndex = 2
        section.buttonoutline.Size = v2(11 + section.text.TextBounds.X, 21)
        section.text.Position = section.buttons.Position + v2(5 + section.text.TextBounds.X * 0.5, 4)
        section.text.ZIndex = 3
        section.background = self.menu:draw("Square", {Size = v2(229, height - 27), Position = section.outline.Position + v2(1, 26), Color = wapus.theme.background, Visible = visible}, "background")
        section.menu = self.menu
        section.tab = self
        section.name = text
        section.sections = {section}
        section.sectionIndex = 1
        section.index = 1
        section.AddSection = addSection
        section.elements = {}
        section.flags = {}
        section.AddToggle = addToggle
        section.AddSlider = addSlider
        section.AddDropdown = addDropdown
        section.AddButton = addButton
        section.AddTextBox = addTextbox
        section.bgOffset = v2(8, 4)
        self[side] += height + 4
        insert(self.mainSections, section)
        return section
    end

    local players = game:GetService("Players")
    local localplayer = players.LocalPlayer
    local function initPlayerList(list)
        local data = list.playerdata
        local status = list.playerstatus
        local drawings = list.playerdrawings
        
        local function updateListText()
            for _, drawingData in drawings do
                drawingData.name.Text = ""
                drawingData.team.Text = ""
                drawingData.status.Text = ""
            end
            
            local scrollmax = math.max(#data - 9, 0)
            local scrollcount = math.min(list.scrollcount, scrollmax)
            list.scrollcount = scrollcount
            
            for playerIndex = 1, 9 do
                local player = data[playerIndex - scrollcount]
                
                if player then
                    local islocal = player == localplayer
                    local isteamed = player.Team ~= nil
                    local playerdrawings = drawings[playerIndex]
                    playerdrawings.name.Text = player.Name
                    playerdrawings.team.Text = isteamed and player.Team.Name or "None"
                    playerdrawings.team.Color = isteamed and player.TeamColor.Color or wapus.theme.text
                    playerdrawings.status.Text = islocal and "Local Player" or status[player] or "None"
                    playerdrawings.status.Color = islocal and Color3.new(0.407843, 0, 0.87451) or wapus.theme.text
                end
            end
        end
        
        local function setTeam(player, team)
            for playerIndex = 1, #data do
                if data[playerIndex].Team == team then
                    insert(data, playerIndex, player)
                    break
                end
            end
        end
        
        local function updateTeam(player)
            player:GetPropertyChangedSignal("Team", function(team)
                table.remove(data, table.find(data, player))
                setTeam(player, team)
            end)
        end
        
        local teams = {}
        for _, player in players:GetPlayers() do
            local team = player.Team or "Nil"
            
            if not teams[team] then
                teams[team] = {}
            end
            
            insert(teams[team], player)
        end
        
        for _, team in teams do
            for _, player in team do
                insert(data, player)
                updateTeam(player)
            end
        end

        updateListText()
        
        table.insert(connectionList, players.PlayerAdded:Connect(function(player)
            if player.Team then
                setTeam(player, player.Team)
            end
            
            updateTeam(player)
            updateListText()
        end))
        
        table.insert(connectionList, players.PlayerRemoving:Connect(function(player)
            table.remove(data, table.find(data, player))
            
            if table.find(status, player) then
                status[player] = nil
            end
            
            if list.selected == player then
                list.playerPFP.Data = blankData
                list.playertext.Text = "No Player Selected"
                list.selected = nil
            end
            
            updateListText()
        end))
        
        return updateListText
    end

    local playerlists = {}
    local function createPlayerList(self, statuslist, callbacks)
        local playerlist = {playerdata = {}, listdata = {}, playerstatus = {}, scrollcount = 0} -- , selected = nil
        local visible = self.menu.open and self.tabIndex == self.menu.tabIndex
        local height = 344
        playerlist.type = "playerlist"
        playerlist.statuslist = statuslist
        playerlist.status = callbacks.status
        playerlist.votekick = callbacks.votekick
        playerlist.spectate = callbacks.spectate
        playerlist.outline = self.menu:draw("Square", {Size = v2(231 + 235, height), Position = self.menu.sectionbg.Position + v2(7, 3), Color = wapus.theme.outline, Visible = visible}, "outline")
        playerlist.highlightoutline = self.menu:draw("Square", {Size = v2(229 + 235, 4), Position = playerlist.outline.Position + v2(1, 1), Color = wapus.theme.outline, Visible = visible}, "outline")
        playerlist.highlight = modifyDrawing(self.menu:gradient({wapus.theme.accent:Lerp(Color3.new(1, 1, 1), 0.1), wapus.theme.accent, darken(wapus.theme.accent, 0.4)}, 3), {Size = v2(229 + 235, 3), Position = playerlist.highlightoutline.Position, Color = wapus.theme.accent, Visible = visible})
        playerlist.buttons = self.menu:draw("Square", {Size = v2(229 + 235, 20), Position = playerlist.highlightoutline.Position + v2(0, 4), Color = wapus.theme.hidden, Visible = visible}, "hidden")
        playerlist.buttonoutline = self.menu:draw("Square", {Position = playerlist.highlightoutline.Position + v2(0, 4), Color = wapus.theme.outline, Visible = visible}, "outline")
        playerlist.button = self.menu:draw("Square", {Position = playerlist.highlightoutline.Position + v2(0, 4), Color = wapus.theme.background, Visible = visible}, "background")
        playerlist.buttonbackground = modifyDrawing(self.menu:gradient({wapus.theme.lightbackground, wapus.theme.background}, 8), {Position = playerlist.highlightoutline.Position + v2(0, 4), Color = wapus.theme.background, Visible = visible})
        playerlist.text = self.menu:draw("Text", {Size = 14, Color = wapus.theme.text, Center = true, Text = "Player List", Visible = visible}, "text")
        playerlist.button.Size = v2(10 + playerlist.text.TextBounds.X, 21)
        playerlist.buttonbackground.Size = playerlist.button.Size
        playerlist.buttonbackground.ZIndex = 2
        playerlist.buttonoutline.Size = v2(11 + playerlist.text.TextBounds.X, 21)
        playerlist.text.Position = playerlist.buttons.Position + v2(5 + playerlist.text.TextBounds.X * 0.5, 4)
        playerlist.text.ZIndex = 3
        playerlist.background = self.menu:draw("Square", {Size = v2(229 + 235, height - 27), Position = playerlist.outline.Position + v2(1, 26), Color = wapus.theme.background, Visible = visible}, "background")
        playerlist.playerBoxOutline = self.menu:draw("Square", {Size = v2(229 + 235 - 16, 210), Position = playerlist.outline.Position + v2(9, 26 + 18), Color = wapus.theme.outline, Visible = visible}, "outline")
        playerlist.playerBoxBackground = self.menu:draw("Square", {Size = v2(229 + 235 - 16 - 2, 208), Position = playerlist.outline.Position + v2(10, 26 + 19), Color = wapus.theme.background, Visible = visible}, "background")
        playerlist.playerPFPOutline = self.menu:draw("Square", {Size = v2(74, 74), Position = playerlist.outline.Position + v2(9, 26 + 18 + 8 + 210), Color = wapus.theme.outline, Visible = visible}, "outline")
        playerlist.playerPFP = self.menu:draw("Image", {Size = v2(72, 72), Position = playerlist.outline.Position + v2(10, 26 + 18 + 8 + 211), Data = blankData, Visible = visible}, "outline")
        --playerlist.playerPFP = self.menu:draw("Square", {Size = v2(72, 72), Position = playerlist.outline.Position + v2(10, 26 + 18 + 8 + 211), Color = wapus.theme.outline, Visible = visible}, "outline")
        playerlist.statusbuttonoutline = self.menu:draw("Square", {Size = v2(149, 20), Position = playerlist.outline.Position + v2(308, 26 + 18 + 210 + 22), Color = wapus.theme.outline, Visible = visible}, "outline")
        playerlist.statusbutton = modifyDrawing(self.menu:gradient({wapus.theme.lightbackground, wapus.theme.background}, 6), {Size = v2(147, 18), Position = playerlist.outline.Position + v2(309, 26 + 18 + 210 + 23), Visible = visible})
        playerlist.votekickbuttonoutline = self.menu:draw("Square", {Size = v2(69, 20), Position = playerlist.outline.Position + v2(308, 26 + 18 + 210 + 53), Color = wapus.theme.outline, Visible = visible}, "outline")
        playerlist.votekickbutton = modifyDrawing(self.menu:gradient({wapus.theme.lightbackground, wapus.theme.background}, 6), {Size = v2(67, 18), Position = playerlist.outline.Position + v2(309, 26 + 18 + 210 + 54), Visible = visible})
        playerlist.spectatebuttonoutline = self.menu:draw("Square", {Size = v2(69, 20), Position = playerlist.outline.Position + v2(308 + 80, 26 + 18 + 210 + 53), Color = wapus.theme.outline, Visible = visible}, "outline")
        playerlist.spectatebutton = modifyDrawing(self.menu:gradient({wapus.theme.lightbackground, wapus.theme.background}, 6), {Size = v2(67, 18), Position = playerlist.outline.Position + v2(308 + 81, 26 + 18 + 210 + 54), Visible = visible})

        playerlist.nametext = self.menu:draw("Text", {Position = playerlist.playerBoxOutline.Position + v2(4, -17), Size = 14, Color = wapus.theme.text, Text = "Name", Visible = visible}, "text")
        playerlist.teamtext = self.menu:draw("Text", {Position = playerlist.playerBoxOutline.Position + v2(4 + 148, -17), Size = 14, Color = wapus.theme.text, Text = "Team", Visible = visible}, "text")
        playerlist.statuslabeltext = self.menu:draw("Text", {Position = playerlist.playerBoxOutline.Position + v2(4 + 298, -17), Size = 14, Color = wapus.theme.text, Text = "Status", Visible = visible}, "text")
        playerlist.playertext = self.menu:draw("Text", {Position = playerlist.playerPFP.Position + v2(78, -2), Size = 14, Color = wapus.theme.text, Text = "No Player Selected", Visible = visible}, "text")
        playerlist.playerstatustext = self.menu:draw("Text", {Position = playerlist.statusbuttonoutline.Position + v2(-1, -17), Size = 14, Color = wapus.theme.text, Text = "Player Status", Visible = visible}, "text")
        playerlist.statustext = self.menu:draw("Text", {Position = playerlist.playerstatustext.Position + v2(6, 19), Size = 14, Color = wapus.theme.text, Text = "None", Visible = visible}, "text")
        playerlist.droptext = self.menu:draw("Text", {Position = playerlist.playerstatustext.Position + v2(137, 20), Size = 14, Color = wapus.theme.text, Text = "-", Visible = visible}, "text")
        playerlist.votekicktext = self.menu:draw("Text", {Position = playerlist.votekickbutton.Position + v2(33, 1), Size = 14, Center = true, Color = wapus.theme.text, Text = "Votekick", Visible = visible}, "text")
        playerlist.spectatetext = self.menu:draw("Text", {Position = playerlist.spectatebutton.Position + v2(33, 1), Size = 14, Center = true, Color = wapus.theme.text, Text = "Spectate", Visible = visible}, "text")

        playerlist.carrot = self.menu:draw("Text", {Position = playerlist.playerBoxBackground.Position + v2(437, -1), Size = 14, Outline = false, Color = wapus.theme.accent, Text = "^", Visible = visible}, "accent")
        playerlist.tinyv = self.menu:draw("Text", {Position = playerlist.playerBoxBackground.Position + v2(437, 195), Size = 11, Outline = false, Color = wapus.theme.accent, Text = "v", Visible = visible}, "accent")

        playerlist.playerdrawings = {}
        for playerIndex = 1, 9 do
            local drawinglist = {}

            if playerIndex ~= 9 then
                drawinglist.sectionline = self.menu:draw("Square", {Size = v2(438, 1), Position = playerlist.playerBoxBackground.Position + v2(4, 23 * playerIndex), Color = wapus.theme.outline, Visible = visible}, "outline")
            end

            drawinglist.teamline = self.menu:draw("Square", {Size = v2(1, playerIndex ~= 9 and 16 or 17), Position = playerlist.playerBoxBackground.Position + v2(148, 23 * (playerIndex - 1) + 4), Color = wapus.theme.outline, Visible = visible}, "outline")
            drawinglist.statusline = self.menu:draw("Square", {Size = v2(1, playerIndex ~= 9 and 16 or 17), Position = playerlist.playerBoxBackground.Position + v2(298, 23 * (playerIndex - 1) + 4), Color = wapus.theme.outline, Visible = visible}, "outline")
            drawinglist.name = self.menu:draw("Text", {Position = playerlist.playerBoxBackground.Position + v2(4, 23 * (playerIndex - 1) + 5), Size = 14, Color = wapus.theme.text, Text = "", Visible = visible}, "text")
            drawinglist.team = self.menu:draw("Text", {Position = playerlist.playerBoxBackground.Position + v2(152, 23 * (playerIndex - 1) + 5), Size = 14, Color = wapus.theme.text, Text = "", Visible = visible}, "text")
            drawinglist.status = self.menu:draw("Text", {Position = playerlist.playerBoxBackground.Position + v2(302, 23 * (playerIndex - 1) + 5), Size = 14, Color = wapus.theme.text, Text = "", Visible = visible}, "text")

            playerlist.playerdrawings[playerIndex] = drawinglist
        end

        self.left += height + 4
        self.right += height + 4
        playerlist.updatelist = initPlayerList(playerlist)
        insert(self.mainSections, playerlist)
        insert(playerlists, playerlist)
        return playerlist
    end

    local function createTab(self, text)
        local tab = {}
        tab.tabIndex = #self.tabs + 1
        tab.button = self["tab" .. tostring(tab.tabIndex)]
        tab.title = self:draw("Text", {Size = 15, Position = tab.button.Position + v2(48, 11), Color = wapus.theme[tab.tabIndex == self.tabIndex and "text" or "hiddenText"], Text = text, Center = true, Visible = self.open}, "text")
        tab.CreateSection = createSection
        tab.CreatePlayerList = createPlayerList
        tab.menu = self
        tab.left = 0
        tab.right = 0
        tab.mainSections = {}
        insert(self.tabs, tab)
        return tab
    end

    local function destroyKeyList(self) -- idec if it lags prolly wont be much
        for _, drawing in self.keys.drawCache do
            pcall(function()
                drawing:Remove()
            end)
        end
        
        self.keys = nil
        self.DestroyKeyList = nil
        self.UpdateKeyList = nil
    end

    local white = Color3.new(1, 1, 1)
    local darker = Color3.new(0.65, 0.65, 0.65)

    local function createKeyList(self, includeKeyName)
        local keys = {}
        keys.include = includeKeyName
        keys.drawCache = {}
        keys.draw = draw
        keys.gradient = gradient
        keys.outline = keys:draw("Square", {Color = wapus.theme.outline, Visible = true}, "outline")
        keys.background = keys:draw("Square", {Color = wapus.theme.background, Visible = true}, "background")
        keys.titlebackground = modifyDrawing(keys:gradient({wapus.theme.lightbackground, wapus.theme.background}, 7), {Color = wapus.theme.accent, Visible = true})
        keys.highlightoutline = keys:draw("Square", {Color = wapus.theme.outline, Visible = true}, "outline")
        keys.highlight = modifyDrawing(keys:gradient({wapus.theme.accent:Lerp(Color3.new(1, 1, 1), 0.1), wapus.theme.accent, darken(wapus.theme.accent, 0.4)}, 3), {Color = wapus.theme.accent, Visible = true})
        keys.title = keys:draw("Text", {Size = 16, Color = wapus.theme.text, Text = "Keybinds", Visible = true}, "text")

        local function updateKeybinds()
            if keys.keybinds then
                for _, keyData in keys.keybinds do
                    keyData[1]:Remove()
                end
            end
            
            local newkeybinds = {}
            
            for _, keyData in self.keybinds do
                local keyName, keybind = table.unpack(keyData)
                local text = keybind.toggle.section.text.Text .. ": " .. keybind.toggle.text.Text
                
                if keys.include then
                    text = text .. " [ " .. keyName .. " ]"
                end
                
                insert(newkeybinds, {keys:draw("Text", {Size = 16, Color = wapus.theme.text, Text = text, Visible = true}, "text"), keybind})
            end
            
            keys.keybinds = newkeybinds
        end
        
        local function updateList()
            local keycount = #keys.keybinds
            local height = 23 + 16 * keycount
            local width = 150
            
            for _, bindData in keys.keybinds do
                local text, keybind = table.unpack(bindData)
                local bounds = text.TextBounds.X + 4
                
                if bounds > width then
                    width = bounds
                end
            end
            
            local size = v2(width, height)
            keys.outline.Position = v2(9, workspace.CurrentCamera.ViewportSize.Y * 0.5 - height * 0.5 - 1)
            keys.outline.Size = size + v2(2, 2)
            keys.background.Position = keys.outline.Position + v2(1, 1)
            keys.background.Size = size
            keys.titlebackground.Position = keys.background.Position + v2(0, 5)
            keys.titlebackground.Size = v2(width, 14)
            keys.highlightoutline.Position = keys.outline.Position
            keys.highlightoutline.Size = v2(width + 2, 5)
            keys.highlight.Position = keys.background.Position
            keys.highlight.Size = v2(width, 3)
            keys.title.Position = keys.background.Position + v2(2, 3)
            
            for keyIndex = 1, keycount do
                local text, keybind = table.unpack(keys.keybinds[keyIndex])
                text.Color = keybind.toggle.value and white or darker
                text.Position = keys.title.Position + v2(0, keyIndex * 16 + 1)
            end
        end
        
        local function updateKeyList()
            updateKeybinds()
            runService.RenderStepped:Wait()
            updateList()
        end

        keys.updateKeybinds = updateKeybinds
        keys.updateList = updateList
        self.keys = keys
        self.DestroyKeyList = destroyKeyList
        self.UpdateKeyList = updateKeyList
        updateKeyList()
    end

    function wapus:CreateMenu(title, visible, index)
        if visible == nil then
            visible = true
        end

        local menu = {}
        menu.drawCache = {}
        menu.draw = draw
        menu.gradient = gradient
        local bgSize = v2(500, 600)
        menu.open = visible
        self.open = visible
        menu.tabIndex = index and math.clamp(index, 1, 5) or 1
        menu.outline = menu:draw("Square", {Size = bgSize + v2(2, 2), Position = middle - bgSize * 0.5 - v2(1, 1), Color = self.theme.outline, Visible = visible}, "outline")
        menu.background = menu:draw("Square", {Size = bgSize, Position = middle - bgSize * 0.5, Color = self.theme.background, Visible = visible}, "background")
        menu.outline2 = menu:draw("Square", {Size = v2(502, 4), Position = menu.outline.Position, Color = self.theme.outline, Visible = visible}, "outline")
        menu.highlightoutline = menu:draw("Square", {Size = v2(500, 4), Position = menu.background.Position, Color = self.theme.outline, Visible = visible}, "outline")
        menu.highlight = modifyDrawing(menu:gradient({self.theme.accent:Lerp(Color3.new(1, 1, 1), 0.1), self.theme.accent, darken(self.theme.accent, 0.4)}, 3), {Size = v2(500, 3), Position = menu.background.Position, Color = self.theme.accent, Visible = visible})
        menu.titlebackground = modifyDrawing(menu:gradient({self.theme.lightbackground, self.theme.background}, 7), {Size = v2(500, 21), Position = menu.background.Position + v2(0, 4), Color = self.theme.accent, Visible = visible})
        menu.title = menu:draw("Text", {Size = 16, Position = menu.background.Position + v2(5, 5), Color = self.theme.text, Text = title, Visible = visible}, "text")
        menu.inline = menu:draw("Square", {Size = bgSize + v2(2 - 20, 2 - 35), Position = menu.outline.Position + v2(10, 25), Color = self.theme.outline, Visible = visible}, "outline")
        menu.tab1 = menu:draw("Square", {Size = v2(95, 35), Position = menu.inline.Position + v2(1, 3), Color = self.theme.hidden, Visible = visible}, "hidden")
        menu.tab2 = menu:draw("Square", {Size = v2(95, 35), Position = menu.tab1.Position + v2(96, 0), Color = self.theme.hidden, Visible = visible}, "hidden")
        menu.tab3 = menu:draw("Square", {Size = v2(96, 35), Position = menu.tab2.Position + v2(96, 0), Color = self.theme.hidden, Visible = visible}, "hidden")
        menu.tab4 = menu:draw("Square", {Size = v2(95, 35), Position = menu.tab3.Position + v2(97, 0), Color = self.theme.hidden, Visible = visible}, "hidden")
        menu.tab5 = menu:draw("Square", {Size = v2(95, 35), Position = menu.tab4.Position + v2(96, 0), Color = self.theme.hidden, Visible = visible}, "hidden")
        menu.tabbackground = modifyDrawing(menu:gradient({self.theme.lightbackground, self.theme.background}, 14), {Visible = visible})
        menu.inlightoutline = menu:draw("Square", {Size = v2(480, 4), Position = menu.inline.Position + v2(1, 1), Color = self.theme.outline, Visible = visible}, "outline")
        --menu.inlight = menu:draw("Square", {Size = v2(480, 2), Position = menu.inlightoutline.Position, Color = self.theme.accent, Visible = visible}, "accent")
        menu.inlight = modifyDrawing(menu:gradient({self.theme.accent:Lerp(Color3.new(1, 1, 1), 0.20), self.theme.accent, darken(self.theme.accent, 0.4)}, 3), {Size = v2(480, 3), Position = menu.inlightoutline.Position, Color = self.theme.accent, Visible = visible})
        menu.sectionbg = menu:draw("Square", {Size = v2(480, 527), Position = menu.inlight.Position + v2(0, 38), Color = self.theme.background, Visible = visible}, "background")
        menu.sectionIndexes = {}
        menu.tabs = {}
        menu.keybinds = {}
        menu.UpdateTheme = updateTheme
        menu.GetValue = getValue
        menu.SetValue = setValue
        menu.CreateTab = createTab
        local selectedTab = menu["tab" .. tostring(menu.tabIndex)]
        selectedTab.Color = self.theme.background
        selectedTab.Size += v2(0, 1)
        menu.tabbackground.Position = selectedTab.Position
        menu.tabbackground.Size = selectedTab.Size
        menu.CreateKeyList = createKeyList

        insert(self.menus, menu)
        return menu
    end

    local function checkBounds(rel, size)
        local x0, y0 = rel.X, rel.Y
        local x1, y1 = size.X, size.Y
        return x0 >= 0 and x0 <= x1 and y0 >= 0 and y0 <= y1
    end

    local function checkDrawing(mouse, drawing)
        return checkBounds(mouse - drawing.Position, drawing.Size)
    end

    local function getSectionDrawings(section)
        local drawings = {}

        for _, elementData in section.elements do
            if elementData.type == "toggle" then
                insert(drawings, elementData.buttonoutline)
                insert(drawings, elementData.button)
                insert(drawings, elementData.text)

                if elementData.keybind then
                    insert(drawings, elementData.keybind.buttonoutline)
                    insert(drawings, elementData.keybind.button)
                    insert(drawings, elementData.keybind.text)
                end

                for colorIndex = 1, #elementData.colors do
                    local colorData = elementData.colors[colorIndex]
                    insert(drawings, colorData.buttonoutline)
                    insert(drawings, colorData.buttonbackground)
                    insert(drawings, colorData.button)
                end
            elseif elementData.type == "slider" then
                insert(drawings, elementData.buttonoutline)
                insert(drawings, elementData.button)
                insert(drawings, elementData.highlight)
                insert(drawings, elementData.text)
                insert(drawings, elementData.valuetext)
            elseif elementData.type == "dropdown" then
                insert(drawings, elementData.buttonoutline)
                insert(drawings, elementData.button)
                insert(drawings, elementData.text)
                insert(drawings, elementData.valuetext)
                insert(drawings, elementData.droptext)
            elseif elementData.type == "button" then
                insert(drawings, elementData.buttonoutline)
                insert(drawings, elementData.button)
                insert(drawings, elementData.text)
            elseif elementData.type == "textbox" then
                insert(drawings, elementData.buttonoutline)
                insert(drawings, elementData.button)
                insert(drawings, elementData.text)
                insert(drawings, elementData.valuetext)
            end
        end

        return drawings
    end

    local function getTabDrawings(tab)
        local drawings = {}

        for _, sectionData in tab.mainSections do
            if sectionData.type == "playerlist" then
                insert(drawings, sectionData.outline)
                insert(drawings, sectionData.highlightoutline)
                insert(drawings, sectionData.highlight)
                insert(drawings, sectionData.buttons)
                insert(drawings, sectionData.buttonoutline)
                insert(drawings, sectionData.button)
                insert(drawings, sectionData.buttonbackground)
                insert(drawings, sectionData.text)
                insert(drawings, sectionData.background)
                insert(drawings, sectionData.playerBoxOutline)
                insert(drawings, sectionData.playerBoxBackground)
                insert(drawings, sectionData.playerPFPOutline)
                insert(drawings, sectionData.playerPFP)
                insert(drawings, sectionData.statusbuttonoutline)
                insert(drawings, sectionData.statusbutton)
                insert(drawings, sectionData.votekickbuttonoutline)
                insert(drawings, sectionData.votekickbutton)
                insert(drawings, sectionData.spectatebuttonoutline)
                insert(drawings, sectionData.spectatebutton)
                insert(drawings, sectionData.nametext)
                insert(drawings, sectionData.teamtext)
                insert(drawings, sectionData.statuslabeltext)
                insert(drawings, sectionData.playertext)
                insert(drawings, sectionData.playerstatustext)
                insert(drawings, sectionData.statustext)
                insert(drawings, sectionData.droptext)
                insert(drawings, sectionData.votekicktext)
                insert(drawings, sectionData.spectatetext)
                insert(drawings, sectionData.carrot)
                insert(drawings, sectionData.tinyv)

                for _, playerDrawingData in sectionData.playerdrawings do
                    if playerDrawingData.sectionline then
                        insert(drawings, playerDrawingData.sectionline)
                    end

                    insert(drawings, playerDrawingData.teamline)
                    insert(drawings, playerDrawingData.statusline)
                    insert(drawings, playerDrawingData.name)
                    insert(drawings, playerDrawingData.team)
                    insert(drawings, playerDrawingData.status)
                end
            else
                insert(drawings, sectionData.outline)
                insert(drawings, sectionData.highlightoutline)
                insert(drawings, sectionData.buttons)
                insert(drawings, sectionData.highlight)
                insert(drawings, sectionData.background)

                for sectionIndex, section in sectionData.sections do
                    insert(drawings, section.buttonoutline)
                    insert(drawings, section.buttonbackground)
                    insert(drawings, section.button)
                    insert(drawings, section.text)

                    if sectionIndex == sectionData.sectionIndex then
                        for _, drawing in getSectionDrawings(section) do
                            insert(drawings, drawing)
                        end
                    end
                end
            end
        end

        return drawings
    end

    local lastPos, dragging, sliding, dropping, statusdropping, typing, waiting, picking -- cotton
    local fadeDuration = 0.125
    local fadeSteps = 15
    local lastToggle = 0
    local keyboard = "QWERTYUIOPASDFGHJKLZXCVBNM"
    local shiftkeys = {Backquote = "~", One = "!", Two = "@", Three = "#", Four = "$", Five = "%", Six = "^", Seven = "&", Eight = "*", Nine = "(", Zero = ")", Minus = "_", Equals = "+", LeftBracket = "{", RightBracket = "]", BackSlash = "|", Semicolon = ":", Quote = '"', Comma = "<", Period = ">", Slash = "?"}
    local keynames = {Space = " ", QuotedDouble = '"', Hash = "#", Dollar = "$", Percent = "%", Ampersand = "&", Quote = "'", LeftParenthesis = "(", RightParenthesis = ")", Asterisk = "*", Plus = "+", Comma = ",", Minus = "-", Period = ".", Slash = "/", Zero = "0", One = "1", Two = "2", Three = "3", Four = "4", Five = "5", Six = "6", Seven = "7", Eight = "8", Nine = "9", Colon = ":", Semicolon = ";", LessThan = "<", Equals = "=", GreaterThan = ">", Question = "?", At = "@", LeftBracket = "[", BackSlash = "\\", RightBracket = "]", Caret = "^", Underscore = "_", Backquote = "`", LeftCurly = "{", Pipe = "|", RightCurly = "}", Tilde = "~"}
    table.insert(connectionList, userInputService.InputBegan:Connect(function(input)
        if input.KeyCode ~= Enum.KeyCode.Unknown then
            local key = input.KeyCode.Name

            if typing then
                local text = typing.valuetext.Text

                if key == "Backspace" or key == "Delete" then
                    text = string.sub(text, 1, string.len(text) - 1)
                elseif key == "Return" or key == "Escape" then
                    typing:SetValue(text)
                    typing = false
                    return
                elseif key == "V" and (userInputService:IsKeyDown(Enum.KeyCode.LeftControl) or userInputService:IsKeyDown(Enum.KeyCode.RightControl)) and keypress and keyrelease then
                    task.spawn(function()
                        local screenGui = Instance.new("ScreenGui", game.CoreGui) -- erm is this iray code?
                        local textBox = Instance.new("TextBox", screenGui) -- first person to tell iray where this is pasted from with proof gets a free nihon key
                        textBox.TextTransparency = 1
                        textBox:CaptureFocus()
                        keypress(0x11)  
                        keypress(0x56)
                        task.wait(1/60)
                        keyrelease(0x11)
                        keyrelease(0x56)
                        textBox:ReleaseFocus()
                        text = text .. textBox.Text
                        textBox:Destroy()
                        screenGui:Destroy()
                    end)
                else
                    local lower = not userInputService:IsKeyDown(Enum.KeyCode.LeftShift) and not userInputService:IsKeyDown(Enum.KeyCode.RightShift)

                    if string.find(keyboard, key) then
                        if lower then
                            key = string.lower(key)
                        end

                        text = text .. key
                    elseif not lower and shiftkeys[key] then
                        text = text .. shiftkeys[key]
                    elseif keynames[key] then
                        text = text .. keynames[key]
                    end
                end

                typing.valuetext.Text = text
                return
            end

            if waiting then
                if key == "Escape" then
                    waiting:SetValue()
                    waiting = false
                else
                    waiting:SetValue(key)
                    waiting = false
                end

                return
            end

            for _, menuData in wapus.menus do
                for _, keyData in menuData.keybinds do
                    if key == keyData[1] then
                        keyData[2].toggle:SetValue(not keyData[2].toggle.value)
                        
                        if menuData.keys and menuData.keys.updateList then
                            menuData.keys.updateList()
                        end
                    end
                end
            end

            local clockTime = os.clock()
            if input.KeyCode == Enum.KeyCode[wapus.toggleKeybind] and clockTime - lastToggle > fadeDuration * 2 and not dragging and not sliding and not dropping and not picking then
                wapus.open = not wapus.open
                lastToggle = clockTime

                for _, menu in wapus.menus do
                    local trans = (wapus.open and 0 or 1) --menu.background.Transparency
                    local stepFactor = 1 / fadeSteps
                    local step = stepFactor * (wapus.open and 1 or -1)
                    local stepDur = stepFactor * fadeDuration
                    local drawings = {
                        menu.outline,
                        menu.background,
                        menu.outline2,
                        menu.highlightoutline,
                        menu.highlight,
                        menu.title,
                        menu.inline,
                        menu.tab1,
                        menu.tab2,
                        menu.tab3,
                        menu.tab4,
                        menu.tab5,
                        menu.inlightoutline,
                        menu.inlight,
                        menu.sectionbg,
                        menu.titlebackground,
                        menu.tabbackground
                    }
                    menu.open = wapus.open

                    if menu.updateCache then
                        menu.updateCache()
                    end

                    for _, drawing in getTabDrawings(menu.tabs[menu.tabIndex]) do
                        insert(drawings, drawing)
                    end

                    for _, tabData in menu.tabs do
                        insert(drawings, tabData.title)
                    end

                    task.spawn(function()
                        if wapus.open then
                            for _, drawing in drawings do
                                drawing.Visible = true
                            end
                        end

                        for _ = 1, fadeSteps do
                            trans = trans + step

                            for _, drawing in drawings do
                                drawing.Transparency = trans
                            end

                            task.wait(stepDur)
                        end

                        if not wapus.open then
                            for _, drawing in drawings do
                                drawing.Visible = false
                            end
                        end
                    end)
                end
            end
        end
    end))

    table.insert(connectionList, userInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseWheel then
            for _, list in playerlists do
                if list.playerBoxBackground.Visible and checkDrawing(userInputService:GetMouseLocation(), list.playerBoxBackground) then
                    list.scrollcount = math.max(math.min(list.scrollcount + ((input.Position.Z > 0) and 1 or -1), 0), -#list.playerdata + 9)
                    list.updatelist()
                end
            end
        end
    end))

    local pickerUpdateFPS = 60 -- limiting update speed to reduce lag
    local pickerUpdateRate = 1 / pickerUpdateFPS
    local wasDown = false
    table.insert(connectionList, runService.RenderStepped:Connect(function(delta)
        local down = userInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
        local clicked = down and not wasDown
        wasDown = down

        if wapus.open then
            if sliding then
                if down then
                    local relpos = userInputService:GetMouseLocation().X - sliding.button.Position.X
                    local fraction = math.clamp(relpos, 0, 211) / 211
                    local range = sliding.max - sliding.min
                    local factor = math.floor(range * fraction / sliding.step + 0.5)
                    sliding:SetValue(sliding.min + factor * sliding.step)
                    return
                else
                    sliding = false
                end
            end

            if dropping then
                if clicked then
                    local mouse = userInputService:GetMouseLocation()
                    local newoption = dropping.value

                    for optionIndex, option in dropping.optionDrawings do
                        if checkDrawing(mouse, option.button) then
                            newoption = option.valuetext.Text
                        end

                        for _, drawing in option do
                            drawing:Remove()
                        end
                    end

                    dropping:SetValue(newoption)
                    dropping.optionDrawings = nil
                    dropping = false
                end

                return
            end
            
            if statusdropping then
                if clicked then
                    local mouse = userInputService:GetMouseLocation()
                    local selectedstatus
                    
                    for _, buttonData in statusdropping.buttons do
                        if checkDrawing(mouse, buttonData.button) then
                            selectedstatus = buttonData.status
                            break
                        end
                    end

                    for _, drawing in statusdropping.drawCache do
                        drawing:Remove()
                    end

                    if selectedstatus then
                        local player = statusdropping.list.selected
                        statusdropping.list.playerstatus[player] = selectedstatus
                        statusdropping.list.status(player, selectedstatus)
                        statusdropping.list.updatelist()
                    end
                    
                    statusdropping = nil
                end
                
                return
            end

            if typing then
                if clicked then
                    typing:SetValue(typing.valuetext.Text)
                    typing = false
                end

                return
            end

            if waiting then
                if clicked then
                    waiting:SetValue()
                    waiting = false
                end

                return
            end

            if picking then
                local mouse = userInputService:GetMouseLocation()
                local picker = picking.picker

                if clicked then -- i wanna kmsssss
                    if checkDrawing(mouse, picker.outline) then
                        local clock = os.clock()

                        if mouse.Y < picker.outline.Position.Y + 18 then
                            picker.dragging = {mouse, clock}
                        elseif checkDrawing(mouse, picker.hsvOutline) then
                            picker.clicked = {"hsv", clock, Vector2.zero}
                        elseif checkDrawing(mouse, picker.hue) then
                            picker.clicked = {"hue", clock, Vector2.zero}
                        elseif checkDrawing(mouse, picker.valuebar) then
                            picker.clicked = {"val", clock, Vector2.zero}
                        elseif checkBounds(mouse - (picker.background.Position + v2(193, 135)), v2(80, 80)) then
                            for _, drawing in picker.drawCache do
                                drawing:Remove()
                            end

                            picking:SetValue(Color3.fromHSV(table.unpack(picker.current)))
                            picking.picker = nil
                            picking = nil
                        end
                    else
                        for _, drawing in picker.drawCache do
                            drawing:Remove()
                        end

                        picking:SetValue(picking.value)
                        picking.picker = nil
                        picking = nil
                    end
                elseif down then
                    local clock = os.clock()

                    if picker.dragging then
                        local oldPos, oldTime = table.unpack(picker.dragging)

                        if clock > oldTime + pickerUpdateRate then
                            local offset = mouse - oldPos

                            if offset.Magnitude > 0 then
                                for _, drawing in picker.drawCache do
                                    drawing.Position = drawing.Position + offset
                                end

                                picker.dragging = {mouse, clock}
                            end
                        end
                    end

                    if picker.clicked then
                        local clicktype, oldTime, oldMouse = table.unpack(picker.clicked)

                        if clock > oldTime + pickerUpdateRate and (mouse - oldMouse).Magnitude > 0 then
                            if clicktype == "hsv" then
                                local bgpos = picker.hsvOutline.Position + v2(1, 1)
                                local rel = mouse - bgpos
                                local x, y = math.clamp(rel.X, 0, 166), math.clamp(rel.Y, 0, 166)
                                local sat = x / 166
                                local val = 1 - (y / 166)
                                picker.newColor.Color = Color3.fromHSV(picker.current[1], sat, val)
                                picker.current[2] = sat
                                picker.current[3] = val
                                picker.hsvButtonOutline.Position = bgpos + v2(x - 3, y - 3)
                                picker.hsvButton.Position = bgpos + v2(x - 2, y - 2)
                                picker.valueButtonOutline.Position = v2(picker.valuebar.Position.X + 166 - y - 3, picker.valueButtonOutline.Position.Y)
                                picker.valueButton.Position = picker.valueButtonOutline.Position + v2(1, 1)
                            elseif clicktype == "val" then
                                local x = math.clamp(mouse.X - picker.valuebar.Position.X, 0, 166)
                                local val = x / 166
                                picker.newColor.Color = Color3.fromHSV(picker.current[1], picker.current[2], val)
                                picker.current[3] = val
                                picker.valueButtonOutline.Position = v2(picker.valuebar.Position.X + x - 3, picker.valueButtonOutline.Position.Y)
                                picker.valueButton.Position = picker.valueButtonOutline.Position + v2(1, 1)
                                picker.hsvButtonOutline.Position = v2(picker.hsvButtonOutline.Position.X, picker.hsvOutline.Position.Y + 166 - x - 2)
                                picker.hsvButton.Position = picker.hsvButtonOutline.Position + v2(1, 1)
                            elseif clicktype == "hue" then
                                local y = math.clamp(mouse.Y - picker.hue.Position.Y, 0, 166)
                                local hue = (166 - y) / 166
                                picker.newColor.Color = Color3.fromHSV(hue, picker.current[2], picker.current[3])
                                picker.current[1] = hue
                                picker.hueButtonOutline.Position = v2(picker.hueButtonOutline.Position.X, picker.hue.Position.Y + y - 3)
                                picker.hueButton.Position = picker.hueButtonOutline.Position + v2(1, 1)
                                picker.clicked[2] = clock
                                picker.hueSquare.Color = Color3.fromHSV(hue, 1, 1)
                                --local xMax = #picker.colordrawings
                                --local yMax = picker.colordrawings[1]; yMax = #yMax
                                --for x = 0, xMax do -- more lag
                                --	local sat = x / xMax
                                --
                                --	for y = 0, yMax do
                                --		local value = 1 - (y / yMax)
                                --		picker.colordrawings[x][y].Color = Color3.fromHSV(hue, sat, value)
                                --	end
                                --end
                            end
                        end
                    end
                elseif picker.dragging then
                    picker.dragging = false
                elseif picker.clicked then
                    picker.clicked = false
                end

                return
            end

            for _, menuData in wapus.menus do
                if menuData.open then
                    local mouse = userInputService:GetMouseLocation()
                    local onMenu = checkDrawing(mouse, menuData.outline)
                    local onInside = onMenu and checkDrawing(mouse, menuData.inline)

                    if clicked and not dragging and onMenu and not onInside then
                        dragging = true
                        lastPos = mouse
                    end

                    if dragging and down then
                        local offset = mouse - lastPos

                        if offset.Magnitude > 0 then
                            for _, drawing in menuData.drawCache do
                                drawing.Position = drawing.Position + offset
                            end

                            lastPos = mouse
                        end
                    else
                        dragging = false
                    end

                    if onInside then
                        local sectionbg = menuData.sectionbg.Position

                        if mouse.Y < sectionbg.Y then
                            if clicked then
                                local newIndex = math.clamp(math.ceil((mouse.X - sectionbg.X) / 96), 1, 5)
                                local oldTab = menuData.tabs[menuData.tabIndex]
                                local newTab = menuData.tabs[newIndex]
                                oldTab.title.Color = wapus.theme.hiddenText
                                newTab.title.Color = wapus.theme.text
                                local oldButton = menuData["tab" .. tostring(menuData.tabIndex)]
                                local newButton = menuData["tab" .. tostring(newIndex)]
                                oldButton.Size = oldButton.Size - v2(0, 1)
                                newButton.Size = newButton.Size + v2(0, 1)
                                oldButton.Color = wapus.theme.hidden
                                newButton.Color = wapus.theme.background
                                menuData.tabbackground.Position = newButton.Position
                                menuData.tabbackground.Size = newButton.Size

                                for _, drawing in getTabDrawings(oldTab) do
                                    drawing.Visible = false
                                end

                                for _, drawing in getTabDrawings(newTab) do
                                    drawing.Visible = true
                                end

                                menuData.tabIndex = newIndex

                                if menuData.updateCache then
                                    menuData.updateCache()
                                end
                            end
                        else
                            for _, sectionData in menuData.tabs[menuData.tabIndex].mainSections do
                                if sectionData.type == "playerlist" then
                                    if clicked and checkDrawing(mouse, sectionData.outline) then
                                        if checkDrawing(mouse, sectionData.playerBoxBackground) then
                                            local index = math.min(math.ceil((mouse.Y - sectionData.playerBoxBackground.Position.Y) / 23), 9)
                                            local player = sectionData.playerdata[index - sectionData.scrollcount]
                                            
                                            if player and player ~= localplayer then
                                                sectionData.selected = player
                                                sectionData.playerPFP.Data = players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420) or blankData
                                                sectionData.playertext.Text = player.Name
                                            end
                                        end
                                        
                                        if sectionData.selected then
                                            if checkDrawing(mouse, sectionData.votekickbuttonoutline) then
                                                sectionData.votekick(sectionData.selected)
                                            end

                                            if checkDrawing(mouse, sectionData.spectatebuttonoutline) then
                                                sectionData.votekick(sectionData.selected)
                                            end
                                            
                                            local statusButton = sectionData.statusbuttonoutline
                                            if checkDrawing(mouse, statusButton) then
                                                statusdropping = {list = sectionData, buttons = {}, drawCache = {}, draw = draw}
                                                
                                                for statusIndex = 1, #sectionData.statuslist + 1 do
                                                    local statusName = statusIndex == 1 and "None" or sectionData.statuslist[statusIndex - 1]
                                                    local buttonData = {}
                                                    buttonData.status = statusName
                                                    buttonData.outline = statusdropping:draw("Square", {Size = v2(149, 20), Position = statusButton.Position + v2(0, 19 * statusIndex), Color = wapus.theme.outline, Visible = true, ZIndex = 4}, "outline")
                                                    buttonData.button = statusdropping:draw("Square", {Size = v2(147, 18), Position = buttonData.outline.Position + v2(1, 1), Color = wapus.theme.background, Visible = true, ZIndex = 4}, "outline")
                                                    buttonData.text = statusdropping:draw("Text", {Position = buttonData.button.Position + v2(4, 1), Size = 14, Color = wapus.theme.text, Text = statusName, Visible = true, ZIndex = 4}, "text")
                                                    statusdropping.buttons[statusIndex] = buttonData
                                                end
                                            end
                                        end
                                    end
                                elseif checkDrawing(mouse, sectionData.outline) then
                                    if mouse.Y < sectionData.background.Position.Y then
                                        if clicked then
                                            for sectionIndex, section in sectionData.sections do
                                                if checkDrawing(mouse, section.button) then
                                                    local oldSec = sectionData.sections[sectionData.sectionIndex]
                                                    oldSec.text.Color = wapus.theme.hiddenText
                                                    section.text.Color = wapus.theme.text
                                                    oldSec.button.Size = oldSec.button.Size - v2(0, 1)
                                                    section.button.Size = section.button.Size + v2(0, 1)
                                                    oldSec.button.Color = wapus.theme.hidden
                                                    section.button.Color = wapus.theme.background
                                                    sectionData.buttonbackground.Position = section.button.Position
                                                    sectionData.buttonbackground.Size = section.button.Size

                                                    for _, drawing in getSectionDrawings(oldSec) do
                                                        drawing.Visible = false
                                                    end

                                                    for _, drawing in getSectionDrawings(section) do
                                                        drawing.Visible = true
                                                    end

                                                    sectionData.sectionIndex = sectionIndex
                                                end
                                            end
                                        end
                                    else
                                        if clicked then
                                            local section = sectionData.sections[sectionData.sectionIndex]
                                            local relPos = mouse - (sectionData.background.Position + v2(8, 4))
                                            local height = 0

                                            for elementIndex = 1, #section.elements do
                                                local element = section.elements[elementIndex]

                                                if checkBounds(relPos - v2(0, height), v2(230, element.height)) then
                                                    if element.type == "toggle" then
                                                        if element.keybind and checkDrawing(mouse, element.keybind.buttonoutline) then
                                                            element.keybind:SetValue()
                                                            element.keybind.text.Text = "..."
                                                            waiting = element.keybind
                                                            return
                                                        end

                                                        for _, color in element.colors do
                                                            if checkDrawing(mouse, color.buttonoutline) then
                                                                local picker = {
                                                                    drawCache = {},
                                                                    draw = draw,
                                                                    gradient = gradient
                                                                } -- i wanna kms
                                                                picker.outline = picker:draw("Square", {Position = color.toggle.buttonoutline.Position + v2(-57, -8), Size = v2(275, 217), Color = wapus.theme.outline, Visible = true, ZIndex = 4})
                                                                picker.background = picker:draw("Square", {Position = picker.outline.Position + v2(1, 1), Size = v2(273, 215), Color = wapus.theme.background, Visible = true, ZIndex = 4})
                                                                picker.highlightbackground = picker:draw("Square", {Position = picker.outline.Position + v2(1, 1), Size = v2(273, 4), Color = wapus.theme.outline, Visible = true, ZIndex = 4})
                                                                picker.highlight = modifyDrawing(picker:gradient({wapus.theme.accent:Lerp(Color3.new(1, 1, 1), 0.1), wapus.theme.accent, darken(wapus.theme.accent, 0.4)}, 3), {Position = picker.highlightbackground.Position, Size = v2(273, 3), Visible = true, ZIndex = 4})
                                                                picker.titlebackground = modifyDrawing(picker:gradient({wapus.theme.lightbackground, wapus.theme.background}, 6), {Size = v2(273, 17), Position = picker.background.Position + v2(0, 4), Visible = true, ZIndex = 4})
                                                                picker.title = picker:draw("Text", {Position = picker.background.Position + v2(3, 3), Size = 14, Color = wapus.theme.text, Text = color.name, Visible = true, ZIndex = 4})
                                                                picker.hsvOutline = picker:draw("Square", {Position = picker.background.Position + v2(7, 19), Size = v2(202 - 18 - 16, 168), Color = wapus.theme.outline, Visible = true, ZIndex = 4})
                                                                picker.hueOutline = picker:draw("Square", {Position = picker.hsvOutline.Position + v2(7 + picker.hsvOutline.Size.X, 0), Size = v2(12, 168), Color = wapus.theme.outline, Visible = true, ZIndex = 4})
                                                                picker.hue = picker:draw("Image", {Position = picker.hsvOutline.Position + v2(8 + picker.hsvOutline.Size.X, 1), Size = v2(10, 166), Data = hueData, Visible = true, ZIndex = 4})
                                                                picker.valueOutline = picker:draw("Square", {Position = picker.background.Position + v2(7, 195), Size = v2(202 - 18 - 16, 12), Color = wapus.theme.outline, Visible = true, ZIndex = 4})
                                                                picker.valuebar = picker:draw("Image", {Position = picker.background.Position + v2(8, 196), Size = v2(200 - 18 - 16, 10), Data = valueData, Visible = true, ZIndex = 4})
                                                                picker.newtext = picker:draw("Text", {Position = picker.hueOutline.Position + v2(19, -2), Size = 14, Color = wapus.theme.text, Text = "New Color", Visible = true, ZIndex = 4})
                                                                picker.newOutline = picker:draw("Square", {Position = picker.newtext.Position + v2(0, 17), Size = v2(65, 35), Color = wapus.theme.outline, Visible = true, ZIndex = 4})
                                                                picker.newColor = picker:draw("Square", {Position = picker.newtext.Position + v2(1, 18), Size = v2(63, 33), Color = color.value, Visible = true, ZIndex = 4})
                                                                picker.oldtext = picker:draw("Text", {Position = picker.hueOutline.Position + v2(19, 52), Size = 14, Color = wapus.theme.text, Text = "Old Color", Visible = true, ZIndex = 4})
                                                                picker.oldOutline = picker:draw("Square", {Position = picker.oldtext.Position + v2(0, 17), Size = v2(65, 35), Color = wapus.theme.outline, Visible = true, ZIndex = 4})
                                                                picker.oldColor = picker:draw("Square", {Position = picker.oldtext.Position + v2(1, 18), Size = v2(63, 33), Color = color.value, Visible = true, ZIndex = 4})
                                                                picker.applytext = picker:draw("Text", {Position = picker.hueOutline.Position + v2(27, 175), Size = 14, Color = wapus.theme.text, Text = "[  Apply  ]", Visible = true, ZIndex = 4})
                                                                picker.colordrawings = {}

                                                                local h, s, v = color.value:ToHSV()
                                                                picker.current = {h, s, v}
                                                                local startPos = picker.hsvOutline.Position + v2(1, 1)
                                                                
                                                                -- lol
                                                                --for x = 0, xMax do -- lags cuz almost 7k drawings created here
                                                                --	picker.colordrawings[x] = {}
                                                                --	local sat = x / xMax
                                                                --
                                                                --	for y = 0, yMax do
                                                                --		local value = 1 - (y / yMax)
                                                                --		picker.colordrawings[x][y] = picker:draw("Square", {Position = startPos + v2(x * xStepPX, y * yStepPX), Size = v2(xStepPX, yStepPX), Color = Color3.fromHSV(h, sat, value), Visible = true})
                                                                --	end
                                                                --end
                                                                
                                                                picker.hueSquare = picker:draw("Square", {Position = picker.hsvOutline.Position + v2(1, 1), Size = v2(166, 166), Color = Color3.fromHSV(h, 1, 1), Visible = true, ZIndex = 4})
                                                                picker.satSquare = picker:draw("Square", {Position = picker.hsvOutline.Position + v2(1, 1), Size = v2(166, 166), Color = Color3.fromHSV(0, 0, 1), Visible = true, ZIndex = 4})
                                                                picker.valSquare = picker:draw("Square", {Position = picker.hsvOutline.Position + v2(1, 1), Size = v2(166, 166), Color = Color3.fromHSV(0, 1, 0), Visible = true, ZIndex = 4})
                                                                
                                                                for i = 1, 2 do
                                                                    local parent = i == 1 and "satSquare" or "valSquare"
                                                                    local uiGradient = Instance.new("UIGradient", picker[i == 1 and "satSquare" or "valSquare"]._data.drawings.box)
                                                                    uiGradient.Transparency = NumberSequence.new(0, 1)
                                                                    
                                                                    if i == 2 then
                                                                        uiGradient.Rotation = 270
                                                                    end
                                                                end
                                                                
                                                                
                                                                picker.hsvButtonOutline = picker:draw("Square", {Position = startPos + v2(s * 166 - 2, (1 - v) * 166 - 2), Size = v2(5, 5), Filled = false, Thickness = 1, Color = wapus.theme.outline, Visible = true, ZIndex = 4})
                                                                picker.hsvButton = picker:draw("Square", {Position = picker.hsvButtonOutline.Position + v2(1, 1), Size = v2(3, 3), Filled = false, Thickness = 1, Color = Color3.new(1, 1, 1), Visible = true, ZIndex = 4})
                                                                picker.hueButtonOutline = picker:draw("Square", {Position = picker.hue.Position + v2(-3, (1 - h) * 166 - 3), Size = v2(16, 5), Filled = false, Thickness = 1, Color = wapus.theme.outline, Visible = true, ZIndex = 4})
                                                                picker.hueButton = picker:draw("Square", {Position = picker.hueButtonOutline.Position + v2(1, 1), Size = v2(14, 3), Filled = false, Thickness = 1, Color = Color3.new(1, 1, 1), Visible = true, ZIndex = 4})
                                                                picker.valueButtonOutline = picker:draw("Square", {Position = picker.valuebar.Position + v2(v * 166 - 3, -3), Size = v2(5, 16), Filled = false, Thickness = 1, Color = wapus.theme.outline, Visible = true, ZIndex = 4})
                                                                picker.valueButton = picker:draw("Square", {Position = picker.valueButtonOutline.Position + v2(1, 1), Size = v2(3, 14), Filled = false, Thickness = 1, Color = Color3.new(1, 1, 1), Visible = true, ZIndex = 4})
                                                                color.picker = picker
                                                                picking = color
                                                                return
                                                            end
                                                        end

                                                        element:SetValue(not element.value)
                                                    elseif element.type == "slider" then
                                                        sliding = element
                                                    elseif element.type == "dropdown" then
                                                        dropping = element
                                                        element.optionDrawings = {}

                                                        for optionIndex = 1, #element.options do
                                                            local newDrawings = {}
                                                            newDrawings.outline = menuData:draw("Square", {Position = element.buttonoutline.Position + v2(0, optionIndex * 17), Size = v2(213, 18), Color = wapus.theme.outline, Visible = true, ZIndex = 4}, "outline")
                                                            newDrawings.button = menuData:draw("Square", {Position = newDrawings.outline.Position + v2(1, 1), Size = v2(211, 16), Color = wapus.theme.background, Visible = true, ZIndex = 4}, "background")
                                                            newDrawings.valuetext = menuData:draw("Text", {Position = newDrawings.button.Position + v2(6, 0), Size = 14, Color = wapus.theme.text, Text = element.options[optionIndex], Visible = true, ZIndex = 4}, "text")
                                                            element.optionDrawings[optionIndex] = newDrawings
                                                        end
                                                    elseif element.type == "button" then
                                                        if element.callback then
                                                            element.callback()
                                                        end
                                                    elseif element.type == "textbox" then
                                                        typing = element
                                                        element.valuetext.Text = ""
                                                    end
                                                end

                                                height = height + element.height
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end))
end

return wapus
