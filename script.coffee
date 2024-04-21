# Operators
mul = (a, b) -> a * b
add = (a, b) -> a + b
sum = (x) -> foldr(add, x, 0)
square = (x) -> x ** 2

# ===| Vector operations |===

dotProduct = (v1, v2) ->
  return sum(map(mul, v1, v2))

# Function to calculate the magnitude of a vector
magnitude = (v) ->
    return Math.sqrt(sum(map(square, v)))

projection = (w, v) ->
  # Project w⃗ onto v⃗.
  # See https://en.wikipedia.org/wiki/Vector_projection for the derivation.
  scalar = dotProduct(w, v) / magnitude(v)**2
  projectionVector = map(((x) -> x * scalar), v)
  return projectionVector

# ===| Utility functions |===

map = (callback, ...lists) -> (callback(...elements) for elements in zip(...lists))

foldr = (callback, list, initialValue) ->
    accumulator = initialValue
    for element in list
      accumulator = callback(accumulator, element)
    accumulator

head = (items) -> if items.length then items[0] else null

filter = (closure, items) -> (item for item in items when closure(item))

zip = (arrays...) -> ((arr[i] for arr in arrays) for i in [0...Math.min(...(arr.length for arr in arrays))])

# ===| DOM functions |===

intersectsMiddleHorizontal = (element) ->
  # Check if an element would intersect a horizontal line
  # drawn in the middle of the viewport.
  elementRect = element.getBoundingClientRect()
  elementHeight = elementRect.height
  middleHorizontalLine = window.innerHeight / 2
  elementMiddleY = elementRect.top + elementHeight / 2

  elementMiddleY >= middleHorizontalLine - (elementHeight / 2) and elementMiddleY <= middleHorizontalLine + elementHeight / 2


topPaddingOf = (element) ->
  styles = window.getComputedStyle(element)
  parseInt styles.paddingTop, 10

containedByViewport = (element) ->
    rect = element.getBoundingClientRect()
    return (rect.top >= 0 and
    rect.left >= 0 and
    rect.bottom <= (window.innerHeight or document.documentElement.clientHeight) and
    rect.right <= (window.innerWidth or document.documentElement.clientWidth))

intersectsViewport = (element) ->
  rect = element.getBoundingClientRect()
  return (
    rect.bottom >= 0 and
    rect.top <= (window.innerHeight or document.documentElement.clientHeight) and
    rect.right >= 0 and
    rect.left <= (window.innerWidth or document.documentElement.clientWidth)
  )

fadeInElement = (element, delay) ->
    setTimeout ->
        element.classList.add("fade--visible")
    , delay

getAbsoluteTopPosition = (element) ->
  topPosition = 0
  while element
    topPosition += element.offsetTop
    element = element.offsetParent
  return topPosition

getTopHeightAsRatio = (elem) ->
    ratio = (elem.getBoundingClientRect().top / window.innerHeight)

# ===| Specific functions & helpers |===

FADE_IN_MAX_DELAY_MS = 500
FADE_IN_DISTANCE = "50px"
FADE_IN_LAST_LOADED_HEIGHT = 0

listenHover = (classname) ->
    # Listen for hover events, setting --this-focused on the hovered event and --other-focused on all other
    # items of the class. If no item of the class is hovered, the default is --none-focused.
    elements = document.querySelectorAll("." + classname)

    # Helper functions to avoid lambda-in-loop shenanigans
    setElementFocused = (selectedElement) ->
      -> for el in elements
        el.classList.remove(classname + "--this-focused")
        el.classList.add(classname + (if el is selectedElement then "--this-focused" else "--other-focused"))

    setNoneFocused = () ->
      -> for el in elements
        # Remove any matching elements.
        el.classList.remove(classname + "--this-focused")
        el.classList.remove(classname + "--other-focused")
        el.classList.add(classname + "--none-focused")

    for element in elements
      element.addEventListener('mouseover', setElementFocused(element))
      element.addEventListener('mouseout', setNoneFocused())


# ===| Listeners |===

copyParentRange = (element) ->
    text = element.parentElement.children[1]
    range = document.createRange()
    range.selectNode text
    window.getSelection().removeAllRanges()
    window.getSelection().addRange range
    document.execCommand 'copy'
    window.getSelection().removeAllRanges()
    return

