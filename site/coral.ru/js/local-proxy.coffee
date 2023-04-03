local_cache_get =
    '/': '/site/coral.ru/assets/dev-cache/coral-home.html'
    '/v1/geography/tocountryfilter?areaid=2529': '/site/coral.ru/assets/dev-cache/tocountryfilter-2529.json'
    '/v1/flight/availabledate?fromAreaId=2529&toCountryId=1': '/site/coral.ru/assets/dev-cache/availabledate-from-2529-to-1.json'

local_cache_post_by_optionId =
    '7c5ec50a-c9d6-490a-a867-ad8700e553ba': '/site/coral.ru/assets/dev-cache/turkey-best-deals.html'

export $get = (url) ->
    if window.location.hostname == 'localhost'
        if local_cache_get[url]
            return $.get(local_cache_get[url])
        else throw "NO LOCAL CACHE MAPPING FOR #{ url }; ; request wil certainly fail"
    else
        return $.get(url)

export $post = (url, param) ->
    if window.location.hostname == 'localhost'
        if local_cache_post_by_optionId[param.optionId]
            return $.get(local_cache_post_by_optionId[param.optionId])
        else throw "NO LOCAL CACHE MAPPING FOR #{ param.optionId }; request wil certainly fail"
    else
        return $.post url, param

export getActiveDeparture = () ->
    if window.location.hostname == 'localhost'
#        return name: "Москва", value: "2671"
        return name: "Казань", value: "2529"
    else
        window.global.getActiveDeparture()