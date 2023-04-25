
--Start of Global Scope---------------------------------------------------------
print('AppEngine Version: ' .. Engine.getVersion())

local DELAY = 1500 -- ms between visualization steps for demonstration purpose

-- Creating viewer
local viewer = View.create()

-- Setting up graphical overlay attributes
local shapeDeco = View.ShapeDecoration.create()
shapeDeco:setLineColor(0, 255, 0):setLineWidth(5)
local textDeco = View.TextDecoration.create():setColor(0, 255, 0)
textDeco:setSize(40):setPosition(30, 30)

--End of Global Scope-----------------------------------------------------------

--Start of Function and Event Scope---------------------------------------------

---@param image Image
---@param sleepTime int
---@param text string
local function presentImage(image, sleepTime, text)
  viewer:addImage(image)
  viewer:addText(text, textDeco)
  viewer:present()
  Script.sleep(sleepTime)
  viewer:clear()
end

---@param circles Shape[]
---@param houghAcc Image
---@return Shape
local function getBestHoughCircle(circles, houghAcc)
  local bestCircles = {}
  local currentHighestPixVal = 0

  if circles ~= nil then
    if circles[1] ~= nil then
      for _, v in ipairs(circles) do
        local centerExt, _ = v:getCircleParameters()
        local pixelCenter = houghAcc:toPixelCoordinate(centerExt)
        local pixelValue = houghAcc:getPixel(pixelCenter:getXY())

        if pixelValue >= currentHighestPixVal then
          currentHighestPixVal = pixelValue
          table.remove(bestCircles)
          table.insert(bestCircles, v)
        end
      end
    end
  end
  return bestCircles[1]
end

---@param img Image
local function houghTransform(img)
  local radius = 54
  local w, h = img:getSize()
  -- First step, use canny to segment edges in image
  local edgeIm = img:canny(300, 100)
  presentImage(edgeIm, DELAY, 'Edge Image')
  -- Second step, produce likely circle candidates from edge image
  -- Circles with radius close to input parameter radius will have
  -- higher intensities in the output. Afterwards, the image is
  -- normalized between 0 and 255
  local houghAcc = edgeIm:houghTransformCircle(radius, w, h)
  houghAcc:multiplyConstantInplace(255 / houghAcc:getMax())
  presentImage(houghAcc, DELAY, 'Hough Accumulator')
  -- Access local extremas with the most likely circles
  -- and use hough transform to retrieve these circle candidates
  -- Lastly, go through all circles and find the most likely candidate.
  local locExt = houghAcc:findLocalExtrema('MAX', 3, 100)
  local circles = houghAcc:houghTransformExtremaToCircles(locExt, radius)
  local bestCircle = getBestHoughCircle(circles, houghAcc)

  -- present results
  viewer:addImage(img)
  viewer:addShape(bestCircle, shapeDeco)
  viewer:addText('Found Circle', textDeco)
  viewer:present()
  Script.sleep(DELAY)
  viewer:clear()
end

local function main()
  -- Loading images from resources
  local oneCircleImage = Image.load('resources/OneCircle.png')
  local multipleCircleImage = Image.load('resources/MultipleCircles.png')

  presentImage(oneCircleImage, DELAY, 'Original Image')
  houghTransform(oneCircleImage)

  presentImage(multipleCircleImage, DELAY, 'Original Image')
  houghTransform(multipleCircleImage)

  print('App finished.')
end
--The following registration is part of the global scope which runs once after startup
--Registration of the 'main' function to the 'Engine.OnStarted' event
Script.register('Engine.OnStarted', main)

--End of Function and Event Scope--------------------------------------------------