# Function to handle scroll event
handleLoad = () ->
  fadeElements = document.querySelectorAll('.fade')
  for element in fadeElements
      if intersectsViewport(element)
          lastHeight = FADE_IN_LAST_LOADED_HEIGHT
          FADE_IN_LAST_LOADED_HEIGHT = getAbsoluteTopPosition element
          heightDifference = (FADE_IN_LAST_LOADED_HEIGHT - lastHeight) / window.innerHeight
          delay = heightDifference * FADE_IN_MAX_DELAY_MS

          fadeInElement element, delay

document.addEventListener "DOMContentLoaded", () ->
    window.addEventListener('scroll', (event) ->
        handleLoad()
    )
    window.addEventListener('load', handleLoad)


# ===| Old code for sidebar collapsing |===

# LISTEN_SIDEBAR_COLLAPSE_QUERY = '.toggle-fold-button, .content, .sidebar'
# LISTEN_SUGGEST_FOLD_QUERY = ".toggle-fold-button"
#
# currentlyFocused = null
# showingFoldOption = false
#
# scrollToSection = (sectionId) ->
#   targetSection = document.getElementById(sectionId)
#   targetSectionY = targetSection.getBoundingClientRect().top
#   # Scroll the item into view - use this instead of scrollIntoView to show some padding which looks nicer
#   parentPadding = topPaddingOf(targetSection.parentElement)
#   targetTop = targetSectionY + window.pageYOffset - parentPadding
#   window.scrollTo
#     top: targetTop
#     behavior: 'smooth'
#   return
#
# sectionToShortcut = (section) ->
#   document.querySelector 'p[id="sidebar-' + section.id + '"]'
#
# makeFocusedSection = (item) ->
#   currentlyFocused?.classList.remove 'focused-sidebar-item'
#   item.classList.add 'focused-sidebar-item'
#   currentlyFocused = item
#   return
#
# updateCurrentlyFocusedSection = ->
#   sections = document.querySelectorAll('section')
#   section = head filter(intersectsMiddleHorizontal, sections)
#
#   if section?
#       section = sectionToShortcut(section)
#       if section?
#           makeFocusedSection section
#
#   return
# sidebarIsFolded = ->
#     for el in document.querySelectorAll(LISTEN_SIDEBAR_COLLAPSE_QUERY)
#         return 'sidebar-collapsed' in el.classList
#
# setSidebarFolded = (shouldFold) ->
#     for el in document.querySelectorAll(LISTEN_SIDEBAR_COLLAPSE_QUERY)
#         if shouldFold
#             el.classList.add 'sidebar-collapsed'
#         else
#             el.classList.remove 'sidebar-collapsed'
#
#
# toggleSidebarFolded = ->
#     setSidebarFolded(not sidebarIsFolded())
#
#
# updateSuggestingFoldBasedOnMouseMove = (event) ->
#     sidebar = document.querySelector(".sidebar")
#     distance = distanceToBoundingBoxFromPoint sidebar, event.clientX, event.clientY
#     distancePercent = (distance / window.innerWidth) * 100
#     farAwayPercentageBound = 10
#     shouldForceSuggestFold = distancePercent < farAwayPercentageBound
#
#     changeTookPlace = shouldForceSuggestFold != showingFoldOption
#     showingFoldOption = shouldForceSuggestFold
#
#     if not changeTookPlace
#         return undefined
#
#     for el in document.querySelectorAll(LISTEN_SUGGEST_FOLD_QUERY)
#         if showingFoldOption
#             el.classList.add("suggest-fold")
#         else
#             el.classList.remove("suggest-fold")
#
#
# window.addEventListener 'scroll', updateCurrentlyFocusedSection
#
# document.addEventListener 'DOMContentLoaded', ->
#   updateCurrentlyFocusedSection()
#   listenHover ".project"
#   listenHover ".icon"
#   setSidebarFolded(false)
#   # document.querySelector(".sidebar").classList.remove("sidebar-collapsed")
#
# document.addEventListener('mousemove', updateSuggestingFoldBasedOnMouseMove)
#
# distanceToBoundingBoxFromPoint = (element, pointX, pointY) ->
#   # Calculate the length of the shortest line from a point to an element's bounding box.
#   # BUG: this does not take into consideration
#   # Points inside the element are
#   elementRect = element.getBoundingClientRect()
#
#   # Calculate the closest distance to each side of the box
#   closestX = Math.max(elementRect.left - pointX, 0, pointX - elementRect.right)
#   closestY = Math.max(elementRect.top - pointY, 0, pointY - elementRect.bottom)
#
#   # Calculate the Euclidean distance from the point to the closest side
#   closestDistance = Math.sqrt(closestX * closestX + closestY * closestY)
#
#   return closestDistance
