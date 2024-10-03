local LrHttp = import 'LrHttp'
local LrDialogs = import 'LrDialogs'
local LrTasks = import 'LrTasks'
local LrFunctionContext = import 'LrFunctionContext'
local LrPrefs = import 'LrPrefs'
local LrApplication = import 'LrApplication'
local LrProgressScope = import 'LrProgressScope'
local LrPasswords = import 'LrPasswords'

local json = require 'dkjson'

local prefs = LrPrefs.prefsForPlugin()

local debug = false

local function findKeywordByName(catalog, keywordName)
    local allKeywords = catalog:getKeywords()
    for _, keyword in ipairs(allKeywords) do
        if keyword:getName() == keywordName then
            return keyword
        end
    end
    return nil
end

local function isValidParam(param)
    return param ~= nil and param ~= ""
end

function generateMetadata(photo, callback)
    LrTasks.startAsyncTask(function()
        local apiToken = LrPasswords.retrieve("phototagai_token") or ""
        local url = "https://server.phototag.ai/api/keywords"

        if not isValidParam(apiToken) then
            LrDialogs.message("Notice", "Please enter your PhotoTag.ai API token in the Plug-in Manager settings.")
            callback()
            return
        end

        if not photo then
            if debug then
                LrDialogs.message("Error", "Invalid photo.")
            end
            callback()
            return
        end

        local photoPath = photo:getRawMetadata('path')

        if not isValidParam(photoPath) then
            if debug then
                LrDialogs.message("Error", "Invalid photo path.")
            end
            callback()
            return
        end

        local headers = {
            { field = 'Authorization', value = 'Bearer ' .. apiToken },
        }

        local formData = {
            { name = 'file', fileName = photoPath, filePath = photoPath },
        }

        if isValidParam(prefs.language) then
            table.insert(formData, { name = 'language', value = prefs.language })
        end
        if isValidParam(prefs.maxKeywords) then
            table.insert(formData, { name = 'maxKeywords', value = tostring(prefs.maxKeywords) })
        end
        if isValidParam(prefs.requiredKeywords) then
            table.insert(formData, { name = 'requiredKeywords', value = prefs.requiredKeywords })
        end
        if isValidParam(prefs.customContext) then
            table.insert(formData, { name = 'customContext', value = prefs.customContext })
        end
        if isValidParam(prefs.maxDescriptionCharacters) then
            table.insert(formData, { name = 'maxDescriptionCharacters', value = tostring(prefs.maxDescriptionCharacters) })
        end
        if isValidParam(prefs.minDescriptionCharacters) then
            table.insert(formData, { name = 'minDescriptionCharacters', value = tostring(prefs.minDescriptionCharacters) })
        end
        if isValidParam(prefs.maxTitleCharacters) then
            table.insert(formData, { name = 'maxTitleCharacters', value = tostring(prefs.maxTitleCharacters) })
        end
        if isValidParam(prefs.minTitleCharacters) then
            table.insert(formData, { name = 'minTitleCharacters', value = tostring(prefs.minTitleCharacters) })
        end
        if isValidParam(prefs.useFileNameForContext) then
            table.insert(formData, { name = 'useFileNameForContext', value = tostring(prefs.useFileNameForContext) })
        end
        if isValidParam(prefs.singleWordKeywordsOnly) then
            table.insert(formData, { name = 'singleWordKeywordsOnly', value = tostring(prefs.singleWordKeywordsOnly) })
        end
        if isValidParam(prefs.excludedKeywords) then
            table.insert(formData, { name = 'excludedKeywords', value = prefs.excludedKeywords })
        end

        local response, responseHeaders = LrHttp.postMultipart(url, formData, headers)

        if response then
            local jsonResponse, _, err = json.decode(response)

            if err and debug then
                LrDialogs.message("Error", "Failed to parse JSON response: " .. err)
                callback()
                return
            end

            if jsonResponse and jsonResponse.data then
                local title = jsonResponse.data.title
                local description = jsonResponse.data.description
                local keywords = jsonResponse.data.keywords

                local catalog = LrApplication.activeCatalog()

                local success = catalog:withWriteAccessDo("Update Metadata", function()
                    photo:setRawMetadata('title', title)
                    photo:setRawMetadata('caption', description)

                    for _, keyword in ipairs(keywords) do
                        local existingKeyword = findKeywordByName(catalog, keyword)
                        if not existingKeyword then
                            existingKeyword = catalog:createKeyword(keyword, {}, false, nil, true)
                        end
                        photo:addKeyword(existingKeyword)
                    end
                end, { timeout = 30 })

                if not success and debug then
                    LrDialogs.message("Error", "Could not update metadata. Another write operation is blocking it.")
                end
            elseif debug then
                LrDialogs.message("Error", "Invalid response from the PhotoTag.ai API.")
            end
        elseif debug then
            LrDialogs.message("Error", "Failed to generate metadata. Please check your API token or network connection.")
        end

        callback()
    end)
end

LrFunctionContext.callWithContext('generateMetadata', function(context)
    local catalog = LrApplication.activeCatalog()
    local selectedPhotos = catalog:getTargetPhotos()

    local progress = LrProgressScope({
        title = "Generating metadata for selected photos...",
    })
    progress:setCancelable(true)
    progress:setPortionComplete(0, #selectedPhotos)

    local function processNextPhoto(index)
        local photo = selectedPhotos[index]

        generateMetadata(photo, function()
            progress:setPortionComplete(index, #selectedPhotos)
            if index < #selectedPhotos and not progress:isCanceled() then
                processNextPhoto(index + 1)
            else
                progress:done()
            end
        end)
    end

    processNextPhoto(1)
end)
