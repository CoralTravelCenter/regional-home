export ASAP = (->
    fns = []
    callall = () ->
        f() while f = fns.shift()
    if document.addEventListener
        document.addEventListener 'DOMContentLoaded', callall, false
        window.addEventListener 'load', callall, false
    else if document.attachEvent
        document.attachEvent 'onreadystatechange', callall
        window.attachEvent 'onload', callall
    (fn) ->
        fns.push fn
        callall() if document.readyState is 'complete'
)()

export preload = (what, fn) ->
    ASAP ->
        what = [what] unless  Array.isArray(what)
        $.when.apply($, ($.ajax(lib, dataType: 'script', cache: true) for lib in what)).done -> fn?()

export queryParam = (p, nocase) ->
    params_kv = location.search.substr(1).split('&')
    params = {}
    params_kv.forEach (kv) -> k_v = kv.split('='); params[k_v[0]] = k_v[1] or ''
    if p
        if nocase
            return decodeURIComponent(params[k]) for k of params when k.toUpperCase() == p.toUpperCase()
            return undefined
        else
            return decodeURIComponent params[p]
    params

export arrayOfNodesWith = (what) ->
    if what.jquery
        nodes = what.toArray()
    else if what instanceof Array
        nodes = Array.from what
    else if what instanceof Node
        nodes = [what]
    else if what instanceof NodeList
        nodes = Array.from what
    else if typeof what == 'string'
        nodes = Array.from document.querySelectorAll what
    else
        throw "*** arrayOfNodesWith: Got something unusable as 'what' param"
    nodes

export debounce = (func, threshold, execAsap) ->
    timeout = null
    (args...) ->
        obj = this
        delayed = ->
            func.apply(obj, args) unless execAsap
            timeout = null
        if timeout
            clearTimeout(timeout)
        else if (execAsap)
            func.apply(obj, args)
        timeout = setTimeout delayed, threshold || (1000 / 25)

export responsiveHandler = (media_query, match_handler, unmatch_handler) ->
    layout = matchMedia media_query
    layout.addEventListener 'change', (e) ->
        if e.matches then match_handler() else unmatch_handler()
    if layout.matches then match_handler() else unmatch_handler()
    layout

export autoplayVimeo = (lookup_selector = '.vimeo-video-box [data-vimeo-vid]', vid_attr = 'data-vimeo-vid', observer_options = {}) ->
    vboxes = document.querySelectorAll(lookup_selector)
    if vboxes.length
        preload 'https://player.vimeo.com/api/player.js', ->
            io = new IntersectionObserver (entries, observer) ->
                for entry in entries
                    player_el = entry.target
                    vplayer = player_el['vimeo-player']
                    if entry.isIntersecting
                        if vplayer
                            vplayer.play()
                        else
                            vplayer = new Vimeo.Player player_el,
                                id: player_el.getAttribute vid_attr
                                background: 1
                                playsinline: 1
                                autopause: 0
                                title: 0
                                byline: 0
                                portrait: 0
                            player_el['vimeo-player'] = vplayer
                            vplayer.on 'play', ->
                                this.element.parentElement.classList.add 'playback'
                    else
                        vplayer?.pause()
            , { threshold: 0.33, observer_options... }
            io.observe vbox for vbox in vboxes

export watchIntersection = (targets, options, yes_handler, no_handler) ->
    io = new IntersectionObserver (entries, observer) ->
        for entry in entries
            if entry.isIntersecting then yes_handler?.call(entry.target) else no_handler?.call(entry.target)
    , { threshold: 1, options... }
    io.observe target for target in arrayOfNodesWith targets
    io


export fixLayout = () ->
    if document.querySelector('section.underbrow')
        document.body.classList.add('underbrow')
    ASAP ->
        document.querySelectorAll('section.hero').forEach (heroSection) ->
            klasses = heroSection.closest('.widgetcontainer').classList
            klasses.add('hero')
            klasses.remove('oti-content-typography')
