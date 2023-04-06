local_cache_get =
    '/': '/site/coral.ru/assets/dev-cache/coral-home.html'
    '/v1/geography/tocountryfilter?areaid=2529': '/site/coral.ru/assets/dev-cache/tocountryfilter-2529.json'
    '/v1/geography/tocountryfilter?areaid=2705': '/site/coral.ru/assets/dev-cache/tocountryfilter-2705.json'
    '/v1/geography/tocountryfilter?areaid=2504': '/site/coral.ru/assets/dev-cache/tocountryfilter-2504.json'
    '/v1/geography/tocountryfilter?areaid=2823': '/site/coral.ru/assets/dev-cache/tocountryfilter-2823.json'
    '/v1/geography/tocountryfilter?areaid=2679': '/site/coral.ru/assets/dev-cache/tocountryfilter-2679.json'
    '/v1/geography/tocountryfilter?areaid=2935': '/site/coral.ru/assets/dev-cache/tocountryfilter-2935.json'
    '/v1/geography/tocountryfilter?areaid=2763': '/site/coral.ru/assets/dev-cache/tocountryfilter-2763.json'
    '/v1/geography/tocountryfilter?areaid=2827': '/site/coral.ru/assets/dev-cache/tocountryfilter-2827.json'
    '/v1/geography/tocountryfilter?areaid=2743': '/site/coral.ru/assets/dev-cache/tocountryfilter-2743.json'
    '/v1/geography/tocountryfilter?areaid=2449': '/site/coral.ru/assets/dev-cache/tocountryfilter-2449.json'
    '/v1/geography/tocountryfilter?areaid=2671': '/site/coral.ru/assets/dev-cache/tocountryfilter-2671.json'
    '/v1/geography/tocountryfilter?areaid=2416': '/site/coral.ru/assets/dev-cache/tocountryfilter-2416.json'
    '/v1/geography/tocountryfilter?areaid=2989': '/site/coral.ru/assets/dev-cache/tocountryfilter-2989.json'
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