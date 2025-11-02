

-- Author :

return {
    onEvent = function(event, ...) addEvent(event, true) addEventHandler(event, ...) end,
    onPreRender = function(__func) return addEventHandler('onClientPreRender', root, __func) end,
    onRender = function(__func) return addEventHandler('onClientRender', root, __func) end,
    onRestore = function(__func) return addEventHandler('onClientRestore', root, __func) end,
    onStart = function(__func) return addEventHandler('onClientResourceStart', root, __func) end,
    onStop = function(__func) return addEventHandler('onClientResourceStop', root, __func) end,
    onClick = function(__func) return addEventHandler('onClientClick', root, __func) end,
    onDoubleClick = function(__func) return addEventHandler('onClientDoubleClick', root, __func) end,
    onKey = function(__func) return addEventHandler('onClientKey', root, __func) end,
    onTimer = function(__func, ...) return setTimer(__func, ...) end,
    isEvent = function( sEventName, pElementAttachedTo, func ) if type( sEventName ) == 'string' and isElement( pElementAttachedTo ) and type( func ) == 'function' then local aAttachedFunctions = getEventHandlers( sEventName, pElementAttachedTo ) if type( aAttachedFunctions ) == 'table' and #aAttachedFunctions > 0 then for i, v in ipairs( aAttachedFunctions ) do if v == func then return true end end end end return false end,
    onCommand = function(...) return addCommandHandler(...) end
}
